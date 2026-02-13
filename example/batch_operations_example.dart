import 'package:synclayer/synclayer.dart';

/// Example demonstrating batch operations in SyncLayer
void main() async {
  // Initialize SyncLayer
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      authToken: 'your-auth-token',
      syncInterval: Duration(minutes: 5),
    ),
  );

  // Example 1: Batch Save
  print('Example 1: Batch Save Multiple Documents');
  final messages = [
    {
      'text': 'Hello World',
      'userId': '123',
      'timestamp': DateTime.now().toIso8601String(),
    },
    {
      'text': 'How are you?',
      'userId': '123',
      'timestamp': DateTime.now().toIso8601String(),
    },
    {
      'text': 'Good morning!',
      'userId': '456',
      'timestamp': DateTime.now().toIso8601String(),
    },
  ];

  final ids = await SyncLayer.collection('messages').saveAll(messages);
  print('Saved ${ids.length} messages with IDs: $ids');

  // Example 2: Retrieve All
  print('\nExample 2: Retrieve All Messages');
  final allMessages = await SyncLayer.collection('messages').getAll();
  print('Total messages: ${allMessages.length}');
  for (final message in allMessages) {
    print('- ${message['text']} (from user ${message['userId']})');
  }

  // Example 3: Watch for Changes
  print('\nExample 3: Watch Collection for Changes');
  final subscription = SyncLayer.collection('messages').watch().listen(
    (messages) {
      print('Messages updated! Count: ${messages.length}');
    },
  );

  // Add a new message to trigger watch
  await SyncLayer.collection('messages').save({
    'text': 'New message!',
    'userId': '789',
    'timestamp': DateTime.now().toIso8601String(),
  });

  await Future.delayed(Duration(seconds: 1));

  // Example 4: Batch Delete
  print('\nExample 4: Batch Delete Multiple Documents');
  await SyncLayer.collection('messages').deleteAll(ids);
  print('Deleted ${ids.length} messages');

  // Verify deletion
  final remainingMessages = await SyncLayer.collection('messages').getAll();
  print('Remaining messages: ${remainingMessages.length}');

  // Example 5: Manual Sync
  print('\nExample 5: Manual Sync Trigger');
  await SyncLayer.syncNow();
  print('Sync completed!');

  // Example 6: Monitor Sync Events
  print('\nExample 6: Monitor Sync Events');
  final eventSubscription = SyncLayerCore.instance.syncEngine.events.listen(
    (event) {
      print('Sync Event: ${event.type}');
      if (event.collectionName != null) {
        print('  Collection: ${event.collectionName}');
      }
      if (event.recordId != null) {
        print('  Record ID: ${event.recordId}');
      }
      if (event.error != null) {
        print('  Error: ${event.error}');
      }
    },
  );

  // Trigger sync to see events
  await SyncLayer.collection('messages').save({
    'text': 'Event test message',
    'userId': '999',
  });
  await SyncLayer.syncNow();

  await Future.delayed(Duration(seconds: 2));

  // Cleanup
  await subscription.cancel();
  await eventSubscription.cancel();
  await SyncLayer.dispose();

  print('\nExample completed!');
}
