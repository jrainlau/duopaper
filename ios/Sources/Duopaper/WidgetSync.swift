import Foundation
import UIKit
import WidgetKit

/// 把小组件当前来源（收藏，或关键词缓存的那一批图）同步成小组件专用的小缩略图 + 清单，放在 App Group 共享目录里。
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

    /// 当前来源对应的图片：来源是关键词且缓存可用时用缓存，否则用收藏。
    nonisolated static func photos(favorites: [Photo]) -> [Photo] {
        WidgetSource.active()?.photos ?? favorites
    }

    /// 按当前来源对账。收藏变化时，来源是关键词就不动小组件（避免无谓重排时间线）。
    /// progress：缩略图下载进度 0...1（只汇报本次调用自己跑的那一轮），在主线程回调。
    func sync(favorites: [Photo], favoritesChanged: Bool = false, progress: (@MainActor @Sendable (Double) -> Void)? = nil) async {
        if favoritesChanged && !WidgetShared.sourceKeyword.isEmpty { return }
        await sync(Self.photos(favorites: favorites), progress: progress)
    }

    func sync(_ photos: [Photo], progress: (@MainActor @Sendable (Double) -> Void)? = nil) async {
        if running { pending = photos; return }
        running = true
        var current = photos
        var report = progress
        while true {
            await run(current, progress: report)
            report = nil
            guard let next = pending else { break }
            pending = nil
            current = next
        }
        running = false
    }

    private func run(_ photos: [Photo], progress: (@MainActor @Sendable (Double) -> Void)?) async {
        guard let dir = WidgetShared.directory else { return }
        let fm = FileManager.default

        // 先落清单（已有的缩略图立即可用），再补下载缺的，最后再落一次。
        WidgetShared.saveManifest(photos.map(Self.item))
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetShared.kind)

        var downloaded = false
        let missing = photos.filter { photo in
            WidgetShared.thumbDestination(for: photo.id).map { !fm.fileExists(atPath: $0.path) } ?? false
        }
        var finished = 0
        await progress?(missing.isEmpty ? 1 : 0)

        // 退到后台时向系统多要一点时间，避免下载到一半被挂起，只落下几张。
        let background = await MainActor.run { UIApplication.shared.beginBackgroundTask(withName: "widget-thumbs") }
        defer { if background != .invalid { Task { @MainActor in UIApplication.shared.endBackgroundTask(background) } } }

        // 并发下载（同时 4 张），每张失败后重试一次。
        await withTaskGroup(of: Bool.self) { group in
            var iterator = missing.makeIterator()
            func addNext() -> Bool {
                guard let photo = iterator.next() else { return false }
                group.addTask { await Self.download(photo) }
                return true
            }
            for _ in 0..<4 { if !addNext() { break } }
            while let ok = await group.next() {
                if ok { downloaded = true }
                finished += 1
                await progress?(Double(finished) / Double(missing.count))
                _ = addNext()
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

    private static func download(_ photo: Photo) async -> Bool {
        guard let dest = WidgetShared.thumbDestination(for: photo.id) else { return false }
        for attempt in 0..<2 {
            if attempt > 0 { try? await Task.sleep(for: .seconds(1)) }
            guard let (data, response) = try? await URLSession.shared.data(from: UnsplashClient.widgetThumbURL(photo)),
                  (response as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) ?? true,
                  (try? data.write(to: dest, options: .atomic)) != nil else { continue }
            return true
        }
        return false
    }

    private static func item(_ photo: Photo) -> WidgetShared.Item {
        WidgetShared.Item(id: photo.id, color: photo.color, width: photo.width, height: photo.height, user: photo.user.name)
    }
}
