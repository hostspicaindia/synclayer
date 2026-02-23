/// Represents a sort order for query results
class QuerySort {
  /// The field name to sort by
  final String field;

  /// Whether to sort in descending order (default: false = ascending)
  final bool descending;

  const QuerySort({
    required this.field,
    this.descending = false,
  });

  /// Compares two data maps based on this sort order
  int compare(Map<String, dynamic> a, Map<String, dynamic> b) {
    final aValue = _getNestedValue(a, field);
    final bValue = _getNestedValue(b, field);

    // Handle null values (nulls last)
    if (aValue == null && bValue == null) return 0;
    if (aValue == null) return 1;
    if (bValue == null) return -1;

    final result = _compareValues(aValue, bValue);
    return descending ? -result : result;
  }

  /// Gets a nested value from a map using dot notation
  dynamic _getNestedValue(Map<String, dynamic> data, String path) {
    final parts = path.split('.');
    dynamic current = data;

    for (final part in parts) {
      if (current is! Map<String, dynamic>) return null;
      current = current[part];
      if (current == null) return null;
    }

    return current;
  }

  /// Compares two values
  int _compareValues(dynamic a, dynamic b) {
    if (a is num && b is num) {
      return a.compareTo(b);
    }
    if (a is String && b is String) {
      return a.compareTo(b);
    }
    if (a is DateTime && b is DateTime) {
      return a.compareTo(b);
    }
    if (a is bool && b is bool) {
      return a == b ? 0 : (a ? 1 : -1);
    }
    // Fallback to string comparison
    return a.toString().compareTo(b.toString());
  }

  @override
  String toString() {
    return 'QuerySort(field: $field, descending: $descending)';
  }
}
