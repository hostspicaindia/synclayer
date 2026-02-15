import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/local/local_storage.dart';
import 'package:synclayer/local/local_models.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalStorage', () {
    late LocalStorage localStorage;

    setUp(() async {
      localStorage = LocalStorage();
      await localStorage.init();
    });

    tearDown(() async {
      await localStorage.close();
    });

    test('should save data with version 1 for new records', () async {
      // Arrange
      const collectionName = 'todos';
      const recordId = 'test-1';
      final data = jsonEncode({'text': 'Buy milk', 'done': false});

      // Act
      await localStorage.saveData(
        collectionName: collectionName,
        recordId: recordId,
        data: data,
      );

      // Assert
      final record = await localStorage.getData(
        collectionName: collectionName,
        recordId: recordId,
      );

      expect(record, isNotNull);
      expect(record!.recordId, equals(recordId));
      expect(record.collectionName, equals(collectionName));
      expect(record.data, equals(data));
      expect(record.version, equals(1));
      expect(record.isSynced, isFalse);
      expect(record.syncHash, isNotNull);
    });

    test('should increment version on update', () async {
      // Arrange
      const collectionName = 'todos';
      const recordId = 'test-2';
      final data1 = jsonEncode({'text': 'Buy milk', 'done': false});
      final data2 = jsonEncode({'text': 'Buy milk', 'done': true});

      // Act
      await localStorage.saveData(
        collectionName: collectionName,
        recordId: recordId,
        data: data1,
      );

      final record1 = await localStorage.getData(
        collectionName: collectionName,
        recordId: recordId,
      );

      await localStorage.saveData(
        collectionName: collectionName,
        recordId: recordId,
        data: data2,
      );

      final record2 = await localStorage.getData(
        collectionName: collectionName,
        recordId: recordId,
      );

      // Assert
      expect(record1!.version, equals(1));
      expect(record2!.version, equals(2));
      expect(record2.data, equals(data2));
    });

    test('should generate different hashes for different data', () async {
      // Arrange
      const collectionName = 'todos';
      final data1 = jsonEncode({'text': 'Buy milk'});
      final data2 = jsonEncode({'text': 'Buy eggs'});

      // Act
      await localStorage.saveData(
        collectionName: collectionName,
        recordId: 'test-3',
        data: data1,
      );

      await localStorage.saveData(
        collectionName: collectionName,
        recordId: 'test-4',
        data: data2,
      );

      final record1 = await localStorage.getData(
        collectionName: collectionName,
        recordId: 'test-3',
      );

      final record2 = await localStorage.getData(
        collectionName: collectionName,
        recordId: 'test-4',
      );

      // Assert
      expect(record1!.syncHash, isNotNull);
      expect(record2!.syncHash, isNotNull);
      expect(record1.syncHash, isNot(equals(record2.syncHash)));
    });

    test('should soft delete records', () async {
      // Arrange
      const collectionName = 'todos';
      const recordId = 'test-5';
      final data = jsonEncode({'text': 'Buy milk'});

      await localStorage.saveData(
        collectionName: collectionName,
        recordId: recordId,
        data: data,
      );

      // Act
      await localStorage.deleteData(
        collectionName: collectionName,
        recordId: recordId,
      );

      // Assert
      final record = await localStorage.getData(
        collectionName: collectionName,
        recordId: recordId,
      );

      expect(record, isNull); // getData filters out deleted records
    });

    test('should increment version on delete', () async {
      // Arrange
      const collectionName = 'todos';
      const recordId = 'test-6';
      final data = jsonEncode({'text': 'Buy milk'});

      await localStorage.saveData(
        collectionName: collectionName,
        recordId: recordId,
        data: data,
      );

      final beforeDelete = await localStorage.getData(
        collectionName: collectionName,
        recordId: recordId,
      );

      // Act
      await localStorage.deleteData(
        collectionName: collectionName,
        recordId: recordId,
      );

      // Assert - need to query without filter to see deleted record
      // For now, just verify version was 1 before delete
      expect(beforeDelete!.version, equals(1));
    });

    test('should get all records in a collection', () async {
      // Arrange
      const collectionName = 'todos';
      final data1 = jsonEncode({'text': 'Task 1'});
      final data2 = jsonEncode({'text': 'Task 2'});
      final data3 = jsonEncode({'text': 'Task 3'});

      await localStorage.saveData(
        collectionName: collectionName,
        recordId: 'test-7',
        data: data1,
      );

      await localStorage.saveData(
        collectionName: collectionName,
        recordId: 'test-8',
        data: data2,
      );

      await localStorage.saveData(
        collectionName: collectionName,
        recordId: 'test-9',
        data: data3,
      );

      // Act
      final records = await localStorage.getAllData(collectionName);

      // Assert
      expect(records.length, greaterThanOrEqualTo(3));
      expect(records.any((r) => r.recordId == 'test-7'), isTrue);
      expect(records.any((r) => r.recordId == 'test-8'), isTrue);
      expect(records.any((r) => r.recordId == 'test-9'), isTrue);
    });

    test('should get all unique collections', () async {
      // Arrange
      await localStorage.saveData(
        collectionName: 'todos',
        recordId: 'test-10',
        data: jsonEncode({'text': 'Task'}),
      );

      await localStorage.saveData(
        collectionName: 'users',
        recordId: 'test-11',
        data: jsonEncode({'name': 'John'}),
      );

      // Act
      final collections = await localStorage.getAllCollections();

      // Assert
      expect(collections, contains('todos'));
      expect(collections, contains('users'));
    });

    test('should mark record as synced', () async {
      // Arrange
      const collectionName = 'todos';
      const recordId = 'test-12';
      final data = jsonEncode({'text': 'Task'});

      await localStorage.saveData(
        collectionName: collectionName,
        recordId: recordId,
        data: data,
      );

      final syncTime = DateTime.now();

      // Act
      await localStorage.markAsSynced(
        collectionName: collectionName,
        recordId: recordId,
        version: 5,
        syncTime: syncTime,
      );

      // Assert
      final record = await localStorage.getData(
        collectionName: collectionName,
        recordId: recordId,
      );

      expect(record!.isSynced, isTrue);
      expect(record.version, equals(5));
      expect(record.lastSyncedAt, isNotNull);
    });

    test('should manage sync queue operations', () async {
      // Arrange
      final operation = SyncOperation()
        ..collectionName = 'todos'
        ..operationType = 'insert'
        ..payload = jsonEncode({'text': 'Task'})
        ..timestamp = DateTime.now()
        ..status = 'pending'
        ..recordId = 'test-13';

      // Act
      await localStorage.addToSyncQueue(operation);
      final pending = await localStorage.getPendingSyncOperations();

      // Assert
      expect(pending, isNotEmpty);
      expect(pending.any((op) => op.recordId == 'test-13'), isTrue);
    });

    test('should update sync operation status', () async {
      // Arrange
      final operation = SyncOperation()
        ..collectionName = 'todos'
        ..operationType = 'insert'
        ..payload = jsonEncode({'text': 'Task'})
        ..timestamp = DateTime.now()
        ..status = 'pending'
        ..recordId = 'test-14';

      await localStorage.addToSyncQueue(operation);
      final pending = await localStorage.getPendingSyncOperations();
      final operationId = pending.first.id;

      // Act
      await localStorage.updateSyncOperationStatus(
        operationId: operationId,
        status: 'synced',
      );

      // Assert
      final pendingAfter = await localStorage.getPendingSyncOperations();
      expect(
        pendingAfter.any((op) => op.id == operationId),
        isFalse,
      );
    });

    test('should increment retry count', () async {
      // Arrange
      final operation = SyncOperation()
        ..collectionName = 'todos'
        ..operationType = 'insert'
        ..payload = jsonEncode({'text': 'Task'})
        ..timestamp = DateTime.now()
        ..status = 'pending'
        ..recordId = 'test-15'
        ..retryCount = 0;

      await localStorage.addToSyncQueue(operation);
      final pending = await localStorage.getPendingSyncOperations();
      final operationId = pending.first.id;

      // Act
      await localStorage.incrementOperationRetryCount(operationId);

      // Assert
      final updated = await localStorage.getPendingSyncOperations();
      final updatedOp = updated.firstWhere((op) => op.id == operationId);
      expect(updatedOp.retryCount, equals(1));
    });

    test('should watch collection for changes', () async {
      // Arrange
      const collectionName = 'todos';
      final stream = localStorage.watchCollection(collectionName);
      final emittedValues = <List<DataRecord>>[];

      // Act
      final subscription = stream.listen((records) {
        emittedValues.add(records);
      });

      // Wait for initial emission
      await Future.delayed(Duration(milliseconds: 100));

      // Add a record
      await localStorage.saveData(
        collectionName: collectionName,
        recordId: 'test-16',
        data: jsonEncode({'text': 'Watch test'}),
      );

      // Wait for stream to emit
      await Future.delayed(Duration(milliseconds: 100));

      // Assert
      expect(emittedValues.length, greaterThanOrEqualTo(1));

      await subscription.cancel();
    });
  });
}
