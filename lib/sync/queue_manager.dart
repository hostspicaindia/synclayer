import 'dart:convert';
import '../local/local_storage.dart';
import '../local/local_models.dart';
import '../core/sync_event.dart';

/// Manages sync operation queue
class QueueManager {
  final LocalStorage _localStorage;
  final void Function(SyncEvent)? _onEvent;

  QueueManager(this._localStorage, {void Function(SyncEvent)? onEvent})
      : _onEvent = onEvent;

  /// Add insert operation to queue
  Future<void> queueInsert({
    required String collectionName,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    final operation = SyncOperation()
      ..collectionName = collectionName
      ..operationType = 'insert'
      ..payload = jsonEncode(data)
      ..timestamp = DateTime.now()
      ..status = 'pending'
      ..recordId = recordId;

    await _localStorage.addToSyncQueue(operation);

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
    final operation = SyncOperation()
      ..collectionName = collectionName
      ..operationType = 'update'
      ..payload = jsonEncode(data)
      ..timestamp = DateTime.now()
      ..status = 'pending'
      ..recordId = recordId;

    await _localStorage.addToSyncQueue(operation);

    // Emit event
    _onEvent?.call(SyncEvent(
      type: SyncEventType.operationQueued,
      collectionName: collectionName,
      recordId: recordId,
      metadata: {'operationType': 'update'},
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
