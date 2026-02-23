import 'dart:async';
import 'dart:convert';
import '../local/local_storage.dart';
import '../local/local_models.dart';
import '../utils/metrics.dart';
import '../core/sync_event.dart';

/// Manages sync operation queue
class QueueManager {
  final LocalStorage _localStorage;
  final void Function(SyncEvent)? _onEvent;
  final _metrics = SyncMetrics.instance;

  QueueManager(this._localStorage, {void Function(SyncEvent)? onEvent})
      : _onEvent = onEvent;

  /// Validate that data is JSON-serializable
  bool _isJsonSerializable(Map<String, dynamic> data) {
    try {
      jsonEncode(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Add multiple insert operations to queue in a batch
  Future<void> queueInsertBatch({
    required String collectionName,
    required List<Map<String, dynamic>> items,
  }) async {
    final operations = <SyncOperation>[];

    for (final item in items) {
      if (!_isJsonSerializable(item['data'])) {
        throw ArgumentError(
          'Data for record ${item['recordId']} is not JSON-serializable',
        );
      }

      final operation = SyncOperation()
        ..collectionName = collectionName
        ..operationType = 'insert'
        ..payload = jsonEncode(item['data'])
        ..timestamp = DateTime.now()
        ..status = 'pending'
        ..recordId = item['recordId'];

      operations.add(operation);
    }

    await _localStorage.addToSyncQueueBatch(operations);

    // Emit events for all operations
    for (final op in operations) {
      _onEvent?.call(SyncEvent(
        type: SyncEventType.operationQueued,
        collectionName: collectionName,
        recordId: op.recordId,
        metadata: {'operationType': 'insert'},
      ));
    }
  }

  /// Add insert operation to queue
  Future<void> queueInsert({
    required String collectionName,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    if (!_isJsonSerializable(data)) {
      throw ArgumentError(
        'Data is not JSON-serializable. Ensure all values are primitive types, '
        'Lists, or Maps containing JSON-serializable values.',
      );
    }

    final operation = SyncOperation()
      ..collectionName = collectionName
      ..operationType = 'insert'
      ..payload = jsonEncode(data)
      ..timestamp = DateTime.now()
      ..status = 'pending'
      ..recordId = recordId;

    await _localStorage.addToSyncQueue(operation);

    _metrics.recordOperationQueued('insert');

    // Emit event
    _onEvent?.call(SyncEvent(
      type: SyncEventType.operationQueued,
      collectionName: collectionName,
      recordId: recordId,
      metadata: {'operationType': 'insert'},
    ));
  }

  /// Add update operation to queue
  Future<void> queueUpdate({
    required String collectionName,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    if (!_isJsonSerializable(data)) {
      throw ArgumentError(
        'Data is not JSON-serializable. Ensure all values are primitive types, '
        'Lists, or Maps containing JSON-serializable values.',
      );
    }

    final operation = SyncOperation()
      ..collectionName = collectionName
      ..operationType = 'update'
      ..payload = jsonEncode(data)
      ..timestamp = DateTime.now()
      ..status = 'pending'
      ..recordId = recordId;

    await _localStorage.addToSyncQueue(operation);

    _metrics.recordOperationQueued('update');

    // Emit event
    _onEvent?.call(SyncEvent(
      type: SyncEventType.operationQueued,
      collectionName: collectionName,
      recordId: recordId,
      metadata: {'operationType': 'update'},
    ));
  }

  /// Add delta update operation to queue (partial update).
  ///
  /// Delta updates only sync changed fields, reducing bandwidth by up to 98%.
  ///
  /// Parameters:
  /// - [collectionName]: The collection name
  /// - [recordId]: The document ID
  /// - [delta]: Only the fields that changed
  /// - [baseVersion]: The version before this update
  ///
  /// Example:
  /// ```dart
  /// await queueDeltaUpdate(
  ///   collectionName: 'todos',
  ///   recordId: '123',
  ///   delta: {'done': true},  // Only this field changed
  ///   baseVersion: 5,
  /// );
  /// ```
  Future<void> queueDeltaUpdate({
    required String collectionName,
    required String recordId,
    required Map<String, dynamic> delta,
    required int baseVersion,
  }) async {
    if (!_isJsonSerializable(delta)) {
      throw ArgumentError(
        'Delta is not JSON-serializable. Ensure all values are primitive types, '
        'Lists, or Maps containing JSON-serializable values.',
      );
    }

    // Store delta with metadata
    final payload = {
      'delta': delta,
      'baseVersion': baseVersion,
      'isDelta': true,
    };

    final operation = SyncOperation()
      ..collectionName = collectionName
      ..operationType = 'delta_update'
      ..payload = jsonEncode(payload)
      ..timestamp = DateTime.now()
      ..status = 'pending'
      ..recordId = recordId;

    await _localStorage.addToSyncQueue(operation);

    _metrics.recordOperationQueued('delta_update');

    // Emit event
    _onEvent?.call(SyncEvent(
      type: SyncEventType.operationQueued,
      collectionName: collectionName,
      recordId: recordId,
      metadata: {
        'operationType': 'delta_update',
        'fieldsChanged': delta.keys.length,
      },
    ));
  }

  /// Add delete operation to queue
  Future<void> queueDelete({
    required String collectionName,
    required String recordId,
  }) async {
    final operation = SyncOperation()
      ..collectionName = collectionName
      ..operationType = 'delete'
      ..payload = jsonEncode({'recordId': recordId})
      ..timestamp = DateTime.now()
      ..status = 'pending'
      ..recordId = recordId;

    await _localStorage.addToSyncQueue(operation);

    _metrics.recordOperationQueued('delete');

    // Emit event
    _onEvent?.call(SyncEvent(
      type: SyncEventType.operationQueued,
      collectionName: collectionName,
      recordId: recordId,
      metadata: {'operationType': 'delete'},
    ));
  }

  /// Get all pending operations
  Future<List<SyncOperation>> getPendingOperations() async {
    return await _localStorage.getPendingSyncOperations();
  }

  /// Mark operation as syncing
  Future<void> markAsSyncing(int operationId) async {
    await _localStorage.updateSyncOperationStatus(
      operationId: operationId,
      status: 'syncing',
    );
  }

  /// Mark operation as synced
  Future<void> markAsSynced(int operationId) async {
    await _localStorage.updateSyncOperationStatus(
      operationId: operationId,
      status: 'synced',
    );
  }

  /// Mark operation as failed
  Future<void> markAsFailed(int operationId, String error) async {
    await _localStorage.updateSyncOperationStatus(
      operationId: operationId,
      status: 'failed',
      errorMessage: error,
    );
  }

  /// Increment retry count for an operation
  Future<void> incrementRetryCount(int operationId) async {
    await _localStorage.incrementOperationRetryCount(operationId);
  }

  /// Reset failed operations to pending (for retry after reconnect)
  Future<void> resetFailedOperations() async {
    final failedOps = await _localStorage.getFailedSyncOperations();
    for (final op in failedOps) {
      await _localStorage.updateSyncOperationStatus(
        operationId: op.id,
        status: 'pending',
      );
      // Reset retry count
      await _localStorage.resetOperationRetryCount(op.id);
    }
  }
}
