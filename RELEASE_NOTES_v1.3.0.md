# Release Notes - v1.3.0

## 🎉 Custom Conflict Resolvers, Delta Sync & Encryption

**Release Date:** February 19, 2026

We're excited to announce v1.3.0 with three critical features that make SyncLayer production-ready for enterprise applications!

---

## 🎯 What's New

### 1. Custom Conflict Resolvers ⭐⭐⭐⭐

**The Problem:**
The built-in conflict strategies (lastWriteWins, serverWins, clientWins) don't work for all real-world scenarios:
- Social apps need to merge likes and comments, not replace them
- Inventory apps need to sum quantities, not choose one
- Collaborative editing needs field-level merging
- Analytics apps need maximum values, not most recent

**The Solution:**
Custom conflict resolvers allow you to implement application-specific conflict resolution logic.

**Example:**
```dart
// Social app: Merge likes and comments
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    conflictStrategy: ConflictStrategy.custom,
    customConflictResolver: (local, remote, localTime, remoteTime) {
      return {
        ...remote,
        'likes': [...local['likes'], ...remote['likes']].toSet().toList(),
        'comments': [...local['comments'], ...remote['comments']],
      };
    },
  ),
);
```

**Pre-built Resolvers:**
```dart
// Merge arrays (social apps)
ConflictResolvers.mergeArrays(['tags', 'likes'])

// Sum numbers (inventory apps)
ConflictResolvers.sumNumbers(['quantity', 'views'])

// Field-level merging (collaborative editing)
ConflictResolvers.fieldLevelLastWriteWins()

// Max value (analytics)
ConflictResolvers.maxValue(['version', 'score'])

// Deep merge (nested objects)
ConflictResolvers.deepMerge()

// Merge specific fields
ConflictResolvers.mergeFields(['comments', 'likes'])
```

---

### 2. Delta Sync (Partial Updates) ⭐⭐⭐⭐

**The Problem:**
Sending entire documents wastes bandwidth, especially for large documents where only one field changed:
- Toggling a todo completion sends 50 fields when only 1 changed
- Incrementing a view count sends 50KB of content
- Updating user status sends entire profile

**The Solution:**
Delta sync only sends changed fields, reducing bandwidth by 70-98%.

**Example:**
```dart
// Traditional way: Send entire document (wasteful)
await collection.save({
  'id': '123',
  'title': 'My Document',
  'content': '... 50KB of content ...',
  'done': true,  // Only this changed!
}, id: '123');

// Delta sync: Only send changed field (efficient)
await collection.update('123', {'done': true});
// Saves 98% bandwidth!
```

**Real-World Examples:**
```dart
// Toggle todo completion
await collection.update(todoId, {'done': true});

// Increment view count
await collection.update(docId, {'views': views + 1});

// Update user status
await collection.update(userId, {
  'status': 'online',
  'lastSeen': DateTime.now().toIso8601String(),
});
```

**Bandwidth Savings:**
- Todo completion: 95% reduction
- View count increment: 98% reduction
- Status update: 70% reduction

---

### 3. Encryption (Data at Rest) ⭐⭐⭐⭐

