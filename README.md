# SyncLayer

[![pub package](https://img.shields.io/pub/v/synclayer.svg)](https://pub.dev/packages/synclayer)

**Build offline-first Flutter apps in minutes** — Production-grade sync engine with automatic background synchronization and conflict resolution.

Works with REST APIs, Firebase, Supabase, Appwrite, or any custom backend.

⚠️ **ALPHA VERSION** - Early release. APIs may change. [See known limitations](#known-limitations).

---

## Why SyncLayer?

Your users expect apps to work offline. But building sync is hard:

❌ Manual queue management  
❌ Conflict resolution logic  
❌ Network retry handling  
❌ Version tracking  

**SyncLayer handles all of this for you.**

```dart
// That's it. Your app now works offline.
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['todos'],
  ),
);

// Save works instantly (local-first)
await SyncLayer.collection('todos').save({
  'text': 'Buy groceries',
  'done': false,
});

// Auto-syncs in background when online
// Handles conflicts automatically
// Retries on failure
```

---

## What You Get

🚀 **Local-First** - Writes happen instantly to local storage  
🔄 **Auto-Sync** - Background sync every 5 minutes (configurable)  
📡 **Offline Queue** - Operations sync automatically when online  
⚔️ **Conflict Resolution** - Last-write-wins, server-wins, or client-wins  
🔌 **Backend Agnostic** - Works with REST, Firebase, Supabase, or custom backends  
📦 **Batch Operations** - Save/delete multiple documents efficiently  
👀 **Reactive** - Watch collections for real-time UI updates  

---

## Supported Backends

### Works With

- ✅ **REST APIs** (built-in adapter)
- ✅ **Firebase Firestore** (adapter on GitHub)
- ✅ **Supabase** (adapter on GitHub)
- ✅ **Appwrite** (adapter on GitHub)
- ✅ **Custom backends** (implement `SyncBackendAdapter`)

Platform adapters are available in the [GitHub repository](https://github.com/hostspicaindia/synclayer/tree/main/lib/adapters).  
See [Platform Adapters Guide](doc/PLATFORM_ADAPTERS.md) for setup instructions.  

---

## Quick Start

### 1. Add dependency

```yaml
dependencies:
  synclayer: ^0.1.0-alpha.6
```

### 2. Initialize

**Option A: REST API (default)**

```dart
import 'package:synclayer/synclayer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      syncInterval: Duration(minutes: 5),
      collections: ['todos', 'users'],
    ),
  );
  
  runApp(MyApp());
}
```

**Option B: Firebase, Supabase, or Appwrite**

Platform adapters are available on [GitHub](https://github.com/hostspicaindia/synclayer/tree/main/lib/adapters). Copy the adapter into your project:

```dart
// 1. Add platform package
dependencies:
  synclayer: ^0.1.0-alpha.6
  cloud_firestore: ^5.7.0  # For Firebase

// 2. Copy adapter from GitHub into your project

// 3. Use it
import 'your_adapters/firebase_adapter.dart';

await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: FirebaseAdapter(
      firestore: FirebaseFirestore.instance,
    ),
    collections: ['todos'],
  ),
);
```

See [Platform Adapters Guide](doc/PLATFORM_ADAPTERS.md) for complete instructions.

### 3. Use it

```dart
// Save (works offline)
final id = await SyncLayer.collection('todos').save({
  'text': 'Buy milk',
  'done': false,
});

// Get
final todo = await SyncLayer.collection('todos').get(id);

// Update (same as save with id)
await SyncLayer.collection('todos').save({
  'text': 'Buy milk',
  'done': true,
}, id: id);

// Delete
await SyncLayer.collection('todos').delete(id);

// Watch for changes (reactive UI)
StreamBuilder(
  stream: SyncLayer.collection('todos').watch(),
  builder: (context, snapshot) {
    final todos = snapshot.data ?? [];
    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, i) => Text(todos[i]['text']),
    );
  },
);
```

---

## How It Works

```
┌─────────────┐
│  Your App   │
└──────┬──────┘
       │ save()
       ▼
┌─────────────┐     ┌──────────────┐
│   SyncLayer │────▶│ Local Storage│  (Instant)
│             │     │    (Isar)    │
└──────┬──────┘     └──────────────┘
       │
       │ (Background)
       ▼
┌─────────────┐     ┌──────────────┐
│ Sync Engine │────▶│   Backend    │  (Auto-sync)
│   + Queue   │     │     API      │
└─────────────┘     └──────────────┘
```

**Architecture:**
- **SyncLayer** - Main API (what you use)
- **Collections** - Data abstraction (like tables)
- **SyncEngine** - Background processor (handles sync)
- **Queue Manager** - Retry logic and ordering
- **Conflict Resolver** - Handles conflicts automatically

---

## Example App

See the [Todo App example](example/todo_app/) for a complete working app with:
- Offline editing
- Auto-sync when online
- Conflict resolution
- Real-time UI updates

---

## Backend Integration

SyncLayer works with any backend. You need two endpoints:

```typescript
// Push: Receive changes from client
POST /sync/{collection}
Body: { recordId, data, version, updatedAt }

// Pull: Send changes to client
GET /sync/{collection}?since={timestamp}
Response: [{ recordId, data, version, updatedAt }]
```

See [backend example](backend/) for a complete Node.js implementation.

---

## Advanced Features

### Batch Operations

```dart
// Save multiple
await SyncLayer.collection('todos').saveAll([
  {'text': 'Task 1'},
  {'text': 'Task 2'},
  {'text': 'Task 3'},
]);

// Delete multiple
await SyncLayer.collection('todos').deleteAll([id1, id2, id3]);
```

### Manual Sync

```dart
// Trigger sync immediately (e.g., pull-to-refresh)
await SyncLayer.syncNow();
```

### Conflict Resolution

```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    conflictStrategy: ConflictStrategy.lastWriteWins, // Default
    // or: ConflictStrategy.serverWins
    // or: ConflictStrategy.clientWins
  ),
);
```

### Event Monitoring

```dart
SyncLayerCore.instance.syncEngine.events.listen((event) {
  switch (event.type) {
    case SyncEventType.syncStarted:
      print('Sync started');
      break;
    case SyncEventType.syncCompleted:
      print('Sync completed');
      break;
    case SyncEventType.conflictDetected:
      print('Conflict in ${event.collectionName}');
      break;
  }
});
```

---

## Known Limitations

This is an alpha release. Known issues:

- ⚠️ Pull sync requires explicit `collections` configuration
- ⚠️ Example backend uses in-memory storage (not production-ready)
- ⚠️ Limited production testing (2 of 10 validation tests completed)
- ⚠️ Basic error handling and retry logic
- ⚠️ No built-in authentication or encryption

See [CHANGELOG](CHANGELOG.md) for details.

---

## Roadmap

- [ ] Complete production validation tests
- [ ] Persistent backend example
- [ ] Custom conflict resolvers
- [ ] Encryption support
- [ ] WebSocket support for real-time sync
- [ ] Firebase/Supabase adapters
- [ ] Pagination for large datasets

---

## vs Other Solutions

| Feature | SyncLayer | Drift | Firebase | Supabase |
|---------|-----------|-------|----------|----------|
| Offline-first | ✅ | ✅ | ❌ | ❌ |
| Backend agnostic | ✅ | ✅ | ❌ | ❌ |
| Auto-sync | ✅ | ❌ | ✅ | ✅ |
| Conflict resolution | ✅ | ❌ | ✅ | ✅ |
| Queue management | ✅ | ❌ | ✅ | ✅ |
| Custom backend | ✅ | ✅ | ❌ | ❌ |

**SyncLayer = Drift's offline-first + Firebase's auto-sync + Your own backend**

---

## Contributing

Issues and PRs welcome! See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

MIT License - see [LICENSE](LICENSE) file.

---

## Support

- 📖 [Complete API Reference](doc/API_REFERENCE.md)
- 🔌 [Platform Adapters Guide](doc/PLATFORM_ADAPTERS.md) - Firebase, Supabase, Appwrite
- 📖 [Documentation](https://github.com/hostspicaindia/synclayer/wiki)
- 🐛 [Issues](https://github.com/hostspicaindia/synclayer/issues)
- 💬 [Discussions](https://github.com/hostspicaindia/synclayer/discussions)
- 🤝 [Contributing](CONTRIBUTING.md)

---

**Made with ❤️ by [Hostspica](https://hostspica.com)**
