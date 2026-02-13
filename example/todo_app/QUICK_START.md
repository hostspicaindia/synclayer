# Quick Start - Workaround for Android Issues

## Issue

Isar has compatibility issues with Android Gradle Plugin 8.11+. 

## Quick Solution: Run on Chrome (Web)

This lets you test the app immediately while we fix Android:

```bash
cd example/todo_app

# Update baseUrl for web
# Edit lib/main.dart line 10:
# Change: baseUrl: 'http://localhost:3000',
# To: baseUrl: 'http://localhost:3000',  # Already correct for web

flutter run -d chrome
```

**Note:** Web won't test true offline scenarios, but you can test:
- UI functionality
- Data persistence (IndexedDB)
- Sync operations
- Event system

## Alternative: Run Backend Example Instead

Use the simpler batch operations example that doesn't need UI:

```bash
# Terminal 1: Start backend
cd backend
npm install
npm start

# Terminal 2: Run example
cd example
dart run batch_operations_example.dart
```

## Fixing Android (For Later)

The Android issue is with Isar + AGP 8.11. Solutions:

### Option 1: Downgrade AGP (Recommended)
Edit `example/todo_app/android/settings.gradle.kts` line 23:
```kotlin
id("com.android.application") version "8.1.0" apply false
```

Then:
```bash
flutter clean
flutter pub get
flutter run
```

### Option 2: Wait for Isar Update
Isar team is working on AGP 8.11 compatibility.

### Option 3: Use iOS
```bash
flutter run -d ios
```

## For Now: Test with Web + Backend Example

This validates the core sync logic without Android complications.

1. Start backend: `cd backend && npm start`
2. Run on web: `cd example/todo_app && flutter run -d chrome`
3. Test basic functionality
4. Run batch example: `dart run example/batch_operations_example.dart`

## What You Can Test on Web

✅ Add/edit/delete todos
✅ Watch real-time updates
✅ Sync with backend
✅ Event system
✅ Connectivity changes (simulated)
⚠️ True offline mode (limited)
⚠️ App lifecycle (N/A on web)

## Production Validation

For full production validation, you'll need:
- iOS device/simulator, OR
- Fix Android AGP issue, OR
- Wait for Isar update

But you can start validation now with web + backend example!
