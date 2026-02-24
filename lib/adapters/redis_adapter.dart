import 'package:redis/redis.dart';
import 'package:synclayer/synclayer.dart';
import 'dart:convert';

/// Redis adapter for SyncLayer
class RedisAdapter implements SyncBackendAdapter {
  final Command command;

  RedisAdapter({required this.command});

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
    final currentVersion = await command.send_object(['HGET', key, 'version']);
    final version =
        currentVersion != null ? int.parse(currentVersion.toString()) + 1 : 1;

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

    await command.send_object([
      'ZADD',
      indexKey,
      timestamp.millisecondsSinceEpoch.toString(),
      recordId,
    ]);
  }

  @override
  Future<void> pushDelta({
    required String collection,
    required String recordId,
    required Map<String, dynamic> delta,
    required int baseVersion,
    required DateTime timestamp,
  }) async {
    final key = _getKey(collection, recordId);
    final indexKey = _getIndexKey(collection);

    await command.send_object([
      'HSET',
      key,
      'data',
      jsonEncode(delta),
      'updated_at',
      timestamp.toIso8601String(),
    ]);
    await command.send_object(['HINCRBY', key, 'version', '1']);
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
    int? limit,
    int? offset,
    SyncFilter? filter,
  }) async {
    final indexKey = _getIndexKey(collection);
    final records = <SyncRecord>[];
    final effectiveSince = filter?.since ?? since;
    final minScore =
        effectiveSince?.millisecondsSinceEpoch.toString() ?? '-inf';
    final recordIds = await command.send_object([
      'ZRANGEBYSCORE',
      indexKey,
      minScore,
      '+inf',
    ]) as List;

    for (final recordId in recordIds) {
      final key = _getKey(collection, recordId.toString());
      final hash = await command.send_object(['HGETALL', key]) as List;
      if (hash.isEmpty) continue;

      final Map<String, String> fields = {};
      for (int i = 0; i < hash.length; i += 2) {
        fields[hash[i].toString()] = hash[i + 1].toString();
      }

      var recordData = jsonDecode(fields['data']!) as Map<String, dynamic>;
      if (filter != null) recordData = filter.applyFieldFilter(recordData);

      records.add(SyncRecord(
        recordId: recordId.toString(),
        data: recordData,
        updatedAt: DateTime.parse(fields['updated_at']!),
        version: int.parse(fields['version']!),
      ));
    }

    return records;
  }

  @override
  Future<void> delete(
      {required String collection, required String recordId}) async {
    final key = _getKey(collection, recordId);
    final indexKey = _getIndexKey(collection);
    await command.send_object(['DEL', key]);
    await command.send_object(['ZREM', indexKey, recordId]);
  }

  @override
  void updateAuthToken(String token) {}
}
