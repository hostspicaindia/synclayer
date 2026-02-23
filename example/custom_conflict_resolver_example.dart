// ignore_for_file: unused_local_variable, avoid_print

import 'package:synclayer/synclayer.dart';

/// Examples of custom conflict resolvers for real-world scenarios.
///
/// Custom conflict resolvers allow you to implement application-specific
/// logic for handling conflicts that the built-in strategies don't cover.
void main() async {
  // Example 1: Social App - Merge Likes and Comments
  await socialAppExample();

  // Example 2: Inventory App - Sum Quantities
  await inventoryAppExample();

  // Example 3: Collaborative Editing - Field-Level Merging
  await collaborativeEditingExample();

  // Example 4: Analytics - Max Values
  await analyticsExample();

  // Example 5: Document Editor - Deep Merge
  await documentEditorExample();

  // Example 6: Using Pre-built Resolvers
  await prebuiltResolversExample();
}

/// Example 1: Social App - Merge Likes and Comments
///
/// Problem: When two users like/comment on the same post offline,
/// you want to merge both sets of likes and comments, not replace them.
Future<void> socialAppExample() async {
  print('\n=== Social App Example ===\n');

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['posts'],
      conflictStrategy: ConflictStrategy.custom,
      customConflictResolver: (local, remote, localTime, remoteTime) {
        // Merge likes (deduplicate)
        final localLikes = List<String>.from(local['likes'] ?? []);
        final remoteLikes = List<String>.from(remote['likes'] ?? []);
        final mergedLikes = {...localLikes, ...remoteLikes}.toList();

        // Merge comments (keep all)
        final localComments = List<Map>.from(local['comments'] ?? []);
        final remoteComments = List<Map>.from(remote['comments'] ?? []);
        final mergedComments = [...localComments, ...remoteComments];

        return {
          ...remote, // Keep other fields from remote
          'likes': mergedLikes,
          'comments': mergedComments,
        };
      },
    ),
  );

  print('✓ Social app configured with custom conflict resolver');
  print('  - Merges likes (deduplicates)');
  print('  - Merges comments (keeps all)');
}

/// Example 2: Inventory App - Sum Quantities
///
/// Problem: When inventory is updated on multiple devices,
/// you want to sum the quantities, not replace them.
Future<void> inventoryAppExample() async {
  print('\n=== Inventory App Example ===\n');

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['inventory'],
      conflictStrategy: ConflictStrategy.custom,
      customConflictResolver: (local, remote, localTime, remoteTime) {
        // Sum quantities from both versions
        final localQty = local['quantity'] as int? ?? 0;
        final remoteQty = remote['quantity'] as int? ?? 0;

        return {
          ...remote, // Keep other fields from remote
          'quantity': localQty + remoteQty,
        };
      },
    ),
  );

  print('✓ Inventory app configured with custom conflict resolver');
  print('  - Sums quantities from both versions');
  print('  - Keeps latest metadata from remote');
}

/// Example 3: Collaborative Editing - Field-Level Merging
///
/// Problem: Multiple users editing different fields of the same document.
/// You want each field to use its own timestamp, not the document timestamp.
Future<void> collaborativeEditingExample() async {
  print('\n=== Collaborative Editing Example ===\n');

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['documents'],
      conflictStrategy: ConflictStrategy.custom,
      customConflictResolver: (local, remote, localTime, remoteTime) {
        final result = <String, dynamic>{};

        // Get all unique field names (excluding timestamp fields)
        final allFields = <String>{
          ...local.keys.where((k) => !k.endsWith('_updatedAt')),
          ...remote.keys.where((k) => !k.endsWith('_updatedAt')),
        };

        // For each field, use the version with the latest timestamp
        for (final field in allFields) {
          final localFieldTime = local['${field}_updatedAt'];
          final remoteFieldTime = remote['${field}_updatedAt'];

          if (localFieldTime is String && remoteFieldTime is String) {
            final localTime = DateTime.parse(localFieldTime);
            final remoteTime = DateTime.parse(remoteFieldTime);

            if (localTime.isAfter(remoteTime)) {
              result[field] = local[field];
              result['${field}_updatedAt'] = localFieldTime;
            } else {
              result[field] = remote[field];
              result['${field}_updatedAt'] = remoteFieldTime;
            }
          } else {
            // Fallback to document-level timestamp
            result[field] =
                localTime.isAfter(remoteTime) ? local[field] : remote[field];
          }
        }

        return result;
      },
    ),
  );

  print('✓ Collaborative editing configured with field-level merging');
  print('  - Each field uses its own timestamp');
  print('  - User A can edit title while User B edits content');
  print('  - Both changes are preserved');
}

