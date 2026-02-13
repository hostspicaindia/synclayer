/// Event types emitted during sync operations.
///
/// These events allow you to monitor the sync lifecycle, track operations,
/// detect conflicts, and respond to connectivity changes.
///
/// Example:
/// ```dart
/// SyncLayerCore.instance.syncEngine.events.listen((event) {
///   switch (event.type) {
///     case SyncEventType.syncStarted:
///       print('Sync started');
///       break;
///     case SyncEventType.syncCompleted:
///       print('Sync completed successfully');
///       break;
///     case SyncEventType.syncFailed:
///       print('Sync failed: ${event.error}');
///       break;
///     case SyncEventType.conflictDetected:
///       print('Conflict in ${event.collectionName}/${event.recordId}');
///       break;
///   }
/// });
/// ```
enum SyncEventType {
  /// Emitted when a sync cycle starts.
  ///
  /// A sync cycle includes both push (local → backend) and
  /// pull (backend → local) operations.
  syncStarted,

  /// Emitted when a sync cycle completes successfully.
  ///
  /// This means all pending operations were synced and all
  /// remote changes were pulled and merged.
  syncCompleted,

  /// Emitted when a sync cycle fails.
  ///
  /// The event will include an error message in the [SyncEvent.error] field.
  syncFailed,

  /// Emitted when a new operation is added to the sync queue.
  ///
  /// This happens when you call save() or delete() on a collection.
  operationQueued,

  /// Emitted when an operation is successfully synced to the backend.
  ///
  /// The operation is removed from the queue after this event.
  operationSynced,

  /// Emitted when an operation fails to sync after max retries.
  ///
  /// The operation remains in the queue with 'failed' status and
  /// will be retried when connectivity is restored.
  operationFailed,

  /// Emitted when a conflict is detected during pull sync.
  ///
  /// A conflict occurs when the same document was modified on both
  /// the local device and the backend since the last sync.
  conflictDetected,

  /// Emitted after a conflict is resolved.
  ///
  /// The event metadata will include information about which version
  /// won based on the configured conflict resolution strategy.
  conflictResolved,

  /// Emitted when network connectivity changes.
  ///
  /// The event metadata will include an 'isOnline' boolean indicating
  /// the current connectivity status.
  connectivityChanged,
}

/// Event emitted during sync operations.
///
/// Events provide visibility into the sync lifecycle and allow you to
/// build features like sync status indicators, conflict notifications,
/// and error handling.
///
/// Example:
/// ```dart
/// // Listen to all sync events
/// SyncLayerCore.instance.syncEngine.events.listen((event) {
///   print('Event: ${event.type}');
///   print('Collection: ${event.collectionName}');
///   print('Record: ${event.recordId}');
///   print('Time: ${event.timestamp}');
///
///   if (event.error != null) {
///     print('Error: ${event.error}');
///   }
///
///   if (event.metadata != null) {
///     print('Metadata: ${event.metadata}');
///   }
/// });
/// ```
class SyncEvent {
  /// The type of event that occurred.
  final SyncEventType type;

  /// The collection name associated with this event, if applicable.
  ///
  /// Will be null for global events like [SyncEventType.syncStarted].
  final String? collectionName;

  /// The record ID associated with this event, if applicable.
  ///
  /// Will be null for collection-level or global events.
  final String? recordId;

  /// Additional metadata about the event.
  ///
  /// Contents vary by event type:
  /// - conflictDetected: includes 'localVersion', 'remoteVersion'
  /// - conflictResolved: includes 'strategy', 'winner'
  /// - connectivityChanged: includes 'isOnline'
  final Map<String, dynamic>? metadata;

  /// When the event occurred.
  final DateTime timestamp;

  /// Error message if the event represents a failure.
  ///
  /// Only populated for [SyncEventType.syncFailed] and
  /// [SyncEventType.operationFailed] events.
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
