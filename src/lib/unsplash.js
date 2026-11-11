import { isIOS } from './device.js';

const PUBLIC_API = 'https://api.unsplash.com';
const PUBLIC_IMG = 'https://images.unsplash.com';

// dev 下走 Vite 同源代理：手机只需连 Mac，绕开跨域预检与手机出网不通。
// 生产构建仍直连官方地址，保持 hotlinking 与 ixid 统计。
const DEV = import.meta.env.DEV;
export const API = DEV ? '/unsplash-api' : PUBLIC_API;

export function toApiUrl(url) {
  return DEV && url.startsWith(PUBLIC_API)
    ? url.replace(PUBLIC_API, '/unsplash-api')
    : url;
}

export function toImageUrl(url) {
  return DEV && url.startsWith(PUBLIC_IMG)
    ? url.replace(PUBLIC_IMG, '/unsplash-img')
    : url;
}

export const PER_PAGE = 12;

export class ApiError extends Error {
  constructor(status, detail) {
    super(detail || `HTTP ${status}`);
    this.name = 'ApiError';
    this.status = status;
    this.detail = detail || '';
  }
}

// 官方公开鉴权只认 `Authorization: Client-ID <access_key>`，裸 Client-ID 头会 401。
// 只带 Authorization 一个自定义头：CORS 预检白名单里包含它。
export async function requestJson(url, key, signal, noStore = false) {
  const res = await fetch(url, {
    signal,
    headers: { Authorization: `Client-ID ${key}` },
    ...(noStore ? { cache: 'no-store' } : {}),
  });

  const quota = {
    remaining: res.headers.get('X-RateLimit-Remaining'),
    limit: res.headers.get('X-RateLimit-Limit'),
  };

  if (!res.ok) {
    let detail = '';
    try {
      const body = await res.json();
      detail = Array.isArray(body.errors) ? body.errors.join('; ') : '';
    } catch {
      // 非 JSON 错误响应，保留空 detail
    }
    throw new ApiError(res.status, detail);
  }

  return { data: await res.json(), quota };
}

export function buildSearchUrl({ query, orientation, page }) {
  const url = new URL(`${API}/search/photos`, window.location.origin);
  url.searchParams.set('query', query.trim() || 'wallpaper');
  if (orientation) url.searchParams.set('orientation', orientation);
  url.searchParams.set('page', String(page));
  url.searchParams.set('per_page', String(PER_PAGE));
  return url.toString();
}

// 「缩略图」档规格：600px / q70 / jpeg，均值约 54KB（实测 6 张样本）。
// 手机 2 列卡片约 182 CSS px × DPR 3 ≈ 546 物理像素，600px 刚好覆盖，看起来清晰；
// 体积只有 2000px 展示图的约 1/10、原图的约 1/100。展示图与点击下载共用这一份规格。
const THUMB_WIDTH = 600;
const THUMB_QUALITY = 70;

function thumbUrlFor(photo) {
  const url = new URL(toImageUrl(photo.urls.regular), window.location.origin);
  url.searchParams.set('w', String(THUMB_WIDTH));
  url.searchParams.set('q', String(THUMB_QUALITY));
  url.searchParams.set('fm', 'jpg'); // iOS 要 jpeg 才会出现「存储图像」
  return url.toString(); // 保留 ixid 等统计参数
}

// iOS 长按「存储到照片」保存的是 <img> 当前加载的那份资源，Web 无法在长按时换源。
// 所以展示源必须跟尺寸选项走：
//  - 缩略图：展示 600px 小图，长按存下来就是这张小图
//  - 其它档：展示 2000px / q85 / jpeg（约 400–800KB），放大不糊；
//    2.5K / 4K / 原始只能靠「点击下载」，长按存的是 2000px 展示图。
export function displayUrlFor(photo, size = 'full') {
  if (size === 'thumb') return thumbUrlFor(photo);
  const url = new URL(toImageUrl(photo.urls.regular), window.location.origin);
  url.searchParams.set('w', '2000');
  url.searchParams.set('q', '85');
  url.searchParams.set('fm', 'jpg');
  return url.toString(); // 保留 ixid 等统计参数
}

// 在 API 返回的 raw URL 上追加 imgix 参数，set() 会保留必须留存的 ixid。
export function imageUrlFor(photo, size) {
  if (size === 'thumb') return thumbUrlFor(photo);
  if (size === 'full') return toImageUrl(photo.urls.full);
  const url = new URL(toImageUrl(photo.urls.raw), window.location.origin);
  if (size !== 'raw') {
    url.searchParams.set('w', size);
    url.searchParams.set('q', '85');
    // iOS 分享面板只对 image/jpeg / image/png 提供「存储图像」（存相册）；
    // webp 会被当成普通文件，只能存到「文件」。
    url.searchParams.set('fm', isIOS() ? 'jpg' : 'webp');
  }
  return url.toString();
}

export function extFromType(contentType) {
  if (!contentType) return 'jpg';
  if (contentType.includes('webp')) return 'webp';
  if (contentType.includes('avif')) return 'avif';
  if (contentType.includes('png')) return 'png';
  return 'jpg';
}

export function describeError(err) {
  if (err instanceof ApiError) {
    if (err.status === 401) return 'Access Key 无效或尚未生效。请确认填的是 Access Key（不是 Secret Key），并到 Unsplash Developers 检查应用状态。';
    if (err.status === 403 || err.status === 429) return '请求配额已用尽（Demo 应用 50 次 / 小时），请等待重置或申请提高限额。';
    return `请求失败（HTTP ${err.status}）：${err.detail || err.message}`;
  }
  return `网络请求失败：${err.message}。请检查网络与跨域设置。`;
}
