# SyncLayer

[![pub package](https://img.shields.io/pub/v/synclayer.svg)](https://pub.dev/packages/synclayer)
[![likes](https://img.shields.io/pub/likes/synclayer)](https://pub.dev/packages/synclayer/score)
[![popularity](https://img.shields.io/pub/popularity/synclayer)](https://pub.dev/packages/synclayer/score)
[![pub points](https://img.shields.io/pub/points/synclayer)](https://pub.dev/packages/synclayer/score)

**Build offline-first Flutter apps in minutes** — Production-grade sync engine with automatic background synchronization and conflict resolution.

**Now supports 14+ databases:** PostgreSQL, MySQL, MongoDB, Firebase, Supabase, Redis, DynamoDB, and more!

---

## 🎉 What's New in v1.4.0

✨ **Multi-Database Support** - Now supports 14+ databases!
- **SQL**: PostgreSQL, MySQL, MariaDB, SQLite
- **NoSQL**: MongoDB, CouchDB, Redis, DynamoDB, Cassandra
- **BaaS**: Firebase, Supabase, Appwrite
- **API**: REST, GraphQL

📚 **Comprehensive Documentation** - Complete guides for each database  
🧪 **60+ Tests** - All adapters fully tested  
🔧 **Optional Dependencies** - Only install what you need  

[See full changelog →](#changelog)

---

## Why SyncLayer?

Your users expect apps to work offline. But building sync is hard:

❌ Manual queue management  
❌ Conflict resolution logic  
❌ Network retry handling  
❌ Version tracking  
❌ Database integration  

**SyncLayer handles all of this for you.**

```dart
// Works with any database - PostgreSQL, MongoDB, Firebase, etc.
await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: PostgresAdapter(connection: conn),
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
🗄️ **14+ Databases** - PostgreSQL, MySQL, MongoDB, Firebase, and more  
⚔️ **Conflict Resolution** - Last-write-wins, server-wins, or client-wins  
🔌 **Backend Agnostic** - Works with any database or API  
📦 **Batch Operations** - Save/delete multiple documents efficiently  
👀 **Reactive** - Watch collections for real-time UI updates  

---

## Supported Databases

### BaaS Platforms
- ✅ **Firebase Firestore** - Google's NoSQL cloud database
- ✅ **Supabase** - Open-source Firebase alternative with PostgreSQL
- ✅ **Appwrite** - Self-hosted backend-as-a-service

### SQL Databases
- ✅ **PostgreSQL** - Advanced open-source relational database
- ✅ **MySQL** - Popular open-source relational database
- ✅ **MariaDB** - MySQL fork with enhanced features
- ✅ **SQLite** - Embedded relational database

### NoSQL Databases
- ✅ **MongoDB** - Document-oriented database
- ✅ **CouchDB** - Document database with built-in sync
- ✅ **Redis** - In-memory key-value store
- ✅ **DynamoDB** - AWS managed NoSQL database
- ✅ **Cassandra** - Distributed wide-column store

### API Protocols
- ✅ **REST API** - Generic HTTP/REST backend (built-in)
- ✅ **GraphQL** - Flexible query language for APIs

📖 **See:** [Database Comparison Guide](DATABASE_COMPARISON.md) | [Installation Guide](INSTALLATION.md)

---

## Quick Start

### 1. Add dependency

```yaml
dependencies:
  synclayer: ^1.4.0
  # Add your database package
  postgres: ^3.0.0  # Example: PostgreSQL
```

### 2. Initialize

```dart
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters.dart';
import 'package:postgres/postgres.dart';

// Connect to your database
final conn = await Connection.open(
  Endpoint(host: 'localhost', database: 'mydb'),
);

// Initialize SyncLayer
await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: PostgresAdapter(connection: conn),
    collections: ['todos'],
  ),
);
```

### 3. Use it

```dart
// Save data (works offline)
final id = await SyncLayer.collection('todos').save({
  'text': 'Buy milk',
  'done': false,
});

// Get data
final todo = await SyncLayer.collection('todos').get(id);

// Watch for changes (real-time)
SyncLayer.collection('todos').watch().listen((todos) {
  print('Todos: ${todos.length}');
});

// Delete
await SyncLayer.collection('todos').delete(id);

// Manual sync
await SyncLayer.syncNow();
```

---

## More Examples

### Firebase
```dart
import 'package:synclayer/adapters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: FirebaseAdapter(
      firestore: FirebaseFirestore.instance,
    ),
    collections: ['todos'],
  ),
);
```

### MongoDB
```dart
import 'package:synclayer/adapters.dart';
import 'package:mongo_dart/mongo_dart.dart';

final db = await Db.create('mongodb://localhost:27017/mydb');
await db.open();

await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: MongoDBAdapter(db: db),
    collections: ['todos'],
  ),
);
```

### REST API (Default)
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

⚠️ **Important:** Platform adapters are NOT included in the pub.dev package. You must copy them from GitHub.

**Quick Install (Windows PowerShell):**
```powershell
# Create adapters folder
New-Item -ItemType Directory -Force -Path lib\adapters

# Download Firebase adapter
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hostspicaindia/synclayer/main/lib/adapters/firebase_adapter.dart" -OutFile "lib\adapters\firebase_adapter.dart"
```

**Or manually:**
1. Go to [GitHub adapters folder](https://github.com/hostspicaindia/synclayer/tree/main/lib/adapters)
2. Copy the adapter file (e.g., `firebase_adapter.dart`)
3. Paste into your project at `lib/adapters/firebase_adapter.dart`

**Then use it:**
```dart
// 1. Add platform package to pubspec.yaml
dependencies:
  synclayer: ^0.2.0-beta.1
  cloud_firestore: ^5.7.0  # For Firebase

// 2. Import the adapter you copied
import 'adapters/firebase_adapter.dart';

// 3. Initialize
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

📖 **Full setup guide:** [Platform Adapters Guide](https://github.com/hostspicaindia/synclayer/blob/main/doc/PLATFORM_ADAPTERS.md)

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
