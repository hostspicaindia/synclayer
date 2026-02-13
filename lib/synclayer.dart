library synclayer;

export 'core/synclayer_init.dart';
export 'core/sync_event.dart';
export 'network/sync_backend_adapter.dart';
export 'conflict/conflict_resolver.dart';

import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'core/synclayer_init.dart';

/// Main entry point for SyncLayer SDK.
///
/// SyncLayer provides a local-first synchronization engine for Flutter apps
/// with automatic offline support and conflict resolution.
///
/// Example:
/// ```dart
/// // Initialize
/// await SyncLayer.init(
///   SyncConfig(
///     baseUrl: 'https://api.example.com',
///     syncInterval: Duration(minutes: 5),
///     collections: ['todos', 'users'],
///   ),
/// );
///
/// // Save data
/// final id = await SyncLayer.collection('todos').save({
///   'text': 'Buy groceries',
///   'completed': false,
/// });
///
/// // Get data
/// final todo = await SyncLayer.collection('todos').get(id);
///
/// // Watch for changes
/// SyncLayer.collection('todos').watch().listen((todos) {
///   print('Todos updated: ${todos.length}');
/// });
/// ```
class SyncLayer {
  /// Initializes SyncLayer with the provided configuration.
  ///
  /// This must be called before using any other SyncLayer methods.
  /// It sets up local storage, network adapters, and starts auto-sync
  /// if enabled in the config.
  ///
  /// Parameters:
  /// - [config]: Configuration for SyncLayer including backend URL,
  ///   sync interval, collections to sync, and other options.
  ///
  /// Throws:
  /// - [StateError] if SyncLayer is already initialized.
  ///
  /// Example:
  /// ```dart
  /// await SyncLayer.init(
  ///   SyncConfig(
  ///     baseUrl: 'https://api.example.com',
  ///     authToken: 'your-token',
  ///     syncInterval: Duration(minutes: 5),
  ///     enableAutoSync: true,
  ///     collections: ['todos', 'users'],
  ///     maxRetries: 3,
  ///     conflictStrategy: ConflictStrategy.lastWriteWins,
  ///   ),
  /// );
  /// ```
  static Future<void> init(SyncConfig config) async {
    await SyncLayerCore.init(config);
  }

  /// Returns a reference to a collection for performing CRUD operations.
  ///
  /// Collections are logical groupings of documents, similar to tables
  /// in a database or collections in MongoDB.
  ///
  /// Parameters:
  /// - [name]: The name of the collection.
  ///
  /// Returns:
  /// A [CollectionReference] that can be used to save, get, delete,
  /// and watch documents in the collection.
  ///
  /// Example:
  /// ```dart
  /// final todos = SyncLayer.collection('todos');
  /// await todos.save({'text': 'Buy milk'});
  /// ```
  static CollectionReference collection(String name) {
    return CollectionReference._(name);
  }

  /// Disposes SyncLayer and releases all resources.
  ///
  /// This stops auto-sync, closes database connections, and cleans up
  /// all resources. Call this when your app is shutting down.
  ///
  /// After calling dispose, you must call [init] again before using
  /// SyncLayer.
  ///
  /// Example:
  /// ```dart
  /// await SyncLayer.dispose();
  /// ```
  static Future<void> dispose() async {
    await SyncLayerCore.dispose();
  }

  /// Triggers an immediate synchronization with the backend.
  ///
  /// This bypasses the automatic sync interval and forces a sync
  /// to happen right now. Useful for "pull to refresh" functionality
  /// or when you want to ensure data is synced immediately.
  ///
  /// The sync will:
  /// 1. Push all pending local changes to the backend
  /// 2. Pull all remote changes from the backend
  /// 3. Resolve any conflicts using the configured strategy
  ///
  /// Example:
  /// ```dart
  /// // User pulls to refresh
  /// await SyncLayer.syncNow();
  /// ```
  static Future<void> syncNow() async {
    await SyncLayerCore.instance.syncEngine.syncNow();
  }
}

/// Reference to a collection for performing CRUD operations.
///
/// A collection is a logical grouping of documents. All documents in a
/// collection share the same sync behavior and conflict resolution strategy.
///
/// Operations on a collection are local-first: writes happen instantly to
/// local storage and are queued for background synchronization.
///
/// Example:
/// ```dart
/// final todos = SyncLayer.collection('todos');
///
/// // Save
/// final id = await todos.save({'text': 'Buy milk', 'done': false});
///
/// // Get
/// final todo = await todos.get(id);
///
/// // Update (same as save with existing id)
/// await todos.save({'text': 'Buy milk', 'done': true}, id: id);
///
/// // Delete
/// await todos.delete(id);
///
/// // Watch for changes
/// todos.watch().listen((allTodos) {
///   print('Collection updated: ${allTodos.length} items');
/// });
/// ```
class CollectionReference {
  final String _name;
  static const _uuid = Uuid();

  CollectionReference._(this._name);

