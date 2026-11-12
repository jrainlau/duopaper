import SwiftUI

/// 瀑布流，发现页和收藏页共用；点图片在根视图弹出预览浮层。
struct PhotoGridView: View {
    let photos: [Photo]
    var footer: AnyView? = nil
    var onNearEnd: (() -> Void)? = nil

    @Environment(FavoritesStore.self) private var favorites
    @Environment(ViewerState.self) private var viewer

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
                onOpen: { viewer.photo = photo },
                onToggleFavorite: { favorites.toggle(photo) }
            )
            .onAppear { if tail.contains(photo.id) { onNearEnd?() } }
        }
    }
}
