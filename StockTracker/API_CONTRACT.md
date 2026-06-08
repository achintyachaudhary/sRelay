# Stock Tracker API Contract

The iOS app syncs messages incrementally by passing the **last received message ID**. The StockRelay server on Render stores messages in memory and pushes them to connected clients over WebSocket.

---

## Render Deployment

| Item | Value |
|------|-------|
| Server URL | `https://srelay.onrender.com` |
| WebSocket | `wss://srelay.onrender.com/ws/messages` |
| Health check | `GET /health` (iOS pings every 7 min to prevent spin-down) |
| Ingest | `POST /api/v1/ingest` (stock backend pushes here) |

See [`StockRelay/README.md`](../StockRelay/README.md) for deploy steps.

---

## Connection Modes (iOS)

| Mode | Behavior |
|------|----------|
| **Polling** | `GET` request every 5 seconds |
| **WebSocket** | Persistent connection with auto-reconnect; client sends `last_message_id` on connect |

Additionally, the iOS app always calls `GET /health` every **7 minutes** (independent of connection mode) to keep the Render free-tier server awake.

---

## 0. Health / Keepalive

### Request

```http
GET /health HTTP/1.1
Host: srelay.onrender.com
Accept: application/json
```

### Response

```json
{
  "status": "ok",
  "uptime": 3600,
  "connected_clients": 1,
  "message_count": 42
}
```

---

## 1. Ingest (Stock Backend → Relay)

Your stock market backend pushes new data here. The relay stores it in memory and broadcasts to all connected iOS clients.

### Request

```http
POST /api/v1/ingest HTTP/1.1
Host: srelay.onrender.com
Content-Type: application/json
```

**Single message**

```json
{
  "id": "msg_001",
  "type": "price_update",
  "symbol": "RELIANCE",
  "price": 2845.50,
  "change_percent": 1.25
}
```

**Batch**

```json
{
  "messages": [
    { "type": "price_update", "symbol": "TCS", "price": 3842.75 },
    { "type": "alert", "symbol": "INFY", "message": "Volume spike detected" }
  ]
}
```

`id` and `timestamp` are auto-generated if omitted.

### Response

```json
{
  "accepted": 1,
  "messages": [
    {
      "id": "msg_000001",
      "timestamp": "2025-06-08T14:30:00Z",
      "type": "price_update",
      "symbol": "RELIANCE",
      "price": 2845.50,
      "change_percent": 1.25
    }
  ]
}
```

---

## 2. Polling (HTTP)

### Request

```http
GET /api/v1/messages?since_id={last_message_id} HTTP/1.1
Host: srelay.onrender.com
Accept: application/json
```

**Query parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `since_id` | string | No | Last message ID the client has. Omit on first request. |

### Response

```json
{
  "messages": [
    {
      "id": "msg_004",
      "timestamp": "2025-06-08T14:30:00Z",
      "type": "price_update",
      "symbol": "RELIANCE",
      "price": 2845.50,
      "change_percent": 1.25,
      "volume": 1250000
    }
  ],
  "has_more": false
}
```

**Empty response (no new messages)**

```json
{
  "messages": [],
  "has_more": false
}
```

---

## 3. WebSocket

### Connect

```
wss://srelay.onrender.com/ws/messages
```

Use `wss://` on Render (TLS required). Use `ws://` only for local dev.

### Client → Server (on connect and after reconnect)

```json
{
  "action": "sync",
  "last_message_id": "msg_003"
}
```

Omit `last_message_id` or send `null` on first connect.

### Server → Client (batch of new messages)

```json
{
  "type": "messages",
  "messages": [
    {
      "id": "msg_004",
      "timestamp": "2025-06-08T14:30:00Z",
      "type": "price_update",
      "symbol": "RELIANCE",
      "price": 2845.50,
      "change_percent": 1.25
    }
  ],
  "has_more": false
}
```

### Server → Client (heartbeat)

```json
{
  "type": "ping"
}
```

Client responds with:

```json
{
  "action": "pong"
}
```

---

## Message Schema

Messages are **flexible JSON objects**. The app renders every top-level key as a card row. Minimum expected field:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique message identifier used for incremental sync |

All other fields are displayed as-is (nested objects/arrays are JSON-stringified).

---

## Error Responses (HTTP)

```json
{
  "error": "invalid_body",
  "message": "Send a single message object or { \"messages\": [...] }"
}
```

HTTP status codes: `400` bad request, `500` server error.

---

## App Configuration (Settings)

| Setting | Default | Description |
|---------|---------|-------------|
| Server URL | `https://srelay.onrender.com` | Full Render HTTPS URL |
| Connection mode | WebSocket | `polling` or `websocket` |
| Use dummy data | `false` | Offline testing with simulated messages |
| Notifications | `false` | Push local notification on new messages |
| Local storage | automatic | Messages saved to `messages.json` on device (max 500) |

---

## Data Flow

```
Stock Backend  --POST /api/v1/ingest-->  StockRelay (Render)
                                              |
                                         WebSocket push
                                              |
                                         iOS Stock Tracker
                                              |
                                         Local JSON storage
```

---

## Limitations (Render Free Tier)

- Server spins down after **15 minutes** without inbound traffic (HTTP or WebSocket)
- iOS keepalive (`GET /health` every 7 min) prevents spin-down when app is active
- In-memory messages are **lost** on spin-down/restart; iOS local storage is the archive
- Ingest endpoint is **public** (no auth) for now
