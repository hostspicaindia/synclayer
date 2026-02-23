import 'package:graphql/client.dart';
import '../network/sync_backend_adapter.dart';

/// GraphQL adapter for SyncLayer
///
/// Syncs data with any GraphQL backend.
/// Requires your GraphQL schema to support sync operations.
///
/// **IMPORTANT:** This adapter requires the `graphql` package.
/// Add to your pubspec.yaml:
/// ```yaml
/// dependencies:
///   graphql: ^5.1.0
/// ```
///
/// **Required GraphQL Schema:**
/// Your backend should implement these operations:
///
/// ```graphql
/// # Mutation for push
/// mutation PushRecord($collection: String!, $recordId: String!, $data: JSON!, $timestamp: DateTime!) {
///   pushRecord(collection: $collection, recordId: $recordId, data: $data, timestamp: $timestamp) {
///     success
///   }
/// }
///
/// # Query for pull
/// query PullRecords($collection: String!, $since: DateTime) {
///   pullRecords(collection: $collection, since: $since) {
///     recordId
///     data
///     updatedAt
///     version
///   }
/// }
///
/// # Mutation for delete
/// mutation DeleteRecord($collection: String!, $recordId: String!) {
///   deleteRecord(collection: $collection, recordId: $recordId) {
///     success
///   }
/// }
/// ```
///
/// Example:
/// ```dart
/// final httpLink = HttpLink('https://api.example.com/graphql');
/// final authLink = AuthLink(getToken: () async => 'Bearer YOUR_TOKEN');
/// final link = authLink.concat(httpLink);
///
/// final client = GraphQLClient(
///   cache: GraphQLCache(),
///   link: link,
/// );
///
/// await SyncLayer.init(
///   SyncConfig(
///     baseUrl: 'https://api.example.com', // Not used
///     customBackendAdapter: GraphQLAdapter(
///       client: client,
///     ),
///     collections: ['todos', 'users'],
///   ),
/// );
/// ```
///
/// Note: This file will show analyzer errors if graphql is not installed.
/// This is expected - the package is optional and only needed if you use this adapter.
class GraphQLAdapter implements SyncBackendAdapter {
  final GraphQLClient client;

  GraphQLAdapter({
    required this.client,
  });

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    const mutation = r'''
      mutation PushRecord($collection: String!, $recordId: String!, $data: JSON!, $timestamp: DateTime!) {
        pushRecord(collection: $collection, recordId: $recordId, data: $data, timestamp: $timestamp) {
          success
        }
      }
    ''';

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          'collection': collection,
          'recordId': recordId,
          'data': data,
          'timestamp': timestamp.toIso8601String(),
        },
      ),
    );

    if (result.hasException) {
      throw Exception('GraphQL push failed: ${result.exception}');
    }
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
  }) async {
    const query = r'''
      query PullRecords($collection: String!, $since: DateTime) {
        pullRecords(collection: $collection, since: $since) {
          recordId
          data
          updatedAt
          version
        }
      }
    ''';

    final result = await client.query(
      QueryOptions(
        document: gql(query),
        variables: {
          'collection': collection,
          if (since != null) 'since': since.toIso8601String(),
        },
      ),
    );

    if (result.hasException) {
      throw Exception('GraphQL pull failed: ${result.exception}');
    }

    final records = result.data?['pullRecords'] as List? ?? [];

    return records.map((record) {
      return SyncRecord(
        recordId: record['recordId'] as String,
        data: record['data'] as Map<String, dynamic>,
        updatedAt: DateTime.parse(record['updatedAt'] as String),
        version: record['version'] as int,
      );
    }).toList();
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    const mutation = r'''
      mutation DeleteRecord($collection: String!, $recordId: String!) {
        deleteRecord(collection: $collection, recordId: $recordId) {
          success
        }
      }
    ''';

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          'collection': collection,
          'recordId': recordId,
        },
      ),
    );

    if (result.hasException) {
      throw Exception('GraphQL delete failed: ${result.exception}');
    }
  }

  @override
  void updateAuthToken(String token) {
    // GraphQL client auth is typically handled via AuthLink
    // To update token, you need to recreate the client with new AuthLink
    // This is a no-op for existing clients
  }
}
