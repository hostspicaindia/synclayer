/// Event types for sync operations
enum SyncEventType {
  syncStarted,
  syncCompleted,
  syncFailed,
  operationQueued,
  operationSynced,
  operationFailed,
  conflictDetected,
  conflictResolved,
  connectivityChanged,
}

/// Event emitted during sync operations
class SyncEvent {
  final SyncEventType type;
  final String? collectionName;
  final String? recordId;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final String? error;

  SyncEvent({
    required this.type,
    this.collectionName,
    this.recordId,
    this.metadata,
    String? error,
  })  : timestamp = DateTime.now(),
        error = error;

  @override
  String toString() {
    return 'SyncEvent(type: $type, collection: $collectionName, recordId: $recordId, timestamp: $timestamp)';
  }
}
