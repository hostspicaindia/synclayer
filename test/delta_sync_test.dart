import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';

void main() {
  group('Delta Sync', () {
    group('DeltaCalculator.calculateDelta', () {
      test('detects changed fields', () {
        final oldDoc = {
          'title': 'Old Title',
          'done': false,
          'priority': 5,
        };

        final newDoc = {
          'title': 'New Title',
          'done': true,
          'priority': 5,
        };

        final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

        expect(delta, {
          'title': 'New Title',
          'done': true,
        });
        expect(delta.containsKey('priority'), false); // Unchanged
      });

      test('detects new fields', () {
        final oldDoc = {
          'title': 'Title',
        };

        final newDoc = {
          'title': 'Title',
          'done': true,
        };

        final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

        expect(delta, {'done': true});
      });

      test('detects removed fields', () {
        final oldDoc = {
          'title': 'Title',
          'done': true,
        };

        final newDoc = {
          'title': 'Title',
        };

        final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

        expect(delta, {'done': null});
      });

      test('handles nested objects', () {
        final oldDoc = {
          'user': {
            'name': 'John',
            'age': 30,
          },
        };

        final newDoc = {
          'user': {
            'name': 'John',
            'age': 31,
          },
        };

        final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

        expect(delta['user']['age'], 31);
      });

      test('handles arrays', () {
        final oldDoc = {
          'tags': ['tag1', 'tag2'],
        };

        final newDoc = {
          'tags': ['tag1', 'tag2', 'tag3'],
        };

        final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

        expect(delta['tags'], ['tag1', 'tag2', 'tag3']);
      });

      test('returns empty map when nothing changed', () {
        final doc = {
          'title': 'Title',
          'done': false,
        };

        final delta = DeltaCalculator.calculateDelta(doc, doc);

        expect(delta, isEmpty);
      });
    });

    group('DeltaCalculator.applyDelta', () {
      test('applies delta to document', () {
        final doc = {
          'title': 'Old Title',
          'done': false,
          'priority': 5,
        };

        final delta = {
          'title': 'New Title',
          'done': true,
        };

        final result = DeltaCalculator.applyDelta(doc, delta);

        expect(result, {
          'title': 'New Title',
          'done': true,
          'priority': 5,
        });
      });

      test('adds new fields', () {
        final doc = {
          'title': 'Title',
        };

        final delta = {
          'done': true,
        };

        final result = DeltaCalculator.applyDelta(doc, delta);

        expect(result, {
          'title': 'Title',
          'done': true,
        });
      });

      test('removes fields with null value', () {
        final doc = {
          'title': 'Title',
          'done': true,
        };

        final delta = {
          'done': null,
        };

        final result = DeltaCalculator.applyDelta(doc, delta);

        expect(result, {'title': 'Title'});
        expect(result.containsKey('done'), false);
      });
    });

    group('DeltaCalculator.calculateSavings', () {
      test('calculates bandwidth savings', () {
        final fullDoc = {
          'id': '123',
          'title': 'My Document',
          'content':
              'This is a very long content that takes up a lot of space...',
          'metadata': {
            'author': 'John Doe',
            'created': '2024-01-01',
            'tags': ['tag1', 'tag2', 'tag3'],
          },
          'done': false,
        };

        final delta = {
          'done': true,
        };

        final savings = DeltaCalculator.calculateSavings(fullDoc, delta);

        expect(savings, greaterThan(90.0)); // Should save > 90%
      });

      test('returns 0 for empty document', () {
        final savings = DeltaCalculator.calculateSavings({}, {});
        expect(savings, 0.0);
      });

      test('returns 0 when delta is same size as document', () {
        final doc = {'a': 1};
        final savings = DeltaCalculator.calculateSavings(doc, doc);
        expect(savings, 0.0);
      });
    });

    group('DocumentDelta', () {
      test('creates delta object', () {
        final delta = DocumentDelta(
          recordId: '123',
          collectionName: 'todos',
          changedFields: {'done': true},
          timestamp: DateTime(2024, 1, 1),
          baseVersion: 5,
        );

        expect(delta.recordId, '123');
        expect(delta.collectionName, 'todos');
        expect(delta.changedFields, {'done': true});
        expect(delta.baseVersion, 5);
      });

      test('converts to JSON', () {
        final delta = DocumentDelta(
          recordId: '123',
          collectionName: 'todos',
          changedFields: {'done': true},
          timestamp: DateTime(2024, 1, 1, 10, 0),
          baseVersion: 5,
        );

        final json = delta.toJson();

        expect(json['recordId'], '123');
        expect(json['collectionName'], 'todos');
        expect(json['changedFields'], {'done': true});
        expect(json['baseVersion'], 5);
        expect(json['timestamp'], '2024-01-01T10:00:00.000');
      });

      test('creates from JSON', () {
        final json = {
          'recordId': '123',
          'collectionName': 'todos',
          'changedFields': {'done': true},
          'timestamp': '2024-01-01T10:00:00.000',
          'baseVersion': 5,
        };

        final delta = DocumentDelta.fromJson(json);

        expect(delta.recordId, '123');
        expect(delta.collectionName, 'todos');
        expect(delta.changedFields, {'done': true});
        expect(delta.baseVersion, 5);
        expect(delta.timestamp, DateTime(2024, 1, 1, 10, 0));
      });

      test('toString shows fields', () {
        final delta = DocumentDelta(
          recordId: '123',
          collectionName: 'todos',
          changedFields: {'done': true, 'priority': 5},
          timestamp: DateTime(2024, 1, 1),
          baseVersion: 5,
        );

        final str = delta.toString();

        expect(str, contains('123'));
        expect(str, contains('done'));
        expect(str, contains('priority'));
      });
    });

    group('Real-world scenarios', () {
      test('todo completion - 98% bandwidth savings', () {
        final fullTodo = {
          'id': '123',
          'text': 'Buy groceries',
          'description': 'Need to buy milk, eggs, bread, and other items',
          'priority': 5,
          'tags': ['shopping', 'urgent'],
          'createdAt': '2024-01-01T10:00:00.000Z',
          'updatedAt': '2024-01-01T10:00:00.000Z',
          'userId': 'user123',
          'done': false,
        };

        final delta = {'done': true};

        final savings = DeltaCalculator.calculateSavings(fullTodo, delta);
        expect(savings, greaterThan(90.0));
      });

      test('increment counter - minimal bandwidth', () {
        final fullDoc = {
          'id': '123',
          'title': 'My Article',
          'content': 'Very long article content...' * 100,
          'views': 100,
          'likes': 50,
        };

        final delta = {'views': 101};

        final savings = DeltaCalculator.calculateSavings(fullDoc, delta);
        expect(savings, greaterThan(98.0));
      });

      test('update status - small delta', () {
        final fullDoc = {
          'id': '123',
          'name': 'John Doe',
          'email': 'john@example.com',
          'profile': {
            'bio': 'Long bio text...',
            'avatar': 'https://example.com/avatar.jpg',
          },
          'status': 'offline',
          'lastSeen': '2024-01-01T10:00:00.000Z',
        };

        final delta = {
          'status': 'online',
          'lastSeen': '2024-01-01T11:00:00.000Z',
        };

        final savings = DeltaCalculator.calculateSavings(fullDoc, delta);
        expect(savings, greaterThan(60.0));
      });
    });
  });
}
