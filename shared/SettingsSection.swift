import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case key, history, download, widget, language, cache, about
    var id: String { rawValue }

    var title: String {
        switch self {
        case .language: L("settings.language")
        case .key: L("settings.section.key")
        case .history: L("settings.section.history")
        case .download: L("settings.section.download")
        case .widget: L("settings.section.widget")
        case .cache: L("settings.section.cache")
        case .about: L("settings.section.about")
        }
    }

    var symbol: String {
        switch self {
        case .language: "globe"
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
