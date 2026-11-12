// 简体中文文案（沿用现有界面措辞）。
export default {
  // 分类
  'topic.wallpaper': '精选',
  'topic.minimal': '极简',
  'topic.autumn': '秋日',
  'topic.nature': '自然',
  'topic.3d render': '3D',
  'topic.experimental': '实验',
  'topic.film photography': '胶片',
  'topic.street photography': '街拍',
  'topic.architecture': '建筑',
  'topic.textures': '纹理',
  'topic.travel': '旅行',
  'topic.portrait': '人物',

  // 方向与下载尺寸
  'orientation.landscape': '横屏',
  'orientation.portrait': '竖屏',
  'orientation.squarish': '方图',
  'orientation.any': '全部',
  'size.thumb': '缩略图',
  'size.full': '标准',
  'size.2560': '2.5K',
  'size.3840': '4K',
  'size.raw': '原始',

  // 控制条
  'control.categories': '分类',
  'control.search': '搜索',
  'control.searchAria': '搜索壁纸关键词',
  'control.orientationAria': '方向筛选',
  'control.sizeAria': '下载尺寸',
  'control.keyAria': 'Access Key 设置',
  'control.settings': '设置',

  // Access Key 设置面板
  'setup.close': '关闭',
  'setup.body1': '到 ',
  'setup.body2':
    ' 免费创建应用，复制 Access Key（不是 Secret Key）。Demo 应用限额 50 次 / 小时。Unsplash 要求两个密钥都保密，公开部署请改用服务端代理保存密钥；本机自用可直接填在这里。',
  'setup.configuredPlaceholder': '已配置 · 输入新 key 可替换',
  'setup.pastePlaceholder': '粘贴 Access Key',
  'setup.save': '保存',
  'setup.clear': '清除',
  'setup.note': '密钥只存在本机 localStorage，只发送给 api.unsplash.com；页面不内置也不回退到任何默认密钥。',
  'setup.emptyKeyError': 'Access Key 不能为空，本页面不会使用默认密钥。',

  // 空状态
  'empty.error.title': 'Something went wrong',
  'empty.idle.title': 'The room is dark',
  'empty.none.title': 'No frames found',
  'empty.error.text': '先看上方的错误码，检查 Access Key 与配额后再试一次。',
  'empty.idle.text': '填入 Unsplash Access Key，让光进来。页面不内置任何密钥，也不会回退到默认值。',
  'empty.none.text': '换个关键词或方向，再取一次片。',
  'empty.setupKey': '设置 Access Key',
  'grid.loadingAria': '正在加载',

  // 卡片
  'card.unsplashPhotographer': 'Unsplash 摄影师',
  'card.downloadBy': '下载 {author} 的壁纸',
  'card.downloadByLoading': '下载 {author} 的壁纸（图片加载中）',
  'card.unsplashWallpaper': 'Unsplash 壁纸',

  // 下载与提示
  'app.iosPrepare': '准备图片中… 存入相册：在分享面板选「存储图像」，或长按图片选「存储到照片」',
  'app.fetchingLabel': '取片中',
  'app.shared': '已调起分享 · {filename} · {mb} MB · 面板里选「存储图像」即存入相册',
  'app.savedToFiles': '已保存到「文件」 · {filename} · {mb} MB · 存相册请长按图片选「存储到照片」',
  'app.saved': '已保存 {filename} · {mb} MB',
  'app.downloadFailed': '下载失败：{message}',
  'app.imageHttp': '图片请求 HTTP {status}',

  // 加载更多
  'loadMore.loading': '正在加载更多…',
  'loadMore.hint': '继续下滑，自动加载',
  'loadMore.end': '已经到底了',

  // 列表状态
  'status.fetching': '正在取片…',
  'status.noKey': '未配置 Access Key：填入后即可开始取片。',
  'status.online': '在线',
  'status.cache': '缓存',
  'status.summary': '{source} · 共 {total} 张 · 已加载 {loaded} 张',

  // 接口错误
  'error.invalidKey': 'Access Key 无效或尚未生效。请确认填的是 Access Key（不是 Secret Key），并到 Unsplash Developers 检查应用状态。',
  'error.quota': '请求配额已用尽（Demo 应用 50 次 / 小时），请等待重置或申请提高限额。',
  'error.http': '请求失败（HTTP {code}）：{detail}',
  'error.network': '网络请求失败：{message}。请检查网络与跨域设置。',
};
