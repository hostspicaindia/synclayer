// ignore_for_file: avoid_print

import 'package:synclayer/synclayer.dart';

/// Example demonstrating the Query & Filtering API
///
/// This example shows how to use the new query capabilities to filter,
/// sort, and paginate data in SyncLayer.
void main() async {
  // Initialize SyncLayer
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['todos'],
    ),
  );

  final todos = SyncLayer.collection('todos');

  // ========================================
  // 1. BASIC FILTERING
  // ========================================

  print('\n=== Basic Filtering ===');

  // Get only incomplete todos
  final incompleteTodos = await todos.where('done', isEqualTo: false).get();
  print('Incomplete todos: ${incompleteTodos.length}');

  // Get high priority todos
  final highPriorityTodos =
      await todos.where('priority', isGreaterThan: 5).get();
  print('High priority todos: ${highPriorityTodos.length}');

  // ========================================
  // 2. MULTIPLE CONDITIONS
  // ========================================

  print('\n=== Multiple Conditions ===');

  // Get incomplete high priority todos
  final urgentTodos = await todos
      .where('done', isEqualTo: false)
      .where('priority', isGreaterThan: 5)
      .get();
  print('Urgent todos: ${urgentTodos.length}');

  // ========================================
  // 3. STRING OPERATIONS
  // ========================================

  print('\n=== String Operations ===');

  // Search todos by text
  final searchResults = await todos.where('text', contains: 'buy').get();
  print('Todos containing "buy": ${searchResults.length}');

  // Find todos starting with specific text
  final startsWithResults = await todos.where('text', startsWith: 'Call').get();
  print('Todos starting with "Call": ${startsWithResults.length}');

  // ========================================
  // 4. SORTING
  // ========================================

  print('\n=== Sorting ===');

  // Sort by priority (highest first)
  final sortedByPriority =
      await todos.orderBy('priority', descending: true).get();
  print('Sorted by priority:');
  for (final todo in sortedByPriority.take(3)) {
    print('  - ${todo['text']} (priority: ${todo['priority']})');
  }

  // Sort by multiple fields
  final multiSort = await todos
      .orderBy('done') // Incomplete first
      .orderBy('priority', descending: true) // Then by priority
      .orderBy('createdAt') // Then by creation date
      .get();
  print('\nMulti-field sort: ${multiSort.length} todos');

  // ========================================
  // 5. PAGINATION
  // ========================================

  print('\n=== Pagination ===');

  // Get first page (10 items)
  final page1 = await todos.limit(10).get();
  print('Page 1: ${page1.length} todos');

  // Get second page (skip 10, take 10)
  final page2 = await todos.offset(10).limit(10).get();
  print('Page 2: ${page2.length} todos');

  // ========================================
  // 6. COMBINED QUERY
  // ========================================

  print('\n=== Combined Query ===');

  // Complex query: incomplete, high priority, sorted, paginated
  final complexQuery = await todos
      .where('done', isEqualTo: false)
      .where('priority', isGreaterThanOrEqualTo: 5)
      .where('userId', isEqualTo: 'user123')
      .orderBy('priority', descending: true)
      .orderBy('createdAt')
      .limit(20)
      .get();
  print('Complex query results: ${complexQuery.length} todos');

  // ========================================
  // 7. ARRAY OPERATIONS
  // ========================================

  print('\n=== Array Operations ===');

  // Find todos with specific tag
  final workTodos = await todos.where('tags', arrayContains: 'work').get();
  print('Work todos: ${workTodos.length}');

  // Find todos with any of multiple tags
  final taggedTodos = await todos
      .where('tags', arrayContainsAny: ['urgent', 'important']).get();
  print('Urgent or important todos: ${taggedTodos.length}');

  // ========================================
  // 8. NULL CHECKS
  // ========================================

  print('\n=== Null Checks ===');

  // Find todos without due date
  final noDueDate = await todos.where('dueDate', isNull: true).get();
  print('Todos without due date: ${noDueDate.length}');

  // Find todos with due date
  final withDueDate = await todos.where('dueDate', isNull: false).get();
  print('Todos with due date: ${withDueDate.length}');

  // ========================================
  // 9. REACTIVE QUERIES (WATCH)
  // ========================================

  print('\n=== Reactive Queries ===');

  // Watch incomplete todos (updates automatically)
  final subscription = todos.where('done', isEqualTo: false).watch().listen(
    (incompleteTodos) {
      print('Incomplete todos updated: ${incompleteTodos.length}');
      for (final todo in incompleteTodos.take(3)) {
        print('  - ${todo['text']}');
      }
    },
  );

  // Simulate some changes
  await Future.delayed(Duration(seconds: 1));
  await todos.save({'text': 'New todo', 'done': false, 'priority': 8});

  await Future.delayed(Duration(seconds: 1));
  subscription.cancel();

  // ========================================
  // 10. UTILITY METHODS
  // ========================================

  print('\n=== Utility Methods ===');

  // Get first result
  final firstTodo = await todos
      .where('done', isEqualTo: false)
      .orderBy('priority', descending: true)
      .first();
  if (firstTodo != null) {
    print('Highest priority incomplete todo: ${firstTodo['text']}');
  }

  // Count results
  final count = await todos.where('done', isEqualTo: true).count();
  print('Completed todos count: $count');

  // ========================================
  // 11. NESTED FIELD QUERIES
  // ========================================

  print('\n=== Nested Field Queries ===');

  // Query nested fields using dot notation
  final userTodos = await todos.where('user.name', isEqualTo: 'John').get();
  print('John\'s todos: ${userTodos.length}');

  final highScoreTodos =
      await todos.where('metadata.score', isGreaterThan: 80).get();
  print('High score todos: ${highScoreTodos.length}');

  // ========================================
  // 12. WHEREININ / WHERENOTIN
  // ========================================

  print('\n=== WhereIn / WhereNotIn ===');

  // Find todos with specific statuses
  final activeTodos = await todos
      .where('status', whereIn: ['active', 'pending', 'in-progress']).get();
  print('Active todos: ${activeTodos.length}');

  // Find todos excluding certain statuses
  final nonDeletedTodos =
      await todos.where('status', whereNotIn: ['deleted', 'archived']).get();
  print('Non-deleted todos: ${nonDeletedTodos.length}');

  // Clean up
  await SyncLayer.dispose();
  print('\n=== Example Complete ===');
}
