import 'dart:async';
import 'dart:convert';
import '../local/local_storage.dart';
import '../conflict/conflict_resolver.dart';
import '../core/sync_event.dart';
import '../utils/logger.dart';
import 'websocket_service.dart';

/// Real-time sync manager that handles WebSocket-based synchronization
class RealtimeSyncManager {
  final WebSocketService _websocketService;
  final LocalStorage _localStorage;
  final ConflictResolver _conflictResolver;
  final List<String> _collections;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _stateSubscription;
  final _logger = SyncLogger.instance;

  // Event bus for sync events
  final _eventController = StreamController<SyncEvent>.broadcast();

  RealtimeSyncManager({
    required WebSocketService websocketService,
    required LocalStorage localStorage,
    required ConflictResolver conflictResolver,
    required List<String> collections,
  })  : _websocketService = websocketService,
        _localStorage = localStorage,
        _conflictResolver = conflictResolver,
        _collections = collections;

  /// Stream of real-time sync events
  Stream<SyncEvent> get events => _eventController.stream;

  /// Check if real-time sync is active
  bool get isActive => _websocketService.isConnected;

  /// Start real-time sync
  Future<void> start() async {
    _logger.info('Starting real-time sync');

    // Connect to WebSocket
    await _websocketService.connect();

    // Listen to connection state changes
    _stateSubscription = _websocketService.onStateChanged.listen((state) {
      _logger.info('WebSocket state changed: $state');

      if (state == WebSocketState.connected) {
        // Subscribe to all collections
        for (final collection in _collections) {
          _websocketService.subscribe(collection);
          _logger.info('Subscribed to real-time updates: $collection');
        }

        _eventController.add(SyncEvent(
          type: SyncEventType.realtimeConnected,
          metadata: {'collections': _collections},
        ));
      } else if (state == WebSocketState.disconnected ||
          state == WebSocketState.error) {
        _eventController.add(SyncEvent(
          type: SyncEventType.realtimeDisconnected,
          metadata: {'state': state.name},
        ));
      }
    });

    // Listen to incoming messages
    _messageSubscription = _websocketService.onMessage.listen(_handleMessage);
  }

  /// Stop real-time sync
  Future<void> stop() async {
    _logger.info('Stopping real-time sync');

    // Unsubscribe from all collections
    for (final collection in _collections) {
      _websocketService.unsubscribe(collection);
    }

    await _messageSubscription?.cancel();
    await _stateSubscription?.cancel();
    await _websocketService.disconnect();
  }

  /// Handle incoming WebSocket message
  Future<void> _handleMessage(WebSocketMessage message) async {
    try {
      switch (message.type) {
        case MessageType.insert:
          await _handleInsert(message);
          break;
        case MessageType.update:
          await _handleUpdate(message);
          break;
        case MessageType.delete:
          await _handleDelete(message);
          break;
        case MessageType.sync:
          await _handleSync(message);
          break;
        default:
          _logger.debug('Unhandled message type: ${message.type}');
      }
    } catch (e, stackTrace) {
      _logger.error('Error handling real-time message', e, stackTrace);
      _eventController.add(SyncEvent(
        type: SyncEventType.error,
        error: e.toString(),
        metadata: {'messageType': message.type.name},
      ));
    }
  }

  /// Handle insert message from server
  Future<void> _handleInsert(WebSocketMessage message) async {
    if (message.collection == null ||
        message.recordId == null ||
        message.data == null) {
      _logger.warning('Invalid insert message - missing required fields');
      return;
    }

    _logger.info('Real-time insert: ${message.collection}/${message.recordId}');

    // Check if record already exists locally
    final existing = await _localStorage.getData(
      collectionName: message.collection!,
      recordId: message.recordId!,
    );

    if (existing != null) {
      // Record exists - handle as update with conflict resolution
      await _handleUpdate(message);
      return;
    }

    // Save new record to local storage
    await _localStorage.saveData(
      collectionName: message.collection!,
      recordId: message.recordId!,
      data: jsonEncode(message.data),
    );

    // Mark as synced since it came from server
    await _localStorage.markAsSynced(
      collectionName: message.collection!,
      recordId: message.recordId!,
      version: message.metadata?['version'] ?? 1,
      syncTime: message.timestamp ?? DateTime.now(),
    );

    _eventController.add(SyncEvent(
      type: SyncEventType.realtimeInsert,
      collectionName: message.collection,
      recordId: message.recordId,
      metadata: {'data': message.data},
    ));
  }

