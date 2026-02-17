import 'package:cloud_firestore/cloud_firestore.dart';
import '../network/sync_backend_adapter.dart';

/// Firebase Firestore adapter for SyncLayer
///
/// Syncs data with Firebase Firestore collections.
///
/// **IMPORTANT:** This adapter requires the `cloud_firestore` package.
/// Add to your pubspec.yaml:
/// ```yaml
/// dependencies:
///   cloud_firestore: ^5.7.0
/// ```
///
/// Example:
/// ```dart
/// await SyncLayer.init(
///   SyncConfig(
///     baseUrl: 'https://firebaseapp.com', // Not used
///     customBackendAdapter: FirebaseAdapter(
///       firestore: FirebaseFirestore.instance,
///     ),
///     collections: ['todos', 'users'],
///   ),
/// );
/// ```
///
/// Note: This file will show analyzer errors if cloud_firestore is not installed.
/// This is expected - the package is optional and only needed if you use this adapter.
class FirebaseAdapter implements SyncBackendAdapter {
  final FirebaseFirestore firestore;

  FirebaseAdapter({
    required this.firestore,
  });

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    await firestore.collection(collection).doc(recordId).set({
      'data': data,
      'updatedAt': Timestamp.fromDate(timestamp),
      'version': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
    int? limit,
    int? offset,
  }) async {
    Query query = firestore.collection(collection);

    if (since != null) {
      query =
          query.where('updatedAt', isGreaterThan: Timestamp.fromDate(since));
    }

    // Apply pagination
    if (limit != null) {
      query = query.limit(limit);
    }

    // Note: Firestore doesn't have native offset, so we skip documents
    // For better performance, consider using cursor-based pagination in production
    if (offset != null && offset > 0) {
      final skipSnapshot = await query.limit(offset).get();
      if (skipSnapshot.docs.isNotEmpty) {
        query = query.startAfterDocument(skipSnapshot.docs.last);
      }
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return SyncRecord(
        recordId: doc.id,
        data: data['data'] as Map<String, dynamic>,
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        version: data['version'] as int? ?? 1,
      );
    }).toList();
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    await firestore.collection(collection).doc(recordId).delete();
  }

  @override
  void updateAuthToken(String token) {
    // Firebase auth is handled separately via FirebaseAuth
    // Token updates are managed through Firebase Authentication SDK
  }
}
