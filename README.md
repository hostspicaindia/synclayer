# SyncLayer

[![pub package](https://img.shields.io/pub/v/synclayer.svg)](https://pub.dev/packages/synclayer)
[![pub points](https://img.shields.io/pub/points/synclayer?color=2E8B57&label=pub%20points)](https://pub.dev/packages/synclayer/score)
[![popularity](https://img.shields.io/pub/popularity/synclayer?logo=dart)](https://pub.dev/packages/synclayer/score)
[![likes](https://img.shields.io/pub/likes/synclayer?logo=dart)](https://pub.dev/packages/synclayer/score)

**Build offline-first Flutter apps in minutes** — Production-grade sync engine with automatic background synchronization and conflict resolution.

Works with REST APIs, Firebase, Supabase, Appwrite, or any custom backend.

✅ **PRODUCTION READY** - v1.3.1 stable release. Battle-tested with 242+ downloads and perfect pub.dev score (160/160).

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
⚔️ **Conflict Resolution** - Last-write-wins, server-wins, client-wins, or custom resolvers  
🎨 **Custom Conflict Resolvers** - Merge arrays, sum numbers, field-level merging (NEW in v1.3.0!)  
⚡ **Delta Sync** - Only sync changed fields, save 70-98% bandwidth (NEW in v1.3.0!)  
🔐 **Encryption at Rest** - AES-256-GCM, CBC, ChaCha20 for HIPAA/PCI compliance (NEW in v1.3.0!)  
🔌 **Backend Agnostic** - Works with REST, Firebase, Supabase, or custom backends  
📦 **Batch Operations** - Save/delete multiple documents efficiently  
👀 **Reactive** - Watch collections for real-time UI updates  
🔍 **Query & Filter** - Powerful querying with sorting and pagination  
🎯 **Selective Sync** - Filter what data gets synced (privacy, bandwidth, storage)  
📊 **Metrics & Telemetry** - Track sync performance and success rates  
📝 **Structured Logging** - Production-ready logging framework  
⚡ **High Performance** - 50-90% faster with optimizations  
🔒 **Data Integrity** - SHA-256 hashing and proper validation  

---

## Supported Backends

### Works With 14+ Databases

**BaaS Platforms (3)**
- ✅ **Firebase Firestore** - Google's NoSQL cloud database
- ✅ **Supabase** - Open-source Firebase alternative with PostgreSQL
- ✅ **Appwrite** - Self-hosted backend-as-a-service

**SQL Databases (4)**
- ✅ **PostgreSQL** - Advanced open-source relational database
- ✅ **MySQL** - Popular open-source relational database
- ✅ **MariaDB** - MySQL fork with enhanced features
- ✅ **SQLite** - Embedded relational database

**NoSQL Databases (5)**
- ✅ **MongoDB** - Document-oriented database
- ✅ **CouchDB** - Document database with built-in sync
- ✅ **Redis** - In-memory key-value store
- ✅ **DynamoDB** - AWS managed NoSQL database
- ✅ **Cassandra** - Distributed wide-column store

**API Protocols (2)**
- ✅ **REST APIs** - Generic HTTP/REST backend (built-in)
- ✅ **GraphQL** - Flexible query language for APIs

**Custom Backends**
- ✅ Implement `SyncBackendAdapter` for any backend

⚠️ **Note:** Database adapters (Firebase, Supabase, PostgreSQL, MongoDB, etc.) are NOT in the pub.dev package.  
You must copy them from the [GitHub repository](https://github.com/hostspicaindia/synclayer/tree/main/lib/adapters) into your project.

**Why?** To keep the package lightweight and avoid forcing optional dependencies on all users.

📖 **Setup guides:**
- [Database Support Guide](https://github.com/hostspicaindia/synclayer/blob/main/DATABASE_SUPPORT.md) - Overview of all 14 databases
- [Database Comparison](https://github.com/hostspicaindia/synclayer/blob/main/DATABASE_COMPARISON.md) - Choose the right database
- [Adapter Guide](https://github.com/hostspicaindia/synclayer/blob/main/lib/adapters/ADAPTER_GUIDE.md) - Setup for each database
- [Platform Adapters Guide](https://github.com/hostspicaindia/synclayer/blob/main/doc/PLATFORM_ADAPTERS.md) - Firebase, Supabase, Appwrite  

---

## Quick Start

### 1. Add dependency

```yaml
dependencies:
  synclayer: ^1.4.1
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

**Option B: Firebase, Supabase, PostgreSQL, MongoDB, or 10+ other databases**

⚠️ **Important:** Database adapters are NOT included in the pub.dev package. You must copy them from GitHub.

**Quick Install (Windows PowerShell):**
```powershell
# Create adapters folder
New-Item -ItemType Directory -Force -Path lib\adapters

# Download Firebase adapter
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hostspicaindia/synclayer/main/lib/adapters/firebase_adapter.dart" -OutFile "lib\adapters\firebase_adapter.dart"

# Or PostgreSQL adapter
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hostspicaindia/synclayer/main/lib/adapters/postgres_adapter.dart" -OutFile "lib\adapters\postgres_adapter.dart"

# Or MongoDB adapter
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hostspicaindia/synclayer/main/lib/adapters/mongodb_adapter.dart" -OutFile "lib\adapters\mongodb_adapter.dart"
```

**Or manually:**
1. Go to [GitHub adapters folder](https://github.com/hostspicaindia/synclayer/tree/main/lib/adapters)
2. Copy the adapter file you need (e.g., `firebase_adapter.dart`, `postgres_adapter.dart`, `mongodb_adapter.dart`)
3. Paste into your project at `lib/adapters/[adapter_name].dart`

**Then use it:**
```dart
// 1. Add platform package to pubspec.yaml
dependencies:
  synclayer: ^1.4.1
  cloud_firestore: ^5.7.0  # For Firebase
  # OR postgres: ^3.0.0     # For PostgreSQL
  # OR mongo_dart: ^0.10.0  # For MongoDB
  # See DATABASE_SUPPORT.md for all options

// 2. Import the adapter you copied
import 'adapters/firebase_adapter.dart';
// OR import 'adapters/postgres_adapter.dart';
// OR import 'adapters/mongodb_adapter.dart';

// 3. Initialize with Firebase
await Firebase.initializeApp();
await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: FirebaseAdapter(
      firestore: FirebaseFirestore.instance,
    ),
    collections: ['todos'],
  ),
);

// OR with PostgreSQL
final connection = await Connection.open(
  Endpoint(host: 'localhost', database: 'mydb', username: 'user', password: 'pass'),
);
await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: PostgresAdapter(connection: connection),
    collections: ['todos'],
  ),
);

// OR with MongoDB
final db = await Db.create('mongodb://localhost:27017/mydb');
await db.open();
await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: MongoDBAdapter(db: db),
    collections: ['todos'],
  ),
);
```

📖 **Full setup guides:**
- [Database Support Guide](https://github.com/hostspicaindia/synclayer/blob/main/DATABASE_SUPPORT.md) - All 14 databases
- [Database Comparison](https://github.com/hostspicaindia/synclayer/blob/main/DATABASE_COMPARISON.md) - Choose the right one
- [Adapter Guide](https://github.com/hostspicaindia/synclayer/blob/main/lib/adapters/ADAPTER_GUIDE.md) - Setup instructions
- [Platform Adapters Guide](https://github.com/hostspicaindia/synclayer/blob/main/doc/PLATFORM_ADAPTERS.md) - Firebase, Supabase, Appwrite

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

// Query & Filter (NEW in v1.1.0!)
final incompleteTodos = await SyncLayer.collection('todos')
  .where('done', isEqualTo: false)
  .orderBy('priority', descending: true)
  .limit(10)
  .get();

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

### Selective Sync (Sync Filters) (NEW in v1.2.0!)

Control exactly what data gets synced to save bandwidth, storage, and ensure privacy.

**Why use sync filters?**
- 🔒 **Privacy:** Users don't want to download everyone's data
- 📱 **Bandwidth:** Mobile users have limited data plans
- 💾 **Storage:** Devices have limited space
- 🔐 **Security:** Multi-tenant apps need user isolation
- ⚖️ **Legal:** GDPR requires data minimization

```dart
// Multi-tenant: Only sync current user's data
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['todos', 'notes'],
    syncFilters: {
      'todos': SyncFilter(
        where: {'userId': currentUserId},
      ),
    },
  ),
);

// Time-based: Only sync recent data
syncFilters: {
  'todos': SyncFilter(
    since: DateTime.now().subtract(Duration(days: 30)),
  ),
}

// Bandwidth optimization: Exclude large fields
syncFilters: {
  'documents': SyncFilter(
    excludeFields: ['fullContent', 'attachments', 'thumbnail'],
  ),
}

// Or include only specific fields
syncFilters: {
  'documents': SyncFilter(
    fields: ['id', 'title', 'summary', 'createdAt'],
  ),
}

// Progressive sync: Limit initial sync size
syncFilters: {
  'todos': SyncFilter(
    limit: 50, // Only sync first 50 items
  ),
}

// Combined filters: All together
syncFilters: {
  'todos': SyncFilter(
    where: {
      'userId': currentUserId,
      'archived': false,
    },
    since: DateTime.now().subtract(Duration(days: 30)),
    limit: 100,
    excludeFields: ['attachments', 'comments'],
  ),
}
```

**Real-world example: Todo app**
```dart
final currentUserId = 'user-123';

await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['todos', 'projects', 'tags'],
    syncFilters: {
      // Todos: Only user's active todos from last 90 days
      'todos': SyncFilter(
        where: {
          'userId': currentUserId,
          'deleted': false,
        },
        since: DateTime.now().subtract(Duration(days: 90)),
      ),
      // Projects: Only user's projects
      'projects': SyncFilter(
        where: {'userId': currentUserId},
      ),
      // Tags: Only user's tags, exclude metadata
      'tags': SyncFilter(
        where: {'userId': currentUserId},
        excludeFields: ['usage_stats', 'metadata'],
      ),
    },
  ),
);
```

**GDPR compliance example:**
```dart
syncFilters: {
  'user_data': SyncFilter(
    where: {
      'userId': currentUserId,
      'consentGiven': true, // Only sync if consent given
    },
    since: DateTime.now().subtract(Duration(days: 365)), // Data retention
    excludeFields: ['ssn', 'creditCard', 'medicalRecords'], // Privacy
  ),
}
```

**Mobile bandwidth optimization:**
```dart
syncFilters: {
  // Messages: Only recent, only essential fields
  'messages': SyncFilter(
    where: {'userId': currentUserId},
    since: DateTime.now().subtract(Duration(days: 7)),
    fields: ['id', 'text', 'senderId', 'timestamp'],
    limit: 200,
  ),
  // Media: Only thumbnails, no full resolution
  'media': SyncFilter(
    where: {'userId': currentUserId},
    fields: ['id', 'thumbnailUrl', 'type'],
  ),
}
```

See [sync filter example](example/sync_filter_example.dart) for more use cases.

### Query & Filtering (NEW in v1.1.0!)

```dart
// Basic filtering
final incompleteTodos = await SyncLayer.collection('todos')
  .where('done', isEqualTo: false)
  .get();

// Multiple conditions
final urgentTodos = await SyncLayer.collection('todos')
  .where('done', isEqualTo: false)
  .where('priority', isGreaterThan: 5)
  .get();

// String operations
final searchResults = await SyncLayer.collection('todos')
  .where('text', contains: 'urgent')
  .get();

// Sorting
final sortedTodos = await SyncLayer.collection('todos')
  .orderBy('priority', descending: true)
  .orderBy('createdAt')
  .get();

// Pagination
final page1 = await SyncLayer.collection('todos')
  .limit(10)
  .get();

final page2 = await SyncLayer.collection('todos')
  .offset(10)
  .limit(10)
  .get();

// Complex queries
final results = await SyncLayer.collection('todos')
  .where('done', isEqualTo: false)
  .where('priority', isGreaterThanOrEqualTo: 5)
  .where('userId', isEqualTo: currentUserId)
  .orderBy('priority', descending: true)
  .limit(20)
  .get();

// Reactive queries with filters
SyncLayer.collection('todos')
  .where('done', isEqualTo: false)
  .watch()
  .listen((todos) {
    print('Incomplete todos: ${todos.length}');
  });

// Array operations
final workTodos = await SyncLayer.collection('todos')
  .where('tags', arrayContains: 'work')
  .get();

// Nested fields
final userTodos = await SyncLayer.collection('todos')
  .where('user.name', isEqualTo: 'John')
  .get();

// Utility methods
final firstTodo = await SyncLayer.collection('todos')
  .where('done', isEqualTo: false)
  .first();

final count = await SyncLayer.collection('todos')
  .where('done', isEqualTo: true)
  .count();
```

**Supported Operators:**
- Comparison: `isEqualTo`, `isNotEqualTo`, `isGreaterThan`, `isLessThan`, etc.
- String: `startsWith`, `endsWith`, `contains`
- Array: `arrayContains`, `arrayContainsAny`, `whereIn`, `whereNotIn`
- Null: `isNull`, `isNotNull`

See [query example](example/query_example.dart) for more details.

### Custom Conflict Resolvers (NEW in v1.3.0!)

Go beyond the built-in strategies with custom conflict resolution logic:

```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    conflictStrategy: ConflictStrategy.custom,
    customConflictResolver: (local, remote, localTime, remoteTime) {
      // Social app: Merge likes and comments
      return {
        ...remote,
        'likes': [...local['likes'], ...remote['likes']].toSet().toList(),
        'comments': [...local['comments'], ...remote['comments']],
      };
    },
  ),
);
```

**Pre-built resolvers for common scenarios:**

```dart
// Merge arrays (social apps)
customConflictResolver: ConflictResolvers.mergeArrays(['tags', 'likes'])

// Sum numbers (inventory apps)
customConflictResolver: ConflictResolvers.sumNumbers(['quantity', 'views'])

// Field-level last-write-wins (collaborative editing)
customConflictResolver: ConflictResolvers.fieldLevelLastWriteWins()

// Deep merge (nested objects)
customConflictResolver: ConflictResolvers.deepMerge()

// Max value (analytics)
customConflictResolver: ConflictResolvers.maxValue(['version', 'score'])
```

See [custom conflict resolver example](example/custom_conflict_resolver_example.dart) for more use cases.

### Delta Sync - Partial Updates (NEW in v1.3.0!)

Save 70-98% bandwidth by only syncing changed fields:

```dart
// Instead of sending entire document (wasteful):
await collection.save({
  'id': '123',
  'title': 'My Document',
  'content': '... 50KB of content ...',
  'done': true,  // Only this changed!
}, id: '123');

// Use delta sync - only send changed field (efficient):
await collection.update('123', {'done': true});
// Saves 98% bandwidth!
```

**Real-world examples:**

```dart
// Toggle todo completion
await collection.update(todoId, {'done': true});

// Increment view count
final doc = await collection.get(docId);
await collection.update(docId, {'views': (doc!['views'] ?? 0) + 1});

// Update user status
await collection.update(userId, {
  'status': 'online',
  'lastSeen': DateTime.now().toIso8601String(),
});
```

**Benefits:**
- 70-98% bandwidth reduction
- Faster sync performance
- Lower server costs
- Better battery life
- Fewer conflicts (only specific fields change)

See [delta sync example](example/delta_sync_example.dart) for more details.

### Encryption at Rest (NEW in v1.3.0!)

Protect sensitive data with industry-standard encryption:

```dart
import 'dart:math';
import 'dart:typed_data';

// Generate secure encryption key (32 bytes for AES-256)
Uint8List generateSecureKey() {
  final random = Random.secure();
  return Uint8List.fromList(
    List.generate(32, (_) => random.nextInt(256)),
  );
}

await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['patients', 'transactions'],
    encryption: EncryptionConfig(
      enabled: true,
      key: encryptionKey,
      algorithm: EncryptionAlgorithm.aes256GCM, // Recommended
      compressBeforeEncryption: true, // Reduce storage
    ),
  ),
);

