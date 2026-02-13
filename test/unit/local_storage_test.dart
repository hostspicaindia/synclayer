import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/local/local_storage.dart';

void main() {
  group('LocalStorage', () {
    late LocalStorage localStorage;

    setUp(() async {
      localStorage = LocalStorage();
      await localStorage.init();
    });

    tearDown(() async {
      await localStorage.close();
    });

    test('should save and retrieve data', () async {
      const collectionName = 'test_collection';
      const recordId = 'test_record_1';
      const data = '{"name": "Test", "value": 123}';

      await localStorage.saveData(
        collectionName: collectionName,
        recordId: recordId,
        data: data,
      );

      final retrieved = await localStorage.getData(
        collectionName: collectionName,
        recordId: recordId,
      );

      expect(retrieved, isNotNull);
      expect(retrieved!.recordId, equals(recordId));
      expect(retrieved.data, equals(data));
      expect(retrieved.isDeleted, isFalse);
    });

    test('should update existing data', () async {
      const collectionName = 'test_collection';
      const recordId = 'test_record_2';
      const initialData = '{"value": 1}';
      const updatedData = '{"value": 2}';

      await localStorage.saveData(
        collectionName: collectionName,
        recordId: recordId,
        data: initialData,
      );

      await localStorage.saveData(
        collectionName: collectionName,
        recordId: recordId,
        data: updatedData,
      );

      final retrieved = await localStorage.getData(
        collectionName: collectionName,
        recordId: recordId,
      );

      expect(retrieved!.data, equals(updatedData));
    });

    test('should soft delete data', () async {
      const collectionName = 'test_collection';
      const recordId = 'test_record_3';
      const data = '{"name": "To Delete"}';

      await localStorage.saveData(
        collectionName: collectionName,
        recordId: recordId,
        data: data,
      );

      await localStorage.deleteData(
        collectionName: collectionName,
        recordId: recordId,
      );

      final retrieved = await localStorage.getData(
        collectionName: collectionName,
        recordId: recordId,
      );

      expect(retrieved, isNull);
    });

    test('should get all data in collection', () async {
      const collectionName = 'test_collection';

      await localStorage.saveData(
        collectionName: collectionName,
        recordId: 'record_1',
        data: '{"id": 1}',
      );

      await localStorage.saveData(
        collectionName: collectionName,
        recordId: 'record_2',
        data: '{"id": 2}',
      );

      final allData = await localStorage.getAllData(collectionName);

      expect(allData.length, greaterThanOrEqualTo(2));
    });

    test('should get all unique collections', () async {
      await localStorage.saveData(
        collectionName: 'collection_1',
        recordId: 'record_1',
        data: '{}',
      );

      await localStorage.saveData(
        collectionName: 'collection_2',
        recordId: 'record_2',
        data: '{}',
      );

      final collections = await localStorage.getAllCollections();

      expect(collections, contains('collection_1'));
      expect(collections, contains('collection_2'));
    });

    test('should mark record as synced', () async {
      const collectionName = 'test_collection';
      const recordId = 'test_record_4';

      await localStorage.saveData(
        collectionName: collectionName,
        recordId: recordId,
        data: '{}',
      );

      final syncTime = DateTime.now();
      await localStorage.markAsSynced(
        collectionName: collectionName,
        recordId: recordId,
        version: 2,
        syncTime: syncTime,
      );

      final retrieved = await localStorage.getData(
        collectionName: collectionName,
        recordId: recordId,
      );

      expect(retrieved!.isSynced, isTrue);
      expect(retrieved.version, equals(2));
      expect(retrieved.lastSyncedAt, isNotNull);
    });
  });
}
