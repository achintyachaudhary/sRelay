const express = require('express');
const cors = require('cors');
const http = require('http');
const messageStore = require('./messageStore');
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

server.listen(port, '0.0.0.0', () => {
  console.log(`StockRelay listening on port ${port}`);
});
