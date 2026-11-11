import { extFromType, imageUrlFor, requestJson, toApiUrl } from './unsplash.js';
import { canShareFiles, isIOS } from './device.js';

function triggerAnchorDownload(blob, filename) {
  const href = URL.createObjectURL(blob);
  const anchor = document.createElement('a');
  anchor.href = href;
  anchor.download = filename;
  document.body.append(anchor);
  anchor.click();
  anchor.remove();
  window.setTimeout(() => URL.revokeObjectURL(href), 60_000);
}

export async function savePhoto({ photo, size, key }) {
  // Unsplash API 规范：用户下载图片前需触发一次 download_location 计数。
  try {
    await requestJson(toApiUrl(photo.links.download_location), key);
  } catch {
    // 计数失败不阻断保存
  }

  const res = await fetch(imageUrlFor(photo, size));
  if (!res.ok) throw new Error(`图片请求 HTTP ${res.status}`);

  const blob = await res.blob();
  // 缩略图档加 -thumb 后缀，避免和同一张图的原图文件重名
  const suffix = size === 'thumb' ? '-thumb' : '';
  const filename = `duopaper-${photo.id}${suffix}.${extFromType(res.headers.get('content-type'))}`;
  const file = new File([blob], filename, { type: blob.type || 'image/jpeg' });

  // iOS 纯 Web 没有写入相册的 API：优先分享面板的「存储图像」（需 jpeg/png）。
  if (isIOS() && canShareFiles(file)) {
    try {
      await navigator.share({ files: [file], title: 'Wallpaper' });
      return { method: 'share', filename, bytes: blob.size };
    } catch (err) {
      if (err && err.name === 'AbortError') return { method: 'cancelled', filename, bytes: blob.size };
    }
  }

  // 分享不可用（例如主屏 PWA）时仍要落盘，点击不能变成「什么都没发生」。
  // iOS 会存到「文件」；想要相册请长按卡片里的高清图选「存储到照片」。
  triggerAnchorDownload(blob, filename);
  return { method: isIOS() ? 'fallback' : 'download', filename, bytes: blob.size };
}
