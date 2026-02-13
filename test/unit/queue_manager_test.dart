import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/local/local_storage.dart';
import 'package:synclayer/sync/queue_manager.dart';

void main() {
  group('QueueManager', () {
    late LocalStorage localStorage;
    late QueueManager queueManager;

    setUp(() async {
      localStorage = LocalStorage();
      await localStorage.init();
      queueManager = QueueManager(localStorage);
    });

    tearDown(() async {
      await localStorage.close();
    });

    test('should queue insert operation', () async {
      await queueManager.queueInsert(
        collectionName: 'test_collection',
        recordId: 'record_1',
        data: {'name': 'Test'},
      );

      final pending = await queueManager.getPendingOperations();
      expect(pending.length, greaterThanOrEqualTo(1));

      final operation = pending.firstWhere(
        (op) => op.recordId == 'record_1',
      );
      expect(operation.operationType, equals('insert'));
      expect(operation.status, equals('pending'));
    });

    test('should queue update operation', () async {
      await queueManager.queueUpdate(
        collectionName: 'test_collection',
        recordId: 'record_2',
        data: {'name': 'Updated'},
      );

      final pending = await queueManager.getPendingOperations();
      final operation = pending.firstWhere(
        (op) => op.recordId == 'record_2',
      );

      expect(operation.operationType, equals('update'));
    });

    test('should queue delete operation', () async {
      await queueManager.queueDelete(
        collectionName: 'test_collection',
        recordId: 'record_3',
      );

      final pending = await queueManager.getPendingOperations();
      final operation = pending.firstWhere(
        (op) => op.recordId == 'record_3',
      );

      expect(operation.operationType, equals('delete'));
    });

    test('should mark operation as syncing', () async {
      await queueManager.queueInsert(
        collectionName: 'test_collection',
        recordId: 'record_4',
        data: {},
      );

      final pending = await queueManager.getPendingOperations();
      final operation = pending.firstWhere(
        (op) => op.recordId == 'record_4',
      );

      await queueManager.markAsSyncing(operation.id);

      final updated = await localStorage.getPendingSyncOperations();
      final syncingOp = updated.firstWhere(
        (op) => op.id == operation.id,
        orElse: () => operation,
      );

      expect(syncingOp.status, equals('syncing'));
    });

    test('should mark operation as synced', () async {
      await queueManager.queueInsert(
        collectionName: 'test_collection',
        recordId: 'record_5',
        data: {},
      );

      final pending = await queueManager.getPendingOperations();
      final operation = pending.firstWhere(
        (op) => op.recordId == 'record_5',
      );

      await queueManager.markAsSynced(operation.id);

      final allOps = await localStorage.getPendingSyncOperations();
      final syncedExists = allOps.any((op) => op.id == operation.id);

      expect(syncedExists, isFalse);
    });

    test('should increment retry count', () async {
      await queueManager.queueInsert(
        collectionName: 'test_collection',
        recordId: 'record_6',
        data: {},
      );

      final pending = await queueManager.getPendingOperations();
      final operation = pending.firstWhere(
        (op) => op.recordId == 'record_6',
      );

      await queueManager.incrementRetryCount(operation.id);

      final updated = await queueManager.getPendingOperations();
      final retried = updated.firstWhere((op) => op.id == operation.id);

      expect(retried.retryCount, equals(1));
    });

    test('should mark operation as failed', () async {
      await queueManager.queueInsert(
        collectionName: 'test_collection',
        recordId: 'record_7',
        data: {},
      );

      final pending = await queueManager.getPendingOperations();
      final operation = pending.firstWhere(
        (op) => op.recordId == 'record_7',
      );

      await queueManager.markAsFailed(operation.id, 'Test error');

      final allOps = await localStorage.getPendingSyncOperations();
      final failedOp = allOps.firstWhere(
        (op) => op.id == operation.id,
        orElse: () => operation,
      );

      expect(failedOp.status, equals('failed'));
      expect(failedOp.errorMessage, equals('Test error'));
    });
  });
}
