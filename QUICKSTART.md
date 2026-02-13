# SyncLayer Quick Start Guide

Get started with SyncLayer in 5 minutes.

---

## Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  synclayer: ^0.1.0
```

Run:
```bash
flutter pub get
flutter pub run build_runner build
```

---

## Basic Setup

### 1. Initialize (in main.dart)

```dart
import 'package:flutter/material.dart';
import 'package:synclayer/synclayer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      authToken: 'your-auth-token',
    ),
  );

  runApp(MyApp());
}
```

### 2. Save Data

```dart
// Data is saved locally instantly, synced in background
final id = await SyncLayer.collection('messages').save({
  'text': 'Hello World',
  'userId': '123',
  'timestamp': DateTime.now().toIso8601String(),
});

print('Saved with ID: $id');
```

### 3. Read Data

```dart
// Get single document
final message = await SyncLayer.collection('messages').get(id);
print(message?['text']);

// Get all documents
final allMessages = await SyncLayer.collection('messages').getAll();
print('Total messages: ${allMessages.length}');
```

### 4. Watch for Changes (Reactive)

```dart
StreamBuilder<List<Map<String, dynamic>>>(
  stream: SyncLayer.collection('messages').watch(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return CircularProgressIndicator();
    }

    final messages = snapshot.data!;
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(messages[index]['text']),
        );
      },
    );
  },
)
```

### 5. Delete Data

```dart
await SyncLayer.collection('messages').delete(id);
```

---

## Advanced Features

### Custom Backend Adapter

```dart
class FirebaseBackendAdapter implements SyncBackendAdapter {
  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(recordId)
        .set(data);
  }

  // Implement other methods...
}

// Use it
await SyncLayer.init(
  SyncConfig(
    baseUrl: '', // Not needed for Firebase
    customBackendAdapter: FirebaseBackendAdapter(),
  ),
);
```

### Monitor Sync Events

```dart
SyncLayer.syncEngine.events.listen((event) {
  switch (event.type) {
    case SyncEventType.syncStarted:
      print('Sync started');
    case SyncEventType.operationSynced:
      print('Synced: ${event.recordId}');
    case SyncEventType.syncFailed:
      print('Sync failed: ${event.error}');
  }
});
```

### Manual Sync Trigger

```dart
ElevatedButton(
  onPressed: () async {
    await SyncLayer.syncNow();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sync triggered')),
    );
  },
  child: Text('Sync Now'),
)
```

### Custom Conflict Strategy

```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    conflictStrategy: ConflictStrategy.serverWins, // or clientWins
  ),
);
```

---

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:synclayer/synclayer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      authToken: 'your-token',
      syncInterval: Duration(minutes: 5),
    ),
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todos'),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () => SyncLayer.syncNow(),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SyncLayer.collection('todos').watch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final todos = snapshot.data!;

          return ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return ListTile(
                title: Text(todo['title']),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    SyncLayer.collection('todos').delete(todo['id']);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Todo'),
        content: TextField(
          controller: _controller,
          decoration: InputDecoration(hintText: 'Enter todo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_controller.text.isNotEmpty) {
                await SyncLayer.collection('todos').save({
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'title': _controller.text,
                  'createdAt': DateTime.now().toIso8601String(),
                });
                _controller.clear();
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

## Backend Requirements

Your backend should implement these endpoints:

### POST /sync/{collection}
```json
{
  "recordId": "doc-123",
  "data": {
    "title": "Hello",
    "createdAt": "2026-02-13T10:00:00Z"
  },
  "timestamp": "2026-02-13T10:00:00Z"
}
```

### GET /sync/{collection}?since={timestamp}
```json
{
  "records": [
    {
      "recordId": "doc-123",
      "data": {...},
      "updatedAt": "2026-02-13T10:00:00Z",
      "version": 1
    }
  ]
}
```

### DELETE /sync/{collection}/{recordId}
Returns 200 OK

---

## Configuration Options

```dart
SyncConfig(
  baseUrl: 'https://api.example.com',     // Required
  authToken: 'token',                      // Optional
  syncInterval: Duration(minutes: 5),      // Default: 5 min
  maxRetries: 3,                           // Default: 3
  enableAutoSync: true,                    // Default: true
  conflictStrategy: ConflictStrategy.lastWriteWins, // Default
  customBackendAdapter: MyAdapter(),       // Optional
)
```

---

## Troubleshooting

### "SyncLayer not initialized"
Make sure you call `SyncLayer.init()` before using any other methods.

### Data not syncing
Check:
1. Internet connectivity
2. Backend API is running
3. Auth token is valid
4. Check sync events for errors

### Build errors
Run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Next Steps

- Read [API.md](API.md) for detailed API documentation
- Read [ARCHITECTURE.md](ARCHITECTURE.md) for architecture details
- Check [example/main.dart](example/main.dart) for complete example
- Join our community for support

---

## Support

- GitHub Issues: [Report bugs](https://github.com/hostspica/synclayer/issues)
- Documentation: [Full docs](https://docs.synclayer.dev)
- Email: support@hostspica.com

---

**Happy coding! 🚀**
