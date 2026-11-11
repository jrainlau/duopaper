// 图标包来自 wallpaper-h5-icons：24px 网格、2px 线宽、圆角端点。
// 用 CSS mask 渲染：颜色由外层 CSS 的 color 驱动（选中态高亮靠 currentColor），
// 且不需要往 DOM 里塞任何 HTML 字符串。
import search from '../assets/icons/search.svg?url';
import settings from '../assets/icons/settings.svg?url';
import featured from '../assets/icons/featured.svg?url';
import category from '../assets/icons/category.svg?url';
import download from '../assets/icons/download.svg?url';
import favorite from '../assets/icons/favorite.svg?url';
import history from '../assets/icons/history.svg?url';
import share from '../assets/icons/share.svg?url';
import filter from '../assets/icons/filter.svg?url';
import sort from '../assets/icons/sort.svg?url';
import image from '../assets/icons/image.svg?url';
import landscape from '../assets/icons/landscape.svg?url';
import portrait from '../assets/icons/portrait.svg?url';
import square from '../assets/icons/square.svg?url';
import back from '../assets/icons/back.svg?url';
import close from '../assets/icons/close.svg?url';

const ICONS = {
  search, settings, featured, category, download, favorite, history, share,
  filter, sort, image, landscape, portrait, square, back, close,
};

export default function Icon({ name, size = 16, className = '' }) {
  const url = ICONS[name];
  if (!url) return null;
  return (
    <span
      className={`icon ${className}`.trim()}
      style={{ width: size, height: size, '--icon-url': `url("${url}")` }}
      aria-hidden="true"
    />
  );
}
