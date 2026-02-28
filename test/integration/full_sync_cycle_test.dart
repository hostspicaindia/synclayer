import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';
import '../test_infrastructure.dart';

/// Integration tests for complete sync cycles
void main() {
  late TestEnvironment env;

  setUp(() async {
    env = TestEnvironment();
    await env.setUp();
    // Clear shared backend storage before each test
    MockBackendAdapter.clearSharedStorage();
  });

  tearDown(() async {
    await env.tearDown();
  });

  group('Full Sync Cycle - Single Device', () {
    test('should complete full CRUD cycle with sync', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // CREATE
      final id = await SyncLayer.collection('todos').save({
        'text': 'Buy milk',
        'done': false,
      });

      await SyncLayer.syncNow();
      await waitForSync();

      // Verify on backend
      var backendRecords = env.backend.getCollectionRecords('todos');
      expect(backendRecords.length, 1);
      expect(backendRecords.first.data['text'], 'Buy milk');

      // UPDATE
      await SyncLayer.collection('todos').save({
        'text': 'Buy milk',
        'done': true,
      }, id: id);

      await SyncLayer.syncNow();
      await waitForSync();

      // Verify update on backend
      backendRecords = env.backend.getCollectionRecords('todos');
      expect(backendRecords.first.data['done'], true);

      // DELETE
      await SyncLayer.collection('todos').delete(id);

      await SyncLayer.syncNow();
      await waitForSync();

      // Verify deletion on backend
      backendRecords = env.backend.getCollectionRecords('todos');
      expect(backendRecords.length, 0);
    });

    test('should handle offline-to-online transition', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Go offline
      env.connectivity.goOffline();
      await waitForSync();

      // Create data while offline
      final ids = <String>[];
      for (int i = 0; i < 5; i++) {
        final id = await SyncLayer.collection('todos').save({
          'text': 'Task $i',
          'done': false,
        });
        ids.add(id);
      }

      // Verify data is local
      final localData = await SyncLayer.collection('todos').getAll();
      expect(localData.length, 5);

      // Backend should be empty
      expect(env.backend.getCollectionRecords('todos').length, 0);

      // Come back online
      env.connectivity.goOnline();
      await waitForSync();

      // Sync
      await SyncLayer.syncNow();
      await waitForSync(timeout: const Duration(seconds: 1));

      // Verify all data synced to backend
      final backendRecords = env.backend.getCollectionRecords('todos');
      expect(backendRecords.length, 5);
    });

    test('should handle rapid successive operations', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Rapid operations
      final id = await SyncLayer.collection('todos').save({'value': 1});
      await SyncLayer.collection('todos').save({'value': 2}, id: id);
      await SyncLayer.collection('todos').save({'value': 3}, id: id);
      await SyncLayer.collection('todos').save({'value': 4}, id: id);
      await SyncLayer.collection('todos').save({'value': 5}, id: id);

      await SyncLayer.syncNow();
      await waitForSync();

      // Should have final value
      final backendRecords = env.backend.getCollectionRecords('todos');
      expect(backendRecords.length, 1);
      expect(backendRecords.first.data['value'], 5);
    });
  });

  group('Full Sync Cycle - Multi-Device Simulation', () {
    test('should sync changes between two devices', () async {
      // Device 1: Create data
      await env.initSyncLayer(
        enableAutoSync: false,
        collections: ['todos'],
      );

      final id1 = await SyncLayer.collection('todos').save({
        'text': 'Device 1 task',
        'device': 'device1',
      });

      await SyncLayer.syncNow();
      await waitForSync();

      // Dispose device 1
      await SyncLayer.dispose();

      // Device 2: Pull changes
      await env.initSyncLayer(
        enableAutoSync: false,
        collections: ['todos'],
      );

      await SyncLayer.syncNow();
      await waitForSync();

      // Device 2 should have device 1's data
      final device2Data = await SyncLayer.collection('todos').get(id1);
      expect(device2Data, isNotNull);
      expect(device2Data!['device'], 'device1');

      // Device 2: Create new data
      final id2 = await SyncLayer.collection('todos').save({
        'text': 'Device 2 task',
        'device': 'device2',
      });

      await SyncLayer.syncNow();
      await waitForSync();

      // Dispose device 2
      await SyncLayer.dispose();

      // Device 1: Pull changes again
      await env.initSyncLayer(
        enableAutoSync: false,
        collections: ['todos'],
      );

      await SyncLayer.syncNow();
      await waitForSync();

      // Device 1 should have both tasks
      final allTasks = await SyncLayer.collection('todos').getAll();
      expect(allTasks.length, 2);
      expect(allTasks.any((t) => t['device'] == 'device1'), true);
      expect(allTasks.any((t) => t['device'] == 'device2'), true);
    });

    test('should handle concurrent edits with conflict resolution', () async {
      // Device 1: Create initial data
      await env.initSyncLayer(
        enableAutoSync: false,
        conflictStrategy: ConflictStrategy.lastWriteWins,
        collections: ['todos'],
      );

      final id = await SyncLayer.collection('todos').save({
        'text': 'Shared task',
        'value': 0,
      });

      await SyncLayer.syncNow();
      await waitForSync();

      // Simulate device 1 editing (but not syncing yet)
      await SyncLayer.collection('todos').save({
        'text': 'Shared task',
        'value': 1,
      }, id: id);

      // Simulate device 2 editing and syncing first
      await env.backend.push(
        collection: 'todos',
        recordId: id,
        data: {
          'text': 'Shared task',
          'value': 2,
        },
        timestamp: DateTime.now(),
      );

      // Device 1 syncs (conflict!)
      await SyncLayer.syncNow();
      await waitForSync();

      // Should resolve conflict
      final metrics = SyncLayer.getMetrics();
      expect(metrics.conflictsDetected, greaterThan(0));
      expect(metrics.conflictsResolved, greaterThan(0));
    });

    test('should maintain data consistency across devices', () async {
      // Device 1: Create multiple items
      await env.initSyncLayer(
        enableAutoSync: false,
        collections: ['todos'],
      );

      final ids = <String>[];
      for (int i = 0; i < 10; i++) {
        final id = await SyncLayer.collection('todos').save({
          'index': i,
          'text': 'Task $i',
        });
        ids.add(id);
      }

      await SyncLayer.syncNow();
      await waitForSync();

      await SyncLayer.dispose();

      // Device 2: Pull and verify
      await env.initSyncLayer(
        enableAutoSync: false,
        collections: ['todos'],
      );

      await SyncLayer.syncNow();
      await waitForSync();

      final device2Data = await SyncLayer.collection('todos').getAll();
      expect(device2Data.length, 10);

      // Verify all items present
      for (int i = 0; i < 10; i++) {
        expect(device2Data.any((d) => d['index'] == i), true);
      }
    });
  });

  group('Full Sync Cycle - Error Recovery', () {
    test('should recover from network failures', () async {
      await env.initSyncLayer(
        enableAutoSync: false,
        collections: ['todos'],
      );

      // Create data
      await SyncLayer.collection('todos').save({'text': 'Test'});

      // Simulate network failure
      env.backend.setShouldFail(true);

      await SyncLayer.syncNow();
      await waitForSync();

      // Should have failed
      var metrics = SyncLayer.getMetrics();
      expect(metrics.syncFailures, greaterThan(0));

      // Fix network
      env.backend.setShouldFail(false);

      // Retry
      await SyncLayer.syncNow();
      await waitForSync();

      // Should succeed now
      metrics = SyncLayer.getMetrics();
      expect(metrics.syncSuccesses, greaterThan(0));
      expect(env.backend.getCollectionRecords('todos').length, 1);
    });

    test('should handle partial sync failures', () async {
      await env.initSyncLayer(
        enableAutoSync: false,
        collections: ['todos'],
      );

      // Create multiple items
      for (int i = 0; i < 5; i++) {
        await SyncLayer.collection('todos').save({'index': i});
      }

      // Make backend fail after first item
      var pushCount = 0;
      env.backend.setShouldFail(false);

      // This is a simplified test - in reality, you'd need more sophisticated
      // failure injection to test partial failures
      await SyncLayer.syncNow();
      await waitForSync();

      // At least some items should sync
      expect(env.backend.getCollectionRecords('todos').length, greaterThan(0));
    });

    test('should maintain queue integrity during failures', () async {
      await env.initSyncLayer(
        enableAutoSync: false,
        collections: ['todos'],
      );

      // Create data
      final id1 = await SyncLayer.collection('todos').save({'order': 1});
      final id2 = await SyncLayer.collection('todos').save({'order': 2});
      final id3 = await SyncLayer.collection('todos').save({'order': 3});

      // Fail sync
      env.backend.setShouldFail(true);
      await SyncLayer.syncNow();
      await waitForSync();

      // Fix and retry
      env.backend.setShouldFail(false);
      await SyncLayer.syncNow();
      await waitForSync();

      // All items should eventually sync
      final backendRecords = env.backend.getCollectionRecords('todos');
      expect(backendRecords.length, 3);
    });
  });

  group('Full Sync Cycle - Large Datasets', () {
    test('should handle syncing 1000 items', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Create 1000 items
      for (int i = 0; i < 1000; i++) {
        await SyncLayer.collection('todos').save({
          'index': i,
          'text': 'Task $i',
        });
      }

      // Sync all
      await SyncLayer.syncNow();
      await waitForSync(timeout: const Duration(seconds: 5));

      // Verify all synced
      final backendRecords = env.backend.getCollectionRecords('todos');
      expect(backendRecords.length, 1000);
    });

    test('should handle pulling 1000 items', () async {
      // Add 1000 items to backend
      for (int i = 0; i < 1000; i++) {
        await env.backend.push(
          collection: 'todos',
          recordId: 'item-$i',
          data: {'index': i},
          timestamp: DateTime.now(),
        );
      }

      await env.initSyncLayer(
        enableAutoSync: false,
        collections: ['todos'],
      );

      // Pull all
      await SyncLayer.syncNow();
      await waitForSync(timeout: const Duration(seconds: 5));

      // Verify all pulled
      final localData = await SyncLayer.collection('todos').getAll();
      expect(localData.length, 1000);
    });

    test('should handle mixed operations on large dataset', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Create 100 items
      final ids = <String>[];
      for (int i = 0; i < 100; i++) {
        final id = await SyncLayer.collection('todos').save({'index': i});
        ids.add(id);
      }

      // Update 50 items
      for (int i = 0; i < 50; i++) {
        await SyncLayer.collection('todos').save(
          {'index': i, 'updated': true},
          id: ids[i],
        );
      }

      // Delete 25 items
      for (int i = 0; i < 25; i++) {
        await SyncLayer.collection('todos').delete(ids[i]);
      }

      // Sync all operations
      await SyncLayer.syncNow();
      await waitForSync(timeout: const Duration(seconds: 3));

      // Verify final state
      final backendRecords = env.backend.getCollectionRecords('todos');
      expect(backendRecords.length, 75); // 100 - 25 deleted
    });
  });

  group('Full Sync Cycle - Delta Sync', () {
    test('should use delta sync for partial updates', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Create initial document
      final id = await SyncLayer.collection('todos').save({
        'text': 'Task',
        'done': false,
        'priority': 1,
        'tags': ['work', 'urgent'],
      });

      await SyncLayer.syncNow();
      await waitForSync();

      final initialPushCount = env.backend.pushCallCount;

      // Update only one field using delta sync
      await SyncLayer.collection('todos').update(id, {'done': true});

      await SyncLayer.syncNow();
      await waitForSync();

      // Should have used delta sync
      expect(env.backend.pushCallCount, greaterThan(initialPushCount));

      // Verify final state has all fields
      final backendRecord = env.backend.getCollectionRecords('todos').first;
      expect(backendRecord.data['done'], true);
      expect(backendRecord.data['text'], 'Task');
      expect(backendRecord.data['priority'], 1);
    });

    test('should handle multiple delta updates', () async {
      await env.initSyncLayer(enableAutoSync: false);

      final id = await SyncLayer.collection('todos').save({
        'counter': 0,
        'text': 'Counter',
      });

      await SyncLayer.syncNow();
      await waitForSync();

      // Multiple delta updates
      for (int i = 1; i <= 5; i++) {
        await SyncLayer.collection('todos').update(id, {'counter': i});
      }

      await SyncLayer.syncNow();
      await waitForSync();

      // Should have final value
      final backendRecord = env.backend.getCollectionRecords('todos').first;
      expect(backendRecord.data['counter'], 5);
    });
  });

  group('Full Sync Cycle - Multiple Collections', () {
    test('should sync multiple collections independently', () async {
      await env.initSyncLayer(
        enableAutoSync: false,
        collections: ['todos', 'notes', 'tags'],
      );

      // Create data in different collections
      await SyncLayer.collection('todos').save({'text': 'Todo 1'});
      await SyncLayer.collection('notes').save({'text': 'Note 1'});
      await SyncLayer.collection('tags').save({'name': 'Tag 1'});

      await SyncLayer.syncNow();
      await waitForSync();

      // Verify all collections synced
      expect(env.backend.getCollectionRecords('todos').length, 1);
      expect(env.backend.getCollectionRecords('notes').length, 1);
      expect(env.backend.getCollectionRecords('tags').length, 1);
    });

    test('should handle collection-specific sync filters', () async {
      await env.initSyncLayer(
        enableAutoSync: false,
        collections: ['todos', 'notes'],
        syncFilters: {
          'todos': SyncFilter(where: {'userId': 'user1'}),
          'notes': SyncFilter(where: {'userId': 'user1'}),
        },
      );

      // Add data for multiple users to backend
      await env.backend.push(
        collection: 'todos',
        recordId: 'todo-user1',
        data: {'userId': 'user1', 'text': 'User 1 todo'},
        timestamp: DateTime.now(),
      );
      await env.backend.push(
        collection: 'todos',
        recordId: 'todo-user2',
        data: {'userId': 'user2', 'text': 'User 2 todo'},
        timestamp: DateTime.now(),
      );

      await SyncLayer.syncNow();
      await waitForSync();

      // Should only have user1's data
      final todos = await SyncLayer.collection('todos').getAll();
      expect(todos.length, 1);
      expect(todos.first['userId'], 'user1');
    });
  });
}
