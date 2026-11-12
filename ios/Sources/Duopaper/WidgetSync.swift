import Foundation
import WidgetKit

/// 把收藏同步成小组件专用的小缩略图 + 清单，放在 App Group 共享目录里。
///
/// 兜底思路：
/// - 缩略图是「小组件专用副本」，不放在 Caches / Nuke 缓存里，所以清空缓存不会影响小组件；
/// - 每次启动、回到前台、收藏变化都会对账：缺的补下载，多的删除，所以文件丢了也会自愈；
/// - 某张图下载失败时清单里仍保留它，小组件用 Unsplash 主色块占位，不会空白也不会崩；
/// - App Group 不可用时静默跳过，小组件显示「收藏几张图片」的提示。
actor WidgetSync {
    static let shared = WidgetSync()

    private var running = false
    private var pending: [Photo]?

    struct Status {
        var groupAvailable: Bool
        var favorites: Int
        var thumbs: Int
    }

    nonisolated static func status() -> Status {
        let items = WidgetShared.loadManifest()
        return Status(
            groupAvailable: WidgetShared.directory != nil,
            favorites: items.count,
            thumbs: items.filter { WidgetShared.thumbURL(for: $0.id) != nil }.count
        )
    }

    func sync(_ photos: [Photo]) async {
        if running { pending = photos; return }
        running = true
        var current = photos
        while true {
            await run(current)
            guard let next = pending else { break }
            pending = nil
            current = next
        }
        running = false
    }

    private func run(_ photos: [Photo]) async {
        guard let dir = WidgetShared.directory else { return }
        let fm = FileManager.default

        // 先落清单（已有的缩略图立即可用），再补下载缺的，最后再落一次。
        WidgetShared.saveManifest(photos.map(Self.item))
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetShared.kind)

        var downloaded = false
        for photo in photos {
            guard let dest = WidgetShared.thumbDestination(for: photo.id), !fm.fileExists(atPath: dest.path) else { continue }
            do {
                let (data, response) = try await URLSession.shared.data(from: UnsplashClient.widgetThumbURL(photo))
                if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) { continue }
                try data.write(to: dest, options: .atomic)
                downloaded = true
            } catch {
                continue
            }
        }

        let keep = Set(photos.map { "\($0.id).jpg" })
        if let files = try? fm.contentsOfDirectory(atPath: dir.path) {
            for file in files where file.hasSuffix(".jpg") && !keep.contains(file) {
                try? fm.removeItem(at: dir.appendingPathComponent(file))
            }
        }

        if downloaded { WidgetCenter.shared.reloadTimelines(ofKind: WidgetShared.kind) }
    }

    private static func item(_ photo: Photo) -> WidgetShared.Item {
        WidgetShared.Item(id: photo.id, color: photo.color, width: photo.width, height: photo.height, user: photo.user.name)
    }
}
