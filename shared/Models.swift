import SwiftUI

struct Photo: Decodable, Identifiable, Hashable {
    struct Urls: Decodable, Hashable {
        let raw: URL
        let full: URL
        let regular: URL
    }
    struct Links: Decodable, Hashable {
        let html: URL
        let downloadLocation: URL

        enum CodingKeys: String, CodingKey {
            case html
            case downloadLocation = "download_location"
        }
    }
    struct User: Decodable, Hashable {
        let name: String
    }

    let id: String
    let width: Int
    let height: Int
    let color: String?
    let altDescription: String?
    let urls: Urls
    let links: Links
    let user: User

    enum CodingKeys: String, CodingKey {
        case id, width, height, color, urls, links, user
        case altDescription = "alt_description"
    }
}

extension Photo {
    /// Unsplash 返回的主色，用作占位底色。
    var tint: Color {
        guard let color, color.hasPrefix("#"), let v = UInt32(color.dropFirst(), radix: 16) else { return Color.gray.opacity(0.3) }
        return Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }
}

struct SearchPage: Codable {
    var results: [PhotoBox]
    var total: Int
    var totalPages: Int

    enum CodingKeys: String, CodingKey {
        case results, total
        case totalPages = "total_pages"
    }
}

/// 让缓存可以原样保存接口返回的照片 JSON。
struct PhotoBox: Codable {
    let photo: Photo

    init(from decoder: Decoder) throws { photo = try Photo(from: decoder) }
    func encode(to encoder: Encoder) throws { try photo.encode(to: encoder) }
}

extension Photo: Encodable {}
extension Photo.Urls: Encodable {}
extension Photo.Links: Encodable {}
extension Photo.User: Encodable {}

enum Orientation: String, CaseIterable, Identifiable {
    case any = ""
    case landscape, portrait, squarish
    var id: String { rawValue }
    var title: String {
        switch self {
        case .any: "全部"
        case .landscape: "横屏"
        case .portrait: "竖屏"
        case .squarish: "方图"
        }
    }
}

enum DownloadSize: String, CaseIterable, Identifiable {
    case standard, w2560, w3840, raw
    var id: String { rawValue }
    var title: String {
        switch self {
        case .standard: "标准"
        case .w2560: "2.5K"
        case .w3840: "4K"
        case .raw: "原始"
        }
    }
}

struct Topic: Identifiable, Hashable {
    let title: String
    let query: String
    let symbol: String
    let tint: Color
    var id: String { query }

    /// 分类菜单里固定保留的三个，其余靠搜索；搜过的词进入「历史搜索」。
    static var pinned: [Topic] {
        ["wallpaper", "nature", "street photography"].compactMap { q in all.first { $0.query == q } }
    }

    static let all: [Topic] = [
        .init(title: "精选", query: "wallpaper", symbol: "star", tint: .yellow),
        .init(title: "极简", query: "minimal", symbol: "circle.dashed", tint: .gray),
        .init(title: "秋日", query: "autumn", symbol: "leaf", tint: .orange),
        .init(title: "自然", query: "nature", symbol: "mountain.2", tint: .green),
        .init(title: "3D", query: "3d render", symbol: "cube", tint: .indigo),
        .init(title: "实验", query: "experimental", symbol: "flask", tint: .purple),
        .init(title: "胶片", query: "film photography", symbol: "film", tint: .brown),
        .init(title: "街拍", query: "street photography", symbol: "figure.walk", tint: .teal),
        .init(title: "建筑", query: "architecture", symbol: "building.2", tint: .blue),
        .init(title: "纹理", query: "textures", symbol: "square.grid.3x3", tint: .mint),
        .init(title: "旅行", query: "travel", symbol: "airplane", tint: .cyan),
        .init(title: "人物", query: "portrait", symbol: "person.crop.square", tint: .pink),
    ]
}
