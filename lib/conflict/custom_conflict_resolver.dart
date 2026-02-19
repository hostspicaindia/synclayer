/// Custom conflict resolver callback type.
///
/// Allows developers to implement custom conflict resolution logic
/// for specific use cases that the built-in strategies don't handle.
///
/// Parameters:
/// - [local]: The local version of the document
/// - [remote]: The remote (server) version of the document
/// - [localTimestamp]: When the local version was last modified
/// - [remoteTimestamp]: When the remote version was last modified
///
/// Returns:
/// The resolved version of the document
///
/// Example:
/// ```dart
/// // Merge arrays instead of replacing
/// Map<String, dynamic> mergeArrays(
///   Map<String, dynamic> local,
///   Map<String, dynamic> remote,
///   DateTime localTimestamp,
///   DateTime remoteTimestamp,
/// ) {
///   return {
///     ...remote,
///     'tags': [
///       ...List<String>.from(local['tags'] ?? []),
///       ...List<String>.from(remote['tags'] ?? []),
///     ].toSet().toList(),
///   };
/// }
/// ```
typedef CustomConflictResolverCallback = Map<String, dynamic> Function(
  Map<String, dynamic> local,
  Map<String, dynamic> remote,
  DateTime localTimestamp,
  DateTime remoteTimestamp,
);

/// Pre-built custom conflict resolvers for common scenarios.
class ConflictResolvers {
  /// Merges arrays from both versions, removing duplicates.
  ///
  /// Use for: Social apps with likes/comments, collaborative editing
  ///
  /// Example:
  /// ```dart
  /// conflictResolver: ConflictResolvers.mergeArrays(['tags', 'likes'])
  /// ```
  static CustomConflictResolverCallback mergeArrays(List<String> arrayFields) {
    return (local, remote, localTimestamp, remoteTimestamp) {
      final result = Map<String, dynamic>.from(remote);

      for (final field in arrayFields) {
        final localArray = local[field];
        final remoteArray = remote[field];

        if (localArray is List && remoteArray is List) {
          // Merge and deduplicate
          result[field] = [...localArray, ...remoteArray].toSet().toList();
        }
      }

      return result;
    };
  }

  /// Sums numeric fields from both versions.
  ///
  /// Use for: Inventory apps, counters, analytics
  ///
  /// Example:
  /// ```dart
  /// conflictResolver: ConflictResolvers.sumNumbers(['quantity', 'views'])
  /// ```
  static CustomConflictResolverCallback sumNumbers(List<String> numericFields) {
    return (local, remote, localTimestamp, remoteTimestamp) {
      final result = Map<String, dynamic>.from(remote);

      for (final field in numericFields) {
        final localValue = local[field];
        final remoteValue = remote[field];

        if (localValue is num && remoteValue is num) {
          result[field] = localValue + remoteValue;
        }
      }

      return result;
    };
  }

  /// Merges specific fields from local, keeps rest from remote.
  ///
  /// Use for: Field-level merging, partial updates
  ///
  /// Example:
  /// ```dart
  /// conflictResolver: ConflictResolvers.mergeFields(['comments', 'likes'])
  /// ```
  static CustomConflictResolverCallback mergeFields(
      List<String> fieldsToMerge) {
    return (local, remote, localTimestamp, remoteTimestamp) {
      final result = Map<String, dynamic>.from(remote);

      for (final field in fieldsToMerge) {
        if (local.containsKey(field)) {
          result[field] = local[field];
        }
      }

      return result;
    };
  }

  /// Takes the maximum value for numeric fields.
  ///
  /// Use for: Version numbers, counters that only increase
  ///
  /// Example:
  /// ```dart
  /// conflictResolver: ConflictResolvers.maxValue(['version', 'score'])
  /// ```
  static CustomConflictResolverCallback maxValue(List<String> numericFields) {
    return (local, remote, localTimestamp, remoteTimestamp) {
      final result = Map<String, dynamic>.from(remote);

      for (final field in numericFields) {
        final localValue = local[field];
        final remoteValue = remote[field];

        if (localValue is num && remoteValue is num) {
          result[field] = localValue > remoteValue ? localValue : remoteValue;
        }
      }

      return result;
    };
  }

  /// Field-level last-write-wins: each field independently uses most recent.
  ///
  /// Use for: Collaborative editing where different fields change independently
  ///
  /// Requires: Documents must have per-field timestamps in format:
  /// `{field}_updatedAt` (e.g., 'title_updatedAt', 'content_updatedAt')
  ///
  /// Example:
  /// ```dart
  /// conflictResolver: ConflictResolvers.fieldLevelLastWriteWins()
  /// ```
  static CustomConflictResolverCallback fieldLevelLastWriteWins() {
    return (local, remote, localTimestamp, remoteTimestamp) {
      final result = <String, dynamic>{};

      // Get all unique field names (excluding timestamp fields)
      final allFields = <String>{
        ...local.keys.where((k) => !k.endsWith('_updatedAt')),
        ...remote.keys.where((k) => !k.endsWith('_updatedAt')),
      };

      for (final field in allFields) {
        final localTimestampField = '${field}_updatedAt';
        final remoteTimestampField = '${field}_updatedAt';

        final localFieldTime = local[localTimestampField];
        final remoteFieldTime = remote[remoteTimestampField];

        // If both have timestamps, compare them
        if (localFieldTime is String && remoteFieldTime is String) {
          final localTime = DateTime.parse(localFieldTime);
          final remoteTime = DateTime.parse(remoteFieldTime);

          if (localTime.isAfter(remoteTime)) {
            result[field] = local[field];
            result[localTimestampField] = localFieldTime;
          } else {
            result[field] = remote[field];
            result[remoteTimestampField] = remoteFieldTime;
          }
        } else {
          // Fallback to document-level timestamp
          if (localTimestamp.isAfter(remoteTimestamp)) {
            if (local.containsKey(field)) result[field] = local[field];
          } else {
            if (remote.containsKey(field)) result[field] = remote[field];
          }
        }
      }

      return result;
    };
  }

  /// Deep merge: recursively merges nested objects.
  ///
  /// Use for: Complex nested data structures
  ///
  /// Example:
  /// ```dart
  /// conflictResolver: ConflictResolvers.deepMerge()
  /// ```
  static CustomConflictResolverCallback deepMerge() {
    return (local, remote, localTimestamp, remoteTimestamp) {
      return _deepMergeRecursive(local, remote);
    };
  }

  static Map<String, dynamic> _deepMergeRecursive(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final result = Map<String, dynamic>.from(remote);

    for (final key in local.keys) {
      if (!remote.containsKey(key)) {
        result[key] = local[key];
      } else if (local[key] is Map && remote[key] is Map) {
        result[key] = _deepMergeRecursive(
          local[key] as Map<String, dynamic>,
          remote[key] as Map<String, dynamic>,
        );
      } else if (local[key] is List && remote[key] is List) {
        // Merge lists and deduplicate
        result[key] =
            [...local[key] as List, ...remote[key] as List].toSet().toList();
      }
    }

    return result;
  }
}