/// Example 4: Analytics - Max Values
///
/// Problem: Analytics counters should always use the maximum value,
/// not the most recent one.
Future<void> analyticsExample() async {
  print('\n=== Analytics Example ===\n');

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['analytics'],
      conflictStrategy: ConflictStrategy.custom,
      customConflictResolver: (local, remote, localTime, remoteTime) {
        // Take maximum for numeric fields
        final result = Map<String, dynamic>.from(remote);

        for (final key in local.keys) {
          final localValue = local[key];
          final remoteValue = remote[key];

          if (localValue is num && remoteValue is num) {
            result[key] = localValue > remoteValue ? localValue : remoteValue;
          }
        }

        return result;
      },
    ),
  );

  print('✓ Analytics app configured with max value resolver');
  print('  - Always uses maximum value for counters');
  print('  - Prevents counter decreases');
}

/// Example 5: Document Editor - Deep Merge
///
/// Problem: Complex nested data structures need recursive merging.
Future<void> documentEditorExample() async {
  print('\n=== Document Editor Example ===\n');

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['documents'],
      conflictStrategy: ConflictStrategy.custom,
      customConflictResolver: (local, remote, localTime, remoteTime) {
        return _deepMerge(local, remote);
      },
    ),
  );

  print('✓ Document editor configured with deep merge');
  print('  - Recursively merges nested objects');
  print('  - Merges arrays and deduplicates');
}

Map<String, dynamic> _deepMerge(
  Map<String, dynamic> local,
  Map<String, dynamic> remote,
) {
  final result = Map<String, dynamic>.from(remote);

  for (final key in local.keys) {
    if (!remote.containsKey(key)) {
      result[key] = local[key];
    } else if (local[key] is Map && remote[key] is Map) {
      result[key] = _deepMerge(
        local[key] as Map<String, dynamic>,
        remote[key] as Map<String, dynamic>,
      );
    } else if (local[key] is List && remote[key] is List) {
      result[key] =
          [...local[key] as List, ...remote[key] as List].toSet().toList();
    }
  }

  return result;
}

/// Example 6: Using Pre-built Resolvers
///
/// SyncLayer provides pre-built resolvers for common scenarios.
Future<void> prebuiltResolversExample() async {
  print('\n=== Pre-built Resolvers Example ===\n');

  // Merge arrays
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['posts'],
      conflictStrategy: ConflictStrategy.custom,
      customConflictResolver: ConflictResolvers.mergeArrays(['tags', 'likes']),
    ),
  );
  print('✓ Using ConflictResolvers.mergeArrays()');

  // Sum numbers
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['inventory'],
      conflictStrategy: ConflictStrategy.custom,
      customConflictResolver:
          ConflictResolvers.sumNumbers(['quantity', 'views']),
    ),
  );
  print('✓ Using ConflictResolvers.sumNumbers()');

  // Merge specific fields
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['documents'],
      conflictStrategy: ConflictStrategy.custom,
      customConflictResolver:
          ConflictResolvers.mergeFields(['comments', 'likes']),
    ),
  );
  print('✓ Using ConflictResolvers.mergeFields()');

  // Max value
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['analytics'],
      conflictStrategy: ConflictStrategy.custom,
      customConflictResolver: ConflictResolvers.maxValue(['version', 'score']),
    ),
  );
  print('✓ Using ConflictResolvers.maxValue()');

  // Field-level last-write-wins
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['documents'],
      conflictStrategy: ConflictStrategy.custom,
      customConflictResolver: ConflictResolvers.fieldLevelLastWriteWins(),
    ),
  );
  print('✓ Using ConflictResolvers.fieldLevelLastWriteWins()');

  // Deep merge
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['documents'],
      conflictStrategy: ConflictStrategy.custom,
      customConflictResolver: ConflictResolvers.deepMerge(),
    ),
  );
  print('✓ Using ConflictResolvers.deepMerge()');

  print('\n=== Summary ===\n');
  print('Custom conflict resolvers allow you to:');
  print('  ✓ Merge arrays instead of replacing');
  print('  ✓ Sum quantities in inventory apps');
  print('  ✓ Merge likes and comments in social apps');
  print('  ✓ Field-level merging for collaborative editing');
  print('  ✓ Use maximum values for analytics');
  print('  ✓ Deep merge nested objects');
  print('\nChoose the strategy that fits your use case!');
}
