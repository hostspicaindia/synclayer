# Real-Time Sync Migration Guide

## Overview

This guide helps you migrate from polling-based sync to real-time WebSocket sync in SyncLayer. The migration is backward compatible and can be done incrementally.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Migration Steps](#migration-steps)
3. [Backend Setup](#backend-setup)
4. [Client Configuration](#client-configuration)
5. [Testing](#testing)
6. [Rollback Plan](#rollback-plan)
7. [Common Issues](#common-issues)

## Prerequisites

### Client Requirements

- SyncLayer SDK version 1.7.0 or higher
- Flutter SDK 3.0.0 or higher
- `web_socket_channel` package (automatically included)

### Backend Requirements

- WebSocket server implementation
- Support for secure WebSocket (WSS)
- Authentication mechanism
- Message broadcasting capability

## Migration Steps

### Step 1: Update SyncLayer SDK

```yaml
# pubspec.yaml
dependencies:
  synclayer: ^1.7.0  # Update to 1.7.0 or higher
```

```bash
flutter pub upgrade synclayer
```

### Step 2: Set Up Backend WebSocket Server

See [BACKEND_WEBSOCKET_PROTOCOL.md](BACKEND_WEBSOCKET_PROTOCOL.md) for complete implementation guide.

Quick checklist:
- [ ] WebSocket endpoint created (e.g., `wss://api.example.com/ws`)
- [ ] Authentication implemented
- [ ] Authorization implemented
- [ ] Message broadcasting implemented
- [ ] Ping/pong keep-alive implemented
- [ ] Error handling implemented

### Step 3: Update Client Configuration

#### Before (Polling Only)

```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    authToken: yourAuthToken,
    syncInterval: Duration(minutes: 5),
    enableAutoSync: true,
    collections: ['todos', 'users', 'notes'],
  ),
);
```

#### After (With Real-Time Sync)

```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    authToken: yourAuthToken,
    
    // Keep polling as fallback
    syncInterval: Duration(minutes: 5),
    enableAutoSync: true,
    
    // Add real-time sync
    enableRealtimeSync: true,
    websocketUrl: 'wss://api.example.com/ws',
    websocketReconnectDelay: Duration(seconds: 5),
    maxWebsocketReconnectAttempts: 5,
    
    collections: ['todos', 'users', 'notes'],
  ),
);
```

### Step 4: No Code Changes Required!

Your existing code continues to work without modifications:

```dart
// Existing code - works with both polling and real-time
await SyncLayer.collection('todos').save({'text': 'Buy milk'});

// Existing code - works with both polling and real-time
SyncLayer.collection('todos').watch().listen((todos) {
  print('Todos: ${todos.length}');
});
```

### Step 5: Add Connection Status Indicator (Optional)

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isRealtimeActive = false;
  
  @override
  void initState() {
    super.initState();
    _monitorRealtimeStatus();
  }
  
  void _monitorRealtimeStatus() {
    final realtimeManager = SyncLayerCore.instance.realtimeSyncManager;
    
    if (realtimeManager != null) {
      realtimeManager.events.listen((event) {
        if (event.type == SyncEventType.realtimeConnected) {
          setState(() => _isRealtimeActive = true);
          print('✅ Real-time sync active');
        } else if (event.type == SyncEventType.realtimeDisconnected) {
          setState(() => _isRealtimeActive = false);
          print('❌ Real-time sync inactive (using polling)');
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('My App'),
          actions: [
            // Connection status indicator
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(
                    _isRealtimeActive ? Icons.cloud_done : Icons.cloud_queue,
                    color: _isRealtimeActive ? Colors.green : Colors.orange,
                  ),
                  SizedBox(width: 4),
                  Text(
                    _isRealtimeActive ? 'Live' : 'Syncing',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: MyContent(),
      ),
    );
  }
}
```

## Backend Setup

### Option 1: Node.js + Express + ws

```javascript
const express = require('express');
const WebSocket = require('ws');
const app = express();
const server = app.listen(3000);
const wss = new WebSocket.Server({ server });

// See BACKEND_WEBSOCKET_PROTOCOL.md for complete implementation
```

### Option 2: Python + FastAPI + websockets

```python
from fastapi import FastAPI, WebSocket
app = FastAPI()

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, token: str):
    # See BACKEND_WEBSOCKET_PROTOCOL.md for complete implementation
    pass
```

### Option 3: Use Existing Services

If you're using Firebase, Supabase, or similar services, they may already provide WebSocket support:

- **Firebase**: Use Firebase Realtime Database or Firestore real-time listeners
- **Supabase**: Use Supabase Realtime
- **Hasura**: Use GraphQL subscriptions over WebSocket
- **AWS AppSync**: Use GraphQL subscriptions

## Client Configuration

### Development Environment

```dart
SyncConfig(
  baseUrl: 'http://localhost:3000',
  websocketUrl: 'ws://localhost:3000/ws',  // Non-secure for local dev
  enableRealtimeSync: true,
)
```

### Production Environment

```dart
SyncConfig(
  baseUrl: 'https://api.example.com',
  websocketUrl: 'wss://api.example.com/ws',  // Secure WebSocket
  enableRealtimeSync: true,
)
```

### Environment-Based Configuration

```dart
import 'package:flutter/foundation.dart';

final config = SyncConfig(
  baseUrl: kReleaseMode 
      ? 'https://api.example.com'
      : 'http://localhost:3000',
  
  websocketUrl: kReleaseMode
      ? 'wss://api.example.com/ws'
      : 'ws://localhost:3000/ws',
  
  enableRealtimeSync: true,
  
  // More aggressive reconnect in development
  websocketReconnectDelay: kReleaseMode
      ? Duration(seconds: 5)
      : Duration(seconds: 2),
  
  maxWebsocketReconnectAttempts: kReleaseMode ? 5 : 10,
  
  collections: ['todos', 'users', 'notes'],
);
```

## Testing

### Test Plan

1. **Unit Tests**: Verify configuration
2. **Integration Tests**: Test WebSocket connection
3. **Manual Tests**: Test real-time sync behavior
4. **Load Tests**: Test with multiple concurrent users

### Unit Tests

```dart
// test/realtime_config_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';

void main() {
  test('Real-time config is valid', () {
    final config = SyncConfig(
      baseUrl: 'https://api.example.com',
      enableRealtimeSync: true,
      websocketUrl: 'wss://api.example.com/ws',
      collections: ['todos'],
    );
    
    expect(config.enableRealtimeSync, true);
    expect(config.websocketUrl, 'wss://api.example.com/ws');
  });
}
```

### Integration Tests

```dart
// test/realtime_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:synclayer/synclayer.dart';

void main() {
  group('Real-Time Sync Integration', () {
    setUp(() async {
      await SyncLayer.init(
        SyncConfig(
          baseUrl: 'http://localhost:3000',
          enableRealtimeSync: true,
          websocketUrl: 'ws://localhost:3000/ws',
          collections: ['test_collection'],
        ),
      );
    });
    
    tearDown(() async {
      await SyncLayer.dispose();
    });
    
    test('Save triggers real-time update', () async {
      final id = await SyncLayer.collection('test_collection').save({
        'text': 'Test item',
      });
      
      expect(id, isNotEmpty);
      
      // Verify real-time manager is active
      final realtimeManager = SyncLayerCore.instance.realtimeSyncManager;
      expect(realtimeManager, isNotNull);
    });
  });
}
```

### Manual Testing

1. **Two Device Test**
   - Open app on Device A
   - Open app on Device B
   - Create item on Device A
   - Verify item appears on Device B within 1 second

2. **Offline Test**
   - Disconnect from network
   - Create items offline
   - Reconnect to network
   - Verify items sync to server and other devices

3. **Conflict Test**
   - Edit same item on two devices while offline
   - Reconnect both devices
   - Verify conflict is resolved correctly

## Rollback Plan

### Quick Rollback

If issues occur, disable real-time sync:

```dart
SyncConfig(
  baseUrl: 'https://api.example.com',
  enableRealtimeSync: false,  // Disable real-time
  enableAutoSync: true,  // Keep polling
  syncInterval: Duration(minutes: 5),
  collections: ['todos'],
)
```

### Feature Flag Approach

Use a feature flag for gradual rollout:

```dart
import 'package:firebase_remote_config/firebase_remote_config.dart';

final remoteConfig = FirebaseRemoteConfig.instance;
await remoteConfig.fetchAndActivate();

final enableRealtime = remoteConfig.getBool('enable_realtime_sync');

SyncConfig(
  baseUrl: 'https://api.example.com',
  enableRealtimeSync: enableRealtime,  // Controlled remotely
  websocketUrl: enableRealtime ? 'wss://api.example.com/ws' : null,
  collections: ['todos'],
)
```

### Gradual Rollout

1. **Week 1**: Enable for internal testing (5% of users)
2. **Week 2**: Enable for beta users (20% of users)
3. **Week 3**: Enable for 50% of users
4. **Week 4**: Enable for all users (100%)

Monitor metrics at each stage:
- Connection success rate
- Message delivery latency
- Error rate
- Battery usage
- User feedback

## Common Issues

### Issue 1: WebSocket Not Connecting

**Symptoms**: Real-time sync never activates

**Solutions**:
1. Check WebSocket URL is correct
2. Verify server is running and accessible
3. Check firewall/proxy settings
4. Verify SSL certificate (for WSS)
5. Check authentication token

```dart
// Enable debug logging
SyncLayer.configureLogger(
  enabled: true,
  minLevel: LogLevel.debug,
);

// Check WebSocket state
final websocket = SyncLayerCore.instance.websocketService;
print('WebSocket state: ${websocket?.state}');
```

### Issue 2: Frequent Disconnections

**Symptoms**: Connection drops frequently

**Solutions**:
1. Increase ping interval on server
2. Check network stability
3. Increase reconnect attempts
4. Use longer reconnect delay

```dart
SyncConfig(
  websocketReconnectDelay: Duration(seconds: 10),
  maxWebsocketReconnectAttempts: 10,
)
```

### Issue 3: High Battery Usage

**Symptoms**: App drains battery quickly

**Solutions**:
1. Increase server ping interval (default: 30s)
2. Debounce frequent updates
3. Disable real-time when app in background

```dart
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Disconnect when app goes to background
      SyncLayerCore.instance.websocketService?.disconnect();
    } else if (state == AppLifecycleState.resumed) {
      // Reconnect when app comes to foreground
      SyncLayerCore.instance.websocketService?.connect();
    }
  }
}
```

### Issue 4: Messages Not Broadcasting

**Symptoms**: Changes on one device don't appear on others

**Solutions**:
1. Verify server broadcasts messages correctly
2. Check all devices are subscribed to same collection
3. Verify authorization allows access
4. Check server logs for errors

```javascript
// Server-side debugging
function broadcastToCollection(collection, message) {
  const clients = subscriptions.get(collection);
  console.log(`Broadcasting to ${clients?.size || 0} clients`);
  
  clients?.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify(message));
      console.log('Message sent to client');
    }
  });
}
```

### Issue 5: Authentication Failures

**Symptoms**: Connection rejected immediately

**Solutions**:
1. Verify auth token is valid
2. Check token expiration
3. Verify token format matches server expectations
4. Check server authentication logic

```dart
// Update auth token dynamically
final newToken = await getNewAuthToken();

// Reconnect with new token
await SyncLayerCore.instance.websocketService?.disconnect();
// Token will be used on next connect
```

## Performance Monitoring

### Metrics to Track

1. **Connection Metrics**
   - Connection success rate
   - Average connection time
   - Reconnection frequency
   - Connection duration

2. **Message Metrics**
   - Message delivery latency
   - Messages per second
   - Message size
   - Broadcast fanout

3. **Resource Metrics**
   - Battery usage
   - Network bandwidth
   - Memory usage
   - CPU usage

### Monitoring Code

```dart
class RealtimeMonitor {
  int _messagesReceived = 0;
  int _messagesSent = 0;
  DateTime? _connectedAt;
  
  void startMonitoring() {
    final realtimeManager = SyncLayerCore.instance.realtimeSyncManager;
    
    realtimeManager?.events.listen((event) {
      switch (event.type) {
        case SyncEventType.realtimeConnected:
          _connectedAt = DateTime.now();
          print('✅ Connected');
          break;
          
        case SyncEventType.realtimeDisconnected:
          if (_connectedAt != null) {
            final duration = DateTime.now().difference(_connectedAt!);
            print('❌ Disconnected after ${duration.inSeconds}s');
          }
          break;
          
        case SyncEventType.realtimeInsert:
        case SyncEventType.realtimeUpdate:
        case SyncEventType.realtimeDelete:
          _messagesReceived++;
          break;
      }
    });
  }
  
  void printStats() {
    print('Messages received: $_messagesReceived');
    print('Messages sent: $_messagesSent');
    if (_connectedAt != null) {
      final uptime = DateTime.now().difference(_connectedAt!);
      print('Uptime: ${uptime.inMinutes} minutes');
    }
  }
}
```

## Best Practices

1. **Start with polling enabled** as fallback
2. **Monitor metrics** during rollout
3. **Use feature flags** for gradual rollout
4. **Test thoroughly** before production
5. **Have rollback plan** ready
6. **Document issues** and solutions
7. **Communicate with users** about new feature
8. **Monitor battery usage** closely
9. **Optimize message frequency** (debounce)
10. **Use delta updates** to reduce bandwidth

## Success Criteria

Migration is successful when:

- [ ] WebSocket connection success rate > 95%
- [ ] Message delivery latency < 500ms
- [ ] Battery usage increase < 10%
- [ ] No increase in crash rate
- [ ] User satisfaction maintained or improved
- [ ] Rollback plan tested and ready
- [ ] Monitoring in place
- [ ] Documentation complete

## Conclusion

Migrating to real-time sync is straightforward and backward compatible. Start with a small rollout, monitor metrics, and gradually increase adoption. The fallback to polling ensures reliability while you optimize the real-time experience.

For questions or issues, refer to:
- [Real-Time Sync Guide](REALTIME_SYNC_GUIDE.md)
- [Backend WebSocket Protocol](BACKEND_WEBSOCKET_PROTOCOL.md)
- [GitHub Issues](https://github.com/hostspicaindia/synclayer/issues)
