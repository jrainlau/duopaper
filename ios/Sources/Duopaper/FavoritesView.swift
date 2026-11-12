import SwiftUI

struct FavoritesView: View {
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        NavigationStack {
            Group {
                if favorites.photos.isEmpty {
                    ContentUnavailableView(L("favorites.empty.title"), systemImage: "star", description: Text(L("favorites.empty.body")))
                } else {
                    PhotoGridView(photos: favorites.photos)
                }
            }
            .background(Color.appBackground)
            .navigationTitle(L("tab.favorites"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
