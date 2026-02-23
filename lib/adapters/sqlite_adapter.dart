// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist, undefined_class, undefined_identifier, undefined_method
import 'package:sqflite/sqflite.dart';
import '../network/sync_backend_adapter.dart';
import 'dart:convert';

/// SQLite adapter for SyncLayer
///
/// Syncs data with a local or remote SQLite database.
/// Useful for server-side SQLite or local-to-local sync scenarios.
///
/// **IMPORTANT:** This adapter requires the `sqflite` package.
/// Add to your pubspec.yaml:
/// ```yaml
/// dependencies:
///   sqflite: ^2.3.0
/// ```
///
/// **Database Schema:**
/// Each collection should have a table with these columns:
/// ```sql
/// CREATE TABLE your_collection (
///   record_id TEXT PRIMARY KEY,
///   data TEXT NOT NULL,
///   updated_at TEXT NOT NULL,
///   version INTEGER NOT NULL DEFAULT 1
/// );
///
/// CREATE INDEX idx_updated_at ON your_collection(updated_at);
/// ```
///
/// Example:
/// ```dart
/// final db = await openDatabase(
///   'sync_backend.db',
///   version: 1,
///   onCreate: (db, version) async {
///     await db.execute('''
///       CREATE TABLE todos (
///         record_id TEXT PRIMARY KEY,
///         data TEXT NOT NULL,
///         updated_at TEXT NOT NULL,
///         version INTEGER NOT NULL DEFAULT 1
///       )
///     ''');
///   },
/// );
///
/// await SyncLayer.init(
///   SyncConfig(
///     baseUrl: 'sqlite://local', // Not used
///     customBackendAdapter: SQLiteAdapter(
///       database: db,
///     ),
///     collections: ['todos', 'users'],
///   ),
/// );
/// ```
///
/// Note: This file will show analyzer errors if sqflite is not installed.
/// This is expected - the package is optional and only needed if you use this adapter.
class SQLiteAdapter implements SyncBackendAdapter {
  final Database database;

  SQLiteAdapter({
    required this.database,
  });

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
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
  }) async {
    List<Map<String, dynamic>> results;

    if (since != null) {
      results = await database.query(
        collection,
        where: 'updated_at > ?',
        whereArgs: [since.toIso8601String()],
        orderBy: 'updated_at ASC',
      );
    } else {
      results = await database.query(
        collection,
        orderBy: 'updated_at ASC',
      );
    }

    return results.map((row) {
      return SyncRecord(
        recordId: row['record_id'] as String,
        data: jsonDecode(row['data'] as String) as Map<String, dynamic>,
        updatedAt: DateTime.parse(row['updated_at'] as String),
        version: row['version'] as int,
      );
    }).toList();
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    await database.delete(
      collection,
      where: 'record_id = ?',
      whereArgs: [recordId],
    );
  }

  @override
  void updateAuthToken(String token) {
    // SQLite doesn't use authentication tokens
    // This is a no-op for local database connections
  }
}
