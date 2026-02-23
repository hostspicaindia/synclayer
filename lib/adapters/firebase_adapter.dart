// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist, undefined_class, undefined_identifier, undefined_method, non_type_as_type_argument, cast_to_non_type
import 'package:cloud_firestore/cloud_firestore.dart';
import '../network/sync_backend_adapter.dart';
import '../sync/sync_filter.dart';

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
  Future<void> pushDelta({
    required String collection,
    required String recordId,
    required Map<String, dynamic> delta,
    required int baseVersion,
    required DateTime timestamp,
  }) async {
    // Firebase Firestore supports partial updates natively
    // We can use merge: true to only update changed fields
    final updateData = <String, dynamic>{};

    // Prefix each delta field with 'data.' for nested update
    for (final entry in delta.entries) {
      updateData['data.${entry.key}'] = entry.value;
    }

    updateData['updatedAt'] = Timestamp.fromDate(timestamp);
    updateData['version'] = FieldValue.increment(1);

    await firestore.collection(collection).doc(recordId).set(
          updateData,
          SetOptions(merge: true),
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
    Query query = firestore.collection(collection);

    // Use filter's since if provided, otherwise use since parameter
    final effectiveSince = filter?.since ?? since;
    if (effectiveSince != null) {
      query = query.where('updatedAt',
          isGreaterThan: Timestamp.fromDate(effectiveSince));
    }

    // Apply filter where conditions
    if (filter?.where != null) {
      for (final entry in filter!.where!.entries) {
        query = query.where('data.${entry.key}', isEqualTo: entry.value);
      }
    }

    // Apply pagination - use filter's limit if provided
    final effectiveLimit = filter?.limit ?? limit;
    if (effectiveLimit != null) {
      query = query.limit(effectiveLimit);
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
      var recordData = data['data'] as Map<String, dynamic>;

      // Apply field filtering if specified
      if (filter != null) {
        recordData = filter.applyFieldFilter(recordData);
      }

      return SyncRecord(
        recordId: doc.id,
        data: recordData,
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
