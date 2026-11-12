import Foundation
import SwiftUI

// MARK: - 语言选择

/// 用户可选语言：system 跟随系统首选语言，其余固定。
/// 原生端在「设置 → 语言」里选择，存 UserDefaults（key 见 LanguageStore.storageKey）。
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case en
    case zhHans = "zh-Hans"
    case zhHant = "zh-Hant"
    var id: String { rawValue }

    /// 选择器里显示的名称（自身文案跟随当前语言；语言名固定原文）。
    var title: String {
        switch self {
        case .system: L10n.t("settings.language.system")
        case .en: "English"
        case .zhHans: "简体中文"
        case .zhHant: "繁體中文"
        }
    }

    /// 解析成实际用于查表的语言；system 跟随系统首选语言。
    var resolved: ResolvedLanguage {
        switch self {
        case .system: ResolvedLanguage.system
        case .en: .en
        case .zhHans: .zhHans
        case .zhHant: .zhHant
        }
    }
}

enum ResolvedLanguage: String {
    case en, zhHans, zhHant

    /// 跟随系统：按 preferredLanguages 顺序找第一个支持的语言；zh 系按地区分简繁。
    static var system: ResolvedLanguage {
        for lang in Locale.preferredLanguages {
            let l = lang.lowercased()
            if l.hasPrefix("zh") {
                if l.contains("hant") || l.contains("-tw") || l.contains("-hk") || l.contains("-mo") { return .zhHant }
                return .zhHans
            }
            if l.hasPrefix("en") { return .en }
        }
        return .en
    }
}

/// 语言偏好的存取。UserDefaults 线程安全，视图用 @AppStorage(storageKey) 监听变化。
enum LanguageStore {
    static let storageKey = "appLanguage"

    static var selection: AppLanguage {
        get { UserDefaults.standard.string(forKey: storageKey).flatMap(AppLanguage.init(rawValue:)) ?? .system }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: storageKey) }
    }

    static var resolved: ResolvedLanguage { selection.resolved }
}

/// 全局取文案的便捷函数：`L("tab.discover")`。
func L(_ key: String) -> String {
    L10n.t(key, in: LanguageStore.resolved)
}

/// 带占位符的文案：模板里用 {name}，如 L10n.f("viewer.savedAlbum", ["album": name])。
func L(_ key: String, _ params: [String: String]) -> String {
    var text = L(key)
    for (name, value) in params { text = text.replacingOccurrences(of: "{\(name)}", with: value) }
    return text
}

/// 渲染含 Markdown（如 `[文本](链接)`）的文案：解析成可点击链接；失败时回退纯文本。
func Lmd(_ key: String) -> Text {
    if let attr = try? AttributedString(markdown: L(key), options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
        return Text(attr)
    }
    return Text(L(key))
}

// MARK: - 文案表

enum L10n {
    /// 查表：先按指定语言（缺省用当前语言设置），缺 key 时回退英文，再回退 key 本身。
    static func t(_ key: String, in lang: ResolvedLanguage? = nil) -> String {
        let target = lang ?? LanguageStore.resolved
        return tables[target]?[key] ?? tables[.en]?[key] ?? key
    }

    static let tables: [ResolvedLanguage: [String: String]] = [
        .en: enTable,
        .zhHans: zhHansTable,
        .zhHant: zhHantTable,
    ]

