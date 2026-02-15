# Quick Setup Guide

## 🎉 Good News!

**No backend server needed!** The app now connects directly to Firebase using SyncLayer's Firebase adapter.

## Setup Steps

### 1. Firebase Configuration (Already Done)

✅ You've already run `flutterfire configure`
✅ Firebase is configured for your project

### 2. Set Firestore Rules

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click **Firestore Database** → **Rules**
4. Replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /todos/{todoId} {
      allow read, write: if true;
    }
  }
}
```

5. Click **Publish**

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run the App

```bash
flutter run
```

## That's It!

The app will:
- ✅ Connect directly to Firebase Firestore
- ✅ Work offline automatically
- ✅ Sync changes every 5 minutes
- ✅ Handle conflicts automatically

## Test Offline Mode

1. Add some todos
2. Turn off WiFi
3. Add more todos (works!)
4. Turn WiFi back on
5. Changes sync automatically

## Troubleshooting

### "Permission denied" error

**Solution:** Update Firestore rules (see step 2 above)

### Data not syncing

**Solutions:**
- Wait 5 minutes for auto-sync
- Or restart the app to trigger sync
- Check Firebase Console → Firestore to verify data

### App won't start

**Solutions:**
- Run `flutter clean && flutter pub get`
- Make sure Firebase is configured: `flutterfire configure`
- Check `lib/firebase_options.dart` exists

## What About the Backend Folder?

The `backend/` folder contains a Node.js server that's **no longer needed**. The app now uses the Firebase adapter to connect directly to Firestore.

You can safely ignore or delete the `backend/` folder.

## Next Steps

- Add Firebase Authentication
- Update Firestore rules for production
- Implement pull-to-refresh
- Add error handling UI

Enjoy your offline-first todo app! 🚀
