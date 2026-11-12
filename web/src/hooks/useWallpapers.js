import { useCallback, useEffect, useRef, useState } from 'react';
import { buildSearchUrl, describeError, requestJson } from '../lib/unsplash.js';
import { cacheDeletePrefix, cacheGet, cacheKey, cachePrefix, cachePut, isFresh } from '../lib/cache.js';
import { migrateLegacyKey } from '../lib/storage.js';
import { t } from '../i18n/index.js';

const MAX_PAGE = 50;
const PREF_KEY = 'duopaper.prefs';

function readPrefs() {
  migrateLegacyKey('darkroom.prefs', PREF_KEY);
  try { return JSON.parse(localStorage.getItem(PREF_KEY) || '{}'); }
  catch { return {}; }
}

export function useWallpapers(key) {
  // 默认「全部」方向：横图竖图混合，瀑布流的高低错落才看得出来。
  const [query, setQuery] = useState(() => readPrefs().query || 'wallpaper');
  const [orientation, setOrientation] = useState(() => readPrefs().orientation ?? '');
  const [size, setSize] = useState(() => readPrefs().size || 'full');
  const [items, setItems] = useState([]);
  const [total, setTotal] = useState(0);
  const [phase, setPhase] = useState('idle'); // idle | loading | ready | error
  const [message, setMessage] = useState('');
  const [quota, setQuota] = useState(null);
  const [hasMore, setHasMore] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);

  const pageRef = useRef(0);
  const countRef = useRef(0);
  const busyRef = useRef(false);
  const generationRef = useRef(0);

  useEffect(() => {
    try { localStorage.setItem(PREF_KEY, JSON.stringify({ query, orientation, size })); }
    catch { /* 隐私模式下忽略 */ }
  }, [query, orientation, size]);

  const applyPage = useCallback((payload, targetPage, append, fromCache) => {
    const results = Array.isArray(payload.results) ? payload.results : [];
    const loaded = append ? countRef.current + results.length : results.length;
    countRef.current = loaded;
    pageRef.current = targetPage;
    setTotal(payload.total ?? 0);
    setItems((previous) => (append ? [...previous, ...results] : results));
    setHasMore(results.length > 0 && targetPage < (payload.totalPages ?? 1));
    setPhase('ready');
    // 追加页命中缓存时不要让整条状态倒退回「缓存」——本次会话已经联网刷新过。
    setMessage((previous) => {
      const wasOnline = previous.startsWith(t('status.online'));
      const source = wasOnline ? t('status.online') : (fromCache ? t('status.cache') : t('status.online'));
      return t('status.summary', { source, total: payload.total, loaded });
    });
  }, []);

  const loadPage = useCallback(async (targetPage, append, force = false) => {
    if (!key || busyRef.current) return;
    const generation = ++generationRef.current;
    const isCurrent = () => generation === generationRef.current;
    busyRef.current = true;

    if (append) setLoadingMore(true);
    else { setPhase('loading'); setMessage(t('status.fetching')); }

    const pageKey = cacheKey({ query, orientation, page: targetPage });

    try {
      if (!force) {
        const cached = await cacheGet(pageKey);
        if (!isCurrent()) return;
        if (isFresh(cached)) {
          applyPage(cached, targetPage, append, true);
          return; // 缓存命中：本次刷新零接口请求
        }
      }

      const { data, quota: nextQuota } = await requestJson(
        buildSearchUrl({ query, orientation, page: targetPage }),
        key,
        undefined,
        force,
      );
      if (!isCurrent()) return;

      const maxPage = Math.max(1, Math.min(data.total_pages ?? 1, MAX_PAGE));
      const payload = {
        results: Array.isArray(data.results) ? data.results : [],
        total: data.total ?? 0,
        totalPages: maxPage,
      };
      setQuota(nextQuota);
      applyPage(payload, targetPage, append, false);
      await cachePut(pageKey, payload);
    } catch (err) {
      if (!isCurrent() || err.name === 'AbortError') return;
      if (append) setHasMore(false);
      else { setItems([]); setPhase('error'); }
      setMessage(describeError(err));
    } finally {
      if (isCurrent()) {
        busyRef.current = false;
        setLoadingMore(false);
      }
    }
  }, [key, query, orientation, applyPage]);

  const loadMore = useCallback(() => {
    if (!hasMore || busyRef.current) return;
    void loadPage(pageRef.current + 1, true);
  }, [hasMore, loadPage]);

  // 点「取片」= 强制刷新：清掉当前筛选下的缓存页并重新联网取第一页。
  const search = useCallback(async (nextQuery, force = false) => {
    const next = (nextQuery || '').trim() || 'wallpaper';
    if (force) await cacheDeletePrefix(cachePrefix({ query: next, orientation }));

    generationRef.current += 1;
    busyRef.current = false;
    countRef.current = 0;
    pageRef.current = 0;
    setLoadingMore(false);

    if (next === query) {
      await loadPage(1, false, force);
    } else {
      setQuery(next); // query 变化触发 effect 重新加载；force 时缓存已清空，会走网络
    }
  }, [query, orientation, loadPage]);

  // query / orientation / key 变化即清空并从第一页重新开始（优先读缓存）。
  useEffect(() => {
    generationRef.current += 1;
    busyRef.current = false;
    countRef.current = 0;
    pageRef.current = 0;
    setLoadingMore(false);

    if (!key) {
      setItems([]);
      setTotal(0);
      setHasMore(false);
      setPhase('idle');
      setMessage(t('status.noKey'));
      return undefined;
    }

    void loadPage(1, false);
    return undefined;
  }, [key, query, orientation, loadPage]);

  const reset = useCallback(() => {
    generationRef.current += 1;
    busyRef.current = false;
    countRef.current = 0;
    pageRef.current = 0;
    setItems([]);
    setTotal(0);
    setQuota(null);
    setHasMore(false);
    setLoadingMore(false);
    setPhase('idle');
    setMessage('');
  }, []);

  return {
    query, setQuery, orientation, setOrientation, size, setSize,
    items, total, phase, message, quota,
    hasMore, loadingMore, loadMore, search, reset,
  };
}
