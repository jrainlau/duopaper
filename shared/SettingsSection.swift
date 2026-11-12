import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case key, history, download, cache, about
    var id: String { rawValue }

    var title: String {
        switch self {
        case .key: "Unsplash 密钥"
        case .history: "搜索历史"
        case .download: "下载"
        case .cache: "缓存"
        case .about: "关于"
        }
    }

    var symbol: String {
        switch self {
        case .key: "key.fill"
        case .history: "clock.arrow.circlepath"
        case .download: "arrow.down.circle.fill"
        case .cache: "internaldrive.fill"
        case .about: "info.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .key: .orange
        case .history: .blue
        case .download: .green
        case .cache: .gray
        case .about: .indigo
        }
    }
}
