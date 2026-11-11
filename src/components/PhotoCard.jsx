import { memo, useEffect, useRef, useState } from 'react';
import { displayUrlFor } from '../lib/unsplash.js';

function PhotoCard({ photo, index, size, onSave, saving }) {
  const author = photo.user?.name || 'Unsplash 摄影师';
  const src = displayUrlFor(photo, size);
  const [loaded, setLoaded] = useState(false);
  const imgRef = useRef(null);

  // 展示源变化（切换尺寸档）时重新进入「加载中」；缓存命中时 load 事件可能早于
  // 副作用执行，用 complete 兜底。
  useEffect(() => {
    const img = imgRef.current;
    if (img && img.complete && img.naturalWidth > 0) setLoaded(true);
    else setLoaded(false);
  }, [src]);

  const busy = !loaded || Boolean(saving);

  function activate() {
    if (!saving) onSave(photo);
  }

  return (
    <article
      className="card"
      role="button"
      tabIndex={0}
      aria-label={busy ? `下载 ${author} 的壁纸（图片加载中）` : `下载 ${author} 的壁纸`}
      // 让 content-visibility 跳过渲染时也按原图比例占位，不出现固定高度的空白
      style={{ aspectRatio: `${photo.width} / ${photo.height}` }}
      onClick={activate}
      onKeyDown={(event) => {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          activate();
        }
      }}
    >
      {/* img 是顶层元素：iOS 长按可直接出现「存储到照片」 */}
      <img
        ref={imgRef}
        src={src}
        alt={photo.alt_description || photo.description || 'Unsplash 壁纸'}
        width={photo.width}
        height={photo.height}
        loading={index < 4 ? 'eager' : 'lazy'}
        decoding="async"
        onLoad={() => setLoaded(true)}
        onError={() => setLoaded(true)}
      />
      {/* 图片字节未到本地、或点击下载任务进行中时显示 */}
      {busy && <span className="card__spinner" aria-hidden="true" />}
    </article>
  );
}

export default memo(PhotoCard);
