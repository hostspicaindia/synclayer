import 'query_operators.dart';

/// Represents a single filter condition in a query
class QueryFilter {
  /// The field name to filter on
  final String field;

  /// The operator to use for comparison
  final QueryOperator operator;

  /// The value to compare against
  final dynamic value;

  const QueryFilter({
    required this.field,
    required this.operator,
    required this.value,
  });

  /// Evaluates this filter against a data map
  bool matches(Map<String, dynamic> data) {
    final fieldValue = _getNestedValue(data, field);

    switch (operator) {
      case QueryOperator.isEqualTo:
        return fieldValue == value;

      case QueryOperator.isNotEqualTo:
        return fieldValue != value;

      case QueryOperator.isGreaterThan:
        if (fieldValue == null) return false;
        return _compare(fieldValue, value) > 0;

      case QueryOperator.isGreaterThanOrEqualTo:
        if (fieldValue == null) return false;
        return _compare(fieldValue, value) >= 0;

      case QueryOperator.isLessThan:
        if (fieldValue == null) return false;
        return _compare(fieldValue, value) < 0;

      case QueryOperator.isLessThanOrEqualTo:
        if (fieldValue == null) return false;
        return _compare(fieldValue, value) <= 0;

      case QueryOperator.startsWith:
        if (fieldValue == null) return false;
        return fieldValue.toString().startsWith(value.toString());

      case QueryOperator.endsWith:
        if (fieldValue == null) return false;
        return fieldValue.toString().endsWith(value.toString());

      case QueryOperator.contains:
        if (fieldValue == null) return false;
        return fieldValue.toString().contains(value.toString());

      case QueryOperator.arrayContains:
        if (fieldValue is! List) return false;
        return fieldValue.contains(value);

      case QueryOperator.arrayContainsAny:
        if (fieldValue is! List) return false;
        if (value is! List) return false;
        return fieldValue.any((item) => value.contains(item));

      case QueryOperator.whereIn:
        if (value is! List) return false;
        return value.contains(fieldValue);

      case QueryOperator.whereNotIn:
        if (value is! List) return false;
        return !value.contains(fieldValue);

      case QueryOperator.isNull:
        return fieldValue == null;

      case QueryOperator.isNotNull:
        return fieldValue != null;
    }
  }

  /// Gets a nested value from a map using dot notation
  /// Example: "user.name" returns data['user']['name']
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

  /// Compares two values for ordering
  int _compare(dynamic a, dynamic b) {
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
    return 'QueryFilter(field: $field, operator: $operator, value: $value)';
  }
}
