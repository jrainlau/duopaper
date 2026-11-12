// 繁體中文文案。
export default {
  // 分類
  'topic.wallpaper': '精選',
  'topic.minimal': '極簡',
  'topic.autumn': '秋日',
  'topic.nature': '自然',
  'topic.3d render': '3D',
  'topic.experimental': '實驗',
  'topic.film photography': '底片',
  'topic.street photography': '街拍',
  'topic.architecture': '建築',
  'topic.textures': '紋理',
  'topic.travel': '旅行',
  'topic.portrait': '人物',

  // 方向與下載尺寸
  'orientation.landscape': '橫向',
  'orientation.portrait': '直向',
  'orientation.squarish': '方形',
  'orientation.any': '全部',
  'size.thumb': '縮圖',
  'size.full': '標準',
  'size.2560': '2.5K',
  'size.3840': '4K',
  'size.raw': '原始',

  // 控制列
  'control.categories': '分類',
  'control.search': '搜尋',
  'control.searchAria': '搜尋桌布關鍵字',
  'control.orientationAria': '方向篩選',
  'control.sizeAria': '下載尺寸',
  'control.keyAria': 'Access Key 設定',
  'control.settings': '設定',

  // Access Key 設定面板
  'setup.close': '關閉',
  'setup.body1': '到 ',
  'setup.body2':
    ' 免費建立應用程式，複製 Access Key（不是 Secret Key）。Demo 應用程式上限 50 次 / 小時。Unsplash 要求兩把金鑰都須保密，公開部署請改用伺服器端代理保存金鑰；本機自用可直接填在這裡。',
  'setup.configuredPlaceholder': '已設定 · 輸入新 key 可替換',
  'setup.pastePlaceholder': '貼上 Access Key',
  'setup.save': '儲存',
  'setup.clear': '清除',
  'setup.note': '金鑰只存在本機 localStorage，只傳送給 api.unsplash.com；頁面不內建、也不會退回任何預設金鑰。',
  'setup.emptyKeyError': 'Access Key 不能為空，本頁面不會使用預設金鑰。',

  // 空狀態
  'empty.error.title': 'Something went wrong',
  'empty.idle.title': 'The room is dark',
  'empty.none.title': 'No frames found',
  'empty.error.text': '先看上方的錯誤碼，檢查 Access Key 與額度後再試一次。',
  'empty.idle.text': '貼上 Unsplash Access Key，讓光進來。頁面不內建任何金鑰，也不會退回預設值。',
  'empty.none.text': '換個關鍵字或方向，再取一次圖。',
  'empty.setupKey': '設定 Access Key',
  'grid.loadingAria': '載入中',

  // 卡片
  'card.unsplashPhotographer': 'Unsplash 攝影師',
  'card.downloadBy': '下載 {author} 的桌布',
  'card.downloadByLoading': '下載 {author} 的桌布（圖片載入中）',
  'card.unsplashWallpaper': 'Unsplash 桌布',

  // 下載與提示
  'app.iosPrepare': '準備圖片中… 存入相簿：在分享面板選「儲存影像」，或長按圖片選「儲存到照片」',
  'app.fetchingLabel': '取圖中',
  'app.shared': '已開啟分享面板 · {filename} · {mb} MB · 在面板裡選「儲存影像」即可存入相簿',
  'app.savedToFiles': '已儲存到「檔案」 · {filename} · {mb} MB · 要存相簿請長按圖片選「儲存到照片」',
  'app.saved': '已儲存 {filename} · {mb} MB',
  'app.downloadFailed': '下載失敗：{message}',
  'app.imageHttp': '圖片請求 HTTP {status}',

  // 載入更多
  'loadMore.loading': '正在載入更多…',
  'loadMore.hint': '繼續下滑，自動載入',
  'loadMore.end': '已經到底了',

  // 列表狀態
  'status.fetching': '正在取圖…',
  'status.noKey': '未設定 Access Key：填入後即可開始取圖。',
  'status.online': '線上',
  'status.cache': '快取',
  'status.summary': '{source} · 共 {total} 張 · 已載入 {loaded} 張',

  // 錯誤
  'error.invalidKey': 'Access Key 無效或尚未生效。請確認填的是 Access Key（不是 Secret Key），並到 Unsplash Developers 檢查應用程式狀態。',
  'error.quota': '請求額度已用完（Demo 應用程式 50 次 / 小時），請等待重置或申請提高額度。',
  'error.http': '請求失敗（HTTP {code}）：{detail}',
  'error.network': '網路請求失敗：{message}。請檢查網路與跨域設定。',
};
