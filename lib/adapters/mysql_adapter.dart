import 'package:mysql1/mysql1.dart';
import 'package:synclayer/synclayer.dart';
import 'dart:convert';

/// MySQL adapter for SyncLayer
class MySQLAdapter implements SyncBackendAdapter {
  final MySqlConnection connection;

  MySQLAdapter({required this.connection});

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    final jsonData = jsonEncode(data);
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
  Future<void> pushDelta({
    required String collection,
    required String recordId,
    required Map<String, dynamic> delta,
    required int baseVersion,
    required DateTime timestamp,
  }) async {
    final jsonData = jsonEncode(delta);
    await connection.query('''
      UPDATE $collection
      SET data = JSON_MERGE_PATCH(data, ?),
          updated_at = ?,
          version = version + 1
      WHERE record_id = ?
    ''', [jsonData, timestamp, recordId]);
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
    Results results;

    if (effectiveSince != null) {
      results = await connection.query('''
        SELECT record_id, data, updated_at, version
        FROM $collection
        WHERE updated_at > ?
        ORDER BY updated_at ASC
        ${effectiveLimit != null ? 'LIMIT ?' : ''}
        ${offset != null ? 'OFFSET ?' : ''}
      ''', [
        effectiveSince,
        if (effectiveLimit != null) effectiveLimit,
        if (offset != null) offset
      ]);
    } else {
      results = await connection.query('''
        SELECT record_id, data, updated_at, version
        FROM $collection
        ORDER BY updated_at ASC
        ${effectiveLimit != null ? 'LIMIT ?' : ''}
        ${offset != null ? 'OFFSET ?' : ''}
      ''', [
        if (effectiveLimit != null) effectiveLimit,
        if (offset != null) offset
      ]);
    }

    return results.map((row) {
      var recordData = jsonDecode(row[1] as String) as Map<String, dynamic>;
      if (filter != null) recordData = filter.applyFieldFilter(recordData);
      return SyncRecord(
        recordId: row[0] as String,
        data: recordData,
        updatedAt: row[2] as DateTime,
        version: row[3] as int,
      );
    }).toList();
  }

  @override
  Future<void> delete(
      {required String collection, required String recordId}) async {
    await connection
        .query('DELETE FROM $collection WHERE record_id = ?', [recordId]);
  }

  @override
  void updateAuthToken(String token) {}
}
