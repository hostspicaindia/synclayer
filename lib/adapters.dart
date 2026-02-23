/// Database adapters for SyncLayer
///
/// This library exports all available database adapters.
/// Import only this file to access any adapter:
///
/// ```dart
/// import 'package:synclayer/adapters.dart';
/// ```
///
/// **IMPORTANT:** Each adapter requires its own package dependency.
/// Only install the packages for databases you actually use.
///
/// ## Available Adapters
///
/// ### BaaS Platforms
/// - `FirebaseAdapter` - Requires: `cloud_firestore`
/// - `SupabaseAdapter` - Requires: `supabase_flutter`
/// - `AppwriteAdapter` - Requires: `appwrite`
///
/// ### SQL Databases
/// - `PostgresAdapter` - Requires: `postgres`
/// - `MySQLAdapter` - Requires: `mysql1`
/// - `MariaDBAdapter` - Requires: `mysql1`
/// - `SQLiteAdapter` - Requires: `sqflite`
///
/// ### NoSQL Databases
/// - `MongoDBAdapter` - Requires: `mongo_dart`
/// - `CouchDBAdapter` - Requires: `dio` (included)
/// - `RedisAdapter` - Requires: `redis`
/// - `DynamoDBAdapter` - Requires: `aws_dynamodb_api`
/// - `CassandraAdapter` - Requires: `dart_cassandra_cql`
///
/// ### API Protocols
/// - `GraphQLAdapter` - Requires: `graphql`
/// - `RestBackendAdapter` - Built-in (uses `dio`)
///
/// ## Installation
///
/// Add SyncLayer and your chosen database package:
/// ```yaml
/// dependencies:
///   synclayer: ^1.4.0
///   postgres: ^3.0.0  # Example: for PostgreSQL
/// ```
///
/// ## Usage Example
///
/// ```dart
/// import 'package:synclayer/synclayer.dart';
/// import 'package:synclayer/adapters.dart';
/// import 'package:postgres/postgres.dart';
///
/// final conn = await Connection.open(
///   Endpoint(host: 'localhost', database: 'mydb'),
/// );
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
/// See the [Adapter Guide](https://github.com/hostspicaindia/synclayer/blob/main/lib/adapters/ADAPTER_GUIDE.md)
/// for detailed setup instructions for each database.
///
/// **Note:** Adapter files will show analyzer errors if their required packages
/// are not installed. This is expected - they are optional dependencies.
library adapters;

// Export all adapters
export 'adapters/adapters.dart';