// Data is automatically encrypted before storage
await SyncLayer.collection('patients').save({
  'name': 'John Doe',
  'ssn': '123-45-6789', // Encrypted at rest
  'diagnosis': 'Hypertension',
});
```

**Supported algorithms:**
- `aes256GCM` - Best balance (recommended for most apps)
- `aes256CBC` - Legacy compatibility
- `chacha20Poly1305` - Mobile-optimized

**Use cases:**
- Healthcare apps (HIPAA compliance)
- Finance apps (PCI DSS compliance)
- Legal apps (attorney-client privilege)
- Enterprise apps (SOC2, ISO 27001)

**IMPORTANT:** Store encryption keys securely using `flutter_secure_storage` or platform keychain. Never hardcode keys!

See [encryption example](example/encryption_example.dart) for complete guide.

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

### Metrics & Monitoring

```dart
// Get current sync metrics
final metrics = SyncLayer.getMetrics();
print('Success rate: ${(metrics.successRate * 100).toStringAsFixed(1)}%');
print('Average sync: ${metrics.averageSyncDuration?.inMilliseconds}ms');
print('Conflicts: ${metrics.conflictsDetected}');

// Configure custom metrics handler
SyncLayer.configureMetrics(
  customHandler: (event) {
    // Send to your analytics service
    analytics.track(event.type, event.data);
  },
);
```

### Logging Configuration

```dart
// Configure logging for production
SyncLayer.configureLogger(
  enabled: !kReleaseMode, // Disable in release mode
  minLevel: LogLevel.warning, // Only warnings and errors
  customLogger: (level, message, error, stackTrace) {
    // Send errors to crash reporting
    if (level == LogLevel.error) {
      crashlytics.recordError(error, stackTrace);
    }
  },
);
```

---

## Known Limitations

This is a beta release. Known issues:

- ⚠️ Pull sync requires explicit `collections` configuration
- ⚠️ Example backend uses in-memory storage (not production-ready)
- ⚠️ Basic authentication (token-based only)

See [CHANGELOG](CHANGELOG.md) for details.

---

## Performance

**v0.2.0-beta.7 Improvements:**
- 90% less memory usage for large datasets (pagination)
- 50-80% faster queries (database indexes)
- 70% faster bulk operations (batch processing)
- SHA-256 data integrity verification
- 30-second operation timeouts

---

## Roadmap

- [x] Production-grade logging and metrics
- [x] Database indexes for performance
- [x] Pagination for large datasets
- [x] Batch operations
- [x] Data validation
- [x] Custom conflict resolvers ⭐ NEW in v1.3.0
- [x] Delta sync (partial updates) ⭐ NEW in v1.3.0
- [x] Encryption at rest ⭐ NEW in v1.3.0
- [ ] WebSocket support for real-time sync
- [ ] Migration tools

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
- 🎯 [Sync Filters Guide](doc/SYNC_FILTERS.md) - Control what data gets synced
- 🚀 [Quick Start: Sync Filters](doc/QUICK_START_SYNC_FILTERS.md) - 5-minute tutorial
- 🔄 [Migration Guide v1.2.0](doc/MIGRATION_GUIDE_v1.2.0.md) - Upgrade from v1.1.0
- 🔌 [Platform Adapters Guide](doc/PLATFORM_ADAPTERS.md) - Firebase, Supabase, Appwrite
- 📖 [Documentation](https://github.com/hostspicaindia/synclayer/wiki)
- 🐛 [Issues](https://github.com/hostspicaindia/synclayer/issues)
- 💬 [Discussions](https://github.com/hostspicaindia/synclayer/discussions)
- 🤝 [Contributing](CONTRIBUTING.md)

---

**Made with ❤️ by [Hostspica](https://hostspica.com)**
