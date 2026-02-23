# Database Adapters

This directory contains built-in adapters for 14+ database backends and protocols.

## Available Adapters

### BaaS Platforms

#### Firebase Firestore (`firebase_adapter.dart`)
- Syncs with Google Cloud Firestore
- Requires: `cloud_firestore` package
- Best for: Mobile apps, real-time features, Firebase ecosystem

#### Supabase (`supabase_adapter.dart`)
- Syncs with Supabase PostgreSQL database
- Requires: `supabase_flutter` package
- Best for: Open-source Firebase alternative, PostgreSQL with real-time

#### Appwrite (`appwrite_adapter.dart`)
- Syncs with Appwrite database collections
- Requires: `appwrite` package
- Best for: Self-hosted backend, privacy-focused apps

### SQL Databases

#### PostgreSQL (`postgres_adapter.dart`)
- Direct PostgreSQL connection
- Requires: `postgres` package
- Best for: Relational data, complex queries, ACID compliance

#### MySQL (`mysql_adapter.dart`)
- Direct MySQL connection
- Requires: `mysql1` package
- Best for: Traditional web apps, shared hosting

#### MariaDB (`mariadb_adapter.dart`)
- MariaDB connection (MySQL-compatible)
- Requires: `mysql1` package
- Best for: MySQL alternative, enhanced features

#### SQLite (`sqlite_adapter.dart`)
- Local/embedded SQLite database
- Requires: `sqflite` package
- Best for: Local storage, offline-first, no server needed

### NoSQL Databases

#### MongoDB (`mongodb_adapter.dart`)
- MongoDB document database
- Requires: `mongo_dart` package
- Best for: Document storage, flexible schema, JSON data

#### CouchDB (`couchdb_adapter.dart`)
- Apache CouchDB
- Requires: `dio` package
- Best for: Built-in replication, offline-first design

#### Redis (`redis_adapter.dart`)
- Redis key-value store
- Requires: `redis` package
- Best for: Caching, session storage, fast access

#### DynamoDB (`dynamodb_adapter.dart`)
- AWS DynamoDB
- Requires: `aws_dynamodb_api` package
- Best for: AWS ecosystem, serverless, auto-scaling

#### Cassandra (`cassandra_adapter.dart`)
- Apache Cassandra
- Requires: `dart_cassandra_cql` package
- Best for: High availability, distributed systems, big data

### API Protocols

#### GraphQL (`graphql_adapter.dart`)
- Any GraphQL API
- Requires: `graphql` package
- Best for: Custom GraphQL backends, flexible queries

#### REST API (`rest_backend_adapter.dart`)
- Generic REST API (built-in)
- Requires: `dio` package (included)
- Best for: Any HTTP API, custom backends

## Installation

These adapters are optional. Add only the package for your chosen database:

```yaml
dependencies:
  synclayer: ^0.1.0-alpha.6
  
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
  dio: ^5.4.0                       # CouchDB (included for REST)
  graphql: ^5.1.0                   # GraphQL
```

## Quick Start Examples

### Firebase
```dart
import 'package:synclayer/adapters/adapters.dart';
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

### PostgreSQL
```dart
import 'package:synclayer/adapters/adapters.dart';
import 'package:postgres/postgres.dart';

final conn = await Connection.open(
  Endpoint(host: 'localhost', database: 'mydb', username: 'user', password: 'pass'),
);

await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: PostgresAdapter(connection: conn),
    collections: ['todos', 'users'],
  ),
);
```

### MongoDB
```dart
import 'package:synclayer/adapters/adapters.dart';
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

### REST API (Default)
```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    authToken: 'your-token',
    collections: ['todos', 'users'],
  ),
);
// Automatically uses RestBackendAdapter
```

## Documentation

- **[Complete Adapter Guide](ADAPTER_GUIDE.md)** - Detailed setup for all databases
- **[API Documentation](../../doc/api/)** - Generated API docs
- **[Examples](../../example/)** - Working code examples

## Database Schema Requirements

Most SQL databases need this table structure:
```sql
CREATE TABLE your_collection (
  record_id VARCHAR(255) PRIMARY KEY,
  data JSON/JSONB NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  version INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX idx_updated_at ON your_collection(updated_at);
```

NoSQL databases (MongoDB, CouchDB, etc.) handle schema automatically.

See [ADAPTER_GUIDE.md](ADAPTER_GUIDE.md) for database-specific requirements.

## Creating Custom Adapters

To create your own adapter, implement the `SyncBackendAdapter` interface:

```dart
class MyCustomAdapter implements SyncBackendAdapter {
  @override
  Future<void> push({...}) async {
    // Push data to your backend
  }

  @override
  Future<List<SyncRecord>> pull({...}) async {
    // Pull data from your backend
  }

  @override
  Future<void> delete({...}) async {
    // Delete data on your backend
  }

  @override
  void updateAuthToken(String token) {
    // Update authentication token
  }
}
```

See the existing adapters in this directory for reference implementations.
