# SyncLayer Architecture

## Overview

SyncLayer is built with a modular, extensible architecture following clean architecture principles and senior-level design patterns.

---

## Core Design Principles

### 1. Local-First Architecture
All write operations hit local storage first, ensuring:
- Instant UI updates (no network latency)
- Full offline capability
- Resilient user experience

### 2. Backend Agnostic
Uses adapter pattern to support multiple backends:
- REST APIs (default)
- Firebase (future)
- Supabase (future)
- GraphQL (future)
- Custom implementations

### 3. Event-Driven
Internal event bus for:
- Logging and debugging
- Analytics integration
- Plugin system
- Real-time monitoring

### 4. Conflict Resolution
Pluggable conflict resolution strategies:
- Last Write Wins (MVP)
- Server Wins
- Client Wins
- Custom strategies (future)

---

## Architecture Layers

```
┌─────────────────────────────────────────┐
│         Developer API Layer             │
│   (SyncLayer.collection().save())       │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         Core Initialization             │
│      (Lifecycle Management)             │
└─────────────────────────────────────────┘
                    ↓
┌──────────────┬──────────────┬───────────┐
│   Local      │    Sync      │  Network  │
│   Storage    │    Engine    │  Adapter  │
│   (Isar)     │   (Queue)    │  (REST)   │
└──────────────┴──────────────┴───────────┘
                    ↓
┌─────────────────────────────────────────┐
│         Utilities & Services            │
│  (Connectivity, Serializer, Events)     │
└─────────────────────────────────────────┘
```

---

## Module Breakdown

### 1. Developer API Layer (`lib/synclayer.dart`)

**Responsibility:** Simple, intuitive public API

**Key Classes:**
- `SyncLayer` - Main entry point
- `CollectionReference` - CRUD operations

**Design Pattern:** Facade pattern

**Example:**
```dart
await SyncLayer.init(config);
await SyncLayer.collection('messages').save(data);
```

---

### 2. Core Initialization (`lib/core/`)

**Responsibility:** Lifecycle management and dependency injection

**Key Classes:**
- `SyncLayerCore` - Singleton coordinator
- `SyncConfig` - Configuration object
- `SyncEvent` - Event bus messages

**Design Patterns:**
- Singleton pattern
- Dependency injection
- Observer pattern (event bus)

---

### 3. Local Storage Layer (`lib/local/`)

**Responsibility:** Data persistence and querying

**Key Classes:**
- `LocalStorage` - Isar database abstraction
- `DataRecord` - Document model with sync metadata
- `SyncOperation` - Queue operation model

**Features:**
- Reactive streams (watch queries)
- Soft deletes
- Sync metadata tracking (version, timestamp, hash)

**Sync Metadata:**
```dart
class DataRecord {
  int version;           // Version vector for conflict detection
  DateTime? lastSyncedAt; // Last successful sync
  String? syncHash;      // Hash for change detection
}
```

---

### 4. Sync Engine (`lib/sync/`)

**Responsibility:** Background synchronization orchestration

**Key Classes:**
- `SyncEngine` - Main sync coordinator
- `QueueManager` - Operation queue management

**Features:**
- Push sync (local → server)
- Pull sync (server → local) - prepared for future
- Automatic retry with exponential backoff
- Concurrency safety (prevents overlapping syncs)
- Event emission for monitoring

**Concurrency Safety:**
```dart
bool _isSyncing = false;

Future<void> _performSync() async {
  if (_isSyncing) return; // Prevent race conditions
  _isSyncing = true;
  try {
    await _pushSync();
    await _pullSync();
  } finally {
    _isSyncing = false;
  }
}
```

---

### 5. Network Layer (`lib/network/`)

**Responsibility:** Backend communication

**Key Classes:**
- `SyncBackendAdapter` - Abstract interface
- `RestBackendAdapter` - REST implementation
- `SyncRecord` - Backend data model

**Design Pattern:** Adapter pattern (Strategy pattern)

**Why This Matters:**
Decouples sync engine from specific backend:
```dart
// Easy to add new backends
class FirebaseBackendAdapter implements SyncBackendAdapter { }
class SupabaseBackendAdapter implements SyncBackendAdapter { }
class GraphQLBackendAdapter implements SyncBackendAdapter { }
```

**Usage:**
```dart
SyncConfig(
  customBackendAdapter: FirebaseBackendAdapter(),
)
```

---

### 6. Conflict Resolution (`lib/conflict/`)

**Responsibility:** Merge conflicting data

**Key Classes:**
- `ConflictResolver` - Resolution logic
- `ConflictStrategy` - Strategy enum

**Strategies:**
- Last Write Wins (timestamp comparison)
- Server Wins (always prefer remote)
- Client Wins (always prefer local)
- Custom (future: user-defined merge functions)

---

### 7. Utilities (`lib/utils/`)

**Responsibility:** Cross-cutting concerns

