import SwiftUI

struct Photo: Decodable, Identifiable, Hashable {
    struct Urls: Decodable, Hashable {
        let raw: URL
        let full: URL
        let regular: URL
    }
    struct Links: Decodable, Hashable {
        let html: URL
        let downloadLocation: URL

        enum CodingKeys: String, CodingKey {
            case html
            case downloadLocation = "download_location"
        }
    }
    struct User: Decodable, Hashable {
        struct Links: Decodable, Hashable {
            let html: URL?
        }
        let name: String
        /// 旧版收藏文件里没有这两个字段，所以是可选的；缺失时署名链接退回到照片页。
        let username: String?
        let links: Links?
    }

    let id: String
    let width: Int
    let height: Int
    let color: String?
    let altDescription: String?
    let urls: Urls
    let links: Links
    let user: User
    /// 图片来源；旧版收藏等持久化数据里没有该字段，默认 Unsplash。
    let source: PhotoSource

    enum CodingKeys: String, CodingKey {
        case id, width, height, color, urls, links, user, source
        case altDescription = "alt_description"
    }

    init(
        id: String, width: Int, height: Int, color: String?, altDescription: String?,
        urls: Urls, links: Links, user: User, source: PhotoSource = .unsplash
    ) {
        self.id = id
        self.width = width
        self.height = height
        self.color = color
        self.altDescription = altDescription
        self.urls = urls
        self.links = links
        self.user = user
        self.source = source
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        width = try c.decode(Int.self, forKey: .width)
        height = try c.decode(Int.self, forKey: .height)
        color = try c.decodeIfPresent(String.self, forKey: .color)
        altDescription = try c.decodeIfPresent(String.self, forKey: .altDescription)
        urls = try c.decode(Urls.self, forKey: .urls)
        links = try c.decode(Links.self, forKey: .links)
        user = try c.decode(User.self, forKey: .user)
        source = try c.decodeIfPresent(PhotoSource.self, forKey: .source) ?? .unsplash
    }
}

/// 只覆盖指定参数、其余保留的 URL 改写工具（Unsplash 的 ixid 统计参数必须留存）。
enum URLParams {
    static func replacing(_ url: URL, _ params: [String: String]) -> URL {
        var c = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        var items = (c.queryItems ?? []).filter { params[$0.name] == nil }
        items += params.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        c.queryItems = items
        return c.url!
    }
}

/// Unsplash API 规范：所有指向 Unsplash 的链接都要带 utm_source=<应用名>&utm_medium=referral。
enum UnsplashLink {
    static let appName = "duopaper"

    static func tagged(_ url: URL) -> URL {
        guard var c = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        var items = (c.queryItems ?? []).filter { $0.name != "utm_source" && $0.name != "utm_medium" }
        items += [.init(name: "utm_source", value: appName), .init(name: "utm_medium", value: "referral")]
        c.queryItems = items
        return c.url ?? url
    }

    static let home = tagged(URL(string: "https://unsplash.com/")!)
}

extension Photo {
    /// 摄影师个人主页；Unsplash 按规范带 UTM，Pexels 保持原链接。
    var photographerURL: URL {
        let url = user.links?.html ?? links.html
        return source == .unsplash ? UnsplashLink.tagged(url) : url
    }
    /// 照片原图源页面。
    var pageURL: URL { source == .unsplash ? UnsplashLink.tagged(links.html) : links.html }
    /// Unsplash 返回的主色，用作占位底色。
    var tint: Color {
        guard let color, color.hasPrefix("#"), let v = UInt32(color.dropFirst(), radix: 16) else { return Color.gray.opacity(0.3) }
        return Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }

    /// 瀑布流缩略图：640px / q75，体积小，Retina 下约 320pt 宽的列也足够清晰。
    var thumbURL: URL {
        switch source {
        case .unsplash: UnsplashClient.thumbURL(self)
        case .pexels: URLParams.replacing(urls.regular, ["w": "640"])
        }
    }

