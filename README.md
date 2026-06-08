# StockRelay

Node.js relay server for the Stock Tracker iOS app. Deploy to [Render](https://render.com) free tier.

Your stock market backend pushes messages here; connected iOS clients receive them instantly over WebSocket.

## Local development

```bash
cd StockRelay
npm install
npm start
```

Server runs at `http://localhost:10000`.

## Deploy to Render

1. Push this folder to a GitHub repo.
2. In the [Render Dashboard](https://dashboard.render.com), click **New → Web Service**.
3. Connect your repo and use these settings:

| Setting | Value |
|---------|-------|
| Language | Node |
| Build Command | `npm install` |
| Start Command | `npm start` |
| Instance Type | Free |
| Health Check Path | `/health` |

Or use the included [`render.yaml`](render.yaml) Blueprint for one-click deploy.

4. Deployed URL: `https://srelay.onrender.com`.

### Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `10000` | Set automatically by Render |
| `MAX_MESSAGES` | `1000` | In-memory message cap |

## API

### Health (keepalive)

```bash
curl https://srelay.onrender.com/health
```

```json
{
  "status": "ok",
  "uptime": 3600,
  "connected_clients": 1,
  "message_count": 42
}
```

The iOS app calls this every **7 minutes** to prevent Render free-tier spin-down (15 min idle limit).

### Ingest (stock backend pushes here)

**Single message:**

```bash
curl -X POST https://srelay.onrender.com/api/v1/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "id": "msg_001",
    "type": "price_update",
    "symbol": "RELIANCE",
    "price": 2845.50,
    "change_percent": 1.25
  }'
```

**Batch:**

```bash
curl -X POST https://srelay.onrender.com/api/v1/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      { "type": "price_update", "symbol": "TCS", "price": 3842.75 },
      { "type": "alert", "symbol": "INFY", "message": "Volume spike" }
    ]
  }'
```

`id` and `timestamp` are auto-generated if omitted.

### Polling (iOS fallback)

```bash
curl "https://srelay.onrender.com/api/v1/messages?since_id=msg_001"
```

### WebSocket (iOS primary)

```
wss://srelay.onrender.com/ws/messages
```

Client sync message:

```json
{ "action": "sync", "last_message_id": "msg_003" }
```

Server push:

```json
{
  "type": "messages",
  "messages": [{ "id": "msg_004", "symbol": "RELIANCE", "price": 2845.50 }],
  "has_more": false
}
```

## Architecture

```
Stock Backend  --POST /api/v1/ingest-->  StockRelay (Render)
                                              |
                                         WebSocket push
                                              |
                                         iOS Stock Tracker
```

## Limitations (Render free tier)

- **15-minute idle spin-down** — iOS keepalive ping every 7 min + active WebSocket prevents this
- **Ephemeral memory** — messages lost on restart; iOS app stores history locally
- **~1 min cold start** — if server spins down, first request is slow
- **Public ingest** — no auth yet; add API key before production
