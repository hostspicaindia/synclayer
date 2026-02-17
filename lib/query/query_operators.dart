/// Query operators for filtering data
enum QueryOperator {
  /// Equal to (==)
  isEqualTo,

  /// Not equal to (!=)
  isNotEqualTo,

  /// Greater than (>)
  isGreaterThan,

  /// Greater than or equal to (>=)
  isGreaterThanOrEqualTo,

  /// Less than (<)
  isLessThan,

  /// Less than or equal to (<=)
  isLessThanOrEqualTo,

  /// String starts with
  startsWith,

  /// String ends with
  endsWith,

  /// String contains
  contains,

  /// Array contains value
  arrayContains,

  /// Array contains any of values
  arrayContainsAny,

  /// Value in list
  whereIn,

  /// Value not in list
  whereNotIn,

  /// Field is null
  isNull,

  /// Field is not null
  isNotNull,
}
