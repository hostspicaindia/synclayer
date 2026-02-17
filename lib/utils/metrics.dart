/// Metrics and telemetry for SyncLayer SDK
///
/// Tracks sync performance, success rates, and error patterns.
class SyncMetrics {
  static SyncMetrics? _instance;
  static void Function(SyncMetricEvent event)? _customMetricsHandler;

  // Counters
  int _syncAttempts = 0;
  int _syncSuccesses = 0;
  int _syncFailures = 0;
  int _conflictsDetected = 0;
  int _conflictsResolved = 0;
  int _operationsQueued = 0;
  int _operationsSynced = 0;
  int _operationsFailed = 0;

  // Timing
  final List<Duration> _syncDurations = [];
  DateTime? _lastSyncStartTime;
  DateTime? _lastSyncEndTime;

  // Error tracking
  final Map<String, int> _errorCounts = {};

  SyncMetrics._();

  static SyncMetrics get instance {
    _instance ??= SyncMetrics._();
    return _instance!;
  }

  /// Set custom metrics handler
  ///
  /// Example:
  /// ```dart
  /// SyncMetrics.setCustomHandler((event) {
  ///   analytics.track(event.type, event.data);
  /// });
  /// ```
  static void setCustomHandler(void Function(SyncMetricEvent event)? handler) {
    _customMetricsHandler = handler;
  }

  /// Record sync attempt
  void recordSyncAttempt() {
    _syncAttempts++;
    _lastSyncStartTime = DateTime.now();
    _emitEvent(SyncMetricEvent(
      type: 'sync_attempt',
      data: {'total_attempts': _syncAttempts},
    ));
  }

  /// Record sync success
  void recordSyncSuccess() {
    _syncSuccesses++;
    _lastSyncEndTime = DateTime.now();

    if (_lastSyncStartTime != null) {
      final duration = _lastSyncEndTime!.difference(_lastSyncStartTime!);
      _syncDurations.add(duration);

      // Keep only last 100 durations
      if (_syncDurations.length > 100) {
        _syncDurations.removeAt(0);
      }
    }

    _emitEvent(SyncMetricEvent(
      type: 'sync_success',
      data: {
        'total_successes': _syncSuccesses,
        'success_rate': successRate,
        'duration_ms': _syncDurations.isNotEmpty
            ? _syncDurations.last.inMilliseconds
            : null,
      },
    ));
  }

  /// Record sync failure
  void recordSyncFailure(String error) {
    _syncFailures++;
    _errorCounts[error] = (_errorCounts[error] ?? 0) + 1;

    _emitEvent(SyncMetricEvent(
      type: 'sync_failure',
      data: {
        'total_failures': _syncFailures,
        'success_rate': successRate,
        'error': error,
      },
    ));
  }

  /// Record conflict detected
  void recordConflictDetected(String collection, String recordId) {
    _conflictsDetected++;
    _emitEvent(SyncMetricEvent(
      type: 'conflict_detected',
      data: {
        'total_conflicts': _conflictsDetected,
        'collection': collection,
        'record_id': recordId,
      },
    ));
  }

  /// Record conflict resolved
  void recordConflictResolved(String collection, String recordId) {
    _conflictsResolved++;
    _emitEvent(SyncMetricEvent(
      type: 'conflict_resolved',
      data: {
        'total_resolved': _conflictsResolved,
        'collection': collection,
        'record_id': recordId,
      },
    ));
  }

  /// Record operation queued
  void recordOperationQueued(String operationType) {
    _operationsQueued++;
    _emitEvent(SyncMetricEvent(
      type: 'operation_queued',
      data: {
        'total_queued': _operationsQueued,
        'operation_type': operationType,
      },
    ));
  }

  /// Record operation synced
  void recordOperationSynced(String operationType) {
    _operationsSynced++;
    _emitEvent(SyncMetricEvent(
      type: 'operation_synced',
      data: {
        'total_synced': _operationsSynced,
        'operation_type': operationType,
      },
    ));
  }