    static let enTable: [String: String] = [
        // 通用
        "common.ok": "OK",
        "common.close": "Close",
        "common.delete": "Delete",
        "common.retry": "Retry",

        // 标签页 / 侧边栏
        "tab.discover": "Discover",
        "tab.favorites": "Favorites",
        "tab.settings": "Settings",

        // 分类（与 Web 共用同一套 query → 文案）
        "topic.wallpaper": "Featured",
        "topic.minimal": "Minimal",
        "topic.autumn": "Autumn",
        "topic.nature": "Nature",
        "topic.3d render": "3D",
        "topic.experimental": "Experimental",
        "topic.film photography": "Film",
        "topic.street photography": "Street",
        "topic.architecture": "Architecture",
        "topic.textures": "Textures",
        "topic.travel": "Travel",
        "topic.portrait": "People",

        // 方向 / 清晰度
        "orientation.any": "All",
        "orientation.landscape": "Landscape",
        "orientation.portrait": "Portrait",
        "orientation.squarish": "Square",
        "size.standard": "Standard",
        "size.raw": "Original",

        // 发现页
        "discover.search": "Search",
        "discover.categories": "Categories",
        "discover.history": "History",
        "discover.filter": "Filter",
        "discover.refresh": "Refresh",
        "discover.shuffle": "Shuffle",
        "discover.shuffleHint": "Shuffle (random pages)",
        "discover.noKey.title": "No Access Key yet",
        "discover.noKey.body": "Add your Unsplash Access Key in Settings to start browsing.",
        "discover.openSettings": "Open Settings",
        "discover.loading": "Fetching…",
        "discover.loadFailed": "Failed to load",

        // 收藏
        "favorites.empty.title": "No favorites yet",
        "favorites.empty.body": "Tap the star at the top right of an image to favorite it.",
        "favorites.empty.body.hover": "Hover an image and click the star at its top right to favorite it.",
        "favorites.count": "{n} photos",
        "favorites.add": "Favorite",
        "favorites.remove": "Unfavorite",

        // 卡片 / 预览
        "card.wallpaperBy": "{name}’s wallpaper",
        "card.preview": "Preview",
        "card.openInUnsplash": "Open in Unsplash",
        "viewer.closePreview": "Close preview",
        "viewer.quality": "Quality",
        "viewer.saveToAlbum": "Save to Photos",
        "viewer.download": "Download",
        "viewer.savedAlbum": "Saved to the “{album}” album",
        "viewer.saveFailed": "Save failed: {error}",
        "viewer.downloadFailed": "Download failed",
        "viewer.noAlbumPermission": "No permission to write to Photos. Allow it in Settings.",

        // 设置（栏目）
        "settings.title": "Settings",
        "settings.pickSection": "Pick a section",
        "settings.section.key": "Unsplash Key",
        "settings.section.history": "Search History",
        "settings.section.download": "Download",
        "settings.section.widget": "Widget",
        "settings.section.cache": "Cache",
        "settings.section.about": "About",

        // 设置（语言）
        "settings.language": "Language",
        "settings.language.system": "Follow System",
        "settings.language.footer": "Changes apply immediately across the app.",

        // 设置（密钥）
        "key.placeholder.empty": "Paste Access Key",
        "key.placeholder.configured": "Configured · paste a new key to replace",
        "key.saveAndVerify": "Save & Verify",
        "key.footer": "Create an app for free at [Unsplash Developers](https://unsplash.com/developers), then copy the Access Key (not the Secret Key). Demo apps allow 50 requests per hour. The key stays on this device and is sent only to api.unsplash.com. Saving verifies it with the lightest API call first, then returns to the home screen.",
        "key.configured": "Configured",
        "key.clear": "Clear Key",
        "key.clearShort": "Clear",
        "key.verifyFailed": "Verification failed",
        "key.notSaved": "Key not saved.",

        // 设置（搜索历史）
        "history.empty.title": "No search history",
        "history.empty.body.tab": "Keywords you searched appear in the home screen category menu for quick reuse.",
        "history.empty.body.sidebar": "Keywords you searched appear under “History” in the main window sidebar for quick reuse.",
        "history.editHint": "Use “Edit” at the top right to drag and reorder; swipe left to delete. Items higher up appear first in the category menu.",
        "history.dragHint": "Drag to reorder; items higher up appear earlier in the sidebar.",
        "history.clearAll": "Clear All",
        "history.clearAllAll": "Clear All History",
        "history.remove": "Remove from History",
        "history.delete": "Delete",
        "history.deleteItem": "Delete {item}",

        // 设置（下载）
        "download.quality": "Quality",
        "download.default": "Default Quality",
        "download.footer.photos": "You can switch anytime in the preview. Images are saved to the system Photos library; allow access on first save.",
        "download.footer.downloads": "You can switch anytime in the preview. Images are saved to the Downloads folder and revealed in Finder.",

        // 设置（小组件）
        "widget.interval": "Interval",
        "widget.carouselInterval": "Carousel Interval",
        "widget.intervalFooter": "The widget cross-fades through its photos; multiple widgets shuffle independently and are not synchronized. The system throttles widget refreshes, so actual switches may drift a bit.",
        "widget.dataChannel": "Data Channel",
        "widget.statusOk": "OK",
        "widget.statusUnavailable": "Unavailable",
        "widget.thumbs": "Widget Thumbnails",
        "widget.thumbsValue": "{shown} / {total} photos",
        "widget.status": "Status",
        "widget.statusFooterOk": "Each favorite or fetched photo keeps a small thumbnail for the widget.",
        "widget.statusFooterBad": "App Group unavailable: enable the same App Group (group.com.jrainlau.duopaper) for both the Duopaper and DuopaperWidgetExtension targets in Xcode’s Signing & Capabilities.",
        "widget.intervalMinutes": "{n} min",
        "widget.intervalHours": "{n} hr",
        "widget.source": "Source",
        "widget.source.favorites": "Favorites",
        "widget.source.keyword": "Keyword",
        "widget.source.placeholder": "Keyword, e.g. cat",
        "widget.source.refresh": "Fetch a Different Batch",
        "widget.source.footer": "Press Return to fetch up to {n} photos once and cache them. Refresh swaps in a new batch.",
        "widget.gallery": "Cache Gallery",
        "widget.gallery.count": "{n} photos",
        "widget.gallery.empty.title": "No Cached Photos",
        "widget.gallery.empty.body": "Photos fetched by keyword appear here.",
        "gallery.delete": "Delete from Cache",
        "widget.source.noResults": "No photos found for “{keyword}”.",
        "widget.source.failed": "Couldn’t Load Photos",
        "widget.source.fetching": "Fetching photos",
        "widget.tap": "When Tapped",
        "widget.tap.shuffle": "Show Another Photo",
        "widget.tap.open": "Open in App",
        "widget.tap.footer": "“Show Another Photo” shuffles in place without opening the app. “Open in App” launches Duopaper and shows the current photo in the viewer.",

        // 设置（缓存）
        "cache.usage": "Image Cache",
        "cache.clear": "Clear Image & API Cache",
        "cache.cleared": "Cleared.",
        "cache.footer.cleared": "Cleared.",
        "cache.footer.ios": "Clears browsed images, in-app thumbnails and API caches (API results are cached for 6 hours to save the 50-requests-per-hour quota).\n\nThumbnails reserved for the widget are stored separately and are not part of the cache; the widget keeps working, and images in Favorites reload from the network.",
        "cache.footer.mac": "API results are cached for 6 hours to save the 50-requests-per-hour quota; the image cache speeds up browsing.",

        // 设置（关于）
        "about.version": "Version",
        "about.apiGuidelines": "Unsplash API Guidelines",
        "about.footer": "Photos provided by Unsplash and its photographers. Every photo credits the photographer and links to their Unsplash profile; each save reports one download to Unsplash per the API guidelines.",

        // 错误
        "error.noKey": "No Access Key configured. Add one in Settings.",
        "error.invalidKey": "The Access Key is invalid or not active yet. Make sure it is the Access Key (not the Secret Key).",
        "error.quota": "Request quota exhausted (50 per hour for demo apps). Wait for the reset or request a higher limit.",
        "quota.hourlyExhausted": "Hourly limit reached — try again after the top of the hour",
        "error.http": "Request failed (HTTP {code}){detail}",

        // 小组件（跟随系统语言）
        "widget.emptyPrompt": "Favorite some photos and they’ll rotate here",
        "widget.configName": "Favorites Carousel",
        "widget.configDesc": "Rotate through your favorite photos; tap to show another one.",
    ]

