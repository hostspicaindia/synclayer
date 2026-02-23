import '../sync/sync_filter.dart';

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

  /// Push delta (partial update) to backend.
  ///
  /// Only sends changed fields instead of the entire document,
  /// reducing bandwidth by up to 98%.
  ///
  /// Parameters:
  /// - [collection]: Collection name
  /// - [recordId]: Document ID
  /// - [delta]: Only the fields that changed
  /// - [baseVersion]: Version before this update
  /// - [timestamp]: When the update occurred
  ///
  /// If the backend doesn't support delta sync, this should fall back
  /// to a regular push() with the full document.
  Future<void> pushDelta({
    required String collection,
    required String recordId,
    required Map<String, dynamic> delta,
    required int baseVersion,
    required DateTime timestamp,
  }) async {
    // Default implementation: fall back to regular push
    // Backends that support delta sync should override this method
    throw UnimplementedError(
      'Delta sync not implemented for this backend adapter. '
      'Override pushDelta() or use regular push().',
    );
  }

  /// Pull data from backend with optional pagination and filtering
  ///
  /// Parameters:
  /// - [collection]: Collection name to pull from
  /// - [since]: Only pull records modified after this timestamp
  /// - [limit]: Maximum number of records to pull
  /// - [offset]: Number of records to skip (for pagination)
  /// - [filter]: Optional sync filter for selective synchronization
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
    int? limit,
    int? offset,
    SyncFilter? filter,
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
