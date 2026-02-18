/// Sync filter for selective synchronization
///
/// Allows filtering which data gets synced based on conditions,
/// timestamps, and other criteria. This is essential for:
/// - Privacy: Users don't want to download everyone's data
/// - Bandwidth: Mobile users have limited data plans
/// - Storage: Devices have limited space
/// - Security: Multi-tenant apps need user isolation
/// - Legal: GDPR requires data minimization
///
/// Example:
/// ```dart
/// final config = SyncConfig(
///   baseUrl: 'https://api.example.com',
///   collections: ['todos', 'notes'],
///   syncFilters: {
///     'todos': SyncFilter(
///       where: {'userId': currentUserId},
///       since: DateTime.now().subtract(Duration(days: 30)),
///     ),
///     'notes': SyncFilter(
///       where: {
///         'userId': currentUserId,
///         'archived': false,
///       },
///     ),
///   },
/// );
/// ```
class SyncFilter {
  /// Field-based filters for the collection
  ///
  /// Only records matching ALL conditions will be synced.
  /// Supports simple equality checks.
  ///
  /// Example:
  /// ```dart
  /// where: {
  ///   'userId': currentUserId,
  ///   'status': 'active',
  /// }
  /// ```
  final Map<String, dynamic>? where;

  /// Only sync records modified after this timestamp
  ///
  /// Useful for limiting sync to recent data only.
  ///
  /// Example:
  /// ```dart
  /// since: DateTime.now().subtract(Duration(days: 30))
  /// ```
  final DateTime? since;

  /// Maximum number of records to sync per pull operation
  ///
  /// Useful for limiting initial sync size or implementing
  /// progressive sync strategies.
  ///
  /// Example:
  /// ```dart
  /// limit: 100  // Only sync first 100 records
  /// ```
  final int? limit;

  /// Field names to include in synced records
  ///
  /// If specified, only these fields will be synced, reducing
  /// bandwidth and storage usage.
  ///
  /// Example:
  /// ```dart
  /// fields: ['id', 'title', 'status']  // Don't sync 'description' field
  /// ```
  final List<String>? fields;

  /// Field names to exclude from synced records
  ///
  /// If specified, these fields will be omitted from sync.
  /// Cannot be used together with [fields].
  ///
  /// Example:
  /// ```dart
  /// excludeFields: ['largeAttachment', 'internalNotes']
  /// ```
  final List<String>? excludeFields;

  const SyncFilter({
    this.where,
    this.since,
    this.limit,
    this.fields,
    this.excludeFields,
  }) : assert(
          fields == null || excludeFields == null,
          'Cannot specify both fields and excludeFields',
        );

  /// Check if a record matches this filter
  ///
  /// Used for local filtering before pushing data to backend.
  bool matches(Map<String, dynamic> data, DateTime? updatedAt) {
    // Check timestamp filter
    if (since != null && updatedAt != null) {
      if (updatedAt.isBefore(since!)) {
        return false;
      }
    }

    // Check field filters
    if (where != null) {
      for (final entry in where!.entries) {
        final fieldValue = data[entry.key];
        final filterValue = entry.value;

        // Simple equality check
        if (fieldValue != filterValue) {
          return false;
        }
      }
    }

    return true;
  }

  /// Apply field filtering to a record
  ///
  /// Returns a new map with only included fields or excluded fields removed.
  Map<String, dynamic> applyFieldFilter(Map<String, dynamic> data) {
    if (fields != null) {
      // Include only specified fields
      return Map.fromEntries(
        data.entries.where((entry) => fields!.contains(entry.key)),
      );
    }

    if (excludeFields != null) {
      // Exclude specified fields
      return Map.fromEntries(
        data.entries.where((entry) => !excludeFields!.contains(entry.key)),
      );
    }

    // No field filtering
    return data;
  }

  /// Convert filter to query parameters for backend requests
  ///
  /// This allows the backend to filter data before sending it,
  /// reducing bandwidth usage.
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (where != null) {
      // Convert where conditions to query params
      // Format: where[field]=value
      for (final entry in where!.entries) {
        params['where[${entry.key}]'] = entry.value.toString();
      }
    }

    if (since != null) {
      params['since'] = since!.toIso8601String();
    }

    if (limit != null) {
      params['limit'] = limit.toString();
    }

    if (fields != null) {
      params['fields'] = fields!.join(',');
    }

    if (excludeFields != null) {
      params['excludeFields'] = excludeFields!.join(',');
    }

    return params;
  }

  /// Create a copy with modified properties
  SyncFilter copyWith({
    Map<String, dynamic>? where,
    DateTime? since,
    int? limit,
    List<String>? fields,
    List<String>? excludeFields,
  }) {
    return SyncFilter(
      where: where ?? this.where,
      since: since ?? this.since,
      limit: limit ?? this.limit,
      fields: fields ?? this.fields,
      excludeFields: excludeFields ?? this.excludeFields,
    );
  }

  @override
  String toString() {
    final parts = <String>[];
    if (where != null) parts.add('where: $where');
    if (since != null) parts.add('since: $since');
    if (limit != null) parts.add('limit: $limit');
    if (fields != null) parts.add('fields: $fields');
    if (excludeFields != null) parts.add('excludeFields: $excludeFields');
    return 'SyncFilter(${parts.join(', ')})';
  }
}
