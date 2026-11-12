import { useEffect, useState } from 'react';
import { isDualScreen } from '../lib/device.js';

// 列数由 JS 决定，卡片宽度交给 CSS grid 按 1fr 精确平分。
// 手机：纵向 2 列、横向 4 列；更宽的屏幕给更多列。
function columnCount() {
  if (typeof window === 'undefined') return 2;
  if (isDualScreen()) return 3; // 双屏时右屏只有一半宽

  const width = window.innerWidth;
  const landscape = width > window.innerHeight;

  if (width <= 620) return landscape ? 4 : 2;
  if (width <= 1000) return landscape ? 4 : 3;
  return Math.min(6, Math.max(4, Math.floor(width / 230)));
}

export function useColumns() {
  const [count, setCount] = useState(columnCount);

  useEffect(() => {
    const update = () => setCount(columnCount());
    window.addEventListener('resize', update);
    window.addEventListener('orientationchange', update);
    return () => {
      window.removeEventListener('resize', update);
      window.removeEventListener('orientationchange', update);
    };
  }, []);

  return count;
}
