import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';
import 'dart:io';

void main() {
  group('CRUD Operations Tests', () {
    late Directory tempDir;

    setUp(() async {
      // Create temp directory for each test
      tempDir = await Directory.systemTemp.createTemp('synclayer_crud_test_');
    });

    tearDown(() async {
      await SyncLayer.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('save() - Insert Operations', () {
      test('should save a simple document', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final id = await SyncLayer.collection('todos').save({
          'text': 'Buy milk',
          'done': false,
        });

        expect(id, isNotEmpty);
        expect(id.length, equals(36)); // UUID length
      });

      test('should save document with all data types', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['mixed'],
        ));

        final id = await SyncLayer.collection('mixed').save({
          'string': 'text',
          'int': 42,
          'double': 3.14,
          'bool': true,
          'null': null,
          'list': [1, 2, 3],
          'map': {'nested': 'value'},
        });

        final doc = await SyncLayer.collection('mixed').get(id);
        expect(doc!['string'], equals('text'));
        expect(doc['int'], equals(42));
        expect(doc['double'], equals(3.14));
        expect(doc['bool'], equals(true));
        expect(doc['null'], isNull);
        expect(doc['list'], equals([1, 2, 3]));
        expect(doc['map'], equals({'nested': 'value'}));
      });

      test('should save document with nested objects', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['nested'],
        ));

        final id = await SyncLayer.collection('nested').save({
          'user': {
            'name': 'John',
            'address': {
              'street': '123 Main St',
              'city': 'NYC',
            },
          },
        });

        final doc = await SyncLayer.collection('nested').get(id);
        expect(doc!['user']['name'], equals('John'));
        expect(doc['user']['address']['city'], equals('NYC'));
      });

      test('should save document with arrays', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['arrays'],
        ));

        final id = await SyncLayer.collection('arrays').save({
          'tags': ['work', 'urgent', 'important'],
          'numbers': [1, 2, 3, 4, 5],
          'mixed': [1, 'two', true, null],
        });

        final doc = await SyncLayer.collection('arrays').get(id);
        expect(doc!['tags'], equals(['work', 'urgent', 'important']));
        expect(doc['numbers'], equals([1, 2, 3, 4, 5]));
        expect(doc['mixed'], equals([1, 'two', true, null]));
      });

      test('should save empty document', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['empty'],
        ));

        final id = await SyncLayer.collection('empty').save({});
        final doc = await SyncLayer.collection('empty').get(id);
        expect(doc, equals({}));
      });

      test('should save document with special characters', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['special'],
        ));

        final id = await SyncLayer.collection('special').save({
          'text': 'Hello 世界 🌍 "quotes" \'apostrophes\' \n\t\\',
        });

        final doc = await SyncLayer.collection('special').get(id);
        expect(doc!['text'],
            equals('Hello 世界 🌍 "quotes" \'apostrophes\' \n\t\\'));
      });

      test('should save document with large text', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['large'],
        ));

        final largeText = 'A' * 10000; // 10KB of text
        final id = await SyncLayer.collection('large').save({
          'content': largeText,
        });

        final doc = await SyncLayer.collection('large').get(id);
        expect(doc!['content'].length, equals(10000));
      });

      test('should save document with timestamp', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['timestamps'],
        ));

        final now = DateTime.now();
        final id = await SyncLayer.collection('timestamps').save({
          'createdAt': now.toIso8601String(),
        });

        final doc = await SyncLayer.collection('timestamps').get(id);
        expect(doc!['createdAt'], equals(now.toIso8601String()));
      });

      test('should save multiple documents sequentially', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final id1 =
            await SyncLayer.collection('todos').save({'text': 'Task 1'});
        final id2 =
            await SyncLayer.collection('todos').save({'text': 'Task 2'});
        final id3 =
            await SyncLayer.collection('todos').save({'text': 'Task 3'});

        expect(id1, isNot(equals(id2)));
        expect(id2, isNot(equals(id3)));
        expect(id1, isNot(equals(id3)));
      });

      test('should save document with custom ID', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['custom'],
        ));

        final customId = 'my-custom-id-123';
        final id = await SyncLayer.collection('custom').save(
          {'text': 'Custom ID doc'},
          id: customId,
        );

        expect(id, equals(customId));
        final doc = await SyncLayer.collection('custom').get(customId);
        expect(doc, isNotNull);
      });
    });

    group('save() - Update Operations', () {
      test('should update existing document', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final id = await SyncLayer.collection('todos').save({
          'text': 'Buy milk',
          'done': false,
        });

        await SyncLayer.collection('todos').save({
          'text': 'Buy milk',
          'done': true,
        }, id: id);

        final doc = await SyncLayer.collection('todos').get(id);
        expect(doc!['done'], equals(true));
      });

      test('should completely replace document on update', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final id = await SyncLayer.collection('todos').save({
          'text': 'Buy milk',
          'done': false,
          'priority': 5,
        });

        await SyncLayer.collection('todos').save({
          'text': 'Buy eggs',
        }, id: id);

        final doc = await SyncLayer.collection('todos').get(id);
        expect(doc!['text'], equals('Buy eggs'));
        expect(doc['done'], isNull);
        expect(doc['priority'], isNull);
      });

      test('should update document multiple times', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['counter'],
        ));

        final id = await SyncLayer.collection('counter').save({'count': 0});

        for (int i = 1; i <= 10; i++) {
          await SyncLayer.collection('counter').save({'count': i}, id: id);
        }

        final doc = await SyncLayer.collection('counter').get(id);
        expect(doc!['count'], equals(10));
      });
    });

    group('get() Operations', () {
      test('should get existing document', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final id = await SyncLayer.collection('todos').save({
          'text': 'Buy milk',
          'done': false,
        });

        final doc = await SyncLayer.collection('todos').get(id);
        expect(doc, isNotNull);
        expect(doc!['text'], equals('Buy milk'));
        expect(doc['done'], equals(false));
      });

      test('should return null for non-existent document', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final doc = await SyncLayer.collection('todos').get('non-existent-id');
        expect(doc, isNull);
      });

      test('should get document immediately after save', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final id = await SyncLayer.collection('todos').save({'text': 'Test'});
        final doc = await SyncLayer.collection('todos').get(id);
        expect(doc, isNotNull);
      });

      test('should get updated document', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final id = await SyncLayer.collection('todos').save({'version': 1});
        await SyncLayer.collection('todos').save({'version': 2}, id: id);

        final doc = await SyncLayer.collection('todos').get(id);
        expect(doc!['version'], equals(2));
      });
    });

    group('getAll() Operations', () {
      test('should return empty list for empty collection', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final docs = await SyncLayer.collection('todos').getAll();
        expect(docs, isEmpty);
      });

      test('should return all documents', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').save({'text': 'Task 1'});
        await SyncLayer.collection('todos').save({'text': 'Task 2'});
        await SyncLayer.collection('todos').save({'text': 'Task 3'});

        final docs = await SyncLayer.collection('todos').getAll();
        expect(docs.length, equals(3));
      });

      test('should return documents in insertion order', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').save({'order': 1});
        await SyncLayer.collection('todos').save({'order': 2});
        await SyncLayer.collection('todos').save({'order': 3});

        final docs = await SyncLayer.collection('todos').getAll();
        expect(docs[0]['order'], equals(1));
        expect(docs[1]['order'], equals(2));
        expect(docs[2]['order'], equals(3));
      });

      test('should not include deleted documents', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final id1 =
            await SyncLayer.collection('todos').save({'text': 'Task 1'});
        await SyncLayer.collection('todos').save({'text': 'Task 2'});
        await SyncLayer.collection('todos').delete(id1);

        final docs = await SyncLayer.collection('todos').getAll();
        expect(docs.length, equals(1));
        expect(docs[0]['text'], equals('Task 2'));
      });

      test('should handle large number of documents', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['large'],
        ));

        for (int i = 0; i < 1000; i++) {
          await SyncLayer.collection('large').save({'index': i});
        }

        final docs = await SyncLayer.collection('large').getAll();
        expect(docs.length, equals(1000));
      });
    });

    group('delete() Operations', () {
      test('should delete existing document', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final id =
            await SyncLayer.collection('todos').save({'text': 'Delete me'});
        await SyncLayer.collection('todos').delete(id);

        final doc = await SyncLayer.collection('todos').get(id);
        expect(doc, isNull);
      });

      test('should not throw when deleting non-existent document', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        expect(
          () => SyncLayer.collection('todos').delete('non-existent'),
          returnsNormally,
        );
      });

      test('should delete document multiple times without error', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final id = await SyncLayer.collection('todos').save({'text': 'Test'});
        await SyncLayer.collection('todos').delete(id);
        await SyncLayer.collection('todos').delete(id);

        final doc = await SyncLayer.collection('todos').get(id);
        expect(doc, isNull);
      });

      test('should remove document from getAll results', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final id = await SyncLayer.collection('todos').save({'text': 'Task 1'});
        await SyncLayer.collection('todos').save({'text': 'Task 2'});

        await SyncLayer.collection('todos').delete(id);

        final docs = await SyncLayer.collection('todos').getAll();
        expect(docs.length, equals(1));
        expect(docs[0]['text'], equals('Task 2'));
      });

      test('should delete all documents one by one', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final id1 =
            await SyncLayer.collection('todos').save({'text': 'Task 1'});
        final id2 =
            await SyncLayer.collection('todos').save({'text': 'Task 2'});
        final id3 =
            await SyncLayer.collection('todos').save({'text': 'Task 3'});

        await SyncLayer.collection('todos').delete(id1);
        await SyncLayer.collection('todos').delete(id2);
        await SyncLayer.collection('todos').delete(id3);

        final docs = await SyncLayer.collection('todos').getAll();
        expect(docs, isEmpty);
      });
    });

    group('update() - Delta Sync Operations', () {
      test('should update single field', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final id = await SyncLayer.collection('todos').save({
          'text': 'Buy milk',
          'done': false,
          'priority': 5,
        });

        await SyncLayer.collection('todos').update(id, {'done': true});

        final doc = await SyncLayer.collection('todos').get(id);
        expect(doc!['text'], equals('Buy milk'));
        expect(doc['done'], equals(true));
        expect(doc['priority'], equals(5));
      });

      test('should update multiple fields', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final id = await SyncLayer.collection('todos').save({
          'text': 'Buy milk',
          'done': false,
          'priority': 5,
        });

        await SyncLayer.collection('todos').update(id, {
          'done': true,
          'priority': 10,
        });

        final doc = await SyncLayer.collection('todos').get(id);
        expect(doc!['done'], equals(true));
        expect(doc['priority'], equals(10));
      });

      test('should add new fields via update', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final id =
            await SyncLayer.collection('todos').save({'text': 'Buy milk'});

        await SyncLayer.collection('todos').update(id, {
          'done': true,
          'tags': ['shopping', 'urgent'],
        });

        final doc = await SyncLayer.collection('todos').get(id);
        expect(doc!['text'], equals('Buy milk'));
        expect(doc['done'], equals(true));
        expect(doc['tags'], equals(['shopping', 'urgent']));
      });

      test('should throw error when updating non-existent document', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        expect(
          () => SyncLayer.collection('todos')
              .update('non-existent', {'done': true}),
          throwsStateError,
        );
      });

      test('should update nested fields', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['users'],
        ));

        final id = await SyncLayer.collection('users').save({
          'name': 'John',
          'address': {
            'street': '123 Main St',
            'city': 'NYC',
          },
        });

        await SyncLayer.collection('users').update(id, {
          'address': {
            'street': '456 Oak Ave',
            'city': 'LA',
          },
        });

        final doc = await SyncLayer.collection('users').get(id);
        expect(doc!['address']['street'], equals('456 Oak Ave'));
        expect(doc['address']['city'], equals('LA'));
      });

      test('should increment counter via update', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['counters'],
        ));

        final id = await SyncLayer.collection('counters').save({'count': 0});

        for (int i = 1; i <= 10; i++) {
          final doc = await SyncLayer.collection('counters').get(id);
          await SyncLayer.collection('counters').update(id, {
            'count': (doc!['count'] as int) + 1,
          });
        }

        final doc = await SyncLayer.collection('counters').get(id);
        expect(doc!['count'], equals(10));
      });
    });

    group('Multiple Collections', () {
      test('should handle multiple collections independently', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos', 'notes', 'users'],
        ));

        await SyncLayer.collection('todos').save({'text': 'Todo 1'});
        await SyncLayer.collection('notes').save({'content': 'Note 1'});
        await SyncLayer.collection('users').save({'name': 'User 1'});

        final todos = await SyncLayer.collection('todos').getAll();
        final notes = await SyncLayer.collection('notes').getAll();
        final users = await SyncLayer.collection('users').getAll();

        expect(todos.length, equals(1));
        expect(notes.length, equals(1));
        expect(users.length, equals(1));
      });

      test('should not mix documents between collections', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos', 'notes'],
        ));

        final todoId =
            await SyncLayer.collection('todos').save({'text': 'Todo'});

        final noteDoc = await SyncLayer.collection('notes').get(todoId);
        expect(noteDoc, isNull);
      });
    });

    group('Edge Cases', () {
      test('should handle very long field names', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['test'],
        ));

        final longFieldName = 'a' * 1000;
        final id = await SyncLayer.collection('test').save({
          longFieldName: 'value',
        });

        final doc = await SyncLayer.collection('test').get(id);
        expect(doc![longFieldName], equals('value'));
      });

      test('should handle documents with many fields', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['test'],
        ));

        final data = <String, dynamic>{};
        for (int i = 0; i < 100; i++) {
          data['field$i'] = 'value$i';
        }

        final id = await SyncLayer.collection('test').save(data);
        final doc = await SyncLayer.collection('test').get(id);
        expect(doc!.length, equals(100));
      });

      test('should handle null values', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['test'],
        ));

        final id = await SyncLayer.collection('test').save({
          'field1': null,
          'field2': 'value',
          'field3': null,
        });

        final doc = await SyncLayer.collection('test').get(id);
        expect(doc!['field1'], isNull);
        expect(doc['field2'], equals('value'));
        expect(doc['field3'], isNull);
      });

      test('should handle boolean values correctly', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['test'],
        ));

        final id = await SyncLayer.collection('test').save({
          'isTrue': true,
          'isFalse': false,
        });

        final doc = await SyncLayer.collection('test').get(id);
        expect(doc!['isTrue'], equals(true));
        expect(doc['isFalse'], equals(false));
      });

      test('should handle numeric edge cases', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['test'],
        ));

        final id = await SyncLayer.collection('test').save({
          'zero': 0,
          'negative': -42,
          'large': 9007199254740991, // Max safe integer
          'decimal': 3.14159265359,
        });

        final doc = await SyncLayer.collection('test').get(id);
        expect(doc!['zero'], equals(0));
        expect(doc['negative'], equals(-42));
        expect(doc['large'], equals(9007199254740991));
        expect(doc['decimal'], equals(3.14159265359));
      });
    });
  });
}
