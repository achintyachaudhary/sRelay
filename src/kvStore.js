const fs = require('fs');
const path = require('path');

const DATA_DIR = process.env.KV_DATA_DIR || path.join(__dirname, '..', 'data');
const STORE_FILE = path.join(DATA_DIR, 'kv-store.json');

function ensureStore() {
  if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
  }
  if (!fs.existsSync(STORE_FILE)) {
    fs.writeFileSync(STORE_FILE, '{}', 'utf8');
  }
}

function readStore() {
  ensureStore();
  const raw = fs.readFileSync(STORE_FILE, 'utf8');
  try {
    return JSON.parse(raw);
  } catch {
    return {};
  }
}

function writeStore(store) {
  ensureStore();
  fs.writeFileSync(STORE_FILE, JSON.stringify(store, null, 2), 'utf8');
}

function isValidKey(key) {
  return typeof key === 'string' && /^[a-zA-Z0-9_-]+$/.test(key) && key.length <= 128;
}

function isValidBase64(value) {
  if (typeof value !== 'string' || value.length === 0) {
    return false;
  }
  if (!/^[A-Za-z0-9+/]*={0,2}$/.test(value) || value.length % 4 !== 0) {
    return false;
  }
  try {
    Buffer.from(value, 'base64');
    return true;
  } catch {
    return false;
  }
}

function set(key, value) {
  const store = readStore();
  const entry = {
    value,
    updated_at: new Date().toISOString(),
  };
  store[key] = entry;
  writeStore(store);
  return entry;
}

function get(key) {
  const store = readStore();
  return store[key] || null;
}

function remove(key) {
  const store = readStore();
  if (!store[key]) {
    return false;
  }
  delete store[key];
  writeStore(store);
  return true;
}

function listKeys() {
  const store = readStore();
  return Object.keys(store);
}

module.exports = {
  isValidKey,
  isValidBase64,
  set,
  get,
  remove,
  listKeys,
};
