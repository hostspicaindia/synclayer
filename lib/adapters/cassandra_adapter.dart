// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist, undefined_class, undefined_identifier, undefined_method
import 'package:dart_cassandra_cql/dart_cassandra_cql.dart';
import '../network/sync_backend_adapter.dart';
import '../sync/sync_filter.dart';
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
  Future<void> pushDelta({
    required String collection,
    required String recordId,
    required Map<String, dynamic> delta,
    required int baseVersion,
    required DateTime timestamp,
  }) async {
    // Cassandra doesn't have native delta sync support
    // Fall back to full document update
    // In production, you might want to read the current document first
    // and merge the delta, but that requires an additional read
    final jsonData = jsonEncode(delta);

    await client.execute('''
      INSERT INTO $collection (record_id, data, updated_at, version)
      VALUES (?, ?, ?, ?)
    ''', [recordId, jsonData, timestamp, baseVersion + 1]);
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
    int? limit,
    int? offset,
    SyncFilter? filter,
  }) async {
    StreamedQueryResult result;

    // Use filter's since if provided, otherwise use since parameter
    final effectiveSince = filter?.since ?? since;

    // Note: Cassandra filtering is limited without proper indexes
    // For production, create appropriate secondary indexes
    if (effectiveSince != null) {
      result = await client.execute('''
        SELECT record_id, data, updated_at, version
        FROM $collection
        WHERE updated_at > ?
        ALLOW FILTERING
      ''', [effectiveSince]);
    } else {
      result = await client.execute('''
        SELECT record_id, data, updated_at, version
        FROM $collection
      ''');
    }

    final records = <SyncRecord>[];
    var count = 0;
    final skipCount = offset ?? 0;
    final maxRecords = limit ?? 1000000; // Large default if no limit

    await for (final row in result.rows) {
      // Handle offset
      if (count < skipCount) {
        count++;
        continue;
      }

      // Handle limit
      if (records.length >= maxRecords) {
        break;
      }

      var recordData =
          jsonDecode(row['data'] as String) as Map<String, dynamic>;

      // Apply field filtering if specified
      if (filter != null) {
        recordData = filter.applyFieldFilter(recordData);
      }

      records.add(SyncRecord(
        recordId: row['record_id'] as String,
        data: recordData,
        updatedAt: row['updated_at'] as DateTime,
        version: row['version'] as int,
      ));

      count++;
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
