import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/query/query_filter.dart';
import 'package:synclayer/query/query_operators.dart';
import 'package:synclayer/query/query_sort.dart';

void main() {
  group('Comparison Operators - Complete Coverage', () {
    test('isEqualTo with different data types', () {
      final filter = QueryFilter(
        field: 'value',
        operator: QueryOperator.isEqualTo,
        value: 42,
      );

      expect(filter.matches({'value': 42}), true);
      expect(filter.matches({'value': 43}), false);
      expect(filter.matches({'value': '42'}), false); // Type mismatch
      expect(filter.matches({'value': null}), false);
      expect(filter.matches({}), false); // Missing field
    });

    test('isNotEqualTo with edge cases', () {
      final filter = QueryFilter(
        field: 'status',
        operator: QueryOperator.isNotEqualTo,
        value: 'deleted',
      );

      expect(filter.matches({'status': 'active'}), true);
      expect(filter.matches({'status': 'deleted'}), false);
      expect(filter.matches({'status': null}), true);
      expect(filter.matches({}), true); // Missing field != 'deleted'
    });

    test('isGreaterThan with numbers', () {
      final filter = QueryFilter(
        field: 'score',
        operator: QueryOperator.isGreaterThan,
        value: 50,
      );

      expect(filter.matches({'score': 51}), true);
      expect(filter.matches({'score': 100}), true);
      expect(filter.matches({'score': 50}), false);
      expect(filter.matches({'score': 49}), false);
      expect(filter.matches({'score': null}), false);
    });

    test('isGreaterThanOrEqualTo boundary test', () {
      final filter = QueryFilter(
        field: 'age',
        operator: QueryOperator.isGreaterThanOrEqualTo,
        value: 18,
      );

      expect(filter.matches({'age': 18}), true); // Boundary
      expect(filter.matches({'age': 19}), true);
      expect(filter.matches({'age': 17}), false);
      expect(filter.matches({'age': 0}), false);
    });

    test('isLessThan with negative numbers', () {
      final filter = QueryFilter(
        field: 'temperature',
        operator: QueryOperator.isLessThan,
        value: 0,
      );

      expect(filter.matches({'temperature': -1}), true);
      expect(filter.matches({'temperature': -100}), true);
      expect(filter.matches({'temperature': 0}), false);
      expect(filter.matches({'temperature': 1}), false);
    });

    test('isLessThanOrEqualTo with decimals', () {
      final filter = QueryFilter(
        field: 'price',
        operator: QueryOperator.isLessThanOrEqualTo,
        value: 99.99,
      );

      expect(filter.matches({'price': 99.99}), true); // Boundary
      expect(filter.matches({'price': 50.00}), true);
      expect(filter.matches({'price': 100.00}), false);
    });
  });

  group('String Operators - Complete Coverage', () {
    test('startsWith case sensitivity', () {
      final filter = QueryFilter(
        field: 'name',
        operator: QueryOperator.startsWith,
        value: 'John',
      );

      expect(filter.matches({'name': 'John Doe'}), true);
      expect(filter.matches({'name': 'Johnny'}), true);
      expect(filter.matches({'name': 'john doe'}), false); // Case sensitive
      expect(filter.matches({'name': 'Jane Doe'}), false);
      expect(filter.matches({'name': ''}), false);
    });

    test('endsWith with special characters', () {
      final filter = QueryFilter(
        field: 'email',
        operator: QueryOperator.endsWith,
        value: '@gmail.com',
      );

      expect(filter.matches({'email': 'user@gmail.com'}), true);
      expect(filter.matches({'email': 'test@gmail.com'}), true);
      expect(filter.matches({'email': 'user@yahoo.com'}), false);
      expect(filter.matches({'email': '@gmail.com'}), true); // Edge case
    });

    test('contains with empty string', () {
      final filter = QueryFilter(
        field: 'description',
        operator: QueryOperator.contains,
        value: '',
      );

      expect(filter.matches({'description': 'anything'}), true);
      expect(filter.matches({'description': ''}), true);
      expect(filter.matches({'description': 'test'}), true);
    });

    test('contains with special characters', () {
      final filter = QueryFilter(
        field: 'text',
        operator: QueryOperator.contains,
        value: 'C++',
      );

      expect(filter.matches({'text': 'I love C++'}), true);
      expect(filter.matches({'text': 'C++ programming'}), true);
      expect(filter.matches({'text': 'C# programming'}), false);
    });
  });

  group('Array Operators - Complete Coverage', () {
    test('arrayContains with different types', () {
      final numberFilter = QueryFilter(
        field: 'numbers',
        operator: QueryOperator.arrayContains,
        value: 5,
      );

      expect(
          numberFilter.matches({
            'numbers': [1, 2, 3, 4, 5]
          }),
          true);
      expect(
          numberFilter.matches({
            'numbers': [1, 2, 3]
          }),
          false);

      final stringFilter = QueryFilter(
        field: 'tags',
        operator: QueryOperator.arrayContains,
        value: 'urgent',
      );

      expect(
          stringFilter.matches({
            'tags': ['work', 'urgent']
          }),
          true);
      expect(
          stringFilter.matches({
            'tags': ['work', 'normal']
          }),
          false);
    });

    test('arrayContains with empty array', () {
      final filter = QueryFilter(
        field: 'items',
        operator: QueryOperator.arrayContains,
        value: 'test',
      );

      expect(filter.matches({'items': []}), false);
      expect(filter.matches({'items': null}), false);
      expect(filter.matches({}), false);
    });

    test('arrayContainsAny with multiple matches', () {
      final filter = QueryFilter(
        field: 'tags',
        operator: QueryOperator.arrayContainsAny,
        value: ['urgent', 'important', 'critical'],
      );

      expect(
          filter.matches({
            'tags': ['work', 'urgent']
          }),
          true);
      expect(
          filter.matches({
            'tags': ['important', 'meeting']
          }),
          true);
      expect(
          filter.matches({
            'tags': ['work', 'normal']
          }),
          false);
      expect(filter.matches({'tags': []}), false);
    });

    test('whereIn with various values', () {
      final filter = QueryFilter(
        field: 'status',
        operator: QueryOperator.whereIn,
        value: ['active', 'pending', 'processing'],
      );

      expect(filter.matches({'status': 'active'}), true);
      expect(filter.matches({'status': 'pending'}), true);
      expect(filter.matches({'status': 'completed'}), false);
      expect(filter.matches({'status': null}), false);
    });

    test('whereNotIn exclusion test', () {
      final filter = QueryFilter(
        field: 'status',
        operator: QueryOperator.whereNotIn,
        value: ['deleted', 'archived', 'spam'],
      );

      expect(filter.matches({'status': 'active'}), true);
      expect(filter.matches({'status': 'deleted'}), false);
      expect(filter.matches({'status': 'archived'}), false);
      expect(filter.matches({'status': null}), true); // null not in list
    });
  });

  group('Null Operators - Complete Coverage', () {
    test('isNull with various scenarios', () {
      final filter = QueryFilter(
        field: 'deletedAt',
        operator: QueryOperator.isNull,
        value: null,
      );

      expect(filter.matches({'deletedAt': null}), true);
      expect(filter.matches({}), true); // Missing field is null
      expect(filter.matches({'deletedAt': '2024-01-01'}), false);
      expect(filter.matches({'deletedAt': 0}), false);
      expect(filter.matches({'deletedAt': ''}), false);
      expect(filter.matches({'deletedAt': false}), false);
    });

    test('isNotNull with various scenarios', () {
      final filter = QueryFilter(
        field: 'createdAt',
        operator: QueryOperator.isNotNull,
        value: null,
      );

      expect(filter.matches({'createdAt': '2024-01-01'}), true);
      expect(filter.matches({'createdAt': 0}), true);
      expect(filter.matches({'createdAt': ''}), true);
      expect(filter.matches({'createdAt': false}), true);
      expect(filter.matches({'createdAt': null}), false);
      expect(filter.matches({}), false); // Missing field is null
    });
  });

  group('Nested Field Access - Complete Coverage', () {
    test('single level nesting', () {
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
      expect(filter.matches({'user': null}), false);
      expect(filter.matches({}), false);
    });

    test('deep nesting', () {
      final filter = QueryFilter(
        field: 'company.address.city',
        operator: QueryOperator.isEqualTo,
        value: 'New York',
      );

      expect(
          filter.matches({
            'company': {
              'address': {'city': 'New York'}
            }
          }),
          true);
      expect(
          filter.matches({
            'company': {
              'address': {'city': 'Boston'}
            }
          }),
          false);
      expect(
          filter.matches({
            'company': {'address': null}
          }),
          false);
    });

    test('nested with comparison operators', () {
      final filter = QueryFilter(
        field: 'user.age',
        operator: QueryOperator.isGreaterThan,
        value: 18,
      );

      expect(
          filter.matches({
            'user': {'age': 25}
          }),
          true);
      expect(
          filter.matches({
            'user': {'age': 15}
          }),
          false);
    });
  });

  group('Sorting - Complete Coverage', () {
    test('sort numbers ascending', () {
      final sort = QuerySort(field: 'priority');

      final data = [
        {'priority': 5},
        {'priority': 1},
        {'priority': 10},
        {'priority': 3},
        {'priority': 7},
      ];

      data.sort(sort.compare);

      expect(data[0]['priority'], 1);
      expect(data[1]['priority'], 3);
      expect(data[2]['priority'], 5);
      expect(data[3]['priority'], 7);
      expect(data[4]['priority'], 10);
    });

    test('sort numbers descending', () {
      final sort = QuerySort(field: 'score', descending: true);

      final data = [
        {'score': 50},
        {'score': 100},
        {'score': 25},
        {'score': 75},
      ];

      data.sort(sort.compare);

      expect(data[0]['score'], 100);
      expect(data[1]['score'], 75);
      expect(data[2]['score'], 50);
      expect(data[3]['score'], 25);
    });

    test('sort strings alphabetically', () {
      final sort = QuerySort(field: 'name');

      final data = [
        {'name': 'Zebra'},
        {'name': 'Apple'},
        {'name': 'Mango'},
        {'name': 'Banana'},
      ];

      data.sort(sort.compare);

      expect(data[0]['name'], 'Apple');
      expect(data[1]['name'], 'Banana');
      expect(data[2]['name'], 'Mango');
      expect(data[3]['name'], 'Zebra');
    });

    test('sort with null values (nulls last)', () {
      final sort = QuerySort(field: 'value');

      final data = [
        {'value': 5},
        {'value': null},
        {'value': 1},
        {'value': null},
        {'value': 3},
      ];

      data.sort(sort.compare);

      expect(data[0]['value'], 1);
      expect(data[1]['value'], 3);
      expect(data[2]['value'], 5);
      expect(data[3]['value'], null);
      expect(data[4]['value'], null);
    });

    test('sort booleans', () {
      final sort = QuerySort(field: 'done');

      final data = [
        {'done': true},
        {'done': false},
        {'done': true},
        {'done': false},
      ];

      data.sort(sort.compare);

      expect(data[0]['done'], false);
      expect(data[1]['done'], false);
      expect(data[2]['done'], true);
      expect(data[3]['done'], true);
    });

    test('sort dates', () {
      final sort = QuerySort(field: 'date', descending: true);

      final data = [
        {'date': DateTime(2024, 1, 1)},
        {'date': DateTime(2024, 12, 31)},
        {'date': DateTime(2024, 6, 15)},
      ];

      data.sort(sort.compare);

      expect(data[0]['date'], DateTime(2024, 12, 31));
      expect(data[1]['date'], DateTime(2024, 6, 15));
      expect(data[2]['date'], DateTime(2024, 1, 1));
    });

    test('multi-field sorting', () {
      final sorts = [
        QuerySort(field: 'category'),
        QuerySort(field: 'priority', descending: true),
        QuerySort(field: 'name'),
      ];

      final data = [
        {'category': 'B', 'priority': 5, 'name': 'Task 1'},
        {'category': 'A', 'priority': 10, 'name': 'Task 2'},
        {'category': 'A', 'priority': 10, 'name': 'Task 1'},
        {'category': 'A', 'priority': 5, 'name': 'Task 3'},
        {'category': 'B', 'priority': 10, 'name': 'Task 4'},
      ];

      data.sort((a, b) {
        for (final sort in sorts) {
          final comparison = sort.compare(a, b);
          if (comparison != 0) return comparison;
        }
        return 0;
      });

      // Should be sorted by: category ASC, priority DESC, name ASC
      expect(data[0]['category'], 'A');
      expect(data[0]['priority'], 10);
      expect(data[0]['name'], 'Task 1');

      expect(data[1]['category'], 'A');
      expect(data[1]['priority'], 10);
      expect(data[1]['name'], 'Task 2');
    });
  });

  group('Complex Query Scenarios', () {
    test('multiple filters with AND logic', () {
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
        QueryFilter(
          field: 'tags',
          operator: QueryOperator.arrayContains,
          value: 'urgent',
        ),
      ];

      final data = [
        {
          'status': 'active',
          'priority': 10,
          'tags': ['urgent', 'work']
        }, // Match
        {
          'status': 'active',
          'priority': 3,
          'tags': ['urgent']
        }, // No (priority)
        {
          'status': 'inactive',
          'priority': 10,
          'tags': ['urgent']
        }, // No (status)
        {
          'status': 'active',
          'priority': 10,
          'tags': ['normal']
        }, // No (tags)
      ];

      final results = data.where((item) {
        return filters.every((filter) => filter.matches(item));
      }).toList();

      expect(results.length, 1);
      expect(results[0]['priority'], 10);
    });

    test('filter + sort + pagination simulation', () {
      final filter = QueryFilter(
        field: 'done',
        operator: QueryOperator.isEqualTo,
        value: false,
      );

      final sort = QuerySort(field: 'priority', descending: true);

      final data = [
        {'id': 1, 'done': false, 'priority': 5},
        {'id': 2, 'done': true, 'priority': 10},
        {'id': 3, 'done': false, 'priority': 8},
        {'id': 4, 'done': false, 'priority': 3},
        {'id': 5, 'done': false, 'priority': 10},
        {'id': 6, 'done': true, 'priority': 7},
      ];

      // Filter
      var results = data.where((item) => filter.matches(item)).toList();
      expect(results.length, 4);

      // Sort
      results.sort(sort.compare);
      expect(results[0]['priority'], 10);
      expect(results[1]['priority'], 8);

      // Pagination (limit 2, offset 1)
      results = results.skip(1).take(2).toList();
      expect(results.length, 2);
      expect(results[0]['id'], 3); // priority 8
      expect(results[1]['id'], 1); // priority 5
    });

    test('nested field with string operator', () {
      final filter = QueryFilter(
        field: 'user.email',
        operator: QueryOperator.endsWith,
        value: '@company.com',
      );

      final data = [
        {
          'user': {'email': 'john@company.com'}
        },
        {
          'user': {'email': 'jane@gmail.com'}
        },
        {
          'user': {'email': 'bob@company.com'}
        },
      ];

      final results = data.where((item) => filter.matches(item)).toList();

      expect(results.length, 2);
    });

    test('whereIn with nested field', () {
      final filter = QueryFilter(
        field: 'metadata.status',
        operator: QueryOperator.whereIn,
        value: ['draft', 'pending', 'review'],
      );

      final data = [
        {
          'metadata': {'status': 'draft'}
        },
        {
          'metadata': {'status': 'published'}
        },
        {
          'metadata': {'status': 'pending'}
        },
      ];

      final results = data.where((item) => filter.matches(item)).toList();

      expect(results.length, 2);
    });
  });

  group('Edge Cases and Error Handling', () {
    test('filter on non-existent field', () {
      final filter = QueryFilter(
        field: 'nonexistent',
        operator: QueryOperator.isEqualTo,
        value: 'test',
      );

      expect(filter.matches({}), false);
      expect(filter.matches({'other': 'value'}), false);
    });

    test('sort on non-existent field', () {
      final sort = QuerySort(field: 'nonexistent');

      final data = [
        {'id': 1},
        {'id': 2},
      ];

      // Should not throw, nulls go last
      expect(() => data.sort(sort.compare), returnsNormally);
    });

    test('comparison with incompatible types', () {
      final filter = QueryFilter(
        field: 'value',
        operator: QueryOperator.isGreaterThan,
        value: 5,
      );

      // String vs number - should use string comparison as fallback
      expect(() => filter.matches({'value': 'text'}), returnsNormally);
    });

    test('empty string in various operators', () {
      final startsWithFilter = QueryFilter(
        field: 'text',
        operator: QueryOperator.startsWith,
        value: '',
      );

      expect(startsWithFilter.matches({'text': 'anything'}), true);
      expect(startsWithFilter.matches({'text': ''}), true);
    });

    test('array operators with non-array values', () {
      final filter = QueryFilter(
        field: 'tags',
        operator: QueryOperator.arrayContains,
        value: 'test',
      );

      expect(filter.matches({'tags': 'not-an-array'}), false);
      expect(filter.matches({'tags': 123}), false);
      expect(filter.matches({'tags': null}), false);
    });

    test('whereIn with non-list value', () {
      final filter = QueryFilter(
        field: 'status',
        operator: QueryOperator.whereIn,
        value: 'not-a-list', // Invalid
      );

      expect(filter.matches({'status': 'active'}), false);
    });
  });

  group('Performance and Large Dataset Tests', () {
    test('filter large dataset', () {
      final filter = QueryFilter(
        field: 'active',
        operator: QueryOperator.isEqualTo,
        value: true,
      );

      // Create 1000 items
      final data = List.generate(
        1000,
        (i) => {'id': i, 'active': i % 2 == 0},
      );

      final stopwatch = Stopwatch()..start();
      final results = data.where((item) => filter.matches(item)).toList();
      stopwatch.stop();

      expect(results.length, 500);
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast
    });

    test('sort large dataset', () {
      final sort = QuerySort(field: 'value');

      // Create 1000 items in random order
      final data = List.generate(1000, (i) => {'value': 1000 - i});

      final stopwatch = Stopwatch()..start();
      data.sort(sort.compare);
      stopwatch.stop();

      expect(data.first['value'], 1);
      expect(data.last['value'], 1000);
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('multiple filters on large dataset', () {
      final filters = [
        QueryFilter(
          field: 'category',
          operator: QueryOperator.isEqualTo,
          value: 'A',
        ),
        QueryFilter(
          field: 'score',
          operator: QueryOperator.isGreaterThan,
          value: 50,
        ),
      ];

      final data = List.generate(
        1000,
        (i) => {
          'id': i,
          'category': i % 3 == 0 ? 'A' : 'B',
          'score': i % 100,
        },
      );

      final stopwatch = Stopwatch()..start();
      final results = data.where((item) {
        return filters.every((filter) => filter.matches(item));
      }).toList();
      stopwatch.stop();

      expect(results.isNotEmpty, true);
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
