import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Optimization Tests', () {
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

    group('Pagination for Pull Sync', () {
      test('should fetch records in batches of 100', () async {
        // Setup: Add 250 records to mock backend
        final records = List.generate(
          250,
          (i) => SyncRecord(
            recordId: 'record_$i',
            data: {'index': i, 'value': 'data_$i'},
            updatedAt: DateTime.now(),
            version: 1,
          ),
        );
        mockBackend.remoteData['test_collection'] = records;

        // Act: Trigger sync
        await SyncLayer.syncNow();

        // Assert: Should have made 3 pull requests (100, 100, 50)
        expect(mockBackend.pullCallCount, equals(3));
        expect(mockBackend.pullCalls.length, equals(3));

        // First call: offset 0, limit 100
        expect(mockBackend.pullCalls[0]['offset'], equals(0));
        expect(mockBackend.pullCalls[0]['limit'], equals(100));
      });

      test('should handle large datasets without memory issues', () async {
        // Setup: Simulate 1000 records
        final records = List.generate(
          1000,
          (i) => SyncRecord(
            recordId: 'large_$i',
            data: {'index': i},
            updatedAt: DateTime.now(),
            version: 1,
          ),
        );
        mockBackend.remoteData['test_collection'] = records;

        // Act
        final stopwatch = Stopwatch()..start();
        await SyncLayer.syncNow();
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(30000));
        expect(mockBackend.pullCallCount, equals(10));
        print('✅ Synced 1000 records in ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Database Indexes', () {
      test('should perform fast queries on large collections', () async {
        final documents = List.generate(
          1000,
          (i) => {'index': i, 'name': 'Record $i'},
        );
        await SyncLayer.collection('test_collection').saveAll(documents);

        final stopwatch = Stopwatch()..start();
        final results = await SyncLayer.collection('test_collection').getAll();
        stopwatch.stop();

        expect(results.length, equals(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        print('✅ Query 1000 records: ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Batch Queue Operations', () {
      test('should use batch operations for bulk saves', () async {
        final documents = List.generate(
          200,
          (i) => {'index': i, 'data': 'batch_$i'},
        );

        final stopwatch = Stopwatch()..start();
        final ids =
            await SyncLayer.collection('test_collection').saveAll(documents);
        stopwatch.stop();

        expect(ids.length, equals(200));
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
        print('✅ Batch save 200 records: ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Data Validation', () {
      test('should validate JSON-serializability', () async {
        final validData = {
          'string': 'test',
          'number': 42,
          'list': [1, 2, 3],
        };

        expect(
          () => SyncLayer.collection('test_collection').save(validData),
          returnsNormally,
        );
      });

      test('should throw ArgumentError for invalid data', () async {
        final invalidData = {
          'name': 'test',
          'function': () => print('not serializable'),
        };

        expect(
          () => SyncLayer.collection('test_collection').save(invalidData),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}

/// Mock backend adapter with pagination tracking
class MockBackendAdapter implements SyncBackendAdapter {
  final List<Map<String, dynamic>> pushedData = [];
  final Map<String, List<SyncRecord>> remoteData = {};
  int pullCallCount = 0;
  final List<Map<String, dynamic>> pullCalls = [];

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
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
    int? limit,
    int? offset,
    SyncFilter? filter,
  }) async {
    pullCallCount++;
    pullCalls.add({
      'collection': collection,
      'since': since,
      'limit': limit,
      'offset': offset,
    });

    final records = remoteData[collection] ?? [];
    var filtered = since == null
        ? records
        : records.where((r) => r.updatedAt.isAfter(since)).toList();

    if (offset != null && offset > 0) {
      if (offset >= filtered.length) return [];
      filtered = filtered.skip(offset).toList();
    }

    if (limit != null && limit > 0) {
      filtered = filtered.take(limit).toList();
    }

    return filtered;
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {}

  @override
  void updateAuthToken(String token) {}

  void reset() {
    pushedData.clear();
    remoteData.clear();
    pullCallCount = 0;
    pullCalls.clear();
  }
}
