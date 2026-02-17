import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/query/query_filter.dart';
import 'package:synclayer/query/query_operators.dart';
import 'package:synclayer/query/query_sort.dart';

void main() {
  group('QueryFilter', () {
    test('isEqualTo matches correctly', () {
      final filter = QueryFilter(
        field: 'status',
        operator: QueryOperator.isEqualTo,
        value: 'active',
      );

      expect(filter.matches({'status': 'active'}), true);
      expect(filter.matches({'status': 'inactive'}), false);
    });

    test('isNotEqualTo matches correctly', () {
      final filter = QueryFilter(
        field: 'status',
        operator: QueryOperator.isNotEqualTo,
        value: 'deleted',
      );

      expect(filter.matches({'status': 'active'}), true);
      expect(filter.matches({'status': 'deleted'}), false);
    });

    test('isGreaterThan matches correctly', () {
      final filter = QueryFilter(
        field: 'priority',
        operator: QueryOperator.isGreaterThan,
        value: 5,
      );

      expect(filter.matches({'priority': 10}), true);
      expect(filter.matches({'priority': 5}), false);
      expect(filter.matches({'priority': 3}), false);
    });

    test('isLessThan matches correctly', () {
      final filter = QueryFilter(
        field: 'priority',
        operator: QueryOperator.isLessThan,
        value: 5,
      );

      expect(filter.matches({'priority': 3}), true);
      expect(filter.matches({'priority': 5}), false);
      expect(filter.matches({'priority': 10}), false);
    });

    test('startsWith matches correctly', () {
      final filter = QueryFilter(
        field: 'name',
        operator: QueryOperator.startsWith,
        value: 'John',
      );

      expect(filter.matches({'name': 'John Doe'}), true);
      expect(filter.matches({'name': 'Jane Doe'}), false);
    });

    test('contains matches correctly', () {
      final filter = QueryFilter(
        field: 'description',
        operator: QueryOperator.contains,
        value: 'urgent',
      );

      expect(filter.matches({'description': 'This is urgent'}), true);
      expect(filter.matches({'description': 'Not important'}), false);
    });

    test('arrayContains matches correctly', () {
      final filter = QueryFilter(
        field: 'tags',
        operator: QueryOperator.arrayContains,
        value: 'work',
      );

      expect(
          filter.matches({
            'tags': ['work', 'important']
          }),
          true);
      expect(
          filter.matches({
            'tags': ['personal', 'home']
          }),
          false);
    });

    test('whereIn matches correctly', () {
      final filter = QueryFilter(
        field: 'status',
        operator: QueryOperator.whereIn,
        value: ['active', 'pending'],
      );

      expect(filter.matches({'status': 'active'}), true);
      expect(filter.matches({'status': 'pending'}), true);
      expect(filter.matches({'status': 'completed'}), false);
    });

    test('isNull matches correctly', () {
      final filter = QueryFilter(
        field: 'deletedAt',
        operator: QueryOperator.isNull,
        value: null,
      );

      expect(filter.matches({'deletedAt': null}), true);
      expect(filter.matches({'deletedAt': '2024-01-01'}), false);
      expect(filter.matches({}), true); // Missing field is null
    });

    test('isNotNull matches correctly', () {
      final filter = QueryFilter(
        field: 'createdAt',
        operator: QueryOperator.isNotNull,
        value: null,
      );

      expect(filter.matches({'createdAt': '2024-01-01'}), true);
      expect(filter.matches({'createdAt': null}), false);
      expect(filter.matches({}), false); // Missing field is null
    });

    test('nested field access works', () {
      final filter = QueryFilter(
        field: 'user.name',
        operator: QueryOperator.isEqualTo,
        value: 'John',
      );

      expect(
          filter.matches({
            'user': {'name': 'John'}
          }),
          true);
      expect(
          filter.matches({
            'user': {'name': 'Jane'}
          }),
          false);
    });

    test('handles missing fields gracefully', () {
      final filter = QueryFilter(
        field: 'nonexistent',
        operator: QueryOperator.isEqualTo,
        value: 'test',
      );

      expect(filter.matches({}), false);
      expect(filter.matches({'other': 'value'}), false);
    });
  });

  group('QuerySort', () {
    test('sorts numbers ascending', () {
      final sort = QuerySort(field: 'priority');

      final data = [
        {'priority': 5},
        {'priority': 1},
        {'priority': 10},
        {'priority': 3},
      ];

      data.sort(sort.compare);

      expect(data[0]['priority'], 1);
      expect(data[1]['priority'], 3);
      expect(data[2]['priority'], 5);
      expect(data[3]['priority'], 10);
    });

    test('sorts numbers descending', () {
      final sort = QuerySort(field: 'priority', descending: true);

      final data = [
        {'priority': 5},
        {'priority': 1},
        {'priority': 10},
        {'priority': 3},
      ];

      data.sort(sort.compare);

      expect(data[0]['priority'], 10);
      expect(data[1]['priority'], 5);
      expect(data[2]['priority'], 3);
      expect(data[3]['priority'], 1);
    });

    test('sorts strings alphabetically', () {
      final sort = QuerySort(field: 'name');

      final data = [
        {'name': 'Charlie'},
        {'name': 'Alice'},
        {'name': 'Bob'},
      ];

      data.sort(sort.compare);

      expect(data[0]['name'], 'Alice');
      expect(data[1]['name'], 'Bob');
      expect(data[2]['name'], 'Charlie');
    });

    test('handles null values (nulls last)', () {
      final sort = QuerySort(field: 'priority');

      final data = [
        {'priority': 5},
        {'priority': null},
        {'priority': 1},
      ];

      data.sort(sort.compare);

      expect(data[0]['priority'], 1);
      expect(data[1]['priority'], 5);
      expect(data[2]['priority'], null);
    });

    test('sorts nested fields', () {
      final sort = QuerySort(field: 'user.age');

      final data = [
        {
          'user': {'age': 30}
        },
        {
          'user': {'age': 25}
        },
        {
          'user': {'age': 35}
        },
      ];

      data.sort(sort.compare);

      expect((data[0]['user'] as Map)['age'], 25);
      expect((data[1]['user'] as Map)['age'], 30);
      expect((data[2]['user'] as Map)['age'], 35);
    });
  });

  group('Multiple Filters', () {
    test('combines multiple filters with AND logic', () {
      final filters = [
        QueryFilter(
          field: 'status',
          operator: QueryOperator.isEqualTo,
          value: 'active',
        ),
        QueryFilter(
          field: 'priority',
          operator: QueryOperator.isGreaterThan,
          value: 5,
        ),
      ];

      final data = [
        {'status': 'active', 'priority': 10}, // Matches both
        {'status': 'active', 'priority': 3}, // Matches first only
        {'status': 'inactive', 'priority': 10}, // Matches second only
        {'status': 'inactive', 'priority': 3}, // Matches neither
      ];

      final results = data.where((item) {
        return filters.every((filter) => filter.matches(item));
      }).toList();

      expect(results.length, 1);
      expect(results[0]['priority'], 10);
    });
  });

  group('Multiple Sorts', () {
    test('applies multiple sort orders', () {
      final sorts = [
        QuerySort(field: 'priority', descending: true),
        QuerySort(field: 'name'),
      ];

      final data = [
        {'priority': 5, 'name': 'Charlie'},
        {'priority': 10, 'name': 'Bob'},
        {'priority': 5, 'name': 'Alice'},
        {'priority': 10, 'name': 'Alice'},
      ];

      data.sort((a, b) {
        for (final sort in sorts) {
          final comparison = sort.compare(a, b);
          if (comparison != 0) return comparison;
        }
        return 0;
      });

      // Should be sorted by priority DESC, then name ASC
      expect(data[0]['priority'], 10);
      expect(data[0]['name'], 'Alice');
      expect(data[1]['priority'], 10);
      expect(data[1]['name'], 'Bob');
      expect(data[2]['priority'], 5);
      expect(data[2]['name'], 'Alice');
      expect(data[3]['priority'], 5);
      expect(data[3]['name'], 'Charlie');
    });
  });
}
