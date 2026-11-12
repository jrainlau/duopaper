import AppIntents
import ImageIO
import SwiftUI
import WidgetKit

// 小组件进程不编译 shared/，这里放一份最小文案表；语言跟随系统（小组件没有设置入口）。
private enum WidgetL10n {
    static func t(_ key: String) -> String {
        for lang in Locale.preferredLanguages {
            let l = lang.lowercased()
            if l.hasPrefix("zh") {
                let hant = l.contains("hant") || l.contains("-tw") || l.contains("-hk") || l.contains("-mo")
                return (hant ? hantTable : hansTable)[key] ?? key
            }
            if l.hasPrefix("en") { return enTable[key] ?? key }
        }
        return enTable[key] ?? key
    }

    private static let enTable = [
        "widget.emptyPrompt": "Favorite some photos and they’ll rotate here",
        "widget.configName": "Favorites Carousel",
        "widget.configDesc": "Rotate through your favorite photos; tap to show another one.",
        "widget.nextPhoto": "Next photo",
    ]

    private static let hansTable = [
        "widget.emptyPrompt": "收藏几张图片，这里会轮播",
        "widget.configName": "收藏轮播",
        "widget.configDesc": "轮播你收藏的图片，点一下随机换一张。",
        "widget.nextPhoto": "换一张",
    ]

    private static let hantTable = [
        "widget.emptyPrompt": "收藏幾張圖片，這裡會輪播",
        "widget.configName": "收藏輪播",
        "widget.configDesc": "輪播你收藏的圖片，點一下隨機換一張。",
        "widget.nextPhoto": "換一張",
    ]
}

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
        let pool = WidgetShared.carouselPool()
        // 只是小组件库 / 占位预览，纯随机即可，不消耗洗牌袋进度。
        let item = pool.randomElement()
        let pixel = CGSize(width: context.displaySize.width * 2.5, height: context.displaySize.height * 2.5)
        let image = item.flatMap { WidgetShared.thumbURL(for: $0.id) }.flatMap { WidgetImage.load($0, cover: pixel) }
        completion(FavoriteEntry(date: .now, item: item, hasFavorites: !pool.isEmpty, image: image))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FavoriteEntry>) -> Void) {
        let pool = WidgetShared.carouselPool()
        let now = Date()

        // 兜底：没有任何收藏（或 App Group 不可用）→ 显示提示，15 分钟后再看一眼。
        guard !pool.isEmpty else {
            let entry = FavoriteEntry(date: now, item: nil, hasFavorites: false)
            completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(900))))
            return
        }

        let interval = WidgetShared.interval
        // 一次生成一小批未来条目：系统按时间自动切换，批次用完后再重新生成。
        // 间隔下限见 WidgetShared.minimumInterval，12 条可覆盖 3~24 小时，期间不消耗后台刷新额度。
        // 条目数要少：每个条目的渲染结果都会被预先存档，上百个条目会在真机上撑爆内存，小组件只剩空框。
        let count = 12
        let displaySize = context.displaySize
        let pixel = CGSize(width: displaySize.width * 2.5, height: displaySize.height * 2.5)

        // 点击换图：把按钮从洗牌袋抽到的那张放到新时间线首张，其余继续按袋排。
        // Button(intent:) 结束后系统保证 reload 时间线，所以点一次只推进一张，且不会纯随机重复。
        let tappedID = ShuffleBag.consumePendingTap()
        let tapped = tappedID.flatMap { id in pool.first { $0.id == id } }
        var sequence = (tapped.map { [$0] } ?? []) + ShuffleBag.draw(count - (tapped == nil ? 0 : 1), from: pool)
        // 兜底补齐，避免条目索引越界（pool 非空时理论上不会走到）。
        if sequence.count < count {
            sequence += ShuffleBag.draw(count - sequence.count, from: pool)
        }

        var decoded: [String: UIImage] = [:]
        func image(for item: WidgetShared.Item) -> UIImage? {
            if let cached = decoded[item.id] { return cached }
            guard let url = WidgetShared.thumbURL(for: item.id), let img = WidgetImage.load(url, cover: pixel) else { return nil }
            decoded[item.id] = img
            return img
        }
        let entries = sequence.prefix(count).enumerated().map { i, item in
            FavoriteEntry(date: now.addingTimeInterval(Double(i) * interval), item: item, hasFavorites: true, image: image(for: item))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct FavoritesWidgetView: View {
    let entry: FavoriteEntry

    var body: some View {
        ZStack {
            if entry.hasFavorites {
                Button(intent: NextPhotoIntent()) {
                    content
                }
                .buttonStyle(.plain)
                .accessibilityLabel(WidgetL10n.t("widget.nextPhoto"))
            } else {
                content
            }
        }
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
                Text(WidgetL10n.t("widget.emptyPrompt"))
                    .font(.footnote.weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(8)
        } else if let item = entry.item {
            ZStack {
                tint(item)
                if let image = entry.image {
                    Image(uiImage: image)
                        .resizable()
                        .renderingMode(.original)
                        // 着色 / 清透样式下系统会把内容染成单色，要求保留原图颜色。
                        .widgetAccentedRenderingMode(.fullColor)
                        .scaledToFill()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .ignoresSafeArea()
            .id(item.id)
            .transition(.opacity)
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: 0.8), value: item.id)
            // 署名：整块是换图按钮，所以这里只放文字，不放可点的链接。
            .overlay(alignment: .bottomLeading) {
                Text("\(item.user) / Unsplash")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.6), radius: 2)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
            }
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

struct FavoritesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetShared.kind, provider: FavoritesProvider()) { entry in
            FavoritesWidgetView(entry: entry)
        }
        .configurationDisplayName(WidgetL10n.t("widget.configName"))
        .description(WidgetL10n.t("widget.configDesc"))
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