    static let zhHansTable: [String: String] = [
        // 通用
        "common.ok": "好",
        "common.close": "关闭",
        "common.delete": "删除",
        "common.retry": "重试",

        // 标签页 / 侧边栏
        "tab.discover": "发现",
        "tab.favorites": "收藏",
        "tab.settings": "设置",

        // 分类
        "topic.wallpaper": "精选",
        "topic.minimal": "极简",
        "topic.autumn": "秋日",
        "topic.nature": "自然",
        "topic.3d render": "3D",
        "topic.experimental": "实验",
        "topic.film photography": "胶片",
        "topic.street photography": "街拍",
        "topic.architecture": "建筑",
        "topic.textures": "纹理",
        "topic.travel": "旅行",
        "topic.portrait": "人物",

        // 方向 / 清晰度
        "orientation.any": "全部",
        "orientation.landscape": "横屏",
        "orientation.portrait": "竖屏",
        "orientation.squarish": "方图",
        "size.standard": "标准",
        "size.raw": "原始",

        // 发现页
        "discover.search": "搜索",
        "discover.categories": "分类",
        "discover.history": "历史搜索",
        "discover.filter": "筛选",
        "discover.refresh": "刷新",
        "discover.shuffle": "换一批",
        "discover.shuffleHint": "换一批（随机取片）",
        "discover.noKey.title": "尚未配置 Access Key",
        "discover.noKey.body": "到「设置」里填入你的 Unsplash Access Key 后即可开始取片。",
        "discover.openSettings": "打开设置",
        "discover.loading": "正在取片…",
        "discover.loadFailed": "无法加载",

        // 收藏
        "favorites.empty.title": "还没有收藏",
        "favorites.empty.body": "点图片右上角的星即可收藏。",
        "favorites.empty.body.hover": "把鼠标移到图片上，点右上角的星即可收藏。",
        "favorites.count": "{n} 张",
        "favorites.add": "收藏",
        "favorites.remove": "取消收藏",

        // 卡片 / 预览
        "card.wallpaperBy": "{name} 的壁纸",
        "card.preview": "预览",
        "card.openInUnsplash": "在 Unsplash 中打开",
        "viewer.closePreview": "关闭预览",
        "viewer.quality": "清晰度",
        "viewer.saveToAlbum": "保存到相册",
        "viewer.download": "下载",
        "viewer.savedAlbum": "已保存到相册「{album}」",
        "viewer.saveFailed": "保存失败：{error}",
        "viewer.downloadFailed": "下载失败",
        "viewer.noAlbumPermission": "没有相册写入权限，请在系统设置中允许。",

        // 设置（栏目）
        "settings.title": "设置",
        "settings.pickSection": "选择一个栏目",
        "settings.section.key": "Unsplash 密钥",
        "settings.section.history": "搜索历史",
        "settings.section.download": "下载",
        "settings.section.widget": "小组件",
        "settings.section.cache": "缓存",
        "settings.section.about": "关于",

        // 设置（语言）
        "settings.language": "语言",
        "settings.language.system": "跟随系统",
        "settings.language.footer": "更改后整个 App 立即生效。",

        // 设置（密钥）
        "key.placeholder.empty": "粘贴 Access Key",
        "key.placeholder.configured": "已配置 · 输入新 Key 可替换",
        "key.saveAndVerify": "保存并验证",
        "key.footer": "到 [Unsplash Developers](https://unsplash.com/developers) 免费创建应用，复制 Access Key（不是 Secret Key）。Demo 应用限额 50 次 / 小时。密钥只保存在本机，只发送给 api.unsplash.com。保存时会先用一个最轻的接口验证，通过后才会保存并回到首页。",
        "key.configured": "已配置",
        "key.clear": "清除密钥",
        "key.clearShort": "清除",
        "key.verifyFailed": "验证失败",
        "key.notSaved": "密钥未保存。",

        // 设置（搜索历史）
        "history.empty.title": "暂无搜索历史",
        "history.empty.body.tab": "搜索过的关键词会出现在首页的分类菜单里，方便下次直接使用。",
        "history.empty.body.sidebar": "搜索过的关键词会出现在主窗口侧边栏的「历史搜索」里，方便下次直接使用。",
        "history.editHint": "点右上角「编辑」可以拖动排序；左滑可以删除。排在前面的会先出现在分类菜单里。",
        "history.dragHint": "拖动调整顺序，排在前面的在侧边栏里也靠前。",
        "history.clearAll": "清空全部",
        "history.clearAllAll": "清空全部历史",
        "history.remove": "从历史中删除",
        "history.delete": "删除",
        "history.deleteItem": "删除 {item}",

        // 设置（下载）
        "download.quality": "清晰度",
        "download.default": "默认清晰度",
        "download.footer.photos": "预览里也可以随时切换。图片会保存到系统相册，首次保存需要允许写入相册。",
        "download.footer.downloads": "预览里也可以随时切换。图片保存到「下载」文件夹，并在 Finder 中选中。",

        // 设置（小组件）
        "widget.interval": "切换间隔",
        "widget.carouselInterval": "轮播切换间隔",
        "widget.intervalFooter": "小组件会渐隐渐显地轮播图片；桌面上有多个小组件时，各自随机、互不同步。系统对小组件刷新有节流，实际切换时间可能略有偏差。",
        "widget.dataChannel": "数据通道",
        "widget.statusOk": "正常",
        "widget.statusUnavailable": "不可用",
        "widget.thumbs": "小组件缩略图",
        "widget.thumbsValue": "{shown} / {total} 张",
        "widget.status": "状态",
        "widget.statusFooterOk": "收藏或拉取的图片会各存一份缩略图给小组件使用。",
        "widget.statusFooterBad": "App Group 不可用：请在 Xcode 的 Signing & Capabilities 里为 Duopaper 和 DuopaperWidgetExtension 两个 target 开启同一个 App Group（group.com.jrainlau.duopaper）。",
        "widget.intervalMinutes": "{n} 分钟",
        "widget.intervalHours": "{n} 小时",
        "widget.source": "来源",
        "widget.source.favorites": "收藏",
        "widget.source.keyword": "关键词",
        "widget.source.placeholder": "输入关键词，例如 cat",
        "widget.source.refresh": "换一批图片",
        "widget.source.footer": "回车拉取一次（最多 {n} 张）并缓存；刷新会换一批。",
        "widget.gallery": "缓存画廊",
        "widget.gallery.count": "{n} 张",
        "widget.gallery.empty.title": "没有缓存的图片",
        "widget.gallery.empty.body": "按关键词拉取的图片会出现在这里。",
        "gallery.delete": "从缓存删除",
        "widget.source.noResults": "没有找到「{keyword}」相关的图片。",
        "widget.source.failed": "拉取失败",
        "widget.source.fetching": "正在拉取图片",
        "widget.tap": "点击小组件",
        "widget.tap.shuffle": "换一张",
        "widget.tap.open": "打开 App 并预览",
        "widget.tap.footer": "「换一张」直接在桌面上换图，不打开 App；「打开 App 并预览」会进入 Duopaper，并用预览弹出当前这张图。",

        // 设置（缓存）
        "cache.usage": "图片缓存占用",
        "cache.clear": "清除图片与接口缓存",
        "cache.cleared": "已清除。",
        "cache.footer.cleared": "已清除。",
        "cache.footer.ios": "会清除浏览过的图片、App 里的缩略图和接口缓存（接口结果缓存 6 小时，节省每小时 50 次的额度）。\n\n你收藏的图片的小组件专用缩略图单独保存，不属于缓存，清除后小组件仍能正常显示；收藏页里的图片会重新联网加载。",
        "cache.footer.mac": "接口结果会缓存 6 小时以节省每小时 50 次的额度，图片缓存用于加快浏览。",

        // 设置（关于）
        "about.version": "版本",
        "about.apiGuidelines": "Unsplash API 使用规范",
        "about.footer": "Photos provided by Unsplash 及其摄影师。每张图片都标注了摄影师并链接到其 Unsplash 主页；每次保存图片都会按 API 规范向 Unsplash 上报一次下载。",

        // 错误
        "error.noKey": "尚未配置 Access Key。请在「设置」中填入。",
        "error.invalidKey": "Access Key 无效或尚未生效。请确认填的是 Access Key（不是 Secret Key）。",
        "error.quota": "请求配额已用尽（Demo 应用 50 次 / 小时），请等待重置或申请提高限额。",
        "quota.hourlyExhausted": "本小时内请求次数已达上限，整点后自动重置",
        "error.http": "请求失败（HTTP {code}）{detail}",

        // 小组件（跟随系统语言）
        "widget.emptyPrompt": "收藏几张图片，这里会轮播",
        "widget.configName": "收藏轮播",
        "widget.configDesc": "轮播你收藏的图片，点一下随机换一张。",
    ]

