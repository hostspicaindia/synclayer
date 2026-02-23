import 'package:aws_dynamodb_api/dynamodb-2012-08-10.dart';
import '../network/sync_backend_adapter.dart';

/// AWS DynamoDB adapter for SyncLayer
///
/// Syncs data with Amazon DynamoDB tables.
///
/// **IMPORTANT:** This adapter requires the `aws_dynamodb_api` package.
/// Add to your pubspec.yaml:
/// ```yaml
/// dependencies:
///   aws_dynamodb_api: ^2.0.0
/// ```
///
/// **Table Schema:**
/// Each collection maps to a DynamoDB table with:
/// - Partition Key: `record_id` (String)
/// - Attributes: `data` (Map), `updated_at` (String), `version` (Number)
///
/// **Required Index:**
/// Create a GSI (Global Secondary Index) on `updated_at` for efficient pull sync:
/// - Index name: `updated_at-index`
/// - Partition key: `collection_name` (if using single table)
/// - Sort key: `updated_at`
///
/// Example:
/// ```dart
/// final dynamodb = DynamoDB(
///   region: 'us-east-1',
///   credentials: AwsClientCredentials(
///     accessKey: 'YOUR_ACCESS_KEY',
///     secretKey: 'YOUR_SECRET_KEY',
///   ),
/// );
///
/// await SyncLayer.init(
///   SyncConfig(
///     baseUrl: 'dynamodb://us-east-1', // Not used
///     customBackendAdapter: DynamoDBAdapter(
///       dynamodb: dynamodb,
///       tablePrefix: 'synclayer_', // Optional
///     ),
///     collections: ['todos', 'users'],
///   ),
/// );
/// ```
///
/// Note: This file will show analyzer errors if aws_dynamodb_api is not installed.
/// This is expected - the package is optional and only needed if you use this adapter.
class DynamoDBAdapter implements SyncBackendAdapter {
  final DynamoDB dynamodb;
  final String tablePrefix;

  DynamoDBAdapter({
    required this.dynamodb,
    this.tablePrefix = '',
  });

  String _getTableName(String collection) => '$tablePrefix$collection';

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    final tableName = _getTableName(collection);

    await dynamodb.putItem(
      tableName: tableName,
      item: {
        'record_id': AttributeValue(s: recordId),
        'data': AttributeValue(m: _convertToAttributeMap(data)),
        'updated_at': AttributeValue(s: timestamp.toIso8601String()),
        'version': AttributeValue(n: '1'),
      },
    );

    // Increment version using UpdateItem
    await dynamodb.updateItem(
      tableName: tableName,
      key: {
        'record_id': AttributeValue(s: recordId),
      },
      updateExpression: 'ADD version :inc',
      expressionAttributeValues: {
        ':inc': AttributeValue(n: '1'),
      },
    );
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
  }) async {
    final tableName = _getTableName(collection);
    final records = <SyncRecord>[];

    // Scan table (or use Query with GSI if available)
    Map<String, AttributeValue>? lastEvaluatedKey;

    do {
      final result = await dynamodb.scan(
        tableName: tableName,
        exclusiveStartKey: lastEvaluatedKey,
        filterExpression: since != null ? 'updated_at > :since' : null,
        expressionAttributeValues: since != null
            ? {':since': AttributeValue(s: since.toIso8601String())}
            : null,
      );

      for (final item in result.items ?? []) {
        records.add(SyncRecord(
          recordId: item['record_id']!.s!,
          data: _convertFromAttributeMap(item['data']!.m!),
          updatedAt: DateTime.parse(item['updated_at']!.s!),
          version: int.parse(item['version']!.n!),
        ));
      }

      lastEvaluatedKey = result.lastEvaluatedKey;
    } while (lastEvaluatedKey != null);

    return records;
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    final tableName = _getTableName(collection);

    await dynamodb.deleteItem(
      tableName: tableName,
      key: {
        'record_id': AttributeValue(s: recordId),
      },
    );
  }

  @override
  void updateAuthToken(String token) {
    // DynamoDB uses AWS credentials, not bearer tokens
    // To update credentials, create a new DynamoDB instance
    // This is a no-op for AWS SDK connections
  }

  /// Convert Map to DynamoDB AttributeValue map
  Map<String, AttributeValue> _convertToAttributeMap(
      Map<String, dynamic> data) {
    final result = <String, AttributeValue>{};

    for (final entry in data.entries) {
      if (entry.value is String) {
        result[entry.key] = AttributeValue(s: entry.value as String);
      } else if (entry.value is num) {
        result[entry.key] = AttributeValue(n: entry.value.toString());
      } else if (entry.value is bool) {
        result[entry.key] = AttributeValue(bool: entry.value as bool);
      } else if (entry.value is Map) {
        result[entry.key] = AttributeValue(
          m: _convertToAttributeMap(entry.value as Map<String, dynamic>),
        );
      }
      // Add more type conversions as needed
    }

    return result;
  }

  /// Convert DynamoDB AttributeValue map to Map
  Map<String, dynamic> _convertFromAttributeMap(
      Map<String, AttributeValue> attributeMap) {
    final result = <String, dynamic>{};

    for (final entry in attributeMap.entries) {
      final value = entry.value;
      if (value.s != null) {
        result[entry.key] = value.s;
      } else if (value.n != null) {
        result[entry.key] = num.parse(value.n!);
      } else if (value.bool != null) {
        result[entry.key] = value.bool;
      } else if (value.m != null) {
        result[entry.key] = _convertFromAttributeMap(value.m!);
      }
      // Add more type conversions as needed
    }

    return result;
  }
}
