import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';

void main() {
  group('Custom Conflict Resolvers', () {
    final localTime = DateTime(2024, 1, 1, 10, 0);
    final remoteTime = DateTime(2024, 1, 1, 10, 5);

    test('mergeArrays - merges and deduplicates arrays', () {
      final resolver = ConflictResolver(
        strategy: ConflictStrategy.custom,
        customResolver: ConflictResolvers.mergeArrays(['tags', 'likes']),
      );

      final local = {
        'title': 'Post',
        'tags': ['flutter', 'dart'],
        'likes': ['user1', 'user2'],
      };

      final remote = {
        'title': 'Post Updated',
        'tags': ['dart', 'mobile'],
        'likes': ['user2', 'user3'],
      };

      final result = resolver.resolve(
        localData: local,
        remoteData: remote,
        localTimestamp: localTime,
        remoteTimestamp: remoteTime,
      );

      expect(
          result['title'], 'Post Updated'); // Remote wins for non-array fields
      expect(result['tags'], containsAll(['flutter', 'dart', 'mobile']));
      expect(result['tags'].length, 3); // Deduplicated
      expect(result['likes'], containsAll(['user1', 'user2', 'user3']));
      expect(result['likes'].length, 3); // Deduplicated
    });

    test('sumNumbers - sums numeric fields', () {
      final resolver = ConflictResolver(
        strategy: ConflictStrategy.custom,
        customResolver: ConflictResolvers.sumNumbers(['quantity', 'views']),
      );

      final local = {
        'name': 'Product',
        'quantity': 10,
        'views': 100,
      };

      final remote = {
        'name': 'Product Updated',
        'quantity': 5,
        'views': 50,
      };

      final result = resolver.resolve(
        localData: local,
        remoteData: remote,
        localTimestamp: localTime,
        remoteTimestamp: remoteTime,
      );

      expect(result['name'],
          'Product Updated'); // Remote wins for non-numeric fields
      expect(result['quantity'], 15); // 10 + 5
      expect(result['views'], 150); // 100 + 50
    });

    test('mergeFields - merges specific fields from local', () {
      final resolver = ConflictResolver(
        strategy: ConflictStrategy.custom,
        customResolver: ConflictResolvers.mergeFields(['comments', 'likes']),
      );

      final local = {
        'title': 'Local Title',
        'comments': ['comment1', 'comment2'],
        'likes': 10,
      };

      final remote = {
        'title': 'Remote Title',
        'comments': ['comment3'],
        'likes': 5,
      };

      final result = resolver.resolve(
        localData: local,
        remoteData: remote,
        localTimestamp: localTime,
        remoteTimestamp: remoteTime,
      );

      expect(result['title'], 'Remote Title'); // Remote wins
      expect(result['comments'], ['comment1', 'comment2']); // Local wins
      expect(result['likes'], 10); // Local wins
    });

    test('maxValue - takes maximum for numeric fields', () {
      final resolver = ConflictResolver(
        strategy: ConflictStrategy.custom,
        customResolver: ConflictResolvers.maxValue(['version', 'score']),
      );

      final local = {
        'version': 5,
        'score': 100,
      };

      final remote = {
        'version': 3,
        'score': 150,
      };

      final result = resolver.resolve(
        localData: local,
        remoteData: remote,
        localTimestamp: localTime,
        remoteTimestamp: remoteTime,
      );

      expect(result['version'], 5); // Max of 5 and 3
      expect(result['score'], 150); // Max of 100 and 150
    });

    test('fieldLevelLastWriteWins - uses per-field timestamps', () {
      final resolver = ConflictResolver(
        strategy: ConflictStrategy.custom,
        customResolver: ConflictResolvers.fieldLevelLastWriteWins(),
      );

      final local = {
        'title': 'Local Title',
        'title_updatedAt': '2024-01-01T10:05:00.000Z', // Newer
        'content': 'Local Content',
        'content_updatedAt': '2024-01-01T10:00:00.000Z', // Older
      };

      final remote = {
        'title': 'Remote Title',
        'title_updatedAt': '2024-01-01T10:00:00.000Z', // Older
        'content': 'Remote Content',
        'content_updatedAt': '2024-01-01T10:05:00.000Z', // Newer
      };

      final result = resolver.resolve(
        localData: local,
        remoteData: remote,
        localTimestamp: localTime,
        remoteTimestamp: remoteTime,
      );

      expect(result['title'], 'Local Title'); // Local is newer
      expect(result['content'], 'Remote Content'); // Remote is newer
    });

    test('deepMerge - recursively merges nested objects', () {
      final resolver = ConflictResolver(
        strategy: ConflictStrategy.custom,
        customResolver: ConflictResolvers.deepMerge(),
      );

      final local = {
        'user': {
          'name': 'John',
          'settings': {
            'theme': 'dark',
            'notifications': true,
          },
        },
        'tags': ['tag1', 'tag2'],
      };

      final remote = {
        'user': {
          'email': 'john@example.com',
          'settings': {
            'language': 'en',
          },
        },
        'tags': ['tag2', 'tag3'],
      };

      final result = resolver.resolve(
        localData: local,
        remoteData: remote,
        localTimestamp: localTime,
        remoteTimestamp: remoteTime,
      );

      expect(result['user']['name'], 'John'); // From local
      expect(result['user']['email'], 'john@example.com'); // From remote
      expect(result['user']['settings']['theme'], 'dark'); // From local
      expect(result['user']['settings']['language'], 'en'); // From remote
      expect(result['user']['settings']['notifications'], true); // From local
      expect(result['tags'], containsAll(['tag1', 'tag2', 'tag3'])); // Merged
    });

    test('custom resolver - inventory sum example', () {
      final resolver = ConflictResolver(
        strategy: ConflictStrategy.custom,
        customResolver: (local, remote, localTime, remoteTime) {
          // Inventory app: sum quantities, keep latest metadata
          return {
            ...remote,
            'quantity': (local['quantity'] ?? 0) + (remote['quantity'] ?? 0),
          };
        },
      );

      final local = {
        'productId': '123',
        'quantity': 10,
        'location': 'Warehouse A',
      };

      final remote = {
        'productId': '123',
        'quantity': 5,
        'location': 'Warehouse B',
      };

      final result = resolver.resolve(
        localData: local,
        remoteData: remote,
        localTimestamp: localTime,
        remoteTimestamp: remoteTime,
      );

      expect(result['quantity'], 15); // Summed
      expect(result['location'], 'Warehouse B'); // Remote wins
    });

    test('custom resolver - social app merge likes and comments', () {
      final resolver = ConflictResolver(
        strategy: ConflictStrategy.custom,
        customResolver: (local, remote, localTime, remoteTime) {
          // Social app: merge likes and comments
          final localLikes = List<String>.from(local['likes'] ?? []);
          final remoteLikes = List<String>.from(remote['likes'] ?? []);
          final localComments = List<Map>.from(local['comments'] ?? []);
          final remoteComments = List<Map>.from(remote['comments'] ?? []);

          return {
            ...remote,
            'likes': [...localLikes, ...remoteLikes].toSet().toList(),
            'comments': [...localComments, ...remoteComments],
          };
        },
      );

      final local = {
        'postId': '123',
        'likes': ['user1', 'user2'],
        'comments': [
          {'user': 'user1', 'text': 'Great!'}
        ],
      };

      final remote = {
        'postId': '123',
        'likes': ['user2', 'user3'],
        'comments': [
          {'user': 'user3', 'text': 'Nice!'}
        ],
      };

      final result = resolver.resolve(
        localData: local,
        remoteData: remote,
        localTimestamp: localTime,
        remoteTimestamp: remoteTime,
      );

      expect(result['likes'], containsAll(['user1', 'user2', 'user3']));
      expect(result['likes'].length, 3); // Deduplicated
      expect(result['comments'].length, 2); // Both comments kept
    });

    test('ConflictResolver requires customResolver when strategy is custom',
        () {
      expect(
        () => ConflictResolver(
          strategy: ConflictStrategy.custom,
          // Missing customResolver
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('ConflictResolver works with custom strategy', () {
      final resolver = ConflictResolver(
        strategy: ConflictStrategy.custom,
        customResolver: (local, remote, localTime, remoteTime) {
          return {'merged': true};
        },
      );

      final result = resolver.resolve(
        localData: {'a': 1},
        remoteData: {'b': 2},
        localTimestamp: localTime,
        remoteTimestamp: remoteTime,
      );

      expect(result, {'merged': true});
    });
  });
}
