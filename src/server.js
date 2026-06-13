const express = require('express');
const cors = require('cors');
const http = require('http');
const messageStore = require('./messageStore');
const kvStore = require('./kvStore');
const wsHub = require('./wsHub');

const app = express();
const server = http.createServer(app);
const port = process.env.PORT || 10000;
const startTime = Date.now();

app.use(cors());
app.use(express.json({ limit: '1mb' }));

wsHub.init(server);

app.get('/', (_req, res) => {
  res.json({
    service: 'stock-relay',
    status: 'ok',
    endpoints: {
      health: 'GET /health',
      messages: 'GET /api/v1/messages?since_id={id}',
      ingest: 'POST /api/v1/ingest',
      store_get: 'GET /api/v1/store/:key',
      store_post: 'POST /api/v1/store/:key',
      websocket: 'wss://{host}/ws/messages',
    },
  });
});

app.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    uptime: Math.floor((Date.now() - startTime) / 1000),
    connected_clients: wsHub.connectedCount(),
    message_count: messageStore.count(),
  });
});

app.get('/api/v1/messages', (req, res) => {
  const sinceId = req.query.since_id || null;
  const messages = messageStore.getSince(sinceId);
  res.json({ messages, has_more: false });
});

app.post('/api/v1/ingest', (req, res) => {
  const body = req.body;

  if (!body || (typeof body !== 'object')) {
    return res.status(400).json({ error: 'invalid_body', message: 'Request body must be JSON' });
  }

  let incoming = [];
  if (Array.isArray(body.messages)) {
    incoming = body.messages;
  } else if (body.id || body.type || body.symbol) {
    incoming = [body];
  } else {
    return res.status(400).json({
      error: 'invalid_body',
      message: 'Send a single message object or { "messages": [...] }',
    });
  }

  const stored = messageStore.addMessages(incoming);
  wsHub.broadcastMessages(stored);

  res.status(201).json({
    accepted: stored.length,
    messages: stored,
  });
});

app.post('/api/v1/store/:key', (req, res) => {
  const { key } = req.params;
  const body = req.body;

  if (!kvStore.isValidKey(key)) {
    return res.status(400).json({
      error: 'invalid_key',
      message: 'Key must be 1-128 characters: letters, numbers, underscore, or hyphen',
    });
  }

  if (!body || typeof body !== 'object' || typeof body.value !== 'string') {
    return res.status(400).json({
      error: 'invalid_body',
      message: 'Request body must be JSON with a "value" field containing a base64 string',
    });
  }

  if (!kvStore.isValidBase64(body.value)) {
    return res.status(400).json({
      error: 'invalid_value',
      message: '"value" must be a valid base64-encoded string',
    });
  }

  const entry = kvStore.set(key, body.value);

  res.status(201).json({
    key,
    value: entry.value,
    updated_at: entry.updated_at,
  });
});

app.get('/api/v1/store/:key', (req, res) => {
  const { key } = req.params;

  if (!kvStore.isValidKey(key)) {
    return res.status(400).json({
      error: 'invalid_key',
      message: 'Key must be 1-128 characters: letters, numbers, underscore, or hyphen',
    });
  }

  const entry = kvStore.get(key);
  if (!entry) {
    return res.status(404).json({
      error: 'not_found',
      message: `No value stored for key "${key}"`,
    });
  }

  res.json({
    key,
    value: entry.value,
    updated_at: entry.updated_at,
  });
});

server.listen(port, '0.0.0.0', () => {
  console.log(`StockRelay listening on port ${port}`);
});
