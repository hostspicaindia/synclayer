import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/sync/queue_manager.dart';
import 'package:synclayer/local/local_storage.dart';
import 'package:synclayer/core/sync_event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QueueManager', () {
    late LocalStorage localStorage;
    late QueueManager queueManager;
    final capturedEvents = <SyncEvent>[];

    setUp(() async {
      localStorage = LocalStorage();
      await localStorage.init();
      capturedEvents.clear();

      queueManager = QueueManager(
        localStorage,
        onEvent: (event) => capturedEvents.add(event),
      );
    });

    tearDown(() async {
      await localStorage.close();
    });

    test('should queue insert operation', () async {
      // Arrange
      const collectionName = 'todos';
      const recordId = 'test-1';
      final data = {'text': 'Buy milk', 'done': false};

      // Act
      await queueManager.queueInsert(
        collectionName: collectionName,
        recordId: recordId,
        data: data,
      );

      // Assert
      final pending = await queueManager.getPendingOperations();
      expect(pending, isNotEmpty);
      expect(pending.any((op) => op.recordId == recordId), isTrue);
      expect(pending.first.operationType, equals('insert'));

      // Check event emission
      expect(capturedEvents, isNotEmpty);
      expect(capturedEvents.first.type, equals(SyncEventType.operationQueued));
      expect(capturedEvents.first.collectionName, equals(collectionName));
    });

    test('should queue update operation', () async {
      // Arrange
      const collectionName = 'todos';
      const recordId = 'test-2';
      final data = {'text': 'Buy eggs', 'done': true};

      // Act
      await queueManager.queueUpdate(
        collectionName: collectionName,
        recordId: recordId,
        data: data,
      );

      // Assert
      final pending = await queueManager.getPendingOperations();
      final operation = pending.firstWhere((op) => op.recordId == recordId);
      expect(operation.operationType, equals('update'));
      expect(operation.status, equals('pending'));
    });

    test('should queue delete operation', () async {
      // Arrange
      const collectionName = 'todos';
      const recordId = 'test-3';

      // Act
      await queueManager.queueDelete(
        collectionName: collectionName,
        recordId: recordId,
      );

      // Assert
      final pending = await queueManager.getPendingOperations();
      final operation = pending.firstWhere((op) => op.recordId == recordId);
      expect(operation.operationType, equals('delete'));
      expect(operation.status, equals('pending'));
    });

    test('should mark operation as syncing', () async {
      // Arrange
      await queueManager.queueInsert(
        collectionName: 'todos',
        recordId: 'test-4',
        data: {'text': 'Task'},
      );

      final pending = await queueManager.getPendingOperations();
      final operationId = pending.first.id;

      // Act
      await queueManager.markAsSyncing(operationId);

      // Assert
      final pendingAfter = await queueManager.getPendingOperations();
      expect(
        pendingAfter.any((op) => op.id == operationId),
        isFalse,
      );
    });

    test('should mark operation as synced', () async {
      // Arrange
      await queueManager.queueInsert(
        collectionName: 'todos',
        recordId: 'test-5',
        data: {'text': 'Task'},
      );

      final pending = await queueManager.getPendingOperations();
      final operationId = pending.first.id;

      // Act
      await queueManager.markAsSynced(operationId);

      // Assert
      final pendingAfter = await queueManager.getPendingOperations();
      expect(
        pendingAfter.any((op) => op.id == operationId),
        isFalse,
      );
    });

    test('should mark operation as failed with error message', () async {
      // Arrange
      await queueManager.queueInsert(
        collectionName: 'todos',
        recordId: 'test-6',
        data: {'text': 'Task'},
      );

      final pending = await queueManager.getPendingOperations();
      final operationId = pending.first.id;
      const errorMessage = 'Network error';

      // Act
      await queueManager.markAsFailed(operationId, errorMessage);

      // Assert
      final failed = await localStorage.getFailedSyncOperations();
      final failedOp = failed.firstWhere((op) => op.id == operationId);
      expect(failedOp.status, equals('failed'));
      expect(failedOp.errorMessage, equals(errorMessage));
    });

    test('should increment retry count', () async {
      // Arrange
      await queueManager.queueInsert(
        collectionName: 'todos',
        recordId: 'test-7',
        data: {'text': 'Task'},
      );

      final pending = await queueManager.getPendingOperations();
      final operationId = pending.first.id;

      // Act
      await queueManager.incrementRetryCount(operationId);
      await queueManager.incrementRetryCount(operationId);

      // Assert
      final updated = await queueManager.getPendingOperations();
      final operation = updated.firstWhere((op) => op.id == operationId);
      expect(operation.retryCount, equals(2));
    });

    test('should reset failed operations to pending', () async {
      // Arrange
      await queueManager.queueInsert(
        collectionName: 'todos',
        recordId: 'test-8',
        data: {'text': 'Task'},
      );

      final pending = await queueManager.getPendingOperations();
      final operationId = pending.first.id;

      await queueManager.markAsFailed(operationId, 'Test error');
      await queueManager.incrementRetryCount(operationId);

      // Act
      await queueManager.resetFailedOperations();

      // Assert
      final pendingAfter = await queueManager.getPendingOperations();
      final operation = pendingAfter.firstWhere((op) => op.id == operationId);
      expect(operation.status, equals('pending'));
      expect(operation.retryCount, equals(0));
    });

    test('should emit events for all queue operations', () async {
      // Arrange
      capturedEvents.clear();

      // Act
      await queueManager.queueInsert(
        collectionName: 'todos',
        recordId: 'test-9',
        data: {'text': 'Task 1'},
      );

      await queueManager.queueUpdate(
        collectionName: 'todos',
        recordId: 'test-10',
        data: {'text': 'Task 2'},
      );

      await queueManager.queueDelete(
        collectionName: 'todos',
        recordId: 'test-11',
      );

      // Assert
      expect(capturedEvents.length, equals(3));
      expect(
        capturedEvents.every(
          (e) => e.type == SyncEventType.operationQueued,
        ),
        isTrue,
      );
    });

    test('should handle multiple operations for same record', () async {
      // Arrange
      const collectionName = 'todos';
      const recordId = 'test-12';

      // Act - Queue insert then update
      await queueManager.queueInsert(
        collectionName: collectionName,
        recordId: recordId,
        data: {'text': 'Original'},
      );

      await queueManager.queueUpdate(
        collectionName: collectionName,
        recordId: recordId,
        data: {'text': 'Updated'},
      );

      // Assert
      final pending = await queueManager.getPendingOperations();
      final operations = pending.where((op) => op.recordId == recordId);
      expect(operations.length, equals(2));
    });
  });
}
