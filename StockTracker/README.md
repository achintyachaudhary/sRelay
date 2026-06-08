# Stock Tracker (iOS)

SwiftUI frontend for a custom stock market tracker and analytics backend. The app incrementally syncs messages by passing the **last received message ID** to the server.

## Open in Xcode

```bash
open StockTracker.xcodeproj
```

Select an iPhone simulator (or your device) and press **Run** (⌘R).

## Features

- **Polling mode** — `GET /api/v1/messages?since_id={id}` every 5 seconds
- **WebSocket mode** — persistent `ws://host:port/ws/messages` connection
- **Settings toggle** — switch between polling and WebSocket; configure server host/port
- **Dummy data** — enabled by default until your backend is ready
- **Message cards** — any JSON response field is shown as key → value on the UI

## Settings

| Setting | Default |
|---------|---------|
| Server host | `192.168.1.100` |
| Server port | `8080` |
| Connection mode | Poll every 5 seconds |
| Use dummy data | On |

When your server is ready:

1. Open **Settings** (gear icon)
2. Enter your server IP and port
3. Turn off **Use dummy data**
4. Choose **Poll every 5 seconds** or **WebSocket**
5. Tap **Apply & Restart Connection**

## API Contract

Full request/response samples are in [API_CONTRACT.md](API_CONTRACT.md).

### Quick reference

**Polling request**

```http
GET /api/v1/messages?since_id=msg_003 HTTP/1.1
Host: 192.168.1.100:8080
```

**Polling response**

```json
{
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

**WebSocket client message**

```json
{
  "action": "sync",
  "last_message_id": "msg_003"
}
```

**WebSocket server message**

```json
{
  "type": "messages",
  "messages": [ { "id": "msg_004", "symbol": "RELIANCE", "price": 2845.50 } ],
  "has_more": false
}
```

## Project structure

```
StockTracker/
├── StockTrackerApp.swift          # App entry
├── Views/
│   ├── ContentView.swift          # Main feed + status bar
│   ├── MessageCardView.swift      # Key-value card UI
│   └── SettingsView.swift         # Server & mode settings
├── ViewModels/
│   └── MessageFeedViewModel.swift
├── Models/
│   ├── StockMessage.swift         # Flexible JSON message model
│   └── AppSettings.swift
└── Services/
    ├── DummyMessageService.swift
    ├── PollingMessageService.swift
    └── WebSocketMessageService.swift
```

## Requirements

- Xcode 15+ (tested with Xcode 26)
- iOS 17+
- iPhone only (portrait)
