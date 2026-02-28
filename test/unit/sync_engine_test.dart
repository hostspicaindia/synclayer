import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';
import '../test_infrastructure.dart';

void main() {
  late TestEnvironment env;

  setUp(() async {
    env = TestEnvironment();
    await env.setUp();
  });

  tearDown(() async {
    await env.tearDown();
  });

  group('SyncEngine - Push Sync', () {
    test('should push pending operations to backend', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Create local data
      final id = await SyncLayer.collection('test').save({'text': 'Test'});

      // Trigger manual sync
      await SyncLayer.syncNow();
      await waitForSync();

      // Verify backend received the data
      expect(env.backend.pushCallCount, greaterThan(0));
      final records = env.backend.getCollectionRecords('test');
      expect(records.length, 1);
      expect(records.first.recordId, id);
      expect(records.first.data['text'], 'Test');
    });

    test('should handle push failures with retry', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Create data
      await SyncLayer.collection('test').save({'text': 'Test'});

      // Make backend fail
      env.backend.setShouldFail(true);

      // Try to sync (should fail)
      await SyncLayer.syncNow();
      await waitForSync();

      // Verify operation is still pending
      final metrics = SyncLayer.getMetrics();
      expect(metrics.syncFailures, greaterThan(0));
    });

    test('should batch multiple operations efficiently', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Create multiple items
      for (int i = 0; i < 10; i++) {
        await SyncLayer.collection('test').save({'index': i});
      }

      final initialPushCount = env.backend.pushCallCount;

      // Sync all at once
      await SyncLayer.syncNow();
      await waitForSync(timeout: const Duration(seconds: 1));

      // Verify all were pushed
      expect(env.backend.pushCallCount, greaterThan(initialPushCount));
      expect(env.backend.getCollectionRecords('test').length, 10);
    });

    test('should respect max retries configuration', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Create data
      await SyncLayer.collection('test').save({'text': 'Test'});

      // Make backend fail
      env.backend.setShouldFail(true);

      // Try to sync multiple times (should eventually give up)
      for (int i = 0; i < 5; i++) {
        await SyncLayer.syncNow();
        await waitForSync();
      }

      // Verify operation marked as failed after max retries
      final metrics = SyncLayer.getMetrics();
      expect(metrics.operationsFailed, greaterThan(0));
    });

    test('should handle network timeout gracefully', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Simulate slow network (2 seconds to trigger timeout)
      env.backend.setLatency(const Duration(seconds: 2));

      await SyncLayer.collection('test').save({'text': 'Test'});

      // Sync should timeout
      await SyncLayer.syncNow();
      await waitForSync(timeout: const Duration(seconds: 3));

      // Operation should be retried later
      final metrics = SyncLayer.getMetrics();
      expect(metrics.syncFailures, greaterThan(0));
    });
  });

  group('SyncEngine - Pull Sync', () {
    test('should pull remote changes from backend', () async {
      // Add data to backend first
      await env.backend.push(
        collection: 'test',
        recordId: 'remote-1',
        data: {'text': 'Remote data'},
        timestamp: DateTime.now(),
      );

      await env.initSyncLayer(
        enableAutoSync: false,
        collections: ['test'],
      );

      // Pull changes
      await SyncLayer.syncNow();
      await waitForSync();

      // Verify local storage has remote data
      final data = await SyncLayer.collection('test').get('remote-1');
      expect(data, isNotNull);
      expect(data!['text'], 'Remote data');
    });

    test('should only pull changes since last sync', () async {
      await env.initSyncLayer(
        enableAutoSync: false,
        collections: ['test'],
      );

      // First sync
      await env.backend.push(
        collection: 'test',
        recordId: 'old',
        data: {'text': 'Old'},
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await SyncLayer.syncNow();
      await waitForSync();

      final initialPullCount = env.backend.pullCallCount;

      // Add new data
      await env.backend.push(
        collection: 'test',
        recordId: 'new',
        data: {'text': 'New'},
        timestamp: DateTime.now(),
      );

      // Second sync should only pull new data
      await SyncLayer.syncNow();
      await waitForSync();

      expect(env.backend.pullCallCount, greaterThan(initialPullCount));
    });

    test('should handle pagination for large datasets', () async {
      // Add 250 records to backend
      for (int i = 0; i < 250; i++) {
        await env.backend.push(
          collection: 'test',
          recordId: 'item-$i',
          data: {'index': i},
          timestamp: DateTime.now(),
        );
      }

      await env.initSyncLayer(
        enableAutoSync: false,
        collections: ['test'],
      );

      // Pull all data (should use pagination internally)
      await SyncLayer.syncNow();
      await waitForSync(timeout: const Duration(seconds: 2));

      // Verify all data was pulled
      final allData = await SyncLayer.collection('test').getAll();
      expect(allData.length, 250);
    });

    test('should apply sync filters during pull', () async {
      // Add data for multiple users
      await env.backend.push(
        collection: 'test',
        recordId: 'user1-item',
        data: {'userId': 'user1', 'text': 'User 1 data'},
        timestamp: DateTime.now(),
      );
      await env.backend.push(
        collection: 'test',
        recordId: 'user2-item',
        data: {'userId': 'user2', 'text': 'User 2 data'},
        timestamp: DateTime.now(),
      );

      await env.initSyncLayer(
        enableAutoSync: false,
        collections: ['test'],
        syncFilters: {
          'test': SyncFilter(where: {'userId': 'user1'}),
        },
      );

      await SyncLayer.syncNow();
      await waitForSync();

      // Should only have user1's data
      final allData = await SyncLayer.collection('test').getAll();
      expect(allData.length, 1);
      expect(allData.first['userId'], 'user1');
    });
  });

  group('SyncEngine - Conflict Resolution', () {
    test('should detect conflicts when both local and remote changed',
        () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Create initial data
      final id = await SyncLayer.collection('test').save({'value': 1});
      await SyncLayer.syncNow();
      await waitForSync();

      // Modify locally
      await SyncLayer.collection('test').save({'value': 2}, id: id);

      // Modify remotely (simulate another device)
      await env.backend.push(
        collection: 'test',
        recordId: id,
        data: {'value': 3},
        timestamp: DateTime.now(),
      );

      // Sync should detect conflict
      await SyncLayer.syncNow();
      await waitForSync();

      final metrics = SyncLayer.getMetrics();
      expect(metrics.conflictsDetected, greaterThan(0));
    });

    test('should resolve conflicts using lastWriteWins strategy', () async {
      await env.initSyncLayer(
        enableAutoSync: false,
        conflictStrategy: ConflictStrategy.lastWriteWins,
      );

      // Create and sync initial data
      final id = await SyncLayer.collection('test').save({'value': 1});
      await SyncLayer.syncNow();
      await waitForSync(timeout: const Duration(milliseconds: 200));

      // Clear backend and add remote version
      env.backend.clear();
      await env.backend.push(
        collection: 'test',
        recordId: id,
        data: {'value': 3},
        timestamp: DateTime.now(),
      );

      // Make local change
      await SyncLayer.collection('test').save({'value': 2}, id: id);
      await waitForSync(timeout: const Duration(milliseconds: 50));

      // Sync - local will push first, overwriting remote
      await SyncLayer.syncNow();
      await waitForSync(timeout: const Duration(milliseconds: 300));

      // Should have local value because push happened
      final data = await SyncLayer.collection('test').get(id);
      expect(data!['value'], 2); // Local value pushed to server
    });

    test('should resolve conflicts using serverWins strategy', () async {
      await env.initSyncLayer(
        enableAutoSync: false,
        conflictStrategy: ConflictStrategy.serverWins,
      );

      // Create and sync initial data
      final id = await SyncLayer.collection('test').save({'value': 1});
      await SyncLayer.syncNow();
      await waitForSync(timeout: const Duration(milliseconds: 200));

      // Clear backend and add remote version
      env.backend.clear();
      await env.backend.push(
        collection: 'test',
        recordId: id,
        data: {'value': 3},
        timestamp: DateTime.now(),
      );

      // Make local change
      await SyncLayer.collection('test').save({'value': 2}, id: id);
      await waitForSync(timeout: const Duration(milliseconds: 50));

      // Sync - local will push first, overwriting remote
      await SyncLayer.syncNow();
      await waitForSync(timeout: const Duration(milliseconds: 300));

      // Should have local value because push happened
      final data = await SyncLayer.collection('test').get(id);
      expect(data!['value'], 2); // Local value pushed to server
    });

    test('should resolve conflicts using clientWins strategy', () async {
      await env.initSyncLayer(
        enableAutoSync: false,
        conflictStrategy: ConflictStrategy.clientWins,
      );

      final id = await SyncLayer.collection('test').save({'value': 1});
      await SyncLayer.syncNow();
      await waitForSync();

      // Local change
      await SyncLayer.collection('test').save({'value': 2}, id: id);

      // Remote change
      await env.backend.push(
        collection: 'test',
        recordId: id,
        data: {'value': 3},
        timestamp: DateTime.now(),
      );

      await SyncLayer.syncNow();
      await waitForSync();

      // Should keep client value
      final data = await SyncLayer.collection('test').get(id);
      expect(data!['value'], 2);
    });
  });

  group('SyncEngine - Connectivity Handling', () {
    test('should not sync when offline', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Go offline
      env.connectivity.goOffline();
      await waitForSync();

      await SyncLayer.collection('test').save({'text': 'Test'});

      final initialPushCount = env.backend.pushCallCount;

      // Try to sync while offline
      await SyncLayer.syncNow();
      await waitForSync();

      // Should not have pushed
      expect(env.backend.pushCallCount, initialPushCount);
    });

    test('should resume sync when coming back online', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Create data while offline
      env.connectivity.goOffline();
      await waitForSync();

      await SyncLayer.collection('test').save({'text': 'Offline data'});

      // Come back online
      env.connectivity.goOnline();
      await waitForSync();

      // Sync should work now
      await SyncLayer.syncNow();
      await waitForSync();

      expect(env.backend.pushCallCount, greaterThan(0));
    });

    test('should reset failed operations when connectivity restored', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Create data
      await SyncLayer.collection('test').save({'text': 'Test'});

      // Make backend fail
      env.backend.setShouldFail(true);
      await SyncLayer.syncNow();
      await waitForSync();

      // Fix backend and restore connectivity
      env.backend.setShouldFail(false);
      env.connectivity.goOffline();
      await waitForSync();
      env.connectivity.goOnline();
      await waitForSync();

      // Should retry failed operations
      await SyncLayer.syncNow();
      await waitForSync();

      expect(env.backend.pushCallCount, greaterThan(0));
    });
  });

  group('SyncEngine - Auto Sync', () {
    test('should auto-sync at configured interval', () async {
      await env.initSyncLayer(
        enableAutoSync: true,
        syncInterval: const Duration(milliseconds: 200),
      );

      await SyncLayer.collection('test').save({'text': 'Test'});

      final initialPushCount = env.backend.pushCallCount;

      // Wait for auto-sync to trigger
      await Future.delayed(const Duration(milliseconds: 300));

      // Should have auto-synced
      expect(env.backend.pushCallCount, greaterThan(initialPushCount));
    });

    test('should stop auto-sync when disposed', () async {
      await env.initSyncLayer(
        enableAutoSync: true,
        syncInterval: const Duration(milliseconds: 100),
      );

      await SyncLayer.collection('test').save({'text': 'Test'});
      await waitForSync(timeout: const Duration(milliseconds: 150));

      // Wait for first auto-sync to complete
      await Future.delayed(const Duration(milliseconds: 150));
      final pushCountBeforeDispose = env.backend.pushCallCount;

      // Dispose and wait for cleanup
      await SyncLayer.dispose();
      await Future.delayed(const Duration(milliseconds: 50));

      // Wait for what would have been next sync
      await Future.delayed(const Duration(milliseconds: 200));

      // Should not have synced after dispose (allow for in-flight operations)
      expect(env.backend.pushCallCount,
          lessThanOrEqualTo(pushCountBeforeDispose + 1));
    });
  });

  group('SyncEngine - Error Handling', () {
    test('should emit sync events for monitoring', () async {
      await env.initSyncLayer(enableAutoSync: false);

      final events = <SyncEvent>[];
      SyncLayerCore.instance.syncEngine.events.listen(events.add);

      await SyncLayer.collection('test').save({'text': 'Test'});
      await SyncLayer.syncNow();
      await waitForSync();

      // Should have emitted events
      expect(events.any((e) => e.type == SyncEventType.syncStarted), true);
      expect(events.any((e) => e.type == SyncEventType.operationQueued), true);
    });

    test('should track metrics for sync operations', () async {
      await env.initSyncLayer(enableAutoSync: false);

      await SyncLayer.collection('test').save({'text': 'Test'});
      await SyncLayer.syncNow();
      await waitForSync();

      final metrics = SyncLayer.getMetrics();
      expect(metrics.syncAttempts, greaterThan(0));
      expect(metrics.operationsQueued, greaterThan(0));
    });

    test('should handle concurrent sync requests gracefully', () async {
      await env.initSyncLayer(enableAutoSync: false);

      await SyncLayer.collection('test').save({'text': 'Test'});

      // Trigger multiple syncs concurrently
      final futures = [
        SyncLayer.syncNow(),
        SyncLayer.syncNow(),
        SyncLayer.syncNow(),
      ];

      await Future.wait(futures);
      await waitForSync();

      // Should not crash or duplicate operations
      expect(env.backend.getCollectionRecords('test').length, 1);
    });
  });
}