  /// Handle update message from server
  Future<void> _handleUpdate(WebSocketMessage message) async {
    if (message.collection == null ||
        message.recordId == null ||
        message.data == null) {
      _logger.warning('Invalid update message - missing required fields');
      return;
    }

    _logger.info('Real-time update: ${message.collection}/${message.recordId}');

    // Get local record
    final localRecord = await _localStorage.getData(
      collectionName: message.collection!,
      recordId: message.recordId!,
    );

    if (localRecord == null) {
      // Record doesn't exist locally - treat as insert
      await _handleInsert(message);
      return;
    }

    // Check if local record has unsaved changes
    if (!localRecord.isSynced) {
      _logger.info('Conflict detected - local changes not synced');

      // Resolve conflict
      final localData = jsonDecode(localRecord.data) as Map<String, dynamic>;
      final remoteData = message.data!;

      final resolved = _conflictResolver.resolve(
        localData: localData,
        remoteData: remoteData,
        localTimestamp: localRecord.updatedAt,
        remoteTimestamp: message.timestamp ?? DateTime.now(),
      );

      // Save resolved data
      await _localStorage.saveData(
        collectionName: message.collection!,
        recordId: message.recordId!,
        data: jsonEncode(resolved),
      );

      _eventController.add(SyncEvent(
        type: SyncEventType.conflictResolved,
        collectionName: message.collection,
        recordId: message.recordId,
        metadata: {
          'strategy': _conflictResolver.strategy.name,
          'localData': localData,
          'remoteData': remoteData,
          'resolvedData': resolved,
        },
      ));
    } else {
      // No conflict - apply remote changes
      await _localStorage.saveData(
        collectionName: message.collection!,
        recordId: message.recordId!,
        data: jsonEncode(message.data),
      );
    }

    // Mark as synced
    await _localStorage.markAsSynced(
      collectionName: message.collection!,
      recordId: message.recordId!,
      version: message.metadata?['version'] ?? localRecord.version + 1,
      syncTime: message.timestamp ?? DateTime.now(),
    );

    _eventController.add(SyncEvent(
      type: SyncEventType.realtimeUpdate,
      collectionName: message.collection,
      recordId: message.recordId,
      metadata: {'data': message.data},
    ));
  }

  /// Handle delete message from server
  Future<void> _handleDelete(WebSocketMessage message) async {
    if (message.collection == null || message.recordId == null) {
      _logger.warning('Invalid delete message - missing required fields');
      return;
    }

    _logger.info('Real-time delete: ${message.collection}/${message.recordId}');

    // Delete from local storage
    await _localStorage.deleteData(
      collectionName: message.collection!,
      recordId: message.recordId!,
    );

    _eventController.add(SyncEvent(
      type: SyncEventType.realtimeDelete,
      collectionName: message.collection,
      recordId: message.recordId,
    ));
  }

  /// Handle full sync message from server
  Future<void> _handleSync(WebSocketMessage message) async {
    if (message.collection == null || message.data == null) {
      _logger.warning('Invalid sync message - missing required fields');
      return;
    }

    _logger.info('Real-time full sync: ${message.collection}');

    final records = message.data!['records'] as List<dynamic>?;
    if (records == null) return;

    for (final record in records) {
      final recordMap = record as Map<String, dynamic>;
      await _localStorage.saveData(
        collectionName: message.collection!,
        recordId: recordMap['id'],
        data: jsonEncode(recordMap['data']),
      );

      await _localStorage.markAsSynced(
        collectionName: message.collection!,
        recordId: recordMap['id'],
        version: recordMap['version'] ?? 1,
        syncTime: DateTime.parse(recordMap['updatedAt']),
      );
    }

    _eventController.add(SyncEvent(
      type: SyncEventType.realtimeSync,
      collectionName: message.collection,
      metadata: {'recordCount': records.length},
    ));
  }

  /// Send local change to server via WebSocket
  void sendChange({
    required MessageType type,
    required String collection,
    required String recordId,
    Map<String, dynamic>? data,
  }) {
    if (!isActive) {
      _logger.warning('Cannot send change - real-time sync not active');
      return;
    }

    _websocketService.send(WebSocketMessage(
      type: type,
      collection: collection,
      recordId: recordId,
      data: data,
      timestamp: DateTime.now(),
    ));
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stop();
    await _eventController.close();
  }
}
