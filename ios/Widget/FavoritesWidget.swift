import ImageIO
import SwiftUI
import WidgetKit

struct FavoriteEntry: TimelineEntry {
    let date: Date
    /// nil 表示占位（系统要求先给个占位）或没有收藏。
    let item: WidgetShared.Item?
    let hasFavorites: Bool
    /// 图片在可移动方向上的位置：0 = 一端，1 = 另一端，0.5 = 正中。
    var progress: Double = 0.5
    /// 到下一个条目的时长，用作两个条目之间的移动动画时长，让画面持续缓慢移动。
    var stepDuration: Double = 1
}

enum WidgetImage {
    /// 解码并缩小到「刚好覆盖目标像素尺寸」（不裁切、不放大），保留完整画面供小组件里平移。
    static func cover(_ url: URL, target: CGSize) -> UIImage? {
        let key = "\(url.lastPathComponent)|\(Int(target.width))x\(Int(target.height))"
        if let hit = cache, hit.key == key { return hit.image }

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
        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary) else { return nil }
        let image = UIImage(cgImage: cg)
        cache = (key, image)
        return image
    }

    /// 同一张图的多个条目连续渲染时只解码一次。只留一张，内存占用恒定。
    nonisolated(unsafe) private static var cache: (key: String, image: UIImage)?
}

/// 一张图在小组件里的移动方案。
enum WidgetPan {
    /// 判断这张图放进小组件时哪个方向有「没展示出来的部分」。
    /// 返回 nil 表示基本能按原图比例铺满，不需要移动。
    static func axis(item: WidgetShared.Item, in size: CGSize) -> Axis? {
        guard item.width > 0, item.height > 0, size.width > 0, size.height > 0 else { return nil }
        let image = Double(item.width) / Double(item.height)
        let box = Double(size.width / size.height)
        if image < box / 1.04 { return .vertical }
        if image > box * 1.04 { return .horizontal }
        return nil
    }

    enum Axis { case horizontal, vertical }

    /// 在 `steps` 个条目里从一端缓慢移向另一端，方向随机（上 / 下 或 左 / 右）。
    /// 总行程只占可移动距离的一部分，起点和终点都在范围内，所以永远不会超出图片边缘。
    static func progresses(steps: Int, canPan: Bool) -> [Double] {
        guard canPan, steps > 1 else { return Array(repeating: 0.5, count: steps) }
        let travel = Double.random(in: 0.55...0.9)
        let forward = Bool.random()
        let start = forward ? Double.random(in: 0...(1 - travel)) : Double.random(in: travel...1)
        return (0..<steps).map { k in
            let p = start + (forward ? 1 : -1) * travel * Double(k) / Double(steps - 1)
            return min(1, max(0, p))
        }
    }
}

struct FavoritesProvider: TimelineProvider {
    func placeholder(in context: Context) -> FavoriteEntry {
        FavoriteEntry(date: .now, item: nil, hasFavorites: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (FavoriteEntry) -> Void) {
        let pool = Self.pool()
        completion(FavoriteEntry(date: .now, item: pool.randomElement(), hasFavorites: !pool.isEmpty))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FavoriteEntry>) -> Void) {
        let pool = Self.pool()
        let now = Date()

        // 兜底：没有任何收藏（或 App Group 不可用）→ 显示提示，15 分钟后再看一眼。
        guard !pool.isEmpty else {
            let entry = FavoriteEntry(date: now, item: nil, hasFavorites: false)
            completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(900))))
            return
        }

        let interval = WidgetShared.interval
        // 一张图停留 interval 秒，期间拆成几个条目让画面缓慢移动；
        // 图片总数和条目总数都要克制，条目太多真机上会出问题。
        let steps = interval >= 180 ? 3 : (interval >= 60 ? 2 : 1)
        let photos = 8
        let stepDuration = interval / Double(steps)

        // 每个小组件实例各自洗牌、各自随机起点和方向，所以多个小组件之间不同步。
        var sequence: [WidgetShared.Item] = []
        var last: String?
        while sequence.count < photos {
            var round = pool.shuffled()
            if round.count > 1, round.first?.id == last { round.swapAt(0, round.count - 1) }
            sequence += round
            last = round.last?.id
        }
        sequence = Array(sequence.prefix(photos))

        var entries: [FavoriteEntry] = []
        var date = now
        for item in sequence {
            let canPan = WidgetPan.axis(item: item, in: context.displaySize) != nil
            for p in WidgetPan.progresses(steps: steps, canPan: canPan) {
                entries.append(FavoriteEntry(date: date, item: item, hasFavorites: true, progress: p, stepDuration: stepDuration))
                date = date.addingTimeInterval(stepDuration)
            }
        }
        completion(Timeline(entries: entries, policy: .after(date)))
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
            // 图片放在内容层而不是容器背景里：iOS 26 的「清透 / 玻璃」主屏样式会把容器背景
            // 整个替换成玻璃，放在背景里的图片会被抹掉，只剩一个空框。
            .containerBackground(for: .widget) { backdrop }
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
        } else if let item = entry.item {
            PanningImage(item: item, progress: entry.progress, duration: entry.stepDuration, tint: tint(item))
                .ignoresSafeArea()
                .id(item.id)
                .transition(.opacity)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.8), value: item.id)
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private var backdrop: some View {
        if let item = entry.item { tint(item) } else { Color(.secondarySystemBackground) }
    }

    private func tint(_ item: WidgetShared.Item) -> Color {
        guard let hex = item.color, hex.hasPrefix("#"), let v = UInt32(hex.dropFirst(), radix: 16) else {
            return Color(.secondarySystemBackground)
        }
        return Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }
}

/// 按「刚好铺满」缩放图片，沿唯一有多余内容的方向平移。
/// 平移量被限制在多余部分的范围内，所以任何时候都不会露出边。
struct PanningImage: View {
    let item: WidgetShared.Item
    let progress: Double
    let duration: Double
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            let box = geo.size
            ZStack {
                tint
                if let url = WidgetShared.thumbURL(for: item.id),
                   let image = WidgetImage.cover(url, target: CGSize(width: box.width * 2.5, height: box.height * 2.5)) {
                    let iw = image.size.width, ih = image.size.height
                    // 略放大 0.5%，吃掉浮点和取整误差。
                    let scale = max(box.width / iw, box.height / ih) * 1.005
                    let w = iw * scale, h = ih * scale
                    let maxX = max(0, (w - box.width) / 2), maxY = max(0, (h - box.height) / 2)
                    let p = min(1, max(0, progress))
                    let vertical = (h - box.height) >= (w - box.width)
                    let dx = vertical ? 0 : (0.5 - p) * 2 * maxX
                    let dy = vertical ? (0.5 - p) * 2 * maxY : 0
                    Image(uiImage: image)
                        .resizable()
                        .widgetAccentedRenderingMode(.fullColor)
                        .frame(width: w, height: h)
                        .offset(x: dx, y: dy)
                        // 条目切换时，用整段停留时间做线性动画，画面持续缓慢移动。
                        .animation(.linear(duration: duration), value: progress)
                }
            }
            .frame(width: box.width, height: box.height)
            .clipped()
        }
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
