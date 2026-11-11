import { useEffect, useRef, useState } from 'react';
import Icon from './Icon.jsx';

// 参考横向分类条，内容用本项目的暗色 + 酸橙高亮文字风格重画。
// 每个标签对应一个搜索关键词，点击即切换列表（优先走 IndexedDB 缓存）。
const TOPICS = [
  { label: '精选', query: 'wallpaper', icon: 'featured' },
  { label: '极简', query: 'minimal' },
  { label: '秋日', query: 'autumn' },
  { label: '自然', query: 'nature' },
  { label: '3D', query: '3d render' },
  { label: '实验', query: 'experimental' },
  { label: '胶片', query: 'film photography' },
  { label: '街拍', query: 'street photography' },
  { label: '建筑', query: 'architecture' },
  { label: '纹理', query: 'textures' },
  { label: '旅行', query: 'travel' },
  { label: '人物', query: 'portrait' },
];

const ORIENTATIONS = [
  { value: 'landscape', label: '横屏', icon: 'landscape' },
  { value: 'portrait', label: '竖屏', icon: 'portrait' },
  { value: 'squarish', label: '方图', icon: 'square' },
  { value: '', label: '全部', icon: 'category' },
];

const SIZES = [
  { value: 'thumb', label: '缩略图' },
  { value: 'full', label: '标准' },
  { value: '2560', label: '2.5K' },
  { value: '3840', label: '4K' },
  { value: 'raw', label: '原始' },
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

      <div className="control-bar__topics" role="group" aria-label="分类">
        {TOPICS.map((topic) => (
          <button
            key={topic.query}
            className="chip chip--topic"
            type="button"
            aria-pressed={query.toLowerCase() === topic.query}
            onClick={() => onTopic(topic.query)}
          >
            {topic.icon && <Icon name={topic.icon} size={13} />}
            {topic.label}
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
            placeholder="搜索"
            aria-label="搜索壁纸关键词"
          />
        </form>

        <div className="control-bar__filters" role="group" aria-label="方向筛选">
          {ORIENTATIONS.map((item) => (
            <button
              key={item.value}
              className="chip"
              type="button"
              aria-pressed={orientation === item.value}
              onClick={() => onOrientation(item.value)}
            >
              <Icon name={item.icon} size={14} />
              {item.label}
            </button>
          ))}
          <select className="select" value={size} onChange={(event) => onSize(event.target.value)} aria-label="下载尺寸">
            {SIZES.map((item) => <option key={item.value} value={item.value}>{item.label}</option>)}
          </select>
        </div>

        <button className="control-bar__action" type="button" onClick={onSetup} aria-label="Access Key 设置">
          <Icon name="settings" size={15} />
          设置
        </button>

        <span className={`control-bar__status${phase === 'error' ? ' is-error' : ''}`}>{status}</span>
      </div>
    </div>
  );
}
