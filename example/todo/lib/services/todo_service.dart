import 'package:synclayer/synclayer.dart';
import '../models/todo.dart';

class TodoService {
  final CollectionReference _collection = SyncLayer.collection('todos');

  // Watch all todos (real-time stream)
  Stream<List<Todo>> watchTodos() {
    return _collection.watch().map((docs) {
      final todos = <Todo>[];

      for (var doc in docs) {
        // SyncLayer watch() returns documents with their IDs
        // The ID should be in the 'id' field that we set when saving
        final id = doc['id'] as String?;

        if (id == null || id.isEmpty) {
          print('⚠️ Skipping document without ID: $doc');
          continue;
        }

        todos.add(Todo.fromMap(id, doc));
      }

      // Sort by createdAt descending
      todos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return todos;
    });
  }

  // Add todo (works offline)
  Future<String> addTodo(String text) async {
    final id = await _collection.save({
      'text': text,
      'done': false,
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Save again with the ID included in the data
    // This ensures the ID is available in watch()
    await _collection.save({
      'id': id,
      'text': text,
      'done': false,
      'createdAt': DateTime.now().toIso8601String(),
    }, id: id);

    return id;
  }

  // Update todo (works offline)
  Future<void> updateTodo(Todo todo) async {
    await _collection.save({
      'id': todo.id, // Include ID in the data
      'text': todo.text,
      'done': todo.done,
      'createdAt': todo.createdAt.toIso8601String(),
    }, id: todo.id);
  }

  // Delete todo (works offline)
  Future<void> deleteTodo(String id) async {
    if (id.isEmpty) {
      print('❌ Cannot delete todo with empty ID');
      return;
    }
    await _collection.delete(id);
  }

  // Toggle done status
  Future<void> toggleTodo(Todo todo) async {
    await updateTodo(todo.copyWith(done: !todo.done));
  }
}
