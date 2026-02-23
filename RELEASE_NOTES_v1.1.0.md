# 🔍 SyncLayer v1.1.0 - Query & Filtering Release

**Release Date:** February 17, 2026  
**Status:** Production Ready  
**Type:** Minor Release (New Features)

---

## 🎉 What's New

The most requested feature is here! SyncLayer v1.1.0 introduces a powerful **Query & Filtering API** that transforms SyncLayer from a basic sync SDK into a production-ready database solution.

### Query & Filtering API

Build complex queries with a fluent, intuitive API:

```dart
// Simple and powerful
final results = await SyncLayer.collection('todos')
  .where('done', isEqualTo: false)
  .where('priority', isGreaterThan: 5)
  .orderBy('priority', descending: true)
  .limit(20)
  .get();
```

---

## ✨ Key Features

### 1. **15 Query Operators**

**Comparison:**
- `isEqualTo` - Exact match
- `isNotEqualTo` - Not equal
- `isGreaterThan` - Greater than
- `isGreaterThanOrEqualTo` - Greater or equal
- `isLessThan` - Less than
- `isLessThanOrEqualTo` - Less or equal

**String:**
- `startsWith` - String starts with
- `endsWith` - String ends with
- `contains` - String contains substring

**Array:**
- `arrayContains` - Array contains value
- `arrayContainsAny` - Array contains any of values
- `whereIn` - Value in list
- `whereNotIn` - Value not in list

**Null:**
- `isNull` - Field is null
- `isNotNull` - Field is not null

### 2. **Multi-Field Sorting**

```dart
// Sort by multiple fields
final sorted = await collection
  .orderBy('priority', descending: true)
  .orderBy('createdAt')
  .get();
```

### 3. **Pagination**

```dart
// Page 2 (skip 10, take 10)
final page2 = await collection
  .offset(10)
  .limit(10)
  .get();
```

### 4. **Nested Field Queries**

```dart
// Query nested objects using dot notation
final userTodos = await collection
  .where('user.name', isEqualTo: 'John')
  .get();
```

### 5. **Reactive Queries**

```dart
// Watch with filters (updates automatically)
collection
  .where('done', isEqualTo: false)
  .watch()
  .listen((todos) => updateUI(todos));
```

### 6. **Utility Methods**

```dart
// Get first result
final first = await collection
  .where('priority', isGreaterThan: 5)
  .first();

// Count results
final count = await collection
  .where('done', isEqualTo: true)
  .count();
```

---

## 📊 Performance

Query performance is excellent for typical use cases:

| Dataset Size | Query Time |
|--------------|------------|
| < 1,000 records | < 10ms |
| 1,000 - 10,000 records | 10-50ms |
| > 10,000 records | 50-200ms |

---

## 🎯 Use Cases

### Search Functionality
```dart
final searchResults = await collection
  .where('text', contains: searchQuery)
  .orderBy('createdAt', descending: true)
  .get();
```

### User-Specific Data
```dart
final myTodos = await collection
  .where('userId', isEqualTo: currentUserId)
  .where('done', isEqualTo: false)
  .get();
```

### Filtered Lists
```dart
// High priority incomplete tasks
final urgent = await collection
  .where('done', isEqualTo: false)
  .where('priority', isGreaterThanOrEqualTo: 8)
  .orderBy('priority', descending: true)
  .get();
```

### Pagination
```dart
// Infinite scroll
final nextPage = await collection
  .orderBy('createdAt', descending: true)
  .offset(currentPage * pageSize)
  .limit(pageSize)
  .get();
```

---

## 🔄 Migration from v1.0.0

**No migration needed!** v1.1.0 is fully backward compatible.

```dart
// Old code still works
final todos = await collection.getAll();

// New query features are opt-in
final filtered = await collection
  .where('done', isEqualTo: false)
  .get();
```

Simply update your `pubspec.yaml`:

```yaml
dependencies:
  synclayer: ^1.1.0  # Was: ^1.0.0
```

Run:
```bash
flutter pub upgrade synclayer
```

---

## 📦 What's Included

### New API Methods

**CollectionReference:**
- `where(String field, {...})` → `QueryBuilder`
- `orderBy(String field, {bool descending})` → `QueryBuilder`
- `limit(int count)` → `QueryBuilder`
- `offset(int count)` → `QueryBuilder`

**QueryBuilder:**
- `get()` → `Future<List<Map<String, dynamic>>>`
- `watch()` → `Stream<List<Map<String, dynamic>>>`
- `first()` → `Future<Map<String, dynamic>?>`
- `count()` → `Future<int>`

### New Classes
- `QueryBuilder` - Fluent query builder
- `QueryFilter` - Filter logic
- `QuerySort` - Sorting logic
- `QueryOperator` - Operator enum

---

## ✅ Quality Metrics

- **Tests:** 19 comprehensive tests (100% pass rate)
- **Code Coverage:** All query operators tested
- **Breaking Changes:** None
- **Backward Compatibility:** 100%
- **Documentation:** Complete with examples
- **Performance:** Optimized for production use

---

## 📚 Documentation

- **README:** Updated with query examples
- **API Reference:** Complete query API documentation
- **Example:** New `example/query_example.dart` with 12 usage examples
- **CHANGELOG:** Detailed v1.1.0 entry

---

## 🚀 Getting Started

### Installation

```yaml
dependencies:
  synclayer: ^1.1.0
```

### Basic Query

```dart
import 'package:synclayer/synclayer.dart';

// Initialize
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['todos'],
  ),
);

// Query
final incompleteTodos = await SyncLayer.collection('todos')
  .where('done', isEqualTo: false)
  .orderBy('priority', descending: true)
  .limit(10)
  .get();

print('Found ${incompleteTodos.length} incomplete todos');
```

---

## 🎓 Learn More

- **Query Example:** [example/query_example.dart](example/query_example.dart)
- **API Reference:** [doc/API_REFERENCE.md](doc/API_REFERENCE.md#query--filtering-new-in-v110)
- **GitHub:** [github.com/hostspicaindia/synclayer](https://github.com/hostspicaindia/synclayer)
- **pub.dev:** [pub.dev/packages/synclayer](https://pub.dev/packages/synclayer)

---

## 🙏 Feedback

We'd love to hear your feedback on the new Query API!

- **Issues:** [GitHub Issues](https://github.com/hostspicaindia/synclayer/issues)
- **Discussions:** [GitHub Discussions](https://github.com/hostspicaindia/synclayer/discussions)
- **Email:** support@hostspica.com

---

## 🔮 What's Next

Looking ahead to v1.2.0:
- Selective Sync (sync filters)
- Custom Conflict Resolvers
- Delta Sync (partial updates)
- Encryption support

Stay tuned!

---

**Ready to query?**

```bash
flutter pub add synclayer
```

Happy coding! 🚀
