import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case key, history, download, widget, cache, about
    var id: String { rawValue }

    var title: String {
        switch self {
        case .key: "Unsplash 密钥"
        case .history: "搜索历史"
        case .download: "下载"
        case .widget: "小组件"
        case .cache: "缓存"
        case .about: "关于"
        }
    }

    var symbol: String {
        switch self {
        case .key: "key"
        case .history: "clock.arrow.circlepath"
        case .download: "arrow.down.circle"
        case .widget: "square.grid.2x2"
        case .cache: "internaldrive"
        case .about: "info.circle"
        }
    }

}

extension SettingsSection {
    /// macOS 没有小组件栏目。
    static var macCases: [SettingsSection] { allCases.filter { $0 != .widget } }
}
