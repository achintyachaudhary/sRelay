# StockRelay — Key-Value Store API

Simple HTTP API to save and retrieve data by key. Values are stored as **base64-encoded strings** on disk.

**Base URL (production):** `https://srelay.onrender.com`  
**Base URL (local):** `http://localhost:10000`

---

## Overview

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/store/:key` | Save a base64 value under a key |
| `GET` | `/api/v1/store/:key` | Read the stored base64 value for a key |

- **Key** goes in the URL path (`:key`).
- **Value** goes in the JSON request body as a base64 string.
- Posting to the same key **overwrites** the previous value.

---

## Key rules

- 1–128 characters
- Allowed: `a-z`, `A-Z`, `0-9`, `_`, `-`
- Examples: `user_config`, `portfolio-v2`, `device_abc123`

---

## POST — Save data

**`POST /api/v1/store/:key`**

### Request

| Part | Type | Required | Description |
|------|------|----------|-------------|
| `:key` | URL path | Yes | Storage key |
| `value` | JSON body field | Yes | Base64-encoded string |

**Headers:**
```
Content-Type: application/json
```

**Body:**
```json
{
  "value": "eyJuYW1lIjoiSm9obiIsImFnZSI6MzB9"
}
```

The example above is base64 for `{"name":"John","age":30}`.

### Success response — `201 Created`

```json
{
  "key": "user_config",
  "value": "eyJuYW1lIjoiSm9obiIsImFnZSI6MzB9",
  "updated_at": "2026-06-13T10:30:00.000Z"
}
```

### Error responses

| Status | Error | When |
|--------|-------|------|
| `400` | `invalid_key` | Key format is invalid |
| `400` | `invalid_body` | Body is missing or has no `value` field |
| `400` | `invalid_value` | `value` is not valid base64 |

---

## GET — Read data

**`GET /api/v1/store/:key`**

### Request

| Part | Type | Required | Description |
|------|------|----------|-------------|
| `:key` | URL path | Yes | Storage key to look up |

No request body.

### Success response — `200 OK`

```json
{
  "key": "user_config",
  "value": "eyJuYW1lIjoiSm9obiIsImFnZSI6MzB9",
  "updated_at": "2026-06-13T10:30:00.000Z"
}
```

Decode `value` from base64 on the client to get the original bytes/text.

### Error responses

| Status | Error | When |
|--------|-------|------|
| `400` | `invalid_key` | Key format is invalid |
| `404` | `not_found` | No data saved for that key |

---

## Examples

### cURL

**Save:**
```bash
# Encode JSON to base64 first
echo -n '{"symbol":"RELIANCE","qty":10}' | base64
# Output: eyJzeW1ib2wiOiJSRUxJQU5DRSIsInF0eSI6MTB9

curl -X POST "https://srelay.onrender.com/api/v1/store/my_portfolio" \
  -H "Content-Type: application/json" \
  -d '{"value":"eyJzeW1ib2wiOiJSRUxJQU5DRSIsInF0eSI6MTB9"}'
```

**Read:**
```bash
curl "https://srelay.onrender.com/api/v1/store/my_portfolio"
```

**Decode the value locally:**
```bash
curl -s "https://srelay.onrender.com/api/v1/store/my_portfolio" \
  | python3 -c "import sys,json,base64; print(base64.b64decode(json.load(sys.stdin)['value']).decode())"
```

### JavaScript (fetch)

```javascript
const key = 'my_portfolio';
const payload = { symbol: 'RELIANCE', qty: 10 };
const base64Value = btoa(JSON.stringify(payload));

// Save
await fetch(`https://srelay.onrender.com/api/v1/store/${key}`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ value: base64Value }),
});

// Read
const res = await fetch(`https://srelay.onrender.com/api/v1/store/${key}`);
const { value } = await res.json();
const decoded = JSON.parse(atob(value));
console.log(decoded); // { symbol: 'RELIANCE', qty: 10 }
```

### Python

```python
import base64
import json
import requests

BASE = "https://srelay.onrender.com"
key = "my_portfolio"
data = {"symbol": "RELIANCE", "qty": 10}
encoded = base64.b64encode(json.dumps(data).encode()).decode()

# Save
requests.post(
    f"{BASE}/api/v1/store/{key}",
    json={"value": encoded},
)

# Read
res = requests.get(f"{BASE}/api/v1/store/{key}")
stored = res.json()["value"]
decoded = json.loads(base64.b64decode(stored))
print(decoded)
```

### Swift (iOS)

```swift
let key = "my_portfolio"
let payload = ["symbol": "RELIANCE", "qty": 10]
let jsonData = try JSONSerialization.data(withJSONObject: payload)
let base64Value = jsonData.base64EncodedString()

// Save
var request = URLRequest(url: URL(string: "https://srelay.onrender.com/api/v1/store/\(key)")!)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.httpBody = try JSONSerialization.data(withJSONObject: ["value": base64Value])

// Read
let (data, _) = try await URLSession.shared.data(from: URL(string: "https://srelay.onrender.com/api/v1/store/\(key)")!)
let response = try JSONSerialization.jsonObject(with: data) as! [String: Any]
let storedBase64 = response["value"] as! String
let decodedData = Data(base64Encoded: storedBase64)!
let decoded = try JSONSerialization.jsonObject(with: decodedData)
```

---

## How to encode / decode

1. Take your original data (usually JSON text).
2. **Encode:** convert to bytes, then base64 → put in `value`.
3. **Decode:** base64-decode `value` → parse as JSON (or use as plain text).

| Original JSON | Base64 `value` |
|---------------|----------------|
| `{"hello":"world"}` | `eyJoZWxsbyI6IndvcmxkIn0=` |
| `{"a":1,"b":2}` | `eyJhIjoxLCJiIjoyfQ==` |

Online tools work too: search for “base64 encode/decode”.

---

## Notes

- **No authentication** — anyone with the URL can read/write any key. Use unique, hard-to-guess keys (e.g. `team_abc123_secret_config`) until auth is added.
- **Overwrite** — `POST` to the same key replaces the old value.
- **Persistence** — data is written to `data/kv-store.json` on the server. On Render free tier, data may be lost if the service restarts or redeploys.
- **Size limit** — request body max ~1 MB (Express default).

---

## Quick test (local)

```bash
cd StockRelay
npm install
npm start
```

Then:

```bash
curl -X POST "http://localhost:10000/api/v1/store/test_key" \
  -H "Content-Type: application/json" \
  -d '{"value":"aGVsbG8gd29ybGQ="}'

curl "http://localhost:10000/api/v1/store/test_key"
```

Expected GET response:
```json
{
  "key": "test_key",
  "value": "aGVsbG8gd29ybGQ=",
  "updated_at": "..."
}
```

(`aGVsbG8gd29ybGQ=` decodes to `hello world`)

---

## Support

Service health: `GET /health`  
All endpoints: `GET /`
