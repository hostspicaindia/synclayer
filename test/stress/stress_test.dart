import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';
import '../test_infrastructure.dart';

/// Stress tests for large datasets and concurrent operations
void main() {
  late TestEnvironment env;

  setUp(() async {
    env = TestEnvironment();
    await env.setUp();
  });

  tearDown(() async {
    await env.tearDown();
  });

  group('Stress Test - Large Datasets', () {
    test('should handle 10,000 records without memory issues', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Create 10,000 records
      for (int i = 0; i < 10000; i++) {
        await SyncLayer.collection('test').save({
          'index': i,
          'text': 'Record $i',
          'timestamp': DateTime.now().toIso8601String(),
        });

        // Log progress every 1000 records
        if (i % 1000 == 0) {
          print('Created $i records');
        }
      }

      // Query all records
      final allRecords = await SyncLayer.collection('test').getAll();
      expect(allRecords.length, 10000);

      // Sync all records
      await SyncLayer.syncNow();
      await waitForSync(timeout: const Duration(seconds: 30));

      expect(env.backend.getCollectionRecords('test').length, 10000);
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('should handle large documents (1MB each)', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Create large document (1MB of text)
      final largeText = 'x' * (1024 * 1024); // 1MB

      for (int i = 0; i < 10; i++) {
        await SyncLayer.collection('test').save({
          'index': i,
          'largeData': largeText,
        });
      }

      final allRecords = await SyncLayer.collection('test').getAll();
      expect(allRecords.length, 10);

      // Sync large documents
      await SyncLayer.syncNow();
      await waitForSync(timeout: const Duration(seconds: 30));

      expect(env.backend.getCollectionRecords('test').length, 10);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('should handle deeply nested objects', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Create deeply nested structure
      Map<String, dynamic> createNested(int depth) {
        if (depth == 0) {
          return {'value': 'leaf'};
        }
        return {'level': depth, 'nested': createNested(depth - 1)};
      }

      for (int i = 0; i < 100; i++) {
        await SyncLayer.collection('test').save(createNested(50));
      }

      final allRecords = await SyncLayer.collection('test').getAll();
      expect(allRecords.length, 100);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('Stress Test - Concurrent Operations', () {
    test('should handle 100 concurrent saves', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Create 100 concurrent save operations
      final futures = <Future>[];
      for (int i = 0; i < 100; i++) {
        futures.add(SyncLayer.collection('test').save({
          'index': i,
          'text': 'Concurrent $i',
        }));
      }

      await Future.wait(futures);

      final allRecords = await SyncLayer.collection('test').getAll();
      expect(allRecords.length, 100);
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('should handle concurrent reads and writes', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Pre-populate data
      final ids = <String>[];
      for (int i = 0; i < 50; i++) {
        final id = await SyncLayer.collection('test').save({'value': i});
        ids.add(id);
      }

      // Concurrent reads and writes
      final futures = <Future>[];

      // 50 reads
      for (int i = 0; i < 50; i++) {
        futures.add(SyncLayer.collection('test').get(ids[i]));
      }

      // 50 writes
      for (int i = 0; i < 50; i++) {
        futures.add(SyncLayer.collection('test').save({'value': i + 100}));
      }

      await Future.wait(futures);

      final allRecords = await SyncLayer.collection('test').getAll();
      expect(allRecords.length, 100);
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('should handle concurrent sync operations', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Create data
      for (int i = 0; i < 100; i++) {
        await SyncLayer.collection('test').save({'index': i});
      }

      // Trigger multiple concurrent syncs
      final futures = <Future>[];
      for (int i = 0; i < 10; i++) {
        futures.add(SyncLayer.syncNow());
      }

      await Future.wait(futures);
      await waitForSync();

      // Should not duplicate data
      expect(env.backend.getCollectionRecords('test').length, 100);
    }, timeout: const Timeout(Duration(minutes: 1)));
  });

  group('Stress Test - Rapid Operations', () {
    test('should handle rapid successive updates', () async {
      await env.initSyncLayer(enableAutoSync: false);

      final id = await SyncLayer.collection('test').save({'counter': 0});

      // 1000 rapid updates
      for (int i = 1; i <= 1000; i++) {
        await SyncLayer.collection('test').save({'counter': i}, id: id);
      }

      final data = await SyncLayer.collection('test').get(id);
      expect(data!['counter'], 1000);

      await SyncLayer.syncNow();
      await waitForSync(timeout: const Duration(seconds: 10));

      final backendRecord = env.backend.getCollectionRecords('test').first;
      expect(backendRecord.data['counter'], 1000);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('should handle rapid create-delete cycles', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // 100 create-delete cycles
      for (int i = 0; i < 100; i++) {
        final id = await SyncLayer.collection('test').save({'index': i});
        await SyncLayer.collection('test').delete(id);
      }

      final allRecords = await SyncLayer.collection('test').getAll();
      expect(allRecords.length, 0);

      await SyncLayer.syncNow();
      await waitForSync();

      expect(env.backend.getCollectionRecords('test').length, 0);
    }, timeout: const Timeout(Duration(minutes: 1)));
  });

  group('Stress Test - Query Performance', () {
    test('should query 10,000 records efficiently', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Create 10,000 records with various values
      for (int i = 0; i < 10000; i++) {
        await SyncLayer.collection('test').save({
          'index': i,
          'category': i % 10,
          'priority': i % 5,
          'done': i % 2 == 0,
        });
      }

      // Complex query
      final results = await SyncLayer.collection('test')
          .where('done', isEqualTo: false)
          .where('priority', isGreaterThan: 2)
          .orderBy('index', descending: true)
          .limit(100)
          .get();

      expect(results.length, lessThanOrEqualTo(100));
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('should handle multiple concurrent queries', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Create test data
      for (int i = 0; i < 1000; i++) {
        await SyncLayer.collection('test').save({
          'index': i,
          'category': i % 10,
        });
      }

      // 10 concurrent queries
      final futures = <Future>[];
      for (int i = 0; i < 10; i++) {
        futures.add(
          SyncLayer.collection('test').where('category', isEqualTo: i).get(),
        );
      }

      final results = await Future.wait(futures);
      expect(results.length, 10);
    }, timeout: const Timeout(Duration(minutes: 1)));
  });

  group('Stress Test - Memory Management', () {
    test('should not leak memory with repeated operations', () async {
      await env.initSyncLayer(enableAutoSync: false);

      // Perform 1000 cycles of create-read-delete
      for (int cycle = 0; cycle < 1000; cycle++) {
        final id = await SyncLayer.collection('test').save({
          'cycle': cycle,
          'data': 'x' * 1000, // 1KB
        });

        await SyncLayer.collection('test').get(id);
        await SyncLayer.collection('test').delete(id);

        if (cycle % 100 == 0) {
          print('Completed $cycle cycles');
        }
      }

      // Final state should be empty
      final allRecords = await SyncLayer.collection('test').getAll();
      expect(allRecords.length, 0);
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
