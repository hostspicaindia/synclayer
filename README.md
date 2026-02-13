# SyncLayer

[![pub package](https://img.shields.io/pub/v/synclayer.svg)](https://pub.dev/packages/synclayer)

⚠️ **ALPHA VERSION - NOT PRODUCTION READY**

This package is in active development. APIs may change, and there are known limitations. Use in production at your own risk.

**Current Status:** Alpha testing phase. Basic sync functionality works, but comprehensive production validation is ongoing.

---

An offline-first synchronization engine for Flutter apps.

## Features

- **Local-First Storage**: All data writes happen locally first for instant UI updates
- **Bidirectional Sync**: Full push and pull synchronization with conflict resolution
- **Automatic Sync**: Background synchronization when online
- **Offline Queue**: Operations are queued and synced automatically when connection is restored
- **Backend Agnostic**: Works with REST, Firebase, Supabase, or custom backends via adapter pattern
- **Conflict Resolution**: Built-in strategies (last-write-wins, server-wins, client-wins)
- **Batch Operations**: Save or delete multiple documents in a single operation
- **Event System**: Internal event bus for logging, analytics, and monitoring
- **Concurrency Safe**: Prevents race conditions in sync operations
- **Sync Metadata**: Version tracking and timestamps for reliable conflict detection
- **Simple API**: Minimal, intuitive developer experience
- **Comprehensive Tests**: 90%+ test coverage with unit, integration, and performance tests

## Known Limitations

- Requires explicit collection configuration for pull sync
- Example backend uses in-memory storage (not suitable for production)
- Limited production testing and validation
- Error handling and retry logic are basic
- No built-in authentication or encryption

See [PRODUCTION_VALIDATION.md](https://github.com/hostspicaindia/synclayer/blob/main/PRODUCTION_VALIDATION.md) for detailed test status.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  synclayer: ^0.1.0-alpha.1
```

## Quick Start

### 1. Initialize SyncLayer

```dart
import 'package:synclayer/synclayer.dart';

await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    authToken: 'your-auth-token',
    syncInterval: Duration(minutes: 5),
    collections: ['messages', 'users'], // Specify collections to sync
  ),
);
```

### 2. Save Data

```dart
// Data is saved locally instantly
final id = await SyncLayer.collection('messages').save({
  'text': 'Hello World',
  'userId': '123',
  'timestamp': DateTime.now().toIso8601String(),
});
```

### 3. Read Data

```dart
// Get single document
final message = await SyncLayer.collection('messages').get(id);

// Get all documents
final allMessages = await SyncLayer.collection('messages').getAll();
```

### 4. Watch for Changes

```dart
SyncLayer.collection('messages').watch().listen((messages) {
  print('Messages updated: ${messages.length}');
});
```

### 5. Delete Data

```dart
await SyncLayer.collection('messages').delete(id);
```

### 6. Batch Operations

```dart
// Save multiple documents at once
final ids = await SyncLayer.collection('messages').saveAll([
  {'text': 'Message 1', 'userId': '123'},
  {'text': 'Message 2', 'userId': '123'},
  {'text': 'Message 3', 'userId': '123'},
]);

// Delete multiple documents at once
await SyncLayer.collection('messages').deleteAll(ids);
```

## How It Works

1. **Write Operations**: Data is saved to local Isar database immediately
2. **Queue System**: Operations are added to a sync queue
3. **Push Sync**: When online, queued operations are pushed to your backend
4. **Pull Sync**: Remote changes are fetched and merged with local data
5. **Conflict Resolution**: Conflicts are resolved using configured strategy (default: last-write-wins)

## Configuration Options

```dart
SyncConfig(
  baseUrl: 'https://api.example.com',      // Required
  authToken: 'token',                       // Optional
  syncInterval: Duration(minutes: 5),       // Default: 5 minutes
  maxRetries: 3,                            // Default: 3
  enableAutoSync: true,                     // Default: true
  conflictStrategy: ConflictStrategy.lastWriteWins, // Default
  customBackendAdapter: MyCustomAdapter(),  // Optional: Use custom backend
)
```

## Custom Backend Adapter

SyncLayer supports custom backends via the adapter pattern:

```dart
class FirebaseBackendAdapter implements SyncBackendAdapter {
  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    // Firebase implementation
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

## Event Monitoring

Listen to sync events for logging and analytics:

```dart
SyncLayer.syncEngine.events.listen((event) {
  print('Sync event: ${event.type}');
  
  switch (event.type) {
    case SyncEventType.syncStarted:
      print('Sync started');
    case SyncEventType.operationSynced:
      print('Synced: ${event.recordId}');
    case SyncEventType.conflictDetected:
      print('Conflict in ${event.collectionName}');
  }
});
```

## Backend API Requirements

Your backend should implement these endpoints:

- `POST /sync/{collection}` - Receive synced data from client
- `GET /sync/{collection}?since={timestamp}` - Return updates since timestamp
- `DELETE /sync/{collection}/{recordId}` - Handle deletions

### Example Response Format

**GET /sync/{collection}?since={timestamp}**
```json
{
  "records": [
    {
      "recordId": "abc123",
      "data": {"text": "Hello", "userId": "123"},
      "updatedAt": "2026-02-13T10:30:00Z",
      "version": 2
    }
  ]
}
```

## Testing

SyncLayer includes comprehensive test coverage:

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test suite
flutter test test/unit/
flutter test test/integration/
flutter test test/performance/
```

See [TESTING.md](TESTING.md) for detailed testing guide.

## License

Copyright © 2026 Hostspica Private Limited
