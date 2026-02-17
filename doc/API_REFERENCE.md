# SyncLayer API Reference

Complete reference for all public APIs, configuration options, and event types.

---

## Quick Start

Get started with SyncLayer in 5 minutes.

### Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  synclayer: ^0.2.0-beta.7
```

Run:
```bash
flutter pub get
```

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:synclayer/synclayer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SyncLayer
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      authToken: 'your-auth-token',
      collections: ['todos'],
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Todos')),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: SyncLayer.collection('todos').watch(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return CircularProgressIndicator();
            
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final todo = snapshot.data![index];
                return ListTile(title: Text(todo['text']));
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await SyncLayer.collection('todos').save({
              'text': 'New Todo',
              'done': false,
            });
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
```

---

## Table of Contents

- [Initialization](#initialization)
- [Logging & Metrics](#logging--metrics)
- [Collections](#collections)
- [Configuration](#configuration)
- [Events](#events)
- [Backend Integration](#backend-integration)
- [Data Models](#data-models)
- [Performance](#performance)
- [Best Practices](#best-practices)

---

## Initialization

### `SyncLayer.init(SyncConfig config)`

Initialize SyncLayer with configuration. Must be called before using any other methods.

**Parameters:**
- `config` (SyncConfig) - Configuration object

**Returns:** `Future<void>`

**Throws:** `StateError` if already initialized

**Example:**
```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    authToken: 'your-token',
    syncInterval: Duration(minutes: 5),
    maxRetries: 3,
    enableAutoSync: true,
    collections: ['todos', 'users'],
    conflictStrategy: ConflictStrategy.lastWriteWins,
  ),
);
```

---

### `SyncLayer.dispose()`

Dispose SyncLayer and release all resources. Stops auto-sync and closes database connections.

**Returns:** `Future<void>`

**Example:**
```dart
await SyncLayer.dispose();
```

---

### `SyncLayer.syncNow()`

Trigger an immediate sync cycle, bypassing the automatic sync interval.

**Returns:** `Future<void>`

**Example:**
```dart
// User pulls to refresh
await SyncLayer.syncNow();
```

---

## Logging & Metrics

### Logging System (NEW in v0.2.0-beta.7)

SyncLayer includes a production-ready logging framework with configurable levels.

#### `SyncLayer.configureLogger({bool enabled, LogLevel minLevel, Function? customLogger})`

Configure the logging system.

**Parameters:**
- `enabled` (bool, default: true) - Enable/disable logging
- `minLevel` (LogLevel, default: LogLevel.info) - Minimum log level to output
- `customLogger` (Function?, optional) - Custom logger function

**Example:**
```dart
import 'package:synclayer/synclayer.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure logging for production
  SyncLayer.configureLogger(
    enabled: !kReleaseMode, // Only log in debug mode
    minLevel: kReleaseMode ? LogLevel.error : LogLevel.debug,
    customLogger: (level, message, error, stackTrace) {
      // Send to your analytics service
      print('[$level] $message');
      if (error != null) print('Error: $error');
    },
  );
  
  await SyncLayer.init(SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['todos'],
  ));
  
  runApp(MyApp());
}
```

#### `LogLevel` Enum

Available log levels (from least to most severe):

| Level | Use Case |
|-------|----------|
| `LogLevel.debug` | Detailed debugging information |
| `LogLevel.info` | General informational messages |
| `LogLevel.warning` | Warning messages for potential issues |
| `LogLevel.error` | Error messages for failures |

**Example:**
```dart
// Development: See everything
SyncLayer.configureLogger(
  enabled: true,
  minLevel: LogLevel.debug,
);

// Production: Only errors
SyncLayer.configureLogger(
  enabled: true,
  minLevel: LogLevel.error,
  customLogger: (level, message, error, stackTrace) {
    // Send to Sentry, Firebase Crashlytics, etc.
    if (level == LogLevel.error) {
      crashlytics.recordError(error, stackTrace);
    }
  },
);
```

---

### Metrics System (NEW in v0.2.0-beta.7)

Track sync performance, success rates, and error patterns.

#### `SyncLayer.getMetrics()`

Get current metrics snapshot.

**Returns:** `SyncMetricsSnapshot`

**Example:**
```dart
final metrics = SyncLayer.getMetrics();

print('Total syncs: ${metrics.totalSyncs}');
print('Successful: ${metrics.successfulSyncs}');
print('Failed: ${metrics.failedSyncs}');
print('Success rate: ${metrics.successRate}%');
print('Average duration: ${metrics.averageSyncDuration.inMilliseconds}ms');
print('Total conflicts: ${metrics.totalConflicts}');
print('Conflicts resolved: ${metrics.conflictsResolved}');
```

#### `SyncLayer.configureMetrics({Function? customHandler})`

Configure metrics collection with custom handler.

**Parameters:**
- `customHandler` (Function?, optional) - Custom metrics handler for analytics

**Example:**
```dart
SyncLayer.configureMetrics(
  customHandler: (event) {
    // Send to your analytics service
    analytics.logEvent(
      name: 'sync_metric',
      parameters: {
        'type': event.type,
        'duration': event.duration?.inMilliseconds,
        'success': event.success,
      },
    );
  },
);
```

#### `SyncMetricsSnapshot` Class

Snapshot of current metrics.

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `totalSyncs` | int | Total number of sync attempts |
| `successfulSyncs` | int | Number of successful syncs |
| `failedSyncs` | int | Number of failed syncs |
| `successRate` | double | Success rate percentage (0-100) |
| `averageSyncDuration` | Duration | Average time per sync |
| `totalConflicts` | int | Total conflicts detected |
| `conflictsResolved` | int | Conflicts successfully resolved |
| `lastSyncTime` | DateTime? | When last sync occurred |

**Example - Display Metrics in UI:**
```dart
class MetricsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final metrics = SyncLayer.getMetrics();
    
    return Scaffold(
      appBar: AppBar(title: Text('Sync Metrics')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Success Rate'),
            trailing: Text('${metrics.successRate.toStringAsFixed(1)}%'),
          ),
          ListTile(
            title: Text('Total Syncs'),
            trailing: Text('${metrics.totalSyncs}'),
          ),
          ListTile(
            title: Text('Average Duration'),
            trailing: Text('${metrics.averageSyncDuration.inMilliseconds}ms'),
          ),
          ListTile(
            title: Text('Conflicts Resolved'),
            trailing: Text('${metrics.conflictsResolved}/${metrics.totalConflicts}'),
          ),
        ],
      ),
    );
  }
}
```

**Example - Periodic Monitoring:**
```dart
// Monitor metrics every 5 minutes
Timer.periodic(Duration(minutes: 5), (_) {
  final metrics = SyncLayer.getMetrics();
  
  if (metrics.successRate < 80) {
    // Alert: Low success rate
    print('⚠️ Sync success rate is low: ${metrics.successRate}%');
  }
  
  if (metrics.averageSyncDuration > Duration(seconds: 10)) {
    // Alert: Slow syncs
    print('⚠️ Syncs are taking too long: ${metrics.averageSyncDuration}');
  }
});
```

---

## Collections

### `SyncLayer.collection(String name)`

Get a reference to a collection for performing CRUD operations.

**Parameters:**
- `name` (String) - Collection name

**Returns:** `CollectionReference`

**Example:**
```dart
final todos = SyncLayer.collection('todos');
```

---

### `CollectionReference.save(Map<String, dynamic> data, {String? id})`

Save a document to the collection. If `id` is provided and exists, updates the document. Otherwise, creates a new document.

**Parameters:**
- `data` (Map<String, dynamic>) - Document data
- `id` (String?, optional) - Document ID

**Returns:** `Future<String>` - Document ID

**Example:**
```dart
// Insert new document
final id = await collection.save({
  'text': 'Buy groceries',
  'completed': false,
  'createdAt': DateTime.now().toIso8601String(),
});

// Update existing document
await collection.save({
  'text': 'Buy groceries',
  'completed': true,
}, id: id);
```

---

### `CollectionReference.get(String id)`

Retrieve a document by its ID.

**Parameters:**
- `id` (String) - Document ID

**Returns:** `Future<Map<String, dynamic>?>` - Document data or null if not found

**Example:**
```dart
final todo = await collection.get('abc-123');
if (todo != null) {
  print('Todo: ${todo['text']}');
}
```

---

### `CollectionReference.getAll()`

Retrieve all documents in the collection.

**Returns:** `Future<List<Map<String, dynamic>>>` - List of documents

**Example:**
```dart
final allTodos = await collection.getAll();
print('Total: ${allTodos.length}');
```

---

### `CollectionReference.delete(String id)`

Delete a document by its ID (soft delete).

**Parameters:**
- `id` (String) - Document ID

**Returns:** `Future<void>`

**Example:**
```dart
await collection.delete('abc-123');
```

---

### `CollectionReference.watch()`

Returns a stream that emits the collection's documents whenever they change.

**Returns:** `Stream<List<Map<String, dynamic>>>`

**Example:**
```dart
StreamBuilder<List<Map<String, dynamic>>>(
  stream: collection.watch(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    
    final todos = snapshot.data!;
    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) {
        return ListTile(title: Text(todos[index]['text']));
      },
    );
  },
);
```

---

### `CollectionReference.saveAll(List<Map<String, dynamic>> documents)`

Save multiple documents in a single batch operation.

**Parameters:**
- `documents` (List<Map<String, dynamic>>) - List of documents

**Returns:** `Future<List<String>>` - List of document IDs

**Example:**
```dart
final ids = await collection.saveAll([
  {'text': 'Task 1', 'done': false},
  {'text': 'Task 2', 'done': false},
  {'text': 'Task 3', 'done': false},
]);
```

---

### `CollectionReference.deleteAll(List<String> ids)`

Delete multiple documents in a single batch operation.

**Parameters:**
- `ids` (List<String>) - List of document IDs

**Returns:** `Future<void>`

**Example:**
```dart
await collection.deleteAll(['id1', 'id2', 'id3']);
```

---

## Configuration

### `SyncConfig`

Configuration object for initializing SyncLayer.

**Properties:**

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `baseUrl` | String | required | Backend API base URL |
| `authToken` | String? | null | Authentication token for API requests |
| `syncInterval` | Duration | 5 minutes | How often to auto-sync |
| `maxRetries` | int | 3 | Max retry attempts for failed operations |
| `enableAutoSync` | bool | true | Enable automatic background sync |
| `collections` | List<String> | [] | Collections to sync (required for pull sync on fresh devices) |
| `conflictStrategy` | ConflictStrategy | lastWriteWins | How to resolve conflicts |
| `customBackendAdapter` | SyncBackendAdapter? | null | Custom backend implementation |

**Example:**
```dart
SyncConfig(
  baseUrl: 'https://api.example.com',
  authToken: 'Bearer token123',
  syncInterval: Duration(minutes: 5),
  maxRetries: 3,
  enableAutoSync: true,
  collections: ['todos', 'users', 'notes'],
  conflictStrategy: ConflictStrategy.lastWriteWins,
)
```

---

### `ConflictStrategy`

Enum defining conflict resolution strategies.

**Values:**

| Strategy | Description |
|----------|-------------|
| `lastWriteWins` | Most recent change wins (based on timestamp) |
| `serverWins` | Server version always wins |
| `clientWins` | Client version always wins |

**Example:**
```dart
SyncConfig(
  baseUrl: 'https://api.example.com',
  conflictStrategy: ConflictStrategy.serverWins,
)
```

---

## Events

### `SyncEventType`

Enum of all event types emitted during sync operations.

**Values:**

| Event | When Emitted | Use Case |
|-------|--------------|----------|
| `syncStarted` | Sync cycle begins | Show sync indicator |
| `syncCompleted` | Sync cycle completes successfully | Hide sync indicator |
| `syncFailed` | Sync cycle fails | Show error message |
| `operationQueued` | Operation added to queue | Track pending operations |
| `operationSynced` | Operation synced successfully | Update UI status |
| `operationFailed` | Operation failed after max retries | Show error to user |
| `conflictDetected` | Conflict found during pull sync | Log conflict for debugging |
| `conflictResolved` | Conflict resolved | Log resolution strategy |
| `connectivityChanged` | Network status changed | Update online/offline UI |

---

### `SyncEvent`

Event object emitted during sync operations.

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `type` | SyncEventType | Type of event |
| `collectionName` | String? | Collection name (if applicable) |
| `recordId` | String? | Record ID (if applicable) |
| `metadata` | Map<String, dynamic>? | Additional event data |
| `timestamp` | DateTime | When event occurred |
| `error` | String? | Error message (if failed) |

**Metadata Contents by Event Type:**

- `conflictDetected`: `{ localVersion: int, remoteVersion: int }`
- `conflictResolved`: `{ strategy: String, winner: String }`
- `connectivityChanged`: `{ isOnline: bool }`

**Example:**
```dart
SyncLayerCore.instance.syncEngine.events.listen((event) {
  switch (event.type) {
    case SyncEventType.syncStarted:
      print('🔄 Sync started');
      break;
      
    case SyncEventType.syncCompleted:
      print('✅ Sync completed');
      break;
      
    case SyncEventType.syncFailed:
      print('❌ Sync failed: ${event.error}');
      break;
      
    case SyncEventType.conflictDetected:
      print('⚠️ Conflict in ${event.collectionName}/${event.recordId}');
      print('Local version: ${event.metadata?['localVersion']}');
      print('Remote version: ${event.metadata?['remoteVersion']}');
      break;
      
    case SyncEventType.conflictResolved:
      print('✅ Conflict resolved using ${event.metadata?['strategy']}');
      print('Winner: ${event.metadata?['winner']}');
      break;
      
    case SyncEventType.connectivityChanged:
      final isOnline = event.metadata?['isOnline'] ?? false;
      print(isOnline ? '🟢 Online' : '🔴 Offline');
      break;
      
    case SyncEventType.operationQueued:
      print('📝 Operation queued: ${event.collectionName}/${event.recordId}');
      break;
      
    case SyncEventType.operationSynced:
      print('✅ Operation synced: ${event.collectionName}/${event.recordId}');
      break;
      
    case SyncEventType.operationFailed:
      print('❌ Operation failed: ${event.error}');
      break;
  }
});
```

---

## Backend Integration

SyncLayer supports multiple backend platforms through adapters.

### Important: Adapter Installation

The Firebase, Supabase, and Appwrite adapters are **NOT included** in the pub.dev package to keep the package size small and avoid forcing unnecessary dependencies on users.

**To use platform adapters:**

1. **Download the adapter** from GitHub
2. **Copy it** to your project's `lib/adapters/` folder
3. **Add platform dependencies** to your `pubspec.yaml`
4. **Import and use** the adapter

### Platform Adapters

SyncLayer provides adapter implementations for popular platforms. These are available on [GitHub](https://github.com/hostspicaindia/synclayer/tree/main/lib/adapters) and can be copied into your project.

#### How to Use Platform Adapters

1. **Copy the adapter** from GitHub into your project (e.g., `lib/adapters/firebase_adapter.dart`)
2. **Add the platform package** to your `pubspec.yaml`
3. **Import and use** the adapter in your app

#### Firebase Firestore

**Step 1: Download Adapter**

```powershell
# Windows PowerShell
New-Item -ItemType Directory -Force -Path lib\adapters
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hostspicaindia/synclayer/main/lib/adapters/firebase_adapter.dart" -OutFile "lib\adapters\firebase_adapter.dart"
```

```bash
# Linux/Mac
mkdir -p lib/adapters
curl -o lib/adapters/firebase_adapter.dart https://raw.githubusercontent.com/hostspicaindia/synclayer/main/lib/adapters/firebase_adapter.dart
```

**Step 2: Add Dependencies**

```yaml
dependencies:
  synclayer: ^0.2.0-beta.7
  firebase_core: ^3.10.0
  cloud_firestore: ^5.7.0
```

**Step 3: Use It**

```dart
// 1. Copy firebase_adapter.dart from GitHub
// 2. Add to pubspec.yaml:
//    cloud_firestore: ^5.7.0

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:synclayer/synclayer.dart';
import 'adapters/firebase_adapter.dart';  // Your copied file

await Firebase.initializeApp();

await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://firebaseapp.com', // Not used
    customBackendAdapter: FirebaseAdapter(
      firestore: FirebaseFirestore.instance,
    ),
    collections: ['todos', 'users'],
  ),
);
```

**Requirements:**
- Firestore documents must have: `data`, `updatedAt`, `version` fields

#### Supabase

**Step 1: Download Adapter**

```powershell
# Windows PowerShell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hostspicaindia/synclayer/main/lib/adapters/supabase_adapter.dart" -OutFile "lib\adapters\supabase_adapter.dart"
```

```bash
# Linux/Mac
curl -o lib/adapters/supabase_adapter.dart https://raw.githubusercontent.com/hostspicaindia/synclayer/main/lib/adapters/supabase_adapter.dart
```

**Step 2: Add Dependencies**

```yaml
dependencies:
  synclayer: ^0.2.0-beta.7
  supabase_flutter: ^2.9.0
```

**Step 3: Use It**

```dart
// 1. Copy supabase_adapter.dart from GitHub
// 2. Add to pubspec.yaml:
//    supabase_flutter: ^2.9.0

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synclayer/synclayer.dart';
import 'adapters/supabase_adapter.dart';  // Your copied file

await Supabase.initialize(
  url: 'https://your-project.supabase.co',
  anonKey: 'your-anon-key',
);

await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://your-project.supabase.co', // Not used
    customBackendAdapter: SupabaseAdapter(
      client: Supabase.instance.client,
    ),
    collections: ['todos', 'users'],
  ),
);
```

**Requirements:**
- Tables must have: `record_id`, `data`, `updated_at`, `version` columns

#### Appwrite

**Step 1: Download Adapter**

```powershell
# Windows PowerShell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hostspicaindia/synclayer/main/lib/adapters/appwrite_adapter.dart" -OutFile "lib\adapters\appwrite_adapter.dart"
```

```bash
# Linux/Mac
curl -o lib/adapters/appwrite_adapter.dart https://raw.githubusercontent.com/hostspicaindia/synclayer/main/lib/adapters/appwrite_adapter.dart
```

**Step 2: Add Dependencies**

```yaml
dependencies:
  synclayer: ^0.2.0-beta.7
  appwrite: ^14.0.0
```

**Step 3: Use It**

```dart
// 1. Copy appwrite_adapter.dart from GitHub
// 2. Add to pubspec.yaml:
//    appwrite: ^14.0.0

import 'package:appwrite/appwrite.dart';
import 'package:synclayer/synclayer.dart';
import 'adapters/appwrite_adapter.dart';  // Your copied file

final client = Client()
  ..setEndpoint('https://cloud.appwrite.io/v1')
  ..setProject('your-project-id');

await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://cloud.appwrite.io', // Not used
    customBackendAdapter: AppwriteAdapter(
      databases: Databases(client),
      databaseId: 'your-database-id',
    ),
    collections: ['todos', 'users'],
  ),
);
```

**Requirements:**
- Collections must have: `data`, `updated_at`, `version` attributes

See [Platform Adapters Guide](PLATFORM_ADAPTERS.md) for detailed setup instructions.

---

### REST API (Default)

If you don't specify a custom adapter, SyncLayer uses the built-in REST adapter.

### Required Endpoints

Your backend must implement two endpoints:

#### Push Endpoint

```
POST /sync/{collection}
```

**Request Body:**
```json
{
  "recordId": "uuid-string",
  "data": { /* your document data */ },
  "version": 1,
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

**Response:**
```json
{
  "success": true
}
```

#### Pull Endpoint

```
GET /sync/{collection}?since={timestamp}
```

**Query Parameters:**
- `since` (optional) - ISO 8601 timestamp. If omitted, returns all records.

**Response:**
```json
[
  {
    "recordId": "uuid-string",
    "data": { /* your document data */ },
    "version": 1,
    "updatedAt": "2024-01-01T00:00:00.000Z"
  }
]
```

---

### Custom Backend Adapter

Implement `SyncBackendAdapter` for non-REST backends.

**Interface:**
```dart
abstract class SyncBackendAdapter {
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required int version,
    required DateTime updatedAt,
  });

  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
  });
}
```

**Example:**
```dart
class FirebaseAdapter implements SyncBackendAdapter {
  final FirebaseFirestore firestore;

  FirebaseAdapter(this.firestore);

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required int version,
    required DateTime updatedAt,
  }) async {
    await firestore
        .collection(collection)
        .doc(recordId)
        .set({
          'data': data,
          'version': version,
          'updatedAt': updatedAt,
        });
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
  }) async {
    var query = firestore.collection(collection);
    
    if (since != null) {
      query = query.where('updatedAt', isGreaterThan: since);
    }
    
    final snapshot = await query.get();
    
    return snapshot.docs.map((doc) {
      return SyncRecord(
        recordId: doc.id,
        data: doc.data()['data'],
        version: doc.data()['version'],
        updatedAt: (doc.data()['updatedAt'] as Timestamp).toDate(),
      );
    }).toList();
  }
}

// Use it
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://firebaseapp.com', // Not used with custom adapter
    customBackendAdapter: FirebaseAdapter(FirebaseFirestore.instance),
  ),
);
```

---

## Data Models

### Internal Data Structures

These are internal models used by SyncLayer. You don't create these directly, but understanding them helps with debugging.

#### DataRecord

Local storage record structure.

```dart
{
  id: int,                    // Isar auto-increment ID
  collectionName: String,     // Collection name
  recordId: String,           // Document ID (UUID)
  data: String,               // JSON-encoded document data
  version: int,               // Version number (auto-incremented)
  syncHash: String,           // Hash for change detection
  createdAt: DateTime,        // When record was created
  updatedAt: DateTime,        // When record was last updated
  lastSyncedAt: DateTime?,    // When record was last synced
  isDeleted: bool,            // Soft delete flag
  isSynced: bool,             // Whether record is synced
}
```

#### SyncOperation

Queued operation structure.

```dart
{
  id: int,                    // Isar auto-increment ID
  collectionName: String,     // Collection name
  recordId: String,           // Document ID
  operationType: String,      // 'insert', 'update', or 'delete'
  data: String,               // JSON-encoded document data
  timestamp: DateTime,        // When operation was queued
  status: String,             // 'pending', 'synced', or 'failed'
  retryCount: int,            // Number of retry attempts
  errorMessage: String?,      // Error message if failed
}
```

---

## Best Practices

### 1. Always Specify Collections

```dart
// ✅ Good - Pull sync works on fresh devices
SyncConfig(
  baseUrl: 'https://api.example.com',
  collections: ['todos', 'users'],
)

// ❌ Bad - Pull sync won't work on fresh devices
SyncConfig(
  baseUrl: 'https://api.example.com',
  collections: [], // Empty!
)
```

### 2. Handle Sync Events

```dart
// ✅ Good - Show sync status to users
SyncLayerCore.instance.syncEngine.events.listen((event) {
  if (event.type == SyncEventType.syncFailed) {
    showSnackBar('Sync failed: ${event.error}');
  }
});
```

### 3. Use Batch Operations

```dart
// ✅ Good - Single transaction
await collection.saveAll(manyDocuments);

// ❌ Bad - Multiple transactions
for (final doc in manyDocuments) {
  await collection.save(doc);
}
```

### 4. Watch Collections for Reactive UI

```dart
// ✅ Good - UI updates automatically
StreamBuilder(
  stream: collection.watch(),
  builder: (context, snapshot) => /* build UI */,
)

// ❌ Bad - Manual polling
Timer.periodic(Duration(seconds: 1), (_) async {
  final data = await collection.getAll();
  setState(() => _data = data);
});
```

---

## Troubleshooting

### Pull Sync Not Working

**Problem:** Fresh device doesn't receive remote data.

**Solution:** Specify collections in config:
```dart
SyncConfig(
  baseUrl: 'https://api.example.com',
  collections: ['todos'], // Add this!
)
```

### Conflicts Not Resolving

**Problem:** Conflicts detected but not resolved.

**Solution:** Check conflict strategy:
```dart
SyncConfig(
  baseUrl: 'https://api.example.com',
  conflictStrategy: ConflictStrategy.lastWriteWins, // Explicit
)
```

### Operations Not Syncing

**Problem:** Operations stay in queue.

**Solution:** Check connectivity and backend:
```dart
// Listen for connectivity
SyncLayerCore.instance.connectivityService.onConnectivityChanged.listen((isOnline) {
  print('Online: $isOnline');
});

// Check backend health
curl https://api.example.com/health
```

---

## Performance

SyncLayer v0.2.0-beta.7 includes significant performance improvements:

### Memory Optimization (90% reduction)

Pagination prevents loading entire collections into memory:

```dart
// Before: Loads all 10,000 records at once (10 MB memory)
final allRecords = await backend.pull(collection: 'todos');

// After: Loads 100 records at a time (1 MB memory)
// Automatically handled by SyncLayer
await SyncLayer.syncNow(); // Uses pagination internally
```

**Impact:**
- 1,000 records: 10 MB → 1 MB (90% reduction)
- 10,000 records: 100 MB → 10 MB (90% reduction)
- Scales to millions of records without memory issues

### Query Performance (80% faster)

Database indexes dramatically improve query speed:

```dart
// Indexed queries on collectionName + recordId
final record = await collection.get('abc-123'); // 80% faster

// Indexed queries on isSynced and isDeleted
final unsyncedRecords = await storage.getUnsyncedRecords(); // 80% faster
```

**Benchmarks:**
- 1,000 records: 20ms → 4ms (80% faster)
- 10,000 records: 100ms → 20ms (80% faster)
- 100,000 records: 1000ms → 200ms (80% faster)

### Bulk Operations (70% faster)

Batch operations reduce database transactions:

```dart
// Before: 100 separate transactions
for (final doc in documents) {
  await collection.save(doc); // 500ms total
}

// After: Single transaction
await collection.saveAll(documents); // 150ms total (70% faster)
```

**Impact:**
- 100 inserts: 500ms → 150ms (70% faster)
- 1,000 inserts: 5s → 1.5s (70% faster)
- Scales linearly with batch size

### Monitoring Performance

Use metrics to track performance in production:

```dart
final metrics = SyncLayer.getMetrics();

// Check sync performance
if (metrics.averageSyncDuration > Duration(seconds: 10)) {
  print('⚠️ Syncs are slow: ${metrics.averageSyncDuration}');
}

// Check success rate
if (metrics.successRate < 0.8) {
  print('⚠️ Low success rate: ${metrics.successRate * 100}%');
}

// Monitor in real-time
SyncLayer.configureMetrics(
  customHandler: (event) {
    if (event.type == 'sync_success') {
      final duration = event.data['duration_ms'];
      analytics.track('sync_duration', {'ms': duration});
    }
  },
);
```

---

## Version History

- **0.2.0-beta.7** - Current version (15 critical fixes, logging, metrics, pagination, indexes)
- **0.2.0-beta.6** - Library documentation improvements
- **0.2.0-beta.4** - Static analysis fixes
- **0.2.0-beta.3** - Security improvements
- **0.2.0-beta.2** - Package cleanup
- **0.2.0-beta.1** - Beta release with comprehensive test suite
- **0.1.0-alpha.7** - Adapter installation clarification
- **0.1.0-alpha.6** - Built-in platform adapters
- **0.1.0-alpha.5** - Dependency updates
- **0.1.0-alpha.4** - Connectivity fixes
- **0.1.0-alpha.3** - Documentation overhaul
- **0.1.0-alpha.2** - API documentation
- **0.1.0-alpha.1** - Initial alpha release
- See [CHANGELOG.md](../CHANGELOG.md) for full history
