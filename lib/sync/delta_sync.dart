/// Represents a partial update (delta) to a document.
///
/// Delta sync only sends changed fields instead of the entire document,
/// reducing bandwidth usage by up to 98% for large documents.
///
/// Example:
/// ```dart
/// // Instead of sending entire document:
/// await collection.save({
///   'id': '123',
///   'title': 'My Document',
///   'content': '... 50KB of content ...',
///   'metadata': {...},
///   'done': true,  // Only this changed
/// });
///
/// // Send only the changed field:
/// await collection.update('123', {'done': true});
/// ```
class DocumentDelta {
  /// The document ID being updated
  final String recordId;

  /// The collection name
  final String collectionName;

  /// Only the fields that changed
  final Map<String, dynamic> changedFields;

  /// Timestamp of the update
  final DateTime timestamp;

  /// Version of the document before this delta
  final int baseVersion;

  const DocumentDelta({
    required this.recordId,
    required this.collectionName,
    required this.changedFields,
    required this.timestamp,
    required this.baseVersion,
  });

  /// Convert to JSON for network transmission
  Map<String, dynamic> toJson() {
    return {
      'recordId': recordId,
      'collectionName': collectionName,
      'changedFields': changedFields,
      'timestamp': timestamp.toIso8601String(),
      'baseVersion': baseVersion,
    };
  }

  /// Create from JSON
  factory DocumentDelta.fromJson(Map<String, dynamic> json) {
    return DocumentDelta(
      recordId: json['recordId'] as String,
      collectionName: json['collectionName'] as String,
      changedFields: json['changedFields'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      baseVersion: json['baseVersion'] as int,
    );
  }

  @override
  String toString() {
    return 'DocumentDelta(recordId: $recordId, fields: ${changedFields.keys.join(", ")})';
  }
}

/// Calculates the difference between two document versions.
class DeltaCalculator {
  /// Calculate which fields changed between old and new versions.
  ///
  /// Returns only the fields that are different.
  ///
  /// Example:
  /// ```dart
  /// final oldDoc = {'title': 'Old', 'done': false, 'priority': 5};
  /// final newDoc = {'title': 'Old', 'done': true, 'priority': 5};
  ///
  /// final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);
  /// // Returns: {'done': true}
  /// ```
  static Map<String, dynamic> calculateDelta(
    Map<String, dynamic> oldDocument,
    Map<String, dynamic> newDocument,
  ) {
    final delta = <String, dynamic>{};

    // Check for changed or new fields
    for (final key in newDocument.keys) {
      final oldValue = oldDocument[key];
      final newValue = newDocument[key];

      if (!_areEqual(oldValue, newValue)) {
        delta[key] = newValue;
      }
    }

    // Check for removed fields (set to null)
    for (final key in oldDocument.keys) {
      if (!newDocument.containsKey(key)) {
        delta[key] = null;
      }
    }

    return delta;
  }

  /// Apply a delta to a document to get the updated version.
  ///
  /// Example:
  /// ```dart
  /// final doc = {'title': 'Old', 'done': false};
  /// final delta = {'done': true};
  ///
  /// final updated = DeltaCalculator.applyDelta(doc, delta);
  /// // Returns: {'title': 'Old', 'done': true}
  /// ```
  static Map<String, dynamic> applyDelta(
    Map<String, dynamic> document,
    Map<String, dynamic> delta,
  ) {
    final result = Map<String, dynamic>.from(document);

    for (final entry in delta.entries) {
      if (entry.value == null) {
        result.remove(entry.key);
      } else {
        result[entry.key] = entry.value;
      }
    }

    return result;
  }

  /// Check if two values are equal (handles nested structures).
  static bool _areEqual(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a == null || b == null) return false;

    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_areEqual(a[key], b[key])) {
          return false;
        }
      }
      return true;
    }

    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_areEqual(a[i], b[i])) return false;
      }
      return true;
    }

    return false;
  }

  /// Calculate bandwidth savings from using delta sync.
  ///
  /// Returns a percentage (0-100) of bandwidth saved.
  ///
  /// Example:
  /// ```dart
  /// final fullDoc = {'title': '...', 'content': '... 50KB ...'};
  /// final delta = {'done': true};
  ///
  /// final savings = DeltaCalculator.calculateSavings(fullDoc, delta);
  /// // Returns: ~98.0 (98% bandwidth saved)
  /// ```
  static double calculateSavings(
    Map<String, dynamic> fullDocument,
    Map<String, dynamic> delta,
  ) {
    final fullSize = fullDocument.toString().length;
    final deltaSize = delta.toString().length;

    if (fullSize == 0) return 0.0;

    final savings = ((fullSize - deltaSize) / fullSize) * 100;
    return savings.clamp(0.0, 100.0);
  }
}
