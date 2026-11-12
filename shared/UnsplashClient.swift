import Foundation

enum APIError: LocalizedError {
    case http(Int, String)
    case missingKey

    var errorDescription: String? {
        switch self {
        case .missingKey:
            "尚未配置 Access Key。请在「设置」（⌘,）中填入。"
        case .http(401, _):
            "Access Key 无效或尚未生效。请确认填的是 Access Key（不是 Secret Key）。"
        case .http(403, _), .http(429, _):
            "请求配额已用尽（Demo 应用 50 次 / 小时），请等待重置或申请提高限额。"
        case let .http(code, detail):
            "请求失败（HTTP \(code)）\(detail.isEmpty ? "" : "：\(detail)")"
        }
    }
}

struct UnsplashClient {
    static let perPage = 30
    static let maxPage = 50
    static let cacheTTL: TimeInterval = 6 * 60 * 60

    let key: String

    private func request(_ url: URL) -> URLRequest {
        var r = URLRequest(url: url)
        r.setValue("Client-ID \(key)", forHTTPHeaderField: "Authorization")
        return r
    }

    private func fetch(_ url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request(url))
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let detail = (try? JSONDecoder().decode([String: [String]].self, from: data))?["errors"]?.joined(separator: "; ") ?? ""
            throw APIError.http(http.statusCode, detail)
        }
        return data
    }

    func search(query: String, orientation: Orientation, page: Int, force: Bool) async throws -> (SearchPage, fromCache: Bool) {
        let q = query.trimmingCharacters(in: .whitespaces).isEmpty ? "wallpaper" : query.trimmingCharacters(in: .whitespaces)
        let cacheName = "\(q.lowercased())|\(orientation.rawValue.isEmpty ? "any" : orientation.rawValue)|\(page)"
        if !force, let cached = PageCache.read(cacheName) { return (cached, true) }

        var c = URLComponents(string: "https://api.unsplash.com/search/photos")!
        c.queryItems = [
            .init(name: "query", value: q),
            .init(name: "page", value: String(page)),
            .init(name: "per_page", value: String(Self.perPage)),
        ]
        if orientation != .any { c.queryItems?.append(.init(name: "orientation", value: orientation.rawValue)) }

        var result = try JSONDecoder().decode(SearchPage.self, from: try await fetch(c.url!))
        result.totalPages = max(1, min(result.totalPages, Self.maxPage))
        PageCache.write(cacheName, result)
        return (result, false)
    }

    /// 用最轻的接口（只取 1 张图的列表）校验 Access Key 是否可用，不拉瀑布流。
    func validate() async throws {
        var c = URLComponents(string: "https://api.unsplash.com/photos")!
        c.queryItems = [.init(name: "per_page", value: "1")]
        _ = try await fetch(c.url!)
    }

    /// Unsplash API 规范：用户下载图片前需触发一次 download_location 计数。
    func trackDownload(_ photo: Photo) async {
        _ = try? await fetch(photo.links.downloadLocation)
    }

    /// 瀑布流缩略图：640px / q75，体积小，Retina 下约 320pt 宽的列也足够清晰。
    static func thumbURL(_ photo: Photo) -> URL {
        replacing(photo.urls.regular, ["w": "640", "q": "75", "fm": "jpg"])
    }

    /// 小组件专用缩略图：800px / q70，一张约几十 KB。
    static func widgetThumbURL(_ photo: Photo) -> URL {
        replacing(photo.urls.regular, ["w": "800", "q": "70", "fm": "jpg"])
    }

    /// Viewer 中的预览图。
    static func previewURL(_ photo: Photo) -> URL {
        replacing(photo.urls.regular, ["w": "1600", "q": "85", "fm": "jpg"])
    }

    static func downloadURL(_ photo: Photo, size: DownloadSize) -> URL {
        switch size {
        case .standard: photo.urls.full
        case .raw: photo.urls.raw
        case .w2560: replacing(photo.urls.raw, ["w": "2560", "q": "85", "fm": "jpg"])
        case .w3840: replacing(photo.urls.raw, ["w": "3840", "q": "85", "fm": "jpg"])
        }
    }

    /// 只覆盖指定参数，保留 ixid 等必须留存的统计参数。
    private static func replacing(_ url: URL, _ params: [String: String]) -> URL {
        var c = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        var items = (c.queryItems ?? []).filter { params[$0.name] == nil }
        items += params.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        c.queryItems = items
        return c.url!
    }
}

/// 接口结果本地缓存 6 小时，节省 50 次/小时的配额。
enum PageCache {
    private static let dir: URL = {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let d = base.appendingPathComponent("duopaper/pages", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }()

    private static func file(_ name: String) -> URL {
        let safe = Data(name.utf8).base64EncodedString().replacingOccurrences(of: "/", with: "_")
        return dir.appendingPathComponent(safe + ".json")
    }

    static func clear() {
        try? FileManager.default.removeItem(at: dir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    static func read(_ name: String) -> SearchPage? {
        let f = file(name)
        guard let date = (try? f.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate,
              Date().timeIntervalSince(date) < UnsplashClient.cacheTTL,
              let data = try? Data(contentsOf: f) else { return nil }
        return try? JSONDecoder().decode(SearchPage.self, from: data)
    }

    static func write(_ name: String, _ page: SearchPage) {
        if let data = try? JSONEncoder().encode(page) { try? data.write(to: file(name)) }
    }
}
