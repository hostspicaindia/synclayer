# Offline-First Todo App with SyncLayer + Firebase

A Flutter todo app using **SyncLayer v0.1.0-alpha.7** with direct Firebase Firestore integration - **NO backend server needed!**

## ✨ What's New

✅ **Direct Firebase Integration** - SyncLayer now connects directly to Firebase Firestore
✅ **No Backend Server Required** - Firebase adapter eliminates the need for Node.js middleware
✅ **Alpha.7 Release** - Latest SyncLayer with platform adapter support

## Features

✅ **Offline-First** - All operations work without internet (powered by SyncLayer + Isar)
✅ **Auto-Sync** - Changes sync every 5 minutes when online
✅ **Conflict Resolution** - Last-write-wins strategy
✅ **Real-Time Updates** - UI updates instantly
✅ **Swipe to Delete** - Intuitive gesture controls
✅ **Unlimited Cache** - SyncLayer uses Isar for local storage
✅ **Direct Firebase** - No middleware server needed!

## Architecture

```
Flutter App (SyncLayer) ←→ Firebase Firestore
```

**That's it!** No backend server needed.

SyncLayer handles:
- Local storage (Isar)
- Offline queue
- Background sync
- Conflict resolution
- Direct Firebase communication

## Quick Setup

### 1. Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Firestore Database
3. Run `flutterfire configure` (already done for this project)

### 2. Firestore Rules

Add these rules in Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /todos/{todoId} {
      allow read, write: if true; // For demo - add auth in production
    }
  }
}
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run the App

```bash
flutter run
```

**That's it!** No backend server to start. The app connects directly to Firebase.

## Testing Offline Mode

1. Run app: `flutter run`
2. Add some todos
3. **Turn off WiFi/mobile data**
4. Add/edit/delete todos (works instantly!)
5. Turn internet back on
6. Wait 5 minutes OR restart app
7. Watch changes sync automatically to Firebase

## Manual Sync

Trigger immediate sync (e.g., pull-to-refresh):
```dart
await SyncLayer.syncNow();
```

## Project Structure

```
lib/
├── main.dart                    # SyncLayer + Firebase initialization
├── adapters/
│   └── firebase_adapter.dart    # Firebase adapter for SyncLayer
├── models/
│   └── todo.dart                # Todo data model
├── services/
│   └── todo_service.dart        # SyncLayer operations
└── screens/
    └── todo_screen.dart         # Main UI
```

## Key Technologies

- **SyncLayer v0.1.0-alpha.7** - Offline-first sync engine
- **Isar** - Local database (used by SyncLayer)
- **Firebase Firestore** - Cloud database
- **Flutter** - UI framework

## SyncLayer Configuration

```dart
await Firebase.initializeApp();

await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://firebaseapp.com', // Not used with Firebase adapter
    customBackendAdapter: FirebaseAdapter(
      firestore: FirebaseFirestore.instance,
    ),
    syncInterval: Duration(minutes: 5),
    collections: ['todos'],
    conflictStrategy: ConflictStrategy.lastWriteWins,
  ),
);
```

## Firebase Adapter

The Firebase adapter (`lib/adapters/firebase_adapter.dart`) implements:
- `push()` - Save data to Firestore
- `pull()` - Fetch changes from Firestore
- `delete()` - Remove data from Firestore

It translates SyncLayer operations into Firestore API calls.

## Monitoring Sync Events

```dart
SyncLayerCore.instance.syncEngine.events.listen((event) {
  switch (event.type) {
    case SyncEventType.syncStarted:
      print('Sync started');
      break;
    case SyncEventType.syncCompleted:
      print('Sync completed');
      break;
    case SyncEventType.conflictDetected:
      print('Conflict detected');
      break;
  }
});
```

## Troubleshooting

**Sync not working:**
- Check Firestore rules allow read/write
- Verify Firebase is initialized before SyncLayer
- Check app logs for sync events

**Permission denied:**
- Update Firestore rules (see setup above)
- For production, add Firebase Authentication

**Data not syncing:**
- Wait 5 minutes for auto-sync
- Or trigger manual sync: `await SyncLayer.syncNow()`
- Check Firebase Console → Firestore to verify data

## Backend Server (Optional)

The `backend/` folder contains a Node.js server that was used before the Firebase adapter. **You don't need it anymore!** The app now connects directly to Firebase.

You can delete the `backend/` folder if you want, or keep it for reference.

## Why SyncLayer + Firebase?

Compared to Firebase SDK alone:
- ✅ Better offline queue management
- ✅ Custom conflict resolution strategies
- ✅ Explicit sync control
- ✅ Backend agnostic (easy to switch to Supabase/Appwrite later)
- ✅ Consistent API across different backends

Compared to REST backend:
- ✅ No server to maintain
- ✅ No deployment needed
- ✅ Firebase's scalability and reliability
- ✅ Simpler architecture

## Other Platform Adapters

SyncLayer also supports:
- **Supabase** - Copy `supabase_adapter.dart` from GitHub
- **Appwrite** - Copy `appwrite_adapter.dart` from GitHub
- **REST API** - Built-in (no adapter needed)

See [SyncLayer Platform Adapters Guide](https://github.com/hostspicaindia/synclayer/tree/main/lib/adapters)

## Production Checklist

- [ ] Add Firebase Authentication
- [ ] Update Firestore security rules
- [ ] Add error handling UI
- [ ] Implement pull-to-refresh for manual sync
- [ ] Add loading states
- [ ] Test conflict resolution scenarios
- [ ] Monitor sync events for debugging

## License

MIT
