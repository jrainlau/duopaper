import Foundation
import Observation

@MainActor
@Observable
final class FavoritesStore {
    private(set) var photos: [Photo] = []

    /// 收藏列表变化后回调（iOS 用它同步小组件缩略图）。
    @ObservationIgnored var onChange: (([Photo]) -> Void)?

    private static let file: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Duopaper", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("favorites.json")
    }()

    init() {
        if let data = try? Data(contentsOf: Self.file),
           let saved = try? JSONDecoder().decode([Photo].self, from: data) {
            photos = saved
        }
    }

    func contains(_ photo: Photo) -> Bool { photos.contains { $0.id == photo.id } }

    func toggle(_ photo: Photo) {
        if let index = photos.firstIndex(where: { $0.id == photo.id }) {
            photos.remove(at: index)
        } else {
            photos.insert(photo, at: 0)
        }
        if let data = try? JSONEncoder().encode(photos) { try? data.write(to: Self.file, options: .atomic) }
        onChange?(photos)
    }
}
