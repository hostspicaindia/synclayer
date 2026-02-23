# Sync Filters Guide

## Overview

Sync Filters allow you to control exactly what data gets synchronized between your app and the backend. This is essential for:

- **Privacy:** Users don't want to download everyone's data
- **Bandwidth:** Mobile users have limited data plans
- **Storage:** Devices have limited space
- **Security:** Multi-tenant apps need user isolation
- **Legal:** GDPR requires data minimization

## Table of Contents

- [Basic Usage](#basic-usage)
- [Filter Options](#filter-options)
- [Use Cases](#use-cases)
- [Backend Integration](#backend-integration)
- [Best Practices](#best-practices)
- [Examples](#examples)

## Basic Usage

Configure sync filters when initializing SyncLayer:

```dart
import 'package:synclayer/synclayer.dart';

await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['todos', 'notes'],
    syncFilters: {
      'todos': SyncFilter(
        where: {'userId': currentUserId},
      ),
    },
  ),
);
```

## Filter Options

### Where Conditions

Filter records based on field values:

```dart
SyncFilter(
  where: {
    'userId': currentUserId,
    'status': 'active',
    'archived': false,
  },
)
```

**How it works:**
- All conditions must match (AND logic)
- Simple equality checks only
- Works with strings, numbers, booleans

### Since Timestamp

Only sync records modified after a specific date:

```dart
SyncFilter(
  since: DateTime.now().subtract(Duration(days: 30)),
)
```

**Use cases:**
- Sync only recent data
- Implement data retention policies
- Reduce initial sync time

### Limit

Limit the number of records synced:

```dart
SyncFilter(
  limit: 100,
)
```

**Use cases:**
- Progressive sync (load more later)
- Reduce initial sync time
- Implement pagination

### Field Inclusion

Only sync specific fields:

```dart
SyncFilter(
  fields: ['id', 'title', 'status', 'createdAt'],
)
```

**Benefits:**
- Reduces bandwidth usage
- Faster sync times
- Smaller local storage

### Field Exclusion

Exclude specific fields from sync:

```dart
SyncFilter(
  excludeFields: ['fullContent', 'attachments', 'thumbnail'],
)
```

**Benefits:**
- Keep large fields on server
- Reduce bandwidth usage
- Faster sync times

**Note:** Cannot use both `fields` and `excludeFields` together.

## Use Cases

### 1. Multi-Tenant Applications

Only sync data belonging to the current user:

```dart
final currentUserId = 'user-123';

syncFilters: {
  'todos': SyncFilter(
    where: {'userId': currentUserId},
  ),
  'notes': SyncFilter(
    where: {'userId': currentUserId},
  ),
  'projects': SyncFilter(
    where: {'userId': currentUserId},
  ),
}
```

**Benefits:**
- Privacy: Users can't see others' data
- Security: Data isolation
- Performance: Less data to sync

### 2. Time-Based Data Retention

Only sync recent data:

```dart
syncFilters: {
  'messages': SyncFilter(
    since: DateTime.now().subtract(Duration(days: 7)),
  ),
  'logs': SyncFilter(
    since: DateTime.now().subtract(Duration(days: 1)),
  ),
}
```

**Benefits:**
- Compliance: GDPR data retention
- Storage: Less local data
- Performance: Faster sync

### 3. Bandwidth Optimization

Exclude large fields:

```dart
syncFilters: {
  'documents': SyncFilter(
    excludeFields: [
      'fullContent',      // Large text
      'attachments',      // Binary data
      'thumbnail',        // Images
      'metadata',         // Extra info
    ],
  ),
}
```

**Benefits:**
- 70-90% bandwidth reduction
- Faster sync on mobile
- Lower data costs

### 4. Progressive Sync

Load data in stages:

```dart
// Initial sync: First 50 items
syncFilters: {
  'todos': SyncFilter(
    limit: 50,
    where: {'userId': currentUserId},
  ),
}

// Later: Update filter to load more
// (requires re-initialization)
```

**Benefits:**
- Faster app startup
- Better user experience
- Gradual data loading

### 5. GDPR Compliance

Implement data minimization:

```dart
syncFilters: {
  'user_data': SyncFilter(
    where: {
      'userId': currentUserId,
      'consentGiven': true,        // Only with consent
    },
    since: DateTime.now().subtract(
      Duration(days: 365),           // 1 year retention
    ),
    excludeFields: [
      'ssn',                         // Sensitive data
      'creditCard',
      'medicalRecords',
    ],
  ),
}
```

**Benefits:**
- Legal compliance
- User privacy
- Data minimization

### 6. Mobile Optimization

Optimize for mobile networks:

```dart
syncFilters: {
  'messages': SyncFilter(
    where: {'userId': currentUserId},
    since: DateTime.now().subtract(Duration(days: 7)),
    fields: ['id', 'text', 'senderId', 'timestamp'],
    limit: 200,
  ),
  'media': SyncFilter(
    where: {'userId': currentUserId},
    fields: ['id', 'thumbnailUrl', 'type'],
    // Exclude full resolution images
  ),
}
```

**Benefits:**
- 90%+ bandwidth savings
- Faster sync on slow networks
- Lower data costs

## Backend Integration

### REST API

Sync filters are converted to query parameters:

```dart
SyncFilter(
  where: {'userId': '123', 'status': 'active'},
  since: DateTime(2024, 1, 1),
  limit: 50,
  fields: ['id', 'title'],
)
```

Becomes:
```
GET /sync/todos?where[userId]=123&where[status]=active&since=2024-01-01T00:00:00.000Z&limit=50&fields=id,title
```

**Backend implementation:**

```javascript
app.get('/sync/:collection', (req, res) => {
  const { collection } = req.params;
  const { since, limit, offset } = req.query;
  
  // Parse where conditions
  const where = {};
  for (const [key, value] of Object.entries(req.query)) {
    if (key.startsWith('where[')) {
      const field = key.slice(6, -1); // Extract field name
      where[field] = value;
    }
  }
  
  // Parse fields
  const fields = req.query.fields?.split(',');
  const excludeFields = req.query.excludeFields?.split(',');
  
  // Query database
  let query = db.collection(collection).find(where);
  
  if (since) {
    query = query.where('updatedAt', '>', new Date(since));
  }
  
  if (limit) {
    query = query.limit(parseInt(limit));
  }
  
  if (offset) {
    query = query.skip(parseInt(offset));
  }
  
  const records = await query.toArray();
  
  // Apply field filtering
  const filtered = records.map(record => {
    if (fields) {
      return fields.reduce((obj, field) => {
        obj[field] = record[field];
        return obj;
      }, {});
    }
    if (excludeFields) {
      const copy = { ...record };
      excludeFields.forEach(field => delete copy[field]);
      return copy;
    }
    return record;
  });
  
  res.json({ records: filtered });
});
```

### Firebase

Filters are applied as Firestore queries:

```dart
SyncFilter(
  where: {'userId': '123'},
  since: DateTime(2024, 1, 1),
  limit: 50,
)
```

Becomes:
```dart
firestore
  .collection('todos')
  .where('data.userId', isEqualTo: '123')
  .where('updatedAt', isGreaterThan: Timestamp.fromDate(since))
  .limit(50)
  .get();
```

### Supabase

Filters are applied as PostgreSQL queries:

```dart
SyncFilter(
  where: {'userId': '123'},
  since: DateTime(2024, 1, 1),
)
```

Becomes:
```dart
supabase
  .from('todos')
  .select()
  .eq('data->>userId', '123')
  .gt('updated_at', since.toIso8601String())
  .execute();
```

### Appwrite

Filters are applied as Appwrite queries:

```dart
SyncFilter(
  where: {'userId': '123'},
  limit: 50,
)
```

Becomes:
```dart
databases.listDocuments(
  databaseId: databaseId,
  collectionId: 'todos',
  queries: [
    Query.equal('data.userId', '123'),
    Query.limit(50),
  ],
);
```

## Best Practices

### 1. Always Filter by User

For multi-tenant apps, always filter by user ID:

```dart
syncFilters: {
  'todos': SyncFilter(
    where: {'userId': currentUserId},
  ),
}
```

### 2. Use Time-Based Filtering

Limit data to recent records:

```dart
syncFilters: {
  'todos': SyncFilter(
    where: {'userId': currentUserId},
    since: DateTime.now().subtract(Duration(days: 90)),
  ),
}
```

### 3. Exclude Large Fields

Don't sync unnecessary data:

```dart
syncFilters: {
  'documents': SyncFilter(
    where: {'userId': currentUserId},
    excludeFields: ['fullContent', 'attachments'],
  ),
}
```

### 4. Use Limits for Progressive Sync

Start with a small limit:

```dart
syncFilters: {
  'todos': SyncFilter(
    where: {'userId': currentUserId},
    limit: 50, // Load more later
  ),
}
```

### 5. Combine Filters

Use multiple filter options together:

```dart
syncFilters: {
  'todos': SyncFilter(
    where: {
      'userId': currentUserId,
      'archived': false,
    },
    since: DateTime.now().subtract(Duration(days: 30)),
    limit: 100,
    excludeFields: ['attachments'],
  ),
}
```

### 6. Test Filter Performance

Monitor sync performance with different filters:

```dart
final metrics = SyncLayer.getMetrics();
print('Sync duration: ${metrics.averageSyncDuration}');
print('Records synced: ${metrics.totalOperations}');
```

### 7. Document Your Filters

Add comments explaining filter logic:

```dart
syncFilters: {
  'todos': SyncFilter(
    // Only sync user's own data (privacy)
    where: {'userId': currentUserId},
    // Only last 90 days (data retention policy)
    since: DateTime.now().subtract(Duration(days: 90)),
    // Exclude large fields (bandwidth optimization)
    excludeFields: ['attachments', 'comments'],
  ),
}
```

## Examples

### Example 1: Simple Multi-Tenant

```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['todos'],
    syncFilters: {
      'todos': SyncFilter(
        where: {'userId': currentUserId},
      ),
    },
  ),
);
```

### Example 2: Time-Based Filtering

```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['messages'],
    syncFilters: {
      'messages': SyncFilter(
        since: DateTime.now().subtract(Duration(days: 7)),
      ),
    },
  ),
);
```

### Example 3: Bandwidth Optimization

```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['documents'],
    syncFilters: {
      'documents': SyncFilter(
        fields: ['id', 'title', 'summary', 'createdAt'],
      ),
    },
  ),
);
```

### Example 4: Complete Todo App

```dart
final currentUserId = 'user-123';

await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    authToken: userAuthToken,
    collections: ['todos', 'projects', 'tags'],
    syncFilters: {
      // Todos: User's active todos from last 90 days
      'todos': SyncFilter(
        where: {
          'userId': currentUserId,
          'deleted': false,
        },
        since: DateTime.now().subtract(Duration(days: 90)),
      ),
      // Projects: User's projects only
      'projects': SyncFilter(
        where: {'userId': currentUserId},
      ),
      // Tags: User's tags, exclude metadata
      'tags': SyncFilter(
        where: {'userId': currentUserId},
        excludeFields: ['usage_stats', 'metadata'],
      ),
    },
  ),
);
```

### Example 5: GDPR Compliant App

```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['user_data'],
    syncFilters: {
      'user_data': SyncFilter(
        // Data minimization
        where: {
          'userId': currentUserId,
          'consentGiven': true,
        },
        // Data retention (12 months)
        since: DateTime.now().subtract(Duration(days: 365)),
        // Privacy (exclude sensitive fields)
        excludeFields: [
          'ssn',
          'creditCard',
          'medicalRecords',
          'biometricData',
        ],
      ),
    },
  ),
);
```

### Example 6: Mobile-Optimized App

```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['messages', 'media'],
    syncFilters: {
      // Messages: Recent, essential fields only
      'messages': SyncFilter(
        where: {'userId': currentUserId},
        since: DateTime.now().subtract(Duration(days: 7)),
        fields: ['id', 'text', 'senderId', 'timestamp'],
        limit: 200,
      ),
      // Media: Thumbnails only
      'media': SyncFilter(
        where: {'userId': currentUserId},
        fields: ['id', 'thumbnailUrl', 'type'],
      ),
    },
  ),
);
```

## Troubleshooting

### Filter Not Working

**Problem:** Data still syncing without filter

**Solution:** Check that:
1. Filter is configured in `syncFilters` map
2. Collection name matches exactly
3. Backend supports filter parameters
4. Field names are correct

### Too Much Data Syncing

**Problem:** Still downloading too much data

**Solution:**
1. Add more restrictive `where` conditions
2. Use `since` to limit time range
3. Add `limit` to cap number of records
4. Use `excludeFields` to remove large fields

### Backend Errors

**Problem:** Backend returns errors with filters

**Solution:**
1. Check backend logs for query errors
2. Verify backend supports filter parameters
3. Test backend endpoint directly
4. Check field names and types

### Performance Issues

**Problem:** Sync is slow with filters

**Solution:**
1. Add database indexes for filter fields
2. Use `limit` to reduce data volume
3. Exclude large fields
4. Monitor with `SyncLayer.getMetrics()`

## API Reference

### SyncFilter Class

```dart
class SyncFilter {
  /// Field-based filters (AND logic)
  final Map<String, dynamic>? where;
  
  /// Only sync records after this timestamp
  final DateTime? since;
  
  /// Maximum number of records to sync
  final int? limit;
  
  /// Fields to include (mutually exclusive with excludeFields)
  final List<String>? fields;
  
  /// Fields to exclude (mutually exclusive with fields)
  final List<String>? excludeFields;
  
  const SyncFilter({
    this.where,
    this.since,
    this.limit,
    this.fields,
    this.excludeFields,
  });
  
  /// Check if a record matches this filter
  bool matches(Map<String, dynamic> data, DateTime? updatedAt);
  
  /// Apply field filtering to a record
  Map<String, dynamic> applyFieldFilter(Map<String, dynamic> data);
  
  /// Convert filter to query parameters
  Map<String, dynamic> toQueryParams();
  
  /// Create a copy with modified properties
  SyncFilter copyWith({...});
}
```

### SyncConfig Integration

```dart
class SyncConfig {
  /// Sync filters per collection
  final Map<String, SyncFilter> syncFilters;
  
  const SyncConfig({
    // ... other parameters
    this.syncFilters = const {},
  });
}
```

## See Also

- [API Reference](API_REFERENCE.md)
- [Query Guide](QUERY_GUIDE.md)
- [Platform Adapters](PLATFORM_ADAPTERS.md)
- [Examples](../example/)
