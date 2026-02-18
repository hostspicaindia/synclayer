import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';

/// No-op backend adapter for performance testing
class NoOpBackendAdapter implements SyncBackendAdapter {
  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    // No-op for performance testing
    await Future.delayed(Duration(milliseconds: 1));
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
    // No-op
    await Future.delayed(Duration(milliseconds: 1));
  }

  @override
  void updateAuthToken(String token) {
    // No-op
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Benchmarks', () {
    setUp(() async {
      await SyncLayer.init(
        SyncConfig(
          customBackendAdapter: NoOpBackendAdapter(),
          enableAutoSync: false,
          collections: ['todos'],
        ),
      );
    });

    tearDown(() async {
      await SyncLayer.dispose();
    });

    test('benchmark: save 100 records individually', () async {
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {
        await SyncLayer.collection('todos').save({
          'text': 'Task $i',
          'done': false,
          'priority': i % 3,
        });
      }

      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;

      print('✅ Save 100 records: ${elapsed}ms');
      expect(elapsed, lessThan(5000)); // Target: < 5 seconds
    });

    test('benchmark: batch save 100 records', () async {
      final documents = List.generate(
        100,
        (i) => {
          'text': 'Task $i',
          'done': false,
          'priority': i % 3,
        },
      );

      final stopwatch = Stopwatch()..start();

      await SyncLayer.collection('todos').saveAll(documents);

      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;

      print('✅ Batch save 100 records: ${elapsed}ms');
      expect(elapsed, lessThan(5000)); // Target: < 5 seconds
    });

    test('benchmark: retrieve 100 records', () async {
      // Setup: Add 100 records
      final documents = List.generate(
        100,
        (i) => {'text': 'Task $i', 'done': false},
      );
      await SyncLayer.collection('todos').saveAll(documents);

      // Benchmark retrieval
      final stopwatch = Stopwatch()..start();

      final allTodos = await SyncLayer.collection('todos').getAll();

      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;

      print('✅ Retrieve 100 records: ${elapsed}ms');
      expect(elapsed, lessThan(1000)); // Target: < 1 second
      expect(allTodos.length, greaterThanOrEqualTo(100));
    });

    test('benchmark: delete 100 records', () async {
      // Setup: Add 100 records
      final documents = List.generate(
        100,
        (i) => {'text': 'Task $i', 'done': false},
      );
      final ids = await SyncLayer.collection('todos').saveAll(documents);

      // Benchmark deletion
      final stopwatch = Stopwatch()..start();

      await SyncLayer.collection('todos').deleteAll(ids);

      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;

      print('✅ Delete 100 records: ${elapsed}ms');
      expect(elapsed, lessThan(3000)); // Target: < 3 seconds
    });

    test('benchmark: watch stream updates', () async {
      final stopwatch = Stopwatch()..start();
      final emittedValues = <List<Map<String, dynamic>>>[];

      final stream = SyncLayer.collection('todos').watch();
      final subscription = stream.listen((todos) {
        emittedValues.add(todos);
      });

      // Wait for initial emission
      await Future.delayed(Duration(milliseconds: 50));

      // Add 10 records
      for (var i = 0; i < 10; i++) {
        await SyncLayer.collection('todos').save({'text': 'Task $i'});
        await Future.delayed(Duration(milliseconds: 10));
      }

      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;

      print('✅ Watch stream with 10 updates: ${elapsed}ms');
      print('   Emissions: ${emittedValues.length}');

      expect(emittedValues, isNotEmpty);

      await subscription.cancel();
    });

    test('benchmark: concurrent save operations', () async {
      final stopwatch = Stopwatch()..start();

      // Create 50 concurrent save operations
      final futures = List.generate(
        50,
        (i) => SyncLayer.collection('todos').save({
          'text': 'Concurrent task $i',
          'done': false,
        }),
      );

      await Future.wait(futures);

      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;

      print('✅ 50 concurrent saves: ${elapsed}ms');
      expect(elapsed, lessThan(5000)); // Target: < 5 seconds
    });

    test('benchmark: sync 100 operations', () async {
      // Setup: Add 100 records
      final documents = List.generate(
        100,
        (i) => {'text': 'Task $i', 'done': false},
      );
      await SyncLayer.collection('todos').saveAll(documents);

      // Benchmark sync
      final stopwatch = Stopwatch()..start();

      await SyncLayer.syncNow();

      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;

      print('✅ Sync 100 operations: ${elapsed}ms');
      expect(elapsed, lessThan(10000)); // Target: < 10 seconds
    });

    test('benchmark: mixed operations (CRUD)', () async {
      final stopwatch = Stopwatch()..start();

      // Create 25 records
      final createDocs = List.generate(
        25,
        (i) => {'text': 'Create $i', 'done': false},
      );
      final ids = await SyncLayer.collection('todos').saveAll(createDocs);

      // Update 10 records
      for (var i = 0; i < 10; i++) {
        await SyncLayer.collection('todos').save(
          {'text': 'Updated $i', 'done': true},
          id: ids[i],
        );
      }

      // Delete 5 records
      await SyncLayer.collection('todos').deleteAll(ids.sublist(0, 5));

      // Read all
      await SyncLayer.collection('todos').getAll();

      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;

      print('✅ Mixed CRUD operations: ${elapsed}ms');
      expect(elapsed, lessThan(5000)); // Target: < 5 seconds
    });

    test('benchmark: get individual records', () async {
      // Setup: Add 100 records
      final documents = List.generate(
        100,
        (i) => {'text': 'Task $i', 'done': false},
      );
      final ids = await SyncLayer.collection('todos').saveAll(documents);

      // Benchmark individual gets
      final stopwatch = Stopwatch()..start();

      for (final id in ids) {
        await SyncLayer.collection('todos').get(id);
      }

      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;

      print('✅ Get 100 individual records: ${elapsed}ms');
      expect(elapsed, lessThan(2000)); // Target: < 2 seconds
    });

    test('benchmark: large document save', () async {
      // Create a large document (1000 fields)
      final largeDoc = Map.fromIterables(
        List.generate(1000, (i) => 'field_$i'),
        List.generate(1000, (i) => 'value_$i'),
      );

      final stopwatch = Stopwatch()..start();

      await SyncLayer.collection('todos').save(largeDoc);

      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;

      print('✅ Save large document (1000 fields): ${elapsed}ms');
      expect(elapsed, lessThan(1000)); // Target: < 1 second
    });
  });
}
