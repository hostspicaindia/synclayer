# Real-Time Sync Guide

## Overview

SyncLayer's real-time sync feature enables instant data synchronization across devices using WebSocket connections. Changes made on one device appear immediately on all other connected devices, providing a collaborative, real-time experience.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Configuration](#configuration)
3. [How It Works](#how-it-works)
4. [Usage Examples](#usage-examples)
5. [Event Monitoring](#event-monitoring)
6. [Backend Integration](#backend-integration)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

## Quick Start

### 1. Enable Real-Time Sync

```dart
import 'package:synclayer/synclayer.dart';

await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    enableRealtimeSync: true,  // Enable real-time sync
    websocketUrl: 'wss://api.example.com/ws',  // WebSocket URL
    collections: ['todos', 'users', 'notes'],
  ),
);
```

### 2. Use Normally

```dart
// Save data - syncs instantly to all devices
await SyncLayer.collection('todos').save({
  'text': 'Buy groceries',
  'done': false,
});

// Watch for changes - updates instantly
SyncLayer.collection('todos').watch().listen((todos) {
  print('Todos updated: ${todos.length}');
});
```

That's it! Real-time sync works automatically in the background.

## Configuration

### Basic Configuration

```dart
SyncConfig(
  baseUrl: 'https://api.example.com',
  enableRealtimeSync: true,
  websocketUrl: 'wss://api.example.com/ws',
  collections: ['todos'],
)
```

### Advanced Configuration

```dart
SyncConfig(
  baseUrl: 'https://api.example.com',
  authToken: 'your-auth-token',
  
  // Real-time sync settings
  enableRealtimeSync: true,
  websocketUrl: 'wss://api.example.com/ws',
  websocketReconnectDelay: Duration(seconds: 3),  // Reconnect delay
  maxWebsocketReconnectAttempts: 10,  // Max reconnect attempts
  
  // Collections to sync
  collections: ['todos', 'users', 'notes'],
  
  // Fallback to polling if WebSocket fails
  enableAutoSync: true,
  syncInterval: Duration(minutes: 5),
)
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enableRealtimeSync` | `bool` | `false` | Enable WebSocket-based real-time sync |
| `websocketUrl` | `String?` | `null` | WebSocket server URL (required if enabled) |
| `websocketReconnectDelay` | `Duration` | `5 seconds` | Delay between reconnection attempts |
| `maxWebsocketReconnectAttempts` | `int` | `5` | Maximum reconnection attempts |

## How It Works

### Architecture

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│  Device A   │         │   Server    │         │  Device B   │
│             │         │             │         │             │
│  save() ────┼────────►│ WebSocket   │────────►│ Receives    │
│             │ Instant │  Broadcast  │ Instant │ & Updates   │
│  UI Updates │         │             │         │ UI Updates  │
└─────────────┘         └─────────────┘         └─────────────┘
     50ms                                              150ms
```

### Data Flow

1. **User makes change** → Saved to local storage (instant)
2. **Send via WebSocket** → Broadcast to server (50-200ms)
3. **Server broadcasts** → All connected devices receive update
4. **Other devices update** → Local storage + UI refresh (instant)
5. **HTTP sync backup** → Runs in background as fallback

### Fallback Strategy

- **WebSocket Connected** → Real-time sync active (50-200ms latency)
- **WebSocket Disconnected** → Falls back to HTTP polling (5-300s latency)
- **WebSocket Reconnecting** → HTTP polling continues, auto-reconnect in progress
- **WebSocket Failed** → HTTP polling only until app restart

## Usage Examples

### Example 1: Real-Time Todo App

```dart
import 'package:flutter/material.dart';
import 'package:synclayer/synclayer.dart';

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SyncLayer.collection('todos').watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        final todos = snapshot.data!;
        
        return ListView.builder(
          itemCount: todos.length,
          itemBuilder: (context, index) {
            final todo = todos[index];
            return CheckboxListTile(
              title: Text(todo['text']),
              value: todo['done'] ?? false,
              onChanged: (value) async {
                // Update syncs instantly to all devices
                await SyncLayer.collection('todos').update(
                  todo['id'],
                  {'done': value},
                );
              },
            );
          },
        );
      },
    );
  }
}
```

### Example 2: Collaborative Notes

```dart
class CollaborativeNote extends StatefulWidget {
  final String noteId;
  
