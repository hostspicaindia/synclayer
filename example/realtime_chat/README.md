# Real-Time Chat Example

A simple chat application demonstrating SyncLayer's real-time sync feature.

## Features

- ✅ Real-time message synchronization across devices
- ✅ Instant message delivery (50-200ms latency)
- ✅ Connection status indicator
- ✅ Automatic reconnection
- ✅ Fallback to HTTP polling when WebSocket unavailable
- ✅ Offline support with message queue

## Prerequisites

1. **Backend WebSocket Server**
   
   You need a WebSocket server implementing the SyncLayer protocol.
   
   Quick start with Node.js:
   ```bash
   cd server
   npm install
   npm start
   ```
   
   Server will run on `ws://localhost:8080/ws`

2. **Flutter SDK**
   ```bash
   flutter --version
   # Should be 3.0.0 or higher
   ```

## Running the Example

### 1. Start the WebSocket Server

```bash
cd server
npm install
npm start
```

You should see:
```
WebSocket server running on ws://localhost:8080
```

### 2. Run the Flutter App

```bash
cd ..
flutter pub get
flutter run
```

### 3. Test Real-Time Sync

**Option A: Two Devices**
1. Run app on Device A
2. Run app on Device B
3. Send message from Device A
4. See message appear on Device B instantly

**Option B: Two Emulators**
1. Start two emulators
2. Run `flutter run -d emulator-1`
3. Run `flutter run -d emulator-2`
4. Send messages between them

**Option C: Web + Mobile**
1. Run `flutter run -d chrome`
2. Run `flutter run -d <your-device>`
3. Send messages between them

## Project Structure

```
example/realtime_chat/
├── lib/
│   ├── main.dart              # App entry point
│   ├── chat_screen.dart       # Chat UI
│   └── connection_indicator.dart  # Connection status widget
├── server/
│   ├── server.js              # WebSocket server
│   └── package.json
├── pubspec.yaml
└── README.md
```

## How It Works

### 1. Initialization

```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'http://localhost:3000',
    enableRealtimeSync: true,
    websocketUrl: 'ws://localhost:8080/ws',
    collections: ['messages'],
  ),
);
```

### 2. Sending Messages

```dart
await SyncLayer.collection('messages').save({
  'text': messageText,
  'sender': currentUser,
  'timestamp': DateTime.now().toIso8601String(),
});
```

Messages are:
1. Saved to local storage (instant)
2. Sent via WebSocket (50-200ms)
3. Broadcast to all connected devices
4. Queued for HTTP sync (backup)

### 3. Receiving Messages

```dart
StreamBuilder<List<Map<String, dynamic>>>(
  stream: SyncLayer.collection('messages').watch(),
  builder: (context, snapshot) {
    final messages = snapshot.data ?? [];
    return ListView.builder(...);
  },
);
```

The stream emits whenever:
- Local changes occur
- Real-time updates arrive via WebSocket
- HTTP sync completes

### 4. Connection Status

```dart
final realtimeManager = SyncLayerCore.instance.realtimeSyncManager;

realtimeManager?.events.listen((event) {
  if (event.type == SyncEventType.realtimeConnected) {
    setState(() => isConnected = true);
  } else if (event.type == SyncEventType.realtimeDisconnected) {
    setState(() => isConnected = false);
  }
});
```

## Testing Scenarios

### Scenario 1: Normal Operation
1. Both devices online
2. Send message from Device A
3. Verify appears on Device B within 1 second
4. ✅ Expected: Instant delivery via WebSocket

### Scenario 2: Offline Mode
1. Disconnect Device A from network
2. Send messages on Device A
3. Reconnect Device A
4. ✅ Expected: Messages sync when reconnected

### Scenario 3: WebSocket Failure
1. Stop WebSocket server
2. Send message
3. ✅ Expected: Falls back to HTTP polling
4. Restart WebSocket server
5. ✅ Expected: Reconnects automatically

### Scenario 4: Conflict Resolution
1. Disconnect both devices
2. Edit same message on both devices
3. Reconnect both devices
4. ✅ Expected: Conflict resolved (last-write-wins)

## Performance Metrics

Expected performance:
- **Message Delivery**: 50-200ms
- **Connection Time**: 100-500ms
- **Reconnection Time**: 1-5 seconds
- **Battery Impact**: Minimal (1 ping/30s)
- **Bandwidth**: ~2KB/hour (keep-alive only)

## Troubleshooting

### WebSocket Not Connecting

**Problem**: Connection status shows "Disconnected"

**Solutions**:
1. Verify server is running: `curl http://localhost:8080`
2. Check server logs for errors
3. Verify firewall allows WebSocket connections
4. Try different port if 8080 is in use

### Messages Not Syncing

**Problem**: Messages don't appear on other device

**Solutions**:
1. Check connection status indicator
2. Verify both devices are connected to same server
3. Check server logs for broadcast messages
4. Enable debug logging:
   ```dart
   SyncLayer.configureLogger(
     enabled: true,
     minLevel: LogLevel.debug,
   );
   ```

### High Battery Usage

**Problem**: App draining battery quickly

**Solutions**:
1. Increase server ping interval (default: 30s)
2. Disable real-time when app in background
3. Use longer reconnect delay

## Customization

### Change Server URL

```dart
// Development
websocketUrl: 'ws://localhost:8080/ws'

// Production
websocketUrl: 'wss://your-api.com/ws'
```

### Adjust Reconnection

```dart
SyncConfig(
  websocketReconnectDelay: Duration(seconds: 10),
  maxWebsocketReconnectAttempts: 10,
)
```

### Custom Conflict Resolution

```dart
SyncConfig(
  conflictStrategy: ConflictStrategy.custom,
  customConflictResolver: (local, remote, localTime, remoteTime) {
    // Custom merge logic
    return {
      ...remote,
      'text': '${local['text']} | ${remote['text']}',
    };
  },
)
```

## Next Steps

1. **Deploy to Production**
   - Set up production WebSocket server
   - Use secure WebSocket (WSS)
   - Add authentication
   - Implement rate limiting

2. **Add Features**
   - User presence (online/offline status)
   - Typing indicators
   - Read receipts
   - Message reactions
   - File attachments

3. **Optimize Performance**
   - Message pagination
   - Virtual scrolling for large lists
   - Image compression
   - Background sync optimization

## Resources

- [Real-Time Sync Guide](../../doc/REALTIME_SYNC_GUIDE.md)
- [Backend WebSocket Protocol](../../doc/BACKEND_WEBSOCKET_PROTOCOL.md)
- [Migration Guide](../../doc/REALTIME_MIGRATION_GUIDE.md)
- [SyncLayer Documentation](https://pub.dev/packages/synclayer)

## License

This example is part of the SyncLayer package and follows the same license.
