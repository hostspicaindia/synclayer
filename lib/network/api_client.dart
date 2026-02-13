import 'package:dio/dio.dart';

/// HTTP client for API communication
class ApiClient {
  late final Dio _dio;
  final String baseUrl;
  final String? authToken;

  ApiClient({required this.baseUrl, this.authToken}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      ),
    );
  }

  /// Push data to server
  Future<Response> pushData({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    return await _dio.post(
      '/sync/$collection',
      data: {'recordId': recordId, 'data': data},
    );
  }

  /// Pull data from server
  Future<Response> pullData({
    required String collection,
    DateTime? since,
  }) async {
    return await _dio.get(
      '/sync/$collection',
      queryParameters: {if (since != null) 'since': since.toIso8601String()},
    );
  }

  /// Delete data on server
  Future<Response> deleteData({
    required String collection,
    required String recordId,
  }) async {
    return await _dio.delete('/sync/$collection/$recordId');
  }

  /// Update auth token
  void updateAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
}
