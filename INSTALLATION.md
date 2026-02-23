# SyncLayer Installation Guide

Complete guide to installing and setting up SyncLayer with your chosen database.

## Basic Installation

### Step 1: Add SyncLayer

Add to your `pubspec.yaml`:

```yaml
dependencies:
  synclayer: ^1.4.0
```

Run:
```bash
flutter pub get
```

### Step 2: Choose Your Database

SyncLayer supports 14+ databases. Pick one based on your needs:

## Database-Specific Installation

### 🔥 Firebase Firestore

**Best for:** Mobile apps, real-time features, Google ecosystem

```yaml
dependencies:
  synclayer: ^1.4.0
  cloud_firestore: ^6.1.2
```

**Usage:**
```dart
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: FirebaseAdapter(
      firestore: FirebaseFirestore.instance,
    ),
    collections: ['todos', 'users'],
  ),
);
```

---

### 🟢 Supabase

**Best for:** PostgreSQL with real-time, open-source Firebase alternative

```yaml
dependencies:
  synclayer: ^1.4.0
  supabase_flutter: ^2.12.0
```

**Usage:**
```dart
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: SupabaseAdapter(
      client: Supabase.instance.client,
    ),
    collections: ['todos', 'users'],
  ),
);
```

---

### 🐘 PostgreSQL

**Best for:** Complex queries, ACID compliance, relational data

```yaml
dependencies:
  synclayer: ^1.4.0
  postgres: ^3.0.0
```

**Database Setup:**
```sql
CREATE TABLE todos (
  record_id VARCHAR(255) PRIMARY KEY,
  data JSONB NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  version INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX idx_todos_updated_at ON todos(updated_at);
```

**Usage:**
```dart
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters.dart';
import 'package:postgres/postgres.dart';

final connection = await Connection.open(
  Endpoint(
    host: 'localhost',
    database: 'mydb',
    username: 'user',
    password: 'password',
  ),
);

await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: PostgresAdapter(connection: connection),
    collections: ['todos', 'users'],
  ),
);
```

---

### 🐬 MySQL

**Best for:** Traditional web apps, shared hosting

```yaml
dependencies:
  synclayer: ^1.4.0
  mysql1: ^0.20.0
```

**Database Setup:**
```sql
CREATE TABLE todos (
  record_id VARCHAR(255) PRIMARY KEY,
  data JSON NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  version INT NOT NULL DEFAULT 1,
  INDEX idx_updated_at (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

**Usage:**
```dart
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters.dart';
import 'package:mysql1/mysql1.dart';

final settings = ConnectionSettings(
  host: 'localhost',
  port: 3306,
  user: 'root',
  password: 'password',
  db: 'mydb',
);

final conn = await MySqlConnection.connect(settings);

await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: MySQLAdapter(connection: conn),
    collections: ['todos', 'users'],
  ),
);
```

---

### 🍃 MongoDB

**Best for:** Document storage, flexible schema, JSON data

```yaml
dependencies:
  synclayer: ^1.4.0
  mongo_dart: ^0.10.0
```

**Database Setup:**
```javascript
// Create indexes
db.todos.createIndex({ "record_id": 1 }, { unique: true })
db.todos.createIndex({ "updated_at": 1 })
```

**Usage:**
```dart
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters.dart';
import 'package:mongo_dart/mongo_dart.dart';

final db = await Db.create('mongodb://localhost:27017/mydb');
await db.open();

await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: MongoDBAdapter(db: db),
    collections: ['todos', 'users'],
  ),
);
```

---

### 📱 SQLite

**Best for:** Local/offline apps, no server needed

```yaml
dependencies:
  synclayer: ^1.4.0
  sqflite: ^2.3.0
```

**Usage:**
```dart
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters.dart';
import 'package:sqflite/sqflite.dart';

