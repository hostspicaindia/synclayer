import 'package:dio/dio.dart';
import 'sync_backend_adapter.dart';
import '../sync/sync_filter.dart';

/// REST API implementation of SyncBackendAdapter
class RestBackendAdapter implements SyncBackendAdapter {
  late final Dio _dio;
  final String baseUrl;

  RestBackendAdapter({
    required this.baseUrl,
    String? authToken,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
    ));
  }

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    await _dio.post(
      '/sync/$collection',
      data: {
        'recordId': recordId,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
      },
    );
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
    int? limit,
    int? offset,
    SyncFilter? filter,
  }) async {
    // Build query parameters
    final queryParams = <String, dynamic>{
      if (since != null) 'since': since.toIso8601String(),
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
    };

    // Add filter parameters if provided
    if (filter != null) {
      queryParams.addAll(filter.toQueryParams());
    }

    final response = await _dio.get(
      '/sync/$collection',
      queryParameters: queryParams,
    );

    final records = (response.data['records'] as List?) ?? [];
    return records
        .map((r) => SyncRecord(
              recordId: r['recordId'] as String,
              data: r['data'] as Map<String, dynamic>,
              updatedAt: DateTime.parse(r['updatedAt'] as String),
              version: r['version'] as int? ?? 1,
            ))
        .toList();
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    await _dio.delete('/sync/$collection/$recordId');
  }

  @override
  void updateAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
}
