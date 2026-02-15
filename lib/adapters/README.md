# Platform Adapters

This directory contains built-in adapters for popular backend platforms.

## Available Adapters

### Firebase Firestore (`firebase_adapter.dart`)
- Syncs with Google Cloud Firestore
- Requires: `cloud_firestore` package
- Best for: Apps already using Firebase ecosystem

### Supabase (`supabase_adapter.dart`)
- Syncs with Supabase PostgreSQL database
- Requires: `supabase_flutter` package
- Best for: Open-source alternative to Firebase, SQL database needs

### Appwrite (`appwrite_adapter.dart`)
- Syncs with Appwrite database collections
- Requires: `appwrite` package
- Best for: Self-hosted backend, privacy-focused apps

## Usage

These adapters are optional. Add the required package only if you plan to use that adapter:

```yaml
dependencies:
  synclayer: ^0.1.0
  
  # Add only what you need:
  cloud_firestore: ^5.7.0      # For Firebase
  supabase_flutter: ^2.9.0     # For Supabase
  appwrite: ^14.0.0            # For Appwrite
```

## Example

```dart
import 'package:synclayer/synclayer.dart';

// Firebase
await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: FirebaseAdapter(
      firestore: FirebaseFirestore.instance,
    ),
  ),
);

// Supabase
await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: SupabaseAdapter(
      client: Supabase.instance.client,
    ),
  ),
);

// Appwrite
await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: AppwriteAdapter(
      databases: Databases(client),
      databaseId: 'your-database-id',
    ),
  ),
);
```

## Documentation

See [Platform Adapters Guide](../../doc/PLATFORM_ADAPTERS.md) for complete setup instructions.

## Creating Custom Adapters

To create your own adapter, implement the `SyncBackendAdapter` interface:

```dart
class MyCustomAdapter implements SyncBackendAdapter {
  @override
  Future<void> push({...}) async {
    // Push data to your backend
  }

  @override
  Future<List<SyncRecord>> pull({...}) async {
    // Pull data from your backend
  }

  @override
  Future<void> delete({...}) async {
    // Delete data on your backend
  }

  @override
  void updateAuthToken(String token) {
    // Update authentication token
  }
}
```

See the existing adapters in this directory for reference implementations.