  /// Record operation failed
  void recordOperationFailed(String operationType, String error) {
    _operationsFailed++;
    _errorCounts[error] = (_errorCounts[error] ?? 0) + 1;

    _emitEvent(SyncMetricEvent(
      type: 'operation_failed',
      data: {
        'total_failed': _operationsFailed,
        'operation_type': operationType,
        'error': error,
      },
    ));
  }

  /// Get current metrics snapshot
  SyncMetricsSnapshot getSnapshot() {
    return SyncMetricsSnapshot(
      syncAttempts: _syncAttempts,
      syncSuccesses: _syncSuccesses,
      syncFailures: _syncFailures,
      successRate: successRate,
      averageSyncDuration: averageSyncDuration,
      conflictsDetected: _conflictsDetected,
      conflictsResolved: _conflictsResolved,
      operationsQueued: _operationsQueued,
      operationsSynced: _operationsSynced,
      operationsFailed: _operationsFailed,
      topErrors: topErrors,
      lastSyncTime: _lastSyncEndTime,
    );
  }

  /// Reset all metrics
  void reset() {
    _syncAttempts = 0;
    _syncSuccesses = 0;
    _syncFailures = 0;
    _conflictsDetected = 0;
    _conflictsResolved = 0;
    _operationsQueued = 0;
    _operationsSynced = 0;
    _operationsFailed = 0;
    _syncDurations.clear();
    _errorCounts.clear();
    _lastSyncStartTime = null;
    _lastSyncEndTime = null;
  }

  /// Success rate (0.0 to 1.0)
  double get successRate {
    if (_syncAttempts == 0) return 0.0;
    return _syncSuccesses / _syncAttempts;
  }

  /// Average sync duration
  Duration? get averageSyncDuration {
    if (_syncDurations.isEmpty) return null;
    final totalMs = _syncDurations.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    return Duration(milliseconds: totalMs ~/ _syncDurations.length);
  }

  /// Top 5 most common errors
  List<MapEntry<String, int>> get topErrors {
    final entries = _errorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  void _emitEvent(SyncMetricEvent event) {
    _customMetricsHandler?.call(event);
  }
}

/// Metrics snapshot
class SyncMetricsSnapshot {
  final int syncAttempts;
  final int syncSuccesses;
  final int syncFailures;
  final double successRate;
  final Duration? averageSyncDuration;
  final int conflictsDetected;
  final int conflictsResolved;
  final int operationsQueued;
  final int operationsSynced;
  final int operationsFailed;
  final List<MapEntry<String, int>> topErrors;
  final DateTime? lastSyncTime;

  SyncMetricsSnapshot({
    required this.syncAttempts,
    required this.syncSuccesses,
    required this.syncFailures,
    required this.successRate,
    required this.averageSyncDuration,
    required this.conflictsDetected,
    required this.conflictsResolved,
    required this.operationsQueued,
    required this.operationsSynced,
    required this.operationsFailed,
    required this.topErrors,
    required this.lastSyncTime,
  });

  @override
  String toString() {
    return '''
SyncMetrics:
  Sync Attempts: $syncAttempts
  Sync Successes: $syncSuccesses
  Sync Failures: $syncFailures
  Success Rate: ${(successRate * 100).toStringAsFixed(1)}%
  Average Duration: ${averageSyncDuration?.inMilliseconds ?? 0}ms
  Conflicts Detected: $conflictsDetected
  Conflicts Resolved: $conflictsResolved
  Operations Queued: $operationsQueued
  Operations Synced: $operationsSynced
  Operations Failed: $operationsFailed
  Last Sync: ${lastSyncTime ?? 'Never'}
''';
  }
}

/// Metric event
class SyncMetricEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  SyncMetricEvent({
    required this.type,
    required this.data,
  }) : timestamp = DateTime.now();
}
