# SyncLayer Todo App

Real-world example demonstrating SyncLayer's offline-first sync capabilities.

## Features

- ✅ Add/edit/delete todos
- ✅ Offline-first (works without internet)
- ✅ Automatic background sync
- ✅ Real-time updates via streams
- ✅ Connectivity indicator
- ✅ Sync event counter
- ✅ Manual sync trigger

## Setup

### 1. Start Backend
```bash
cd backend
npm install
npm start
```

Backend runs on `http://localhost:3000`

### 2. Run App
```bash
cd example/todo_app
flutter pub get
flutter run
```

## Testing Offline Sync

### Test 1: Basic Offline
1. Start app with backend running
2. Add some todos
3. Stop backend (`Ctrl+C`)
4. Add more todos (they save locally)
5. Start backend again
6. Watch todos sync automatically

### Test 2: Conflict Resolution
1. Run app on two devices/emulators
2. Turn off wifi on device 1
3. Edit same todo on both devices
4. Turn wifi back on device 1
5. Watch conflict resolution (last-write-wins)

### Test 3: Rapid Edits
1. Add 10 todos quickly
2. Toggle them rapidly
3. Watch sync events counter
4. Check backend: `curl http://localhost:3000/debug/todos`

### Test 4: Network Interruption
1. Add todos while online
2. Turn airplane mode on/off repeatedly
3. App should handle gracefully
4. All data should sync eventually

## What to Watch For

### UI Indicators
- **Green cloud**: Online and syncing
- **Red cloud**: Offline mode
- **Events counter**: Shows sync activity

### Console Output
- Sync events logged
- Backend shows push/pull operations
- Version increments visible

### Expected Behavior
- Instant UI updates (local-first)
- Background sync when online
- No data loss during offline periods
- Conflicts resolved automatically

## Common Issues

### Backend not connecting
- Check backend is running: `curl http://localhost:3000/health`
- Check URL in main.dart matches backend port
- For Android emulator, use `http://10.0.2.2:3000`
- For iOS simulator, use `http://localhost:3000`

### Todos not syncing
- Check connectivity indicator (should be green)
- Trigger manual sync (sync button in app bar)
- Check backend logs for errors
- View backend data: `curl http://localhost:3000/debug/todos`

### App crashes
- Check Flutter console for errors
- Ensure SyncLayer initialized before runApp
- Check Isar database permissions

## Production Checklist

Before deploying to production:

- [ ] Replace in-memory backend with real database
- [ ] Add authentication (JWT tokens)
- [ ] Use HTTPS for backend
- [ ] Add error handling UI
- [ ] Add retry logic for failed syncs
- [ ] Add conflict resolution UI (if needed)
- [ ] Test with poor network conditions
- [ ] Test with large datasets (1000+ todos)
- [ ] Add analytics/monitoring
- [ ] Add crash reporting

## Architecture

```
Todo App
    ↓
SyncLayer SDK
    ↓
Local Storage (Isar)
    ↓
Sync Engine
    ↓
REST Backend
    ↓
Database (PostgreSQL/MongoDB)
```

## Next Steps

1. Test thoroughly with real network conditions
2. Add more complex data (nested objects, relations)
3. Test with multiple users
4. Measure performance with large datasets
5. Add pull-to-refresh
6. Add optimistic UI updates
7. Add undo/redo functionality
