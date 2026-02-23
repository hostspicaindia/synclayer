import 'custom_conflict_resolver.dart';

/// Strategies for resolving conflicts when the same document is modified
/// on multiple devices.
///
/// A conflict occurs when:
/// 1. A document is modified on Device A
/// 2. The same document is modified on Device B before A's changes sync
/// 3. Device B pulls changes and detects both versions exist
///
/// Example:
/// ```dart
/// // Configure conflict strategy during initialization
/// await SyncLayer.init(
///   SyncConfig(
///     baseUrl: 'https://api.example.com',
///     conflictStrategy: ConflictStrategy.lastWriteWins,
///   ),
/// );
/// ```
enum ConflictStrategy {
  /// The most recently modified version wins (based on timestamp).
  ///
  /// This is the default and most common strategy. It ensures that
  /// the latest user intent is preserved, regardless of which device
  /// made the change.
  ///
  /// Use when: You want the most recent change to always win.
  lastWriteWins,

  /// The server (backend) version always wins.
  ///
  /// Local changes are discarded if they conflict with the server.
  /// This ensures the server is always the source of truth.
  ///
  /// Use when: You have server-side validation or business logic
  /// that should take precedence over client changes.
  serverWins,

  /// The client (local) version always wins.
  ///
  /// Remote changes are discarded if they conflict with local changes.
  /// This prioritizes the current device's changes.
  ///
  /// Use when: You want to ensure local changes are never lost,
  /// even if they conflict with the server.
  clientWins,

  /// Use a custom conflict resolver function.
  ///
  /// Allows implementing custom conflict resolution logic for
  /// specific use cases like merging arrays, summing quantities,
  /// or field-level merging.
  ///
  /// Use when: Built-in strategies don't fit your use case.
  custom,
}

/// Handles data conflicts during synchronization.
///
/// When the same document is modified on multiple devices between syncs,
/// a conflict occurs. The ConflictResolver uses the configured strategy
/// to determine which version should be kept.
///
/// Example:
/// ```dart
/// final resolver = ConflictResolver(
///   strategy: ConflictStrategy.lastWriteWins,
/// );
///
/// final winner = resolver.resolve(
///   localData: {'text': 'Local version', 'completed': true},
///   remoteData: {'text': 'Remote version', 'completed': false},
///   localTimestamp: DateTime(2024, 1, 1, 10, 0),
///   remoteTimestamp: DateTime(2024, 1, 1, 10, 5),
/// );
///
/// // winner will be remoteData because it's more recent
/// ```
///
/// Custom conflict resolution example:
/// ```dart
/// final resolver = ConflictResolver(
///   strategy: ConflictStrategy.custom,
///   customResolver: (local, remote, localTime, remoteTime) {
///     // Merge arrays instead of replacing
///     return {
///       ...remote,
///       'tags': [
///         ...List<String>.from(local['tags'] ?? []),
///         ...List<String>.from(remote['tags'] ?? []),
///       ].toSet().toList(),
///     };
///   },
/// );
/// ```
class ConflictResolver {
  /// The strategy to use for resolving conflicts.
  final ConflictStrategy strategy;

  /// Custom conflict resolver function (required when strategy is custom).
  final CustomConflictResolverCallback? customResolver;

  ConflictResolver({
    this.strategy = ConflictStrategy.lastWriteWins,
    this.customResolver,
  }) : assert(
          strategy != ConflictStrategy.custom || customResolver != null,
          'customResolver is required when strategy is ConflictStrategy.custom',
        );

  /// Resolves a conflict between local and remote versions of a document.
  ///
  /// Parameters:
  /// - [localData]: The local version of the document.
  /// - [remoteData]: The remote (server) version of the document.
  /// - [localTimestamp]: When the local version was last modified.
  /// - [remoteTimestamp]: When the remote version was last modified.
  ///
  /// Returns:
  /// The winning version of the document based on the configured strategy.
  ///
  /// Example:
  /// ```dart
  /// final winner = resolver.resolve(
  ///   localData: {'text': 'Buy milk', 'done': true},
  ///   remoteData: {'text': 'Buy milk', 'done': false},
  ///   localTimestamp: DateTime(2024, 1, 1, 10, 0),
  ///   remoteTimestamp: DateTime(2024, 1, 1, 10, 5),
  /// );
  /// ```
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

      case ConflictStrategy.custom:
        return customResolver!(
          localData,
          remoteData,
          localTimestamp,
          remoteTimestamp,
        );
    }
  }
}
