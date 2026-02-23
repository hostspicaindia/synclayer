# Database Adapter Guide

SyncLayer supports multiple database backends through its adapter pattern. This guide helps you choose and configure the right adapter for your needs.

## Quick Reference

| Database | Adapter | Package | Best For |
|----------|---------|---------|----------|
| **Firebase** | `FirebaseAdapter` | `cloud_firestore` | Mobile apps, real-time features |
| **Supabase** | `SupabaseAdapter` | `supabase_flutter` | PostgreSQL with auth, real-time |
| **Appwrite** | `AppwriteAdapter` | `appwrite` | Self-hosted BaaS |
| **PostgreSQL** | `PostgresAdapter` | `postgres` | Relational data, complex queries |
| **MySQL** | `MySQLAdapter` | `mysql1` | Traditional web apps |
| **MariaDB** | `MariaDBAdapter` | `mysql1` | MySQL alternative |
| **SQLite** | `SQLiteAdapter` | `sqflite` | Local/embedded databases |
| **MongoDB** | `MongoDBAdapter` | `mongo_dart` | Document storage, flexible schema |
| **CouchDB** | `CouchDBAdapter` | `dio` | Built-in replication |
| **Redis** | `RedisAdapter` | `redis` | Caching, fast access |
| **DynamoDB** | `DynamoDBAdapter` | `aws_dynamodb_api` | AWS ecosystem, serverless |
| **Cassandra** | `CassandraAdapter` | `dart_cassandra_cql` | High availability, big data |
| **GraphQL** | `GraphQLAdapter` | `graphql` | Custom GraphQL APIs |
| **REST API** | `RestBackendAdapter` | `dio` (built-in) | Any HTTP API |

## Installation

### 1. Add SyncLayer
```yaml
dependencies:
  synclayer: ^0.1.0-alpha.6
```

### 2. Add Database Package
Only install the package for your chosen database:

#### BaaS Platforms
```yaml
# Firebase
cloud_firestore: ^5.7.0

# Supabase
supabase_flutter: ^2.9.0

# Appwrite
appwrite: ^14.0.0
```

#### SQL Databases
```yaml
# PostgreSQL
postgres: ^3.0.0

# MySQL/MariaDB
mysql1: ^0.20.0

# SQLite
sqflite: ^2.3.0
```

#### NoSQL Databases
```yaml
# MongoDB
mongo_dart: ^0.10.0

# Redis
redis: ^3.1.0

# DynamoDB
aws_dynamodb_api: ^2.0.0

# Cassandra
dart_cassandra_cql: ^0.5.0
```

#### API Protocols
```yaml
# CouchDB (uses dio)
dio: ^5.4.0

# GraphQL
graphql: ^5.1.0
```

## Usage Examples

### Firebase Firestore
```dart
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters/adapters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

### PostgreSQL
```dart
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters/adapters.dart';
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
    baseUrl: 'postgres://localhost',
    customBackendAdapter: PostgresAdapter(
      connection: connection,
    ),
    collections: ['todos', 'users'],
  ),
);
```

### MongoDB
```dart
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters/adapters.dart';
import 'package:mongo_dart/mongo_dart.dart';

final db = await Db.create('mongodb://localhost:27017/mydb');
await db.open();

await SyncLayer.init(
  SyncConfig(
    baseUrl: 'mongodb://localhost',
    customBackendAdapter: MongoDBAdapter(db: db),
    collections: ['todos', 'users'],
  ),
);
```

### GraphQL
```dart
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters/adapters.dart';
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
    baseUrl: 'https://api.example.com',
    customBackendAdapter: GraphQLAdapter(client: client),
    collections: ['todos', 'users'],
  ),
);
```

### REST API (Built-in)
```dart
import 'package:synclayer/synclayer.dart';

await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    authToken: 'your-token',
    collections: ['todos', 'users'],
  ),
);
// Uses RestBackendAdapter by default
```

## Database Schema Requirements

### SQL Databases (PostgreSQL, MySQL, MariaDB, SQLite)
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

### MongoDB
No schema required. Documents automatically include:
```json
{
  "record_id": "uuid",
  "data": { ... },
  "updated_at": ISODate(...),
  "version": 1
}
```

### DynamoDB
Table requirements:
- Partition Key: `record_id` (String)
- Attributes: `data`, `updated_at`, `version`
- GSI on `updated_at` for efficient queries

### Redis
Uses Hash + Sorted Set pattern:
- Hash: `collection:record_id` → {data, updated_at, version}
- Sorted Set: `collection:_index` → timestamp scores

## Creating Custom Adapters

Implement the `SyncBackendAdapter` interface:

```dart
import 'package:synclayer/synclayer.dart';

class MyCustomAdapter implements SyncBackendAdapter {
  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    // Save data to your backend
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
  }) async {
    // Fetch data from your backend
    return [];
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    // Delete data from your backend
  }

  @override
  void updateAuthToken(String token) {
    // Update authentication
  }
}
```

## Choosing the Right Database

### For Mobile Apps
- **Firebase**: Best for real-time features, easy setup
- **Supabase**: PostgreSQL with real-time, open source
- **SQLite**: Offline-first, no server needed

### For Web Apps
- **PostgreSQL**: Robust, ACID compliant
- **MySQL/MariaDB**: Traditional, widely supported
- **MongoDB**: Flexible schema, document storage

### For Serverless
- **DynamoDB**: AWS native, auto-scaling
- **Firebase**: Google Cloud, managed
- **Supabase**: PostgreSQL, managed

### For High Performance
- **Redis**: In-memory, extremely fast
- **Cassandra**: Distributed, high availability
- **DynamoDB**: Low latency, scalable

### For Self-Hosted
- **PostgreSQL**: Feature-rich, reliable
- **MongoDB**: Flexible, scalable
- **CouchDB**: Built-in replication

## Troubleshooting

### Analyzer Errors
If you see errors in adapter files you're not using, that's normal. The adapters are optional and only work when their packages are installed.

### Connection Issues
- Check network connectivity
- Verify credentials
- Ensure database is accessible from your app

### Schema Errors
- Verify tables/collections exist
- Check column/field names match requirements
- Ensure indexes are created

## Need Help?

- [GitHub Issues](https://github.com/hostspicaindia/synclayer/issues)
- [Documentation](https://pub.dev/packages/synclayer)
- [Examples](https://github.com/hostspicaindia/synclayer/tree/main/example)
