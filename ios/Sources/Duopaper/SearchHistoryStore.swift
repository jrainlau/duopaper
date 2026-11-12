import Foundation
import Observation

/// 搜索历史：最近的在前，可在设置里排序、删除。
@MainActor
@Observable
final class SearchHistoryStore {
    private(set) var items: [String]

    private static let key = "searchHistory"
    private static let limit = 100

    init() {
        items = UserDefaults.standard.stringArray(forKey: Self.key) ?? []
    }

    func add(_ query: String) {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        items.removeAll { $0.caseInsensitiveCompare(q) == .orderedSame }
        items.insert(q, at: 0)
        if items.count > Self.limit { items.removeLast(items.count - Self.limit) }
        save()
    }

    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func removeAll() {
        items.removeAll()
        save()
    }

    private func save() {
        UserDefaults.standard.set(items, forKey: Self.key)
    }
}
