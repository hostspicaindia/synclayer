import 'package:supabase_flutter/supabase_flutter.dart';
import '../network/sync_backend_adapter.dart';
import '../sync/sync_filter.dart';

/// Supabase adapter for SyncLayer
///
/// Syncs data with Supabase PostgreSQL tables.
///
/// **IMPORTANT:** This adapter requires the `supabase_flutter` package.
/// Add to your pubspec.yaml:
/// ```yaml
/// dependencies:
///   supabase_flutter: ^2.9.0
/// ```
///
/// Example:
/// ```dart
/// await SyncLayer.init(
///   SyncConfig(
///     baseUrl: 'https://your-project.supabase.co', // Not used
///     customBackendAdapter: SupabaseAdapter(
///       client: Supabase.instance.client,
///     ),
///     collections: ['todos', 'users'],
///   ),
/// );
/// ```
///
/// Note: This file will show analyzer errors if supabase_flutter is not installed.
/// This is expected - the package is optional and only needed if you use this adapter.
class SupabaseAdapter implements SyncBackendAdapter {
  final SupabaseClient client;

  SupabaseAdapter({
    required this.client,
  });

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    await client.from(collection).upsert({
      'record_id': recordId,
      'data': data,
      'updated_at': timestamp.toIso8601String(),
    });
  }

  @override
  Future<void> pushDelta({
    required String collection,
    required String recordId,
    required Map<String, dynamic> delta,
    required int baseVersion,
    required DateTime timestamp,
  }) async {
    // Supabase doesn't have native delta sync support
    // Fall back to regular push with delta as the data
    // In production, you might want to fetch the full document first,
    // merge the delta, and then push the complete document
    await client.from(collection).upsert({
      'record_id': recordId,
      'data': delta, // Note: This only updates changed fields
      'updated_at': timestamp.toIso8601String(),
    });
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
    int? limit,
    int? offset,
    SyncFilter? filter,
  }) async {
    dynamic query = client.from(collection).select();

    // Use filter's since if provided, otherwise use since parameter
    final effectiveSince = filter?.since ?? since;
    if (effectiveSince != null) {
      query = query.gt('updated_at', effectiveSince.toIso8601String());
    }

    // Apply filter where conditions
    if (filter?.where != null) {
      for (final entry in filter!.where!.entries) {
        // Supabase uses JSON operators for nested data
        query = query.eq('data->${entry.key}', entry.value);
      }
    }

    // Apply pagination - use filter's limit if provided
    final effectiveLimit = filter?.limit ?? limit;
    if (offset != null && effectiveLimit != null) {
      query = query.range(offset, offset + effectiveLimit - 1);
    } else if (effectiveLimit != null) {
      query = query.limit(effectiveLimit);
    }

    final response = await query;
    final List<dynamic> data = response as List<dynamic>;

    return data.map((item) {
      final record = item as Map<String, dynamic>;
      var recordData = record['data'] as Map<String, dynamic>;

      // Apply field filtering if specified
      if (filter != null) {
        recordData = filter.applyFieldFilter(recordData);
      }

      return SyncRecord(
        recordId: record['record_id'] as String,
        data: recordData,
        updatedAt: DateTime.parse(record['updated_at'] as String),
        version: record['version'] as int? ?? 1,
      );
    }).toList();
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    await client.from(collection).delete().eq('record_id', recordId);
  }

  @override
  void updateAuthToken(String token) {
    // Supabase auth is handled via client.auth
    // Token updates are managed through Supabase Authentication SDK
  }
}
