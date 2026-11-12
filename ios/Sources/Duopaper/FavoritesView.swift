import SwiftUI

struct FavoritesView: View {
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        NavigationStack {
            Group {
                if favorites.photos.isEmpty {
                    ContentUnavailableView("还没有收藏", systemImage: "star", description: Text("点图片右上角的星即可收藏。"))
                } else {
                    PhotoGridView(photos: favorites.photos)
                }
            }
            .navigationTitle("收藏")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
