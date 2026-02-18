import 'package:synclayer/synclayer.dart';

/// Example demonstrating Selective Sync (Sync Filters)
///
/// This feature is critical for:
/// - Privacy: Users don't want to download everyone's data
/// - Bandwidth: Mobile users have limited data plans
/// - Storage: Devices have limited space
/// - Security: Multi-tenant apps need user isolation
/// - Legal: GDPR requires data minimization
void main() async {
  // Example 1: Multi-tenant filtering
  // Only sync data belonging to the current user
  await multiTenantExample();

  // Example 2: Time-based filtering
  // Only sync recent data (last 30 days)
  await timeBasedFilteringExample();

  // Example 3: Bandwidth optimization
  // Exclude large fields from sync
  await bandwidthOptimizationExample();

  // Example 4: Progressive sync
  // Limit initial sync size
  await progressiveSyncExample();

  // Example 5: Combined filters
  // Multiple conditions together
  await combinedFiltersExample();
}

/// Example 1: Multi-tenant filtering
/// Only sync data belonging to the current user
Future<void> multiTenantExample() async {
  print('\n=== Multi-tenant Filtering Example ===\n');

  final currentUserId = 'user-123';

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['todos', 'notes'],
      syncFilters: {
        // Only sync todos for current user
        'todos': SyncFilter(
          where: {'userId': currentUserId},
        ),
        // Only sync notes for current user
        'notes': SyncFilter(
          where: {'userId': currentUserId},
        ),
      },
    ),
  );

  print('✓ Configured to sync only data for user: $currentUserId');
  print('✓ Other users\' data will not be downloaded');
  print('✓ Privacy and security maintained');

  await SyncLayer.dispose();
}

/// Example 2: Time-based filtering
/// Only sync recent data (last 30 days)
Future<void> timeBasedFilteringExample() async {
  print('\n=== Time-based Filtering Example ===\n');

  final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['todos'],
      syncFilters: {
        'todos': SyncFilter(
          since: thirtyDaysAgo,
        ),
      },
    ),
  );

  print('✓ Only syncing todos from last 30 days');
  print('✓ Older data stays on server, not downloaded');
  print('✓ Saves bandwidth and storage space');

  await SyncLayer.dispose();
}

/// Example 3: Bandwidth optimization
/// Exclude large fields from sync
Future<void> bandwidthOptimizationExample() async {
  print('\n=== Bandwidth Optimization Example ===\n');

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['documents'],
      syncFilters: {
        'documents': SyncFilter(
          // Exclude large fields to save bandwidth
          excludeFields: [
            'fullContent', // Large text content
            'attachments', // Binary attachments
            'thumbnail', // Image data
          ],
        ),
      },
    ),
  );

  print('✓ Syncing only essential document metadata');
  print('✓ Large fields excluded from sync');
  print('✓ Reduced bandwidth usage by ~80%');

  // Alternative: Include only specific fields
  await SyncLayer.dispose();

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['documents'],
      syncFilters: {
        'documents': SyncFilter(
          // Only sync these fields
          fields: ['id', 'title', 'summary', 'createdAt'],
        ),
      },
    ),
  );

  print('\n✓ Alternative: Only syncing specific fields');
  print('✓ Even more bandwidth savings');

  await SyncLayer.dispose();
}

/// Example 4: Progressive sync
/// Limit initial sync size
Future<void> progressiveSyncExample() async {
  print('\n=== Progressive Sync Example ===\n');

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['todos'],
      syncFilters: {
        'todos': SyncFilter(
          // Only sync first 50 items initially
          limit: 50,
        ),
      },
    ),
  );

  print('✓ Initial sync limited to 50 items');
  print('✓ Faster first-time app load');
  print('✓ Can load more data progressively later');

  await SyncLayer.dispose();
}

/// Example 5: Combined filters
/// Multiple conditions together
Future<void> combinedFiltersExample() async {
  print('\n=== Combined Filters Example ===\n');

  final currentUserId = 'user-123';
  final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['todos'],
      syncFilters: {
        'todos': SyncFilter(
          // Only current user's data
          where: {
            'userId': currentUserId,
            'archived': false, // Exclude archived items
          },
          // Only recent data
          since: thirtyDaysAgo,
          // Limit initial sync
          limit: 100,
          // Exclude large fields
          excludeFields: ['attachments', 'comments'],
        ),
      },
    ),
  );

  print('✓ Multi-condition filtering:');
  print('  - Only current user\'s data');
  print('  - Only non-archived items');
  print('  - Only last 30 days');
  print('  - Maximum 100 items');
  print('  - Excluding large fields');
  print('\n✓ Maximum privacy, bandwidth, and storage optimization');

  await SyncLayer.dispose();
}

