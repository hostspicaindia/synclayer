// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist, undefined_class, undefined_identifier, undefined_method
import 'package:supabase_flutter/supabase_flutter.dart';
import '../network/sync_backend_adapter.dart';

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
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
  }) async {
    PostgrestFilterBuilder query = client.from(collection).select();

    if (since != null) {
      query = query.gt('updated_at', since.toIso8601String());
    }

    final response = await query;
    final List<dynamic> data = response as List<dynamic>;

    return data.map((item) {
      final record = item as Map<String, dynamic>;
      return SyncRecord(
        recordId: record['record_id'] as String,
        data: record['data'] as Map<String, dynamic>,
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
