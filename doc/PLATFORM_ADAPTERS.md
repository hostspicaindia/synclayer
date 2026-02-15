# Platform Adapters Guide

SyncLayer provides built-in adapters for popular backend platforms. This guide shows you how to use them.

---

## Overview

SyncLayer includes ready-to-use adapters for:

- **Firebase Firestore** - Google's NoSQL cloud database
- **Supabase** - Open-source Firebase alternative with PostgreSQL
- **Appwrite** - Open-source backend-as-a-service platform

You can also create custom adapters for any backend by implementing `SyncBackendAdapter`.

---

## Firebase Firestore

### 1. Add Dependencies

```yaml
dependencies:
  synclayer: ^0.1.0
  firebase_core: ^3.10.0
  cloud_firestore: ^5.7.0
```

### 2. Setup Firebase

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:synclayer/synclayer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize SyncLayer with Firebase adapter
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://firebaseapp.com', // Not used with Firebase
      customBackendAdapter: FirebaseAdapter(
        firestore: FirebaseFirestore.instance,
      ),
      collections: ['todos', 'users', 'notes'],
      syncInterval: Duration(minutes: 5),
    ),
  );
  
  runApp(MyApp());
}
```

### 3. Firestore Data Structure

The adapter expects documents in this format:

```
/todos/{recordId}
  - data: Map<String, dynamic>  // Your document data
  - updatedAt: Timestamp         // Last update time
  - version: int                 // Version number
```

### 4. Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /{collection}/{recordId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 5. Example Usage

```dart
// Save data (syncs to Firestore)
final id = await SyncLayer.collection('todos').save({
  'text': 'Buy groceries',
  'completed': false,
  'userId': FirebaseAuth.instance.currentUser!.uid,
});

// Data is automatically synced to Firestore
// Other devices will receive updates via pull sync
```

---

## Supabase

### 1. Add Dependencies

```yaml
dependencies:
  synclayer: ^0.1.0
  supabase_flutter: ^2.9.0
```

### 2. Setup Supabase

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synclayer/synclayer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://your-project.supabase.co',
    anonKey: 'your-anon-key',
  );
  
  // Initialize SyncLayer with Supabase adapter
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://your-project.supabase.co', // Not used
      customBackendAdapter: SupabaseAdapter(
        client: Supabase.instance.client,
      ),
      collections: ['todos', 'users', 'notes'],
      syncInterval: Duration(minutes: 5),
    ),
  );
  
  runApp(MyApp());
}
```

### 3. Database Schema

Create tables in Supabase with this structure:

```sql
-- Example: todos table
CREATE TABLE todos (
  record_id TEXT PRIMARY KEY,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  version INTEGER NOT NULL DEFAULT 1,
  user_id UUID REFERENCES auth.users(id)
);

-- Index for efficient pull sync
CREATE INDEX idx_todos_updated_at ON todos(updated_at);

-- Enable Row Level Security
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access their own data
CREATE POLICY "Users can access own data" ON todos
  FOR ALL USING (auth.uid() = user_id);
```

### 4. Example Usage

```dart
// Save data (syncs to Supabase)
final id = await SyncLayer.collection('todos').save({
  'text': 'Buy groceries',
  'completed': false,
  'userId': Supabase.instance.client.auth.currentUser!.id,
});

// Data is automatically synced to Supabase PostgreSQL
```

---

## Appwrite

### 1. Add Dependencies

```yaml
dependencies:
  synclayer: ^0.1.0
  appwrite: ^14.0.0
```

### 2. Setup Appwrite

```dart
import 'package:appwrite/appwrite.dart';
import 'package:synclayer/synclayer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Appwrite
  final client = Client()
    ..setEndpoint('https://cloud.appwrite.io/v1')
    ..setProject('your-project-id');
  
  // Initialize SyncLayer with Appwrite adapter
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://cloud.appwrite.io', // Not used
      customBackendAdapter: AppwriteAdapter(
        databases: Databases(client),
        databaseId: 'your-database-id',
      ),
      collections: ['todos', 'users', 'notes'],
      syncInterval: Duration(minutes: 5),
    ),
  );
  
  runApp(MyApp());
}
```

### 3. Appwrite Collection Setup

Create collections in Appwrite Console with these attributes:

```
Collection: todos
Attributes:
  - data (JSON) - Required
  - updated_at (DateTime) - Required
  - version (Integer) - Required, Default: 1

Indexes:
  - updated_at (ASC) - For efficient pull sync

Permissions:
  - Read: Users
  - Write: Users
```

### 4. Example Usage

```dart
// Save data (syncs to Appwrite)
final id = await SyncLayer.collection('todos').save({
  'text': 'Buy groceries',
  'completed': false,
});

// Data is automatically synced to Appwrite
```

---

## Custom Adapter

If you need to integrate with a different backend, create a custom adapter:

