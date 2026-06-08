# Stock Tracker API Contract

The iOS app syncs messages incrementally by passing the **last received message ID**. The server returns only messages newer than that ID.

---

## Connection Modes

| Mode | Behavior |
|------|----------|
| **Polling** | `GET` request every 5 seconds |
| **WebSocket** | Persistent connection; client sends `last_message_id` on connect and after each batch |

---

## 1. Polling (HTTP)

### Request

```http
GET /api/v1/messages?since_id={last_message_id} HTTP/1.1
Host: {server_ip}:{port}
Accept: application/json
```

**Query parameters**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `since_id` | string | No | Last message ID the client has. Omit or send `null` on first request to get all recent messages. |

**Example (first request — no prior messages)**

```http
GET /api/v1/messages HTTP/1.1
Host: 192.168.1.100:8080
Accept: application/json
```

**Example (subsequent request)**

```http
GET /api/v1/messages?since_id=msg_003 HTTP/1.1
Host: 192.168.1.100:8080
Accept: application/json
```

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
    },
    {
      "id": "msg_005",
      "timestamp": "2025-06-08T14:30:05Z",
      "type": "alert",
      "symbol": "TCS",
      "message": "Price crossed resistance at 3850",
      "severity": "high"
    }
  ],
  "has_more": false
}
```

| Field | Type | Description |
|-------|------|-------------|
| `messages` | array | New messages with `id` greater than `since_id` (server-defined ordering) |
| `has_more` | boolean | If `true`, client should immediately poll again for remaining messages |

**Empty response (no new messages)**

```json
{
  "messages": [],
  "has_more": false
}
```

---

## 2. WebSocket

### Connect

```
ws://{server_ip}:{port}/ws/messages
```

### Client → Server (on connect and after processing each batch)

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

### Server → Client (heartbeat, optional)

```json
{
  "type": "ping"
}
```

Client may respond with:

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
  "error": "invalid_since_id",
  "message": "since_id 'msg_999' not found"
}
```

HTTP status codes: `400` bad request, `500` server error.

---

## App Configuration (Settings)

| Setting | Default | Description |
|---------|---------|-------------|
| Server host | `192.168.1.100` | Placeholder — update when BE is ready |
| Server port | `8080` | API port |
| Connection mode | Polling | `polling` or `websocket` |
| Use dummy data | `true` | Shows simulated messages until BE is connected |