**Key Classes:**
- `ConnectivityService` - Network monitoring
- `DataSerializer` - Data transformation layer

**DataSerializer Benefits:**
- Encryption support (future)
- Compression (future)
- Schema validation (future)
- Format conversion (future)

---

## Data Flow

### Write Operation Flow

```
Developer calls save()
        ↓
CollectionReference.save()
        ↓
LocalStorage.saveData() ← Instant return
        ↓
QueueManager.queueInsert()
        ↓
SyncEngine (background)
        ↓
BackendAdapter.push()
        ↓
Server
```

### Sync Flow

```
Connectivity Change / Timer / Manual Trigger
        ↓
SyncEngine._performSync()
        ↓
Check _isSyncing (concurrency safety)
        ↓
_pushSync() → Send queued operations
        ↓
_pullSync() → Fetch remote changes (future)
        ↓
ConflictResolver.resolve() (if conflicts)
        ↓
LocalStorage.saveData() (merge)
        ↓
Emit SyncEvent
```

---

## Event System

Internal event bus for observability:

```dart
SyncLayer.syncEngine.events.listen((event) {
  switch (event.type) {
    case SyncEventType.syncStarted:
      print('Sync started');
    case SyncEventType.operationSynced:
      print('Operation synced: ${event.recordId}');
    case SyncEventType.conflictDetected:
      print('Conflict in ${event.collectionName}');
  }
});
```

**Event Types:**
- `syncStarted` / `syncCompleted` / `syncFailed`
- `operationQueued` / `operationSynced` / `operationFailed`
- `conflictDetected` / `conflictResolved`
- `connectivityChanged`

---

## Extensibility Points

### 1. Custom Backend Adapter
```dart
class MyCustomAdapter implements SyncBackendAdapter {
  @override
  Future<void> push(...) async {
    // Custom implementation
  }
}

SyncConfig(customBackendAdapter: MyCustomAdapter())
```

### 2. Custom Conflict Strategy
```dart
// Future enhancement
class CustomConflictResolver extends ConflictResolver {
  @override
  Map<String, dynamic> resolve(...) {
    // Custom merge logic
  }
}
```

### 3. Custom Serializer
```dart
class EncryptedSerializer implements DataSerializer {
  @override
  String serialize(Map<String, dynamic> data) {
    return encrypt(jsonEncode(data));
  }
}
```

### 4. Event Listeners
```dart
SyncLayer.syncEngine.events.listen((event) {
  // Custom logging, analytics, monitoring
});
```

---

## Scalability Considerations

### 1. Batch Operations
Future: Batch multiple operations into single network request

### 2. Incremental Sync
Pull sync uses `since` timestamp to fetch only changes

### 3. Pagination
Future: Handle large datasets with pagination

### 4. Background Processing
Uses Dart isolates for heavy operations (future)

---

## Security Considerations

### 1. Authentication
Bearer token support built-in

### 2. Encryption
Serializer layer prepared for encryption

### 3. Data Validation
Schema validation can be added to serializer

---

## Testing Strategy

### Unit Tests
- Individual module testing
- Mock dependencies

### Integration Tests
- Full sync flow testing
- Conflict resolution scenarios

### Stress Tests
- Large dataset sync
- Network interruption simulation
- Concurrent operation handling

---

## Performance Optimizations

### 1. Lazy Initialization
Components initialized only when needed

### 2. Connection Pooling
Dio HTTP client reuses connections

### 3. Indexed Queries
Isar database uses indexes for fast lookups

### 4. Reactive Streams
Efficient change propagation with Isar watchers

---

## Future Enhancements

### Phase 2
- Pull sync implementation
- Advanced conflict resolution
- Batch operations
- Encryption support

### Phase 3
- Multi-platform support (Web, Desktop)
- Real-time sync (WebSocket)
- Offline analytics
- Sync dashboard

### Phase 4
- Collaborative editing
- Operational transforms
- CRDT support
- P2P sync

---

## Comparison with Alternatives

| Feature | SyncLayer | Firebase | Supabase | WatermelonDB |
|---------|-----------|----------|----------|--------------|
| Local-First | ✅ | ❌ | ❌ | ✅ |
| Backend Agnostic | ✅ | ❌ | ❌ | ✅ |
| Offline Queue | ✅ | ✅ | ❌ | ✅ |
| Conflict Resolution | ✅ | ✅ | ❌ | ✅ |
| Simple API | ✅ | ✅ | ✅ | ⚠️ |
| Self-Hosted | ✅ | ❌ | ✅ | ✅ |

---

## Conclusion

SyncLayer's architecture is designed for:
- **Simplicity** - Easy developer experience
- **Extensibility** - Plugin-based architecture
- **Reliability** - Robust error handling
- **Performance** - Optimized for mobile
- **Future-Proof** - Modular design for growth

This is production-grade infrastructure, not a toy project.
