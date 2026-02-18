import 'dart:async';
import 'dart:convert';
import '../local/local_storage.dart';
import '../local/local_models.dart';
import '../network/sync_backend_adapter.dart';
import '../utils/connectivity_service.dart';
import '../utils/logger.dart';
import '../utils/metrics.dart';
import '../core/synclayer_init.dart';
import '../core/sync_event.dart';
import '../conflict/conflict_resolver.dart';
import 'queue_manager.dart';

/// Core sync engine that handles push/pull synchronization
class SyncEngine {
  final LocalStorage _localStorage;
  final SyncBackendAdapter _backendAdapter;
  final ConnectivityService _connectivityService;
  final SyncConfig _config;
  final ConflictResolver _conflictResolver;
  late final QueueManager _queueManager;

  Timer? _syncTimer;
  StreamSubscription? _connectivitySubscription;
  bool _isRunning = false;
  bool _isSyncing = false; // Prevent concurrent sync operations

  // Event bus for logging, analytics, debugging
  final _eventController = StreamController<SyncEvent>.broadcast();

  // Logger and metrics
  final _logger = SyncLogger.instance;
  final _metrics = SyncMetrics.instance;

  // Timeout for individual sync operations
  final Duration _operationTimeout = const Duration(seconds: 30);

  SyncEngine({
    required LocalStorage localStorage,
    required SyncBackendAdapter backendAdapter,
    required ConnectivityService connectivityService,
    required SyncConfig config,
    ConflictResolver? conflictResolver,
  })  : _localStorage = localStorage,
        _backendAdapter = backendAdapter,
        _connectivityService = connectivityService,
        _config = config,
        _conflictResolver = conflictResolver ?? ConflictResolver() {
    _queueManager = QueueManager(
      _localStorage,
      onEvent: (event) => _eventController.add(event),
    );
  }

  /// Expose queue manager for external access
  QueueManager get queueManager => _queueManager;

  /// Stream of sync events for logging/analytics
  Stream<SyncEvent> get events => _eventController.stream;

  /// Start sync engine
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    // Listen to connectivity changes
    _connectivitySubscription =
        _connectivityService.onConnectivityChanged.listen((isOnline) {
      // Emit connectivity change event
      _eventController.add(SyncEvent(
        type: SyncEventType.connectivityChanged,
        metadata: {'isOnline': isOnline},
      ));

      if (isOnline) {
        // Reset failed operations when coming back online
        _resetFailedOperations();
        _performSync();
      }
    });

    // Start periodic sync
    _syncTimer = Timer.periodic(_config.syncInterval, (_) {
      if (_connectivityService.isOnline) {
        _performSync();
      }
    });

