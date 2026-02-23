/// Database adapters for SyncLayer
///
/// SyncLayer supports 14+ database backends through adapter implementations.
/// Adapters are available on GitHub and can be copied into your project.
///
/// ## Why Adapters Are Not Included
///
/// Each adapter requires specific database packages (postgres, mysql1, mongo_dart, etc.).
/// To keep SyncLayer lightweight and avoid forcing unnecessary dependencies,
/// adapters are distributed separately via GitHub.
///
/// ## Available Adapters
///
/// ### BaaS Platforms
/// - `FirebaseAdapter` - Cloud Firestore
/// - `SupabaseAdapter` - Supabase PostgreSQL
/// - `AppwriteAdapter` - Appwrite Database
///
/// ### SQL Databases
/// - `PostgresAdapter` - PostgreSQL
/// - `MySQLAdapter` - MySQL
/// - `MariaDBAdapter` - MariaDB
/// - `SQLiteAdapter` - SQLite
///
/// ### NoSQL Databases
/// - `MongoDBAdapter` - MongoDB
/// - `CouchDBAdapter` - CouchDB
/// - `RedisAdapter` - Redis
/// - `DynamoDBAdapter` - AWS DynamoDB
/// - `CassandraAdapter` - Apache Cassandra
///
/// ### API Protocols
/// - `GraphQLAdapter` - GraphQL APIs
/// - `RestBackendAdapter` - REST APIs (built-in)
///
/// ## Installation
///
/// 1. Copy the adapter file from GitHub:
///    https://github.com/hostspicaindia/synclayer/tree/main/lib/adapters
///
/// 2. Add to your project: `lib/adapters/postgres_adapter.dart`
///
/// 3. Install required package:
/// ```yaml
/// dependencies:
///   synclayer: ^1.4.0
///   postgres: ^3.0.0  # Example for PostgreSQL
/// ```
///
/// 4. Import and use:
/// ```dart
/// import 'package:synclayer/synclayer.dart';
/// import 'adapters/postgres_adapter.dart';
///
/// await SyncLayer.init(
///   SyncConfig(
///     customBackendAdapter: PostgresAdapter(connection: conn),
///     collections: ['todos'],
///   ),
/// );
/// ```
///
/// ## Documentation
///
/// Complete setup guide:
/// https://github.com/hostspicaindia/synclayer/blob/main/DATABASE_SUPPORT.md
///
/// Quick start (5 minutes):
/// https://github.com/hostspicaindia/synclayer/blob/main/QUICK_START.md
library adapters;
