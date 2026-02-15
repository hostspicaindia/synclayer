import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:synclayer/synclayer.dart';

/// Firebase Firestore adapter for SyncLayer
///
/// This adapter allows SyncLayer to work directly with Firebase Firestore
/// without needing a separate backend server.
class FirebaseAdapter implements SyncBackendAdapter {
  final FirebaseFirestore firestore;

  FirebaseAdapter({required this.firestore});

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    try {
      await firestore.collection(collection).doc(recordId).set({
        ...data,
        'updatedAt': timestamp.toIso8601String(),
        'syncedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Firebase push failed: $e');
    }
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
  }) async {
    try {
      Query query = firestore.collection(collection);

      if (since != null) {
        // Use syncedAt (Timestamp) for comparison instead of updatedAt (String)
        final timestamp = Timestamp.fromDate(since);
        query = query.where('syncedAt', isGreaterThan: timestamp);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Extract updatedAt - SyncRecord expects DateTime
        final updatedAt = data['updatedAt'];
        final updatedAtDate = updatedAt is String
            ? DateTime.parse(updatedAt)
            : DateTime.now();

        // Clean data: remove sync fields and convert Timestamps to strings
        final cleanData = <String, dynamic>{};
        data.forEach((key, value) {
          // Skip sync-related fields
          if (key == 'updatedAt' || key == 'syncedAt' || key == 'version') {
            return;
          }

          // Convert Timestamp to ISO string
          if (value is Timestamp) {
            cleanData[key] = value.toDate().toIso8601String();
          } else {
            cleanData[key] = value;
          }
        });

        return SyncRecord(
          recordId: doc.id,
          data: cleanData,
          version: data['version'] ?? 1,
          updatedAt: updatedAtDate,
        );
      }).toList();
    } catch (e) {
      throw Exception('Firebase pull failed: $e');
    }
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    try {
      await firestore.collection(collection).doc(recordId).delete();
    } catch (e) {
      throw Exception('Firebase delete failed: $e');
    }
  }

  @override
  Future<void> updateAuthToken(String token) async {
    // Firebase auth is handled separately via Firebase Auth
    // This method is not needed for Firebase adapter
  }
}
