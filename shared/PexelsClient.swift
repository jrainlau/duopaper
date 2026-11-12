import Foundation

/// 两个图源客户端共有的搜索能力，WallpaperStore 靠它在图源间切换。
protocol PhotoSearchClient {
    func search(query: String, orientation: Orientation, page: Int, force: Bool) async throws -> (SearchPage, fromCache: Bool)
}

extension UnsplashClient: PhotoSearchClient {}
extension PexelsClient: PhotoSearchClient {}

/// Pexels 图源客户端。接口与 Unsplash 不同，这里统一映射成项目里的 Photo / SearchPage：
/// - id 加 `pexels-` 前缀，避免与 Unsplash 的 id 撞车（收藏去重、小组件文件名都用 id）；
/// - Pexels 不要求下载计数，trackDownload 是空操作；
/// - 响应里没有 total_pages，按 total_results / per_page 自行计算。
struct PexelsClient {
    static let perPage = UnsplashClient.perPage
    static let maxPage = UnsplashClient.maxPage
    static let cacheTTL = UnsplashClient.cacheTTL

    let key: String

    struct Response: Decodable {
        struct Src: Decodable {
            let original: URL
        }
        struct Item: Decodable {
            let id: Int
            let width: Int
            let height: Int
            let url: String?
            let photographer: String
            let photographerURL: String?
            let avgColor: String?
            let alt: String?
            let src: Src

            enum CodingKeys: String, CodingKey {
                case id, width, height, url, photographer, alt, src
                case photographerURL = "photographer_url"
                case avgColor = "avg_color"
            }
        }

        let photos: [Item]
        let totalResults: Int

        enum CodingKeys: String, CodingKey {
            case photos
            case totalResults = "total_results"
        }
    }

    private func request(_ url: URL) -> URLRequest {
        var r = URLRequest(url: url)
        r.setValue(key, forHTTPHeaderField: "Authorization")
        return r
    }

    private func fetch(_ url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request(url))
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw APIError.http(http.statusCode, "")
        }
        return data
    }

    func search(query: String, orientation: Orientation, page: Int, force: Bool) async throws -> (SearchPage, fromCache: Bool) {
        let q = query.trimmingCharacters(in: .whitespaces).isEmpty ? "wallpaper" : query.trimmingCharacters(in: .whitespaces)
        // 缓存名带图源前缀，避免和 Unsplash 的同名缓存混用。
        let cacheName = "pexels|\(q.lowercased())|\(orientation.rawValue.isEmpty ? "any" : orientation.rawValue)|\(page)"
        if !force, let cached = PageCache.read(cacheName) { return (cached, true) }

        var c = URLComponents(string: "https://api.pexels.com/v1/search")!
        c.queryItems = [
            .init(name: "query", value: q),
            .init(name: "page", value: String(page)),
            .init(name: "per_page", value: String(Self.perPage)),
        ]
        // Pexels 只认 landscape / portrait / square。
        if orientation != .any {
            c.queryItems?.append(.init(name: "orientation", value: orientation == .squarish ? "square" : orientation.rawValue))
        }

        let decoded = try JSONDecoder().decode(Response.self, from: try await fetch(c.url!))
        var result = SearchPage(results: decoded.photos.map(\.photoBox), total: decoded.totalResults, totalPages: 1)
        result.totalPages = decoded.photos.isEmpty
            ? 1
            : max(1, min((decoded.totalResults + Self.perPage - 1) / Self.perPage, Self.maxPage))
        PageCache.write(cacheName, result)
        return (result, false)
    }

    /// 用最轻的接口（curated 只取 1 张）校验 API Key 是否可用。
    func validate() async throws {
        var c = URLComponents(string: "https://api.pexels.com/v1/curated")!
        c.queryItems = [.init(name: "per_page", value: "1")]
        _ = try await fetch(c.url!)
    }
}

extension PexelsClient.Response.Item {
    /// Pexels 尺寸参数与 Unsplash 的 imgix 类似：images.pexels.com 支持用 query 调宽高。
    var photoBox: PhotoBox {
        let original = src.original
        let sized = { URLParams.replacing(original, ["auto": "compress", "cs": "tinysrgb", "w": $0]) }
        let photo = Photo(
            id: "pexels-\(id)",
            width: width,
            height: height,
            color: avgColor,
            altDescription: alt,
            urls: .init(raw: original, full: sized("1880"), regular: sized("1080")),
            links: .init(html: url.flatMap(URL.init(string:)) ?? original, downloadLocation: original),
            user: .init(name: photographer, username: photographer, links: .init(html: photographerURL.flatMap(URL.init(string:)))),
            source: .pexels
        )
        return PhotoBox(photo: photo)
    }
}
