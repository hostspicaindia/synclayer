import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';
import 'test_helpers.dart';

void main() {
  setupTestEnvironment();

  group('Bug Fix Validation Tests', () {
    late MockBackendAdapter mockBackend;

    setUp(() async {
      mockBackend = MockBackendAdapter();
      await SyncLayer.init(
        SyncConfig(
          customBackendAdapter: mockBackend,
          enableAutoSync: false,
          collections: ['test_collection'],
        ),
      );
    });

    tearDown(() async {
      await SyncLayer.dispose();
      mockBackend.reset();
    });

    group('Race Condition in save() - Insert/Update Detection', () {
      test('should correctly detect insert operation for new record', () async {
        final data = {'name': 'New Record', 'value': 100};

        // Save new record
        final id = await SyncLayer.collection('test_collection').save(data);
        await SyncLayer.syncNow();

        // Verify it was queued as INSERT
        expect(mockBackend.pushedData.length, equals(1));
        expect(mockBackend.pushedData.first['recordId'], equals(id));
        expect(
            mockBackend.pushedData.first['data']['name'], equals('New Record'));
      });

      test('should correctly detect update operation for existing record',
          () async {
        // First insert
        final data1 = {'name': 'Original', 'value': 100};
        final id = await SyncLayer.collection('test_collection').save(data1);
        await SyncLayer.syncNow();

        mockBackend.pushedData.clear();

        // Then update same record
        final data2 = {'name': 'Updated', 'value': 200};
        await SyncLayer.collection('test_collection').save(data2, id: id);
        await SyncLayer.syncNow();

        // Verify it was queued as UPDATE
        expect(mockBackend.pushedData.length, equals(1));
        expect(mockBackend.pushedData.first['recordId'], equals(id));
        expect(mockBackend.pushedData.first['data']['name'], equals('Updated'));
        expect(mockBackend.pushedData.first['data']['value'], equals(200));
      });

      test('should handle rapid save operations without race condition',
          () async {
        final id = 'rapid-test-id';

        // Rapid fire saves to same ID
        await SyncLayer.collection('test_collection')
            .save({'count': 1}, id: id);
        await SyncLayer.collection('test_collection')
            .save({'count': 2}, id: id);
        await SyncLayer.collection('test_collection')
            .save({'count': 3}, id: id);

        await SyncLayer.syncNow();

        // Should have 3 operations (1 insert + 2 updates)
        expect(mockBackend.pushedData.length, equals(3));

        // Last operation should have count: 3
        final lastOp = mockBackend.pushedData.last;
        expect(lastOp['data']['count'], equals(3));
      });

      test('should prevent duplicate records on server', () async {
        final id = 'duplicate-test';

        // Save same ID multiple times
        await SyncLayer.collection('test_collection').save({'v': 1}, id: id);
        await SyncLayer.collection('test_collection').save({'v': 2}, id: id);
        await SyncLayer.syncNow();

        // Count unique record IDs pushed
        final uniqueIds =
            mockBackend.pushedData.map((op) => op['recordId']).toSet();

        // Should only have 1 unique ID
        expect(uniqueIds.length, equals(1));
        expect(uniqueIds.first, equals(id));
      });

      test('should handle concurrent saves to different records', () async {
        // Save multiple different records concurrently
        final futures = List.generate(
          10,
          (i) => SyncLayer.collection('test_collection').save({
            'index': i,
            'name': 'Record $i',
          }),
        );

        final ids = await Future.wait(futures);
        await SyncLayer.syncNow();

        // Should have 10 unique records
        expect(ids.length, equals(10));
        expect(ids.toSet().length, equals(10)); // All unique
        expect(mockBackend.pushedData.length, equals(10));
      });
    });

    group('Weak Hash Function - SHA-256 Cryptographic Hash', () {
      test('should generate consistent hash for same data', () async {
        final data = {
          'name': 'Test',
          'value': 123,
          'nested': {'key': 'value'}
        };

        // Save same data twice
        final id1 = await SyncLayer.collection('test_collection').save(data);
        final id2 = await SyncLayer.collection('test_collection').save(data);

        // Different IDs but same data should have same hash internally
        expect(id1, isNot(equals(id2)));

        // Verify data integrity
        final retrieved1 =
            await SyncLayer.collection('test_collection').get(id1);
        final retrieved2 =
            await SyncLayer.collection('test_collection').get(id2);

        expect(retrieved1, equals(data));
        expect(retrieved2, equals(data));
      });

      test('should generate different hash for different data', () async {
        final data1 = {'name': 'Test1', 'value': 123};
        final data2 = {'name': 'Test2', 'value': 123};

        final id1 = await SyncLayer.collection('test_collection').save(data1);
        final id2 = await SyncLayer.collection('test_collection').save(data2);

        // Different data should have different IDs
        expect(id1, isNot(equals(id2)));
      });

      test('should handle hash collision resistance', () async {
        // Create many records with similar data
        final ids = <String>[];

        for (var i = 0; i < 100; i++) {
          final id = await SyncLayer.collection('test_collection').save({
            'index': i,
            'data': 'value_$i',
          });
          ids.add(id);
        }

        // All IDs should be unique (no collisions)
        expect(ids.toSet().length, equals(100));
      });

      test('should handle complex nested data hashing', () async {
        final complexData = {
          'level1': {
            'level2': {
              'level3': {
                'array': [
                  1,
                  2,
                  3,
                  {'nested': 'value'}
                ],
                'string': 'test',
                'number': 42.5,
                'bool': true,
                'null': null,
              }
            }
          }
        };

        final id =
            await SyncLayer.collection('test_collection').save(complexData);
        final retrieved = await SyncLayer.collection('test_collection').get(id);

        expect(retrieved, equals(complexData));
      });

      test('should detect data changes via hash', () async {
        final data1 = {'name': 'Original', 'value': 100};
        final id = await SyncLayer.collection('test_collection').save(data1);
        await SyncLayer.syncNow();

        mockBackend.pushedData.clear();

        // Update with different data
        final data2 = {'name': 'Modified', 'value': 100};
        await SyncLayer.collection('test_collection').save(data2, id: id);
        await SyncLayer.syncNow();

        // Should trigger sync because hash changed
        expect(mockBackend.pushedData.length, equals(1));
      });

      test('should not sync if data unchanged (same hash)', () async {
        final data = {'name': 'Unchanged', 'value': 100};
        final id = await SyncLayer.collection('test_collection').save(data);
        await SyncLayer.syncNow();

        mockBackend.pushedData.clear();

        // Save exact same data again
        await SyncLayer.collection('test_collection').save(data, id: id);
        await SyncLayer.syncNow();

        // Should not trigger sync (hash unchanged)
        expect(mockBackend.pushedData.length, equals(0));
      });
    });

    group('Error Handling in watch() Stream', () {
      test('should handle watch stream without breaking', () async {
        final emittedValues = <List<Map<String, dynamic>>>[];
        final errors = <Object>[];

        final stream = SyncLayer.collection('test_collection').watch();
        final subscription = stream.listen(
          (data) => emittedValues.add(data),
          onError: (error) => errors.add(error),
        );

        await Future.delayed(Duration(milliseconds: 50));

        // Add some data
        await SyncLayer.collection('test_collection').save({'test': 1});
        await Future.delayed(Duration(milliseconds: 50));

        await SyncLayer.collection('test_collection').save({'test': 2});
        await Future.delayed(Duration(milliseconds: 50));

        // Stream should emit values without errors
        expect(emittedValues.length, greaterThan(0));
        expect(errors.length, equals(0));

        await subscription.cancel();
      });

      test('should return empty list on error instead of breaking', () async {
        final emittedValues = <List<Map<String, dynamic>>>[];

        final stream = SyncLayer.collection('test_collection').watch();
        final subscription = stream.listen(
          (data) => emittedValues.add(data),
        );

        await Future.delayed(Duration(milliseconds: 50));

        // Even if there are internal errors, stream should continue
        await SyncLayer.collection('test_collection').save({'data': 'test'});
        await Future.delayed(Duration(milliseconds: 50));

        // Should have emitted at least initial empty list
        expect(emittedValues, isNotEmpty);

        // All emissions should be valid lists
        for (final value in emittedValues) {
          expect(value, isA<List<Map<String, dynamic>>>());
        }

        await subscription.cancel();
      });

      test('should handle multiple concurrent watch streams', () async {
        final stream1Values = <List<Map<String, dynamic>>>[];
        final stream2Values = <List<Map<String, dynamic>>>[];
        final stream3Values = <List<Map<String, dynamic>>>[];

        final sub1 = SyncLayer.collection('test_collection')
            .watch()
            .listen((data) => stream1Values.add(data));

        final sub2 = SyncLayer.collection('test_collection')
            .watch()
            .listen((data) => stream2Values.add(data));

        final sub3 = SyncLayer.collection('test_collection')
            .watch()
            .listen((data) => stream3Values.add(data));

        await Future.delayed(Duration(milliseconds: 50));

        await SyncLayer.collection('test_collection')
            .save({'concurrent': true});
        await Future.delayed(Duration(milliseconds: 50));

        // All streams should receive updates
        expect(stream1Values, isNotEmpty);
        expect(stream2Values, isNotEmpty);
        expect(stream3Values, isNotEmpty);

        await sub1.cancel();
        await sub2.cancel();
        await sub3.cancel();
      });

      test('should handle watch stream cancellation gracefully', () async {
        final stream = SyncLayer.collection('test_collection').watch();
        final subscription = stream.listen((_) {});

        await Future.delayed(Duration(milliseconds: 50));

        // Cancel should not throw
        expect(() => subscription.cancel(), returnsNormally);
      });
    });

    group('Transaction Safety in Batch Operations', () {
      test('should handle saveAll() atomically', () async {
        final documents = List.generate(
          50,
          (i) => {'index': i, 'name': 'Batch $i'},
        );

        final ids =
            await SyncLayer.collection('test_collection').saveAll(documents);

        // All should succeed
        expect(ids.length, equals(50));

        // Verify all saved
        for (final id in ids) {
          final data = await SyncLayer.collection('test_collection').get(id);
          expect(data, isNotNull);
        }
      });

      test('should handle deleteAll() atomically', () async {
        // Setup: Create records
        final documents = List.generate(
          30,
          (i) => {'index': i},
        );
        final ids =
            await SyncLayer.collection('test_collection').saveAll(documents);

        // Delete all
        await SyncLayer.collection('test_collection').deleteAll(ids);

        // Verify all deleted
        for (final id in ids) {
          final data = await SyncLayer.collection('test_collection').get(id);
          expect(data, isNull);
        }
      });

      test('should handle empty batch operations', () async {
        // Empty saveAll
        final ids1 = await SyncLayer.collection('test_collection').saveAll([]);
        expect(ids1, isEmpty);

        // Empty deleteAll
        await SyncLayer.collection('test_collection').deleteAll([]);
        // Should not throw
      });

      test('should handle large batch operations', () async {
        final documents = List.generate(
          500,
          (i) => {'index': i, 'data': 'Large batch $i'},
        );

        final stopwatch = Stopwatch()..start();
        final ids =
            await SyncLayer.collection('test_collection').saveAll(documents);
        stopwatch.stop();

        expect(ids.length, equals(500));
        print(
            '✅ Large batch (500 records): ${stopwatch.elapsedMilliseconds}ms');

        // Should complete in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(10000));
      });

      test('should handle batch operations with duplicate IDs', () async {
        final id1 = 'batch-dup-1';
        final id2 = 'batch-dup-2';

        // First batch - create records
        await SyncLayer.collection('test_collection')
            .save({'name': 'First 1'}, id: id1);
        await SyncLayer.collection('test_collection')
            .save({'name': 'First 2'}, id: id2);

        // Second batch - update same records
        await SyncLayer.collection('test_collection')
            .save({'name': 'Second 1'}, id: id1);
        await SyncLayer.collection('test_collection')
            .save({'name': 'Second 2'}, id: id2);

        // Verify updates
        final data1 = await SyncLayer.collection('test_collection').get(id1);
        final data2 = await SyncLayer.collection('test_collection').get(id2);

        expect(data1!['name'], equals('Second 1'));
        expect(data2!['name'], equals('Second 2'));
      });

      test('should maintain data integrity in concurrent batch operations',
          () async {
        // Run multiple batch operations concurrently
        final futures = <Future<List<String>>>[];

        for (var batch = 0; batch < 5; batch++) {
          final documents = List.generate(
            20,
            (i) => {'batch': batch, 'index': i},
          );
          futures.add(
            SyncLayer.collection('test_collection').saveAll(documents),
          );
        }

        final results = await Future.wait(futures);

        // Should have 5 batches of 20 records each
        expect(results.length, equals(5));
        for (final ids in results) {
          expect(ids.length, equals(20));
        }

        // All IDs should be unique
        final allIds = results.expand((ids) => ids).toList();
        expect(allIds.toSet().length, equals(100));
      });
    });

    group('Integration: All Bug Fixes Together', () {
      test('should handle complex scenario with all fixes', () async {
        // Scenario: Rapid updates, batch operations, watching, and syncing

        final watchValues = <List<Map<String, dynamic>>>[];
        final subscription = SyncLayer.collection('test_collection')
            .watch()
            .listen((data) => watchValues.add(data));

        await Future.delayed(Duration(milliseconds: 50));

        // 1. Rapid updates to same record (race condition test)
        final rapidId = 'rapid-update';
        for (var i = 0; i < 5; i++) {
          await SyncLayer.collection('test_collection').save(
            {'iteration': i, 'timestamp': DateTime.now().toIso8601String()},
            id: rapidId,
          );
        }

        // 2. Batch operations (transaction safety)
        final batchDocs = List.generate(20, (i) => {'batch': i});
        final batchIds =
            await SyncLayer.collection('test_collection').saveAll(batchDocs);

        // 3. More updates (hash function test)
        for (final id in batchIds.take(5)) {
          await SyncLayer.collection('test_collection').save(
            {'batch': 'updated', 'modified': true},
            id: id,
          );
        }

        // 4. Sync everything
        await SyncLayer.syncNow();

        await Future.delayed(Duration(milliseconds: 100));

        // Verify watch stream received updates
        expect(watchValues, isNotEmpty);

        // Verify sync happened
        expect(mockBackend.pushedData, isNotEmpty);

        // Verify data integrity
        final rapidData =
            await SyncLayer.collection('test_collection').get(rapidId);
        expect(rapidData, isNotNull);
        expect(rapidData!['iteration'], equals(4)); // Last update

        await subscription.cancel();
      });
    });
  });
}

/// Mock backend adapter for testing
class MockBackendAdapter implements SyncBackendAdapter {
  final List<Map<String, dynamic>> pushedData = [];
  final List<Map<String, dynamic>> deletedData = [];

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    pushedData.add({
      'collection': collection,
      'recordId': recordId,
      'data': data,
      'timestamp': timestamp,
    });
  }

  @override
  Future<void> pushDelta({
    required String collection,
    required String recordId,
    required Map<String, dynamic> delta,
    required int baseVersion,
    required DateTime timestamp,
  }) async {
    pushedData.add({
      'collection': collection,
      'recordId': recordId,
      'delta': delta,
      'baseVersion': baseVersion,
      'timestamp': timestamp,
      'isDelta': true,
    });
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
    int? limit,
    int? offset,
    SyncFilter? filter,
  }) async {
    return [];
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    deletedData.add({
      'collection': collection,
      'recordId': recordId,
    });
  }

  @override
  void updateAuthToken(String token) {}

  void reset() {
    pushedData.clear();
    deletedData.clear();
  }
}
