import SwiftUI

/// 瀑布流 + 预览 sheet，发现页和收藏页共用。
struct PhotoGridView: View {
    let photos: [Photo]
    var footer: AnyView? = nil
    var onNearEnd: (() -> Void)? = nil

    @Environment(FavoritesStore.self) private var favorites
    @State private var viewing: Photo?

    var body: some View {
        let tail = Set(photos.suffix(6).map(\.id))
        MasonryGrid(
            photos: photos,
            minColumnWidth: 150,
            preferEvenColumns: true,
            spacing: 10,
            padding: 12,
            footer: footer
        ) { photo, _ in
            PhotoCard(
                photo: photo,
                isFavorite: favorites.contains(photo),
                onOpen: { viewing = photo },
                onToggleFavorite: { favorites.toggle(photo) }
            )
            .onAppear { if tail.contains(photo.id) { onNearEnd?() } }
        }
        .sheet(item: $viewing) { photo in
            ViewerView(photo: photo)
        }
    }
}
