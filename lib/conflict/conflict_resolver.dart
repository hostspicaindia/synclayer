/// Conflict resolution strategies
enum ConflictStrategy { lastWriteWins, serverWins, clientWins }

/// Handles data conflicts during sync
class ConflictResolver {
  final ConflictStrategy strategy;

  ConflictResolver({this.strategy = ConflictStrategy.lastWriteWins});

  /// Resolve conflict between local and remote data
  Map<String, dynamic> resolve({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    required DateTime localTimestamp,
    required DateTime remoteTimestamp,
  }) {
    switch (strategy) {
      case ConflictStrategy.lastWriteWins:
        return localTimestamp.isAfter(remoteTimestamp) ? localData : remoteData;

      case ConflictStrategy.serverWins:
        return remoteData;

      case ConflictStrategy.clientWins:
        return localData;
    }
  }
}