**The Problem:**
Enterprise apps (healthcare, finance, legal) require encryption at rest for:
- Compliance (HIPAA, PCI DSS, GDPR, SOC2)
- Security (protect data if device is compromised)
- Trust (users expect encryption)
- Market access (can't sell to enterprise without it)

**The Solution:**
Automatic encryption/decryption with multiple algorithms.

**Example:**
```dart
// Generate secure key
final encryptionKey = generateSecureKey();

await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    encryption: EncryptionConfig(
      enabled: true,
      key: encryptionKey,
      algorithm: EncryptionAlgorithm.aes256GCM,
    ),
  ),
);

// Data is automatically encrypted
await collection.save({
  'ssn': '123-45-6789',  // Encrypted!
  'cardNumber': '4111-1111-1111-1111',  // Encrypted!
});
```

**Supported Algorithms:**
```dart
// AES-256-GCM (recommended)
EncryptionAlgorithm.aes256GCM

// AES-256-CBC (legacy compatibility)
EncryptionAlgorithm.aes256CBC

// ChaCha20-Poly1305 (mobile-optimized)
EncryptionAlgorithm.chacha20Poly1305
```

**Compliance:**
- HIPAA: Encrypts PHI (Protected Health Information)
- PCI DSS: Encrypts cardholder data
- GDPR: Encrypts personal data
- SOC2: Meets encryption requirements

---

## 📊 Impact

### Custom Conflict Resolvers
- ✅ **Flexibility:** Handle any conflict scenario
- ✅ **Collaboration:** Enable collaborative editing
- ✅ **Inventory:** Sum quantities correctly
- ✅ **Social:** Merge user interactions
- ✅ **Production-Ready:** No more blockers for complex apps

### Delta Sync
- ✅ **Bandwidth:** 70-98% reduction
- ✅ **Performance:** Faster sync
- ✅ **Battery:** Less network usage
- ✅ **Cost:** Lower server bandwidth costs
- ✅ **Conflicts:** Fewer conflicts (only specific fields change)

### Encryption
- ✅ **Compliance:** HIPAA, PCI DSS, GDPR, SOC2
- ✅ **Security:** Data protected at rest
- ✅ **Trust:** User confidence
- ✅ **Enterprise:** Market access
- ✅ **Automatic:** Transparent encryption/decryption

---

## 🚀 Getting Started

### Custom Conflict Resolvers

```dart
// 1. Use pre-built resolver
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    conflictStrategy: ConflictStrategy.custom,
    customConflictResolver: ConflictResolvers.mergeArrays(['tags', 'likes']),
  ),
);

// 2. Or implement custom logic
customConflictResolver: (local, remote, localTime, remoteTime) {
  // Your custom logic here
  return mergedData;
}
```

### Delta Sync

```dart
// Just use update() instead of save()
await collection.update(id, {'field': newValue});

// Calculate savings
final savings = DeltaCalculator.calculateSavings(fullDoc, delta);
print('Bandwidth saved: ${savings.toStringAsFixed(1)}%');
```

### Encryption

```dart
// Generate secure key (store in flutter_secure_storage)
final encryptionKey = generateSecureKey();

await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    encryption: EncryptionConfig(
      enabled: true,
      key: encryptionKey,
      algorithm: EncryptionAlgorithm.aes256GCM,
    ),
  ),
);

// Data is automatically encrypted
await collection.save({'ssn': '123-45-6789'});
```

---

## 📚 Documentation

- [Encryption Example](example/encryption_example.dart) - 6 real-world examples
- [Custom Conflict Resolver Example](example/custom_conflict_resolver_example.dart) - 6 real-world examples
- [Delta Sync Example](example/delta_sync_example.dart) - 6 bandwidth optimization examples
- [CHANGELOG.md](CHANGELOG.md) - Complete changelog
- [README.md](README.md) - Updated with all three features

---

## 🔄 Migration Guide

### From v1.2.0 to v1.3.0

**No breaking changes!** All features are optional and backward compatible.

**To use encryption:**
```dart
// Add to your SyncConfig
encryption: EncryptionConfig(
  enabled: true,
  key: yourSecureKey,
),
```

**To use custom conflict resolvers:**
```dart
// Add to your SyncConfig
conflictStrategy: ConflictStrategy.custom,
customConflictResolver: yourResolverFunction,
```

**To use delta sync:**
```dart
// Replace save() with update() for partial updates
await collection.update(id, {'field': newValue});
```

---

## 🧪 Testing

- 28 new encryption tests
- 11 custom conflict resolver tests
- 18 delta sync tests
- 153 total tests passing
- 100% backward compatibility
- Zero breaking changes

---

## 🎯 Use Cases

### Encryption

1. **Healthcare Apps:** HIPAA-compliant PHI encryption
2. **Finance Apps:** PCI DSS-compliant card data encryption
3. **Legal Apps:** Attorney-client privilege protection
4. **Enterprise Apps:** SOC2, ISO 27001 compliance
5. **Any Sensitive Data:** User trust and security

### Custom Conflict Resolvers

1. **Social Apps:** Merge likes, comments, followers
2. **Inventory Apps:** Sum quantities from multiple sources
3. **Collaborative Editing:** Field-level merging for documents
4. **Analytics:** Use maximum values for counters
5. **Complex Data:** Deep merge nested objects

### Delta Sync

1. **Todo Apps:** Toggle completion, update priority
2. **Analytics:** Increment views, likes, counters
3. **User Status:** Update online/offline status
4. **Large Documents:** Update single fields in large docs
5. **Real-Time Apps:** Frequent small updates

---

## 🔮 What's Next

We're committed to making SyncLayer the best local-first sync solution for Flutter. Here's what's coming:

- **Batch Delta Sync:** Update multiple documents with deltas
- **Conflict Resolution UI:** Built-in UI for manual conflict resolution
- **Advanced Filtering:** More powerful sync filters
- **Performance Improvements:** Even faster sync
- **More Adapters:** Additional backend integrations

---

## 🙏 Thank You

Thank you to our community for the feedback and feature requests that made this release possible!

---

## 📦 Installation

```yaml
dependencies:
  synclayer: ^1.3.0
```

Then run:
```bash
flutter pub get
```

---

## 🐛 Bug Reports

Found a bug? Please report it on [GitHub Issues](https://github.com/hostspicaindia/synclayer/issues).

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

---

**Happy Syncing! 🚀**