  CollaborativeNote({required this.noteId});
  
  @override
  _CollaborativeNoteState createState() => _CollaborativeNoteState();
}

class _CollaborativeNoteState extends State<CollaborativeNote> {
  final _controller = TextEditingController();
  Timer? _debounce;
  
  @override
  void initState() {
    super.initState();
    _loadNote();
  }
  
  Future<void> _loadNote() async {
    final note = await SyncLayer.collection('notes').get(widget.noteId);
    if (note != null) {
      _controller.text = note['content'] ?? '';
    }
  }
  
  void _onTextChanged(String text) {
    // Debounce updates to avoid too many WebSocket messages
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(Duration(milliseconds: 500), () {
      // Send delta update - only changed content
      SyncLayer.collection('notes').update(
        widget.noteId,
        {
          'content': text,
          'lastModified': DateTime.now().toIso8601String(),
        },
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: SyncLayer.collection('notes')
          .where('id', isEqualTo: widget.noteId)
          .watch()
          .map((notes) => notes.isNotEmpty ? notes.first : null),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final note = snapshot.data!;
          // Update UI if content changed from another device
          if (_controller.text != note['content']) {
            _controller.text = note['content'] ?? '';
          }
        }
        
        return TextField(
          controller: _controller,
          onChanged: _onTextChanged,
          maxLines: null,
          decoration: InputDecoration(
            hintText: 'Start typing...',
            border: InputBorder.none,
          ),
        );
      },
    );
  }
  
  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
```

### Example 3: Live Dashboard

```dart
class LiveDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Real-time user count
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: SyncLayer.collection('users')
              .where('status', isEqualTo: 'online')
              .watch(),
          builder: (context, snapshot) {
            final onlineUsers = snapshot.data?.length ?? 0;
            return Text('Online Users: $onlineUsers');
          },
        ),
        
        // Real-time sales
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: SyncLayer.collection('sales')
              .where('date', isEqualTo: DateTime.now().toIso8601String().split('T')[0])
              .watch(),
          builder: (context, snapshot) {
            final sales = snapshot.data ?? [];
            final total = sales.fold<double>(
              0,
              (sum, sale) => sum + (sale['amount'] as num).toDouble(),
            );
            return Text('Today\'s Sales: \$${total.toStringAsFixed(2)}');
          },
        ),
      ],
    );
  }
}
```

### Example 4: Real-Time Chat

```dart
class ChatScreen extends StatelessWidget {
  final String roomId;
  final _controller = TextEditingController();
  
  ChatScreen({required this.roomId});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Message list - updates instantly
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: SyncLayer.collection('messages')
                .where('roomId', isEqualTo: roomId)
                .orderBy('timestamp', descending: true)
                .watch(),
            builder: (context, snapshot) {
              final messages = snapshot.data ?? [];
              return ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return ListTile(
                    title: Text(msg['text']),
                    subtitle: Text(msg['sender']),
                  );
                },
              );
            },
          ),
        ),
        
        // Send message
        TextField(
          controller: _controller,
          onSubmitted: (text) async {
            if (text.trim().isEmpty) return;
            
            // Send message - appears instantly on all devices
            await SyncLayer.collection('messages').save({
              'roomId': roomId,
              'text': text,
              'sender': 'currentUser',
              'timestamp': DateTime.now().toIso8601String(),
            });
            
            _controller.clear();
          },
        ),
      ],
    );
  }
}
```

## Event Monitoring

### Listen to Real-Time Events

```dart
import 'package:synclayer/synclayer.dart';

// Access the real-time sync manager
final realtimeManager = SyncLayerCore.instance.realtimeSyncManager;

