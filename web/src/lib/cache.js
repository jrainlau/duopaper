const DB_NAME = 'duopaper';
const STORE = 'pages';
const VERSION = 1;
export const CACHE_TTL = 6 * 60 * 60 * 1000; // 6 小时内刷新不重新请求接口

let dbPromise = null;
const memory = new Map(); // IndexedDB 不可用（隐私模式等）时的内存兜底

function openDB() {
  if (dbPromise) return dbPromise;
  dbPromise = new Promise((resolve) => {
    if (typeof indexedDB === 'undefined') { resolve(null); return; }
    let request;
    try { request = indexedDB.open(DB_NAME, VERSION); }
    catch { resolve(null); return; }
    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains(STORE)) db.createObjectStore(STORE);
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => resolve(null);
    request.onblocked = () => resolve(null);
  });
  return dbPromise;
}

export function cacheKey({ query, orientation, page }) {
  return `${query.trim().toLowerCase()}|${orientation || 'any'}|${page}`;
}

export function cachePrefix({ query, orientation }) {
  return `${query.trim().toLowerCase()}|${orientation || 'any'}|`;
}

export async function cacheGet(key) {
  const db = await openDB();
  if (!db) return memory.get(key) ?? null;
  return new Promise((resolve) => {
    try {
      const request = db.transaction(STORE, 'readonly').objectStore(STORE).get(key);
      request.onsuccess = () => resolve(request.result ?? null);
      request.onerror = () => resolve(memory.get(key) ?? null);
    } catch { resolve(memory.get(key) ?? null); }
  });
}

export async function cachePut(key, value) {
  const payload = { ...value, savedAt: Date.now() };
  memory.set(key, payload);
  const db = await openDB();
  if (!db) return;
  try {
    db.transaction(STORE, 'readwrite').objectStore(STORE).put(payload, key);
  } catch {
    // 内存副本仍可用于本次会话
  }
}

export async function cacheDeletePrefix(prefix) {
  for (const key of [...memory.keys()]) {
    if (key.startsWith(prefix)) memory.delete(key);
  }
  const db = await openDB();
  if (!db) return;
  await new Promise((resolve) => {
    try {
      const request = db.transaction(STORE, 'readwrite').objectStore(STORE).openCursor();
      request.onsuccess = () => {
        const cursor = request.result;
        if (!cursor) { resolve(); return; }
        if (String(cursor.key).startsWith(prefix)) cursor.delete();
        cursor.continue();
      };
      request.onerror = () => resolve();
    } catch { resolve(); }
  });
}

export function isFresh(entry) {
  return Boolean(entry && Date.now() - (entry.savedAt || 0) < CACHE_TTL);
}
