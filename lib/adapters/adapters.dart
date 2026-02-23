/// Built-in backend adapters for popular platforms
///
/// SyncLayer provides ready-to-use adapters for:
///
/// **BaaS Platforms:**
/// - Firebase Firestore
/// - Supabase
/// - Appwrite
///
/// **SQL Databases:**
/// - PostgreSQL
/// - MySQL
/// - MariaDB
/// - SQLite
///
/// **NoSQL Databases:**
/// - MongoDB
/// - CouchDB
/// - Redis
/// - DynamoDB
/// - Cassandra
///
/// **API Protocols:**
/// - REST (built-in)
/// - GraphQL
///
/// **IMPORTANT:** These adapters require their respective packages to be installed.
/// Only add the packages you need:
///
/// ```yaml
/// dependencies:
///   synclayer: ^0.1.0-alpha.6
///
///   # BaaS Platforms
///   cloud_firestore: ^5.7.0           # For Firebase
///   supabase_flutter: ^2.9.0          # For Supabase
///   appwrite: ^14.0.0                 # For Appwrite
///
///   # SQL Databases
///   postgres: ^3.0.0                  # For PostgreSQL
///   mysql1: ^0.20.0                   # For MySQL/MariaDB
///   sqflite: ^2.3.0                   # For SQLite
///
///   # NoSQL Databases
///   mongo_dart: ^0.10.0               # For MongoDB
///   redis: ^3.1.0                     # For Redis
///   aws_dynamodb_api: ^2.0.0          # For DynamoDB
///   dart_cassandra_cql: ^0.5.0        # For Cassandra
///
///   # API Protocols
///   dio: ^5.4.0                       # For REST/CouchDB
///   graphql: ^5.1.0                   # For GraphQL
/// ```
///
/// **Note:** The adapter files will show analyzer errors if their dependencies
/// are not installed. This is expected and normal - they are optional dependencies.
///
/// You can also create custom adapters by implementing [SyncBackendAdapter].
library adapters;

// BaaS Platforms
export 'firebase_adapter.dart';
export 'supabase_adapter.dart';
export 'appwrite_adapter.dart';

// SQL Databases
export 'postgres_adapter.dart';
export 'mysql_adapter.dart';
export 'mariadb_adapter.dart';
export 'sqlite_adapter.dart';

// NoSQL Databases
export 'mongodb_adapter.dart';
export 'couchdb_adapter.dart';
export 'redis_adapter.dart';
export 'dynamodb_adapter.dart';
export 'cassandra_adapter.dart';

// API Protocols
export 'graphql_adapter.dart';
