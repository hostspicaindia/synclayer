# SyncLayer Backend

Simple REST backend for testing SyncLayer.

## Setup

```bash
cd backend
npm install
npm start
```

Server runs on `http://localhost:3000`

## Endpoints

### Push Data
```
POST /sync/{collection}
Body: {
  "recordId": "abc123",
  "data": {"text": "Hello"},
  "timestamp": "2026-02-13T10:00:00Z"
}
```

### Pull Data
```
GET /sync/{collection}?since=2026-02-13T10:00:00Z
```

### Delete Data
```
DELETE /sync/{collection}/{recordId}
```

### Health Check
```
GET /health
```

### Debug (View All Data)
```
GET /debug/{collection}
```

## Testing

```bash
# Push data
curl -X POST http://localhost:3000/sync/messages \
  -H "Content-Type: application/json" \
  -d '{"recordId":"msg1","data":{"text":"Hello"},"timestamp":"2026-02-13T10:00:00Z"}'

# Pull data
curl http://localhost:3000/sync/messages

# Health check
curl http://localhost:3000/health

# Debug
curl http://localhost:3000/debug/messages
```

## Notes

- Uses in-memory storage (data lost on restart)
- For production, replace with PostgreSQL/MongoDB
- No authentication (add JWT for production)
- CORS enabled for local testing