if (realtimeManager != null) {
  realtimeManager.events.listen((event) {
    switch (event.type) {
      case SyncEventType.realtimeConnected:
        print('✅ Real-time sync connected');
        print('Collections: ${event.metadata?['collections']}');
        break;
        
      case SyncEventType.realtimeDisconnected:
        print('❌ Real-time sync disconnected');
        break;
        
      case SyncEventType.realtimeInsert:
        print('➕ New record: ${event.collectionName}/${event.recordId}');
        break;
        
      case SyncEventType.realtimeUpdate:
        print('📝 Updated: ${event.collectionName}/${event.recordId}');
        break;
        
      case SyncEventType.realtimeDelete:
        print('🗑️ Deleted: ${event.collectionName}/${event.recordId}');
        break;
        
      case SyncEventType.conflictResolved:
        print('⚠️ Conflict resolved: ${event.collectionName}/${event.recordId}');
        print('Strategy: ${event.metadata?['strategy']}');
        break;
        
      case SyncEventType.error:
        print('❌ Error: ${event.error}');
        break;
    }
  });
}
```

### Check Connection Status

```dart
// Check if real-time sync is active
final isActive = SyncLayerCore.instance.realtimeSyncManager?.isActive ?? false;

if (isActive) {
  print('✅ Real-time sync is active');
} else {
  print('❌ Real-time sync is inactive (using HTTP polling)');
}

// Check WebSocket state
final websocketService = SyncLayerCore.instance.websocketService;
if (websocketService != null) {
  websocketService.onStateChanged.listen((state) {
    print('WebSocket state: ${state.name}');
    // States: disconnected, connecting, connected, reconnecting, error
  });
}
```

## Backend Integration

See [BACKEND_WEBSOCKET_PROTOCOL.md](BACKEND_WEBSOCKET_PROTOCOL.md) for complete backend implementation guide.

### Quick Backend Example (Node.js)

```javascript
const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });

wss.on('connection', (ws, req) => {
  // Authenticate
  const token = new URL(req.url, 'ws://localhost').searchParams.get('token');
  if (!authenticateToken(token)) {
    ws.close();
    return;
  }
  
  ws.on('message', (data) => {
    const message = JSON.parse(data);
    
    switch (message.type) {
      case 'subscribe':
        // Add client to collection subscribers
        subscribeToCollection(ws, message.collection);
        break;
        
      case 'insert':
      case 'update':
      case 'delete':
        // Broadcast to all subscribers
        broadcastToCollection(message.collection, message);
        break;
        
      case 'ping':
        ws.send(JSON.stringify({ type: 'pong' }));
        break;
    }
  });
});
```

## Best Practices

### 1. Debounce Frequent Updates

```dart
// ❌ Bad: Too many WebSocket messages
TextField(
  onChanged: (text) {
    SyncLayer.collection('notes').update(noteId, {'content': text});
  },
);

// ✅ Good: Debounced updates
Timer? _debounce;

TextField(
  onChanged: (text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 500), () {
      SyncLayer.collection('notes').update(noteId, {'content': text});
    });
  },
);
```

### 2. Use Delta Updates

```dart
// ❌ Bad: Sending entire document
await SyncLayer.collection('todos').save({
  'id': todoId,
  'text': 'Buy milk',
  'description': '... 10KB of text ...',
  'done': true,  // Only this changed
}, id: todoId);

// ✅ Good: Send only changed fields
await SyncLayer.collection('todos').update(todoId, {
  'done': true,  // Only 10 bytes instead of 10KB!
});
```

### 3. Handle Connection State

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
    _monitorConnection();
  }
  
  void _monitorConnection() {
    final realtimeManager = SyncLayerCore.instance.realtimeSyncManager;
    realtimeManager?.events.listen((event) {
      if (event.type == SyncEventType.realtimeConnected) {
        setState(() => _isRealtimeActive = true);
      } else if (event.type == SyncEventType.realtimeDisconnected) {
        setState(() => _isRealtimeActive = false);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My App'),
        actions: [
          Icon(
            _isRealtimeActive ? Icons.cloud_done : Icons.cloud_off,
            color: _isRealtimeActive ? Colors.green : Colors.grey,
          ),
        ],
      ),
      body: MyContent(),
    );
  }
}
```

### 4. Optimize for Mobile

