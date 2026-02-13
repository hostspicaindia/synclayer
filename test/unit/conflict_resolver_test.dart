import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/conflict/conflict_resolver.dart';

void main() {
  group('ConflictResolver', () {
    test('lastWriteWins should prefer newer timestamp', () {
      final resolver = ConflictResolver(
        strategy: ConflictStrategy.lastWriteWins,
      );

      final localData = {'name': 'Local', 'value': 1};
      final remoteData = {'name': 'Remote', 'value': 2};
      final localTime = DateTime(2024, 1, 1, 10, 0);
      final remoteTime = DateTime(2024, 1, 1, 11, 0);

      final result = resolver.resolve(
        localData: localData,
        remoteData: remoteData,
        localTimestamp: localTime,
        remoteTimestamp: remoteTime,
      );

      expect(result['name'], equals('Remote'));
      expect(result['value'], equals(2));
    });

    test('lastWriteWins should prefer local when newer', () {
      final resolver = ConflictResolver(
        strategy: ConflictStrategy.lastWriteWins,
      );

      final localData = {'name': 'Local', 'value': 1};
      final remoteData = {'name': 'Remote', 'value': 2};
      final localTime = DateTime(2024, 1, 1, 12, 0);
      final remoteTime = DateTime(2024, 1, 1, 11, 0);

      final result = resolver.resolve(
        localData: localData,
        remoteData: remoteData,
        localTimestamp: localTime,
        remoteTimestamp: remoteTime,
      );

      expect(result['name'], equals('Local'));
      expect(result['value'], equals(1));
    });

    test('serverWins should always prefer remote', () {
      final resolver = ConflictResolver(
        strategy: ConflictStrategy.serverWins,
      );

      final localData = {'name': 'Local', 'value': 1};
      final remoteData = {'name': 'Remote', 'value': 2};
      final localTime = DateTime(2024, 1, 1, 12, 0);
      final remoteTime = DateTime(2024, 1, 1, 11, 0);

      final result = resolver.resolve(
        localData: localData,
        remoteData: remoteData,
        localTimestamp: localTime,
        remoteTimestamp: remoteTime,
      );

      expect(result['name'], equals('Remote'));
      expect(result['value'], equals(2));
    });

    test('clientWins should always prefer local', () {
      final resolver = ConflictResolver(
        strategy: ConflictStrategy.clientWins,
      );

      final localData = {'name': 'Local', 'value': 1};
      final remoteData = {'name': 'Remote', 'value': 2};
      final localTime = DateTime(2024, 1, 1, 10, 0);
      final remoteTime = DateTime(2024, 1, 1, 11, 0);

      final result = resolver.resolve(
        localData: localData,
        remoteData: remoteData,
        localTimestamp: localTime,
        remoteTimestamp: remoteTime,
      );

      expect(result['name'], equals('Local'));
      expect(result['value'], equals(1));
    });
  });
}
