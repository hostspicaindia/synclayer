import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/conflict/conflict_resolver.dart';

void main() {
  group('ConflictResolver', () {
    test('lastWriteWins should choose most recent timestamp', () async {
      // Arrange
      final resolver = ConflictResolver(
        strategy: ConflictStrategy.lastWriteWins,
      );

      final localData = {'text': 'Local version', 'done': true};
      final remoteData = {'text': 'Remote version', 'done': false};
      final localTimestamp = DateTime(2024, 1, 1, 10, 0);
      final remoteTimestamp = DateTime(2024, 1, 1, 10, 5);

      // Act
      final result = resolver.resolve(
        localData: localData,
        remoteData: remoteData,
        localTimestamp: localTimestamp,
        remoteTimestamp: remoteTimestamp,
      );

      // Assert
      expect(result, equals(remoteData));
    });

    test('lastWriteWins should choose local if more recent', () async {
      // Arrange
      final resolver = ConflictResolver(
        strategy: ConflictStrategy.lastWriteWins,
      );

      final localData = {'text': 'Local version', 'done': true};
      final remoteData = {'text': 'Remote version', 'done': false};
      final localTimestamp = DateTime(2024, 1, 1, 10, 10);
      final remoteTimestamp = DateTime(2024, 1, 1, 10, 5);

      // Act
      final result = resolver.resolve(
        localData: localData,
        remoteData: remoteData,
        localTimestamp: localTimestamp,
        remoteTimestamp: remoteTimestamp,
      );

      // Assert
      expect(result, equals(localData));
    });

    test('serverWins should always choose remote data', () async {
      // Arrange
      final resolver = ConflictResolver(
        strategy: ConflictStrategy.serverWins,
      );

      final localData = {'text': 'Local version', 'done': true};
      final remoteData = {'text': 'Remote version', 'done': false};
      final localTimestamp = DateTime(2024, 1, 1, 10, 10);
      final remoteTimestamp = DateTime(2024, 1, 1, 10, 5);

      // Act
      final result = resolver.resolve(
        localData: localData,
        remoteData: remoteData,
        localTimestamp: localTimestamp,
        remoteTimestamp: remoteTimestamp,
      );

      // Assert
      expect(result, equals(remoteData));
    });

    test('clientWins should always choose local data', () async {
      // Arrange
      final resolver = ConflictResolver(
        strategy: ConflictStrategy.clientWins,
      );

      final localData = {'text': 'Local version', 'done': true};
      final remoteData = {'text': 'Remote version', 'done': false};
      final localTimestamp = DateTime(2024, 1, 1, 10, 0);
      final remoteTimestamp = DateTime(2024, 1, 1, 10, 10);

      // Act
      final result = resolver.resolve(
        localData: localData,
        remoteData: remoteData,
        localTimestamp: localTimestamp,
        remoteTimestamp: remoteTimestamp,
      );

      // Assert
      expect(result, equals(localData));
    });

    test('should handle identical timestamps with lastWriteWins', () async {
      // Arrange
      final resolver = ConflictResolver(
        strategy: ConflictStrategy.lastWriteWins,
      );

      final localData = {'text': 'Local version'};
      final remoteData = {'text': 'Remote version'};
      final timestamp = DateTime(2024, 1, 1, 10, 0);

      // Act
      final result = resolver.resolve(
        localData: localData,
        remoteData: remoteData,
        localTimestamp: timestamp,
        remoteTimestamp: timestamp,
      );

      // Assert - should choose remote when timestamps are equal
      expect(result, equals(remoteData));
    });

    test('should preserve data structure in resolution', () async {
      // Arrange
      final resolver = ConflictResolver(
        strategy: ConflictStrategy.lastWriteWins,
      );

      final localData = {
        'id': '123',
        'text': 'Local',
        'nested': {'key': 'value'},
        'list': [1, 2, 3],
      };

      final remoteData = {
        'id': '123',
        'text': 'Remote',
        'nested': {'key': 'different'},
        'list': [4, 5, 6],
      };

      final localTimestamp = DateTime(2024, 1, 1, 10, 10);
      final remoteTimestamp = DateTime(2024, 1, 1, 10, 5);

      // Act
      final result = resolver.resolve(
        localData: localData,
        remoteData: remoteData,
        localTimestamp: localTimestamp,
        remoteTimestamp: remoteTimestamp,
      );

      // Assert
      expect(result, equals(localData));
      expect(result['nested'], isA<Map>());
      expect(result['list'], isA<List>());
    });
  });
}
