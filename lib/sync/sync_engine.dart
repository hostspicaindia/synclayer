import 'dart:async';
import 'dart:convert';
import '../local/local_storage.dart';
import '../local/local_models.dart';
import '../network/sync_backend_adapter.dart';
import '../utils/connectivity_service.dart';
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
      print('🔄 Reset failed operations to retry');
    } catch (e) {
      print('❌ Error resetting failed operations: $e');
    }
  }

  /// Stop sync engine
  Future<void> stop() async {
    _isRunning = false;
    _syncTimer?.cancel();
    await _connectivitySubscription?.cancel();
    await _eventController.close();
  }

  /// Perform full sync (push then pull)
  Future<void> _performSync() async {
    if (!_connectivityService.isOnline) return;

    // Prevent concurrent sync operations
    if (_isSyncing) return;

    _isSyncing = true;
    _eventController.add(SyncEvent(type: SyncEventType.syncStarted));

    try {
      await _pushSync();
      await _pullSync();
      _eventController.add(SyncEvent(type: SyncEventType.syncCompleted));
    } catch (e) {
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

    print('🔄 Push sync: ${operations.length} pending operations');

    for (final operation in operations) {
      print(
          '📤 Processing: ${operation.operationType} ${operation.recordId} (retry: ${operation.retryCount})');

      if (operation.retryCount >= _config.maxRetries) {
        print('❌ Max retries exceeded for ${operation.recordId}');
        await _queueManager.markAsFailed(operation.id, 'Max retries exceeded');
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

        final data = jsonDecode(operation.payload) as Map<String, dynamic>;

        switch (operation.operationType) {
          case 'insert':
          case 'update':
            print('📡 Pushing to backend: ${operation.recordId}');
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
        }

        await _queueManager.markAsSynced(operation.id);
        print('✅ Synced: ${operation.recordId}');
        _eventController.add(SyncEvent(
          type: SyncEventType.operationSynced,
          collectionName: operation.collectionName,
          recordId: operation.recordId,
        ));
      } catch (e) {
        print('❌ Sync failed for ${operation.recordId}: $e');
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

  /// Pull remote changes from server
  Future<void> _pullSync() async {
    try {
      // Get collections to sync: use configured collections if provided,
      // otherwise fall back to local collections
      List<String> collections;
      if (_config.collections.isNotEmpty) {
        collections = _config.collections;
        print('📥 Pull sync: Using configured collections: $collections');
      } else {
        collections = await _localStorage.getAllCollections();
        print('📥 Pull sync: Using local collections: $collections');
      }

      // If no collections found, skip pull sync
      if (collections.isEmpty) {
        print('⚠️ Pull sync: No collections to sync');
        return;
      }

      for (final collection in collections) {
        // Get last sync timestamp for this collection
        final lastSyncTime = await _localStorage.getLastSyncTime(collection);

        print('📥 Pulling $collection since: ${lastSyncTime ?? "beginning"}');

        // Pull changes from backend since last sync
        final remoteRecords = await _backendAdapter.pull(
          collection: collection,
          since: lastSyncTime,
        );

        print('📥 Received ${remoteRecords.length} records from $collection');

        // Process each remote record and track latest timestamp
        DateTime? latestTimestamp;
        for (final remoteRecord in remoteRecords) {
          await _processRemoteRecord(collection, remoteRecord);
          print('✅ Processed remote record: ${remoteRecord.recordId}');

          // Track the latest updatedAt timestamp from pulled records
          if (latestTimestamp == null ||
              remoteRecord.updatedAt.isAfter(latestTimestamp)) {
            latestTimestamp = remoteRecord.updatedAt;
          }
        }

        // Update last sync timestamp to the latest record timestamp (or now if no records)
        final syncTime = latestTimestamp ?? DateTime.now();
        await _localStorage.updateLastSyncTime(collection, syncTime);
        print('📥 Updated lastSyncTime for $collection to: $syncTime');
      }
    } catch (e) {
      print('❌ Pull sync error: $e');
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
    _eventController.add(SyncEvent(
      type: SyncEventType.conflictDetected,
      collectionName: collection,
      recordId: remoteRecord.recordId,
      metadata: {
        'localVersion': localRecord.version,
        'remoteVersion': remoteRecord.version,
      },
    ));

    final localData = jsonDecode(localRecord.data) as Map<String, dynamic>;
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

    // If local has been modified after last sync, there's a potential conflict
    if (localRecord.lastSyncedAt != null &&
        localRecord.updatedAt.isAfter(localRecord.lastSyncedAt!)) {
      return true;
    }

    // If versions differ, there's a conflict
    if (localRecord.version != remoteRecord.version) {
      return true;
    }

    return false;
  }

  /// Manual sync trigger
  Future<void> syncNow() async {
    await _performSync();
  }
}
