import 'package:mongo_dart/mongo_dart.dart';
import 'package:synclayer/synclayer.dart';

/// MongoDB adapter for SyncLayer
class MongoDBAdapter implements SyncBackendAdapter {
  final Db db;

  MongoDBAdapter({required this.db});

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    final coll = db.collection(collection);
    await coll.replaceOne(
      where.eq('record_id', recordId),
      {
        'record_id': recordId,
        'data': data,
        'updated_at': timestamp,
        'version': 1,
      },
      upsert: true,
    );
    await coll.updateOne(
      where.eq('record_id', recordId),
      modify.inc('version', 1),
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
    final coll = db.collection(collection);
    final updateFields = <String, dynamic>{};
    for (final entry in delta.entries) {
      updateFields['data.${entry.key}'] = entry.value;
    }
    updateFields['updated_at'] = timestamp;
    await coll.updateOne(
      where.eq('record_id', recordId),
      modify.set('updated_at', timestamp).inc('version', 1),
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
    final coll = db.collection(collection);
    SelectorBuilder query = where;
    final effectiveSince = filter?.since ?? since;
    if (effectiveSince != null) {
      query = query.gt('updated_at', effectiveSince);
    }
    var finder = coll.find(query.sortBy('updated_at'));
    if (limit != null) finder = finder.take(limit);
    if (offset != null) finder = finder.skip(offset);
    final docs = await finder.toList();
    return docs.map((doc) {
      var recordData = doc['data'] as Map<String, dynamic>;
      if (filter != null) {
        recordData = filter.applyFieldFilter(recordData);
      }
      return SyncRecord(
        recordId: doc['record_id'] as String,
        data: recordData,
        updatedAt: doc['updated_at'] as DateTime,
        version: doc['version'] as int? ?? 1,
      );
    }).toList();
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    await db.collection(collection).deleteOne(where.eq('record_id', recordId));
  }

  @override
  void updateAuthToken(String token) {}
}
