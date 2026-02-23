import 'dart:async';
import 'dart:convert';
import 'query_filter.dart';
import 'query_operators.dart';
import 'query_sort.dart';
import '../core/synclayer_init.dart';

/// Builder for constructing and executing queries on a collection
class QueryBuilder {
  /// The collection name to query
  final String collectionName;

  /// List of filters to apply
  final List<QueryFilter> _filters = [];

  /// List of sort orders to apply
  final List<QuerySort> _sorts = [];

  /// Maximum number of results to return
  int? _limit;

  /// Number of results to skip
  int? _offset;

  QueryBuilder(this.collectionName);

  /// Adds a filter condition to the query
  QueryBuilder where(
    String field, {
    dynamic isEqualTo,
    dynamic isNotEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    String? startsWith,
    String? endsWith,
    String? contains,
    dynamic arrayContains,
    List<dynamic>? arrayContainsAny,
    List<dynamic>? whereIn,
    List<dynamic>? whereNotIn,
    bool? isNull,
  }) {
    // Add filter based on which parameter is provided
    if (isEqualTo != null) {
      _filters.add(QueryFilter(
        field: field,
        operator: QueryOperator.isEqualTo,
        value: isEqualTo,
      ));
    }
    if (isNotEqualTo != null) {
      _filters.add(QueryFilter(
        field: field,
        operator: QueryOperator.isNotEqualTo,
        value: isNotEqualTo,
      ));
    }
    if (isGreaterThan != null) {
      _filters.add(QueryFilter(
        field: field,
        operator: QueryOperator.isGreaterThan,
        value: isGreaterThan,
      ));
    }
    if (isGreaterThanOrEqualTo != null) {
      _filters.add(QueryFilter(
        field: field,
        operator: QueryOperator.isGreaterThanOrEqualTo,
        value: isGreaterThanOrEqualTo,
      ));
    }
    if (isLessThan != null) {
      _filters.add(QueryFilter(
        field: field,
        operator: QueryOperator.isLessThan,
        value: isLessThan,
      ));
    }
    if (isLessThanOrEqualTo != null) {
      _filters.add(QueryFilter(
        field: field,
        operator: QueryOperator.isLessThanOrEqualTo,
        value: isLessThanOrEqualTo,
      ));
    }
    if (startsWith != null) {
      _filters.add(QueryFilter(
        field: field,
        operator: QueryOperator.startsWith,
        value: startsWith,
      ));
    }
    if (endsWith != null) {
      _filters.add(QueryFilter(
        field: field,
        operator: QueryOperator.endsWith,
        value: endsWith,
      ));
    }
    if (contains != null) {
      _filters.add(QueryFilter(
        field: field,
        operator: QueryOperator.contains,
        value: contains,
      ));
    }
    if (arrayContains != null) {
      _filters.add(QueryFilter(
        field: field,
        operator: QueryOperator.arrayContains,
        value: arrayContains,
      ));
    }
    if (arrayContainsAny != null) {
      _filters.add(QueryFilter(
        field: field,
        operator: QueryOperator.arrayContainsAny,
        value: arrayContainsAny,
      ));
    }
    if (whereIn != null) {
      _filters.add(QueryFilter(
        field: field,
        operator: QueryOperator.whereIn,
        value: whereIn,
      ));
    }
    if (whereNotIn != null) {
      _filters.add(QueryFilter(
        field: field,
        operator: QueryOperator.whereNotIn,
        value: whereNotIn,
      ));
    }
    if (isNull == true) {
      _filters.add(QueryFilter(
        field: field,
        operator: QueryOperator.isNull,
        value: null,
      ));
    }
    if (isNull == false) {
      _filters.add(QueryFilter(
        field: field,
        operator: QueryOperator.isNotNull,
        value: null,
      ));
    }

    return this;
  }

  /// Adds a sort order to the query
  QueryBuilder orderBy(String field, {bool descending = false}) {
    _sorts.add(QuerySort(field: field, descending: descending));
    return this;
  }

  /// Limits the number of results
  QueryBuilder limit(int count) {
    if (count < 0) {
      throw ArgumentError('Limit must be non-negative');
    }
    _limit = count;
    return this;
  }

  /// Skips a number of results (for pagination)
  QueryBuilder offset(int count) {
    if (count < 0) {
      throw ArgumentError('Offset must be non-negative');
    }
    _offset = count;
    return this;
  }

  /// Executes the query and returns the results
  Future<List<Map<String, dynamic>>> get() async {
    final localStorage = SyncLayerCore.instance.localStorage;

    // Get all data from collection (returns List<DataRecord>)
    final allRecords = await localStorage.getAllData(collectionName);

    // Convert DataRecord to Map<String, dynamic>
    final allData = allRecords.map((record) {
      return jsonDecode(record.data) as Map<String, dynamic>;
    }).toList();

    // Apply filters
    var results = allData.where((data) {
      return _filters.every((filter) => filter.matches(data));
    }).toList();

    // Apply sorting
    if (_sorts.isNotEmpty) {
      results.sort((a, b) {
        for (final sort in _sorts) {
          final comparison = sort.compare(a, b);
          if (comparison != 0) return comparison;
        }
        return 0;
      });
    }

    // Apply offset
    if (_offset != null && _offset! > 0) {
      results = results.skip(_offset!).toList();
    }

    // Apply limit
    if (_limit != null && _limit! > 0) {
      results = results.take(_limit!).toList();
    }

    return results;
  }

  /// Watches the query results for changes
  Stream<List<Map<String, dynamic>>> watch() {
    final localStorage = SyncLayerCore.instance.localStorage;

    // Watch the collection and apply filters/sorts on each update
    return localStorage.watchCollection(collectionName).asyncMap((_) async {
      return await get();
    });
  }

  /// Returns the first result or null
  Future<Map<String, dynamic>?> first() async {
    final results = await limit(1).get();
    return results.isEmpty ? null : results.first;
  }

  /// Returns the count of matching documents
  Future<int> count() async {
    final results = await get();
    return results.length;
  }

  @override
  String toString() {
    return 'QueryBuilder(collection: $collectionName, filters: $_filters, sorts: $_sorts, limit: $_limit, offset: $_offset)';
  }
}
