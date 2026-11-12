import Foundation
import Observation

@MainActor
@Observable
final class WallpaperStore {
    enum Phase { case idle, loading, ready, failed(String) }

    var photos: [Photo] = []
    var total = 0
    var phase: Phase = .idle
    var loadingMore = false

    private var page = 0
    private var totalPages = 1
    var hasMore: Bool { page < totalPages }

    /// 每次刷新从随机页开始，并打乱页内顺序，让每次看到的图都不一样。
    func reload(key: String, source: PhotoSource, query: String, orientation: Orientation) async {
        page = 0; totalPages = 1; total = 0; photos = []
        guard !key.isEmpty else { phase = .idle; return }
        phase = .loading
        let client = makeClient(source: source, key: key)
        do {
            let start = Int.random(in: 1...20)
            var (result, _) = try await client.search(query: query, orientation: orientation, page: start, force: false)
            var landed = start
            if result.results.isEmpty && start > 1 {
                (result, _) = try await client.search(query: query, orientation: orientation, page: 1, force: false)
                landed = 1
            }
            apply(result, page: landed, append: false)
        } catch is CancellationError {
        } catch let e as URLError where e.code == .cancelled {
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func loadMore(key: String, source: PhotoSource, query: String, orientation: Orientation) async {
        guard hasMore, !loadingMore, !key.isEmpty else { return }
        loadingMore = true
        defer { loadingMore = false }
        do {
            let (result, _) = try await makeClient(source: source, key: key).search(query: query, orientation: orientation, page: page + 1, force: false)
            apply(result, page: page + 1, append: true)
        } catch {
            totalPages = page
        }
    }

    private func makeClient(source: PhotoSource, key: String) -> PhotoSearchClient {
        switch source {
        case .unsplash: UnsplashClient(key: key)
        case .pexels: PexelsClient(key: key)
        }
    }

    private func apply(_ result: SearchPage, page: Int, append: Bool) {
        let items = result.results.map(\.photo).shuffled()
        let known = Set(photos.map(\.id))
        photos = append ? photos + items.filter { !known.contains($0.id) } : items
        total = result.total
        totalPages = items.isEmpty ? page : result.totalPages
        self.page = page
        phase = .ready
    }

    /// 下载原图到指定目录并返回文件地址；调用方决定之后怎么处理（Finder 中显示、存入相册等）。
    /// 密钥按图片来源各自读取（BYO key 模式）；Pexels 不要求下载计数。
    static func download(_ photo: Photo, size: DownloadSize, into directory: URL) async throws -> URL {
        switch photo.source {
        case .unsplash:
            let key = PhotoSource.unsplash.apiKey
            if !key.isEmpty { await UnsplashClient(key: key).trackDownload(photo) }
        case .pexels:
            break
        }
        let (tmp, response) = try await URLSession.shared.download(from: photo.downloadURL(size: size))
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw APIError.http(http.statusCode, "")
        }
        let ext = (response.mimeType ?? "").contains("png") ? "png" : "jpg"
        var dest = directory.appendingPathComponent("duopaper-\(photo.id).\(ext)")
        var n = 1
        while FileManager.default.fileExists(atPath: dest.path) {
            dest = directory.appendingPathComponent("duopaper-\(photo.id)-\(n).\(ext)"); n += 1
        }
        try FileManager.default.moveItem(at: tmp, to: dest)
        return dest
    }
}
