# SyncLayer SDK - Complete Context Document

**Version:** 0.2.0-beta.5  
**Status:** Production Ready (Beta)  
**Platform:** Flutter  
**License:** MIT  
**Publisher:** HostSpica (hostspica.com)  
**Last Updated:** February 15, 2026

---

## Table of Contents
1. [Overview](#overview)
2. [Key Features](#key-features)
3. [Technical Architecture](#technical-architecture)
4. [Installation & Setup](#installation--setup)
5. [API Reference](#api-reference)
6. [Code Examples](#code-examples)
7. [Backend Adapters](#backend-adapters)
8. [Configuration Options](#configuration-options)
9. [Event System](#event-system)
10. [Conflict Resolution](#conflict-resolution)
11. [Performance Metrics](#performance-metrics)
12. [Testing](#testing)
13. [Package Information](#package-information)
14. [Links & Resources](#links--resources)

---

## Overview

SyncLayer is an enterprise-grade local-first sync engine for Flutter applications. It provides automatic synchronization, conflict resolution, and real-time updates with a clean, type-safe API.

### What Problem Does It Solve?
Building offline-first applications is challenging. Developers need to handle:
- Local data storage
- Network synchronization
- Conflict resolution
- Queue management
- Error handling
- Connectivity detection

SyncLayer solves all of these problems with a single, unified SDK.

### Core Philosophy
- **Offline-First**: Your app works perfectly without internet
- **Automatic Sync**: Data syncs automatically when online
- **Backend Agnostic**: Works with any backend (REST, Firebase, Supabase, custom)
- **Type-Safe**: Full Dart type safety
- **Production Ready**: Battle-tested with comprehensive test coverage

---

## Key Features

### 1. Offline-First Architecture
- All data stored locally using Isar database
- App works perfectly without internet connection
- Automatic queue management for pending operations

### 2. Automatic Synchronization
- Background sync when device comes online
- Configurable sync intervals
- Manual sync trigger available
- Intelligent retry with exponential backoff

### 3. Conflict Resolution
Three built-in strategies:
- **Last Write Wins**: Most recent modification takes precedence
- **Server Wins**: Server data always overrides local changes
- **Client Wins**: Local changes always take precedence

### 4. Event-Driven System
Comprehensive event system for monitoring:
- Sync started/completed/failed
- Conflict detected
- Connectivity changed
- Operation queued/processed

### 5. Backend Agnostic
Built-in adapters for:
- REST APIs
- Firebase Firestore
- Supabase
- Appwrite
- Custom backends (via adapter pattern)

### 6. Type-Safe API
- Full Dart type safety
- Compile-time error checking
- IntelliSense support

---

## Technical Architecture

### Three-Layer Architecture

```
┌─────────────────────────────────────┐
│         Application Layer           │
│    (Your Flutter Application)       │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│          SyncLayer SDK              │
│  ┌─────────────────────────────┐   │
│  │   Collection Manager        │   │
│  │   (CRUD Operations)         │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │   Sync Engine               │   │
│  │   - Event System            │   │
│  │   - Conflict Resolution     │   │
│  │   - Queue Management        │   │
│  │   - Retry Logic             │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │   Local Storage (Isar)      │   │
│  │   - Offline Queue           │   │
│  │   - Version Tracking        │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│       Backend Adapters              │
│  - REST API                         │
│  - Firebase                         │
│  - Supabase                         │
│  - Appwrite                         │
│  - Custom                           │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│         Your Backend                │
└─────────────────────────────────────┘
```

### Data Flow

1. **Local Operation**: User performs CRUD operation
2. **Immediate Storage**: Data saved to Isar database instantly
3. **Queue Addition**: Operation added to sync queue if online
4. **Backend Sync**: Queue processed and synced to backend
5. **Conflict Check**: Version comparison and conflict resolution
6. **Update Local**: Local database updated with resolved data

---

## Installation & Setup

### Step 1: Add Dependency

```yaml
# pubspec.yaml
dependencies:
  synclayer: ^0.2.0-beta.5
```

### Step 2: Install

```bash
flutter pub get
```

### Step 3: Initialize

```dart
import 'package:synclayer/synclayer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['todos', 'users'],
      conflictStrategy: ConflictStrategy.lastWriteWins,
    ),
  );
  
  runApp(MyApp());
}
```

---

## API Reference

### SyncLayer Class

Main entry point for the SDK.

#### Methods

**init(SyncConfig config)**
```dart
static Future<void> init(SyncConfig config)
```
Initialize SyncLayer with configuration.

**collection(String name)**
```dart
static CollectionManager collection(String name)
```
Get a collection manager for CRUD operations.

**syncNow()**
```dart
static Future<void> syncNow()
```
Trigger immediate synchronization.

**events**
```dart
static Stream<SyncEvent> get events
```
Stream of sync events for monitoring.

**dispose()**
```dart
static Future<void> dispose()
```
Clean up resources and close connections.

---

### CollectionManager Class

Manages CRUD operations for a specific collection.

#### Methods

**save(Map<String, dynamic> data, {String? id})**
```dart
Future<String> save(Map<String, dynamic> data, {String? id})
```
Save or update a document. Returns document ID.

**get(String id)**
```dart
Future<Map<String, dynamic>?> get(String id)
```
Retrieve a document by ID.

**getAll()**
```dart
Future<List<Map<String, dynamic>>> getAll()
```
Retrieve all documents in collection.

**delete(String id)**
```dart
Future<void> delete(String id)
```
Delete a document by ID.

**watch()**
```dart
Stream<List<Map<String, dynamic>>> watch()
```
Watch for real-time changes in the collection.

---

### SyncConfig Class

Configuration object for initializing SyncLayer.

#### Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| baseUrl | String? | No* | null | Base URL for REST API |
| collections | List<String> | Yes | - | List of collection names |
| conflictStrategy | ConflictStrategy | No | lastWriteWins | Conflict resolution strategy |
| syncInterval | Duration | No | 30 seconds | Automatic sync interval |
| maxRetries | int | No | 3 | Maximum retry attempts |
| retryDelay | Duration | No | 2 seconds | Delay between retries |
| customBackendAdapter | BackendAdapter? | No | null | Custom backend adapter |
| authToken | String? | No | null | Authentication token |

*Required if no customBackendAdapter is provided

---

## Code Examples

### Basic CRUD Operations

```dart
// Create
final id = await SyncLayer
  .collection('todos')
  .save({'text': 'Buy milk', 'done': false});

// Read
final todo = await SyncLayer
  .collection('todos')
  .get(id);

// Update
await SyncLayer
  .collection('todos')
  .save({'done': true}, id: id);

// Delete
await SyncLayer
  .collection('todos')
  .delete(id);
```

### Real-Time Updates

```dart
SyncLayer
  .collection('todos')
  .watch()
  .listen((todos) {
    print('Todos updated: ${todos.length} items');
    // Update your UI
  });
```

### Manual Sync

```dart
await SyncLayer.syncNow();
```

### Event Monitoring

```dart
SyncLayer.events.listen((event) {
  if (event is SyncStartedEvent) {
    print('Sync started at ${event.timestamp}');
  } else if (event is SyncCompletedEvent) {
    print('Sync completed: ${event.itemsSynced} items');
  } else if (event is SyncErrorEvent) {
    print('Sync error: ${event.error}');
  } else if (event is ConflictDetectedEvent) {
    print('Conflict in ${event.collection}: ${event.entityId}');
  } else if (event is ConnectivityChangedEvent) {
    if (event.isOnline) {
      print('Back online - syncing...');
      SyncLayer.syncNow();
    } else {
      print('Offline mode');
    }
  }
});
```

### Complete Todo App Example

```dart
import 'package:flutter/material.dart';
import 'package:synclayer/synclayer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['todos'],
      conflictStrategy: ConflictStrategy.lastWriteWins,
    ),
  );
  
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Todos'),
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
                leading: Checkbox(
                  value: todo['done'] ?? false,
                  onChanged: (value) async {
                    await SyncLayer.collection('todos').save(
                      {'done': value},
                      id: todo['id'],
                    );
                  },
                ),
                title: Text(todo['text'] ?? ''),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    await SyncLayer.collection('todos').delete(todo['id']);
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
          controller: _textController,
          decoration: InputDecoration(hintText: 'Enter todo text'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_textController.text.isNotEmpty) {
                await SyncLayer.collection('todos').save({
                  'text': _textController.text,
                  'done': false,
                });
                _textController.clear();
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}
```

---

## Backend Adapters

### REST API Adapter (Default)

```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['todos'],
    authToken: 'your-auth-token',
  ),
);
```

### Firebase Adapter

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:synclayer/adapters/firebase_adapter.dart';

await Firebase.initializeApp();

await SyncLayer.init(
  SyncConfig(
    collections: ['todos'],
    customBackendAdapter: FirebaseAdapter(
      firestore: FirebaseFirestore.instance,
    ),
  ),
);
```

### Supabase Adapter

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synclayer/adapters/supabase_adapter.dart';

await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);

await SyncLayer.init(
  SyncConfig(
    collections: ['todos'],
    customBackendAdapter: SupabaseAdapter(
      client: Supabase.instance.client,
    ),
  ),
);
```

### Appwrite Adapter

```dart
import 'package:synclayer/adapters/appwrite_adapter.dart';

await SyncLayer.init(
  SyncConfig(
    collections: ['todos'],
    customBackendAdapter: AppwriteAdapter(
      databases: databases,
      databaseId: 'your-database-id',
    ),
  ),
);
```

### Custom Adapter

```dart
import 'package:synclayer/core/backend_adapter.dart';
import 'package:dio/dio.dart';

class CustomBackendAdapter implements BackendAdapter {
  final Dio _dio;

  CustomBackendAdapter({required String baseUrl})
      : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  @override
  Future<Map<String, dynamic>> pull(
    String collection,
    DateTime? lastSync,
  ) async {
    final response = await _dio.get(
      '/$collection/sync',
      queryParameters: lastSync != null
          ? {'since': lastSync.toIso8601String()}
          : null,
    );
    return response.data;
  }

  @override
  Future<void> push(
    String collection,
    List<Map<String, dynamic>> changes,
  ) async {
    await _dio.post(
      '/$collection/sync',
      data: {'changes': changes},
    );
  }

  @override
  Future<void> delete(String collection, String id) async {
    await _dio.delete('/$collection/$id');
  }

  @override
  Future<void> updateAuthToken(String token) async {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
}
```

---

## Configuration Options

### Conflict Resolution Strategies

#### Last Write Wins (Default)
```dart
conflictStrategy: ConflictStrategy.lastWriteWins
```
- Most recent modification (by timestamp) takes precedence
- Best for: Simple apps, single-user scenarios
- Pros: Simple, predictable
- Cons: May lose data in concurrent edits

#### Server Wins
```dart
conflictStrategy: ConflictStrategy.serverWins
```
- Server data always overrides local changes
- Best for: Read-heavy apps, authoritative server
- Pros: Server is source of truth
- Cons: Local changes may be lost

#### Client Wins
```dart
conflictStrategy: ConflictStrategy.clientWins
```
- Local changes always override server data
- Best for: Offline-first apps, user autonomy
- Pros: User changes preserved
- Cons: May conflict with server state

### Sync Configuration

```dart
SyncConfig(
  // Sync every 30 seconds (default)
  syncInterval: Duration(seconds: 30),
  
  // Retry failed operations 3 times (default)
  maxRetries: 3,
  
  // Wait 2 seconds between retries (default)
  retryDelay: Duration(seconds: 2),
)
```

---

## Event System

### Event Types

#### SyncStartedEvent
Emitted when sync process starts.
```dart
class SyncStartedEvent {
  final DateTime timestamp;
}
```

#### SyncCompletedEvent
Emitted when sync completes successfully.
```dart
class SyncCompletedEvent {
  final DateTime timestamp;
  final int itemsSynced;
}
```

#### SyncErrorEvent
Emitted when sync encounters an error.
```dart
class SyncErrorEvent {
  final DateTime timestamp;
  final dynamic error;
  final StackTrace? stackTrace;
}
```

#### ConflictDetectedEvent
Emitted when a conflict is detected.
```dart
class ConflictDetectedEvent {
  final DateTime timestamp;
  final String collection;
  final String entityId;
}
```

#### ConnectivityChangedEvent
Emitted when network connectivity changes.
```dart
class ConnectivityChangedEvent {
  final DateTime timestamp;
  final bool isOnline;
}
```

---

## Conflict Resolution

### How It Works

1. **Version Tracking**: Each document has a version number
2. **Hash Comparison**: Data integrity verified with hashes
3. **Timestamp Comparison**: Modification times compared
4. **Strategy Application**: Configured strategy applied
5. **Resolution**: Winning version saved to both local and server

### Example Conflict Scenario

```
Local:  {id: '1', text: 'Buy milk', version: 2, modified: 10:00}
Server: {id: '1', text: 'Buy bread', version: 2, modified: 10:05}

Strategy: Last Write Wins
Result:   Server wins (10:05 > 10:00)
Final:    {id: '1', text: 'Buy bread', version: 3, modified: 10:05}
```

---

## Performance Metrics

### Benchmarks (100 operations)

| Operation | Time | Notes |
|-----------|------|-------|
| Save 100 records | < 5s | Individual operations |
| Retrieve 100 records | < 1s | Batch queries |
| Delete 100 records | < 3s | Bulk operations |
| Sync 100 operations | < 10s | Full sync cycle |

### Database Performance

- **Query Speed**: < 1ms for indexed queries
- **Storage**: NoSQL flexibility with ACID compliance
- **Memory**: Zero-copy object access
- **Concurrency**: Thread-safe operations

---

## Testing

### Test Coverage

- **Total Tests**: 48
- **Unit Tests**: 24
- **Integration Tests**: 16
- **Performance Tests**: 8
- **Coverage**: Comprehensive

### Test Categories

1. **Conflict Resolver Tests** (100% passing)
   - Last write wins strategy
   - Server wins strategy
   - Client wins strategy
   - Version tracking
   - Hash validation

2. **Local Storage Tests** (Requires device/emulator)
   - CRUD operations
   - Query performance
   - Data persistence
   - Migration handling

3. **Queue Manager Tests** (Requires device/emulator)
   - Queue operations
   - Retry logic
   - Error handling
   - Priority management

4. **Integration Tests** (Requires device/emulator)
   - End-to-end sync flow
   - Multi-collection sync
   - Conflict resolution
   - Network scenarios

5. **Performance Tests** (Requires device/emulator)
   - Bulk operations
   - Query performance
   - Memory usage
   - Sync speed

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/conflict_resolver_test.dart

# Run with coverage
flutter test --coverage
```

---

## Package Information

### Pub.dev Details

- **Package Name**: synclayer
- **Version**: 0.2.0-beta.5
- **Pub Score**: 140/160
- **Package Size**: 312 KB
- **Platforms**: Android, iOS, Linux, macOS, Windows (5 platforms)
- **License**: MIT
- **Publisher**: hostspica.com

### Dependencies

```yaml
dependencies:
  flutter: sdk
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
  dio: ^5.9.1
  connectivity_plus: ^7.0.0
  path_provider: ^2.1.5
  uuid: ^4.5.2
  appwrite: ^21.3.0
  cloud_firestore: ^6.1.2
  supabase_flutter: ^2.12.0

dev_dependencies:
  flutter_test: sdk
  isar_generator: ^3.1.0+1
  build_runner: ^2.4.13
  flutter_lints: ^3.0.2
```

### Changelog

#### v0.2.0-beta.5 (February 15, 2026)
- Added comprehensive test suite (48 tests)
- Added performance benchmarks
- Made baseUrl optional with custom adapters
- Improved error handling
- Fixed conflict resolution edge cases
- Fixed memory leaks in event listeners
- Updated documentation

#### v0.2.0-beta.4 (February 10, 2026)
- Added Appwrite adapter
- Added event system for monitoring
- Added connectivity detection
- Improved sync performance

#### v0.2.0-beta.3 (February 5, 2026)
- Added Supabase adapter
- Added conflict resolution strategies
- Added version tracking
- Fixed Firebase adapter issues

#### v0.2.0-beta.2 (January 30, 2026)
- Added Firebase adapter
- Added automatic retry logic
- Added offline queue
- Refactored sync engine

#### v0.2.0-beta.1 (January 25, 2026)
- Initial beta release
- Core sync functionality
- Isar-based local storage
- REST API adapter

---

## Links & Resources

### Official Links
- **Website**: https://sdk.hostspica.com/flutter/synclayer
- **Documentation**: https://sdk.hostspica.com/docs
- **pub.dev**: https://pub.dev/packages/synclayer
- **GitHub**: https://github.com/hostspicaindia/synclayer
- **Issue Tracker**: https://github.com/hostspicaindia/synclayer/issues

### Documentation Pages
- **Quick Start**: https://sdk.hostspica.com/docs/quick-start
- **Architecture**: https://sdk.hostspica.com/docs/architecture
- **API Reference**: https://sdk.hostspica.com/docs/api
- **Code Examples**: https://sdk.hostspica.com/docs/examples

### Community
- **GitHub Discussions**: https://github.com/hostspicaindia/synclayer/discussions
- **Twitter**: https://twitter.com/hostspicaindia
- **LinkedIn**: https://linkedin.com/company/hostspicaindia

### Company
- **HostSpica**: https://hostspica.com
- **Contact**: https://sdk.hostspica.com/contact
- **About**: https://sdk.hostspica.com/about

---

## Best Practices

### 1. Initialize Early
Initialize SyncLayer in your app's main function before running the app.

### 2. Handle Events
Always listen to sync events for proper error handling and user feedback.

### 3. Use Watch Streams
Use `watch()` for real-time UI updates instead of polling.

### 4. Batch Operations
For multiple operations, perform them in sequence and sync once.

### 5. Test Offline Scenarios
Always test your app in offline mode to ensure proper behavior.

### 6. Choose Right Strategy
Select conflict resolution strategy based on your use case.

### 7. Monitor Performance
Use performance benchmarks to optimize your implementation.

### 8. Handle Errors Gracefully
Implement proper error handling for sync failures.

---

## Common Use Cases

### 1. Todo/Task Management Apps
- Offline task creation and editing
- Real-time sync across devices
- Conflict resolution for concurrent edits

### 2. Note-Taking Apps
- Offline note creation
- Automatic sync when online
- Version tracking for notes

### 3. Inventory Management
- Offline stock updates
- Real-time inventory sync
- Multi-location support

### 4. Field Service Apps
- Offline data collection
- Automatic sync when back online
- Reliable data persistence

### 5. Collaborative Apps
- Multi-user editing
- Conflict resolution
- Real-time updates

---

## Troubleshooting

### Common Issues

**Issue: Sync not working**
- Check internet connectivity
- Verify baseUrl is correct
- Check authentication token
- Review sync events for errors

**Issue: Conflicts not resolving**
- Verify conflict strategy is set
- Check version tracking is enabled
- Review conflict events

**Issue: Performance slow**
- Check number of documents
- Optimize queries with filters
- Review sync interval settings
- Consider batch operations

**Issue: Data not persisting**
- Verify Isar initialization
- Check storage permissions
- Review error logs

---

## Support

### Getting Help

1. **Documentation**: Check comprehensive docs at sdk.hostspica.com/docs
2. **Examples**: Review code examples in documentation
3. **GitHub Issues**: Report bugs or request features
4. **Discussions**: Ask questions in GitHub Discussions
5. **Contact**: Reach out via contact page

### Reporting Issues

When reporting issues, include:
- SyncLayer version
- Flutter version
- Platform (iOS/Android/etc.)
- Minimal reproduction code
- Error messages and logs
- Expected vs actual behavior

---

## License

MIT License - See LICENSE file for details

Copyright (c) 2026 HostSpica

---

## Credits

**Developed by**: HostSpica Team  
**Maintained by**: HostSpica  
**Contributors**: See GitHub contributors page

---

**End of Context Document**

*This document contains all essential information about SyncLayer SDK. Share it with team members, AI assistants, or anyone who needs to understand the SDK.*

*Last Updated: February 15, 2026*