    /// 小组件专用缩略图：1080px，一张约 100KB 以内。
    var widgetThumbURL: URL {
        switch source {
        case .unsplash: UnsplashClient.widgetThumbURL(self)
        case .pexels: URLParams.replacing(urls.regular, ["w": "1080"])
        }
    }

    /// 预览图。
    var previewURL: URL {
        switch source {
        case .unsplash: UnsplashClient.previewURL(self)
        case .pexels: URLParams.replacing(urls.regular, ["w": "1600"])
        }
    }

    /// 下载地址，按清晰度取对应尺寸。
    func downloadURL(size: DownloadSize) -> URL {
        switch source {
        case .unsplash: UnsplashClient.downloadURL(self, size: size)
        case .pexels:
            switch size {
            case .standard: URLParams.replacing(urls.full, ["w": "1880"])
            case .raw: urls.raw
            case .w2560: URLParams.replacing(urls.raw, ["w": "2560"])
            case .w3840: URLParams.replacing(urls.raw, ["w": "3840"])
            }
        }
    }
}

struct SearchPage: Codable {
    var results: [PhotoBox]
    var total: Int
    var totalPages: Int

    enum CodingKeys: String, CodingKey {
        case results, total
        case totalPages = "total_pages"
    }
}

/// 让缓存可以原样保存接口返回的照片 JSON。
struct PhotoBox: Codable {
    let photo: Photo

    init(photo: Photo) { self.photo = photo }
    init(from decoder: Decoder) throws { photo = try Photo(from: decoder) }
    func encode(to encoder: Encoder) throws { try photo.encode(to: encoder) }
}

extension Photo: Encodable {}
extension Photo.Urls: Encodable {}
extension Photo.Links: Encodable {}
extension Photo.User: Encodable {}
extension Photo.User.Links: Encodable {}

enum Orientation: String, CaseIterable, Identifiable {
    case any = ""
    case landscape, portrait, squarish
    var id: String { rawValue }
    var title: String {
        switch self {
        case .any: L("orientation.any")
        case .landscape: L("orientation.landscape")
        case .portrait: L("orientation.portrait")
        case .squarish: L("orientation.squarish")
        }
    }
}

enum DownloadSize: String, CaseIterable, Identifiable {
    case standard, w2560, w3840, raw
    var id: String { rawValue }
    var title: String {
        switch self {
        case .standard: L("size.standard")
        case .w2560: "2.5K"
        case .w3840: "4K"
        case .raw: L("size.raw")
        }
    }
}

struct Topic: Identifiable, Hashable {
    let titleKey: String
    let query: String
    let symbol: String
    var id: String { query }
    /// 标题走文案表，随语言切换。
    var title: String { L(titleKey) }

    /// 分类菜单里固定保留的三个，其余靠搜索；搜过的词进入「历史搜索」。
    static var pinned: [Topic] {
        ["wallpaper", "nature", "street photography"].compactMap { q in all.first { $0.query == q } }
    }

    static let all: [Topic] = [
        .init(titleKey: "topic.wallpaper", query: "wallpaper", symbol: "star"),
        .init(titleKey: "topic.minimal", query: "minimal", symbol: "circle.dashed"),
        .init(titleKey: "topic.autumn", query: "autumn", symbol: "leaf"),
        .init(titleKey: "topic.nature", query: "nature", symbol: "mountain.2"),
        .init(titleKey: "topic.3d render", query: "3d render", symbol: "cube"),
        .init(titleKey: "topic.experimental", query: "experimental", symbol: "flask"),
        .init(titleKey: "topic.film photography", query: "film photography", symbol: "film"),
        .init(titleKey: "topic.street photography", query: "street photography", symbol: "figure.walk"),
        .init(titleKey: "topic.architecture", query: "architecture", symbol: "building.2"),
        .init(titleKey: "topic.textures", query: "textures", symbol: "square.grid.3x3"),
        .init(titleKey: "topic.travel", query: "travel", symbol: "airplane"),
        .init(titleKey: "topic.portrait", query: "portrait", symbol: "person.crop.square"),
    ]
}
