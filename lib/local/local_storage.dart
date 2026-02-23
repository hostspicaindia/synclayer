import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'local_models.dart';
import '../security/encryption_service.dart';

/// Local storage abstraction over Isar database
class LocalStorage {
  late Isar _isar;
  bool _isInitialized = false;
  final EncryptionService? encryptionService;

  LocalStorage({this.encryptionService});

  /// Initialize Isar database
  Future<void> init() async {
    if (_isInitialized) return;

    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [SyncOperationSchema, DataRecordSchema],
      directory: dir.path,
      name: 'synclayer_db',
    );

    _isInitialized = true;
  }

  /// Save data to local storage with version increment and hash generation
  Future<void> saveData({
    required String collectionName,
    required String recordId,
    required String data,
  }) async {
    _ensureInitialized();

    // Encrypt data if encryption is enabled
    final dataToStore =
        encryptionService != null ? encryptionService!.encryptData(data) : data;

    await _isar.writeTxn(() async {
      final existing = await _isar.dataRecords
          .filter()
          .collectionNameEqualTo(collectionName)
          .recordIdEqualTo(recordId)
          .findFirst();

      final record = existing ?? DataRecord();
      record.collectionName = collectionName;
      record.recordId = recordId;
      record.data = dataToStore;
      record.updatedAt = DateTime.now();

      if (existing == null) {
        record.createdAt = DateTime.now();
        record.version = 1; // Initial version
      } else {
        // Increment version on update
        record.version += 1;
      }

      // Generate sync hash for change detection (on original data, not encrypted)
      record.syncHash = _generateHash(data);
      record.isSynced = false;

      await _isar.dataRecords.put(record);
    });
  }

  /// Generate SHA-256 hash for data integrity verification
  String _generateHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get data by record ID
  Future<DataRecord?> getData({
    required String collectionName,
    required String recordId,
  }) async {
    _ensureInitialized();

    final record = await _isar.dataRecords
        .filter()
        .collectionNameEqualTo(collectionName)
        .recordIdEqualTo(recordId)
        .isDeletedEqualTo(false)
        .findFirst();

    if (record == null) return null;

    // Decrypt data if encryption is enabled
    if (encryptionService != null) {
      final decryptedData = encryptionService!.decryptData(record.data);
      return DataRecord()
        ..id = record.id
        ..collectionName = record.collectionName
        ..recordId = record.recordId
        ..data = decryptedData
        ..createdAt = record.createdAt
        ..updatedAt = record.updatedAt
        ..version = record.version
        ..syncHash = record.syncHash
        ..isSynced = record.isSynced
        ..isDeleted = record.isDeleted
        ..lastSyncedAt = record.lastSyncedAt;
    }

    return record;
  }

  /// Get all records in a collection
  Future<List<DataRecord>> getAllData(String collectionName) async {
    _ensureInitialized();

    final records = await _isar.dataRecords
        .filter()
        .collectionNameEqualTo(collectionName)
        .isDeletedEqualTo(false)
        .findAll();

    // Decrypt data if encryption is enabled
    if (encryptionService != null) {
      return records.map((record) {
        final decryptedData = encryptionService!.decryptData(record.data);
        return DataRecord()
          ..id = record.id
          ..collectionName = record.collectionName
          ..recordId = record.recordId
          ..data = decryptedData
          ..createdAt = record.createdAt
          ..updatedAt = record.updatedAt
          ..version = record.version
          ..syncHash = record.syncHash
          ..isSynced = record.isSynced
          ..isDeleted = record.isDeleted
          ..lastSyncedAt = record.lastSyncedAt;
      }).toList();
    }

    return records;
  }

  /// Watch collection for changes
  Stream<List<DataRecord>> watchCollection(String collectionName) {
    _ensureInitialized();

    return _isar.dataRecords
        .filter()
        .collectionNameEqualTo(collectionName)
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true);
  }

  /// Delete data (soft delete) with version increment
  Future<void> deleteData({
    required String collectionName,
    required String recordId,
  }) async {
    _ensureInitialized();

    await _isar.writeTxn(() async {
      final record = await _isar.dataRecords
          .filter()
          .collectionNameEqualTo(collectionName)
          .recordIdEqualTo(recordId)
          .findFirst();

      if (record != null) {
        record.isDeleted = true;
        record.updatedAt = DateTime.now();
        record.version += 1; // Increment version on delete
        record.isSynced = false;
        await _isar.dataRecords.put(record);
      }
    });
  }

  /// Add operation to sync queue
  Future<void> addToSyncQueue(SyncOperation operation) async {
    _ensureInitialized();

    await _isar.writeTxn(() async {
      await _isar.syncOperations.put(operation);
    });
  }

  /// Add multiple operations to sync queue in a single transaction
  Future<void> addToSyncQueueBatch(List<SyncOperation> operations) async {
    _ensureInitialized();

    await _isar.writeTxn(() async {
      await _isar.syncOperations.putAll(operations);
    });
  }

  /// Get pending sync operations
  Future<List<SyncOperation>> getPendingSyncOperations() async {
    _ensureInitialized();

    return await _isar.syncOperations
        .filter()
        .statusEqualTo('pending')
        .sortByTimestamp()
        .findAll();
  }

  /// Update sync operation status
  Future<void> updateSyncOperationStatus({
    required int operationId,
    required String status,
    String? errorMessage,
  }) async {
    _ensureInitialized();

    await _isar.writeTxn(() async {
      final operation = await _isar.syncOperations.get(operationId);
      if (operation != null) {
        operation.status = status;
        operation.errorMessage = errorMessage;
        await _isar.syncOperations.put(operation);
      }
    });
  }

  /// Increment retry count for an operation
  Future<void> incrementOperationRetryCount(int operationId) async {
    _ensureInitialized();

    await _isar.writeTxn(() async {
      final operation = await _isar.syncOperations.get(operationId);
      if (operation != null) {
        operation.retryCount += 1;
        await _isar.syncOperations.put(operation);
      }
    });
  }

  /// Reset retry count for an operation
  Future<void> resetOperationRetryCount(int operationId) async {
    _ensureInitialized();

    await _isar.writeTxn(() async {
      final operation = await _isar.syncOperations.get(operationId);
      if (operation != null) {
        operation.retryCount = 0;
        await _isar.syncOperations.put(operation);
      }
    });
  }

  /// Get failed sync operations
  Future<List<SyncOperation>> getFailedSyncOperations() async {
    _ensureInitialized();

    return await _isar.syncOperations
        .filter()
        .statusEqualTo('failed')
        .findAll();
  }

  /// Close database
  Future<void> close() async {
    if (_isInitialized) {
      await _isar.close();
      _isInitialized = false;
    }
  }

  /// Get all unique collection names
  Future<List<String>> getAllCollections() async {
    _ensureInitialized();

    final records = await _isar.dataRecords.where().findAll();
    final collections = records.map((r) => r.collectionName).toSet().toList();
    return collections;
  }

  /// Get last sync time for a collection
  Future<DateTime?> getLastSyncTime(String collectionName) async {
    _ensureInitialized();

    final records = await _isar.dataRecords
        .filter()
        .collectionNameEqualTo(collectionName)
        .sortByLastSyncedAtDesc()
        .findFirst();

    return records?.lastSyncedAt;
  }

  /// Update last sync time for a collection
  Future<void> updateLastSyncTime(
    String collectionName,
    DateTime syncTime,
  ) async {
    _ensureInitialized();

    await _isar.writeTxn(() async {
      final records = await _isar.dataRecords
          .filter()
          .collectionNameEqualTo(collectionName)
          .findAll();

      for (final record in records) {
        record.lastSyncedAt = syncTime;
        await _isar.dataRecords.put(record);
      }
    });
  }

  /// Mark a record as synced with version and timestamp
  Future<void> markAsSynced({
    required String collectionName,
    required String recordId,
    required int version,
    required DateTime syncTime,
  }) async {
    _ensureInitialized();

    await _isar.writeTxn(() async {
      final record = await _isar.dataRecords
          .filter()
          .collectionNameEqualTo(collectionName)
          .recordIdEqualTo(recordId)
          .findFirst();

      if (record != null) {
        record.isSynced = true;
        record.version = version;
        record.lastSyncedAt = syncTime;
        await _isar.dataRecords.put(record);
      }
    });
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('LocalStorage not initialized');
    }
  }
}