    // Initial sync if online
    if (_connectivityService.isOnline) {
      await _performSync();
    }
  }

  /// Reset failed operations to pending when connectivity restored
  Future<void> _resetFailedOperations() async {
    try {
      await _queueManager.resetFailedOperations();
      _logger.info('Reset failed operations to retry');
    } catch (e, stackTrace) {
      _logger.error('Error resetting failed operations', e, stackTrace);
    }
  }

  /// Stop sync engine
  Future<void> stop() async {
    _isRunning = false;
    _syncTimer?.cancel();
    await _connectivitySubscription?.cancel();

    // Close event controller safely
    if (!_eventController.isClosed) {
      await _eventController.close();
    }
  }

  /// Perform full sync (push then pull)
  Future<void> _performSync() async {
    if (!_connectivityService.isOnline) return;

    // Prevent concurrent sync operations
    if (_isSyncing) {
      _logger.warning('Sync already in progress, skipping');
      return;
    }

    _isSyncing = true;
    _metrics.recordSyncAttempt();
    _eventController.add(SyncEvent(type: SyncEventType.syncStarted));

    try {
      await _pushSync();
      await _pullSync();
      _metrics.recordSyncSuccess();
      _eventController.add(SyncEvent(type: SyncEventType.syncCompleted));
      _logger.info('Sync completed successfully');
    } catch (e, stackTrace) {
      _logger.error('Sync failed', e, stackTrace);
      _metrics.recordSyncFailure(e.toString());
      _eventController.add(SyncEvent(
        type: SyncEventType.syncFailed,
        error: e.toString(),
      ));
    } finally {
      _isSyncing = false;
    }
  }

  /// Push local changes to server
  Future<void> _pushSync() async {
    final operations = await _queueManager.getPendingOperations();

    _logger.info('Push sync: ${operations.length} pending operations');

    for (final operation in operations) {
      _logger.debug(
        'Processing: ${operation.operationType} ${operation.recordId} '
        '(retry: ${operation.retryCount})',
      );

      if (operation.retryCount >= _config.maxRetries) {
        _logger.warning('Max retries exceeded for ${operation.recordId}');
        await _queueManager.markAsFailed(operation.id, 'Max retries exceeded');
        _metrics.recordOperationFailed(
          operation.operationType,
          'Max retries exceeded',
        );
        _eventController.add(SyncEvent(
          type: SyncEventType.operationFailed,
          collectionName: operation.collectionName,
          recordId: operation.recordId,
          error: 'Max retries exceeded',
        ));
        continue;
      }

      try {
        await _queueManager.markAsSyncing(operation.id);

        final data = jsonDecode(operation.payload) as Map<String, dynamic>?;
        if (data == null) {
          throw FormatException('Invalid payload: null data');
        }

        // Execute operation with timeout
        await _executeSyncOperation(operation, data).timeout(
          _operationTimeout,
          onTimeout: () {
            throw TimeoutException(
              'Operation timed out after ${_operationTimeout.inSeconds}s',
            );
          },
        );

        await _queueManager.markAsSynced(operation.id);
        _logger.debug('Synced: ${operation.recordId}');
        _metrics.recordOperationSynced(operation.operationType);
        _eventController.add(SyncEvent(
          type: SyncEventType.operationSynced,
          collectionName: operation.collectionName,
          recordId: operation.recordId,
        ));
      } catch (e, stackTrace) {
        _logger.error('Sync failed for ${operation.recordId}', e, stackTrace);
        _metrics.recordOperationFailed(operation.operationType, e.toString());

        // Increment retry count
        await _queueManager.incrementRetryCount(operation.id);
        await _queueManager.markAsFailed(operation.id, e.toString());
        _eventController.add(SyncEvent(
          type: SyncEventType.operationFailed,
          collectionName: operation.collectionName,
          recordId: operation.recordId,
          error: e.toString(),
        ));
      }
    }
  }

  /// Execute a single sync operation
  Future<void> _executeSyncOperation(
    SyncOperation operation,
    Map<String, dynamic> data,
  ) async {
    switch (operation.operationType) {
      case 'insert':
      case 'update':
        _logger.debug('Pushing to backend: ${operation.recordId}');
        await _backendAdapter.push(
          collection: operation.collectionName,
          recordId: operation.recordId!,
          data: data,
          timestamp: operation.timestamp,
        );
        break;

      case 'delete':
        await _backendAdapter.delete(
          collection: operation.collectionName,
          recordId: operation.recordId!,
        );
        break;

      default:
        throw ArgumentError(
            'Unknown operation type: ${operation.operationType}');
    }
  }

  /// Pull remote changes from server with pagination
  Future<void> _pullSync() async {
    const int pageSize = 100; // Pull 100 records at a time

    try {
      // Get collections to sync: use configured collections if provided,
      // otherwise fall back to local collections
      List<String> collections;
      if (_config.collections.isNotEmpty) {
        collections = _config.collections;
        _logger.info('Pull sync: Using configured collections: $collections');
      } else {
        collections = await _localStorage.getAllCollections();
        _logger.info('Pull sync: Using local collections: $collections');
      }

      // If no collections found, skip pull sync
      if (collections.isEmpty) {
        _logger.warning('Pull sync: No collections to sync');
        return;
      }

      for (final collection in collections) {
        // Get sync filter for this collection
        final filter = _config.syncFilters[collection];

        // Get last sync timestamp for this collection
        final lastSyncTime = await _localStorage.getLastSyncTime(collection);

        // Use filter's since timestamp if provided, otherwise use last sync time
        final effectiveSince = filter?.since ?? lastSyncTime;

        _logger.info(
          'Pulling $collection since: ${effectiveSince ?? "beginning"}'
          '${filter != null ? " with filter: $filter" : ""}',
        );

        // Pull changes from backend with pagination
        int offset = 0;
        DateTime? latestTimestamp;
        int totalRecords = 0;

        while (true) {
          final remoteRecords = await _backendAdapter
              .pull(
            collection: collection,
            since: effectiveSince,
            limit: filter?.limit ?? pageSize,
            offset: offset,
            filter: filter,
          )
              .timeout(
            _operationTimeout,
            onTimeout: () {
              throw TimeoutException(
                'Pull operation timed out after ${_operationTimeout.inSeconds}s',
              );
            },
          );

          if (remoteRecords.isEmpty) {
            break; // No more records to pull
          }

          _logger.debug(
              'Received ${remoteRecords.length} records (offset: $offset)');
          totalRecords += remoteRecords.length;

          // Process each remote record and track latest timestamp
          for (final remoteRecord in remoteRecords) {
            // Apply local filtering if filter is specified
            if (filter != null) {
              // Check if record matches filter criteria
              if (!filter.matches(remoteRecord.data, remoteRecord.updatedAt)) {
                _logger.debug(
                    'Skipping record ${remoteRecord.recordId} - does not match filter');
                continue;
              }

              // Apply field filtering
              final filteredData = filter.applyFieldFilter(remoteRecord.data);
              final filteredRecord = SyncRecord(
                recordId: remoteRecord.recordId,
                data: filteredData,
                updatedAt: remoteRecord.updatedAt,
                version: remoteRecord.version,
              );
              await _processRemoteRecord(collection, filteredRecord);
            } else {
              await _processRemoteRecord(collection, remoteRecord);
            }

            // Track the latest updatedAt timestamp from pulled records
            if (latestTimestamp == null ||
                remoteRecord.updatedAt.isAfter(latestTimestamp)) {
              latestTimestamp = remoteRecord.updatedAt;
            }
          }

          // If we received fewer records than page size, we're done
          // Or if filter has a limit and we've reached it
          if (remoteRecords.length < pageSize ||
              (filter?.limit != null && totalRecords >= filter!.limit!)) {
            break;
          }

          offset += pageSize;
        }

        _logger.info('Total records pulled for $collection: $totalRecords');

        // Update last sync timestamp to the latest record timestamp (or now if no records)
        final syncTime = latestTimestamp ?? DateTime.now();
        await _localStorage.updateLastSyncTime(collection, syncTime);
        _logger.debug('Updated lastSyncTime for $collection to: $syncTime');
      }
    } catch (e, stackTrace) {
      _logger.error('Pull sync error', e, stackTrace);
      _eventController.add(SyncEvent(
        type: SyncEventType.syncFailed,
        error: 'Pull sync failed: ${e.toString()}',
      ));
      rethrow;
    }
  }

  /// Process a single remote record with conflict resolution
  Future<void> _processRemoteRecord(
    String collection,
    SyncRecord remoteRecord,
  ) async {
    // Get local version if exists
    final localRecord = await _localStorage.getData(
      collectionName: collection,
      recordId: remoteRecord.recordId,
    );

    if (localRecord == null) {
      // No local version, just save remote data
      await _localStorage.saveData(
        collectionName: collection,
        recordId: remoteRecord.recordId,
        data: jsonEncode(remoteRecord.data),
      );
      await _localStorage.markAsSynced(
        collectionName: collection,
        recordId: remoteRecord.recordId,
        version: remoteRecord.version,
        syncTime: remoteRecord.updatedAt,
      );
      return;
    }

    // Check for conflicts
    final hasConflict = _detectConflict(localRecord, remoteRecord);

    if (!hasConflict) {
      // No conflict, just update local data
      await _localStorage.saveData(
        collectionName: collection,
        recordId: remoteRecord.recordId,
        data: jsonEncode(remoteRecord.data),
      );
      await _localStorage.markAsSynced(
        collectionName: collection,
        recordId: remoteRecord.recordId,
        version: remoteRecord.version,
        syncTime: remoteRecord.updatedAt,
      );
      return;
    }

    // Conflict detected - use conflict resolver
    _metrics.recordConflictDetected(collection, remoteRecord.recordId);
    _eventController.add(SyncEvent(
      type: SyncEventType.conflictDetected,
      collectionName: collection,
      recordId: remoteRecord.recordId,
      metadata: {
        'localVersion': localRecord.version,
        'remoteVersion': remoteRecord.version,
      },
    ));

    final localData = jsonDecode(localRecord.data) as Map<String, dynamic>?;
    if (localData == null) {
      throw FormatException('Invalid local data: null');
    }

    final resolvedData = _conflictResolver.resolve(
      localData: localData,
      remoteData: remoteRecord.data,
      localTimestamp: localRecord.updatedAt,
      remoteTimestamp: remoteRecord.updatedAt,
    );

    // Save resolved data
    await _localStorage.saveData(
      collectionName: collection,
      recordId: remoteRecord.recordId,
      data: jsonEncode(resolvedData),
    );
    await _localStorage.markAsSynced(
      collectionName: collection,
      recordId: remoteRecord.recordId,
      version: remoteRecord.version + 1, // Increment version after merge
      syncTime: DateTime.now(),
    );

    _metrics.recordConflictResolved(collection, remoteRecord.recordId);
    _eventController.add(SyncEvent(
      type: SyncEventType.conflictResolved,
      collectionName: collection,
      recordId: remoteRecord.recordId,
    ));
  }

  /// Detect if there's a conflict between local and remote records
  bool _detectConflict(DataRecord localRecord, SyncRecord remoteRecord) {
    // If local is already synced and versions match, no conflict
    if (localRecord.isSynced && localRecord.version == remoteRecord.version) {
      return false;
    }

    // If versions differ, there's a conflict
    if (localRecord.version != remoteRecord.version) {
      return true;
    }

    // If local has been modified after last sync with a grace period
    // Grace period prevents false positives from modifications right after sync
    if (localRecord.lastSyncedAt != null) {
      final gracePeriod = Duration(seconds: 5);
      final modifiedAfterSync = localRecord.updatedAt
          .isAfter(localRecord.lastSyncedAt!.add(gracePeriod));

      if (modifiedAfterSync) {
        return true;
      }
    }

    return false;
  }

  /// Manual sync trigger
  Future<void> syncNow() async {
    await _performSync();
  }
}
