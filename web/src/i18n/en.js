// 英文文案。key 与 zh-Hans / zh-Hant 保持一一对应。
export default {
  // 分类（ControlBar / DiscoverView 共用）
  'topic.wallpaper': 'Featured',
  'topic.minimal': 'Minimal',
  'topic.autumn': 'Autumn',
  'topic.nature': 'Nature',
  'topic.3d render': '3D',
  'topic.experimental': 'Experimental',
  'topic.film photography': 'Film',
  'topic.street photography': 'Street',
  'topic.architecture': 'Architecture',
  'topic.textures': 'Textures',
  'topic.travel': 'Travel',
  'topic.portrait': 'People',

  // 方向与下载尺寸
  'orientation.landscape': 'Landscape',
  'orientation.portrait': 'Portrait',
  'orientation.squarish': 'Square',
  'orientation.any': 'All',
  'size.thumb': 'Thumbnail',
  'size.full': 'Standard',
  'size.2560': '2.5K',
  'size.3840': '4K',
  'size.raw': 'Original',

  // 控制条
  'control.categories': 'Categories',
  'control.search': 'Search',
  'control.searchAria': 'Search wallpaper keywords',
  'control.orientationAria': 'Orientation filter',
  'control.sizeAria': 'Download size',
  'control.keyAria': 'Access Key settings',
  'control.settings': 'Settings',

  // Access Key 设置面板
  'setup.close': 'Close',
  'setup.body1': 'Create an app for free at ',
  'setup.body2':
    ' and copy the Access Key (not the Secret Key). Demo apps allow 50 requests per hour. Unsplash requires both keys to stay secret; for public deployments use a server-side proxy — pasting it here is fine for personal use.',
  'setup.configuredPlaceholder': 'Configured · paste a new key to replace',
  'setup.pastePlaceholder': 'Paste Access Key',
  'setup.save': 'Save',
  'setup.clear': 'Clear',
  'setup.note':
    'The key is stored only in this browser’s localStorage and sent only to api.unsplash.com. No key is built in, and there is no silent fallback.',
  'setup.emptyKeyError': 'Access Key cannot be empty; this page never falls back to a default key.',

  // 空状态
  'empty.error.title': 'Something went wrong',
  'empty.idle.title': 'The room is dark',
  'empty.none.title': 'No frames found',
  'empty.error.text': 'Check the error code above, verify your Access Key and quota, then try again.',
  'empty.idle.text': 'Paste your Unsplash Access Key and let the light in. No built-in keys, no fallback.',
  'empty.none.text': 'Try another keyword or orientation, then fetch again.',
  'empty.setupKey': 'Set Access Key',
  'grid.loadingAria': 'Loading',

  // 卡片
  'card.unsplashPhotographer': 'Unsplash photographer',
  'card.downloadBy': "Download {author}'s wallpaper",
  'card.downloadByLoading': "Download {author}'s wallpaper (image loading)",
  'card.unsplashWallpaper': 'Unsplash wallpaper',

  // 下载与提示
  'app.iosPrepare':
    'Preparing… To save to Photos: pick “Save Image” in the share sheet, or long-press the image and choose “Save to Photos”.',
  'app.fetchingLabel': 'Fetching',
  'app.shared': 'Share sheet opened · {filename} · {mb} MB · pick “Save Image” in the sheet to save to Photos',
  'app.savedToFiles': 'Saved to Files · {filename} · {mb} MB · to save to Photos, long-press the image and choose “Save to Photos”',
  'app.saved': 'Saved {filename} · {mb} MB',
  'app.downloadFailed': 'Download failed: {message}',
  'app.imageHttp': 'Image request HTTP {status}',

  // 加载更多
  'loadMore.loading': 'Loading more…',
  'loadMore.hint': 'Scroll down to load more',
  'loadMore.end': 'You’ve reached the end',

  // 列表状态
  'status.fetching': 'Fetching…',
  'status.noKey': 'No Access Key configured: add one to start fetching.',
  'status.online': 'Online',
  'status.cache': 'Cached',
  'status.summary': '{source} · {total} photos · {loaded} loaded',

  // 接口错误
  'error.invalidKey':
    'The Access Key is invalid or not active yet. Make sure it is the Access Key (not the Secret Key), and check your app status on Unsplash Developers.',
  'error.quota': 'Request quota exhausted (50 per hour for demo apps). Wait for the reset or request a higher limit.',
  'error.http': 'Request failed (HTTP {code}): {detail}',
  'error.network': 'Network request failed: {message}. Check your network and CORS settings.',
};
