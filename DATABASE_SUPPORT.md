# SyncLayer Database Support

SyncLayer now supports 14+ database backends through its flexible adapter architecture.

## Supported Databases

### ✅ BaaS Platforms (3)
- **Firebase Firestore** - Google's NoSQL cloud database
- **Supabase** - Open-source Firebase alternative with PostgreSQL
- **Appwrite** - Self-hosted backend-as-a-service

### ✅ SQL Databases (4)
- **PostgreSQL** - Advanced open-source relational database
- **MySQL** - Popular open-source relational database
- **MariaDB** - MySQL fork with enhanced features
- **SQLite** - Embedded relational database

### ✅ NoSQL Databases (5)
- **MongoDB** - Document-oriented database
- **CouchDB** - Document database with built-in sync
- **Redis** - In-memory key-value store
- **DynamoDB** - AWS managed NoSQL database
- **Cassandra** - Distributed wide-column store

### ✅ API Protocols (2)
- **REST API** - Generic HTTP/REST backend (built-in)
- **GraphQL** - Flexible query language for APIs

## Quick Comparison

| Database | Type | Best For | Complexity |
|----------|------|----------|------------|
| Firebase | NoSQL | Mobile apps, real-time | Easy |
| Supabase | SQL | PostgreSQL + real-time | Easy |
| PostgreSQL | SQL | Complex queries, ACID | Medium |
| MySQL | SQL | Traditional web apps | Medium |
| MongoDB | NoSQL | Flexible schema, JSON | Easy |
| Redis | NoSQL | Caching, fast access | Easy |
| DynamoDB | NoSQL | AWS serverless | Medium |
| SQLite | SQL | Local/offline | Easy |
| GraphQL | API | Custom backends | Medium |
| REST | API | Any HTTP API | Easy |

## Installation

### 1. Add SyncLayer
```yaml
dependencies:
  synclayer: ^0.1.0-alpha.6
```

### 2. Add Your Database Package
Choose ONE database package based on your needs:

```yaml
# BaaS Platforms
cloud_firestore: ^5.7.0           # Firebase
supabase_flutter: ^2.9.0          # Supabase
appwrite: ^14.0.0                 # Appwrite

# SQL Databases
postgres: ^3.0.0                  # PostgreSQL
mysql1: ^0.20.0                   # MySQL/MariaDB
sqflite: ^2.3.0                   # SQLite

# NoSQL Databases
mongo_dart: ^0.10.0               # MongoDB
redis: ^3.1.0                     # Redis
aws_dynamodb_api: ^2.0.0          # DynamoDB
dart_cassandra_cql: ^0.5.0        # Cassandra

# API Protocols
dio: ^5.4.0                       # CouchDB/REST
graphql: ^5.1.0                   # GraphQL
```

## Usage Examples

### Firebase
```dart
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters/adapters.dart';

await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: FirebaseAdapter(
      firestore: FirebaseFirestore.instance,
    ),
    collections: ['todos', 'users'],
  ),
);
```

### PostgreSQL
```dart
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

### MongoDB
```dart
final db = await Db.create('mongodb://localhost:27017/mydb');
await db.open();

await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: MongoDBAdapter(db: db),
    collections: ['todos', 'users'],
  ),
);
```

### REST API (Default)
```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    authToken: 'your-token',
    collections: ['todos', 'users'],
  ),
);
// Uses RestBackendAdapter automatically
```

## Architecture

All adapters implement the same `SyncBackendAdapter` interface:

```dart
abstract class SyncBackendAdapter {
  Future<void> push({...});           // Save data
  Future<List<SyncRecord>> pull({...}); // Fetch data
  Future<void> delete({...});         // Delete data
  void updateAuthToken(String token); // Update auth
}
```

This means:
- ✅ Consistent API across all databases
- ✅ Easy to switch databases
- ✅ Can create custom adapters
- ✅ Local-first sync works the same way

## Features Across All Databases

Regardless of which database you choose, you get:

- **Offline-first** - Data saved locally first (Isar)
- **Auto-sync** - Background synchronization
- **Conflict resolution** - Automatic conflict handling
- **Real-time updates** - Reactive streams with `watch()`
- **Versioning** - Track data versions
- **Retry logic** - Automatic retry on failure
- **Type-safe** - Full Dart type safety

## Schema Requirements

### SQL Databases
Each collection needs a table:
```sql
CREATE TABLE your_collection (
  record_id VARCHAR(255) PRIMARY KEY,
  data JSON/JSONB NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  version INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX idx_updated_at ON your_collection(updated_at);
```

### NoSQL Databases
Schema is handled automatically. Documents include:
```json
{
  "record_id": "uuid",
  "data": { ... your data ... },
  "updated_at": "2024-01-01T00:00:00Z",
  "version": 1
}
```

## Creating Custom Adapters

Need a database not listed? Create your own adapter:

```dart
class MyDatabaseAdapter implements SyncBackendAdapter {
  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    // Your push logic
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
  }) async {
    // Your pull logic
    return [];
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    // Your delete logic
  }

  @override
  void updateAuthToken(String token) {
    // Your auth logic
  }
}
```

## Documentation

- **[Adapter Guide](lib/adapters/ADAPTER_GUIDE.md)** - Detailed setup for each database
- **[Adapter README](lib/adapters/README.md)** - Quick reference
- **[API Docs](doc/api/)** - Generated documentation
- **[Examples](example/)** - Working code samples

## Choosing the Right Database

### For Mobile Apps
- Firebase (easiest, real-time)
- Supabase (PostgreSQL, open-source)
- SQLite (offline-only, no server)

### For Web Apps
- PostgreSQL (robust, ACID)
- MySQL (traditional, widely supported)
- MongoDB (flexible schema)

### For Serverless
- DynamoDB (AWS native)
- Firebase (Google Cloud)
- Supabase (managed PostgreSQL)

### For High Performance
- Redis (in-memory, fastest)
- Cassandra (distributed, scalable)
- DynamoDB (low latency)

### For Self-Hosted
- PostgreSQL (feature-rich)
- MongoDB (flexible)
- CouchDB (built-in replication)

## Migration Between Databases

Switching databases is easy since all adapters use the same interface:

```dart
// Before: Firebase
await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: FirebaseAdapter(...),
  ),
);

// After: PostgreSQL
await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: PostgresAdapter(...),
  ),
);
```

Your app code stays the same - only the adapter changes!

## Performance Considerations

- **Local-first**: All writes are instant (saved to Isar first)
- **Background sync**: Network operations don't block UI
- **Batching**: Multiple operations can be batched
- **Indexing**: Ensure `updated_at` is indexed for pull sync
- **Connection pooling**: Reuse database connections

## Security

- Use environment variables for credentials
- Enable SSL/TLS for database connections
- Implement proper authentication
- Use row-level security (PostgreSQL, Supabase)
- Validate data before sync

## Troubleshooting

### Analyzer Errors
If you see errors in adapter files you're not using, that's normal. Adapters are optional and only work when their packages are installed.

### Connection Issues
- Check network connectivity
- Verify credentials
- Ensure database is accessible
- Check firewall rules

### Schema Errors
- Verify tables/collections exist
- Check column/field names
- Ensure indexes are created
- Validate data types

## Contributing

Want to add support for another database? We welcome contributions!

1. Implement `SyncBackendAdapter`
2. Add tests
3. Update documentation
4. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - See [LICENSE](LICENSE) file

## Support

- [GitHub Issues](https://github.com/hostspicaindia/synclayer/issues)
- [Documentation](https://pub.dev/packages/synclayer)
- [Examples](https://github.com/hostspicaindia/synclayer/tree/main/example)
