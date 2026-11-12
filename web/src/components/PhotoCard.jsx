import { memo, useEffect, useRef, useState } from 'react';
import { displayUrlFor, unsplashLink } from '../lib/unsplash.js';
import { t } from '../i18n/index.js';

function PhotoCard({ photo, index, size, onSave, saving }) {
  const author = photo.user?.name || t('card.unsplashPhotographer');
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

  const profile = photo.user?.links?.html || photo.links?.html;

  return (
    <article
      className="card"
      // 让 content-visibility 跳过渲染时也按原图比例占位，不出现固定高度的空白
      style={{ aspectRatio: `${photo.width} / ${photo.height}` }}
    >
      <div
        className="card__hit"
        role="button"
        tabIndex={0}
        aria-label={busy ? t('card.downloadByLoading', { author }) : t('card.downloadBy', { author })}
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
          alt={photo.alt_description || photo.description || t('card.unsplashWallpaper')}
          width={photo.width}
          height={photo.height}
          loading={index < 4 ? 'eager' : 'lazy'}
          decoding="async"
          onLoad={() => setLoaded(true)}
          onError={() => setLoaded(true)}
        />
        {/* 图片字节未到本地、或点击下载任务进行中时显示 */}
        {busy && <span className="card__spinner" aria-hidden="true" />}
      </div>
      {/* Unsplash API 规范：展示图片必须署名，链到摄影师主页和 Unsplash，链接带 UTM。
          桌面端悬停 / 聚焦时出现，触屏常驻。 */}
      <p className="card__credit">
        <a href={unsplashLink(profile)} target="_blank" rel="noopener noreferrer">{author}</a>
        <span aria-hidden="true"> / </span>
        <a href={unsplashLink('https://unsplash.com/')} target="_blank" rel="noopener noreferrer">Unsplash</a>
      </p>
    </article>
  );
}

export default memo(PhotoCard);
