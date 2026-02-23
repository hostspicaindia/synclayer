# SyncLayer Quick Start

Get up and running with SyncLayer in 5 minutes.

## 1. Install

```yaml
dependencies:
  synclayer: ^1.4.0
  # Add your database package (example: PostgreSQL)
  postgres: ^3.0.0
```

```bash
flutter pub get
```

## 2. Initialize

```dart
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters.dart';
import 'package:postgres/postgres.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Connect to database
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

  runApp(MyApp());
}
```

## 3. Use It

### Save Data
```dart
final id = await SyncLayer.collection('todos').save({
  'text': 'Buy groceries',
  'done': false,
});
```

### Get Data
```dart
final todo = await SyncLayer.collection('todos').get(id);
print(todo['text']); // "Buy groceries"
```

### Watch for Changes (Real-time)
```dart
StreamBuilder<List<Map<String, dynamic>>>(
  stream: SyncLayer.collection('todos').watch(),
  builder: (context, snapshot) {
    final todos = snapshot.data ?? [];
    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, i) => Text(todos[i]['text']),
    );
  },
)
```

### Update Data
```dart
await SyncLayer.collection('todos').save(
  {'text': 'Buy groceries', 'done': true},
  id: id,
);
```

### Delete Data
```dart
await SyncLayer.collection('todos').delete(id);
```

### Manual Sync
```dart
await SyncLayer.syncNow();
```

## Database Quick Reference

| Database | Package | Import |
|----------|---------|--------|
| **PostgreSQL** | `postgres: ^3.0.0` | `import 'package:postgres/postgres.dart';` |
| **MySQL** | `mysql1: ^0.20.0` | `import 'package:mysql1/mysql1.dart';` |
| **MongoDB** | `mongo_dart: ^0.10.0` | `import 'package:mongo_dart/mongo_dart.dart';` |
| **Firebase** | `cloud_firestore: ^6.1.2` | `import 'package:cloud_firestore/cloud_firestore.dart';` |
| **Supabase** | `supabase_flutter: ^2.12.0` | `import 'package:supabase_flutter/supabase_flutter.dart';` |
| **SQLite** | `sqflite: ^2.3.0` | `import 'package:sqflite/sqflite.dart';` |
| **Redis** | `redis: ^3.1.0` | `import 'package:redis/redis.dart';` |
| **GraphQL** | `graphql: ^5.1.0` | `import 'package:graphql/client.dart';` |
| **REST API** | Built-in | No extra import needed |

## Adapter Examples

### Firebase
```dart
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
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    authToken: 'your-token',
    collections: ['todos'],
  ),
);
```

## Configuration Options

```dart
SyncConfig(
  // Required (unless using customBackendAdapter)
  baseUrl: 'https://api.example.com',
  
  // Optional
  authToken: 'your-auth-token',
  syncInterval: Duration(minutes: 5),
  maxRetries: 3,
  enableAutoSync: true,
  collections: ['todos', 'users'],
  conflictStrategy: ConflictStrategy.lastWriteWins,
  
  // Custom adapter (overrides baseUrl)
  customBackendAdapter: PostgresAdapter(...),
)
```

## Conflict Strategies

```dart
ConflictStrategy.lastWriteWins  // Most recent change wins (default)
ConflictStrategy.serverWins     // Server version always wins
ConflictStrategy.clientWins     // Client version always wins
```

## Features

✅ **Offline-first** - Data saved locally first (Isar)  
✅ **Auto-sync** - Background synchronization  
✅ **Real-time** - Reactive streams with `watch()`  
✅ **Conflict resolution** - Automatic conflict handling  
✅ **Type-safe** - Full Dart type safety  
✅ **14+ databases** - PostgreSQL, MySQL, MongoDB, Firebase, and more  

## SQL Database Setup

For SQL databases, create tables with this schema:

```sql
CREATE TABLE your_collection (
  record_id VARCHAR(255) PRIMARY KEY,
  data JSON/JSONB NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  version INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX idx_updated_at ON your_collection(updated_at);
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters.dart';
import 'package:postgres/postgres.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final conn = await Connection.open(
    Endpoint(host: 'localhost', database: 'mydb'),
  );

  await SyncLayer.init(
    SyncConfig(
      customBackendAdapter: PostgresAdapter(connection: conn),
      collections: ['todos'],
    ),
  );

  runApp(MaterialApp(home: TodoApp()));
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Todos')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SyncLayer.collection('todos').watch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, i) {
              final todo = snapshot.data![i];
              return CheckboxListTile(
                title: Text(todo['text']),
                value: todo['done'] ?? false,
                onChanged: (value) {
                  SyncLayer.collection('todos').save(
                    {...todo, 'done': value},
                    id: todo['id'],
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          SyncLayer.collection('todos').save({
            'text': 'New Todo',
            'done': false,
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
```

## Next Steps

- 📖 [Full Installation Guide](INSTALLATION.md)
- 🗄️ [Database Support](DATABASE_SUPPORT.md)
- 📚 [Adapter Guide](lib/adapters/ADAPTER_GUIDE.md)
- 💻 [Examples](example/)
- 📘 [API Documentation](https://pub.dev/packages/synclayer)

## Support

- [GitHub Issues](https://github.com/hostspicaindia/synclayer/issues)
- [Documentation](https://pub.dev/packages/synclayer)