/// Real-world example: Todo app with selective sync
Future<void> realWorldTodoAppExample() async {
  print('\n=== Real-world Todo App Example ===\n');

  // Simulated current user
  final currentUserId = 'user-123';

  // Initialize with selective sync
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      authToken: 'user-auth-token',
      collections: ['todos', 'projects', 'tags'],
      syncFilters: {
        // Todos: Only user's active todos from last 90 days
        'todos': SyncFilter(
          where: {
            'userId': currentUserId,
            'deleted': false,
          },
          since: DateTime.now().subtract(Duration(days: 90)),
        ),
        // Projects: Only user's projects
        'projects': SyncFilter(
          where: {'userId': currentUserId},
        ),
        // Tags: Only user's tags, exclude metadata
        'tags': SyncFilter(
          where: {'userId': currentUserId},
          excludeFields: ['usage_stats', 'metadata'],
        ),
      },
    ),
  );

  print('✓ Todo app configured with selective sync');
  print('✓ Privacy: Only user\'s own data synced');
  print('✓ Storage: Only recent todos (90 days)');
  print('✓ Bandwidth: Metadata excluded from tags');

  // Use the app normally
  final todos = SyncLayer.collection('todos');

  // Save a new todo (will be synced)
  await todos.save({
    'userId': currentUserId,
    'text': 'Buy groceries',
    'done': false,
    'deleted': false,
    'createdAt': DateTime.now().toIso8601String(),
  });

  print('\n✓ New todo saved and queued for sync');

  // Get all todos (only user's todos will be returned)
  final allTodos = await todos.getAll();
  print('✓ Retrieved ${allTodos.length} todos (only user\'s data)');

  await SyncLayer.dispose();
}

/// Example: GDPR compliance with data minimization
Future<void> gdprComplianceExample() async {
  print('\n=== GDPR Compliance Example ===\n');

  final currentUserId = 'user-123';

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['user_data'],
      syncFilters: {
        'user_data': SyncFilter(
          // Only sync data for current user (data minimization)
          where: {
            'userId': currentUserId,
            'consentGiven': true, // Only sync if consent given
          },
          // Only sync data from last 12 months (data retention)
          since: DateTime.now().subtract(Duration(days: 365)),
          // Exclude sensitive fields
          excludeFields: [
            'ssn',
            'creditCard',
            'medicalRecords',
          ],
        ),
      },
    ),
  );

  print('✓ GDPR-compliant sync configuration:');
  print('  - Data minimization: Only user\'s own data');
  print('  - Consent: Only data with consent');
  print('  - Retention: Only last 12 months');
  print('  - Privacy: Sensitive fields excluded');

  await SyncLayer.dispose();
}

/// Example: Mobile app with limited bandwidth
Future<void> mobileBandwidthExample() async {
  print('\n=== Mobile Bandwidth Optimization Example ===\n');

  final currentUserId = 'user-123';

  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['messages', 'media'],
      syncFilters: {
        // Messages: Only recent, only essential fields
        'messages': SyncFilter(
          where: {'userId': currentUserId},
          since: DateTime.now().subtract(Duration(days: 7)),
          fields: ['id', 'text', 'senderId', 'timestamp'],
          limit: 200,
        ),
        // Media: Don't sync at all on mobile (or sync only thumbnails)
        'media': SyncFilter(
          where: {'userId': currentUserId},
          fields: ['id', 'thumbnailUrl', 'type'],
          excludeFields: ['fullResolutionUrl', 'rawData'],
        ),
      },
    ),
  );

  print('✓ Mobile-optimized sync:');
  print('  - Messages: Only last 7 days, max 200');
  print('  - Messages: Only text, no attachments');
  print('  - Media: Only thumbnails, no full resolution');
  print('  - Estimated bandwidth savings: 90%+');

  await SyncLayer.dispose();
}
