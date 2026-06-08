const WebSocket = require('ws');
const messageStore = require('./messageStore');

let wss = null;
const clientState = new WeakMap();

function init(server) {
  wss = new WebSocket.Server({ server, path: '/ws/messages' });

  wss.on('connection', (ws) => {
    clientState.set(ws, { lastMessageId: null });
    ws.isAlive = true;

    ws.on('pong', () => {
      ws.isAlive = true;
    });

    ws.on('message', (data) => {
      handleClientMessage(ws, data);
    });

    ws.on('close', () => {
      clientState.delete(ws);
    });

    ws.on('error', (err) => {
      console.error('WebSocket client error:', err.message);
    });
  });

  const heartbeat = setInterval(() => {
    if (!wss) return;

    wss.clients.forEach((ws) => {
      if (ws.isAlive === false) {
        return ws.terminate();
      }
      ws.isAlive = false;
      ws.ping();
      sendJson(ws, { type: 'ping' });
    });
  }, 30000);

  wss.on('close', () => {
    clearInterval(heartbeat);
  });
}

function handleClientMessage(ws, data) {
  let payload;
  try {
    payload = JSON.parse(data.toString());
  } catch {
    sendJson(ws, { type: 'error', message: 'Invalid JSON' });
    return;
  }

  if (payload.action === 'pong') {
    return;
  }

  if (payload.action === 'sync') {
    const lastMessageId = payload.last_message_id || null;
    sendSyncResponse(ws, lastMessageId);
    return;
  }

  sendJson(ws, { type: 'error', message: `Unknown action: ${payload.action}` });
}

function sendJson(ws, payload) {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(payload));
  }
}

function broadcastMessages(messages) {
  if (!wss || messages.length === 0) return;

  const payload = { type: 'messages', messages, has_more: false };

  wss.clients.forEach((ws) => {
    if (ws.readyState !== WebSocket.OPEN) return;
    sendJson(ws, payload);

    const last = messages[messages.length - 1];
    if (last) {
      clientState.set(ws, { lastMessageId: last.id });
    }
  });
}

function sendSyncResponse(ws, lastMessageId) {
  const missed = messageStore.getSince(lastMessageId);
  const latestId = missed.at(-1)?.id ?? lastMessageId ?? null;
  clientState.set(ws, { lastMessageId: latestId });
  sendJson(ws, { type: 'messages', messages: missed, has_more: false });
}

function connectedCount() {
  return wss ? wss.clients.size : 0;
}

module.exports = {
  init,
  broadcastMessages,
  connectedCount,
};
