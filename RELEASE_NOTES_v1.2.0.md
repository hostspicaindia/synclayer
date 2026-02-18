# Release Notes - v1.2.0

## 🎯 Selective Sync (Sync Filters)

**Release Date:** February 18, 2026

We're excited to announce v1.2.0 with **Selective Sync Filters** - a critical feature for production applications that need to control what data gets synchronized.

---

## 🌟 What's New

### Sync Filters

Control exactly what data gets synced between your app and backend:

```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['todos', 'notes'],
    syncFilters: {
      'todos': SyncFilter(
        where: {'userId': currentUserId},
        since: DateTime.now().subtract(Duration(days: 30)),
        excludeFields: ['attachments'],
      ),
    },
  ),
);
```

### Key Features

1. **Where Conditions** - Filter by field values
   ```dart
   where: {'userId': currentUserId, 'status': 'active'}
   ```

2. **Time-Based Filtering** - Only sync recent data
   ```dart
   since: DateTime.now().subtract(Duration(days: 30))
   ```

3. **Field Filtering** - Include/exclude specific fields
   ```dart
   fields: ['id', 'title', 'status']
   // or
   excludeFields: ['fullContent', 'attachments']
   ```

4. **Progressive Sync** - Limit initial sync size
   ```dart
   limit: 50
   ```

5. **Combined Filters** - Use all options together
   ```dart
   SyncFilter(
     where: {'userId': currentUserId},
     since: DateTime.now().subtract(Duration(days: 30)),
     limit: 100,
     excludeFields: ['attachments'],
   )
   ```

---

## 💡 Why Sync Filters?

### Privacy & Security
- **Multi-tenant isolation:** Users only sync their own data
- **Data minimization:** Comply with GDPR requirements
- **User privacy:** Don't download everyone's data

### Performance & Efficiency
- **70-90% bandwidth reduction:** Exclude large fields
- **Faster sync:** Less data to transfer
- **Lower costs:** Reduced data usage on mobile

### Storage Optimization
- **Smaller local database:** Only store what's needed
- **Progressive loading:** Load data in stages
- **Time-based retention:** Keep only recent data

---

## 📊 Real-World Impact

### Before Sync Filters
```dart
// Syncs ALL todos from ALL users
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['todos'],
  ),
);

// Result:
// - 10,000 todos synced
// - 50 MB downloaded
// - 30 seconds sync time
// - Privacy issues (seeing others' data)
```

### After Sync Filters
```dart
// Syncs ONLY current user's recent todos
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['todos'],
    syncFilters: {
      'todos': SyncFilter(
        where: {'userId': currentUserId},
        since: DateTime.now().subtract(Duration(days: 30)),
        excludeFields: ['attachments'],
      ),
    },
  ),
);

// Result:
// - 50 todos synced (user's only)
// - 2 MB downloaded (95% reduction)
// - 2 seconds sync time (93% faster)
// - Privacy protected
```

---

## 🎯 Use Cases

### 1. Multi-Tenant SaaS App
```dart
syncFilters: {
  'todos': SyncFilter(
    where: {'userId': currentUserId},
  ),
}
```
**Benefit:** Each user only sees their own data

### 2. Mobile App with Limited Data
```dart
syncFilters: {
  'messages': SyncFilter(
    since: DateTime.now().subtract(Duration(days: 7)),
    fields: ['id', 'text', 'timestamp'],
    limit: 200,
  ),
}
```
**Benefit:** 90%+ bandwidth savings

### 3. GDPR Compliant App
```dart
syncFilters: {
  'user_data': SyncFilter(
    where: {
      'userId': currentUserId,
      'consentGiven': true,
    },
    since: DateTime.now().subtract(Duration(days: 365)),
    excludeFields: ['ssn', 'creditCard'],
  ),
}
```
**Benefit:** Legal compliance

### 4. Progressive Sync App
```dart
syncFilters: {
  'todos': SyncFilter(
    where: {'userId': currentUserId},
    limit: 50, // Load more later
  ),
}
```
**Benefit:** Faster app startup

---

## 🔧 Backend Integration

### REST API

Filters are sent as query parameters:

```
GET /sync/todos?where[userId]=123&since=2024-01-01T00:00:00.000Z&limit=50&excludeFields=attachments
```

### Firebase

Filters become Firestore queries:

```dart
firestore
  .collection('todos')
  .where('data.userId', isEqualTo: '123')
  .where('updatedAt', isGreaterThan: timestamp)
  .limit(50)
```

### Supabase

Filters become PostgreSQL queries:

```dart
supabase
  .from('todos')
  .select()
  .eq('data->>userId', '123')
  .gt('updated_at', timestamp)
```

### Appwrite

Filters become Appwrite queries:

```dart
databases.listDocuments(
  queries: [
    Query.equal('data.userId', '123'),
    Query.limit(50),
  ],
)
```

---

## 📚 Documentation

- **[Sync Filters Guide](doc/SYNC_FILTERS.md)** - Complete guide with examples
- **[Sync Filter Example](example/sync_filter_example.dart)** - 8 real-world examples
- **[API Reference](doc/API_REFERENCE.md)** - Full API documentation
- **[README](README.md)** - Updated with sync filter section

---

## 🧪 Testing

- ✅ 31 new tests for sync filters
- ✅ All existing tests passing (96 total)
- ✅ Integration tests with all adapters
- ✅ Performance tests
- ✅ Edge case coverage

---

## 🔄 Migration Guide

### No Breaking Changes

Sync filters are completely optional and backward compatible:

```dart
// Old code still works
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['todos'],
  ),
);

// Add filters when ready
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

### Updating from v1.1.0

1. Update dependency:
   ```yaml
   dependencies:
     synclayer: ^1.2.0
   ```

2. Add sync filters (optional):
   ```dart
   syncFilters: {
     'todos': SyncFilter(
       where: {'userId': currentUserId},
     ),
   }
   ```

3. Update backend (if needed):
   - Add support for filter query parameters
   - See [Sync Filters Guide](doc/SYNC_FILTERS.md) for details

---

## 🎉 What's Next

### v1.3.0 (Planned)
- Custom conflict resolvers
- Encryption support
- WebSocket real-time sync
- Migration tools

### Feedback Welcome

We'd love to hear how you're using sync filters:
- 🐛 [Report issues](https://github.com/hostspicaindia/synclayer/issues)
- 💬 [Discussions](https://github.com/hostspicaindia/synclayer/discussions)
- ⭐ [Star on GitHub](https://github.com/hostspicaindia/synclayer)

---

## 📦 Installation

```yaml
dependencies:
  synclayer: ^1.2.0
```

Then run:
```bash
flutter pub get
```

---

## 🙏 Acknowledgments

Thanks to everyone who requested this feature and provided feedback!

Special thanks to the community for:
- Feature requests and use case discussions
- Beta testing and bug reports
- Documentation improvements

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

---

**Made with ❤️ by [Hostspica](https://hostspica.com)**

**Ready to optimize your app's sync?** Check out the [Sync Filters Guide](doc/SYNC_FILTERS.md) to get started!
