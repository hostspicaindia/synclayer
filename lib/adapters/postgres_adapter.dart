import 'package:postgres/postgres.dart';
import 'package:synclayer/synclayer.dart';

/// PostgreSQL adapter for SyncLayer
class PostgresAdapter implements SyncBackendAdapter {
  final Connection connection;

  PostgresAdapter({required this.connection});

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
  Future<void> pushDelta({
    required String collection,
    required String recordId,
    required Map<String, dynamic> delta,
    required int baseVersion,
    required DateTime timestamp,
  }) async {
    // PostgreSQL supports JSON merge - update only changed fields
    await connection.execute(
      Sql.named('''
        UPDATE $collection
        SET data = data || @delta::jsonb,
            updated_at = @timestamp,
            version = version + 1
        WHERE record_id = @recordId
      '''),
      parameters: {
        'recordId': recordId,
        'delta': delta,
        'timestamp': timestamp,
      },
    );
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
    int? limit,
    int? offset,
    SyncFilter? filter,
  }) async {
    final Result result;
    final effectiveSince = filter?.since ?? since;
    final effectiveLimit = filter?.limit ?? limit;

    if (effectiveSince != null) {
      result = await connection.execute(
        Sql.named('''
          SELECT record_id, data, updated_at, version
          FROM $collection
          WHERE updated_at > @since
          ORDER BY updated_at ASC
          ${effectiveLimit != null ? 'LIMIT @limit' : ''}
          ${offset != null ? 'OFFSET @offset' : ''}
        '''),
        parameters: {
          'since': effectiveSince,
          if (effectiveLimit != null) 'limit': effectiveLimit,
          if (offset != null) 'offset': offset,
        },
      );
    } else {
      result = await connection.execute(
        Sql.named('''
          SELECT record_id, data, updated_at, version
          FROM $collection
          ORDER BY updated_at ASC
          ${effectiveLimit != null ? 'LIMIT @limit' : ''}
          ${offset != null ? 'OFFSET @offset' : ''}
        '''),
        parameters: {
          if (effectiveLimit != null) 'limit': effectiveLimit,
          if (offset != null) 'offset': offset,
        },
      );
    }

    return result.map((row) {
      var recordData = row[1] as Map<String, dynamic>;
      if (filter != null) {
        recordData = filter.applyFieldFilter(recordData);
      }
      return SyncRecord(
        recordId: row[0] as String,
        data: recordData,
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
      Sql.named('DELETE FROM $collection WHERE record_id = @recordId'),
      parameters: {'recordId': recordId},
    );
  }

  @override
  void updateAuthToken(String token) {
    // PostgreSQL connection auth is set at connection time
  }
}
