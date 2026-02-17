import 'package:isar/isar.dart';

part 'local_models.g.dart';

/// Represents a sync operation in the queue
@collection
class SyncOperation {
  Id id = Isar.autoIncrement;

  @Index()
  late String collectionName;

  late String operationType; // 'insert', 'update', 'delete'

  late String payload; // JSON string

  late DateTime timestamp;

  @Index()
  late String status; // 'pending', 'syncing', 'synced', 'failed'

  int retryCount = 0;

  String? errorMessage;

  String? recordId; // Optional: ID of the record being synced
}

/// Generic data record for collections
@collection
class DataRecord {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('recordId')])
  late String collectionName;

  @Index()
  late String recordId; // User-defined ID

  late String data; // JSON string

  late DateTime createdAt;

  late DateTime updatedAt;

  @Index()
  bool isSynced = false;

  @Index()
  bool isDeleted = false;

  // Sync metadata for conflict resolution
  int version = 1; // Version vector for conflict detection

  DateTime? lastSyncedAt; // Last successful sync timestamp

  String? syncHash; // Hash for change detection
}
