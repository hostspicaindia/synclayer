import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';
import 'dart:io';

void main() {
  group('Query Operations Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('synclayer_query_test_');
    });

    tearDown(() async {
      await SyncLayer.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('where() - Equality Operators', () {
      test('should filter with isEqualTo', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {'text': 'Buy milk', 'done': false},
          {'text': 'Buy eggs', 'done': true},
          {'text': 'Buy bread', 'done': false},
        ]);

        final results = await SyncLayer.collection('todos')
            .where('done', isEqualTo: false)
            .get();

        expect(results.length, equals(2));
        expect(results.every((doc) => doc['done'] == false), isTrue);
      });

      test('should filter with isNotEqualTo', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {'text': 'Task 1', 'status': 'active'},
          {'text': 'Task 2', 'status': 'completed'},
          {'text': 'Task 3', 'status': 'active'},
        ]);

        final results = await SyncLayer.collection('todos')
            .where('status', isNotEqualTo: 'completed')
            .get();

        expect(results.length, equals(2));
        expect(results.every((doc) => doc['status'] != 'completed'), isTrue);
      });

      test('should filter with isNull', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {'text': 'Task 1', 'priority': 5},
          {'text': 'Task 2', 'priority': null},
          {'text': 'Task 3'},
        ]);

        final results = await SyncLayer.collection('todos')
            .where('priority', isNull: true)
            .get();

        expect(results.length, equals(2));
      });

      test('should filter with isNull false (isNotNull)', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {'text': 'Task 1', 'priority': 5},
          {'text': 'Task 2', 'priority': null},
          {'text': 'Task 3'},
        ]);

        final results = await SyncLayer.collection('todos')
            .where('priority', isNull: false)
            .get();

        expect(results.length, equals(1));
        expect(results[0]['priority'], equals(5));
      });
    });

    group('where() - Comparison Operators', () {
      test('should filter with isGreaterThan', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['scores'],
        ));

        await SyncLayer.collection('scores').saveAll([
          {'player': 'Alice', 'score': 100},
          {'player': 'Bob', 'score': 150},
          {'player': 'Charlie', 'score': 200},
        ]);

        final results = await SyncLayer.collection('scores')
            .where('score', isGreaterThan: 120)
            .get();

        expect(results.length, equals(2));
        expect(results.every((doc) => doc['score'] > 120), isTrue);
      });

      test('should filter with isGreaterThanOrEqualTo', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['scores'],
        ));

        await SyncLayer.collection('scores').saveAll([
          {'player': 'Alice', 'score': 100},
          {'player': 'Bob', 'score': 150},
          {'player': 'Charlie', 'score': 200},
        ]);

        final results = await SyncLayer.collection('scores')
            .where('score', isGreaterThanOrEqualTo: 150)
            .get();

        expect(results.length, equals(2));
        expect(results.every((doc) => doc['score'] >= 150), isTrue);
      });

      test('should filter with isLessThan', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['scores'],
        ));

        await SyncLayer.collection('scores').saveAll([
          {'player': 'Alice', 'score': 100},
          {'player': 'Bob', 'score': 150},
          {'player': 'Charlie', 'score': 200},
        ]);

        final results = await SyncLayer.collection('scores')
            .where('score', isLessThan: 180)
            .get();

        expect(results.length, equals(2));
        expect(results.every((doc) => doc['score'] < 180), isTrue);
      });

      test('should filter with isLessThanOrEqualTo', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['scores'],
        ));

        await SyncLayer.collection('scores').saveAll([
          {'player': 'Alice', 'score': 100},
          {'player': 'Bob', 'score': 150},
          {'player': 'Charlie', 'score': 200},
        ]);

        final results = await SyncLayer.collection('scores')
            .where('score', isLessThanOrEqualTo: 150)
            .get();

        expect(results.length, equals(2));
        expect(results.every((doc) => doc['score'] <= 150), isTrue);
      });
    });

    group('where() - String Operators', () {
      test('should filter with startsWith', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {'text': 'Buy milk'},
          {'text': 'Buy eggs'},
          {'text': 'Sell car'},
        ]);

        final results = await SyncLayer.collection('todos')
            .where('text', startsWith: 'Buy')
            .get();

        expect(results.length, equals(2));
        expect(results.every((doc) => doc['text'].startsWith('Buy')), isTrue);
      });

      test('should filter with endsWith', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['files'],
        ));

        await SyncLayer.collection('files').saveAll([
          {'name': 'document.pdf'},
          {'name': 'image.png'},
          {'name': 'report.pdf'},
        ]);

        final results = await SyncLayer.collection('files')
            .where('name', endsWith: '.pdf')
            .get();

        expect(results.length, equals(2));
        expect(results.every((doc) => doc['name'].endsWith('.pdf')), isTrue);
      });

      test('should filter with contains', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {'text': 'Buy milk from store'},
          {'text': 'Buy eggs'},
          {'text': 'Store the documents'},
        ]);

        final results = await SyncLayer.collection('todos')
            .where('text', contains: 'store')
            .get();

        expect(results.length, equals(2));
      });
    });

    group('where() - Array Operators', () {
      test('should filter with arrayContains', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {
            'text': 'Task 1',
            'tags': ['work', 'urgent']
          },
          {
            'text': 'Task 2',
            'tags': ['personal', 'urgent']
          },
          {
            'text': 'Task 3',
            'tags': ['work']
          },
        ]);

        final results = await SyncLayer.collection('todos')
            .where('tags', arrayContains: 'urgent')
            .get();

        expect(results.length, equals(2));
      });

      test('should filter with arrayContainsAny', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {
            'text': 'Task 1',
            'tags': ['work', 'urgent']
          },
          {
            'text': 'Task 2',
            'tags': ['personal']
          },
          {
            'text': 'Task 3',
            'tags': ['shopping']
          },
        ]);

        final results = await SyncLayer.collection('todos')
            .where('tags', arrayContainsAny: ['work', 'shopping']).get();

        expect(results.length, equals(2));
      });

      test('should filter with whereIn', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {'text': 'Task 1', 'status': 'active'},
          {'text': 'Task 2', 'status': 'completed'},
          {'text': 'Task 3', 'status': 'archived'},
          {'text': 'Task 4', 'status': 'active'},
        ]);

        final results = await SyncLayer.collection('todos')
            .where('status', whereIn: ['active', 'completed']).get();

        expect(results.length, equals(3));
      });

      test('should filter with whereNotIn', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {'text': 'Task 1', 'status': 'active'},
          {'text': 'Task 2', 'status': 'completed'},
          {'text': 'Task 3', 'status': 'archived'},
        ]);

        final results = await SyncLayer.collection('todos')
            .where('status', whereNotIn: ['archived']).get();

        expect(results.length, equals(2));
      });
    });

    group('where() - Multiple Conditions', () {
      test('should filter with multiple where clauses (AND)', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {'text': 'Task 1', 'done': false, 'priority': 5},
          {'text': 'Task 2', 'done': true, 'priority': 5},
          {'text': 'Task 3', 'done': false, 'priority': 3},
        ]);

        final results = await SyncLayer.collection('todos')
            .where('done', isEqualTo: false)
            .where('priority', isGreaterThan: 4)
            .get();

        expect(results.length, equals(1));
        expect(results[0]['text'], equals('Task 1'));
      });

      test('should filter with three conditions', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['products'],
        ));

        await SyncLayer.collection('products').saveAll([
          {
            'name': 'Product 1',
            'price': 100,
            'inStock': true,
            'category': 'electronics'
          },
          {
            'name': 'Product 2',
            'price': 150,
            'inStock': true,
            'category': 'electronics'
          },
          {
            'name': 'Product 3',
            'price': 200,
            'inStock': false,
            'category': 'electronics'
          },
          {
            'name': 'Product 4',
            'price': 120,
            'inStock': true,
            'category': 'books'
          },
        ]);

        final results = await SyncLayer.collection('products')
            .where('category', isEqualTo: 'electronics')
            .where('inStock', isEqualTo: true)
            .where('price', isLessThan: 160)
            .get();

        expect(results.length, equals(2));
      });

      test('should filter with mixed operator types', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {
            'text': 'Buy milk',
            'priority': 5,
            'tags': ['shopping']
          },
          {
            'text': 'Buy eggs',
            'priority': 3,
            'tags': ['shopping', 'urgent']
          },
          {
            'text': 'Call mom',
            'priority': 8,
            'tags': ['personal']
          },
        ]);

        final results = await SyncLayer.collection('todos')
            .where('text', startsWith: 'Buy')
            .where('priority', isGreaterThan: 2)
            .where('tags', arrayContains: 'shopping')
            .get();

        expect(results.length, equals(2));
      });
    });

    group('orderBy() Operations', () {
      test('should sort by field ascending', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['scores'],
        ));

        await SyncLayer.collection('scores').saveAll([
          {'player': 'Charlie', 'score': 200},
          {'player': 'Alice', 'score': 100},
          {'player': 'Bob', 'score': 150},
        ]);

        final results =
            await SyncLayer.collection('scores').orderBy('score').get();

        expect(results[0]['score'], equals(100));
        expect(results[1]['score'], equals(150));
        expect(results[2]['score'], equals(200));
      });

      test('should sort by field descending', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['scores'],
        ));

        await SyncLayer.collection('scores').saveAll([
          {'player': 'Alice', 'score': 100},
          {'player': 'Bob', 'score': 150},
          {'player': 'Charlie', 'score': 200},
        ]);

        final results = await SyncLayer.collection('scores')
            .orderBy('score', descending: true)
            .get();

        expect(results[0]['score'], equals(200));
        expect(results[1]['score'], equals(150));
        expect(results[2]['score'], equals(100));
      });

      test('should sort by string field', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['users'],
        ));

        await SyncLayer.collection('users').saveAll([
          {'name': 'Charlie'},
          {'name': 'Alice'},
          {'name': 'Bob'},
        ]);

        final results =
            await SyncLayer.collection('users').orderBy('name').get();

        expect(results[0]['name'], equals('Alice'));
        expect(results[1]['name'], equals('Bob'));
        expect(results[2]['name'], equals('Charlie'));
      });

      test('should sort with multiple orderBy clauses', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['products'],
        ));

        await SyncLayer.collection('products').saveAll([
          {'name': 'Product A', 'category': 'electronics', 'price': 100},
          {'name': 'Product B', 'category': 'books', 'price': 50},
          {'name': 'Product C', 'category': 'electronics', 'price': 80},
          {'name': 'Product D', 'category': 'books', 'price': 30},
        ]);

        final results = await SyncLayer.collection('products')
            .orderBy('category')
            .orderBy('price')
            .get();

        expect(results[0]['category'], equals('books'));
        expect(results[0]['price'], equals(30));
        expect(results[1]['category'], equals('books'));
        expect(results[1]['price'], equals(50));
        expect(results[2]['category'], equals('electronics'));
        expect(results[2]['price'], equals(80));
      });

      test('should combine where and orderBy', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {'text': 'Task 1', 'done': false, 'priority': 5},
          {'text': 'Task 2', 'done': false, 'priority': 3},
          {'text': 'Task 3', 'done': true, 'priority': 8},
          {'text': 'Task 4', 'done': false, 'priority': 7},
        ]);

        final results = await SyncLayer.collection('todos')
            .where('done', isEqualTo: false)
            .orderBy('priority', descending: true)
            .get();

        expect(results.length, equals(3));
        expect(results[0]['priority'], equals(7));
        expect(results[1]['priority'], equals(5));
        expect(results[2]['priority'], equals(3));
      });
    });

    group('limit() Operations', () {
      test('should limit results', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {'text': 'Task 1'},
          {'text': 'Task 2'},
          {'text': 'Task 3'},
          {'text': 'Task 4'},
          {'text': 'Task 5'},
        ]);

        final results = await SyncLayer.collection('todos').limit(3).get();

        expect(results.length, equals(3));
      });

      test('should limit to 1', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {'text': 'Task 1'},
          {'text': 'Task 2'},
        ]);

        final results = await SyncLayer.collection('todos').limit(1).get();

        expect(results.length, equals(1));
      });

      test('should handle limit larger than collection size', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {'text': 'Task 1'},
          {'text': 'Task 2'},
        ]);

        final results = await SyncLayer.collection('todos').limit(100).get();

        expect(results.length, equals(2));
      });

      test('should combine where, orderBy, and limit', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['scores'],
        ));

        await SyncLayer.collection('scores').saveAll([
          {'player': 'Alice', 'score': 100, 'active': true},
          {'player': 'Bob', 'score': 150, 'active': true},
          {'player': 'Charlie', 'score': 200, 'active': false},
          {'player': 'David', 'score': 180, 'active': true},
        ]);

        final results = await SyncLayer.collection('scores')
            .where('active', isEqualTo: true)
            .orderBy('score', descending: true)
            .limit(2)
            .get();

        expect(results.length, equals(2));
        expect(results[0]['player'], equals('David'));
        expect(results[1]['player'], equals('Bob'));
      });

      test('should throw error for negative limit', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        expect(
          () => SyncLayer.collection('todos').limit(-1),
          throwsArgumentError,
        );
      });
    });

    group('offset() Operations', () {
      test('should skip first N results', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {'text': 'Task 1', 'order': 1},
          {'text': 'Task 2', 'order': 2},
          {'text': 'Task 3', 'order': 3},
          {'text': 'Task 4', 'order': 4},
          {'text': 'Task 5', 'order': 5},
        ]);

        final results = await SyncLayer.collection('todos')
            .orderBy('order')
            .offset(2)
            .get();

        expect(results.length, equals(3));
        expect(results[0]['order'], equals(3));
      });

      test('should combine offset and limit for pagination', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {'text': 'Task 1', 'order': 1},
          {'text': 'Task 2', 'order': 2},
          {'text': 'Task 3', 'order': 3},
          {'text': 'Task 4', 'order': 4},
          {'text': 'Task 5', 'order': 5},
        ]);

        // Page 1
        final page1 = await SyncLayer.collection('todos')
            .orderBy('order')
            .offset(0)
            .limit(2)
            .get();

        expect(page1.length, equals(2));
        expect(page1[0]['order'], equals(1));
        expect(page1[1]['order'], equals(2));

        // Page 2
        final page2 = await SyncLayer.collection('todos')
            .orderBy('order')
            .offset(2)
            .limit(2)
            .get();

        expect(page2.length, equals(2));
        expect(page2[0]['order'], equals(3));
        expect(page2[1]['order'], equals(4));

        // Page 3
        final page3 = await SyncLayer.collection('todos')
            .orderBy('order')
            .offset(4)
            .limit(2)
            .get();

        expect(page3.length, equals(1));
        expect(page3[0]['order'], equals(5));
      });

      test('should handle offset larger than collection size', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {'text': 'Task 1'},
          {'text': 'Task 2'},
        ]);

        final results = await SyncLayer.collection('todos').offset(10).get();

        expect(results, isEmpty);
      });

      test('should throw error for negative offset', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        expect(
          () => SyncLayer.collection('todos').offset(-1),
          throwsArgumentError,
        );
      });
    });

    group('Query Helper Methods', () {
      test('first() should return first result', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {'text': 'Task 1', 'priority': 5},
          {'text': 'Task 2', 'priority': 3},
          {'text': 'Task 3', 'priority': 8},
        ]);

        final result = await SyncLayer.collection('todos')
            .orderBy('priority', descending: true)
            .first();

        expect(result, isNotNull);
        expect(result!['priority'], equals(8));
      });

      test('first() should return null for empty results', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final result = await SyncLayer.collection('todos')
            .where('done', isEqualTo: true)
            .first();

        expect(result, isNull);
      });

      test('count() should return number of matching documents', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').saveAll([
          {'text': 'Task 1', 'done': false},
          {'text': 'Task 2', 'done': true},
          {'text': 'Task 3', 'done': false},
        ]);

        final count = await SyncLayer.collection('todos')
            .where('done', isEqualTo: false)
            .count();

        expect(count, equals(2));
      });

      test('count() should return 0 for empty results', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final count = await SyncLayer.collection('todos')
            .where('done', isEqualTo: true)
            .count();

        expect(count, equals(0));
      });
    });

    group('Complex Query Scenarios', () {
      test('should handle query on large dataset', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['large'],
        ));

        final documents = List.generate(
          1000,
          (i) => {'index': i, 'category': i % 10, 'active': i % 2 == 0},
        );
        await SyncLayer.collection('large').saveAll(documents);

        final results = await SyncLayer.collection('large')
            .where('category', isEqualTo: 5)
            .where('active', isEqualTo: true)
            .get();

        expect(results.length, equals(50));
      });

      test('should handle query with all operators combined', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['products'],
        ));

        await SyncLayer.collection('products').saveAll([
          {
            'name': 'Product A',
            'price': 100,
            'category': 'electronics',
            'tags': ['new', 'sale']
          },
          {
            'name': 'Product B',
            'price': 150,
            'category': 'electronics',
            'tags': ['new']
          },
          {
            'name': 'Product C',
            'price': 80,
            'category': 'books',
            'tags': ['sale']
          },
          {
            'name': 'Product D',
            'price': 120,
            'category': 'electronics',
            'tags': ['new', 'sale']
          },
        ]);

        final results = await SyncLayer.collection('products')
            .where('category', isEqualTo: 'electronics')
            .where('price', isLessThan: 130)
            .where('tags', arrayContains: 'sale')
            .orderBy('price', descending: true)
            .limit(5)
            .get();

        expect(results.length, equals(2));
        expect(results[0]['price'], equals(120));
        expect(results[1]['price'], equals(100));
      });
    });
  });
}
