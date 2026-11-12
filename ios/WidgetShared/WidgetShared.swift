import Foundation

/// App 与小组件共用的数据通道（通过 App Group 共享目录）。
/// 只依赖 Foundation，两个 target 都编译这一个文件。
enum WidgetShared {
    static let groupID = "group.com.jrainlau.duopaper"
    static let kind = "DuopaperFavorites"
    static let deepLink = URL(string: "duopaper://favorites")!

    static let intervalKey = "widgetInterval"
    static let defaultInterval: TimeInterval = 300

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
            return v >= 30 ? v : defaultInterval
        }
        set { defaults?.set(newValue, forKey: intervalKey) }
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
}
