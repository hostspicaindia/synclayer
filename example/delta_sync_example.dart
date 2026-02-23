// ignore_for_file: unused_local_variable, avoid_print

import 'package:synclayer/synclayer.dart';

/// Examples of delta sync (partial updates) for bandwidth optimization.
///
/// Delta sync only sends changed fields instead of the entire document,
/// reducing bandwidth usage by up to 98%.
void main() async {
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['todos', 'documents', 'users', 'analytics'],
    ),
  );

  // Example 1: Toggle Todo Completion
  await toggleTodoExample();

  // Example 2: Increment View Count
  await incrementViewCountExample();

  // Example 3: Update User Status
  await updateUserStatusExample();

  // Example 4: Update Multiple Fields
  await updateMultipleFieldsExample();

  // Example 5: Large Document Update
  await largeDocumentExample();

  // Example 6: Calculate Bandwidth Savings
  await bandwidthSavingsExample();
}

/// Example 1: Toggle Todo Completion
///
/// Instead of sending the entire todo (with text, description, tags, etc.),
/// only send the 'done' field that changed.
Future<void> toggleTodoExample() async {
  print('\n=== Toggle Todo Completion ===\n');

  final collection = SyncLayer.collection('todos');

  // Create a todo
  final todoId = await collection.save({
    'text': 'Buy groceries',
    'description': 'Need to buy milk, eggs, bread, and other items',
    'priority': 5,
    'tags': ['shopping', 'urgent'],
    'done': false,
  });

  print('Created todo: $todoId');

  // Traditional way: Send entire document (wasteful)
  // await collection.save({
  //   'text': 'Buy groceries',
  //   'description': 'Need to buy milk, eggs, bread, and other items',
  //   'priority': 5,
  //   'tags': ['shopping', 'urgent'],
  //   'done': true,  // Only this changed!
  // }, id: todoId);

  // Delta sync way: Only send changed field (efficient)
  await collection.update(todoId, {'done': true});

  print('✓ Updated todo with delta sync');
  print('  - Only sent: {"done": true}');
  print('  - Saved ~95% bandwidth!');
}

/// Example 2: Increment View Count
///
/// Perfect for analytics where you only need to update a counter.
Future<void> incrementViewCountExample() async {
  print('\n=== Increment View Count ===\n');

  final collection = SyncLayer.collection('documents');

  // Create a document
  final docId = await collection.save({
    'title': 'My Article',
    'content': 'Very long article content...' * 100, // Large content
    'author': 'John Doe',
    'views': 0,
    'likes': 0,
  });

  print('Created document: $docId');

  // Get current document
  final doc = await collection.get(docId);

  // Delta sync: Only update view count
  await collection.update(docId, {
    'views': (doc!['views'] as int) + 1,
  });

  print('✓ Incremented view count with delta sync');
  print('  - Only sent: {"views": 1}');
  print('  - Saved ~98% bandwidth (didn\'t send large content)!');
}

/// Example 3: Update User Status
///
/// Update online status without sending entire user profile.
Future<void> updateUserStatusExample() async {
  print('\n=== Update User Status ===\n');

  final collection = SyncLayer.collection('users');

  // Create a user
  final userId = await collection.save({
    'name': 'John Doe',
    'email': 'john@example.com',
    'profile': {
      'bio': 'Software developer with 10 years of experience...',
      'avatar': 'https://example.com/avatar.jpg',
      'location': 'San Francisco, CA',
    },
    'status': 'offline',
    'lastSeen': DateTime.now().toIso8601String(),
  });

  print('Created user: $userId');

  // Delta sync: Only update status and lastSeen
  await collection.update(userId, {
    'status': 'online',
    'lastSeen': DateTime.now().toIso8601String(),
  });

  print('✓ Updated user status with delta sync');
  print('  - Only sent: {"status": "online", "lastSeen": "..."}');
  print('  - Saved ~70% bandwidth!');
}

