import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';

/// Mock backend adapter for testing
class MockBackendAdapter implements SyncBackendAdapter {
  final List<Map<String, dynamic>> pushedData = [];
  final List<Map<String, dynamic>> deletedData = [];
  final Map<String, List<SyncRecord>> remoteData = {};

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

    // Simulate backend storing the data
    remoteData[collection] ??= [];
    remoteData[collection]!.add(SyncRecord(
      recordId: recordId,
      data: data,
      updatedAt: timestamp,
      version: 1,
    ));
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
    int? limit,
    int? offset,
    SyncFilter? filter,
  }) async {
    final records = remoteData[collection] ?? [];

    var filtered = since == null
        ? records
        : records.where((r) => r.updatedAt.isAfter(since)).toList();

    if (offset != null && offset > 0) {
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
  }) async {
    deletedData.add({
      'collection': collection,
      'recordId': recordId,
    });

    // Remove from remote data
    remoteData[collection]?.removeWhere((r) => r.recordId == recordId);
  }

  @override
  void updateAuthToken(String token) {
    // Mock implementation
  }

  void reset() {
    pushedData.clear();
    deletedData.clear();
    remoteData.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sync Flow Integration Tests', () {
    late MockBackendAdapter mockBackend;

    setUp(() async {
      mockBackend = MockBackendAdapter();

      await SyncLayer.init(
        SyncConfig(
          customBackendAdapter: mockBackend,
          enableAutoSync: false, // Disable auto-sync for controlled testing
          collections: ['todos'],
        ),
      );
    });

    tearDown(() async {
      await SyncLayer.dispose();
      mockBackend.reset();
    });

    test('should save data locally and sync to backend', () async {
      // Arrange
      final data = {'text': 'Buy milk', 'done': false};

      // Act
      final id = await SyncLayer.collection('todos').save(data);
      await SyncLayer.syncNow();

      // Assert - Check local storage
      final localData = await SyncLayer.collection('todos').get(id);
      expect(localData, isNotNull);
      expect(localData!['text'], equals('Buy milk'));

      // Assert - Check backend received data
      expect(mockBackend.pushedData, isNotEmpty);
      expect(mockBackend.pushedData.first['recordId'], equals(id));
      expect(mockBackend.pushedData.first['data']['text'], equals('Buy milk'));
    });

    test('should handle batch save operations', () async {
      // Arrange
      final documents = [
        {'text': 'Task 1', 'done': false},
        {'text': 'Task 2', 'done': false},
        {'text': 'Task 3', 'done': false},
      ];

      // Act
      final ids = await SyncLayer.collection('todos').saveAll(documents);
      await SyncLayer.syncNow();

      // Assert
      expect(ids.length, equals(3));
      expect(mockBackend.pushedData.length, equals(3));

      for (var i = 0; i < ids.length; i++) {
        final localData = await SyncLayer.collection('todos').get(ids[i]);
        expect(localData, isNotNull);
        expect(localData!['text'], equals('Task ${i + 1}'));
      }
    });

    test('should handle delete operations', () async {
      // Arrange
      final data = {'text': 'To be deleted', 'done': false};
      final id = await SyncLayer.collection('todos').save(data);
      await SyncLayer.syncNow();

      mockBackend.pushedData.clear();

      // Act
      await SyncLayer.collection('todos').delete(id);
      await SyncLayer.syncNow();

      // Assert - Check local storage
      final localData = await SyncLayer.collection('todos').get(id);
      expect(localData, isNull);

      // Assert - Check backend received delete
      expect(mockBackend.deletedData, isNotEmpty);
      expect(mockBackend.deletedData.first['recordId'], equals(id));
    });

    test('should pull remote data and merge locally', () async {
      // Arrange - Add data directly to mock backend
      final remoteRecord = SyncRecord(
        recordId: 'remote-1',
        data: {'text': 'Remote task', 'done': false},
        updatedAt: DateTime.now(),
        version: 1,
      );

      mockBackend.remoteData['todos'] = [remoteRecord];

      // Act
      await SyncLayer.syncNow();

      // Assert - Check local storage has remote data
      final localData = await SyncLayer.collection('todos').get('remote-1');
      expect(localData, isNotNull);
      expect(localData!['text'], equals('Remote task'));
    });

    test('should handle conflict resolution', () async {
      // Arrange - Create local data
      final localData = {'text': 'Local version', 'done': false};
      final id = await SyncLayer.collection('todos').save(localData);
      await SyncLayer.syncNow();

      // Simulate remote change
      final remoteRecord = SyncRecord(
        recordId: id,
        data: {'text': 'Remote version', 'done': true},
        updatedAt: DateTime.now().add(Duration(seconds: 5)),
        version: 2,
      );

      mockBackend.remoteData['todos'] = [remoteRecord];

      // Act
      await SyncLayer.syncNow();

      // Assert - Should have remote version (last-write-wins)
      final resolvedData = await SyncLayer.collection('todos').get(id);
      expect(resolvedData, isNotNull);
      expect(resolvedData!['text'], equals('Remote version'));
      expect(resolvedData['done'], equals(true));
    });

    test('should emit sync events', () async {
      // Arrange
      final events = <SyncEvent>[];
      final subscription = SyncLayerCore.instance.syncEngine.events.listen(
        (event) => events.add(event),
      );

      final data = {'text': 'Event test', 'done': false};

      // Act
      await SyncLayer.collection('todos').save(data);
      await SyncLayer.syncNow();

      // Wait for events to be processed
      await Future.delayed(Duration(milliseconds: 100));

      // Assert
      expect(events, isNotEmpty);
      expect(
        events.any((e) => e.type == SyncEventType.syncStarted),
        isTrue,
      );
      expect(
        events.any((e) => e.type == SyncEventType.operationQueued),
        isTrue,
      );

      await subscription.cancel();
    });

    test('should handle batch delete operations', () async {
      // Arrange
      final documents = [
        {'text': 'Task 1'},
        {'text': 'Task 2'},
        {'text': 'Task 3'},
      ];

      final ids = await SyncLayer.collection('todos').saveAll(documents);
      await SyncLayer.syncNow();

      mockBackend.deletedData.clear();

      // Act
      await SyncLayer.collection('todos').deleteAll(ids);
      await SyncLayer.syncNow();

      // Assert
      expect(mockBackend.deletedData.length, equals(3));

      for (final id in ids) {
        final localData = await SyncLayer.collection('todos').get(id);
        expect(localData, isNull);
      }
    });

    test('should watch collection for real-time updates', () async {
      // Arrange
      final emittedValues = <List<Map<String, dynamic>>>[];
      final stream = SyncLayer.collection('todos').watch();

      final subscription = stream.listen((todos) {
        emittedValues.add(todos);
      });

      // Wait for initial emission
      await Future.delayed(Duration(milliseconds: 100));

      // Act
      await SyncLayer.collection('todos').save({'text': 'Watch test 1'});
      await Future.delayed(Duration(milliseconds: 100));

      await SyncLayer.collection('todos').save({'text': 'Watch test 2'});
      await Future.delayed(Duration(milliseconds: 100));

      // Assert
      expect(emittedValues.length, greaterThanOrEqualTo(2));

      await subscription.cancel();
    });

    test('should handle update operations', () async {
      // Arrange
      final initialData = {'text': 'Original', 'done': false};
      final id = await SyncLayer.collection('todos').save(initialData);
      await SyncLayer.syncNow();

      mockBackend.pushedData.clear();

      // Act
      final updatedData = {'text': 'Updated', 'done': true};
      await SyncLayer.collection('todos').save(updatedData, id: id);
      await SyncLayer.syncNow();

      // Assert
      final localData = await SyncLayer.collection('todos').get(id);
      expect(localData!['text'], equals('Updated'));
      expect(localData['done'], equals(true));

      expect(mockBackend.pushedData, isNotEmpty);
      expect(mockBackend.pushedData.first['data']['text'], equals('Updated'));
    });
  });
}
