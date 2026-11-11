import { useCallback, useState } from 'react';
import { migrateLegacyKey } from '../lib/storage.js';

const STORAGE_KEY = 'duopaper.accessKey';
const LEGACY_KEY = 'darkroom.accessKey';

export function useAccessKey() {
  const [key, setKeyState] = useState(() => {
    migrateLegacyKey(LEGACY_KEY, STORAGE_KEY);
    return localStorage.getItem(STORAGE_KEY) || '';
  });

  const setKey = useCallback((value) => {
    const next = value.trim();
    if (!next) throw new Error('Access Key 不能为空，本页面不会使用默认密钥。');
    localStorage.setItem(STORAGE_KEY, next);
    setKeyState(next);
  }, []);

  const clearKey = useCallback(() => {
    localStorage.removeItem(STORAGE_KEY);
    setKeyState('');
  }, []);

  return { key, setKey, clearKey, configured: Boolean(key) };
}
