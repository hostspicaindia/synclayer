# How to Install Platform Adapters

## Important: Adapters Are NOT in pub.dev Package

The Firebase, Supabase, and Appwrite adapters are **not included** in the pub.dev package. You need to copy them from GitHub into your project.

---

## Why?

- pub.dev requires all imports to be available as dependencies
- We don't want to force you to install Firebase/Supabase/Appwrite if you don't use them
- Keeps the package lightweight (only 64 KB)

---

## How to Install Firebase Adapter

### Step 1: Copy the Adapter File

Go to GitHub and copy the adapter file:

**Firebase Adapter:**
https://github.com/hostspicaindia/synclayer/blob/main/lib/adapters/firebase_adapter.dart

Copy the entire file content.

### Step 2: Create the File in Your Project

In your Flutter project, create this file:

```
your_project/
  lib/
    adapters/
      firebase_adapter.dart    ← Create this file and paste the code
```

### Step 3: Add Dependencies

Add to your `pubspec.yaml`:

```yaml
dependencies:
  synclayer: ^0.1.0-alpha.6
  firebase_core: ^3.10.0
  cloud_firestore: ^5.7.0
```

Run:
```bash
flutter pub get
```

### Step 4: Use It

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:synclayer/synclayer.dart';
import 'adapters/firebase_adapter.dart';  // Your copied file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://firebaseapp.com', // Not used
      customBackendAdapter: FirebaseAdapter(
        firestore: FirebaseFirestore.instance,
      ),
      collections: ['todos', 'users'],
    ),
  );
  
  runApp(MyApp());
}
```

---

## How to Install Supabase Adapter

### Step 1: Copy the Adapter File

**Supabase Adapter:**
https://github.com/hostspicaindia/synclayer/blob/main/lib/adapters/supabase_adapter.dart

### Step 2: Create the File in Your Project

```
your_project/
  lib/
    adapters/
      supabase_adapter.dart    ← Create this file and paste the code
```

### Step 3: Add Dependencies

```yaml
dependencies:
  synclayer: ^0.1.0-alpha.6
  supabase_flutter: ^2.9.0
```

### Step 4: Use It

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synclayer/synclayer.dart';
import 'adapters/supabase_adapter.dart';  // Your copied file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://your-project.supabase.co',
    anonKey: 'your-anon-key',
  );
  
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://your-project.supabase.co', // Not used
      customBackendAdapter: SupabaseAdapter(
        client: Supabase.instance.client,
      ),
      collections: ['todos', 'users'],
    ),
  );
  
  runApp(MyApp());
}
```

---

## How to Install Appwrite Adapter

### Step 1: Copy the Adapter File

**Appwrite Adapter:**
https://github.com/hostspicaindia/synclayer/blob/main/lib/adapters/appwrite_adapter.dart

### Step 2: Create the File in Your Project

```
your_project/
  lib/
    adapters/
      appwrite_adapter.dart    ← Create this file and paste the code
```

### Step 3: Add Dependencies

```yaml
dependencies:
  synclayer: ^0.1.0-alpha.6
  appwrite: ^14.0.0
```

### Step 4: Use It

```dart
import 'package:appwrite/appwrite.dart';
import 'package:synclayer/synclayer.dart';
import 'adapters/appwrite_adapter.dart';  // Your copied file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final client = Client()
    ..setEndpoint('https://cloud.appwrite.io/v1')
    ..setProject('your-project-id');
  
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://cloud.appwrite.io', // Not used
      customBackendAdapter: AppwriteAdapter(
        databases: Databases(client),
        databaseId: 'your-database-id',
      ),
      collections: ['todos', 'users'],
    ),
  );
  
  runApp(MyApp());
}
```

---

## Quick Copy Commands

### For Firebase:

```bash
# Create adapters directory
mkdir -p lib/adapters

# Download the adapter (Linux/Mac)
curl -o lib/adapters/firebase_adapter.dart https://raw.githubusercontent.com/hostspicaindia/synclayer/main/lib/adapters/firebase_adapter.dart

# Or on Windows PowerShell:
New-Item -ItemType Directory -Force -Path lib\adapters
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hostspicaindia/synclayer/main/lib/adapters/firebase_adapter.dart" -OutFile "lib\adapters\firebase_adapter.dart"
```

### For Supabase:

```bash
# Linux/Mac
curl -o lib/adapters/supabase_adapter.dart https://raw.githubusercontent.com/hostspicaindia/synclayer/main/lib/adapters/supabase_adapter.dart

# Windows PowerShell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hostspicaindia/synclayer/main/lib/adapters/supabase_adapter.dart" -OutFile "lib\adapters\supabase_adapter.dart"
```

### For Appwrite:

```bash
# Linux/Mac
curl -o lib/adapters/appwrite_adapter.dart https://raw.githubusercontent.com/hostspicaindia/synclayer/main/lib/adapters/appwrite_adapter.dart

# Windows PowerShell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hostspicaindia/synclayer/main/lib/adapters/appwrite_adapter.dart" -OutFile "lib\adapters\appwrite_adapter.dart"
```

---

## Verification

After copying the adapter, you should see:

```
your_project/
  lib/
    adapters/
      firebase_adapter.dart    ← This file should exist
    main.dart
  pubspec.yaml
```

Run `flutter pub get` and the adapter should work!

---

## Using REST API Instead (No Adapter Needed)

If you want to use a REST API backend instead, you don't need to copy any adapter:

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

## Need Help?

- **Full Documentation**: https://github.com/hostspicaindia/synclayer/blob/main/doc/PLATFORM_ADAPTERS.md
- **GitHub Issues**: https://github.com/hostspicaindia/synclayer/issues
- **Discussions**: https://github.com/hostspicaindia/synclayer/discussions

