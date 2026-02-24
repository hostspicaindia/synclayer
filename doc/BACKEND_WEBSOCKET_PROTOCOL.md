# Backend WebSocket Protocol Specification

## Overview

This document specifies the WebSocket protocol that backend servers must implement to support SyncLayer's real-time sync feature.

## Table of Contents

1. [Connection](#connection)
2. [Message Format](#message-format)
3. [Message Types](#message-types)
4. [Authentication](#authentication)
5. [Subscription Management](#subscription-management)
6. [Data Synchronization](#data-synchronization)
7. [Keep-Alive](#keep-alive)
8. [Error Handling](#error-handling)
9. [Implementation Examples](#implementation-examples)

## Connection

### Endpoint

```
wss://your-api.com/ws
```

Must use secure WebSocket (WSS) in production.

### Connection Flow

```
1. Client → Server: WebSocket connection request
   GET wss://api.example.com/ws?token=AUTH_TOKEN
   Upgrade: websocket
   
2. Server → Client: Connection accepted (101 Switching Protocols)
   
3. Client → Server: Subscribe to collections
   {"type": "subscribe", "collection": "todos"}
   
4. Server → Client: Subscription confirmed
   {"type": "subscribed", "collection": "todos"}
```

## Message Format

All messages are JSON objects with the following structure:

```typescript
interface WebSocketMessage {
  type: MessageType;           // Required: Message type
  collection?: string;          // Collection name (for data messages)
  recordId?: string;            // Record ID (for data messages)
  data?: Record<string, any>;   // Record data
  timestamp?: string;           // ISO 8601 timestamp
  metadata?: Record<string, any>; // Additional metadata
}
```

### Message Types

```typescript
enum MessageType {
  // Subscription
  subscribe = 'subscribe',
  unsubscribe = 'unsubscribe',
  subscribed = 'subscribed',
  unsubscribed = 'unsubscribed',
  
  // Data operations
  insert = 'insert',
  update = 'update',
  delete = 'delete',
  sync = 'sync',
  
  // Keep-alive
  ping = 'ping',
  pong = 'pong',
  
  // Errors
  error = 'error',
}
```

## Authentication

### Method 1: Query Parameter (Recommended)

```
wss://api.example.com/ws?token=AUTH_TOKEN
```

Server validates token on connection.

### Method 2: First Message

```json
// Client → Server (first message)
{
  "type": "auth",
  "token": "AUTH_TOKEN"
}

// Server → Client (success)
{
  "type": "authenticated"
}

// Server → Client (failure)
{
  "type": "error",
  "error": "Invalid token"
}
```

### Authorization

Server must validate that authenticated user has permission to:
- Subscribe to requested collections
- Receive updates for specific records
- Send updates to collections

## Subscription Management

### Subscribe to Collection

```json
// Client → Server
{
  "type": "subscribe",
  "collection": "todos"
}

// Server → Client (success)
{
  "type": "subscribed",
  "collection": "todos",
  "metadata": {
    "recordCount": 42
  }
}

// Server → Client (failure)
{
  "type": "error",
  "error": "Unauthorized access to collection 'todos'"
}
```

### Unsubscribe from Collection

```json
// Client → Server
{
  "type": "unsubscribe",
  "collection": "todos"
}

// Server → Client
{
  "type": "unsubscribed",
  "collection": "todos"
}
```

### Multiple Collections

Client can subscribe to multiple collections:

```json
{"type": "subscribe", "collection": "todos"}
{"type": "subscribe", "collection": "users"}
{"type": "subscribe", "collection": "notes"}
```

## Data Synchronization

### Insert Operation

```json
// Client → Server (new record created)
{
  "type": "insert",
  "collection": "todos",
  "recordId": "550e8400-e29b-41d4-a716-446655440000",
  "data": {
    "text": "Buy groceries",
    "done": false,
    "createdAt": "2026-02-24T10:30:00Z"
  },
  "timestamp": "2026-02-24T10:30:00Z"
}

// Server → All subscribed clients (broadcast)
{
  "type": "insert",
  "collection": "todos",
  "recordId": "550e8400-e29b-41d4-a716-446655440000",
  "data": {
    "text": "Buy groceries",
    "done": false,
    "createdAt": "2026-02-24T10:30:00Z"
  },
  "timestamp": "2026-02-24T10:30:00Z",
  "metadata": {
    "version": 1,
    "userId": "user123"
  }
}
```

### Update Operation

```json
// Client → Server (record updated)
{
  "type": "update",
  "collection": "todos",
  "recordId": "550e8400-e29b-41d4-a716-446655440000",
  "data": {
    "done": true  // Delta update - only changed fields
  },
  "timestamp": "2026-02-24T10:31:00Z"
}

// Server → All subscribed clients (broadcast)
{
  "type": "update",
  "collection": "todos",
  "recordId": "550e8400-e29b-41d4-a716-446655440000",
  "data": {
    "done": true
  },
  "timestamp": "2026-02-24T10:31:00Z",
  "metadata": {
    "version": 2,
    "userId": "user123"
  }
}
```

### Delete Operation

```json
// Client → Server (record deleted)
{
  "type": "delete",
  "collection": "todos",
  "recordId": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-02-24T10:32:00Z"
}

// Server → All subscribed clients (broadcast)
{
  "type": "delete",
  "collection": "todos",
  "recordId": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-02-24T10:32:00Z",
  "metadata": {
    "userId": "user123"
  }
}
```

### Full Sync Operation

Used for initial sync or resync after reconnection:

```json
// Server → Client (full collection sync)
{
  "type": "sync",
  "collection": "todos",
  "data": {
    "records": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "data": {
          "text": "Buy groceries",
          "done": false
        },
        "version": 1,
        "updatedAt": "2026-02-24T10:30:00Z"
      },
      {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "data": {
          "text": "Walk dog",
          "done": true
        },
        "version": 3,
        "updatedAt": "2026-02-24T09:15:00Z"
      }
    ]
  },
  "timestamp": "2026-02-24T10:35:00Z"
}
```

## Keep-Alive

### Ping/Pong

Client sends ping every 30 seconds to keep connection alive:

```json
// Client → Server (every 30s)
{
  "type": "ping"
}

// Server → Client
{
  "type": "pong"
}
```

Server should close connection if no ping received for 60 seconds.

## Error Handling

### Error Message Format

```json
{
  "type": "error",
  "error": "Error message",
  "code": "ERROR_CODE",
  "metadata": {
    "collection": "todos",
    "recordId": "550e8400-e29b-41d4-a716-446655440000"
  }
}
```

### Common Error Codes

| Code | Description |
|------|-------------|
| `AUTH_FAILED` | Authentication failed |
| `UNAUTHORIZED` | User not authorized for operation |
| `INVALID_MESSAGE` | Malformed message |
| `COLLECTION_NOT_FOUND` | Collection doesn't exist |
| `RECORD_NOT_FOUND` | Record doesn't exist |
| `RATE_LIMIT_EXCEEDED` | Too many requests |
| `SERVER_ERROR` | Internal server error |

### Example Errors

```json
// Authentication error
{
  "type": "error",
  "error": "Invalid authentication token",
  "code": "AUTH_FAILED"
}

// Authorization error
{
  "type": "error",
  "error": "User not authorized to access collection 'admin_logs'",
  "code": "UNAUTHORIZED",
  "metadata": {
    "collection": "admin_logs"
  }
}

// Rate limit error
{
  "type": "error",
  "error": "Rate limit exceeded: 100 messages per minute",
  "code": "RATE_LIMIT_EXCEEDED"
}
```

## Implementation Examples

### Node.js (Express + ws)

```javascript
const express = require('express');
const WebSocket = require('ws');
const jwt = require('jsonwebtoken');

const app = express();
const server = app.listen(3000);
const wss = new WebSocket.Server({ server });

// Store subscriptions: Map<collection, Set<WebSocket>>
const subscriptions = new Map();

wss.on('connection', (ws, req) => {
  // Authenticate
  const url = new URL(req.url, 'ws://localhost');
  const token = url.searchParams.get('token');
  
  let userId;
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    userId = decoded.userId;
  } catch (err) {
    ws.send(JSON.stringify({
      type: 'error',
      error: 'Invalid token',
      code: 'AUTH_FAILED'
    }));
    ws.close();
    return;
  }
  
  console.log(`User ${userId} connected`);
  
  // Handle messages
  ws.on('message', async (data) => {
    try {
      const message = JSON.parse(data);
      
      switch (message.type) {
        case 'subscribe':
          handleSubscribe(ws, userId, message.collection);
          break;
          
        case 'unsubscribe':
          handleUnsubscribe(ws, message.collection);
          break;
          
        case 'insert':
        case 'update':
        case 'delete':
          await handleDataChange(ws, userId, message);
          break;
          
        case 'ping':
          ws.send(JSON.stringify({ type: 'pong' }));
          break;
          
        default:
          ws.send(JSON.stringify({
            type: 'error',
            error: `Unknown message type: ${message.type}`,
            code: 'INVALID_MESSAGE'
          }));
      }
    } catch (err) {
      console.error('Error handling message:', err);
      ws.send(JSON.stringify({
        type: 'error',
        error: err.message,
        code: 'SERVER_ERROR'
      }));
    }
  });
  
  // Handle disconnect
  ws.on('close', () => {
    console.log(`User ${userId} disconnected`);
    // Remove from all subscriptions
    subscriptions.forEach((clients) => clients.delete(ws));
  });
});

function handleSubscribe(ws, userId, collection) {
  // Check authorization
  if (!canAccessCollection(userId, collection)) {
    ws.send(JSON.stringify({
      type: 'error',
      error: `Unauthorized access to collection '${collection}'`,
      code: 'UNAUTHORIZED',
      metadata: { collection }
    }));
    return;
  }
  
  // Add to subscriptions
  if (!subscriptions.has(collection)) {
    subscriptions.set(collection, new Set());
  }
  subscriptions.get(collection).add(ws);
  
  // Confirm subscription
  ws.send(JSON.stringify({
    type: 'subscribed',
    collection,
    metadata: {
      recordCount: getCollectionCount(collection)
    }
  }));
  
  console.log(`User ${userId} subscribed to ${collection}`);
}

function handleUnsubscribe(ws, collection) {
  if (subscriptions.has(collection)) {
    subscriptions.get(collection).delete(ws);
  }
  
  ws.send(JSON.stringify({
    type: 'unsubscribed',
    collection
  }));
}

async function handleDataChange(ws, userId, message) {
  const { type, collection, recordId, data } = message;
  
  // Validate
  if (!canModifyCollection(userId, collection)) {
    ws.send(JSON.stringify({
      type: 'error',
      error: 'Unauthorized to modify collection',
      code: 'UNAUTHORIZED'
    }));
    return;
  }
  
  // Save to database
  await saveToDatabase(type, collection, recordId, data, userId);
  
  // Broadcast to all subscribers
  const broadcast = {
    type,
    collection,
    recordId,
    data,
    timestamp: new Date().toISOString(),
    metadata: {
      version: await getRecordVersion(collection, recordId),
      userId
    }
  };
  
  broadcastToCollection(collection, broadcast, ws);
}

function broadcastToCollection(collection, message, excludeWs = null) {
  const clients = subscriptions.get(collection);
  if (!clients) return;
  
  const messageStr = JSON.stringify(message);
  
  clients.forEach((client) => {
    // Don't send back to sender
    if (client === excludeWs) return;
    
    if (client.readyState === WebSocket.OPEN) {
      client.send(messageStr);
    }
  });
}

// Helper functions (implement based on your database)
function canAccessCollection(userId, collection) {
  // Check user permissions
  return true; // Implement your logic
}

function canModifyCollection(userId, collection) {
  // Check user permissions
  return true; // Implement your logic
}

function getCollectionCount(collection) {
  // Return record count
  return 0; // Implement your logic
}

async function saveToDatabase(type, collection, recordId, data, userId) {
  // Save to your database
  // Implement based on your database
}

async function getRecordVersion(collection, recordId) {
  // Get current version from database
  return 1; // Implement your logic
}

console.log('WebSocket server running on ws://localhost:3000');
```

### Python (FastAPI + websockets)

```python
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from typing import Dict, Set
import json
import jwt
from datetime import datetime

app = FastAPI()

# Store subscriptions: Dict[collection, Set[WebSocket]]
subscriptions: Dict[str, Set[WebSocket]] = {}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, token: str):
    # Authenticate
    try:
        payload = jwt.decode(token, "SECRET_KEY", algorithms=["HS256"])
        user_id = payload["userId"]
    except jwt.InvalidTokenError:
        await websocket.close(code=1008, reason="Invalid token")
        return
    
    await websocket.accept()
    print(f"User {user_id} connected")
    
    try:
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)
            
            if message["type"] == "subscribe":
                await handle_subscribe(websocket, user_id, message["collection"])
            
            elif message["type"] == "unsubscribe":
                await handle_unsubscribe(websocket, message["collection"])
            
            elif message["type"] in ["insert", "update", "delete"]:
                await handle_data_change(websocket, user_id, message)
            
            elif message["type"] == "ping":
                await websocket.send_json({"type": "pong"})
            
            else:
                await websocket.send_json({
                    "type": "error",
                    "error": f"Unknown message type: {message['type']}",
                    "code": "INVALID_MESSAGE"
                })
    
    except WebSocketDisconnect:
        print(f"User {user_id} disconnected")
        # Remove from all subscriptions
        for clients in subscriptions.values():
            clients.discard(websocket)

async def handle_subscribe(ws: WebSocket, user_id: str, collection: str):
    # Check authorization
    if not can_access_collection(user_id, collection):
        await ws.send_json({
            "type": "error",
            "error": f"Unauthorized access to collection '{collection}'",
            "code": "UNAUTHORIZED",
            "metadata": {"collection": collection}
        })
        return
    
    # Add to subscriptions
    if collection not in subscriptions:
        subscriptions[collection] = set()
    subscriptions[collection].add(ws)
    
    # Confirm subscription
    await ws.send_json({
        "type": "subscribed",
        "collection": collection,
        "metadata": {
            "recordCount": get_collection_count(collection)
        }
    })
    
    print(f"User {user_id} subscribed to {collection}")

async def handle_unsubscribe(ws: WebSocket, collection: str):
    if collection in subscriptions:
        subscriptions[collection].discard(ws)
    
    await ws.send_json({
        "type": "unsubscribed",
        "collection": collection
    })

async def handle_data_change(ws: WebSocket, user_id: str, message: dict):
    msg_type = message["type"]
    collection = message["collection"]
    record_id = message["recordId"]
    data = message.get("data")
    
    # Validate
    if not can_modify_collection(user_id, collection):
        await ws.send_json({
            "type": "error",
            "error": "Unauthorized to modify collection",
            "code": "UNAUTHORIZED"
        })
        return
    
    # Save to database
    await save_to_database(msg_type, collection, record_id, data, user_id)
    
    # Broadcast to all subscribers
    broadcast = {
        "type": msg_type,
        "collection": collection,
        "recordId": record_id,
        "data": data,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "metadata": {
            "version": await get_record_version(collection, record_id),
            "userId": user_id
        }
    }
    
    await broadcast_to_collection(collection, broadcast, exclude_ws=ws)

async def broadcast_to_collection(collection: str, message: dict, exclude_ws: WebSocket = None):
    if collection not in subscriptions:
        return
    
    clients = subscriptions[collection]
    message_str = json.dumps(message)
    
    for client in clients:
        if client == exclude_ws:
            continue
        
        try:
            await client.send_text(message_str)
        except:
            pass  # Client disconnected

# Helper functions
def can_access_collection(user_id: str, collection: str) -> bool:
    # Implement your authorization logic
    return True

def can_modify_collection(user_id: str, collection: str) -> bool:
    # Implement your authorization logic
    return True

def get_collection_count(collection: str) -> int:
    # Implement your database query
    return 0

async def save_to_database(msg_type: str, collection: str, record_id: str, data: dict, user_id: str):
    # Implement your database save logic
    pass

async def get_record_version(collection: str, record_id: str) -> int:
    # Implement your database query
    return 1
```

## Security Best Practices

1. **Always use WSS (secure WebSocket)** in production
2. **Validate authentication** on every connection
3. **Check authorization** for every operation
4. **Rate limit** messages per user/connection
5. **Validate message format** before processing
6. **Sanitize data** before broadcasting
7. **Log security events** (failed auth, unauthorized access)
8. **Implement timeouts** for idle connections
9. **Use connection limits** per user
10. **Monitor for abuse** patterns

## Performance Optimization

1. **Use message batching** for high-frequency updates
2. **Implement backpressure** handling
3. **Use binary format** (MessagePack) for large payloads
4. **Cache subscription lists** for fast lookups
5. **Use connection pooling** for database
6. **Implement horizontal scaling** with Redis pub/sub
7. **Monitor connection count** and memory usage
8. **Use compression** for large messages

## Testing

### Test Checklist

- [ ] Connection establishment
- [ ] Authentication (valid/invalid tokens)
- [ ] Authorization (allowed/denied collections)
- [ ] Subscribe/unsubscribe
- [ ] Insert/update/delete operations
- [ ] Message broadcasting
- [ ] Ping/pong keep-alive
- [ ] Error handling
- [ ] Reconnection
- [ ] Concurrent connections
- [ ] Rate limiting
- [ ] Connection timeout

### Test Tools

- **wscat**: Command-line WebSocket client
- **Postman**: WebSocket testing
- **Artillery**: Load testing
- **Custom test scripts**: Automated testing

## Conclusion

This protocol specification provides everything needed to implement a WebSocket server compatible with SyncLayer's real-time sync feature. Follow the message formats, handle all message types, and implement proper authentication/authorization for a secure, scalable real-time sync backend.
