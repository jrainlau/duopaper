import AppKit
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
    func reload(key: String, query: String, orientation: Orientation) async {
        page = 0; totalPages = 1; total = 0; photos = []
        guard !key.isEmpty else { phase = .idle; return }
        phase = .loading
        let client = UnsplashClient(key: key)
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

    func loadMore(key: String, query: String, orientation: Orientation) async {
        guard hasMore, !loadingMore, !key.isEmpty else { return }
        loadingMore = true
        defer { loadingMore = false }
        do {
            let (result, _) = try await UnsplashClient(key: key).search(query: query, orientation: orientation, page: page + 1, force: false)
            apply(result, page: page + 1, append: true)
        } catch {
            totalPages = page
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

    /// 下载到「下载」文件夹并在 Finder 中选中。
    static func download(_ photo: Photo, size: DownloadSize, key: String) async throws {
        await UnsplashClient(key: key).trackDownload(photo)
        let (tmp, response) = try await URLSession.shared.download(from: UnsplashClient.downloadURL(photo, size: size))
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw APIError.http(http.statusCode, "")
        }
        let ext = (response.mimeType ?? "").contains("png") ? "png" : "jpg"
        let dir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        var dest = dir.appendingPathComponent("duopaper-\(photo.id).\(ext)")
        var n = 1
        while FileManager.default.fileExists(atPath: dest.path) {
            dest = dir.appendingPathComponent("duopaper-\(photo.id)-\(n).\(ext)"); n += 1
        }
        try FileManager.default.moveItem(at: tmp, to: dest)
        NSWorkspace.shared.activateFileViewerSelecting([dest])
    }
}