### 1. Implement SyncBackendAdapter

```dart
import 'package:synclayer/synclayer.dart';

class MyCustomAdapter implements SyncBackendAdapter {
  final MyBackendClient client;

  MyCustomAdapter({required this.client});

  @override
  Future<void> push({
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    required DateTime timestamp,
  }) async {
    // Push data to your backend
    await client.post('/sync/$collection', {
      'recordId': recordId,
      'data': data,
      'updatedAt': timestamp.toIso8601String(),
    });
  }

  @override
  Future<List<SyncRecord>> pull({
    required String collection,
    DateTime? since,
  }) async {
    // Pull data from your backend
    final response = await client.get(
      '/sync/$collection',
      queryParameters: since != null ? {'since': since.toIso8601String()} : null,
    );

    return (response.data as List).map((item) {
      return SyncRecord(
        recordId: item['recordId'],
        data: item['data'],
        updatedAt: DateTime.parse(item['updatedAt']),
        version: item['version'] ?? 1,
      );
    }).toList();
  }

  @override
  Future<void> delete({
    required String collection,
    required String recordId,
  }) async {
    await client.delete('/sync/$collection/$recordId');
  }

  @override
  void updateAuthToken(String token) {
    client.setAuthToken(token);
  }
}
```

### 2. Use Your Custom Adapter

```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    customBackendAdapter: MyCustomAdapter(
      client: MyBackendClient(),
    ),
    collections: ['todos'],
  ),
);
```

---

## Comparison

| Feature | Firebase | Supabase | Appwrite | Custom |
|---------|----------|----------|----------|--------|
| Setup Complexity | Easy | Easy | Easy | Medium |
| Real-time Support | ✅ | ✅ | ✅ | Depends |
| Self-hosted | ❌ | ✅ | ✅ | ✅ |
| Free Tier | ✅ | ✅ | ✅ | N/A |
| SQL Database | ❌ | ✅ | ❌ | Depends |
| Authentication | ✅ | ✅ | ✅ | Depends |

---

## Best Practices

### 1. Use Row-Level Security

Always enable RLS (Supabase) or security rules (Firebase/Appwrite) to protect user data:

```sql
-- Supabase example
CREATE POLICY "Users can only access own data" ON todos
  FOR ALL USING (auth.uid() = user_id);
```

### 2. Add Indexes

Index the `updated_at` field for efficient pull sync:

```sql
-- Supabase
CREATE INDEX idx_todos_updated_at ON todos(updated_at);
```

### 3. Handle Authentication

Update auth tokens when users sign in:

```dart
// Firebase
FirebaseAuth.instance.authStateChanges().listen((user) {
  if (user != null) {
    // Token is automatically handled by Firebase SDK
  }
});

// Supabase
Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  if (data.session != null) {
    // Token is automatically handled by Supabase SDK
  }
});
```

### 4. Monitor Sync Events

Listen for sync events to handle errors:

```dart
SyncLayerCore.instance.syncEngine.events.listen((event) {
  if (event.type == SyncEventType.syncFailed) {
    print('Sync failed: ${event.error}');
    // Show error to user
  }
});
```

---

## Troubleshooting

### Firebase: Permission Denied

**Problem:** `PERMISSION_DENIED: Missing or insufficient permissions`

**Solution:** Check Firestore security rules and ensure user is authenticated:

```javascript
match /{collection}/{recordId} {
  allow read, write: if request.auth != null;
}
```

### Supabase: RLS Policy Error

**Problem:** `new row violates row-level security policy`

**Solution:** Ensure RLS policies allow the operation:

```sql
-- Check existing policies
SELECT * FROM pg_policies WHERE tablename = 'todos';

-- Create policy if missing
CREATE POLICY "Enable insert for authenticated users" ON todos
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### Appwrite: Document Not Found

**Problem:** `Document with the requested ID could not be found`

**Solution:** Ensure collection and database IDs are correct:

```dart
AppwriteAdapter(
  databases: Databases(client),
  databaseId: 'your-database-id', // Check this in Appwrite Console
)
```

---

## Migration Guide

### From REST to Firebase

```dart
// Before
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
  ),
);

// After
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://firebaseapp.com', // Not used
    customBackendAdapter: FirebaseAdapter(
      firestore: FirebaseFirestore.instance,
    ),
  ),
);
```

### From Firebase to Supabase

1. Export data from Firestore
2. Create Supabase tables with proper schema
3. Import data to Supabase
4. Update SyncLayer config:

```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://your-project.supabase.co',
    customBackendAdapter: SupabaseAdapter(
      client: Supabase.instance.client,
    ),
  ),
);
```

---

## Next Steps

- See [API Reference](API_REFERENCE.md) for complete API documentation
- Check [examples](../example/) for working implementations
- Read [CONTRIBUTING.md](../CONTRIBUTING.md) to add new adapters

