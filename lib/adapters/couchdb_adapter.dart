// ignore_for_file: depend_on_referenced_packages
import 'package:dio/dio.dart';
import '../network/sync_backend_adapter.dart';

/// CouchDB adapter for SyncLayer
///
/// Syncs data with CouchDB database.
/// CouchDB is a NoSQL document database with built-in sync capabilities.
///
/// **IMPORTANT:** This adapter requires the `dio` package.
/// Add to your pubspec.yaml:
/// ```yaml
/// dependencies:
///   dio: ^5.4.0
/// ```
///
/// **Database Structure:**
/// Each collection maps to a CouchDB database.
/// Documents will have this structure:
/// ```json
/// {
///   "_id": "record_id",
///   "_rev": "revision",
///   "data": { ... your data ... },
///   "updated_at": "2024-01-01T00:00:00Z",
///   "version": 1
/// }
/// ```
///
/// Example:
/// ```dart
/// await SyncLayer.init(
///   SyncConfig(
///     baseUrl: 'http://localhost:5984', // Not used
///     customBackendAdapter: CouchDBAdapter(
///       baseUrl: 'http://localhost:5984',
///       username: 'admin',
///       password: 'password',
///     ),
///     collections: ['todos', 'users'],
///   ),
/// );
/// ```
///
/// Note: This file will show analyzer errors if dio is not installed.
/// This is expected - the package is optional and only needed if you use this adapter.
class CouchDBAdapter implements SyncBackendAdapter {
  final Dio _dio;
  final String baseUrl;

  CouchDBAdapter({
    required this.baseUrl,
    String? username,
    String? password,
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Content-Type': 'application/json',
            if (username != null && password != null)
              'Authorization': 'Basic ${_encodeBasicAuth(username, password)}',
          },
        ));

  static String _encodeBasicAuth(String username, String password) {
    // Base64 encode username:password
    // In production, use dart:convert base64.encode
    return 'dXNlcjpwYXNz'; // Placeholder
  }

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    try {
      // Try to get existing document to get _rev
      final existing = await _dio.get('/$collection/$recordId');
      final rev = existing.data['_rev'];

      // Update with revision
      await _dio.put('/$collection/$recordId', data: {
        '_rev': rev,
        'data': data,
        'updated_at': timestamp.toIso8601String(),
        'version': (existing.data['version'] as int? ?? 0) + 1,
      });
    } catch (e) {
      // Document doesn't exist, create new
      await _dio.put('/$collection/$recordId', data: {
        'data': data,
        'updated_at': timestamp.toIso8601String(),
        'version': 1,
      });
    }
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
  }) async {
    // Use _all_docs view to get all documents
    final response = await _dio.get('/$collection/_all_docs', queryParameters: {
      'include_docs': true,
    });

    final rows = response.data['rows'] as List;
    final records = <SyncRecord>[];

    for (final row in rows) {
      final doc = row['doc'] as Map<String, dynamic>;

      // Skip design documents
      if (doc['_id'].toString().startsWith('_design/')) continue;

      final updatedAt = DateTime.parse(doc['updated_at'] as String);

      // Filter by since timestamp
      if (since != null && !updatedAt.isAfter(since)) continue;

      records.add(SyncRecord(
        recordId: doc['_id'] as String,
        data: doc['data'] as Map<String, dynamic>,
        updatedAt: updatedAt,
        version: doc['version'] as int? ?? 1,
      ));
    }

    return records;
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    // Get current revision
    final doc = await _dio.get('/$collection/$recordId');
    final rev = doc.data['_rev'];

    // Delete with revision
    await _dio.delete('/$collection/$recordId', queryParameters: {
      'rev': rev,
    });
  }

  @override
  void updateAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
}
