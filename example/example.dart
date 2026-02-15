// ignore_for_file: unused_local_variable

import 'package:synclayer/synclayer.dart';

/// Example demonstrating basic SyncLayer usage
void main() async {
  // Initialize SyncLayer
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      syncInterval: const Duration(minutes: 5),
      collections: ['todos', 'users'],
      conflictStrategy: ConflictStrategy.lastWriteWins,
    ),
  );

  // Get a collection reference
  final todos = SyncLayer.collection('todos');

  // Save a document
  final id = await todos.save({
    'text': 'Buy groceries',
    'completed': false,
    'priority': 'high',
  });
  print('Created todo with ID: $id');

  // Get a document
  final todo = await todos.get(id);
  print('Retrieved todo: $todo');

  // Update a document
  await todos.save(
    {
      'text': 'Buy groceries',
      'completed': true,
      'priority': 'high',
    },
    id: id,
  );
  print('Updated todo');

  // Get all documents
  final allTodos = await todos.getAll();
  print('Total todos: ${allTodos.length}');

  // Watch for changes (in a real app, use in a StreamBuilder)
  final subscription = todos.watch().listen((updatedTodos) {
    print('Todos changed: ${updatedTodos.length} items');
  });

  // Batch operations
  final ids = await todos.saveAll([
    {'text': 'Task 1', 'completed': false},
    {'text': 'Task 2', 'completed': false},
    {'text': 'Task 3', 'completed': false},
  ]);
  print('Created ${ids.length} todos');

  // Manual sync
  await SyncLayer.syncNow();
  print('Sync completed');

  // Delete a document
  await todos.delete(id);
  print('Deleted todo');

  // Delete multiple documents
  await todos.deleteAll(ids);
  print('Deleted ${ids.length} todos');

  // Clean up
  await subscription.cancel();
  await SyncLayer.dispose();
  print('SyncLayer disposed');
}
