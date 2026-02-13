# Troubleshooting

## Android Build Issues

### Issue: Namespace not specified for isar_flutter_libs

**Error:**
```
Namespace not specified. Specify a namespace in the module's build file
```

**Solution 1: Clean and Rebuild**
```bash
cd example/todo_app
flutter clean
flutter pub get
flutter run
```

**Solution 2: If Solution 1 doesn't work**

The issue is with Isar and newer Android Gradle Plugin. The fix has been added to `android/build.gradle.kts`.

If still failing, check your Flutter version:
```bash
flutter --version
```

Ensure you're using Flutter 3.16+ with compatible Gradle.

**Solution 3: Alternative - Use Hive instead of Isar**

If Isar continues to cause issues, we can switch to Hive (simpler, more compatible):

1. Update `pubspec.yaml` in main SyncLayer project
2. Replace Isar with Hive
3. Rebuild

### Issue: Android Emulator Connection

**For Android Emulator:**
Change baseUrl in `lib/main.dart`:
```dart
baseUrl: 'http://10.0.2.2:3000',  // Not localhost:3000
```

**For Physical Device:**
Use your computer's IP address:
```dart
baseUrl: 'http://192.168.1.X:3000',  // Your actual IP
```

Find your IP:
- Windows: `ipconfig`
- Mac/Linux: `ifconfig`

### Issue: Backend Not Connecting

**Check backend is running:**
```bash
curl http://localhost:3000/health
```

**Check from Android emulator:**
```bash
adb shell
curl http://10.0.2.2:3000/health
```

## iOS Build Issues

### Issue: CocoaPods

```bash
cd example/todo_app/ios
pod install
cd ..
flutter run
```

## Common Issues

### Issue: SyncLayer not initialized

**Error:** `StateError: SyncLayer not initialized`

**Solution:** Ensure `SyncLayer.init()` is called before `runApp()`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SyncLayer.init(SyncConfig(...));
  runApp(TodoApp());
}
```

### Issue: Todos not syncing

1. Check connectivity indicator (should be green)
2. Check backend logs
3. Trigger manual sync (sync button)
4. Check backend data: `curl http://localhost:3000/debug/todos`

### Issue: App crashes on startup

1. Check Flutter console for errors
2. Ensure all dependencies installed: `flutter pub get`
3. Clean build: `flutter clean && flutter pub get`
4. Check Isar initialization

## Quick Fixes

### Reset Everything
```bash
cd example/todo_app
flutter clean
rm -rf android/.gradle
rm -rf android/app/build
flutter pub get
flutter run
```

### Check Dependencies
```bash
flutter doctor -v
flutter pub outdated
```

### View Logs
```bash
# Flutter logs
flutter logs

# Android logs
adb logcat | grep Flutter

# Backend logs
# Check terminal where backend is running
```

## Alternative: Run on iOS/Web Instead

If Android continues to have issues:

**iOS:**
```bash
flutter run -d ios
```

**Web (for quick testing):**
```bash
flutter run -d chrome
```

Note: Web won't test offline scenarios properly, but good for UI testing.

## Getting Help

If issues persist:
1. Check Flutter version: `flutter --version`
2. Check Android SDK: `flutter doctor -v`
3. Share error logs
4. Try on different platform (iOS/Web)