    static let zhHantTable: [String: String] = [
        // 通用
        "common.ok": "好",
        "common.close": "關閉",
        "common.delete": "刪除",
        "common.retry": "重試",

        // 標籤頁 / 側邊欄
        "tab.discover": "探索",
        "tab.favorites": "收藏",
        "tab.settings": "設定",

        // 分類
        "topic.wallpaper": "精選",
        "topic.minimal": "極簡",
        "topic.autumn": "秋日",
        "topic.nature": "自然",
        "topic.3d render": "3D",
        "topic.experimental": "實驗",
        "topic.film photography": "底片",
        "topic.street photography": "街拍",
        "topic.architecture": "建築",
        "topic.textures": "紋理",
        "topic.travel": "旅行",
        "topic.portrait": "人物",

        // 方向 / 畫質
        "orientation.any": "全部",
        "orientation.landscape": "橫向",
        "orientation.portrait": "直向",
        "orientation.squarish": "方形",
        "size.standard": "標準",
        "size.raw": "原始",

        // 探索頁
        "discover.search": "搜尋",
        "discover.categories": "分類",
        "discover.history": "搜尋紀錄",
        "discover.filter": "篩選",
        "discover.refresh": "重新整理",
        "discover.shuffle": "換一批",
        "discover.shuffleHint": "換一批（隨機取圖）",
        "discover.noKey.title": "尚未設定 Access Key",
        "discover.noKey.body": "到「設定」裡填入你的 Unsplash Access Key 後即可開始取圖。",
        "discover.openSettings": "打開設定",
        "discover.loading": "正在取圖…",
        "discover.loadFailed": "無法載入",

        // 收藏
        "favorites.empty.title": "還沒有收藏",
        "favorites.empty.body": "點圖片右上角的星星即可收藏。",
        "favorites.empty.body.hover": "把滑鼠移到圖片上，點右上角的星星即可收藏。",
        "favorites.count": "{n} 張",
        "favorites.add": "收藏",
        "favorites.remove": "取消收藏",

        // 卡片 / 預覽
        "card.wallpaperBy": "{name} 的桌布",
        "card.preview": "預覽",
        "card.openInUnsplash": "在 Unsplash 中打開",
        "viewer.closePreview": "關閉預覽",
        "viewer.quality": "畫質",
        "viewer.saveToAlbum": "儲存到相簿",
        "viewer.download": "下載",
        "viewer.savedAlbum": "已儲存到相簿「{album}」",
        "viewer.saveFailed": "儲存失敗：{error}",
        "viewer.downloadFailed": "下載失敗",
        "viewer.noAlbumPermission": "沒有相簿寫入權限，請在系統設定中允許。",

        // 設定（欄目）
        "settings.title": "設定",
        "settings.pickSection": "選擇一個欄目",
        "settings.section.key": "Unsplash 金鑰",
        "settings.section.history": "搜尋紀錄",
        "settings.section.download": "下載",
        "settings.section.widget": "小工具",
        "settings.section.cache": "快取",
        "settings.section.about": "關於",

        // 設定（語言）
        "settings.language": "語言",
        "settings.language.system": "跟隨系統",
        "settings.language.footer": "變更後整個 App 立即生效。",

        // 設定（金鑰）
        "key.placeholder.empty": "貼上 Access Key",
        "key.placeholder.configured": "已設定 · 輸入新 Key 可替換",
        "key.saveAndVerify": "儲存並驗證",
        "key.footer": "到 [Unsplash Developers](https://unsplash.com/developers) 免費建立應用程式，複製 Access Key（不是 Secret Key）。Demo 應用程式上限 50 次 / 小時。金鑰只保存在本機，只傳送給 api.unsplash.com。儲存時會先用一個最輕的介面驗證，通過後才會儲存並回到首頁。",
        "key.configured": "已設定",
        "key.clear": "清除金鑰",
        "key.clearShort": "清除",
        "key.verifyFailed": "驗證失敗",
        "key.notSaved": "金鑰未儲存。",

        // 設定（搜尋紀錄）
        "history.empty.title": "沒有搜尋紀錄",
        "history.empty.body.tab": "搜尋過的關鍵字會出現在首頁的分類選單裡，方便下次直接使用。",
        "history.empty.body.sidebar": "搜尋過的關鍵字會出現在全主視窗側邊欄的「搜尋紀錄」裡，方便下次直接使用。",
        "history.editHint": "點右上角「編輯」可以拖曳排序；左滑可以刪除。排在前面會先出現在分類選單裡。",
        "history.dragHint": "拖曳調整順序，排在前面的在側邊欄裡也靠前。",
        "history.clearAll": "全部清除",
        "history.clearAllAll": "清除所有紀錄",
        "history.remove": "從紀錄中刪除",
        "history.delete": "刪除",
        "history.deleteItem": "刪除 {item}",

        // 設定（下載）
        "download.quality": "畫質",
        "download.default": "預設畫質",
        "download.footer.photos": "預覽裡也可以隨時切換。圖片會儲存到系統相簿，首次儲存需要允許寫入相簿。",
        "download.footer.downloads": "預覽裡也可以隨時切換。圖片儲存到「下載」資料夾，並在 Finder 中選取。",

        // 設定（小工具）
        "widget.interval": "切換間隔",
        "widget.carouselInterval": "輪播切換間隔",
        "widget.intervalFooter": "小工具會漸隱漸顯地輪播圖片；桌面上有多個小工具時，各自隨機、互不同步。系統對小工具重新整理有節流，實際切換時間可能略有偏差。",
        "widget.dataChannel": "資料通道",
        "widget.statusOk": "正常",
        "widget.statusUnavailable": "不可用",
        "widget.thumbs": "小工具縮圖",
        "widget.thumbsValue": "{shown} / {total} 張",
        "widget.status": "狀態",
        "widget.statusFooterOk": "收藏或拉取的圖片會各存一份縮圖給小工具使用。",
        "widget.statusFooterBad": "App Group 不可用：請在 Xcode 的 Signing & Capabilities 裡為 Duopaper 和 DuopaperWidgetExtension 兩個 target 開啟同一個 App Group（group.com.jrainlau.duopaper）。",
        "widget.intervalMinutes": "{n} 分鐘",
        "widget.intervalHours": "{n} 小時",
        "widget.source": "來源",
        "widget.source.favorites": "收藏",
        "widget.source.keyword": "關鍵字",
        "widget.source.placeholder": "輸入關鍵字，例如 cat",
        "widget.source.refresh": "換一批圖片",
        "widget.source.footer": "按下 Return 拉取一次（最多 {n} 張）並快取；重新整理會換一批。",
        "widget.gallery": "快取畫廊",
        "widget.gallery.count": "{n} 張",
        "widget.gallery.empty.title": "沒有快取的圖片",
        "widget.gallery.empty.body": "按關鍵字拉取的圖片會出現在這裡。",
        "gallery.delete": "從快取刪除",
        "widget.source.noResults": "沒有找到「{keyword}」相關的圖片。",
        "widget.source.failed": "拉取失敗",
        "widget.source.fetching": "正在拉取圖片",
        "widget.tap": "點擊小工具",
        "widget.tap.shuffle": "換一張",
        "widget.tap.open": "打開 App 並預覽",
        "widget.tap.footer": "「換一張」直接在桌面上換圖，不打開 App；「打開 App 並預覽」會進入 Duopaper，並用預覽彈出目前這張圖。",

        // 設定（快取）
        "cache.usage": "圖片快取佔用",
        "cache.clear": "清除圖片與介面快取",
        "cache.cleared": "已清除。",
        "cache.footer.cleared": "已清除。",
        "cache.footer.ios": "會清除瀏覽過的圖片、App 裡的縮圖和介面快取（介面結果快取 6 小時，節省每小時 50 次的額度）。\n\n你收藏的圖片的小工具專用縮圖另外保存，不屬於快取，清除後小工具仍能正常顯示；收藏頁裡的圖片會重新上網載入。",
        "cache.footer.mac": "介面結果會快取 6 小時以節省每小時 50 次的額度，圖片快取用於加快瀏覽。",

        // 設定（關於）
        "about.version": "版本",
        "about.apiGuidelines": "Unsplash API 使用規範",
        "about.footer": "Photos provided by Unsplash 及其攝影師。每張圖片都標註了攝影師並連結到其 Unsplash 主頁；每次儲存圖片都會按 API 規範向 Unsplash 上報一次下載。",

        // 錯誤
        "error.noKey": "尚未設定 Access Key。請在「設定」中填入。",
        "error.invalidKey": "Access Key 無效或尚未生效。請確認填的是 Access Key（不是 Secret Key）。",
        "error.quota": "請求額度已用完（Demo 應用程式 50 次 / 小時），請等待重置或申請提高額度。",
        "quota.hourlyExhausted": "本小時內請求次數已達上限，整點後自動重置",
        "error.http": "請求失敗（HTTP {code}）{detail}",

        // 小工具（跟隨系統語言）
        "widget.emptyPrompt": "收藏幾張圖片，這裡會輪播",
        "widget.configName": "收藏輪播",
        "widget.configDesc": "輪播你收藏的圖片，點一下隨機換一張。",
    ]
}
