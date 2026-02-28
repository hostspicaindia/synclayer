import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';
import '../test_infrastructure.dart';

void main() {
  late TestEnvironment env;

  setUp(() async {
    env = TestEnvironment();
    await env.setUp();
    await env.initSyncLayer(enableAutoSync: false);
  });

  tearDown(() async {
    await env.tearDown();
  });

  group('QueryBuilder - Basic Queries', () {
    test('should query all documents in collection', () async {
      // Create test data
      await SyncLayer.collection('users').save({'name': 'Alice', 'age': 30});
      await SyncLayer.collection('users').save({'name': 'Bob', 'age': 25});
      await SyncLayer.collection('users').save({'name': 'Charlie', 'age': 35});

      final results = await SyncLayer.collection('users').getAll();

      expect(results.length, 3);
    });

    test('should return empty list for empty collection', () async {
      final results = await SyncLayer.collection('empty').getAll();

      expect(results, isEmpty);
    });
  });

  group('QueryBuilder - Equality Filters', () {
    setUp(() async {
      await SyncLayer.collection('products').save({
        'name': 'Laptop',
        'price': 999.99,
        'category': 'Electronics',
        'inStock': true,
      });
      await SyncLayer.collection('products').save({
        'name': 'Mouse',
        'price': 29.99,
        'category': 'Electronics',
        'inStock': true,
      });
      await SyncLayer.collection('products').save({
        'name': 'Desk',
        'price': 299.99,
        'category': 'Furniture',
        'inStock': false,
      });
    });

    test('should filter by isEqualTo', () async {
      final results = await SyncLayer.collection('products')
          .where('category', isEqualTo: 'Electronics')
          .get();

      expect(results.length, 2);
      expect(results.every((r) => r['category'] == 'Electronics'), isTrue);
    });

    test('should filter by isNotEqualTo', () async {
      final results = await SyncLayer.collection('products')
          .where('category', isNotEqualTo: 'Electronics')
          .get();

      expect(results.length, 1);
      expect(results.first['category'], 'Furniture');
    });

    test('should filter by boolean value', () async {
      final results = await SyncLayer.collection('products')
          .where('inStock', isEqualTo: true)
          .get();

      expect(results.length, 2);
      expect(results.every((r) => r['inStock'] == true), isTrue);
    });
  });

  group('QueryBuilder - Comparison Filters', () {
    setUp(() async {
      for (int i = 1; i <= 10; i++) {
        await SyncLayer.collection('scores').save({
          'player': 'Player$i',
          'score': i * 10,
        });
      }
    });

    test('should filter by isGreaterThan', () async {
      final results = await SyncLayer.collection('scores')
          .where('score', isGreaterThan: 50)
          .get();

      expect(results.length, 5);
      expect(results.every((r) => r['score'] > 50), isTrue);
    });

    test('should filter by isGreaterThanOrEqualTo', () async {
      final results = await SyncLayer.collection('scores')
          .where('score', isGreaterThanOrEqualTo: 50)
          .get();

      expect(results.length, 6);
      expect(results.every((r) => r['score'] >= 50), isTrue);
    });

    test('should filter by isLessThan', () async {
      final results = await SyncLayer.collection('scores')
          .where('score', isLessThan: 50)
          .get();

      expect(results.length, 4);
      expect(results.every((r) => r['score'] < 50), isTrue);
    });

    test('should filter by isLessThanOrEqualTo', () async {
      final results = await SyncLayer.collection('scores')
          .where('score', isLessThanOrEqualTo: 50)
          .get();

      expect(results.length, 5);
      expect(results.every((r) => r['score'] <= 50), isTrue);
    });

    test('should combine multiple comparison filters', () async {
      final results = await SyncLayer.collection('scores')
          .where('score', isGreaterThanOrEqualTo: 30)
          .where('score', isLessThanOrEqualTo: 70)
          .get();

      expect(results.length, 5);
      expect(
          results.every((r) => r['score'] >= 30 && r['score'] <= 70), isTrue);
    });
  });

  group('QueryBuilder - String Filters', () {
    setUp(() async {
      await SyncLayer.collection('users').save({'email': 'alice@example.com'});
      await SyncLayer.collection('users').save({'email': 'bob@test.com'});
      await SyncLayer.collection('users')
          .save({'email': 'charlie@example.org'});
      await SyncLayer.collection('users').save({'email': 'david@example.com'});
    });

    test('should filter by startsWith', () async {
      final results = await SyncLayer.collection('users')
          .where('email', startsWith: 'alice')
          .get();

      expect(results.length, 1);
      expect(results.first['email'], 'alice@example.com');
    });

    test('should filter by endsWith', () async {
      final results = await SyncLayer.collection('users')
          .where('email', endsWith: '.com')
          .get();

      expect(results.length, 3);
      expect(results.every((r) => (r['email'] as String).endsWith('.com')),
          isTrue);
    });

    test('should filter by contains', () async {
      final results = await SyncLayer.collection('users')
          .where('email', contains: 'example')
          .get();

      expect(results.length, 3);
      expect(results.every((r) => (r['email'] as String).contains('example')),
          isTrue);
    });
  });

  group('QueryBuilder - Array Filters', () {
    setUp(() async {
      await SyncLayer.collection('posts').save({
        'title': 'Post 1',
        'tags': ['flutter', 'dart', 'mobile'],
      });
      await SyncLayer.collection('posts').save({
        'title': 'Post 2',
        'tags': ['web', 'javascript'],
      });
      await SyncLayer.collection('posts').save({
        'title': 'Post 3',
        'tags': ['flutter', 'web'],
      });
    });

    test('should filter by arrayContains', () async {
      final results = await SyncLayer.collection('posts')
          .where('tags', arrayContains: 'flutter')
          .get();

      expect(results.length, 2);
      expect(results.every((r) => (r['tags'] as List).contains('flutter')),
          isTrue);
    });

    test('should filter by arrayContainsAny', () async {
      final results = await SyncLayer.collection('posts')
          .where('tags', arrayContainsAny: ['dart', 'javascript']).get();

      expect(results.length, 2);
    });
  });

  group('QueryBuilder - In/Not In Filters', () {
    setUp(() async {
      await SyncLayer.collection('items')
          .save({'status': 'active', 'priority': 1});
      await SyncLayer.collection('items')
          .save({'status': 'pending', 'priority': 2});
      await SyncLayer.collection('items')
          .save({'status': 'completed', 'priority': 3});
      await SyncLayer.collection('items')
          .save({'status': 'archived', 'priority': 4});
    });

    test('should filter by whereIn', () async {
      final results = await SyncLayer.collection('items')
          .where('status', whereIn: ['active', 'pending']).get();

      expect(results.length, 2);
      expect(results.every((r) => ['active', 'pending'].contains(r['status'])),
          isTrue);
    });

    test('should filter by whereNotIn', () async {
      final results = await SyncLayer.collection('items')
          .where('status', whereNotIn: ['archived', 'completed']).get();

      expect(results.length, 2);
      expect(
          results
              .every((r) => !['archived', 'completed'].contains(r['status'])),
          isTrue);
    });
  });

  group('QueryBuilder - Null Filters', () {
    setUp(() async {
      await SyncLayer.collection('data')
          .save({'field': 'value', 'optional': 'present'});
      await SyncLayer.collection('data')
          .save({'field': 'value2', 'optional': null});
      await SyncLayer.collection('data').save({'field': 'value3'});
    });

    test('should filter by isNull', () async {
      final results = await SyncLayer.collection('data')
          .where('optional', isNull: true)
          .get();

      expect(results.length, 2);
    });

    test('should filter by isNotNull', () async {
      final results = await SyncLayer.collection('data')
          .where('optional', isNull: false)
          .get();

      expect(results.length, 1);
      expect(results.first['optional'], 'present');
    });
  });

  group('QueryBuilder - Sorting', () {
    setUp(() async {
      await SyncLayer.collection('books')
          .save({'title': 'Zebra', 'year': 2020});
      await SyncLayer.collection('books')
          .save({'title': 'Apple', 'year': 2022});
      await SyncLayer.collection('books')
          .save({'title': 'Mango', 'year': 2021});
    });

    test('should sort ascending by default', () async {
      final results =
          await SyncLayer.collection('books').orderBy('title').get();

      expect(results[0]['title'], 'Apple');
      expect(results[1]['title'], 'Mango');
      expect(results[2]['title'], 'Zebra');
    });

    test('should sort descending', () async {
      final results = await SyncLayer.collection('books')
          .orderBy('title', descending: true)
          .get();

      expect(results[0]['title'], 'Zebra');
      expect(results[1]['title'], 'Mango');
      expect(results[2]['title'], 'Apple');
    });

    test('should sort by numeric field', () async {
      final results = await SyncLayer.collection('books').orderBy('year').get();

      expect(results[0]['year'], 2020);
      expect(results[1]['year'], 2021);
      expect(results[2]['year'], 2022);
    });

    test('should support multiple sort orders', () async {
      await SyncLayer.collection('employees')
          .save({'name': 'Alice', 'dept': 'IT', 'salary': 80000});
      await SyncLayer.collection('employees')
          .save({'name': 'Bob', 'dept': 'IT', 'salary': 90000});
      await SyncLayer.collection('employees')
          .save({'name': 'Charlie', 'dept': 'HR', 'salary': 70000});

      final results = await SyncLayer.collection('employees')
          .orderBy('dept')
          .orderBy('salary', descending: true)
          .get();

      expect(results[0]['name'], 'Charlie'); // HR
      expect(results[1]['name'], 'Bob'); // IT, higher salary
      expect(results[2]['name'], 'Alice'); // IT, lower salary
    });
  });

  group('QueryBuilder - Pagination', () {
    setUp(() async {
      for (int i = 1; i <= 20; i++) {
        await SyncLayer.collection('items').save({'id': i, 'name': 'Item $i'});
      }
    });

    test('should limit results', () async {
      final results = await SyncLayer.collection('items').limit(5).get();

      expect(results.length, 5);
    });

    test('should skip results with offset', () async {
      final results =
          await SyncLayer.collection('items').orderBy('id').offset(10).get();

      expect(results.length, 10);
      expect(results.first['id'], 11);
    });

    test('should combine limit and offset for pagination', () async {
      // Page 1
      final page1 = await SyncLayer.collection('items')
          .orderBy('id')
          .limit(5)
          .offset(0)
          .get();

      // Page 2
      final page2 = await SyncLayer.collection('items')
          .orderBy('id')
          .limit(5)
          .offset(5)
          .get();

      expect(page1.length, 5);
      expect(page2.length, 5);
      expect(page1.first['id'], 1);
      expect(page2.first['id'], 6);
    });

    test('should throw error for negative limit', () {
      expect(
        () => SyncLayer.collection('items').limit(-1),
        throwsArgumentError,
      );
    });

    test('should throw error for negative offset', () {
      expect(
        () => SyncLayer.collection('items').offset(-1),
        throwsArgumentError,
      );
    });
  });

  group('QueryBuilder - Helper Methods', () {
    setUp(() async {
      await SyncLayer.collection('tasks')
          .save({'title': 'Task 1', 'done': false});
      await SyncLayer.collection('tasks')
          .save({'title': 'Task 2', 'done': true});
      await SyncLayer.collection('tasks')
          .save({'title': 'Task 3', 'done': false});
    });

    test('should return first result', () async {
      final result = await SyncLayer.collection('tasks')
          .where('done', isEqualTo: true)
          .first();

      expect(result, isNotNull);
      expect(result!['title'], 'Task 2');
    });

    test('should return null when no results', () async {
      final result = await SyncLayer.collection('tasks')
          .where('done', isEqualTo: 'invalid')
          .first();

      expect(result, isNull);
    });

    test('should count results', () async {
      final count = await SyncLayer.collection('tasks')
          .where('done', isEqualTo: false)
          .count();

      expect(count, 2);
    });

    test('should count all results', () async {
      final allTasks = await SyncLayer.collection('tasks').getAll();
      final count = allTasks.length;

      expect(count, 3);
    });
  });

  group('QueryBuilder - Complex Queries', () {
    setUp(() async {
      await SyncLayer.collection('products').save({
        'name': 'Laptop Pro',
        'category': 'Electronics',
        'price': 1999.99,
        'rating': 4.5,
        'tags': ['premium', 'business'],
        'inStock': true,
      });
      await SyncLayer.collection('products').save({
        'name': 'Budget Laptop',
        'category': 'Electronics',
        'price': 499.99,
        'rating': 3.8,
        'tags': ['budget', 'student'],
        'inStock': true,
      });
      await SyncLayer.collection('products').save({
        'name': 'Gaming Mouse',
        'category': 'Accessories',
        'price': 79.99,
        'rating': 4.7,
        'tags': ['gaming', 'rgb'],
        'inStock': false,
      });
      await SyncLayer.collection('products').save({
        'name': 'Office Chair',
        'category': 'Furniture',
        'price': 299.99,
        'rating': 4.2,
        'tags': ['ergonomic', 'office'],
        'inStock': true,
      });
    });

    test('should combine multiple filters', () async {
      final results = await SyncLayer.collection('products')
          .where('category', isEqualTo: 'Electronics')
          .where('price', isLessThan: 1000)
          .where('inStock', isEqualTo: true)
          .get();

      expect(results.length, 1);
      expect(results.first['name'], 'Budget Laptop');
    });

    test('should filter, sort, and paginate', () async {
      final results = await SyncLayer.collection('products')
          .where('inStock', isEqualTo: true)
          .orderBy('price', descending: true)
          .limit(2)
          .get();

      expect(results.length, 2);
      expect(results.first['name'], 'Laptop Pro');
      expect(results.last['name'], 'Budget Laptop');
    });

    test('should handle complex array and string filters', () async {
      final results = await SyncLayer.collection('products')
          .where('name', contains: 'Laptop')
          .where('tags', arrayContains: 'business')
          .get();

      expect(results.length, 1);
      expect(results.first['name'], 'Laptop Pro');
    });
  });

  group('QueryBuilder - Watch Stream', () {
    test('should watch query results for changes', () async {
      final stream =
          SyncLayer.collection('live').where('value', isGreaterThan: 0).watch();

      // Collect emitted values
      final emissions = <List<Map<String, dynamic>>>[];
      final subscription = stream.listen(emissions.add);

      // Wait for initial emission
      await Future.delayed(const Duration(milliseconds: 100));

      // Add data
      await SyncLayer.collection('live').save({'value': 1});
      await Future.delayed(const Duration(milliseconds: 100));

      await SyncLayer.collection('live').save({'value': 2});
      await Future.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      // Should have received multiple emissions
      expect(emissions.length, greaterThan(1));
    });
  });

  group('QueryBuilder - Performance', () {
    test('should query 1000 documents efficiently', () async {
      // Create 1000 documents
      for (int i = 0; i < 1000; i++) {
        await SyncLayer.collection('large').save({
          'id': i,
          'category': i % 10,
          'value': i * 2,
        });
      }

      final stopwatch = Stopwatch()..start();

      final results = await SyncLayer.collection('large')
          .where('category', isEqualTo: 5)
          .orderBy('value')
          .limit(50)
          .get();

      stopwatch.stop();

      expect(results.length, 50);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // < 1 second
    });
  });
}
