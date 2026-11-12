import Foundation

/// 小组件「关键词」来源：用关键词拉一次 Unsplash 搜索接口，整批结果（含完整照片信息）缓存在本地。
///
/// - 只在「提交关键词」和「点刷新」时请求接口，其余时间（启动、回到前台、小组件刷新）都只读缓存；
/// - 一次请求一页，最多 `UnsplashClient.perPage` 张；
/// - 刷新会随机换到另一页，成功后整批替换缓存，旧缩略图由 WidgetSync 对账时清掉；
/// - 缓存放在 Application Support，清除图片缓存不会影响它；点小组件进 App 预览时也从这里取完整照片信息。
struct WidgetSourceCache: Codable {
    var keyword: String
    var page: Int
    var totalPages: Int
    var photos: [Photo]
    var fetchedAt: Date
}

enum WidgetSourceError: LocalizedError {
    case noResults(String)

    var errorDescription: String? {
        switch self {
        case let .noResults(keyword): L("widget.source.noResults", ["keyword": keyword])
        }
    }
}

enum WidgetSource {
    /// 一次请求能拿到的最大张数（Unsplash 单页上限由 UnsplashClient.perPage 决定）。
    static var photosPerFetch: Int { UnsplashClient.perPage }
    /// 刷新时随机页的上限，和主页瀑布流保持一致，避免翻到相关度很低的深页。
    private static let randomPageLimit = 20

    private static let file: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Duopaper", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("widget-source.json")
    }()

    static func load() -> WidgetSourceCache? {
        guard let data = try? Data(contentsOf: file) else { return nil }
        return try? JSONDecoder().decode(WidgetSourceCache.self, from: data)
    }

    private static func save(_ cache: WidgetSourceCache) {
        guard let data = try? JSONEncoder().encode(cache) else { return }
        try? data.write(to: file, options: .atomic)
    }

    /// 当前正在使用的关键词缓存；来源不是关键词（或缓存对不上）时为 nil。
    static func active() -> WidgetSourceCache? {
        let keyword = WidgetShared.sourceKeyword
        guard !keyword.isEmpty, let cache = load(), same(cache.keyword, keyword) else { return nil }
        return cache
    }

    /// 点小组件进入 App 时，按 id 找回完整照片信息。
    static func photo(id: String) -> Photo? {
        load()?.photos.first { $0.id == id }
    }

    /// 取这个关键词的一批图。
    /// - fresh = false：本地已有同关键词缓存就直接用，不请求接口；没有才拉第 1 页。
    /// - fresh = true：刷新，换到另一页重新拉，成功后整批替换缓存。
    /// 失败时不改动已有缓存。
    static func pull(keyword: String, key: String, fresh: Bool) async throws -> WidgetSourceCache {
        let q = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        let previous = load().flatMap { same($0.keyword, q) ? $0 : nil }
        if !fresh, let previous, !previous.photos.isEmpty { return previous }
        guard !key.isEmpty else { throw APIError.missingKey }

        var page = 1
        var force = false
        if let previous {
            let upper = max(1, min(previous.totalPages, randomPageLimit))
            let candidates = (1...upper).filter { $0 != previous.page }
            if let pick = candidates.randomElement() {
                page = pick
            } else {
                // 只有一页：没有「另一批」可换，只能绕过 6 小时接口缓存重新拉同一页。
                page = previous.page
                force = true
            }
        }

        let (result, _) = try await UnsplashClient(key: key).search(query: q, orientation: .any, page: page, force: force)
        let photos = result.results.map(\.photo)
        guard !photos.isEmpty else { throw WidgetSourceError.noResults(q) }

        let cache = WidgetSourceCache(keyword: q, page: page, totalPages: result.totalPages, photos: photos, fetchedAt: Date())
        save(cache)
        return cache
    }

    private static func same(_ a: String, _ b: String) -> Bool {
        a.caseInsensitiveCompare(b) == .orderedSame
    }
}
