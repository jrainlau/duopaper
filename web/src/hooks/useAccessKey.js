import { useCallback, useState } from 'react';
import { migrateLegacyKey } from '../lib/storage.js';
import { t } from '../i18n/index.js';

const STORAGE_KEY = 'duopaper.accessKey';
const LEGACY_KEY = 'darkroom.accessKey';

export function useAccessKey() {
  const [key, setKeyState] = useState(() => {
    migrateLegacyKey(LEGACY_KEY, STORAGE_KEY);
    return localStorage.getItem(STORAGE_KEY) || '';
  });

  const setKey = useCallback((value) => {
    const next = value.trim();
    if (!next) throw new Error(t('setup.emptyKeyError'));
    localStorage.setItem(STORAGE_KEY, next);
    setKeyState(next);
  }, []);

  const clearKey = useCallback(() => {
    localStorage.removeItem(STORAGE_KEY);
    setKeyState('');
  }, []);

  return { key, setKey, clearKey, configured: Boolean(key) };
}
