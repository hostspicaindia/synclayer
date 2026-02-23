// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist, undefined_class, undefined_identifier, undefined_method
import 'package:appwrite/appwrite.dart';
import '../network/sync_backend_adapter.dart';

/// Appwrite adapter for SyncLayer
///
/// Syncs data with Appwrite database collections.
///
/// **IMPORTANT:** This adapter requires the `appwrite` package.
/// Add to your pubspec.yaml:
/// ```yaml
/// dependencies:
///   appwrite: ^14.0.0
/// ```
///
/// Example:
/// ```dart
/// final client = Client()
///   ..setEndpoint('https://cloud.appwrite.io/v1')
///   ..setProject('your-project-id');
///
/// await SyncLayer.init(
///   SyncConfig(
///     baseUrl: 'https://cloud.appwrite.io', // Not used
///     customBackendAdapter: AppwriteAdapter(
///       databases: Databases(client),
///       databaseId: 'your-database-id',
///     ),
///     collections: ['todos', 'users'],
///   ),
/// );
/// ```
///
/// Note: This file will show analyzer errors if appwrite is not installed.
/// This is expected - the package is optional and only needed if you use this adapter.
class AppwriteAdapter implements SyncBackendAdapter {
  final Databases databases;
  final String databaseId;

  AppwriteAdapter({
    required this.databases,
    required this.databaseId,
  });

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    try {
      // Try to update existing document
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: collection,
        documentId: recordId,
        data: {
          'data': data,
          'updated_at': timestamp.toIso8601String(),
        },
      );
    } catch (e) {
      // If document doesn't exist, create it
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: collection,
        documentId: recordId,
        data: {
          'data': data,
          'updated_at': timestamp.toIso8601String(),
          'version': 1,
        },
      );
    }
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
  }) async {
    List<String> queries = [];

    if (since != null) {
      queries.add(Query.greaterThan('updated_at', since.toIso8601String()));
    }

    final response = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: collection,
      queries: queries,
    );

    return response.documents.map((doc) {
      return SyncRecord(
        recordId: doc.$id,
        data: doc.data['data'] as Map<String, dynamic>,
        updatedAt: DateTime.parse(doc.data['updated_at'] as String),
        version: doc.data['version'] as int? ?? 1,
      );
    }).toList();
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    await databases.deleteDocument(
      databaseId: databaseId,
      collectionId: collection,
      documentId: recordId,
    );
  }

  @override
  void updateAuthToken(String token) {
    // Appwrite auth is handled via Account API
    // Token updates are managed through Appwrite Authentication SDK
  }
}
