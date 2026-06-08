const MAX_MESSAGES = parseInt(process.env.MAX_MESSAGES || '1000', 10);

let messages = [];
let idCounter = 0;

function generateId() {
  idCounter += 1;
  return `msg_${String(idCounter).padStart(6, '0')}`;
}

function normalizeMessage(raw) {
  const message = { ...raw };
  if (!message.id) {
    message.id = generateId();
  }
  if (!message.timestamp) {
    message.timestamp = new Date().toISOString();
  }
  return message;
}

function addMessage(raw) {
  const message = normalizeMessage(raw);
  const existingIndex = messages.findIndex((m) => m.id === message.id);
  if (existingIndex >= 0) {
    messages[existingIndex] = message;
    return message;
  }

  messages.push(message);
  if (messages.length > MAX_MESSAGES) {
    messages = messages.slice(messages.length - MAX_MESSAGES);
  }
  return message;
}

function addMessages(rawMessages) {
  return rawMessages.map(addMessage);
}

function getAll() {
  return [...messages];
}

function getSince(sinceId) {
  if (!sinceId) {
    return getAll();
  }

  const index = messages.findIndex((m) => m.id === sinceId);
  if (index === -1) {
    return getAll();
  }

  return messages.slice(index + 1);
}

function count() {
  return messages.length;
}

function clear() {
  messages = [];
}

module.exports = {
  addMessage,
  addMessages,
  getAll,
  getSince,
  count,
  clear,
};