  /// Saves a document to the collection (insert or update).
  ///
  /// If [id] is provided and a document with that ID exists, it will be
  /// updated. Otherwise, a new document is created with a generated UUID.
  ///
  /// The operation is local-first: data is saved to local storage immediately
  /// and queued for background sync with the backend.
  ///
  /// Parameters:
  /// - [data]: The document data as a Map. Can contain any JSON-serializable values.
  /// - [id]: Optional document ID. If not provided, a UUID will be generated.
  ///
  /// Returns:
  /// The document ID (either provided or generated).
  ///
  /// Example:
  /// ```dart
  /// // Insert new document
  /// final id = await collection.save({
  ///   'text': 'Buy groceries',
  ///   'completed': false,
  ///   'createdAt': DateTime.now().toIso8601String(),
  /// });
  ///
  /// // Update existing document
  /// await collection.save({
  ///   'text': 'Buy groceries',
  ///   'completed': true,
  /// }, id: id);
  /// ```
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

  /// Retrieves a document by its ID.
  ///
  /// Returns the document data if found, or null if no document exists
  /// with the given ID.
  ///
  /// Parameters:
  /// - [id]: The document ID to retrieve.
  ///
  /// Returns:
  /// The document data as a Map, or null if not found.
  ///
  /// Example:
  /// ```dart
  /// final todo = await collection.get('abc-123');
  /// if (todo != null) {
  ///   print('Todo: ${todo['text']}');
  /// } else {
  ///   print('Todo not found');
  /// }
  /// ```
  Future<Map<String, dynamic>?> get(String id) async {
    final core = SyncLayerCore.instance;
    final record = await core.localStorage.getData(
      collectionName: _name,
      recordId: id,
    );

    if (record == null) return null;
    return jsonDecode(record.data) as Map<String, dynamic>;
  }

  /// Retrieves all documents in the collection.
  ///
  /// Returns a list of all non-deleted documents in the collection.
  /// The list is loaded from local storage and does not trigger a sync.
  ///
  /// Returns:
  /// A list of document data Maps. Empty list if collection is empty.
  ///
  /// Example:
  /// ```dart
  /// final allTodos = await collection.getAll();
  /// print('Total todos: ${allTodos.length}');
  ///
  /// for (final todo in allTodos) {
  ///   print('- ${todo['text']}');
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> getAll() async {
    final core = SyncLayerCore.instance;
    final records = await core.localStorage.getAllData(_name);

    return records
        .map((r) => jsonDecode(r.data) as Map<String, dynamic>)
        .toList();
  }

  /// Deletes a document by its ID.
  ///
  /// The document is soft-deleted locally (marked as deleted) and the
  /// deletion is queued for sync with the backend.
  ///
  /// Parameters:
  /// - [id]: The document ID to delete.
  ///
  /// Example:
  /// ```dart
  /// await collection.delete('abc-123');
  /// ```
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

  /// Returns a stream that emits the collection's documents whenever they change.
  ///
  /// The stream emits immediately with the current state, then emits again
  /// whenever documents are added, updated, or deleted in the collection.
  ///
  /// This is useful for building reactive UIs that automatically update
  /// when data changes.
  ///
  /// Returns:
  /// A Stream that emits a list of all documents in the collection.
  ///
  /// Example:
  /// ```dart
  /// // In a StatefulWidget
  /// StreamBuilder<List<Map<String, dynamic>>>(
  ///   stream: SyncLayer.collection('todos').watch(),
  ///   builder: (context, snapshot) {
  ///     if (!snapshot.hasData) return CircularProgressIndicator();
  ///
  ///     final todos = snapshot.data!;
  ///     return ListView.builder(
  ///       itemCount: todos.length,
  ///       itemBuilder: (context, index) {
  ///         final todo = todos[index];
  ///         return ListTile(title: Text(todo['text']));
  ///       },
  ///     );
  ///   },
  /// );
  /// ```
  Stream<List<Map<String, dynamic>>> watch() {
    final core = SyncLayerCore.instance;

    return core.localStorage.watchCollection(_name).map((records) {
      return records
          .map((r) => jsonDecode(r.data) as Map<String, dynamic>)
          .toList();
    });
  }

  /// Saves multiple documents in a single batch operation.
  ///
  /// This is more efficient than calling [save] multiple times as it
  /// reduces the number of database transactions and sync operations.
  ///
  /// Each document can optionally include an 'id' field. If not provided,
  /// a UUID will be generated for each document.
  ///
  /// Parameters:
  /// - [documents]: List of document data Maps to save.
  ///
  /// Returns:
  /// A list of document IDs in the same order as the input documents.
  ///
  /// Example:
  /// ```dart
  /// final ids = await collection.saveAll([
  ///   {'text': 'Buy milk', 'done': false},
  ///   {'text': 'Buy eggs', 'done': false},
  ///   {'text': 'Buy bread', 'done': false},
  /// ]);
  ///
  /// print('Saved ${ids.length} documents');
  /// ```
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

  /// Deletes multiple documents in a single batch operation.
  ///
  /// This is more efficient than calling [delete] multiple times as it
  /// reduces the number of database transactions and sync operations.
  ///
  /// Parameters:
  /// - [ids]: List of document IDs to delete.
  ///
  /// Example:
  /// ```dart
  /// // Delete all completed todos
  /// final allTodos = await collection.getAll();
  /// final completedIds = allTodos
  ///     .where((todo) => todo['completed'] == true)
  ///     .map((todo) => todo['id'] as String)
  ///     .toList();
  ///
  /// await collection.deleteAll(completedIds);
  /// ```
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
