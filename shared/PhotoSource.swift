import Foundation

/// 图片来源。收藏等持久化数据里的旧记录没有该字段，解码时默认 .unsplash。
enum PhotoSource: String, CaseIterable, Codable, Identifiable {
    case unsplash, pexels
    var id: String { rawValue }

    /// 品牌名，用于署名（「on Unsplash / on Pexels」）与图源切换菜单。
    var title: String {
        switch self {
        case .unsplash: "Unsplash"
        case .pexels: "Pexels"
        }
    }

    /// 官网主页，署名里品牌名指向的链接。
    var home: URL {
        switch self {
        case .unsplash: UnsplashLink.home
        case .pexels: URL(string: "https://www.pexels.com/")!
        }
    }

    /// 密钥在 UserDefaults 里的存储 key（BYO key 模式）。
    var apiKeyKey: String {
        switch self {
        case .unsplash: "accessKey"
        case .pexels: "pexelsKey"
        }
    }

    /// 当前已配置的密钥。
    var apiKey: String { UserDefaults.standard.string(forKey: apiKeyKey) ?? "" }
}