```dart
// Use shorter reconnect delays on WiFi
final connectivity = await Connectivity().checkConnectivity();

SyncConfig(
  baseUrl: 'https://api.example.com',
  enableRealtimeSync: true,
  websocketUrl: 'wss://api.example.com/ws',
  
  // Faster reconnect on WiFi, slower on mobile data
  websocketReconnectDelay: connectivity == ConnectivityResult.wifi
      ? Duration(seconds: 2)
      : Duration(seconds: 10),
  
  // More attempts on WiFi
  maxWebsocketReconnectAttempts: connectivity == ConnectivityResult.wifi
      ? 10
      : 3,
)
```

## Troubleshooting

### WebSocket Not Connecting

**Problem**: Real-time sync not working

**Solutions**:
1. Check WebSocket URL is correct and uses `wss://` (secure)
2. Verify auth token is valid
3. Check server is running and accessible
4. Look for firewall/proxy blocking WebSocket connections
5. Check browser console for WebSocket errors

```dart
// Enable debug logging
SyncLayer.configureLogger(
  enabled: true,
  minLevel: LogLevel.debug,
);

// Check connection status
final websocket = SyncLayerCore.instance.websocketService;
print('WebSocket state: ${websocket?.state}');
```

### Frequent Disconnections

**Problem**: WebSocket keeps disconnecting

**Solutions**:
1. Increase ping interval on server (default: 30s)
2. Check network stability
3. Increase reconnect attempts
4. Use longer reconnect delay

```dart
SyncConfig(
  websocketReconnectDelay: Duration(seconds: 10),
  maxWebsocketReconnectAttempts: 10,
)
```

### High Battery Usage

**Problem**: App draining battery

**Solutions**:
1. Increase ping interval on server
2. Debounce frequent updates
3. Use delta updates instead of full documents
4. Disable real-time sync when app is in background

```dart
// Disable real-time when app goes to background
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App in background - disconnect WebSocket
      SyncLayerCore.instance.websocketService?.disconnect();
    } else if (state == AppLifecycleState.resumed) {
      // App in foreground - reconnect
      SyncLayerCore.instance.websocketService?.connect();
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
```

### Conflicts Not Resolving

**Problem**: Data conflicts not being resolved correctly

**Solutions**:
1. Check conflict strategy is appropriate
2. Use custom conflict resolver for complex cases
3. Ensure timestamps are synchronized across devices

```dart
// Use custom conflict resolver
SyncConfig(
  conflictStrategy: ConflictStrategy.custom,
  customConflictResolver: (local, remote, localTime, remoteTime) {
    // Custom merge logic
    return {
      ...remote,
      'tags': [
        ...List<String>.from(local['tags'] ?? []),
        ...List<String>.from(remote['tags'] ?? []),
      ].toSet().toList(),
    };
  },
)
```

## Performance Metrics

### Latency Comparison

| Sync Method | Latency | Battery | Bandwidth |
|-------------|---------|---------|-----------|
| Real-time (WebSocket) | 50-200ms | Low | Very Low |
| HTTP Polling (5 min) | 5-300s | Medium | Medium |
| HTTP Polling (1 min) | 1-60s | High | High |

### Real-World Performance

- **Chat App**: 50-150ms message delivery
- **Collaborative Editing**: 100-200ms keystroke sync
- **Live Dashboard**: 50-100ms metric updates
- **Multiplayer Game**: 50-150ms state sync

## Migration Guide

See [REALTIME_MIGRATION_GUIDE.md](REALTIME_MIGRATION_GUIDE.md) for detailed migration instructions from polling-only sync.

### Quick Migration

```dart
// Before (polling only)
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    syncInterval: Duration(minutes: 5),
    collections: ['todos'],
  ),
);

// After (with real-time sync)
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    syncInterval: Duration(minutes: 5),  // Fallback
    enableRealtimeSync: true,  // Add this
    websocketUrl: 'wss://api.example.com/ws',  // Add this
    collections: ['todos'],
  ),
);

// No other code changes needed!
```

## Conclusion

Real-time sync makes your app feel instant and collaborative. With just a few configuration changes, you can enable WebSocket-based synchronization that's faster, more efficient, and provides a better user experience than polling.

For more information:
- [Backend WebSocket Protocol](BACKEND_WEBSOCKET_PROTOCOL.md)
- [Migration Guide](REALTIME_MIGRATION_GUIDE.md)
- [API Reference](../api/index.html)
