# Release Notes - SyncLayer v1.7.3

## 📝 Documentation Accuracy Update

**Release Date:** March 5, 2026  
**Type:** Documentation-only release  
**Breaking Changes:** None ✅

---

## What's New

This is a documentation accuracy update that ensures all user-facing documentation correctly reflects the actual codebase implementation.

### 📚 Documentation Updates

#### ✅ README.md
- **Corrected database adapter count** from 14 to 8 (matching actual code)
- **Removed references** to unimplemented adapters:
  - MariaDB (not in codebase)
  - CouchDB (not in codebase)
  - DynamoDB (not in codebase)
  - Cassandra (not in codebase)
  - GraphQL (not in codebase)
- **Updated version references** from 1.7.2 to 1.7.3
- **Added version tags** to roadmap items for clarity

#### ✅ DATABASE_SUPPORT.md
- Updated to reflect 8 actual database adapters
- Corrected dependency versions
- Removed references to unimplemented databases
- Updated installation instructions

#### ✅ API_REFERENCE.md
- Updated version references to 1.7.3
- Verified all API examples match code

#### ✅ QUICK_REFERENCE.md
- Updated installation instructions
- Corrected adapter import statements
- Updated dependency versions

#### ✅ REALTIME_MIGRATION_GUIDE.md
- Updated version references to 1.7.3

---

## Actual Database Support (Verified in Code)

SyncLayer v1.7.3 includes **8 database adapters** in the main package:

### BaaS Platforms (3)
- ✅ Firebase Firestore
- ✅ Supabase
- ✅ Appwrite

### SQL Databases (3)
- ✅ PostgreSQL
- ✅ MySQL
- ✅ SQLite

### NoSQL Databases (2)
- ✅ MongoDB
- ✅ Redis

### API Protocols (1)
- ✅ REST API (built-in)

All adapters are located in `lib/adapters/` and can be imported via:
```dart
import 'package:synclayer/adapters.dart';
```

---

## Verified Features

All documented features have been verified to exist in the codebase:

### ✅ Real-Time Sync (v1.7.0)
- `lib/realtime/websocket_service.dart`
- `lib/realtime/realtime_sync_manager.dart`
- Full WebSocket implementation with reconnection

### ✅ Delta Sync (v1.3.0)
- `lib/sync/delta_sync.dart`
- Bandwidth savings up to 98%
- `DocumentDelta` and `DeltaCalculator` classes

### ✅ Encryption (v1.3.0)
- `lib/security/encryption_config.dart`
- `lib/security/encryption_service.dart`
- AES-256-GCM, AES-256-CBC, ChaCha20-Poly1305

### ✅ Sync Filters (v1.2.0)
- `lib/sync/sync_filter.dart`
- Where conditions, time-based, field filtering

### ✅ Query & Filtering (v1.1.0)
- `lib/query/query_builder.dart`
- 15 query operators
- Sorting, pagination, reactive queries

### ✅ Custom Conflict Resolvers (v1.3.0)
- `lib/conflict/custom_conflict_resolver.dart`
- Pre-built resolvers: mergeArrays, sumNumbers, deepMerge, etc.

### ✅ Metrics & Logging
- `lib/utils/metrics.dart`
- `lib/utils/logger.dart`
- Production-ready observability

---

## Migration Guide

### From v1.7.2 to v1.7.3

**No code changes required!** Simply update your `pubspec.yaml`:

```yaml
dependencies:
  synclayer: ^1.7.3  # Was: ^1.7.2
```

Then run:
```bash
flutter pub upgrade synclayer
```

**That's it!** This is a documentation-only release with no breaking changes.

---

## What Hasn't Changed

- ✅ All APIs remain the same
- ✅ All features work identically
- ✅ No breaking changes
- ✅ Fully backward compatible
- ✅ No code modifications needed

---

## Why This Update?

This release ensures that:
1. **Documentation accuracy** - Users see correct information about available adapters
2. **Clear expectations** - No confusion about which databases are supported
3. **Better developer experience** - Accurate guides and examples
4. **Version clarity** - Roadmap shows when features were added

---

## Installation

```yaml
dependencies:
  synclayer: ^1.7.3
  
  # Add only the database package you need:
  cloud_firestore: ^6.1.2      # For Firebase
  supabase_flutter: ^2.12.0    # For Supabase
  appwrite: ^21.4.0            # For Appwrite
  postgres: ^3.5.9             # For PostgreSQL
  mysql1: ^0.20.0              # For MySQL
  mongo_dart: ^0.10.8          # For MongoDB
  sqflite: ^2.4.2              # For SQLite
  redis: ^4.0.0                # For Redis
```

---

## Quick Start

```dart
import 'package:synclayer/synclayer.dart';
import 'package:synclayer/adapters.dart';  // Import adapters

// Initialize with REST API (default)
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['todos'],
  ),
);

// Or with Firebase
await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: FirebaseAdapter(
      firestore: FirebaseFirestore.instance,
    ),
    collections: ['todos'],
  ),
);

// Use it
final id = await SyncLayer.collection('todos').save({
  'text': 'Buy milk',
  'done': false,
});
```

---

## Documentation Links

- 📖 [README](README.md) - Main documentation
- 📖 [CHANGELOG](CHANGELOG.md) - Version history
- 📖 [Database Support Guide](DATABASE_SUPPORT.md) - All 8 databases
- 📖 [API Reference](doc/API_REFERENCE.md) - Complete API docs
- 📖 [Quick Reference](doc/QUICK_REFERENCE.md) - One-page guide
- 📖 [Real-Time Sync Guide](doc/REALTIME_SYNC_GUIDE.md) - WebSocket sync
- 🐛 [GitHub Issues](https://github.com/hostspicaindia/synclayer/issues)
- 💬 [Discussions](https://github.com/hostspicaindia/synclayer/discussions)

---

## Support

- **GitHub Issues:** https://github.com/hostspicaindia/synclayer/issues
- **Discussions:** https://github.com/hostspicaindia/synclayer/discussions
- **pub.dev:** https://pub.dev/packages/synclayer
- **Email:** legal@hostspica.com

---

## What's Next?

Future releases will focus on:
- Migration tools
- Offline analytics
- P2P sync capabilities
- Additional database adapters (based on community requests)

---

**Made with ❤️ by [Hostspica](https://hostspica.com)**
