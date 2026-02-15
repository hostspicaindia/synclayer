# SyncLayer Quick Reference

One-page reference for common tasks.

---

## Installation

```yaml
dependencies:
  synclayer: ^0.1.0-alpha.6
```

**For platform adapters:** Copy adapter from [GitHub](https://github.com/hostspicaindia/synclayer/tree/main/lib/adapters) and add platform package:

```yaml
# Firebase
cloud_firestore: ^5.7.0

# Supabase
supabase_flutter: ^2.9.0

# Appwrite
appwrite: ^14.0.0
```

---

## Initialization

### REST API
```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['todos'],
  ),
);
```

### Firebase
```dart
// 1. Copy firebase_adapter.dart from GitHub into your project
// 2. Add cloud_firestore: ^5.7.0 to pubspec.yaml
import 'adapters/firebase_adapter.dart';

await Firebase.initializeApp();
await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: FirebaseAdapter(
      firestore: FirebaseFirestore.instance,
    ),
    collections: ['todos'],
  ),
);
```

### Supabase
```dart
// 1. Copy supabase_adapter.dart from GitHub into your project
// 2. Add supabase_flutter: ^2.9.0 to pubspec.yaml
import 'adapters/supabase_adapter.dart';

await Supabase.initialize(url: '...', anonKey: '...');
await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: SupabaseAdapter(
      client: Supabase.instance.client,
    ),
    collections: ['todos'],
  ),
);
```

### Appwrite
```dart
// 1. Copy appwrite_adapter.dart from GitHub into your project
// 2. Add appwrite: ^14.0.0 to pubspec.yaml
import 'adapters/appwrite_adapter.dart';

final client = Client()..setEndpoint('...')..setProject('...');
await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: AppwriteAdapter(
      databases: Databases(client),
      databaseId: 'your-db-id',
    ),
    collections: ['todos'],
  ),
);
```

---

## CRUD Operations

### Save (Insert/Update)
```dart
// Insert
final id = await SyncLayer.collection('todos').save({
  'text': 'Buy milk',
  'done': false,
});

// Update
await SyncLayer.collection('todos').save({
  'text': 'Buy milk',
  'done': true,
}, id: id);
```

### Get
```dart
// Get one
final todo = await SyncLayer.collection('todos').get(id);

// Get all
final todos = await SyncLayer.collection('todos').getAll();
```

### Delete
```dart
await SyncLayer.collection('todos').delete(id);
```

### Watch (Reactive)
```dart
StreamBuilder(
  stream: SyncLayer.collection('todos').watch(),
  builder: (context, snapshot) {
    final todos = snapshot.data ?? [];
    return ListView.builder(...);
  },
);
```

---

## Batch Operations

```dart
// Save multiple
await SyncLayer.collection('todos').saveAll([
  {'text': 'Task 1'},
  {'text': 'Task 2'},
]);

// Delete multiple
await SyncLayer.collection('todos').deleteAll([id1, id2]);
```

---

## Sync Control

```dart
// Manual sync
await SyncLayer.syncNow();

// Dispose
await SyncLayer.dispose();
```

---

## Configuration Options

```dart
SyncConfig(
  baseUrl: 'https://api.example.com',
  authToken: 'Bearer token',
  syncInterval: Duration(minutes: 5),
  maxRetries: 3,
  enableAutoSync: true,
  collections: ['todos', 'users'],
  conflictStrategy: ConflictStrategy.lastWriteWins,
  customBackendAdapter: null,
)
```

---

## Event Monitoring

```dart
SyncLayerCore.instance.syncEngine.events.listen((event) {
  switch (event.type) {
    case SyncEventType.syncStarted:
      print('Sync started');
      break;
    case SyncEventType.syncCompleted:
      print('Sync completed');
      break;
    case SyncEventType.syncFailed:
      print('Sync failed: ${event.error}');
      break;
    case SyncEventType.conflictDetected:
      print('Conflict in ${event.collectionName}');
      break;
  }
});
```

---

## Conflict Strategies

```dart
ConflictStrategy.lastWriteWins  // Most recent wins (default)
ConflictStrategy.serverWins     // Server always wins
ConflictStrategy.clientWins     // Client always wins
```

---

## Backend Requirements

### REST API
```
POST /sync/{collection}
Body: { recordId, data, timestamp }

GET /sync/{collection}?since={timestamp}
Response: [{ recordId, data, updatedAt, version }]
```

### Firebase
```
/collection/{recordId}
  - data: Map
  - updatedAt: Timestamp
  - version: int
```

### Supabase
```sql
CREATE TABLE collection (
  record_id TEXT PRIMARY KEY,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  version INTEGER NOT NULL
);
```

### Appwrite
```
Collection attributes:
  - data (JSON)
  - updated_at (DateTime)
  - version (Integer)
```

---

## Common Patterns

### Pull to Refresh
```dart
RefreshIndicator(
  onRefresh: () => SyncLayer.syncNow(),
  child: ListView(...),
);
```

### Offline Indicator
```dart
StreamBuilder(
  stream: SyncLayerCore.instance.connectivityService.onConnectivityChanged,
  builder: (context, snapshot) {
    final isOnline = snapshot.data ?? false;
    return Banner(
      message: isOnline ? 'Online' : 'Offline',
      location: BannerLocation.topEnd,
      child: YourWidget(),
    );
  },
);
```

### Sync Status
```dart
StreamBuilder(
  stream: SyncLayerCore.instance.syncEngine.events,
  builder: (context, snapshot) {
    if (snapshot.data?.type == SyncEventType.syncStarted) {
      return CircularProgressIndicator();
    }
    return Container();
  },
);
```

---

## Troubleshooting

### Pull sync not working
```dart
// Add collections to config
SyncConfig(
  collections: ['todos'], // Required!
)
```

### Data not syncing
```dart
// Check connectivity
final isOnline = await SyncLayerCore.instance.connectivityService.isConnected;
print('Online: $isOnline');

// Trigger manual sync
await SyncLayer.syncNow();
```

### Conflicts not resolving
```dart
// Set explicit strategy
SyncConfig(
  conflictStrategy: ConflictStrategy.lastWriteWins,
)
```

---

## Links

- [Complete API Reference](API_REFERENCE.md)
- [Platform Adapters Guide](PLATFORM_ADAPTERS.md)
- [GitHub](https://github.com/hostspicaindia/synclayer)
- [pub.dev](https://pub.dev/packages/synclayer)

