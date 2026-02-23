import 'package:dart_cassandra_cql/dart_cassandra_cql.dart';
import '../network/sync_backend_adapter.dart';
import 'dart:convert';

/// Apache Cassandra adapter for SyncLayer
///
/// Syncs data with Apache Cassandra distributed database.
///
/// **IMPORTANT:** This adapter requires the `dart_cassandra_cql` package.
/// Add to your pubspec.yaml:
/// ```yaml
/// dependencies:
///   dart_cassandra_cql: ^0.5.0
/// ```
///
/// **Table Schema:**
/// Each collection should have a table with this schema:
/// ```cql
/// CREATE TABLE your_collection (
///   record_id TEXT PRIMARY KEY,
///   data TEXT,
///   updated_at TIMESTAMP,
///   version INT
/// );
///
/// CREATE INDEX ON your_collection (updated_at);
/// ```
///
/// Example:
/// ```dart
/// final client = Client();
/// await client.connect(['127.0.0.1'], port: 9042);
/// await client.setKeyspace('synclayer');
///
/// await SyncLayer.init(
///   SyncConfig(
///     baseUrl: 'cassandra://localhost', // Not used
///     customBackendAdapter: CassandraAdapter(
///       client: client,
///     ),
///     collections: ['todos', 'users'],
///   ),
/// );
/// ```
///
/// Note: This file will show analyzer errors if dart_cassandra_cql is not installed.
/// This is expected - the package is optional and only needed if you use this adapter.
class CassandraAdapter implements SyncBackendAdapter {
  final Client client;

  CassandraAdapter({
    required this.client,
  });

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    final jsonData = jsonEncode(data);

    // Insert or update with version increment
    await client.execute('''
      INSERT INTO $collection (record_id, data, updated_at, version)
      VALUES (?, ?, ?, 1)
    ''', [recordId, jsonData, timestamp]);

    // Increment version (Cassandra doesn't have auto-increment)
    // This is a simplified approach - in production, use counters or LWT
    await client.execute('''
      UPDATE $collection SET version = version + 1
      WHERE record_id = ?
    ''', [recordId]);
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
  }) async {
    StreamedQueryResult result;

    if (since != null) {
      result = await client.execute('''
        SELECT record_id, data, updated_at, version
        FROM $collection
        WHERE updated_at > ?
        ALLOW FILTERING
      ''', [since]);
    } else {
      result = await client.execute('''
        SELECT record_id, data, updated_at, version
        FROM $collection
      ''');
    }

    final records = <SyncRecord>[];
    await for (final row in result.rows) {
      records.add(SyncRecord(
        recordId: row['record_id'] as String,
        data: jsonDecode(row['data'] as String) as Map<String, dynamic>,
        updatedAt: row['updated_at'] as DateTime,
        version: row['version'] as int,
      ));
    }

    return records;
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    await client.execute('''
      DELETE FROM $collection WHERE record_id = ?
    ''', [recordId]);
  }

  @override
  void updateAuthToken(String token) {
    // Cassandra authentication is set at connection time
    // To update auth, you need to create a new connection
    // This is a no-op for existing connections
  }
}
