import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';

void main() {
  group('SyncFilter', () {
    group('Basic Filtering', () {
      test('should create filter with where conditions', () {
        final filter = SyncFilter(
          where: {'userId': '123', 'status': 'active'},
        );

        expect(filter.where, isNotNull);
        expect(filter.where!['userId'], equals('123'));
        expect(filter.where!['status'], equals('active'));
      });

      test('should create filter with since timestamp', () {
        final since = DateTime(2024, 1, 1);
        final filter = SyncFilter(since: since);

        expect(filter.since, equals(since));
      });

      test('should create filter with limit', () {
        final filter = SyncFilter(limit: 100);

        expect(filter.limit, equals(100));
      });

      test('should create filter with field inclusion', () {
        final filter = SyncFilter(
          fields: ['id', 'title', 'status'],
        );

        expect(filter.fields, isNotNull);
        expect(filter.fields!.length, equals(3));
        expect(filter.fields, contains('id'));
      });

      test('should create filter with field exclusion', () {
        final filter = SyncFilter(
          excludeFields: ['largeAttachment', 'internalNotes'],
        );

        expect(filter.excludeFields, isNotNull);
        expect(filter.excludeFields!.length, equals(2));
      });

      test('should not allow both fields and excludeFields', () {
        expect(
          () => SyncFilter(
            fields: ['id'],
            excludeFields: ['notes'],
          ),
          throwsAssertionError,
        );
      });
    });

    group('Record Matching', () {
      test('should match record with matching where conditions', () {
        final filter = SyncFilter(
          where: {'userId': '123', 'status': 'active'},
        );

        final data = {
          'userId': '123',
          'status': 'active',
          'title': 'Test',
        };

        expect(filter.matches(data, null), isTrue);
      });

      test('should not match record with non-matching where conditions', () {
        final filter = SyncFilter(
          where: {'userId': '123', 'status': 'active'},
        );

        final data = {
          'userId': '456',
          'status': 'active',
          'title': 'Test',
        };

        expect(filter.matches(data, null), isFalse);
      });

      test('should match record with timestamp after since', () {
        final since = DateTime(2024, 1, 1);
        final filter = SyncFilter(since: since);

        final updatedAt = DateTime(2024, 1, 2);
        final data = {'title': 'Test'};

        expect(filter.matches(data, updatedAt), isTrue);
      });

      test('should not match record with timestamp before since', () {
        final since = DateTime(2024, 1, 1);
        final filter = SyncFilter(since: since);

        final updatedAt = DateTime(2023, 12, 31);
        final data = {'title': 'Test'};

        expect(filter.matches(data, updatedAt), isFalse);
      });

      test('should match record with both where and since conditions', () {
        final since = DateTime(2024, 1, 1);
        final filter = SyncFilter(
          where: {'userId': '123'},
          since: since,
        );

        final updatedAt = DateTime(2024, 1, 2);
        final data = {'userId': '123', 'title': 'Test'};

        expect(filter.matches(data, updatedAt), isTrue);
      });

      test('should not match if any condition fails', () {
        final since = DateTime(2024, 1, 1);
        final filter = SyncFilter(
          where: {'userId': '123'},
          since: since,
        );

        // Wrong userId
        final data1 = {'userId': '456', 'title': 'Test'};
        final updatedAt1 = DateTime(2024, 1, 2);
        expect(filter.matches(data1, updatedAt1), isFalse);

        // Wrong timestamp
        final data2 = {'userId': '123', 'title': 'Test'};
        final updatedAt2 = DateTime(2023, 12, 31);
        expect(filter.matches(data2, updatedAt2), isFalse);
      });
    });

    group('Field Filtering', () {
      test('should include only specified fields', () {
        final filter = SyncFilter(
          fields: ['id', 'title'],
        );

        final data = {
          'id': '123',
          'title': 'Test',
          'description': 'Long description',
          'metadata': {'key': 'value'},
        };

        final filtered = filter.applyFieldFilter(data);

        expect(filtered.length, equals(2));
        expect(filtered['id'], equals('123'));
        expect(filtered['title'], equals('Test'));
        expect(filtered.containsKey('description'), isFalse);
        expect(filtered.containsKey('metadata'), isFalse);
      });

      test('should exclude specified fields', () {
        final filter = SyncFilter(
          excludeFields: ['description', 'metadata'],
        );

        final data = {
          'id': '123',
          'title': 'Test',
          'description': 'Long description',
          'metadata': {'key': 'value'},
        };

        final filtered = filter.applyFieldFilter(data);

        expect(filtered.length, equals(2));
        expect(filtered['id'], equals('123'));
        expect(filtered['title'], equals('Test'));
        expect(filtered.containsKey('description'), isFalse);
        expect(filtered.containsKey('metadata'), isFalse);
      });

      test('should return all fields when no field filter specified', () {
        final filter = SyncFilter(
          where: {'userId': '123'},
        );

        final data = {
          'id': '123',
          'title': 'Test',
          'description': 'Long description',
        };

        final filtered = filter.applyFieldFilter(data);

        expect(filtered.length, equals(3));
        expect(filtered, equals(data));
      });
    });

    group('Query Parameters', () {
      test('should convert where conditions to query params', () {
        final filter = SyncFilter(
          where: {'userId': '123', 'status': 'active'},
        );

        final params = filter.toQueryParams();

        expect(params['where[userId]'], equals('123'));
        expect(params['where[status]'], equals('active'));
      });

      test('should convert since to query param', () {
        final since = DateTime(2024, 1, 1, 12, 0, 0);
        final filter = SyncFilter(since: since);

        final params = filter.toQueryParams();

        expect(params['since'], equals(since.toIso8601String()));
      });

      test('should convert limit to query param', () {
        final filter = SyncFilter(limit: 100);

        final params = filter.toQueryParams();

        expect(params['limit'], equals('100'));
      });

      test('should convert fields to query param', () {
        final filter = SyncFilter(
          fields: ['id', 'title', 'status'],
        );

        final params = filter.toQueryParams();

        expect(params['fields'], equals('id,title,status'));
      });

      test('should convert excludeFields to query param', () {
        final filter = SyncFilter(
          excludeFields: ['description', 'metadata'],
        );

        final params = filter.toQueryParams();

        expect(params['excludeFields'], equals('description,metadata'));
      });

      test('should convert all parameters together', () {
        final since = DateTime(2024, 1, 1);
        final filter = SyncFilter(
          where: {'userId': '123'},
          since: since,
          limit: 50,
          fields: ['id', 'title'],
        );

        final params = filter.toQueryParams();

        expect(params['where[userId]'], equals('123'));
        expect(params['since'], equals(since.toIso8601String()));
        expect(params['limit'], equals('50'));
        expect(params['fields'], equals('id,title'));
      });
    });

    group('CopyWith', () {
      test('should create copy with modified where', () {
        final original = SyncFilter(
          where: {'userId': '123'},
          limit: 100,
        );

        final copy = original.copyWith(
          where: {'userId': '456'},
        );

        expect(copy.where!['userId'], equals('456'));
        expect(copy.limit, equals(100));
        expect(original.where!['userId'], equals('123'));
      });

      test('should create copy with modified since', () {
        final since1 = DateTime(2024, 1, 1);
        final since2 = DateTime(2024, 2, 1);

        final original = SyncFilter(since: since1);
        final copy = original.copyWith(since: since2);

        expect(copy.since, equals(since2));
        expect(original.since, equals(since1));
      });

      test('should create copy with modified limit', () {
        final original = SyncFilter(limit: 100);
        final copy = original.copyWith(limit: 200);

        expect(copy.limit, equals(200));
        expect(original.limit, equals(100));
      });
    });

    group('Use Cases', () {
      test('should support multi-tenant filtering', () {
        final currentUserId = 'user-123';
        final filter = SyncFilter(
          where: {'userId': currentUserId},
        );

        // User's own data
        final ownData = {'userId': 'user-123', 'title': 'My Todo'};
        expect(filter.matches(ownData, null), isTrue);

        // Other user's data
        final otherData = {'userId': 'user-456', 'title': 'Their Todo'};
        expect(filter.matches(otherData, null), isFalse);
      });

      test('should support time-based filtering for recent data', () {
        final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
        final filter = SyncFilter(since: thirtyDaysAgo);

        // Recent data
        final recentData = {'title': 'Recent'};
        final recentTime = DateTime.now().subtract(Duration(days: 5));
        expect(filter.matches(recentData, recentTime), isTrue);

        // Old data
        final oldData = {'title': 'Old'};
        final oldTime = DateTime.now().subtract(Duration(days: 60));
        expect(filter.matches(oldData, oldTime), isFalse);
      });

      test('should support bandwidth optimization with field filtering', () {
        final filter = SyncFilter(
          excludeFields: ['largeAttachment', 'fullContent'],
        );

        final data = {
          'id': '123',
          'title': 'Document',
          'summary': 'Short summary',
          'largeAttachment': 'base64encodeddata...',
          'fullContent': 'Very long content...',
        };

        final filtered = filter.applyFieldFilter(data);

        // Only essential fields synced
        expect(filtered.containsKey('id'), isTrue);
        expect(filtered.containsKey('title'), isTrue);
        expect(filtered.containsKey('summary'), isTrue);
        expect(filtered.containsKey('largeAttachment'), isFalse);
        expect(filtered.containsKey('fullContent'), isFalse);
      });

      test('should support progressive sync with limit', () {
        final filter = SyncFilter(
          limit: 50,
          where: {'userId': 'user-123'},
        );

        final params = filter.toQueryParams();

        expect(params['limit'], equals('50'));
        expect(params['where[userId]'], equals('user-123'));
      });

      test('should support GDPR compliance with user-specific filtering', () {
        final currentUserId = 'user-123';
        final filter = SyncFilter(
          where: {
            'userId': currentUserId,
            'consentGiven': true,
          },
        );

        // Data with consent
        final consentedData = {
          'userId': 'user-123',
          'consentGiven': true,
          'data': 'sensitive',
        };
        expect(filter.matches(consentedData, null), isTrue);

        // Data without consent
        final nonConsentedData = {
          'userId': 'user-123',
          'consentGiven': false,
          'data': 'sensitive',
        };
        expect(filter.matches(nonConsentedData, null), isFalse);
      });
    });

    group('ToString', () {
      test('should provide readable string representation', () {
        final filter = SyncFilter(
          where: {'userId': '123'},
          limit: 100,
        );

        final str = filter.toString();

        expect(str, contains('SyncFilter'));
        expect(str, contains('where'));
        expect(str, contains('limit'));
      });

      test('should show all configured properties', () {
        final since = DateTime(2024, 1, 1);
        final filter = SyncFilter(
          where: {'userId': '123'},
          since: since,
          limit: 50,
          fields: ['id', 'title'],
        );

        final str = filter.toString();

        expect(str, contains('where'));
        expect(str, contains('since'));
        expect(str, contains('limit'));
        expect(str, contains('fields'));
      });
    });
  });
}