final db = await openDatabase(
  'sync_backend.db',
  version: 1,
  onCreate: (db, version) async {
    await db.execute('''
      CREATE TABLE todos (
        record_id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('CREATE INDEX idx_updated_at ON todos(updated_at)');
  },
);

await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: SQLiteAdapter(database: db),
    collections: ['todos', 'users'],
  ),
);
```

---

### 🔴 Redis

**Best for:** Caching, session storage, fast access

```yaml
dependencies:
  synclayer: ^1.4.0
  redis: ^3.1.0
```

**Usage:**
```dart
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters.dart';
import 'package:redis/redis.dart';

final conn = RedisConnection();
final command = await conn.connect('localhost', 6379);

await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: RedisAdapter(command: command),
    collections: ['todos', 'users'],
  ),
);
```

---

### ☁️ AWS DynamoDB

**Best for:** AWS ecosystem, serverless, auto-scaling

```yaml
dependencies:
  synclayer: ^1.4.0
  aws_dynamodb_api: ^2.0.0
```

**Usage:**
```dart
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters.dart';
import 'package:aws_dynamodb_api/dynamodb-2012-08-10.dart';

final dynamodb = DynamoDB(
  region: 'us-east-1',
  credentials: AwsClientCredentials(
    accessKey: 'YOUR_ACCESS_KEY',
    secretKey: 'YOUR_SECRET_KEY',
  ),
);

await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: DynamoDBAdapter(
      dynamodb: dynamodb,
      tablePrefix: 'synclayer_',
    ),
    collections: ['todos', 'users'],
  ),
);
```

---

### 🔷 GraphQL

**Best for:** Custom GraphQL APIs, flexible queries

```yaml
dependencies:
  synclayer: ^1.4.0
  graphql: ^5.1.0
```

**Usage:**
```dart
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters.dart';
import 'package:graphql/client.dart';

final httpLink = HttpLink('https://api.example.com/graphql');
final authLink = AuthLink(getToken: () async => 'Bearer YOUR_TOKEN');
final link = authLink.concat(httpLink);

final client = GraphQLClient(
  cache: GraphQLCache(),
  link: link,
);

await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: GraphQLAdapter(client: client),
    collections: ['todos', 'users'],
  ),
);
```

---

### 🌐 REST API (Default)

**Best for:** Any HTTP API, custom backends

**No extra package needed** - uses built-in `dio`

```dart
import 'package:synclayer/synclayer.dart';

await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    authToken: 'your-token',
    collections: ['todos', 'users'],
  ),
);
// Automatically uses RestBackendAdapter
```

---

## Complete Example

Here's a full example with PostgreSQL:

```dart
import 'package:flutter/material.dart';
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters.dart';
import 'package:postgres/postgres.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Connect to PostgreSQL
  final connection = await Connection.open(
    Endpoint(
      host: 'localhost',
      database: 'mydb',
      username: 'user',
      password: 'password',
    ),
  );

  // Initialize SyncLayer
  await SyncLayer.init(
    SyncConfig(
      customBackendAdapter: PostgresAdapter(connection: connection),
      collections: ['todos'],
      syncInterval: Duration(minutes: 5),
      enableAutoSync: true,
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TodoScreen(),
    );
  }
}

class TodoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Todos')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SyncLayer.collection('todos').watch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          final todos = snapshot.data!;
          return ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return ListTile(
                title: Text(todo['text']),
                trailing: Checkbox(
                  value: todo['done'] ?? false,
                  onChanged: (value) async {
                    await SyncLayer.collection('todos').save(
                      {'text': todo['text'], 'done': value},
                      id: todo['id'],
                    );
                  },
                ),
              );
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
    );
  }
}
```

## Troubleshooting

### Analyzer Errors in Adapter Files

If you see errors in adapter files you're not using, that's **normal and expected**. The adapters are optional and only work when their packages are installed.

**Solution:** Ignore errors in adapters you don't use, or add the package if you need that adapter.

### Import Errors

Make sure you import both the main package and adapters:

```dart
import 'package:synclayer/synclayer.dart';      // Core functionality
import 'package:synclayer/adapters.dart';       // Database adapters
```

### Connection Issues

- Verify database is running and accessible
- Check credentials (username, password, host, port)
- Ensure firewall allows connections
- Test connection outside of Flutter first

### Schema Errors

For SQL databases, ensure tables exist with correct schema:
```sql
-- Required columns
record_id VARCHAR(255) PRIMARY KEY
data JSON/JSONB NOT NULL
updated_at TIMESTAMP NOT NULL
version INTEGER NOT NULL DEFAULT 1

-- Required index
CREATE INDEX idx_updated_at ON your_table(updated_at);
```

## Next Steps

- Read the [Adapter Guide](lib/adapters/ADAPTER_GUIDE.md) for detailed setup
- Check [Database Support](DATABASE_SUPPORT.md) for comparison
- See [Examples](example/) for working code
- Visit [Documentation](https://pub.dev/packages/synclayer)

## Support

- [GitHub Issues](https://github.com/hostspicaindia/synclayer/issues)
- [Documentation](https://pub.dev/packages/synclayer)
- [Examples](https://github.com/hostspicaindia/synclayer/tree/main/example)
