import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';

/// Mock backend adapter for testing
class MockBackendAdapter implements SyncBackendAdapter {
  final List<Map<String, dynamic>> pushedData = [];
  final List<String> deletedRecords = [];
  final Map<String, List<SyncRecord>> mockRemoteData = {};

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
  }) async {
    return mockRemoteData[collection] ?? [];
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    deletedRecords.add('$collection:$recordId');
  }

  @override
  void updateAuthToken(String token) {
    // Mock implementation
  }

  void addMockRemoteData(String collection, SyncRecord record) {
    mockRemoteData.putIfAbsent(collection, () => []).add(record);
  }
}

void main() {
  group('Sync Flow Integration Tests', () {
    late MockBackendAdapter mockBackend;

    setUp(() async {
      mockBackend = MockBackendAdapter();

      await SyncLayer.init(
        SyncConfig(
          baseUrl: 'https://test.example.com',
          enableAutoSync: false,
          customBackendAdapter: mockBackend,
        ),
      );
    });

    tearDown(() async {
      await SyncLayer.dispose();
    });

    test('should save data locally and sync to backend', () async {
      final id = await SyncLayer.collection('messages').save({
        'text': 'Hello World',
        'timestamp': DateTime.now().toIso8601String(),
      });

      expect(id, isNotEmpty);

      // Retrieve locally
      final retrieved = await SyncLayer.collection('messages').get(id);
      expect(retrieved, isNotNull);
      expect(retrieved!['text'], equals('Hello World'));

      // Trigger sync
      await SyncLayer.syncNow();

      // Verify backend received data
      await Future.delayed(Duration(milliseconds: 500));
      expect(mockBackend.pushedData.length, greaterThanOrEqualTo(1));

      final pushed = mockBackend.pushedData.firstWhere(
        (item) => item['recordId'] == id,
      );
      expect(pushed['data']['text'], equals('Hello World'));
    });

    test('should handle batch operations', () async {
      final documents = [
        {'name': 'Item 1', 'value': 1},
        {'name': 'Item 2', 'value': 2},
        {'name': 'Item 3', 'value': 3},
      ];

      final ids = await SyncLayer.collection('items').saveAll(documents);

      expect(ids.length, equals(3));

      final allItems = await SyncLayer.collection('items').getAll();
      expect(allItems.length, greaterThanOrEqualTo(3));
    });

    test('should handle delete operations', () async {
      final id = await SyncLayer.collection('messages').save({
        'text': 'To be deleted',
      });

      await SyncLayer.collection('messages').delete(id);

      final retrieved = await SyncLayer.collection('messages').get(id);
      expect(retrieved, isNull);

      // Trigger sync
      await SyncLayer.syncNow();

      await Future.delayed(Duration(milliseconds: 500));
      expect(
        mockBackend.deletedRecords,
        contains('messages:$id'),
      );
    });

    test('should pull remote data and merge locally', () async {
      // Add mock remote data
      mockBackend.addMockRemoteData(
        'messages',
        SyncRecord(
          recordId: 'remote_1',
          data: {'text': 'Remote message', 'source': 'server'},
          updatedAt: DateTime.now(),
          version: 1,
        ),
      );

      // Trigger sync (includes pull)
      await SyncLayer.syncNow();

      await Future.delayed(Duration(milliseconds: 500));

      // Verify remote data is now local
      final retrieved = await SyncLayer.collection('messages').get('remote_1');
      expect(retrieved, isNotNull);
      expect(retrieved!['text'], equals('Remote message'));
    });

    test('should handle conflict resolution', () async {
      // Save local data
      await SyncLayer.collection('messages').save(
        {'text': 'Local version', 'value': 1},
        id: 'conflict_record',
      );

      // Add conflicting remote data
      mockBackend.addMockRemoteData(
        'messages',
        SyncRecord(
          recordId: 'conflict_record',
          data: {'text': 'Remote version', 'value': 2},
          updatedAt: DateTime.now().add(Duration(seconds: 10)),
          version: 2,
        ),
      );

      // Trigger sync
      await SyncLayer.syncNow();

      await Future.delayed(Duration(milliseconds: 500));

      // With lastWriteWins, remote should win (newer timestamp)
      final resolved =
          await SyncLayer.collection('messages').get('conflict_record');
      expect(resolved, isNotNull);
      expect(resolved!['text'], equals('Remote version'));
    });

    test('should emit sync events', () async {
      final events = <SyncEvent>[];
      final subscription = SyncLayerCore.instance.syncEngine.events.listen(
        (event) => events.add(event),
      );

      await SyncLayer.collection('messages').save({'text': 'Test'});
      await SyncLayer.syncNow();

      await Future.delayed(Duration(milliseconds: 500));

      expect(events.any((e) => e.type == SyncEventType.syncStarted), isTrue);
      expect(events.any((e) => e.type == SyncEventType.syncCompleted), isTrue);

      await subscription.cancel();
    });
  });
}
