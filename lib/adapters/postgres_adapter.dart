// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist, undefined_class, undefined_identifier, undefined_method
import 'package:postgres/postgres.dart';
import '../network/sync_backend_adapter.dart';

/// PostgreSQL adapter for SyncLayer
///
/// Syncs data directly with PostgreSQL database tables.
///
/// **IMPORTANT:** This adapter requires the `postgres` package.
/// Add to your pubspec.yaml:
/// ```yaml
/// dependencies:
///   postgres: ^3.0.0
/// ```
///
/// **Database Schema:**
/// Each collection should have a table with these columns:
/// ```sql
/// CREATE TABLE your_collection (
///   record_id VARCHAR(255) PRIMARY KEY,
///   data JSONB NOT NULL,
///   updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
///   version INTEGER NOT NULL DEFAULT 1
/// );
///
/// CREATE INDEX idx_updated_at ON your_collection(updated_at);
/// ```
///
/// Example:
/// ```dart
/// final connection = await Connection.open(
///   Endpoint(
///     host: 'localhost',
///     database: 'mydb',
///     username: 'user',
///     password: 'password',
///   ),
/// );
///
/// await SyncLayer.init(
///   SyncConfig(
///     baseUrl: 'postgres://localhost', // Not used
///     customBackendAdapter: PostgresAdapter(
///       connection: connection,
///     ),
///     collections: ['todos', 'users'],
///   ),
/// );
/// ```
///
/// Note: This file will show analyzer errors if postgres is not installed.
/// This is expected - the package is optional and only needed if you use this adapter.
class PostgresAdapter implements SyncBackendAdapter {
  final Connection connection;

  PostgresAdapter({
    required this.connection,
  });

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    await connection.execute(
      Sql.named('''
        INSERT INTO $collection (record_id, data, updated_at, version)
        VALUES (@recordId, @data::jsonb, @timestamp, 1)
        ON CONFLICT (record_id) 
        DO UPDATE SET 
          data = @data::jsonb,
          updated_at = @timestamp,
          version = $collection.version + 1
      '''),
      parameters: {
        'recordId': recordId,
        'data': data,
        'timestamp': timestamp,
      },
    );
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
  }) async {
    final Result result;

    if (since != null) {
      result = await connection.execute(
        Sql.named('''
          SELECT record_id, data, updated_at, version
          FROM $collection
          WHERE updated_at > @since
          ORDER BY updated_at ASC
        '''),
        parameters: {
          'since': since,
        },
      );
    } else {
      result = await connection.execute(
        Sql.named('''
          SELECT record_id, data, updated_at, version
          FROM $collection
          ORDER BY updated_at ASC
        '''),
      );
    }

    return result.map((row) {
      return SyncRecord(
        recordId: row[0] as String,
        data: row[1] as Map<String, dynamic>,
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
    await connection.execute(
      Sql.named('''
        DELETE FROM $collection WHERE record_id = @recordId
      '''),
      parameters: {
        'recordId': recordId,
      },
    );
  }

  @override
  void updateAuthToken(String token) {
    // PostgreSQL connection auth is set at connection time
    // To update auth, you need to create a new connection
    // This is a no-op for direct database connections
  }
}
