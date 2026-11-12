import ImageIO
import SwiftUI
import WidgetKit

struct FavoriteEntry: TimelineEntry {
    let date: Date
    /// nil 表示占位（系统要求先给个占位）或没有收藏。
    let item: WidgetShared.Item?
    let hasFavorites: Bool
    /// 已经按小组件尺寸缩小并居中裁好的图。真机上小组件渲染有严格的内存限制，
    /// 不能在视图里解码整张大图，更不能为上百个条目各解码一遍。
    var image: UIImage? = nil
}

enum WidgetImage {
    /// 缩放到刚好覆盖目标像素尺寸（不放大），再居中裁成目标比例。
    static func load(_ url: URL, cover target: CGSize) -> UIImage? {
        let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let w = props[kCGImagePropertyPixelWidth] as? CGFloat,
              let h = props[kCGImagePropertyPixelHeight] as? CGFloat, w > 0, h > 0 else { return nil }

        let scale = min(1, max(target.width / w, target.height / h))
        let thumbOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Int((max(w, h) * scale).rounded(.up)),
        ]
        guard let full = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary) else { return nil }

        let cw = CGFloat(full.width), ch = CGFloat(full.height)
        let aspect = target.width / target.height
        let cropSize = cw / ch > aspect ? CGSize(width: ch * aspect, height: ch) : CGSize(width: cw, height: cw / aspect)
        let rect = CGRect(x: (cw - cropSize.width) / 2, y: (ch - cropSize.height) / 2, width: cropSize.width, height: cropSize.height).integral
        guard let cropped = full.cropping(to: rect) else { return UIImage(cgImage: full) }
        return UIImage(cgImage: cropped)
    }
}

struct FavoritesProvider: TimelineProvider {
    func placeholder(in context: Context) -> FavoriteEntry {
        FavoriteEntry(date: .now, item: nil, hasFavorites: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (FavoriteEntry) -> Void) {
        let pool = Self.pool()
        let item = pool.randomElement()
        let pixel = CGSize(width: context.displaySize.width * 2.5, height: context.displaySize.height * 2.5)
        let image = item.flatMap { WidgetShared.thumbURL(for: $0.id) }.flatMap { WidgetImage.load($0, cover: pixel) }
        completion(FavoriteEntry(date: .now, item: item, hasFavorites: !pool.isEmpty, image: image))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FavoriteEntry>) -> Void) {
        let pool = Self.pool()
        let now = Date()

        // 兜底 1：没有任何收藏（或 App Group 不可用）→ 显示提示，15 分钟后再看一眼。
        guard !pool.isEmpty else {
            let entry = FavoriteEntry(date: now, item: nil, hasFavorites: false)
            completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(900))))
            return
        }

        let interval = WidgetShared.interval
        // 一次生成一小批未来条目：系统按时间自动切换，批次用完后再重新生成。
        // 条目数要少：每个条目的渲染结果都会被预先存档，上百个条目会在真机上撑爆内存，小组件只剩空框。
        let count = 12
        let displaySize = context.displaySize
        let pixel = CGSize(width: displaySize.width * 2.5, height: displaySize.height * 2.5)

        // 每个小组件实例各自洗牌、各自随机起点，所以多个小组件之间不同步。
        var sequence: [WidgetShared.Item] = []
        var last: String?
        while sequence.count < count {
            var round = pool.shuffled()
            if round.count > 1, round.first?.id == last { round.swapAt(0, round.count - 1) }
            sequence += round
            last = round.last?.id
        }

        var decoded: [String: UIImage] = [:]
        func image(for item: WidgetShared.Item) -> UIImage? {
            if let cached = decoded[item.id] { return cached }
            guard let url = WidgetShared.thumbURL(for: item.id), let img = WidgetImage.load(url, cover: pixel) else { return nil }
            decoded[item.id] = img
            return img
        }
        let entries = (0..<count).map { i in
            FavoriteEntry(date: now.addingTimeInterval(Double(i) * interval), item: sequence[i], hasFavorites: true, image: image(for: sequence[i]))
        }
        let end = now.addingTimeInterval(Double(count) * interval)
        completion(Timeline(entries: entries, policy: .after(end)))
    }

    /// 优先只用「缩略图文件还在」的收藏；一张都没有时退回到用主色块占位，小组件也不会空白。
    private static func pool() -> [WidgetShared.Item] {
        let all = WidgetShared.loadManifest()
        let withThumb = all.filter { WidgetShared.thumbURL(for: $0.id) != nil }
        return withThumb.isEmpty ? all : withThumb
    }
}

struct FavoritesWidgetView: View {
    let entry: FavoriteEntry

    var body: some View {
        content
            .widgetURL(WidgetShared.deepLink)
            .containerBackground(for: .widget) { background }
    }

    @ViewBuilder
    private var content: some View {
        if !entry.hasFavorites {
            VStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                Text("收藏几张图片，这里会轮播")
                    .font(.footnote.weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(8)
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private var background: some View {
        if let item = entry.item {
            ZStack {
                tint(item)
                if let image = entry.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .id(item.id)
            .transition(.opacity)
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: 0.8), value: item.id)
        } else {
            Color(.secondarySystemBackground)
        }
    }

    private func tint(_ item: WidgetShared.Item) -> Color {
        guard let hex = item.color, hex.hasPrefix("#"), let v = UInt32(hex.dropFirst(), radix: 16) else {
            return Color(.secondarySystemBackground)
        }
        return Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }
}

struct FavoritesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetShared.kind, provider: FavoritesProvider()) { entry in
            FavoritesWidgetView(entry: entry)
        }
        .configurationDisplayName("收藏轮播")
        .description("轮播你收藏的图片，点一下回到 Duopaper 的收藏。")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
