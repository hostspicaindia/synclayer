# 📋 Instructions for Frontend Developer

## Important: Adapters Are NOT in pub.dev Package

The Firebase, Supabase, and Appwrite adapters are **NOT included** when you install `synclayer` from pub.dev. You must copy them from GitHub.

---

## Quick Setup (Firebase Example)

### Step 1: Install SyncLayer

```yaml
# pubspec.yaml
dependencies:
  synclayer: ^0.1.0-alpha.7
  firebase_core: ^3.10.0
  cloud_firestore: ^5.7.0
```

Run:
```bash
flutter pub get
```

### Step 2: Download Firebase Adapter

**Option A: Using PowerShell (Windows)**
```powershell
# Create adapters folder
New-Item -ItemType Directory -Force -Path lib\adapters

# Download Firebase adapter
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hostspicaindia/synclayer/main/lib/adapters/firebase_adapter.dart" -OutFile "lib\adapters\firebase_adapter.dart"
```

**Option B: Using curl (Linux/Mac)**
```bash
mkdir -p lib/adapters
curl -o lib/adapters/firebase_adapter.dart https://raw.githubusercontent.com/hostspicaindia/synclayer/main/lib/adapters/firebase_adapter.dart
```

**Option C: Manual Copy**
1. Go to: https://github.com/hostspicaindia/synclayer/blob/main/lib/adapters/firebase_adapter.dart
2. Click "Raw" button
3. Copy all the code
4. Create file `lib/adapters/firebase_adapter.dart` in your project
5. Paste the code

### Step 3: Verify File Exists

Your project should now have:
```
your_project/
  lib/
    adapters/
      firebase_adapter.dart    ← This file should exist
    main.dart
  pubspec.yaml
```

### Step 4: Use It

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:synclayer/synclayer.dart';
import 'adapters/firebase_adapter.dart';  // Your copied file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize SyncLayer with Firebase adapter
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://firebaseapp.com', // Not used
      customBackendAdapter: FirebaseAdapter(
        firestore: FirebaseFirestore.instance,
      ),
      collections: ['todos', 'users'],
      syncInterval: Duration(minutes: 5),
    ),
  );
  
  runApp(MyApp());
}
```

---

## Why Adapters Are Not in pub.dev?

**Technical Reason:**
- pub.dev requires all imports to be available as dependencies
- Including adapters would force ALL users to install Firebase, Supabase, AND Appwrite
- This would add unnecessary bloat to apps that only use one platform

**Solution:**
- Adapters are on GitHub (free to copy)
- You only install the platform packages you actually use
- Keeps your app size small

---

## For Supabase

### Download Adapter
```powershell
# Windows PowerShell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hostspicaindia/synclayer/main/lib/adapters/supabase_adapter.dart" -OutFile "lib\adapters\supabase_adapter.dart"
```

### Add Dependencies
```yaml
dependencies:
  synclayer: ^0.1.0-alpha.7
  supabase_flutter: ^2.9.0
```

### Use It
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synclayer/synclayer.dart';
import 'adapters/supabase_adapter.dart';

await Supabase.initialize(
  url: 'https://your-project.supabase.co',
  anonKey: 'your-anon-key',
);

await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: SupabaseAdapter(
      client: Supabase.instance.client,
    ),
    collections: ['todos'],
  ),
);
```

---

## For Appwrite

### Download Adapter
```powershell
# Windows PowerShell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hostspicaindia/synclayer/main/lib/adapters/appwrite_adapter.dart" -OutFile "lib\adapters\appwrite_adapter.dart"
```

### Add Dependencies
```yaml
dependencies:
  synclayer: ^0.1.0-alpha.7
  appwrite: ^14.0.0
```

### Use It
```dart
import 'package:appwrite/appwrite.dart';
import 'package:synclayer/synclayer.dart';
import 'adapters/appwrite_adapter.dart';

final client = Client()
  ..setEndpoint('https://cloud.appwrite.io/v1')
  ..setProject('your-project-id');

await SyncLayer.init(
  SyncConfig(
    customBackendAdapter: AppwriteAdapter(
      databases: Databases(client),
      databaseId: 'your-database-id',
    ),
    collections: ['todos'],
  ),
);
```

---

## Using REST API (No Adapter Needed)

If you're using a REST API backend, you don't need to copy any adapter:

```yaml
dependencies:
  synclayer: ^0.1.0-alpha.7
```

```dart
import 'package:synclayer/synclayer.dart';

await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['todos'],
  ),
);
```

The REST adapter is built-in!

---

## Troubleshooting

### "Cannot find adapter file"

**Problem:** Import error like `Error: Cannot find 'adapters/firebase_adapter.dart'`

**Solution:** Make sure you copied the adapter file to the correct location:
```
lib/
  adapters/
    firebase_adapter.dart    ← File must be here
```

### "Undefined class 'FirebaseAdapter'"

**Problem:** The adapter file wasn't copied or is in the wrong location.

**Solution:** 
1. Verify file exists at `lib/adapters/firebase_adapter.dart`
2. Check the import path: `import 'adapters/firebase_adapter.dart';`
3. Run `flutter pub get`

### "Target of URI doesn't exist: 'package:cloud_firestore/cloud_firestore.dart'"

**Problem:** You didn't add the platform package to pubspec.yaml

**Solution:** Add to pubspec.yaml:
```yaml
dependencies:
  cloud_firestore: ^5.7.0
```

Then run:
```bash
flutter pub get
```

---

## Full Documentation

- **Complete Setup Guide**: https://github.com/hostspicaindia/synclayer/blob/main/doc/PLATFORM_ADAPTERS.md
- **API Reference**: https://github.com/hostspicaindia/synclayer/blob/main/doc/API_REFERENCE.md
- **GitHub Repository**: https://github.com/hostspicaindia/synclayer
- **pub.dev Package**: https://pub.dev/packages/synclayer

---

## Need Help?

- **GitHub Issues**: https://github.com/hostspicaindia/synclayer/issues
- **Discussions**: https://github.com/hostspicaindia/synclayer/discussions

