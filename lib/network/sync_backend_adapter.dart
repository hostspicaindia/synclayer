/// Abstract interface for backend sync adapters
/// This allows SyncLayer to work with different backends (REST, Firebase, Supabase, GraphQL)
abstract class SyncBackendAdapter {
  /// Push data to backend
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  });

  /// Pull data from backend with optional pagination
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
    int? limit,
    int? offset,
  });

  /// Delete data on backend
  Future<void> delete({
    required String collection,
    required String recordId,
  });

  /// Update authentication token
  void updateAuthToken(String token);
}

/// Sync record returned from backend
class SyncRecord {
  final String recordId;
  final Map<String, dynamic> data;
  final DateTime updatedAt;
  final int version;

  SyncRecord({
    required this.recordId,
    required this.data,
    required this.updatedAt,
    required this.version,
  });
}
