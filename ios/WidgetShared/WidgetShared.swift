import AppIntents
import Foundation

/// App 与小组件共用的数据通道（通过 App Group 共享目录），以及交互小组件的 App Intent。
/// 这个文件夹被 App 与 Widget Extension 两个 target 同步编译（Apple 要求 AppIntent 同时属于两者）。
enum WidgetShared {
    static let groupID = "group.com.jrainlau.duopaper"
    static let kind = "DuopaperFavorites"
    /// App 的 URL scheme 入口仍保留；小组件本身不再用 widgetURL 打开收藏页。
    static let deepLink = URL(string: "duopaper://favorites")!

    static let intervalKey = "widgetInterval"
    /// Apple 建议 timeline 条目至少间隔约 5 分钟；本项目最短档再放宽到 15 分钟，
    /// 12 个条目可覆盖 3 小时以上，不依赖被系统节流（约 15~60 分钟一次）的后台刷新。
    /// 旧版本存下的 1 分钟 / 5 分钟值会自动回落到这个下限，App 与小组件两端读到的间隔一致。
    static let minimumInterval: TimeInterval = 900
    static let defaultInterval: TimeInterval = minimumInterval

    struct Item: Codable, Hashable {
        let id: String
        let color: String?
        let width: Int
        let height: Int
        let user: String
    }

    static var defaults: UserDefaults? { UserDefaults(suiteName: groupID) }

    /// App Group 不可用（没有签名权限等）时为 nil，调用方按「没有小组件数据」兜底。
    static var directory: URL? {
        guard let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else { return nil }
        let dir = base.appendingPathComponent("widget", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var interval: TimeInterval {
        get {
            let v = defaults?.double(forKey: intervalKey) ?? 0
            return v >= minimumInterval ? v : defaultInterval
        }
        set { defaults?.set(max(newValue, minimumInterval), forKey: intervalKey) }
    }

    private static var manifestURL: URL? { directory?.appendingPathComponent("manifest.json") }

    static func loadManifest() -> [Item] {
        guard let url = manifestURL, let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([Item].self, from: data)) ?? []
    }

    static func saveManifest(_ items: [Item]) {
        guard let url = manifestURL, let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func thumbURL(for id: String) -> URL? {
        guard let url = directory?.appendingPathComponent("\(id).jpg"),
              FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    static func thumbDestination(for id: String) -> URL? {
        directory?.appendingPathComponent("\(id).jpg")
    }

    /// 优先只用「缩略图文件还在」的收藏；一张都没有时退回到用主色块占位，小组件也不会空白。
    /// 时间线轮播与点击换图共用同一个池，避免点到一张没有图的收藏。
    static func carouselPool() -> [Item] {
        let all = loadManifest()
        let withThumb = all.filter { thumbURL(for: $0.id) != nil }
        return withThumb.isEmpty ? all : withThumb
    }
}

/// 「洗牌袋」伪随机：remaining 是本轮还没播的，played 是本轮已播的。
/// 每次从 remaining 里取一张放进 played；remaining 空了就整体换过来（重新洗牌）开下一轮。
/// 状态持久化在 App Group，时间线轮播与点击换图共用同一份进度，所以点击不会纯随机重复。
enum ShuffleBag {
    private struct State: Codable {
        var remaining: [String] = []
        var played: [String] = []
        var last: String?
        /// 点击抽中、还没被新时间线消费的图；Button(intent:) 结束后系统必定 reload 时间线。
        var pendingTap: String? = nil
    }

    private static let key = "widgetShuffleBag"

    /// 生成时间线用：一次取 count 张，进度跨多次 getTimeline 延续。
    static func draw(_ count: Int, from pool: [WidgetShared.Item]) -> [WidgetShared.Item] {
        var state = load()
        let result = take(count, from: pool, state: &state)
        save(state)
        return result
    }

    /// 点击用：只从袋里取一张，记为待显示；系统随后 reload 时间线，由首张展示它。
    static func pickForTap(from pool: [WidgetShared.Item]) {
        var state = load()
        guard let item = take(1, from: pool, state: &state).first else { return }
        state.pendingTap = item.id
        save(state)
    }

    /// 时间线生成时消费一次点击结果。多个小组件实例同时 reload 时只有一个能取到，其余照常抽牌。
    static func consumePendingTap() -> String? {
        var state = load()
        guard let id = state.pendingTap else { return nil }
        state.pendingTap = nil
        save(state)
        return id
    }

    private static func take(_ count: Int, from pool: [WidgetShared.Item], state: inout State) -> [WidgetShared.Item] {
        let byID = Dictionary(pool.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

        // 与当前收藏对齐：删掉已不存在的，新增的随机插进本轮剩余里。
        state.remaining = state.remaining.filter { byID[$0] != nil }
        state.played = state.played.filter { byID[$0] != nil }
        let known = Set(state.remaining).union(state.played)
        for id in byID.keys where !known.contains(id) {
            state.remaining.insert(id, at: Int.random(in: 0...state.remaining.count))
        }

        var result: [WidgetShared.Item] = []
        while result.count < count {
            if state.remaining.isEmpty {
                state.remaining = state.played.shuffled()
                state.played = []
                // 新一轮的第一张不能和上一轮最后一张相同。
                if state.remaining.count > 1, state.remaining.first == state.last {
                    state.remaining.swapAt(0, Int.random(in: 1..<state.remaining.count))
                }
            }
            guard !state.remaining.isEmpty else { break }
            let id = state.remaining.removeFirst()
            state.played.append(id)
            state.last = id
            if let item = byID[id] { result.append(item) }
        }
        return result
    }

    private static func load() -> State {
        guard let data = WidgetShared.defaults?.data(forKey: key),
              let state = try? JSONDecoder().decode(State.self, from: data) else {
            return State()
        }
        return state
    }

    private static func save(_ state: State) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        WidgetShared.defaults?.set(data, forKey: key)
    }
}

/// 点击整块小组件换一张，而不是打开 App。
/// AppIntent 默认在 Widget Extension 进程执行，perform() 返回后系统保证 reload 时间线；
/// 这个 reload 属于交互，不消耗每日刷新预算。
struct NextPhotoIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Another Favorite"

    func perform() async throws -> some IntentResult {
        ShuffleBag.pickForTap(from: WidgetShared.carouselPool())
        return .result()
    }
}
