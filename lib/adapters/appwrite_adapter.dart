import 'package:appwrite/appwrite.dart';
import 'package:synclayer/synclayer.dart';

/// Appwrite adapter for SyncLayer
///
/// Note: This adapter uses Appwrite SDK 21.3.0 which deprecated the Databases API
/// in favor of TablesDB. For production use, consider updating to the new API
/// or pinning to an older Appwrite SDK version.
class AppwriteAdapter implements SyncBackendAdapter {
  final Databases databases;
  final String databaseId;

  AppwriteAdapter({required this.databases, required this.databaseId});

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    try {
      // ignore: deprecated_member_use
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: collection,
        documentId: recordId,
        data: {'data': data, 'updated_at': timestamp.toIso8601String()},
      );
    } catch (e) {
      // ignore: deprecated_member_use
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: collection,
        documentId: recordId,
        data: {
          'data': data,
          'updated_at': timestamp.toIso8601String(),
          'version': 1
        },
      );
    }
  }

  @override
  Future<void> pushDelta({
    required String collection,
    required String recordId,
    required Map<String, dynamic> delta,
    required int baseVersion,
    required DateTime timestamp,
  }) async {
    try {
      // ignore: deprecated_member_use
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: collection,
        documentId: recordId,
        data: {'data': delta, 'updated_at': timestamp.toIso8601String()},
      );
    } catch (e) {
      // ignore: deprecated_member_use
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: collection,
        documentId: recordId,
        data: {
          'data': delta,
          'updated_at': timestamp.toIso8601String(),
          'version': 1
        },
      );
    }
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
    int? limit,
    int? offset,
    SyncFilter? filter,
  }) async {
    List<String> queries = [];
    final effectiveSince = filter?.since ?? since;
    if (effectiveSince != null) {
      queries.add(
          Query.greaterThan('updated_at', effectiveSince.toIso8601String()));
    }
    if (filter?.where != null) {
      for (final entry in filter!.where!.entries) {
        queries.add(Query.equal('data.${entry.key}', entry.value));
      }
    }
    final effectiveLimit = filter?.limit ?? limit;
    if (effectiveLimit != null) queries.add(Query.limit(effectiveLimit));
    if (offset != null) queries.add(Query.offset(offset));

    // ignore: deprecated_member_use
    final response = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: collection,
      queries: queries,
    );

    return response.documents.map((doc) {
      var recordData = doc.data['data'] as Map<String, dynamic>;
      if (filter != null) recordData = filter.applyFieldFilter(recordData);
      return SyncRecord(
        recordId: doc.$id,
        data: recordData,
        updatedAt: DateTime.parse(doc.data['updated_at'] as String),
        version: doc.data['version'] as int? ?? 1,
      );
    }).toList();
  }

  @override
  Future<void> delete(
      {required String collection, required String recordId}) async {
    // ignore: deprecated_member_use
    await databases.deleteDocument(
      databaseId: databaseId,
      collectionId: collection,
      documentId: recordId,
    );
  }

  @override
  void updateAuthToken(String token) {}
}
