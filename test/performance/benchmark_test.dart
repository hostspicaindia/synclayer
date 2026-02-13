import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';

class NoOpBackendAdapter implements SyncBackendAdapter {
  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    // No-op for performance testing
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
  }) async {
    return [];
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    // No-op
  }

  @override
  void updateAuthToken(String token) {}
}

void main() {
  group('Performance Benchmarks', () {
    setUp(() async {
      await SyncLayer.init(
        SyncConfig(
          baseUrl: 'https://test.example.com',
          enableAutoSync: false,
          customBackendAdapter: NoOpBackendAdapter(),
        ),
      );
    });

    tearDown(() async {
      await SyncLayer.dispose();
    });

    test('benchmark: save 100 records', () async {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        await SyncLayer.collection('benchmark').save({
          'index': i,
          'name': 'Record $i',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      stopwatch.stop();
      print('Time to save 100 records: ${stopwatch.elapsedMilliseconds}ms');
      expect(
          stopwatch.elapsedMilliseconds, lessThan(5000)); // Should be under 5s
    });

    test('benchmark: batch save 100 records', () async {
      final documents = List.generate(
        100,
        (i) => {
          'index': i,
          'name': 'Record $i',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      final stopwatch = Stopwatch()..start();
      await SyncLayer.collection('benchmark').saveAll(documents);
      stopwatch.stop();

      print(
          'Time to batch save 100 records: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('benchmark: retrieve 100 records', () async {
      // First, save 100 records
      for (int i = 0; i < 100; i++) {
        await SyncLayer.collection('benchmark').save({
          'index': i,
          'name': 'Record $i',
        });
      }

      final stopwatch = Stopwatch()..start();
      final records = await SyncLayer.collection('benchmark').getAll();
      stopwatch.stop();

      print(
          'Time to retrieve ${records.length} records: ${stopwatch.elapsedMilliseconds}ms');
      expect(
          stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be under 1s
      expect(records.length, greaterThanOrEqualTo(100));
    });

    test('benchmark: delete 100 records', () async {
      // Save records first
      final ids = <String>[];
      for (int i = 0; i < 100; i++) {
        final id = await SyncLayer.collection('benchmark').save({
          'index': i,
        });
        ids.add(id);
      }

      final stopwatch = Stopwatch()..start();
      await SyncLayer.collection('benchmark').deleteAll(ids);
      stopwatch.stop();

      print('Time to delete 100 records: ${stopwatch.elapsedMilliseconds}ms');
      expect(
          stopwatch.elapsedMilliseconds, lessThan(3000)); // Should be under 3s
    });

    test('benchmark: watch stream updates', () async {
      final stopwatch = Stopwatch()..start();
      int updateCount = 0;

      final subscription =
          SyncLayer.collection('benchmark').watch().listen((records) {
        updateCount++;
      });

      // Trigger some updates
      for (int i = 0; i < 10; i++) {
        await SyncLayer.collection('benchmark').save({
          'index': i,
        });
      }

      await Future.delayed(Duration(milliseconds: 500));
      stopwatch.stop();

      print(
          'Stream updates received: $updateCount in ${stopwatch.elapsedMilliseconds}ms');
      expect(updateCount, greaterThan(0));

      await subscription.cancel();
    });

    test('benchmark: concurrent operations', () async {
      final stopwatch = Stopwatch()..start();

      final futures = <Future>[];
      for (int i = 0; i < 50; i++) {
        futures.add(
          SyncLayer.collection('concurrent').save({
            'index': i,
            'name': 'Concurrent $i',
          }),
        );
      }

      await Future.wait(futures);
      stopwatch.stop();

      print('Time for 50 concurrent saves: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });
  });
}
