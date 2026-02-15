# Migration Guide

How to add SyncLayer to your existing app.

---

## Adding SyncLayer to Existing Firebase App

If you already have a Firebase app and want to add offline-first sync:

### Step 1: Add SyncLayer

```yaml
dependencies:
  firebase_core: ^3.10.0
  cloud_firestore: ^5.7.0
  synclayer: ^0.1.0-alpha.6  # Add this
```

### Step 2: Update Data Structure

SyncLayer expects documents in this format:

```
/todos/{recordId}
  - data: Map<String, dynamic>  // Your existing data goes here
  - updatedAt: Timestamp
  - version: int
```

**Migration script:**

```dart
// Run this once to migrate existing data
Future<void> migrateFirestoreData() async {
  final firestore = FirebaseFirestore.instance;
  
  // Get all documents in collection
  final snapshot = await firestore.collection('todos').get();
  
  for (final doc in snapshot.docs) {
    // Wrap existing data in 'data' field
    await doc.reference.update({
      'data': doc.data(),  // Move all fields into 'data'
      'updatedAt': FieldValue.serverTimestamp(),
      'version': 1,
    });
  }
}
```

### Step 3: Initialize SyncLayer

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  // Add SyncLayer initialization
  await SyncLayer.init(
    SyncConfig(
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

### Step 4: Replace Firestore Calls

**Before:**
```dart
// Direct Firestore access
await FirebaseFirestore.instance
    .collection('todos')
    .doc(id)
    .set({'text': 'Buy milk'});

final doc = await FirebaseFirestore.instance
    .collection('todos')
    .doc(id)
    .get();
```

**After:**
```dart
// SyncLayer (works offline!)
await SyncLayer.collection('todos').save({
  'text': 'Buy milk',
}, id: id);

final todo = await SyncLayer.collection('todos').get(id);
```

### Step 5: Update Streams

**Before:**
```dart
StreamBuilder(
  stream: FirebaseFirestore.instance
      .collection('todos')
      .snapshots(),
  builder: (context, snapshot) {
    final docs = snapshot.data?.docs ?? [];
    return ListView.builder(...);
  },
);
```

**After:**
```dart
StreamBuilder(
  stream: SyncLayer.collection('todos').watch(),
  builder: (context, snapshot) {
    final todos = snapshot.data ?? [];
    return ListView.builder(...);
  },
);
```

---

## Adding SyncLayer to Existing Supabase App

### Step 1: Add SyncLayer

```yaml
dependencies:
  supabase_flutter: ^2.9.0
  synclayer: ^0.1.0-alpha.6  # Add this
```

### Step 2: Update Database Schema

Add required columns to your tables:

```sql
-- For each table you want to sync
ALTER TABLE todos ADD COLUMN IF NOT EXISTS record_id TEXT;
ALTER TABLE todos ADD COLUMN IF NOT EXISTS data JSONB;
ALTER TABLE todos ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE todos ADD COLUMN IF NOT EXISTS version INTEGER DEFAULT 1;

-- Create index for efficient sync
CREATE INDEX IF NOT EXISTS idx_todos_updated_at ON todos(updated_at);

-- Migrate existing data
UPDATE todos SET 
  record_id = id::TEXT,
  data = row_to_json(todos.*),
  updated_at = NOW(),
  version = 1
WHERE record_id IS NULL;
```

### Step 3: Initialize SyncLayer

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://your-project.supabase.co',
    anonKey: 'your-anon-key',
  );
  
  // Add SyncLayer initialization
  await SyncLayer.init(
    SyncConfig(
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

### Step 4: Replace Supabase Calls

**Before:**
```dart
// Direct Supabase access
await Supabase.instance.client
    .from('todos')
    .insert({'text': 'Buy milk'});

final response = await Supabase.instance.client
    .from('todos')
    .select()
    .eq('id', id)
    .single();
```

**After:**
```dart
// SyncLayer (works offline!)
await SyncLayer.collection('todos').save({
  'text': 'Buy milk',
});

final todo = await SyncLayer.collection('todos').get(id);
```

---

## Migrating Between Platforms

### Firebase → Supabase

1. **Export Firebase data:**
```dart
Future<void> exportFromFirebase() async {
  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore.collection('todos').get();
  
  final data = snapshot.docs.map((doc) {
    return {
      'record_id': doc.id,
      'data': doc.data()['data'],
      'updated_at': (doc.data()['updatedAt'] as Timestamp).toDate(),
      'version': doc.data()['version'],
    };
  }).toList();
  
  // Save to JSON file
  final file = File('firebase_export.json');
  await file.writeAsString(jsonEncode(data));
}
```

2. **Import to Supabase:**
```sql
-- Create table
CREATE TABLE todos (
  record_id TEXT PRIMARY KEY,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  version INTEGER NOT NULL
);

-- Import from JSON (use Supabase dashboard or API)
```

3. **Update app config:**
```dart
// Change from Firebase adapter
await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: FirebaseAdapter(...),
  ),
);

// To Supabase adapter
await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: SupabaseAdapter(...),
  ),
);
```

### Supabase → Firebase

1. **Export Supabase data:**
```dart
Future<void> exportFromSupabase() async {
  final client = Supabase.instance.client;
  final response = await client.from('todos').select();
  
  // Save to JSON file
  final file = File('supabase_export.json');
  await file.writeAsString(jsonEncode(response));
}
```

2. **Import to Firebase:**
```dart
Future<void> importToFirebase(List<Map<String, dynamic>> data) async {
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();
  
  for (final item in data) {
    final docRef = firestore.collection('todos').doc(item['record_id']);
    batch.set(docRef, {
      'data': item['data'],
      'updatedAt': Timestamp.fromDate(DateTime.parse(item['updated_at'])),
      'version': item['version'],
    });
  }
  
  await batch.commit();
}
```

3. **Update app config:**
```dart
// Change from Supabase adapter
await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: SupabaseAdapter(...),
  ),
);

// To Firebase adapter
await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: FirebaseAdapter(...),
  ),
);
```

---

## Gradual Migration Strategy

You can migrate gradually without breaking your app:

### Phase 1: Add SyncLayer (Read-Only)

```dart
// Keep existing writes
await FirebaseFirestore.instance
    .collection('todos')
    .doc(id)
    .set(data);

// Use SyncLayer for reads (gets offline support)
final todo = await SyncLayer.collection('todos').get(id);
```

### Phase 2: Migrate Writes

```dart
// Switch to SyncLayer for writes
await SyncLayer.collection('todos').save(data, id: id);

// Remove direct Firestore/Supabase calls
```

### Phase 3: Remove Old Code

```dart
// Remove all direct backend calls
// Use only SyncLayer API
```

---

## Common Issues

### Issue: Data not syncing after migration

**Solution:** Ensure data structure matches requirements:

```dart
// Firebase
{
  'data': {...},        // Your data here
  'updatedAt': Timestamp,
  'version': int
}

// Supabase
{
  'record_id': TEXT,
  'data': JSONB,
  'updated_at': TIMESTAMPTZ,
  'version': INTEGER
}
```

### Issue: Duplicate data after migration

**Solution:** Use same record IDs:

```dart
// When migrating, preserve original IDs
await SyncLayer.collection('todos').save(data, id: originalId);
```

### Issue: Conflicts after migration

**Solution:** Set conflict strategy:

```dart
SyncConfig(
  conflictStrategy: ConflictStrategy.serverWins, // Server data wins
)
```

---

## Rollback Plan

If you need to rollback:

### Step 1: Disable SyncLayer

```dart
// Comment out SyncLayer initialization
// await SyncLayer.init(...);
```

### Step 2: Restore Direct Backend Access

```dart
// Use Firebase/Supabase directly again
await FirebaseFirestore.instance
    .collection('todos')
    .doc(id)
    .set(data);
```

### Step 3: Data is Still There

Your data is still in Firebase/Supabase unchanged. SyncLayer just adds a sync layer on top.

---

## Best Practices

1. **Test in Development First**
   - Migrate a test collection first
   - Verify sync works correctly
   - Then migrate production data

2. **Backup Data**
   - Export all data before migration
   - Keep backups for at least 30 days

3. **Monitor Sync**
   - Watch sync events for errors
   - Check sync status regularly
   - Alert on sync failures

4. **Gradual Rollout**
   - Enable for 10% of users first
   - Monitor for issues
   - Gradually increase to 100%

---

## Need Help?

- [Platform Adapters Guide](PLATFORM_ADAPTERS.md)
- [API Reference](API_REFERENCE.md)
- [GitHub Issues](https://github.com/hostspicaindia/synclayer/issues)
- [Discussions](https://github.com/hostspicaindia/synclayer/discussions)