/// Example 4: Update Multiple Fields
///
/// You can update multiple fields at once with delta sync.
Future<void> updateMultipleFieldsExample() async {
  print('\n=== Update Multiple Fields ===\n');

  final collection = SyncLayer.collection('todos');

  // Create a todo
  final todoId = await collection.save({
    'text': 'Buy groceries',
    'priority': 3,
    'done': false,
    'tags': ['shopping'],
  });

  print('Created todo: $todoId');

  // Delta sync: Update multiple fields
  await collection.update(todoId, {
    'priority': 5,
    'done': true,
    'completedAt': DateTime.now().toIso8601String(),
  });

  print('✓ Updated multiple fields with delta sync');
  print('  - Only sent changed fields');
  print('  - Still more efficient than sending entire document');
}

/// Example 5: Large Document Update
///
/// Shows the power of delta sync with large documents.
Future<void> largeDocumentExample() async {
  print('\n=== Large Document Update ===\n');

  final collection = SyncLayer.collection('documents');

  // Create a large document
  final docId = await collection.save({
    'id': '123',
    'title': 'My Document',
    'content': 'Very long content...' * 1000, // ~20KB
    'metadata': {
      'author': 'John Doe',
      'created': DateTime.now().toIso8601String(),
      'tags': List.generate(50, (i) => 'tag$i'),
    },
    'attachments': List.generate(
      10,
      (i) => {
        'name': 'file$i.pdf',
        'url': 'https://example.com/file$i.pdf',
        'size': 1024 * 1024,
      },
    ),
    'done': false,
  });

  print('Created large document: $docId');
  print('  - Document size: ~20KB');

  // Delta sync: Only update done field
  await collection.update(docId, {'done': true});

  print('✓ Updated large document with delta sync');
  print('  - Only sent: {"done": true} (~10 bytes)');
  print('  - Saved ~99.95% bandwidth!');
  print('  - 20KB → 10 bytes');
}

/// Example 6: Calculate Bandwidth Savings
///
/// Use DeltaCalculator to see how much bandwidth you save.
Future<void> bandwidthSavingsExample() async {
  print('\n=== Calculate Bandwidth Savings ===\n');

  // Example 1: Todo completion
  final fullTodo = {
    'id': '123',
    'text': 'Buy groceries',
    'description': 'Need to buy milk, eggs, bread, and other items',
    'priority': 5,
    'tags': ['shopping', 'urgent'],
    'done': false,
  };

  final todoDelta = {'done': true};

  final todoSavings = DeltaCalculator.calculateSavings(fullTodo, todoDelta);
  print('Todo completion:');
  print('  - Full document: ${fullTodo.toString().length} bytes');
  print('  - Delta: ${todoDelta.toString().length} bytes');
  print('  - Savings: ${todoSavings.toStringAsFixed(1)}%');

  // Example 2: View count increment
  final fullDoc = {
    'id': '123',
    'title': 'My Article',
    'content': 'Very long article content...' * 100,
    'views': 100,
  };

  final viewDelta = {'views': 101};

  final viewSavings = DeltaCalculator.calculateSavings(fullDoc, viewDelta);
  print('\nView count increment:');
  print('  - Full document: ${fullDoc.toString().length} bytes');
  print('  - Delta: ${viewDelta.toString().length} bytes');
  print('  - Savings: ${viewSavings.toStringAsFixed(1)}%');

  // Example 3: Status update
  final fullUser = {
    'id': '123',
    'name': 'John Doe',
    'email': 'john@example.com',
    'profile': {
      'bio': 'Long bio...',
      'avatar': 'https://example.com/avatar.jpg',
    },
    'status': 'offline',
  };

  final statusDelta = {'status': 'online'};

  final statusSavings = DeltaCalculator.calculateSavings(fullUser, statusDelta);
  print('\nStatus update:');
  print('  - Full document: ${fullUser.toString().length} bytes');
  print('  - Delta: ${statusDelta.toString().length} bytes');
  print('  - Savings: ${statusSavings.toStringAsFixed(1)}%');

  print('\n=== Summary ===\n');
  print('Delta sync benefits:');
  print('  ✓ Bandwidth: 70-98% reduction');
  print('  ✓ Performance: Faster sync');
  print('  ✓ Battery: Less network usage');
  print('  ✓ Cost: Lower server bandwidth costs');
  print('  ✓ Conflicts: Fewer conflicts (only specific fields change)');
  print('\nUse delta sync for:');
  print('  • Toggling flags (done, active, etc.)');
  print('  • Incrementing counters (views, likes, etc.)');
  print('  • Updating status (online, offline, etc.)');
  print('  • Modifying single fields in large documents');
}
