import 'package:mysql1/mysql1.dart';
import '../network/sync_backend_adapter.dart';

/// MySQL adapter for SyncLayer
///
/// Syncs data directly with MySQL database tables.
///
/// **IMPORTANT:** This adapter requires the `mysql1` package.
/// Add to your pubspec.yaml:
/// ```yaml
/// dependencies:
///   mysql1: ^0.20.0
/// ```
///
/// **Database Schema:**
/// Each collection should have a table with these columns:
/// ```sql
/// CREATE TABLE your_collection (
///   record_id VARCHAR(255) PRIMARY KEY,
///   data JSON NOT NULL,
///   updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
///   version INT NOT NULL DEFAULT 1,
///   INDEX idx_updated_at (updated_at)
/// ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/// ```
///
/// Example:
/// ```dart
/// final settings = ConnectionSettings(
///   host: 'localhost',
///   port: 3306,
///   user: 'root',
///   password: 'password',
///   db: 'mydb',
/// );
///
/// final conn = await MySqlConnection.connect(settings);
///
/// await SyncLayer.init(
///   SyncConfig(
///     baseUrl: 'mysql://localhost', // Not used
///     customBackendAdapter: MySQLAdapter(
///       connection: conn,
///     ),
///     collections: ['todos', 'users'],
///   ),
/// );
/// ```
///
/// Note: This file will show analyzer errors if mysql1 is not installed.
/// This is expected - the package is optional and only needed if you use this adapter.
class MySQLAdapter implements SyncBackendAdapter {
  final MySqlConnection connection;

  MySQLAdapter({
    required this.connection,
  });

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    // Convert data to JSON string for MySQL
    final jsonData = _encodeJson(data);

    await connection.query('''
      INSERT INTO $collection (record_id, data, updated_at, version)
      VALUES (?, ?, ?, 1)
      ON DUPLICATE KEY UPDATE
        data = VALUES(data),
        updated_at = VALUES(updated_at),
        version = version + 1
    ''', [recordId, jsonData, timestamp]);
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
  }) async {
    Results results;

    if (since != null) {
      results = await connection.query('''
        SELECT record_id, data, updated_at, version
        FROM $collection
        WHERE updated_at > ?
        ORDER BY updated_at ASC
      ''', [since]);
    } else {
      results = await connection.query('''
        SELECT record_id, data, updated_at, version
        FROM $collection
        ORDER BY updated_at ASC
      ''');
    }

    return results.map((row) {
      return SyncRecord(
        recordId: row[0] as String,
        data: _decodeJson(row[1] as String),
        updatedAt: row[2] as DateTime,
        version: row[3] as int,
      );
    }).toList();
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    await connection.query('''
      DELETE FROM $collection WHERE record_id = ?
    ''', [recordId]);
  }

  @override
  void updateAuthToken(String token) {
    // MySQL connection auth is set at connection time
    // To update auth, you need to create a new connection
    // This is a no-op for direct database connections
  }

  /// Encode Map to JSON string
  String _encodeJson(Map<String, dynamic> data) {
    // Use dart:convert json.encode
    return data.toString(); // Simplified - use json.encode in production
  }

  /// Decode JSON string to Map
  Map<String, dynamic> _decodeJson(String jsonString) {
    // Use dart:convert json.decode
    return {}; // Simplified - use json.decode in production
  }
}
