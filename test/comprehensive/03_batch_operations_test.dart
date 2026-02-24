import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';
import 'dart:io';

void main() {
  group('Batch Operations Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('synclayer_batch_test_');
    });

    tearDown(() async {
      await SyncLayer.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('saveAll() Operations', () {
      test('should save multiple documents', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final ids = await SyncLayer.collection('todos').saveAll([
          {'text': 'Task 1', 'done': false},
          {'text': 'Task 2', 'done': false},
          {'text': 'Task 3', 'done': true},
        ]);

        expect(ids.length, equals(3));
        expect(ids[0], isNotEmpty);
        expect(ids[1], isNotEmpty);
        expect(ids[2], isNotEmpty);
      });

      test('should save empty list', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final ids = await SyncLayer.collection('todos').saveAll([]);
        expect(ids, isEmpty);
      });

      test('should save single document via saveAll', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final ids = await SyncLayer.collection('todos').saveAll([
          {'text': 'Single task'},
        ]);

        expect(ids.length, equals(1));
        final doc = await SyncLayer.collection('todos').get(ids[0]);
        expect(doc!['text'], equals('Single task'));
      });

      test('should save large batch of documents', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final documents = List.generate(
          100,
          (i) => {'text': 'Task $i', 'index': i},
        );

        final ids = await SyncLayer.collection('todos').saveAll(documents);
        expect(ids.length, equals(100));

        final allDocs = await SyncLayer.collection('todos').getAll();
        expect(allDocs.length, equals(100));
      });

      test('should save documents with custom IDs', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final ids = await SyncLayer.collection('todos').saveAll([
          {'id': 'custom-1', 'text': 'Task 1'},
          {'id': 'custom-2', 'text': 'Task 2'},
          {'id': 'custom-3', 'text': 'Task 3'},
        ]);

        expect(ids, equals(['custom-1', 'custom-2', 'custom-3']));
      });

      test('should save documents with mixed custom and auto IDs', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final ids = await SyncLayer.collection('todos').saveAll([
          {'id': 'custom-1', 'text': 'Task 1'},
          {'text': 'Task 2'}, // Auto ID
          {'id': 'custom-3', 'text': 'Task 3'},
        ]);

        expect(ids.length, equals(3));
        expect(ids[0], equals('custom-1'));
        expect(ids[1], isNot(equals('custom-1')));
        expect(ids[2], equals('custom-3'));
      });

      test('should save documents with different data types', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['mixed'],
        ));

        final ids = await SyncLayer.collection('mixed').saveAll([
          {'type': 'string', 'value': 'text'},
          {'type': 'number', 'value': 42},
          {'type': 'boolean', 'value': true},
          {'type': 'null', 'value': null},
          {
            'type': 'array',
            'value': [1, 2, 3]
          },
          {
            'type': 'object',
            'value': {'nested': 'data'}
          },
        ]);

        expect(ids.length, equals(6));
        final allDocs = await SyncLayer.collection('mixed').getAll();
        expect(allDocs.length, equals(6));
      });

      test('should update existing documents via saveAll', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final id1 =
            await SyncLayer.collection('todos').save({'text': 'Original 1'});
        final id2 =
            await SyncLayer.collection('todos').save({'text': 'Original 2'});

        await SyncLayer.collection('todos').saveAll([
          {'id': id1, 'text': 'Updated 1'},
          {'id': id2, 'text': 'Updated 2'},
        ]);

        final doc1 = await SyncLayer.collection('todos').get(id1);
        final doc2 = await SyncLayer.collection('todos').get(id2);
        expect(doc1!['text'], equals('Updated 1'));
        expect(doc2!['text'], equals('Updated 2'));
      });

      test('should handle saveAll with duplicate IDs', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final ids = await SyncLayer.collection('todos').saveAll([
          {'id': 'same-id', 'text': 'First'},
          {'id': 'same-id', 'text': 'Second'},
        ]);

        expect(ids, equals(['same-id', 'same-id']));

        final doc = await SyncLayer.collection('todos').get('same-id');
        expect(doc!['text'], equals('Second')); // Last write wins
      });

      test('should save documents with nested objects', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['users'],
        ));

        final ids = await SyncLayer.collection('users').saveAll([
          {
            'name': 'John',
            'address': {'city': 'NYC', 'zip': '10001'},
          },
          {
            'name': 'Jane',
            'address': {'city': 'LA', 'zip': '90001'},
          },
        ]);

        expect(ids.length, equals(2));
        final allDocs = await SyncLayer.collection('users').getAll();
        expect(allDocs[0]['address']['city'], equals('NYC'));
        expect(allDocs[1]['address']['city'], equals('LA'));
      });

      test('should maintain order of saved documents', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['ordered'],
        ));

        final ids = await SyncLayer.collection('ordered').saveAll([
          {'order': 1},
          {'order': 2},
          {'order': 3},
          {'order': 4},
          {'order': 5},
        ]);

        for (int i = 0; i < ids.length; i++) {
          final doc = await SyncLayer.collection('ordered').get(ids[i]);
          expect(doc!['order'], equals(i + 1));
        }
      });

      test('should save very large batch', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['large'],
        ));

        final documents = List.generate(
          1000,
          (i) => {'index': i, 'data': 'Item $i'},
        );

        final ids = await SyncLayer.collection('large').saveAll(documents);
        expect(ids.length, equals(1000));

        final allDocs = await SyncLayer.collection('large').getAll();
        expect(allDocs.length, equals(1000));
      });
    });

    group('deleteAll() Operations', () {
      test('should delete multiple documents', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final id1 =
            await SyncLayer.collection('todos').save({'text': 'Task 1'});
        final id2 =
            await SyncLayer.collection('todos').save({'text': 'Task 2'});
        await SyncLayer.collection('todos').save({'text': 'Task 3'});

        await SyncLayer.collection('todos').deleteAll([id1, id2]);

        final allDocs = await SyncLayer.collection('todos').getAll();
        expect(allDocs.length, equals(1));
        expect(allDocs[0]['text'], equals('Task 3'));
      });

      test('should delete empty list', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        await SyncLayer.collection('todos').save({'text': 'Task 1'});
        await SyncLayer.collection('todos').deleteAll([]);

        final allDocs = await SyncLayer.collection('todos').getAll();
        expect(allDocs.length, equals(1));
      });

      test('should delete all documents in collection', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final ids = await SyncLayer.collection('todos').saveAll([
          {'text': 'Task 1'},
          {'text': 'Task 2'},
          {'text': 'Task 3'},
        ]);

        await SyncLayer.collection('todos').deleteAll(ids);

        final allDocs = await SyncLayer.collection('todos').getAll();
        expect(allDocs, isEmpty);
      });

      test('should handle deleteAll with non-existent IDs', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        expect(
          () => SyncLayer.collection('todos').deleteAll([
            'non-existent-1',
            'non-existent-2',
          ]),
          returnsNormally,
        );
      });

      test('should handle deleteAll with mixed existing and non-existent IDs',
          () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final id1 =
            await SyncLayer.collection('todos').save({'text': 'Task 1'});
        final id2 =
            await SyncLayer.collection('todos').save({'text': 'Task 2'});

        await SyncLayer.collection('todos').deleteAll([
          id1,
          'non-existent',
          id2,
        ]);

        final allDocs = await SyncLayer.collection('todos').getAll();
        expect(allDocs, isEmpty);
      });

      test('should delete large batch of documents', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final documents = List.generate(100, (i) => {'text': 'Task $i'});
        final ids = await SyncLayer.collection('todos').saveAll(documents);

        await SyncLayer.collection('todos').deleteAll(ids);

        final allDocs = await SyncLayer.collection('todos').getAll();
        expect(allDocs, isEmpty);
      });

      test('should delete subset of documents', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final ids = await SyncLayer.collection('todos').saveAll([
          {'text': 'Task 1'},
          {'text': 'Task 2'},
          {'text': 'Task 3'},
          {'text': 'Task 4'},
          {'text': 'Task 5'},
        ]);

        await SyncLayer.collection('todos').deleteAll([ids[1], ids[3]]);

        final allDocs = await SyncLayer.collection('todos').getAll();
        expect(allDocs.length, equals(3));
        expect(allDocs[0]['text'], equals('Task 1'));
        expect(allDocs[1]['text'], equals('Task 3'));
        expect(allDocs[2]['text'], equals('Task 5'));
      });

      test('should handle deleteAll with duplicate IDs', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['todos'],
        ));

        final id = await SyncLayer.collection('todos').save({'text': 'Task 1'});

        await SyncLayer.collection('todos').deleteAll([id, id, id]);

        final doc = await SyncLayer.collection('todos').get(id);
        expect(doc, isNull);
      });
    });

    group('Batch Operations Performance', () {
      test('saveAll should be faster than multiple save calls', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['performance'],
        ));

        final documents = List.generate(50, (i) => {'index': i});

        // Measure saveAll
        final batchStart = DateTime.now();
        await SyncLayer.collection('performance').saveAll(documents);
        final batchDuration = DateTime.now().difference(batchStart);

        // Clear collection
        final ids = (await SyncLayer.collection('performance').getAll())
            .map((doc) => doc['id'] as String)
            .toList();
        await SyncLayer.collection('performance').deleteAll(ids);

        // Measure individual saves
        final individualStart = DateTime.now();
        for (final doc in documents) {
          await SyncLayer.collection('performance').save(doc);
        }
        final individualDuration = DateTime.now().difference(individualStart);

        // Batch should be faster (or at least not significantly slower)
        expect(batchDuration.inMilliseconds,
            lessThan(individualDuration.inMilliseconds * 2));
      });

      test('deleteAll should be faster than multiple delete calls', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['performance'],
        ));

        final documents = List.generate(50, (i) => {'index': i});

        // Create documents for batch delete
        final batchIds =
            await SyncLayer.collection('performance').saveAll(documents);

        // Measure deleteAll
        final batchStart = DateTime.now();
        await SyncLayer.collection('performance').deleteAll(batchIds);
        final batchDuration = DateTime.now().difference(batchStart);

        // Create documents for individual delete
        final individualIds =
            await SyncLayer.collection('performance').saveAll(documents);

        // Measure individual deletes
        final individualStart = DateTime.now();
        for (final id in individualIds) {
          await SyncLayer.collection('performance').delete(id);
        }
        final individualDuration = DateTime.now().difference(individualStart);

        // Batch should be faster (or at least not significantly slower)
        expect(batchDuration.inMilliseconds,
            lessThan(individualDuration.inMilliseconds * 2));
      });
    });

    group('Batch Operations Edge Cases', () {
      test('should handle saveAll with very large documents', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['large'],
        ));

        final largeText = 'A' * 10000;
        final documents = List.generate(
          10,
          (i) => {'index': i, 'content': largeText},
        );

        final ids = await SyncLayer.collection('large').saveAll(documents);
        expect(ids.length, equals(10));
      });

      test('should handle saveAll with deeply nested objects', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['nested'],
        ));

        final documents = [
          {
            'level1': {
              'level2': {
                'level3': {
                  'level4': {
                    'level5': 'deep value',
                  },
                },
              },
            },
          },
        ];

        final ids = await SyncLayer.collection('nested').saveAll(documents);
        expect(ids.length, equals(1));

        final doc = await SyncLayer.collection('nested').get(ids[0]);
        expect(doc!['level1']['level2']['level3']['level4']['level5'],
            equals('deep value'));
      });

      test('should handle saveAll with special characters', () async {
        await SyncLayer.init(SyncConfig(
          baseUrl: 'https://api.example.com',
          collections: ['special'],
        ));

        final documents = [
          {'text': 'Hello 世界 🌍'},
          {'text': '"quotes" and \'apostrophes\''},
          {'text': 'Line\nBreaks\tAnd\rCarriage'},
          {'text': 'Backslash \\ and forward /'},
        ];

        final ids = await SyncLayer.collection('special').saveAll(documents);
        expect(ids.length, equals(4));
      });
    });
  });
}
