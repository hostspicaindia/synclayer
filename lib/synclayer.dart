library synclayer;

export 'core/synclayer_init.dart';
export 'core/sync_event.dart';
export 'network/sync_backend_adapter.dart';
export 'conflict/conflict_resolver.dart';

import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'core/synclayer_init.dart';

/// Main entry point for SyncLayer SDK
class SyncLayer {
  /// Initialize SyncLayer
  static Future<void> init(SyncConfig config) async {
    await SyncLayerCore.init(config);
  }

  /// Get a collection reference
  static CollectionReference collection(String name) {
    return CollectionReference._(name);
  }

  /// Dispose SyncLayer resources
  static Future<void> dispose() async {
    await SyncLayerCore.dispose();
  }

  /// Trigger manual sync
  static Future<void> syncNow() async {
    await SyncLayerCore.instance.syncEngine.syncNow();
  }
}

/// Reference to a collection for CRUD operations
class CollectionReference {
  final String _name;
  static const _uuid = Uuid();

  CollectionReference._(this._name);

  /// Save data to collection (insert or update)
  Future<String> save(Map<String, dynamic> data, {String? id}) async {
    final core = SyncLayerCore.instance;
    final recordId = id ?? _uuid.v4();

    // Save locally first
    await core.localStorage.saveData(
      collectionName: _name,
      recordId: recordId,
      data: jsonEncode(data),
    );

    // Queue for sync - access queue manager through sync engine
    final queueManager = core.syncEngine.queueManager;
    final existing = await core.localStorage.getData(
      collectionName: _name,
      recordId: recordId,
    );

    if (existing != null && existing.createdAt != existing.updatedAt) {
      await queueManager.queueUpdate(
        collectionName: _name,
        recordId: recordId,
        data: data,
      );
    } else {
      await queueManager.queueInsert(
        collectionName: _name,
        recordId: recordId,
        data: data,
      );
    }

    return recordId;
  }

  /// Get data by ID
  Future<Map<String, dynamic>?> get(String id) async {
    final core = SyncLayerCore.instance;
    final record = await core.localStorage.getData(
      collectionName: _name,
      recordId: id,
    );

    if (record == null) return null;
    return jsonDecode(record.data) as Map<String, dynamic>;
  }

  /// Get all documents in collection
  Future<List<Map<String, dynamic>>> getAll() async {
    final core = SyncLayerCore.instance;
    final records = await core.localStorage.getAllData(_name);

    return records
        .map((r) => jsonDecode(r.data) as Map<String, dynamic>)
        .toList();
  }

  /// Delete document by ID
  Future<void> delete(String id) async {
    final core = SyncLayerCore.instance;

    await core.localStorage.deleteData(
      collectionName: _name,
      recordId: id,
    );

    await core.syncEngine.queueManager.queueDelete(
      collectionName: _name,
      recordId: id,
    );
  }

  /// Watch collection for changes
  Stream<List<Map<String, dynamic>>> watch() {
    final core = SyncLayerCore.instance;

    return core.localStorage.watchCollection(_name).map((records) {
      return records
          .map((r) => jsonDecode(r.data) as Map<String, dynamic>)
          .toList();
    });
  }

  /// Batch save multiple documents
  Future<List<String>> saveAll(List<Map<String, dynamic>> documents) async {
    final core = SyncLayerCore.instance;
    final ids = <String>[];

    for (final data in documents) {
      final id = data['id'] as String? ?? _uuid.v4();
      ids.add(id);

      await core.localStorage.saveData(
        collectionName: _name,
        recordId: id,
        data: jsonEncode(data),
      );

      final queueManager = core.syncEngine.queueManager;
      await queueManager.queueInsert(
        collectionName: _name,
        recordId: id,
        data: data,
      );
    }

    return ids;
  }

  /// Batch delete multiple documents
  Future<void> deleteAll(List<String> ids) async {
    final core = SyncLayerCore.instance;

    for (final id in ids) {
      await core.localStorage.deleteData(
        collectionName: _name,
        recordId: id,
      );

      await core.syncEngine.queueManager.queueDelete(
        collectionName: _name,
        recordId: id,
      );
    }
  }
}
