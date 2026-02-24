import 'package:sqflite/sqflite.dart';
import 'package:synclayer/synclayer.dart';
import 'dart:convert';

/// SQLite adapter for SyncLayer
class SQLiteAdapter implements SyncBackendAdapter {
  final Database database;

  SQLiteAdapter({required this.database});

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    final jsonData = jsonEncode(data);
    await database.execute('''
      INSERT INTO $collection (record_id, data, updated_at, version)
      VALUES (?, ?, ?, 1)
      ON CONFLICT(record_id) DO UPDATE SET
        data = excluded.data,
        updated_at = excluded.updated_at,
        version = version + 1
    ''', [recordId, jsonData, timestamp.toIso8601String()]);
  }

  @override
  Future<void> pushDelta({
    required String collection,
    required String recordId,
    required Map<String, dynamic> delta,
    required int baseVersion,
    required DateTime timestamp,
  }) async {
    final jsonData = jsonEncode(delta);
    await database.execute('''
      UPDATE $collection
      SET data = json_patch(data, ?),
          updated_at = ?,
          version = version + 1
      WHERE record_id = ?
    ''', [jsonData, timestamp.toIso8601String(), recordId]);
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
    int? limit,
    int? offset,
    SyncFilter? filter,
  }) async {
    final effectiveSince = filter?.since ?? since;
    final effectiveLimit = filter?.limit ?? limit;
    List<Map<String, dynamic>> results;

    if (effectiveSince != null) {
      results = await database.query(
        collection,
        where: 'updated_at > ?',
        whereArgs: [effectiveSince.toIso8601String()],
        orderBy: 'updated_at ASC',
        limit: effectiveLimit,
        offset: offset,
      );
    } else {
      results = await database.query(
        collection,
        orderBy: 'updated_at ASC',
        limit: effectiveLimit,
        offset: offset,
      );
    }

    return results.map((row) {
      var recordData =
          jsonDecode(row['data'] as String) as Map<String, dynamic>;
      if (filter != null) recordData = filter.applyFieldFilter(recordData);
      return SyncRecord(
        recordId: row['record_id'] as String,
        data: recordData,
        updatedAt: DateTime.parse(row['updated_at'] as String),
        version: row['version'] as int,
      );
    }).toList();
  }

  @override
  Future<void> delete(
      {required String collection, required String recordId}) async {
    await database
        .delete(collection, where: 'record_id = ?', whereArgs: [recordId]);
  }

  @override
  void updateAuthToken(String token) {}
}
