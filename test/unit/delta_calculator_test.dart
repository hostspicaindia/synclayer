import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/sync/delta_sync.dart';

void main() {
  group('DeltaCalculator - Calculate Delta', () {
    test('should detect changed fields', () {
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
    });

    test('should detect new fields', () {
      final oldDoc = {
        'title': 'Title',
      };

      final newDoc = {
        'title': 'Title',
        'description': 'New field',
        'tags': ['new', 'field'],
      };

      final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

      expect(delta, {
        'description': 'New field',
        'tags': ['new', 'field'],
      });
    });

    test('should detect removed fields', () {
      final oldDoc = {
        'title': 'Title',
        'description': 'Description',
        'tags': ['tag1'],
      };

      final newDoc = {
        'title': 'Title',
      };

      final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

      expect(delta, {
        'description': null,
        'tags': null,
      });
    });

    test('should return empty delta when documents are identical', () {
      final doc = {
        'title': 'Title',
        'done': false,
        'priority': 5,
      };

      final delta = DeltaCalculator.calculateDelta(doc, doc);

      expect(delta, isEmpty);
    });

    test('should handle empty documents', () {
      final delta = DeltaCalculator.calculateDelta({}, {});

      expect(delta, isEmpty);
    });

    test('should handle adding to empty document', () {
      final oldDoc = <String, dynamic>{};
      final newDoc = {
        'title': 'New',
        'value': 42,
      };

      final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

      expect(delta, {
        'title': 'New',
        'value': 42,
      });
    });

    test('should handle clearing all fields', () {
      final oldDoc = {
        'title': 'Title',
        'value': 42,
      };
      final newDoc = <String, dynamic>{};

      final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

      expect(delta, {
        'title': null,
        'value': null,
      });
    });
  });

  group('DeltaCalculator - Nested Structures', () {
    test('should detect changes in nested maps', () {
      final oldDoc = {
        'user': {
          'name': 'Alice',
          'age': 30,
        },
      };

      final newDoc = {
        'user': {
          'name': 'Alice',
          'age': 31,
        },
      };

      final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

      expect(delta, {
        'user': {
          'name': 'Alice',
          'age': 31,
        },
      });
    });

    test('should detect changes in nested lists', () {
      final oldDoc = {
        'tags': ['tag1', 'tag2'],
      };

      final newDoc = {
        'tags': ['tag1', 'tag2', 'tag3'],
      };

      final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

      expect(delta, {
        'tags': ['tag1', 'tag2', 'tag3'],
      });
    });

    test('should handle deeply nested structures', () {
      final oldDoc = {
        'level1': {
          'level2': {
            'level3': {
              'value': 'old',
            },
          },
        },
      };

      final newDoc = {
        'level1': {
          'level2': {
            'level3': {
              'value': 'new',
            },
          },
        },
      };

      final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

      expect(delta, {
        'level1': {
          'level2': {
            'level3': {
              'value': 'new',
            },
          },
        },
      });
    });

    test('should not include unchanged nested structures', () {
      final oldDoc = {
        'metadata': {
          'created': '2024-01-01',
          'updated': '2024-01-01',
        },
        'content': 'old',
      };

      final newDoc = {
        'metadata': {
          'created': '2024-01-01',
          'updated': '2024-01-01',
        },
        'content': 'new',
      };

      final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

      expect(delta, {
        'content': 'new',
      });
    });
  });

  group('DeltaCalculator - Data Types', () {
    test('should handle string changes', () {
      final oldDoc = {'text': 'old'};
      final newDoc = {'text': 'new'};

      final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

      expect(delta, {'text': 'new'});
    });

    test('should handle number changes', () {
      final oldDoc = {'count': 10};
      final newDoc = {'count': 20};

      final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

      expect(delta, {'count': 20});
    });

    test('should handle boolean changes', () {
      final oldDoc = {'active': false};
      final newDoc = {'active': true};

      final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

      expect(delta, {'active': true});
    });

    test('should handle null values', () {
      final oldDoc = {'value': 'something'};
      final newDoc = {'value': null};

      final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

      expect(delta, {'value': null});
    });

    test('should handle type changes', () {
      final oldDoc = {'field': 'string'};
      final newDoc = {'field': 42};

      final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

      expect(delta, {'field': 42});
    });
  });

  group('DeltaCalculator - Apply Delta', () {
    test('should apply simple delta', () {
      final doc = {
        'title': 'Title',
        'done': false,
        'priority': 5,
      };

      final delta = {
        'done': true,
        'priority': 10,
      };

      final result = DeltaCalculator.applyDelta(doc, delta);

      expect(result, {
        'title': 'Title',
        'done': true,
        'priority': 10,
      });
    });

    test('should add new fields', () {
      final doc = {
        'title': 'Title',
      };

      final delta = {
        'description': 'New description',
        'tags': ['new'],
      };

      final result = DeltaCalculator.applyDelta(doc, delta);

      expect(result, {
        'title': 'Title',
        'description': 'New description',
        'tags': ['new'],
      });
    });

    test('should remove fields with null values', () {
      final doc = {
        'title': 'Title',
        'description': 'Description',
        'tags': ['tag1'],
      };

      final delta = {
        'description': null,
        'tags': null,
      };

      final result = DeltaCalculator.applyDelta(doc, delta);

      expect(result, {
        'title': 'Title',
      });
    });

    test('should apply empty delta', () {
      final doc = {
        'title': 'Title',
        'value': 42,
      };

      final delta = <String, dynamic>{};

      final result = DeltaCalculator.applyDelta(doc, delta);

      expect(result, doc);
    });

    test('should not modify original document', () {
      final doc = {
        'title': 'Original',
        'value': 1,
      };

      final delta = {
        'title': 'Modified',
        'value': 2,
      };

      DeltaCalculator.applyDelta(doc, delta);

      // Original should be unchanged
      expect(doc, {
        'title': 'Original',
        'value': 1,
      });
    });
  });

  group('DeltaCalculator - Round Trip', () {
    test('should maintain data integrity through calculate and apply', () {
      final oldDoc = {
        'title': 'Old Title',
        'description': 'Description',
        'done': false,
        'priority': 5,
        'tags': ['tag1', 'tag2'],
      };

      final newDoc = {
        'title': 'New Title',
        'description': 'Description',
        'done': true,
        'priority': 10,
        'tags': ['tag1', 'tag2', 'tag3'],
      };

      // Calculate delta
      final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

      // Apply delta to old document
      final result = DeltaCalculator.applyDelta(oldDoc, delta);

      // Result should match new document
      expect(result, newDoc);
    });

    test('should handle multiple delta applications', () {
      Map<String, dynamic> doc = {
        'value': 0,
        'status': 'initial',
      };

      // Apply first delta
      final delta1 = {'value': 1};
      doc = DeltaCalculator.applyDelta(doc, delta1);

      // Apply second delta
      final delta2 = {'value': 2, 'status': 'updated'};
      doc = DeltaCalculator.applyDelta(doc, delta2);

      // Apply third delta
      final delta3 = {'value': 3};
      doc = DeltaCalculator.applyDelta(doc, delta3);

      expect(doc, {
        'value': 3,
        'status': 'updated',
      });
    });
  });

  group('DeltaCalculator - Bandwidth Savings', () {
    test('should calculate savings for simple update', () {
      final fullDoc = {
        'title': 'A very long title that takes up space',
        'content': 'Lorem ipsum ' * 100,
        'metadata': {
          'created': '2024-01-01',
          'updated': '2024-01-02',
          'author': 'John Doe',
        },
        'done': false,
      };

      final delta = {
        'done': true,
      };

      final savings = DeltaCalculator.calculateSavings(fullDoc, delta);

      expect(savings, greaterThan(90.0)); // Should save > 90%
    });

    test('should calculate zero savings for full document update', () {
      final doc = {
        'field1': 'value1',
        'field2': 'value2',
      };

      final savings = DeltaCalculator.calculateSavings(doc, doc);

      expect(savings, 0.0);
    });

    test('should calculate savings for large document', () {
      final fullDoc = {
        'content': 'A' * 10000, // 10KB
        'metadata': {'key': 'value'},
      };

      final delta = {
        'metadata': {'key': 'new value'},
      };

      final savings = DeltaCalculator.calculateSavings(fullDoc, delta);

      expect(savings, greaterThan(95.0)); // Should save > 95%
    });

    test('should handle empty document', () {
      final savings = DeltaCalculator.calculateSavings({}, {});

      expect(savings, 0.0);
    });
  });

  group('DocumentDelta - Serialization', () {
    test('should serialize to JSON', () {
      final delta = DocumentDelta(
        recordId: 'doc123',
        collectionName: 'todos',
        changedFields: {'done': true, 'priority': 10},
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        baseVersion: 5,
      );

      final json = delta.toJson();

      expect(json['recordId'], 'doc123');
      expect(json['collectionName'], 'todos');
      expect(json['changedFields'], {'done': true, 'priority': 10});
      expect(json['timestamp'], '2024-01-01T12:00:00.000');
      expect(json['baseVersion'], 5);
    });

    test('should deserialize from JSON', () {
      final json = {
        'recordId': 'doc456',
        'collectionName': 'notes',
        'changedFields': {'title': 'New Title'},
        'timestamp': '2024-01-02T15:30:00.000',
        'baseVersion': 3,
      };

      final delta = DocumentDelta.fromJson(json);

      expect(delta.recordId, 'doc456');
      expect(delta.collectionName, 'notes');
      expect(delta.changedFields, {'title': 'New Title'});
      expect(delta.timestamp, DateTime(2024, 1, 2, 15, 30, 0));
      expect(delta.baseVersion, 3);
    });

    test('should round-trip through JSON', () {
      final original = DocumentDelta(
        recordId: 'doc789',
        collectionName: 'tasks',
        changedFields: {
          'done': true,
          'tags': ['urgent', 'important'],
        },
        timestamp: DateTime(2024, 1, 3, 10, 15, 30),
        baseVersion: 7,
      );

      final json = original.toJson();
      final restored = DocumentDelta.fromJson(json);

      expect(restored.recordId, original.recordId);
      expect(restored.collectionName, original.collectionName);
      expect(restored.changedFields, original.changedFields);
      expect(restored.timestamp, original.timestamp);
      expect(restored.baseVersion, original.baseVersion);
    });
  });

  group('DeltaCalculator - Edge Cases', () {
    test('should handle very large documents', () {
      final oldDoc = {
        'content': 'A' * 100000, // 100KB
        'metadata': {'version': 1},
      };

      final newDoc = {
        'content': 'A' * 100000,
        'metadata': {'version': 2},
      };

      final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

      expect(delta, {
        'metadata': {'version': 2},
      });
    });

    test('should handle special characters', () {
      final oldDoc = {
        'text': 'Hello',
      };

      final newDoc = {
        'text': '你好 🌍 مرحبا',
      };

      final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

      expect(delta, {
        'text': '你好 🌍 مرحبا',
      });
    });

    test('should handle numeric precision', () {
      final oldDoc = {
        'value': 0.1 + 0.2, // 0.30000000000000004
      };

      final newDoc = {
        'value': 0.3,
      };

      final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

      // Should detect the difference
      expect(delta.containsKey('value'), isTrue);
    });

    test('should handle empty strings vs null', () {
      final oldDoc = {
        'field': '',
      };

      final newDoc = {
        'field': null,
      };

      final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);

      expect(delta, {
        'field': null,
      });
    });
  });

  group('DeltaCalculator - Performance', () {
    test('should calculate delta for 1000 fields efficiently', () {
      final oldDoc = <String, dynamic>{};
      final newDoc = <String, dynamic>{};

      for (int i = 0; i < 1000; i++) {
        oldDoc['field$i'] = 'value$i';
        newDoc['field$i'] = i % 2 == 0 ? 'value$i' : 'changed$i';
      }

      final stopwatch = Stopwatch()..start();
      final delta = DeltaCalculator.calculateDelta(oldDoc, newDoc);
      stopwatch.stop();

      expect(delta.length, 500); // Half changed
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // < 100ms
    });

    test('should apply delta to 1000 fields efficiently', () {
      final doc = <String, dynamic>{};
      final delta = <String, dynamic>{};

      for (int i = 0; i < 1000; i++) {
        doc['field$i'] = 'value$i';
        if (i % 2 == 0) {
          delta['field$i'] = 'changed$i';
        }
      }

      final stopwatch = Stopwatch()..start();
      final result = DeltaCalculator.applyDelta(doc, delta);
      stopwatch.stop();

      expect(result.length, 1000);
      expect(stopwatch.elapsedMilliseconds, lessThan(50)); // < 50ms
    });
  });
}
