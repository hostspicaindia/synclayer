// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist, undefined_class, undefined_identifier, undefined_method
import 'package:redis/redis.dart';
import '../network/sync_backend_adapter.dart';
import 'dart:convert';

/// Redis adapter for SyncLayer
///
/// Syncs data with Redis using JSON storage.
/// Uses Redis Hashes to store documents with metadata.
///
/// **IMPORTANT:** This adapter requires the `redis` package.
/// Add to your pubspec.yaml:
/// ```yaml
/// dependencies:
///   redis: ^3.1.0
/// ```
///
/// **Data Structure:**
/// Each record is stored as a Redis Hash:
/// ```
/// Key: collection:record_id
/// Fields:
///   - data: JSON string
///   - updated_at: ISO timestamp
///   - version: integer
/// ```
///
/// **Index Structure:**
/// A sorted set tracks timestamps for pull sync:
/// ```
/// Key: collection:_index
/// Score: timestamp (milliseconds since epoch)
/// Member: record_id
/// ```
///
/// Example:
/// ```dart
/// final conn = RedisConnection();
/// final command = await conn.connect('localhost', 6379);
///
/// await SyncLayer.init(
///   SyncConfig(
///     baseUrl: 'redis://localhost', // Not used
///     customBackendAdapter: RedisAdapter(
///       command: command,
///     ),
///     collections: ['todos', 'users'],
///   ),
/// );
/// ```
///
/// Note: This file will show analyzer errors if redis is not installed.
/// This is expected - the package is optional and only needed if you use this adapter.
class RedisAdapter implements SyncBackendAdapter {
  final Command command;

  RedisAdapter({
    required this.command,
  });

  String _getKey(String collection, String recordId) => '$collection:$recordId';
  String _getIndexKey(String collection) => '$collection:_index';

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    final key = _getKey(collection, recordId);
    final indexKey = _getIndexKey(collection);

    // Get current version
    final currentVersion = await command.send_object(['HGET', key, 'version']);
    final version =
        currentVersion != null ? int.parse(currentVersion.toString()) + 1 : 1;

    // Store document as hash
    await command.send_object([
      'HSET',
      key,
      'data',
      jsonEncode(data),
      'updated_at',
      timestamp.toIso8601String(),
      'version',
      version.toString(),
    ]);

    // Update index (sorted set by timestamp)
    await command.send_object([
      'ZADD',
      indexKey,
      timestamp.millisecondsSinceEpoch.toString(),
      recordId,
    ]);
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
  }) async {
    final indexKey = _getIndexKey(collection);
    final records = <SyncRecord>[];

    // Get record IDs from sorted set
    final minScore = since?.millisecondsSinceEpoch.toString() ?? '-inf';
    final recordIds = await command.send_object([
      'ZRANGEBYSCORE',
      indexKey,
      minScore,
      '+inf',
    ]) as List;

    // Fetch each record
    for (final recordId in recordIds) {
      final key = _getKey(collection, recordId.toString());
      final hash = await command.send_object(['HGETALL', key]) as List;

      if (hash.isEmpty) continue;

      // Parse hash response (alternating keys and values)
      final Map<String, String> fields = {};
      for (int i = 0; i < hash.length; i += 2) {
        fields[hash[i].toString()] = hash[i + 1].toString();
      }

      records.add(SyncRecord(
        recordId: recordId.toString(),
        data: jsonDecode(fields['data']!) as Map<String, dynamic>,
        updatedAt: DateTime.parse(fields['updated_at']!),
        version: int.parse(fields['version']!),
      ));
    }

    return records;
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    final key = _getKey(collection, recordId);
    final indexKey = _getIndexKey(collection);

    // Delete hash
    await command.send_object(['DEL', key]);

    // Remove from index
    await command.send_object(['ZREM', indexKey, recordId]);
  }

  @override
  void updateAuthToken(String token) {
    // Redis AUTH command would need to be sent
    // This requires reconnection with new credentials
    // This is a no-op for existing connections
  }
}
