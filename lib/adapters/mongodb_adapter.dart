import 'package:mongo_dart/mongo_dart.dart';
import '../network/sync_backend_adapter.dart';

/// MongoDB adapter for SyncLayer
///
/// Syncs data with MongoDB collections.
///
/// **IMPORTANT:** This adapter requires the `mongo_dart` package.
/// Add to your pubspec.yaml:
/// ```yaml
/// dependencies:
///   mongo_dart: ^0.10.0
/// ```
///
/// **Collection Schema:**
/// Documents will automatically have this structure:
/// ```json
/// {
///   "record_id": "uuid",
///   "data": { ... your data ... },
///   "updated_at": ISODate("2024-01-01T00:00:00Z"),
///   "version": 1
/// }
/// ```
///
/// **Recommended Indexes:**
/// ```javascript
/// db.your_collection.createIndex({ "record_id": 1 }, { unique: true })
/// db.your_collection.createIndex({ "updated_at": 1 })
/// ```
///
/// Example:
/// ```dart
/// final db = await Db.create('mongodb://localhost:27017/mydb');
/// await db.open();
///
/// await SyncLayer.init(
///   SyncConfig(
///     baseUrl: 'mongodb://localhost', // Not used
///     customBackendAdapter: MongoDBAdapter(
///       db: db,
///     ),
///     collections: ['todos', 'users'],
///   ),
/// );
/// ```
///
/// Note: This file will show analyzer errors if mongo_dart is not installed.
/// This is expected - the package is optional and only needed if you use this adapter.
class MongoDBAdapter implements SyncBackendAdapter {
  final Db db;

  MongoDBAdapter({
    required this.db,
  });

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
        'version': 1, // Will be incremented if exists
      },
      upsert: true,
    );

    // Increment version if document already existed
    await coll.updateOne(
      where.eq('record_id', recordId),
      modify.inc('version', 1),
    );
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
  }) async {
    final coll = db.collection(collection);

    SelectorBuilder query = where;

    if (since != null) {
      query = query.gt('updated_at', since);
    }

    final docs = await coll.find(query.sortBy('updated_at')).toList();

    return docs.map((doc) {
      return SyncRecord(
        recordId: doc['record_id'] as String,
        data: doc['data'] as Map<String, dynamic>,
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
    final coll = db.collection(collection);
    await coll.deleteOne(where.eq('record_id', recordId));
  }

  @override
  void updateAuthToken(String token) {
    // MongoDB connection auth is set at connection time
    // To update auth, you need to create a new connection with new credentials
    // This is a no-op for direct database connections
  }
}
