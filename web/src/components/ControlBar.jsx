import { useEffect, useRef, useState } from 'react';
import Icon from './Icon.jsx';
import { t } from '../i18n/index.js';

// 参考横向分类条，内容用本项目的暗色 + 酸橙高亮文字风格重画。
// 每个标签对应一个搜索关键词，点击即切换列表（优先走 IndexedDB 缓存）。
const TOPICS = [
  { key: 'topic.wallpaper', query: 'wallpaper', icon: 'featured' },
  { key: 'topic.minimal', query: 'minimal' },
  { key: 'topic.autumn', query: 'autumn' },
  { key: 'topic.nature', query: 'nature' },
  { key: 'topic.3d render', query: '3d render' },
  { key: 'topic.experimental', query: 'experimental' },
  { key: 'topic.film photography', query: 'film photography' },
  { key: 'topic.street photography', query: 'street photography' },
  { key: 'topic.architecture', query: 'architecture' },
  { key: 'topic.textures', query: 'textures' },
  { key: 'topic.travel', query: 'travel' },
  { key: 'topic.portrait', query: 'portrait' },
];

const ORIENTATIONS = [
  { value: 'landscape', key: 'orientation.landscape', icon: 'landscape' },
  { value: 'portrait', key: 'orientation.portrait', icon: 'portrait' },
  { value: 'squarish', key: 'orientation.squarish', icon: 'square' },
  { value: '', key: 'orientation.any', icon: 'category' },
];

const SIZES = [
  { value: 'thumb', key: 'size.thumb' },
  { value: 'full', key: 'size.full' },
  { value: '2560', key: 'size.2560' },
  { value: '3840', key: 'size.3840' },
  { value: 'raw', key: 'size.raw' },
];

export default function ControlBar({
  query, orientation, size, phase, message, total, loaded, notice,
  onTopic, onSubmit, onOrientation, onSize, onSetup,
}) {
  const [draft, setDraft] = useState(query);
  const [compact, setCompact] = useState(false);
  const lastY = useRef(0);

  useEffect(() => { setDraft(query); }, [query]);

  // 向下滚自动瘦身（收起分类行），向上滚立刻恢复；rAF 节流，不用定时器。
  useEffect(() => {
    let ticking = false;
    const onScroll = () => {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(() => {
        const y = window.scrollY;
        const delta = y - lastY.current;
        if (y < 40) setCompact(false);
        else if (delta > 6) setCompact(true);
        else if (delta < -6) setCompact(false);
        lastY.current = y;
        ticking = false;
      });
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  function submit(event) {
    event.preventDefault();
    onSubmit(draft.trim() || 'wallpaper');
  }

  const status = phase === 'error' ? message : `${loaded} / ${total}`;

  return (
    <div className={`control-bar${compact ? ' is-compact' : ''}`}>
      {notice && (
        <div className={`control-bar__toast control-bar__toast--${notice.tone}`} role="status">
          {notice.text}
        </div>
      )}

      <div className="control-bar__topics" role="group" aria-label={t('control.categories')}>
        {TOPICS.map((topic) => (
          <button
            key={topic.query}
            className="chip chip--topic"
            type="button"
            aria-pressed={query.toLowerCase() === topic.query}
            onClick={() => onTopic(topic.query)}
          >
            {topic.icon && <Icon name={topic.icon} size={13} />}
            {t(topic.key)}
          </button>
        ))}
      </div>

      <div className="control-bar__row">
        <form className="control-bar__search" onSubmit={submit} role="search">
          <Icon name="search" size={16} />
          <input
            type="search"
            value={draft}
            onChange={(event) => setDraft(event.target.value)}
            placeholder={t('control.search')}
            aria-label={t('control.searchAria')}
          />
        </form>

        <div className="control-bar__filters" role="group" aria-label={t('control.orientationAria')}>
          {ORIENTATIONS.map((item) => (
            <button
              key={item.value}
              className="chip"
              type="button"
              aria-pressed={orientation === item.value}
              onClick={() => onOrientation(item.value)}
            >
              <Icon name={item.icon} size={14} />
              {t(item.key)}
            </button>
          ))}
          <select className="select" value={size} onChange={(event) => onSize(event.target.value)} aria-label={t('control.sizeAria')}>
            {SIZES.map((item) => <option key={item.value} value={item.value}>{t(item.key)}</option>)}
          </select>
        </div>

        <button className="control-bar__action" type="button" onClick={onSetup} aria-label={t('control.keyAria')}>
          <Icon name="settings" size={15} />
          {t('control.settings')}
        </button>

        <span className={`control-bar__status${phase === 'error' ? ' is-error' : ''}`}>{status}</span>
      </div>
    </div>
  );
}
