import { useCallback, useEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import ControlBar from './components/ControlBar.jsx';
import PhotoGrid from './components/PhotoGrid.jsx';
import SetupSheet from './components/SetupSheet.jsx';
import { useAccessKey } from './hooks/useAccessKey.js';
import { useWallpapers } from './hooks/useWallpapers.js';
import { savePhoto } from './lib/download.js';
import { isIOS, isTouchDevice } from './lib/device.js';
import { t } from './i18n/index.js';

export default function App() {
  const { key, setKey, clearKey, configured } = useAccessKey();
  const wall = useWallpapers(key);
  const [setupOpen, setSetupOpen] = useState(() => !configured);
  const [saving, setSaving] = useState({ id: null, label: '' });
  const [notice, setNotice] = useState(null);
  const sentinelRef = useRef(null);

  useEffect(() => {
    // 触屏没有 hover：把状态显式挂到根节点，避免只依赖 CSS 媒体特性。
    document.documentElement.dataset.touch = isTouchDevice() ? 'true' : 'false';
  }, []);

  // 状态栏提示自动归位，不依赖用户必须再做一次操作。
  useEffect(() => {
    if (!notice) return undefined;
    const timer = window.setTimeout(() => setNotice(null), 6000);
    return () => window.clearTimeout(timer);
  }, [notice]);

  // 哨兵进入视口即加载下一页，形成持续的瀑布流（提前 700px 触发）。
  useEffect(() => {
    const node = sentinelRef.current;
    if (!node || !wall.hasMore) return undefined;
    const observer = new IntersectionObserver(
      (entries) => { if (entries[0]?.isIntersecting) wall.loadMore(); },
      { rootMargin: '700px 0px' },
    );
    observer.observe(node);
    return () => observer.disconnect();
  }, [wall.hasMore, wall.loadMore, wall.items.length]);

  const handleSave = useCallback(async (photo) => {
    setNotice(null);
    // iOS 上先把「怎么存进相册」讲清楚，再等图片下载与分享面板。
    if (isIOS()) {
      setNotice({ tone: 'ok', text: t('app.iosPrepare') });
    }
    setSaving({ id: photo.id, label: t('app.fetchingLabel') });
    try {
      const result = await savePhoto({ photo, size: wall.size, key });
      if (result.method !== 'cancelled') {
        const mb = (result.bytes / 1048576).toFixed(1);
        setNotice({
          tone: result.method === 'fallback' ? 'warn' : 'ok',
          text: result.method === 'share'
            ? t('app.shared', { filename: result.filename, mb })
            : result.method === 'fallback'
              ? t('app.savedToFiles', { filename: result.filename, mb })
              : t('app.saved', { filename: result.filename, mb }),
        });
      }
    } catch (err) {
      setNotice({ tone: 'error', text: t('app.downloadFailed', { message: err.message }) });
    } finally {
      setSaving({ id: null, label: '' });
    }
  }, [key, wall.size]);

  function handleClearKey() {
    clearKey();
    setNotice(null);
    setSetupOpen(true);
  }

  return (
    <div className="app">
      <main className="app__main">
        <PhotoGrid
          items={wall.items}
          phase={wall.phase}
          size={wall.size}
          onSave={handleSave}
          savingId={saving.id}
          savingLabel={saving.label}
          onSetup={() => setSetupOpen(true)}
        />

        <div ref={sentinelRef} className="load-more" role="status" aria-live="polite">
          {wall.loadingMore
            ? t('loadMore.loading')
            : wall.hasMore
              ? t('loadMore.hint')
              : wall.items.length ? t('loadMore.end') : ''}
        </div>
      </main>

      {/* 挂到 body：脱离 .app 的布局上下文，fixed 不会被任何祖先的 transform/contain 影响 */}
      {createPortal(
        <ControlBar
          query={wall.query}
          orientation={wall.orientation}
          size={wall.size}
          phase={wall.phase}
          message={wall.message}
          total={wall.total}
          loaded={wall.items.length}
          notice={notice}
          onTopic={(next) => { setNotice(null); void wall.search(next, false); }}
          onSubmit={(next) => { setNotice(null); void wall.search(next, true); }}
          onOrientation={wall.setOrientation}
          onSize={wall.setSize}
          onSetup={() => setSetupOpen(true)}
        />,
        document.body,
      )}

      {setupOpen && (
        <SetupSheet
          configured={configured}
          onSave={setKey}
          onClear={handleClearKey}
          onClose={() => setSetupOpen(false)}
        />
      )}
    </div>
  );
}
