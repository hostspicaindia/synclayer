# Quick Start: Sync Filters

Get started with Selective Sync in 5 minutes!

## What Are Sync Filters?

Sync filters let you control what data gets synced between your app and backend. Essential for:

- 🔒 **Privacy** - Users only sync their own data
- 📱 **Bandwidth** - Save 70-90% on data usage
- 💾 **Storage** - Keep local database small
- ⚖️ **Compliance** - GDPR data minimization

## Installation

```yaml
dependencies:
  synclayer: ^1.2.0
```

```bash
flutter pub get
```

## 5-Minute Tutorial

### Step 1: Basic Setup (No Filters)

```dart
import 'package:synclayer/synclayer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Without filters - syncs ALL data
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['todos'],
    ),
  );
  
  runApp(MyApp());
}
```

**Problem:** This syncs ALL todos from ALL users!

### Step 2: Add User Filter

```dart
import 'package:synclayer/synclayer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final currentUserId = 'user-123'; // Get from auth
  
  // With filter - syncs ONLY user's data
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
  
  runApp(MyApp());
}
```

**Result:** Now only syncs current user's todos! 🎉

### Step 3: Add Time Filter

```dart
syncFilters: {
  'todos': SyncFilter(
    where: {'userId': currentUserId},
    since: DateTime.now().subtract(Duration(days: 30)),
  ),
}
```

**Result:** Only syncs user's todos from last 30 days!

### Step 4: Optimize Bandwidth

```dart
syncFilters: {
  'todos': SyncFilter(
    where: {'userId': currentUserId},
    since: DateTime.now().subtract(Duration(days: 30)),
    excludeFields: ['attachments', 'comments'],
  ),
}
```

**Result:** Excludes large fields - saves 70-90% bandwidth!

## Common Patterns

### Pattern 1: Multi-Tenant App

```dart
final currentUserId = getCurrentUserId();

await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['todos', 'notes', 'projects'],
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
    },
  ),
);
```

### Pattern 2: Mobile App

```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['messages', 'media'],
    syncFilters: {
      'messages': SyncFilter(
        where: {'userId': currentUserId},
        since: DateTime.now().subtract(Duration(days: 7)),
        fields: ['id', 'text', 'timestamp'],
        limit: 200,
      ),
      'media': SyncFilter(
        where: {'userId': currentUserId},
        fields: ['id', 'thumbnailUrl'],
      ),
    },
  ),
);
```

### Pattern 3: GDPR Compliant

```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['user_data'],
    syncFilters: {
      'user_data': SyncFilter(
        where: {
          'userId': currentUserId,
          'consentGiven': true,
        },
        since: DateTime.now().subtract(Duration(days: 365)),
        excludeFields: ['ssn', 'creditCard'],
      ),
    },
  ),
);
```

## Filter Options Reference

### where

Filter by field values (AND logic):

```dart
where: {
  'userId': currentUserId,
  'status': 'active',
  'archived': false,
}
```

### since

Only sync records after this date:

```dart
since: DateTime.now().subtract(Duration(days: 30))
```

### limit

Maximum number of records:

```dart
limit: 100
```

### fields

Only sync these fields:

```dart
fields: ['id', 'title', 'status']
```

### excludeFields

Don't sync these fields:

```dart
excludeFields: ['fullContent', 'attachments']
```

**Note:** Can't use both `fields` and `excludeFields`

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:synclayer/synclayer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Get current user
  final currentUserId = await getCurrentUserId();
  
  // Initialize with filters
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      authToken: await getAuthToken(),
      collections: ['todos'],
      syncFilters: {
        'todos': SyncFilter(
          // Only user's data
          where: {'userId': currentUserId},
          // Only last 90 days
          since: DateTime.now().subtract(Duration(days: 90)),
          // Exclude large fields
          excludeFields: ['attachments'],
        ),
      },
    ),
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Todos')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SyncLayer.collection('todos').watch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          
          final todos = snapshot.data!;
          
          return ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return ListTile(
                title: Text(todo['text']),
                trailing: Checkbox(
                  value: todo['done'] ?? false,
                  onChanged: (value) async {
                    await SyncLayer.collection('todos').save(
                      {...todo, 'done': value},
                      id: todo['id'],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await SyncLayer.collection('todos').save({
            'text': 'New todo',
            'done': false,
            'userId': await getCurrentUserId(),
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

Future<String> getCurrentUserId() async {
  // Get from your auth system
  return 'user-123';
}

Future<String> getAuthToken() async {
  // Get from your auth system
  return 'auth-token';
}
```

## Testing Your Filters

### 1. Check Sync Metrics

```dart
final metrics = SyncLayer.getMetrics();
print('Records synced: ${metrics.totalOperations}');
print('Sync duration: ${metrics.averageSyncDuration}');
```

### 2. Verify Data

```dart
final todos = await SyncLayer.collection('todos').getAll();
print('Total todos: ${todos.length}');

// Verify all belong to current user
final allMine = todos.every((t) => t['userId'] == currentUserId);
print('All mine: $allMine');
```

### 3. Test Bandwidth

```dart
// Before filters
print('Syncing without filters...');
await SyncLayer.syncNow();
// Check network usage in DevTools

// After filters
print('Syncing with filters...');
await SyncLayer.syncNow();
// Compare network usage
```

## Backend Setup

### REST API

Your backend needs to handle filter parameters:

```javascript
app.get('/sync/:collection', (req, res) => {
  const { collection } = req.params;
  const { since, limit } = req.query;
  
  // Parse where conditions
  const where = {};
  for (const [key, value] of Object.entries(req.query)) {
    if (key.startsWith('where[')) {
      const field = key.slice(6, -1);
      where[field] = value;
    }
  }
  
  // Query database
  let query = db.collection(collection).find(where);
  
  if (since) {
    query = query.where('updatedAt', '>', new Date(since));
  }
  
  if (limit) {
    query = query.limit(parseInt(limit));
  }
  
  const records = await query.toArray();
  res.json({ records });
});
```

### Firebase/Supabase/Appwrite

No backend changes needed - adapters handle filters automatically!

## Troubleshooting

### Filters Not Working?

1. Check collection name matches:
   ```dart
   collections: ['todos'],  // Must match
   syncFilters: {
     'todos': SyncFilter(...),  // Must match
   }
   ```

2. Enable debug logging:
   ```dart
   SyncLayer.configureLogger(
     enabled: true,
     minLevel: LogLevel.debug,
   );
   ```

3. Test backend directly:
   ```bash
   curl "http://localhost:3000/sync/todos?where[userId]=123"
   ```

### Still Syncing Too Much?

Add more filters:

```dart
SyncFilter(
  where: {'userId': currentUserId},
  since: DateTime.now().subtract(Duration(days: 30)),
  limit: 100,
  excludeFields: ['attachments'],
)
```

## Next Steps

- 📖 [Complete Sync Filters Guide](SYNC_FILTERS.md)
- 📖 [API Reference](API_REFERENCE.md)
- 💻 [Full Examples](../example/sync_filter_example.dart)
- 🔄 [Migration Guide](MIGRATION_GUIDE_v1.2.0.md)

## Summary

✅ Add `syncFilters` to `SyncConfig`  
✅ Use `where` for user filtering  
✅ Use `since` for time filtering  
✅ Use `excludeFields` for bandwidth  
✅ Combine filters for best results  

**That's it!** You're now syncing only what you need. 🎉
