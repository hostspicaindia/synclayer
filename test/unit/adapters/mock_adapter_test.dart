import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/network/sync_backend_adapter.dart';
import 'package:synclayer/sync/sync_filter.dart';

/// Mock adapter for testing adapter behavior
class MockAdapter implements SyncBackendAdapter {
  final List<Map<String, dynamic>> _storage = [];
  String? _authToken;

  // Track method calls for testing
  int pushCallCount = 0;
  int pullCallCount = 0;
  int deleteCallCount = 0;
  int updateAuthTokenCallCount = 0;

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    pushCallCount++;

    // Simulate storage
    _storage.add({
      'collection': collection,
      'recordId': recordId,
      'data': data,
      'timestamp': timestamp,
      'version': 1,
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
    // For mock, just treat delta as regular push
    await push(
      collection: collection,
      recordId: recordId,
      data: delta,
      timestamp: timestamp,
    );
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

    // Filter by collection and timestamp
    final filtered = _storage.where((item) {
      if (item['collection'] != collection) return false;
      if (since != null && (item['timestamp'] as DateTime).isBefore(since)) {
        return false;
      }
      return true;
    }).toList();

    return filtered.map((item) {
      return SyncRecord(
        recordId: item['recordId'] as String,
        data: item['data'] as Map<String, dynamic>,
        updatedAt: item['timestamp'] as DateTime,
        version: item['version'] as int,
      );
    }).toList();
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    deleteCallCount++;

    _storage.removeWhere((item) =>
        item['collection'] == collection && item['recordId'] == recordId);
  }

  @override
  void updateAuthToken(String token) {
    updateAuthTokenCallCount++;
    _authToken = token;
  }

  // Helper methods for testing
  void clear() {
    _storage.clear();
    pushCallCount = 0;
    pullCallCount = 0;
    deleteCallCount = 0;
    updateAuthTokenCallCount = 0;
  }

  int get storageSize => _storage.length;
  String? get authToken => _authToken;
}

void main() {
  late MockAdapter adapter;

  setUp(() {
    adapter = MockAdapter();
  });

  tearDown(() {
    adapter.clear();
  });

  group('MockAdapter - Push Operations', () {
    test('should push data successfully', () async {
      await adapter.push(
        collection: 'todos',
        recordId: 'todo-1',
        data: {'text': 'Buy milk', 'done': false},
        timestamp: DateTime.now(),
      );

      expect(adapter.pushCallCount, 1);
      expect(adapter.storageSize, 1);
    });

    test('should push multiple records', () async {
      for (int i = 0; i < 5; i++) {
        await adapter.push(
          collection: 'todos',
          recordId: 'todo-$i',
          data: {'text': 'Task $i'},
          timestamp: DateTime.now(),
        );
      }

      expect(adapter.pushCallCount, 5);
      expect(adapter.storageSize, 5);
    });

    test('should handle complex data structures', () async {
      final complexData = {
        'string': 'value',
        'number': 42,
        'boolean': true,
        'nested': {
          'array': [1, 2, 3],
          'object': {'key': 'value'},
        },
      };

      await adapter.push(
        collection: 'complex',
        recordId: 'complex-1',
        data: complexData,
        timestamp: DateTime.now(),
      );

      expect(adapter.storageSize, 1);
    });

    test('should handle empty data', () async {
      await adapter.push(
        collection: 'empty',
        recordId: 'empty-1',
        data: {},
        timestamp: DateTime.now(),
      );

      expect(adapter.storageSize, 1);
    });
  });

  group('MockAdapter - Pull Operations', () {
    test('should pull all records from collection', () async {
      // Push some data
      await adapter.push(
        collection: 'todos',
        recordId: 'todo-1',
        data: {'text': 'Task 1'},
        timestamp: DateTime.now(),
      );
      await adapter.push(
        collection: 'todos',
        recordId: 'todo-2',
        data: {'text': 'Task 2'},
        timestamp: DateTime.now(),
      );

      final records = await adapter.pull(collection: 'todos');

      expect(records.length, 2);
      expect(adapter.pullCallCount, 1);
    });

    test('should filter by collection name', () async {
      await adapter.push(
        collection: 'todos',
        recordId: 'todo-1',
        data: {'text': 'Task 1'},
        timestamp: DateTime.now(),
      );
      await adapter.push(
        collection: 'users',
        recordId: 'user-1',
        data: {'name': 'John'},
        timestamp: DateTime.now(),
      );

      final todoRecords = await adapter.pull(collection: 'todos');
      final userRecords = await adapter.pull(collection: 'users');

      expect(todoRecords.length, 1);
      expect(userRecords.length, 1);
      expect(todoRecords[0].recordId, 'todo-1');
      expect(userRecords[0].recordId, 'user-1');
    });

    test('should filter by timestamp (since parameter)', () async {
      final now = DateTime.now();
      final past = now.subtract(Duration(hours: 1));
      final future = now.add(Duration(hours: 1));

      await adapter.push(
        collection: 'todos',
        recordId: 'old',
        data: {'text': 'Old task'},
        timestamp: past,
      );
      await adapter.push(
        collection: 'todos',
        recordId: 'new',
        data: {'text': 'New task'},
        timestamp: future,
      );

      final recentRecords = await adapter.pull(
        collection: 'todos',
        since: now,
      );

      expect(recentRecords.length, 1);
      expect(recentRecords[0].recordId, 'new');
    });

    test('should return empty list for non-existent collection', () async {
      final records = await adapter.pull(collection: 'nonexistent');
      expect(records, isEmpty);
    });

    test('should return SyncRecord objects with correct structure', () async {
      await adapter.push(
        collection: 'todos',
        recordId: 'todo-1',
        data: {'text': 'Task 1'},
        timestamp: DateTime.now(),
      );

      final records = await adapter.pull(collection: 'todos');
      final record = records[0];

      expect(record, isA<SyncRecord>());
      expect(record.recordId, 'todo-1');
      expect(record.data, {'text': 'Task 1'});
      expect(record.updatedAt, isA<DateTime>());
      expect(record.version, 1);
    });
  });

  group('MockAdapter - Delete Operations', () {
    test('should delete record successfully', () async {
      await adapter.push(
        collection: 'todos',
        recordId: 'todo-1',
        data: {'text': 'Task 1'},
        timestamp: DateTime.now(),
      );

      expect(adapter.storageSize, 1);

      await adapter.delete(collection: 'todos', recordId: 'todo-1');

      expect(adapter.storageSize, 0);
      expect(adapter.deleteCallCount, 1);
    });

    test('should only delete specified record', () async {
      await adapter.push(
        collection: 'todos',
        recordId: 'todo-1',
        data: {'text': 'Task 1'},
        timestamp: DateTime.now(),
      );
      await adapter.push(
        collection: 'todos',
        recordId: 'todo-2',
        data: {'text': 'Task 2'},
        timestamp: DateTime.now(),
      );

      await adapter.delete(collection: 'todos', recordId: 'todo-1');

      expect(adapter.storageSize, 1);

      final records = await adapter.pull(collection: 'todos');
      expect(records.length, 1);
      expect(records[0].recordId, 'todo-2');
    });

    test('should handle deleting non-existent record', () async {
      await adapter.delete(collection: 'todos', recordId: 'nonexistent');
      expect(adapter.deleteCallCount, 1);
      expect(adapter.storageSize, 0);
    });

    test('should only delete from specified collection', () async {
      await adapter.push(
        collection: 'todos',
        recordId: 'todo-1',
        data: {'text': 'Task 1'},
        timestamp: DateTime.now(),
      );
      await adapter.push(
        collection: 'users',
        recordId: 'todo-1', // Same ID, different collection
        data: {'name': 'John'},
        timestamp: DateTime.now(),
      );

      await adapter.delete(collection: 'todos', recordId: 'todo-1');

      expect(adapter.storageSize, 1);

      final userRecords = await adapter.pull(collection: 'users');
      expect(userRecords.length, 1);
    });
  });

  group('MockAdapter - Auth Token Operations', () {
    test('should update auth token', () {
      adapter.updateAuthToken('new-token');

      expect(adapter.updateAuthTokenCallCount, 1);
      expect(adapter.authToken, 'new-token');
    });

    test('should handle multiple token updates', () {
      adapter.updateAuthToken('token-1');
      adapter.updateAuthToken('token-2');
      adapter.updateAuthToken('token-3');

      expect(adapter.updateAuthTokenCallCount, 3);
      expect(adapter.authToken, 'token-3');
    });

    test('should handle empty token', () {
      adapter.updateAuthToken('');
      expect(adapter.authToken, '');
    });
  });

  group('MockAdapter - Integration Scenarios', () {
    test('should handle complete CRUD cycle', () async {
      // Create
      await adapter.push(
        collection: 'todos',
        recordId: 'todo-1',
        data: {'text': 'Task 1', 'done': false},
        timestamp: DateTime.now(),
      );

      // Read
      var records = await adapter.pull(collection: 'todos');
      expect(records.length, 1);
      expect(records[0].data['done'], false);

      // Update
      await adapter.push(
        collection: 'todos',
        recordId: 'todo-1',
        data: {'text': 'Task 1', 'done': true},
        timestamp: DateTime.now(),
      );

      records = await adapter.pull(collection: 'todos');
      expect(records.length, 2); // Mock doesn't dedupe, just adds

      // Delete
      await adapter.delete(collection: 'todos', recordId: 'todo-1');

      records = await adapter.pull(collection: 'todos');
      expect(records, isEmpty);
    });

    test('should handle concurrent operations', () async {
      final futures = <Future>[];

      for (int i = 0; i < 10; i++) {
        futures.add(adapter.push(
          collection: 'todos',
          recordId: 'todo-$i',
          data: {'text': 'Task $i'},
          timestamp: DateTime.now(),
        ));
      }

      await Future.wait(futures);

      expect(adapter.pushCallCount, 10);
      expect(adapter.storageSize, 10);
    });

    test('should maintain data integrity across operations', () async {
      final testData = {
        'string': 'test',
        'number': 42,
        'boolean': true,
        'nested': {'key': 'value'},
      };

      await adapter.push(
        collection: 'test',
        recordId: 'test-1',
        data: testData,
        timestamp: DateTime.now(),
      );

      final records = await adapter.pull(collection: 'test');
      final retrievedData = records[0].data;

      expect(retrievedData['string'], testData['string']);
      expect(retrievedData['number'], testData['number']);
      expect(retrievedData['boolean'], testData['boolean']);
      expect(retrievedData['nested'], testData['nested']);
    });
  });
}
