# SyncLayer API Documentation

## Table of Contents
- [Initialization](#initialization)
- [Configuration](#configuration)
- [Collection Operations](#collection-operations)
- [Sync Management](#sync-management)
- [Data Models](#data-models)

---

## Initialization

### `SyncLayer.init(SyncConfig config)`

Initialize the SyncLayer SDK. Must be called before any other operations.

```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    authToken: 'your-auth-token',
    syncInterval: Duration(minutes: 5),
    maxRetries: 3,
    enableAutoSync: true,
  ),
);
```

**Parameters:**
- `config` (SyncConfig): Configuration object

**Returns:** `Future<void>`

**Throws:** `StateError` if already initialized

---

## Configuration

### `SyncConfig`

Configuration class for SyncLayer initialization.

```dart
class SyncConfig {
  final String baseUrl;           // Required: API base URL
  final String? authToken;        // Optional: Authentication token
  final Duration syncInterval;    // Default: 5 minutes
  final int maxRetries;          // Default: 3
  final bool enableAutoSync;     // Default: true
}
```

**Properties:**

- `baseUrl` (String, required): Base URL of your backend API
- `authToken` (String?, optional): Bearer token for authentication
- `syncInterval` (Duration, default: 5 minutes): How often to sync in background
- `maxRetries` (int, default: 3): Maximum retry attempts for failed operations
- `enableAutoSync` (bool, default: true): Enable automatic background sync

---

## Collection Operations

### `SyncLayer.collection(String name)`

Get a reference to a collection.

```dart
final messages = SyncLayer.collection('messages');
```

**Parameters:**
- `name` (String): Collection name

**Returns:** `CollectionReference`

---

### `CollectionReference.save(Map<String, dynamic> data, {String? id})`

Save data to the collection. Creates new document or updates existing one.

```dart
// Auto-generate ID
final id = await SyncLayer.collection('messages').save({
  'text': 'Hello World',
  'timestamp': DateTime.now().toIso8601String(),
});

// Use custom ID
await SyncLayer.collection('messages').save(
  {'text': 'Hello'},
  id: 'custom-id-123',
);
```

**Parameters:**
- `data` (Map<String, dynamic>): Document data
- `id` (String?, optional): Custom document ID (auto-generated if not provided)

**Returns:** `Future<String>` - Document ID

**Behavior:**
1. Saves data to local database immediately
2. Queues operation for background sync
3. Returns instantly (no network wait)

---

### `CollectionReference.get(String id)`

Retrieve a single document by ID.

```dart
final message = await SyncLayer.collection('messages').get('doc-id-123');

if (message != null) {
  print(message['text']);
}
```

**Parameters:**
- `id` (String): Document ID

**Returns:** `Future<Map<String, dynamic>?>` - Document data or null if not found

---

### `CollectionReference.getAll()`

Retrieve all documents in the collection.

```dart
final allMessages = await SyncLayer.collection('messages').getAll();

for (final message in allMessages) {
  print(message['text']);
}
```

**Returns:** `Future<List<Map<String, dynamic>>>` - List of documents

---

### `CollectionReference.delete(String id)`

Delete a document by ID.

```dart
await SyncLayer.collection('messages').delete('doc-id-123');
```

**Parameters:**
- `id` (String): Document ID

**Returns:** `Future<void>`

**Behavior:**
1. Marks document as deleted locally
2. Queues delete operation for sync
3. Document won't appear in queries

---

### `CollectionReference.watch()`

Watch collection for real-time changes.

```dart
SyncLayer.collection('messages').watch().listen((messages) {
  print('Collection updated: ${messages.length} documents');
  
  for (final message in messages) {
    print(message['text']);
  }
});
```

**Returns:** `Stream<List<Map<String, dynamic>>>` - Stream of document lists

**Behavior:**
- Emits immediately with current data
- Emits on every local change
- Automatically updates UI when used with StreamBuilder

---

## Sync Management

### `SyncLayer.syncNow()`

Manually trigger synchronization.

```dart
await SyncLayer.syncNow();
```

**Returns:** `Future<void>`

**Behavior:**
- Pushes all pending operations to server
- Only executes if online
- Useful for "sync now" buttons

---

### `SyncLayer.dispose()`

Clean up resources and stop sync engine.

```dart
await SyncLayer.dispose();
```

**Returns:** `Future<void>`

**When to use:**
- App shutdown
- User logout
- Switching accounts

---

## Data Models

### Internal Models

These models are used internally by SyncLayer. You don't need to interact with them directly.

#### `SyncOperation`

Represents a queued sync operation.

```dart
class SyncOperation {
  int id;
  String collectionName;
  String operationType;  // 'insert', 'update', 'delete'
  String payload;        // JSON string
  DateTime timestamp;
  String status;         // 'pending', 'syncing', 'synced', 'failed'
  int retryCount;
  String? errorMessage;
  String? recordId;
}
```

#### `DataRecord`

Represents a document in local storage.

```dart
class DataRecord {
  int id;
  String collectionName;
  String recordId;
  String data;           // JSON string
  DateTime createdAt;
  DateTime updatedAt;
  bool isSynced;
  bool isDeleted;
}
```

---

## Backend API Requirements

Your backend should implement these endpoints:

### Push Data
```
POST /sync/{collection}
Content-Type: application/json
Authorization: Bearer {token}

Body:
{
  "recordId": "doc-id-123",
  "data": {
    "text": "Hello World",
    "timestamp": "2026-02-13T10:00:00Z"
  }
}
```

### Pull Data (Future)
```
GET /sync/{collection}?since=2026-02-13T10:00:00Z
Authorization: Bearer {token}

Response:
{
  "records": [
    {
      "recordId": "doc-id-123",
      "data": {...},
      "updatedAt": "2026-02-13T10:00:00Z"
    }
  ]
}
```

### Delete Data
```
DELETE /sync/{collection}/{recordId}
Authorization: Bearer {token}
```

---

## Error Handling

SyncLayer handles errors gracefully:

- **Network errors**: Operations are queued and retried automatically
- **Initialization errors**: Throws `StateError` with clear message
- **Max retries exceeded**: Operation marked as failed (check logs)

---

## Best Practices

1. **Initialize early**: Call `SyncLayer.init()` in `main()` before `runApp()`
2. **Use watch() for UI**: Leverage reactive streams with `StreamBuilder`
3. **Don't block on sync**: Save operations return instantly
4. **Handle offline gracefully**: UI works normally, sync happens when online
5. **Custom IDs**: Use meaningful IDs for easier debugging
6. **Dispose properly**: Call `dispose()` on app shutdown

---

## Example: Complete Integration

```dart
import 'package:flutter/material.dart';
import 'package:synclayer/synclayer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      authToken: 'token',
    ),
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('SyncLayer Demo')),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: SyncLayer.collection('items').watch(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return CircularProgressIndicator();
            
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final item = snapshot.data![index];
                return ListTile(title: Text(item['name']));
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await SyncLayer.collection('items').save({
              'name': 'New Item',
              'createdAt': DateTime.now().toIso8601String(),
            });
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
```
