import SwiftUI

struct PhotoCard: View {
    let photo: Photo
    let isFavorite: Bool
    let onOpen: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        Rectangle()
            .fill(photo.tint)
            .overlay { RemoteImage(url: photo.thumbURL, tint: photo.tint) }
            .overlay(alignment: .bottomLeading) {
                // Unsplash 要求展示图片时署名并链到摄影师主页；触屏没有 hover，所以常驻。
                Attribution(photo: photo, style: .compact, onDark: true)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
                    .padding(.top, 22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .top, endPoint: .bottom))
            }
            .overlay(alignment: .topTrailing) {
                if isFavorite {
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isFavorite ? Color.yellow : Color.white)
                        .frame(width: 28, height: 28)
                        .background(.black.opacity(0.32), in: Circle())
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L("favorites.remove"))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onTapGesture(perform: onOpen)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(L("card.wallpaperBy", ["name": photo.user.name]))
            .accessibilityAddTraits(.isButton)
            .contextMenu {
                Button(L("card.preview"), systemImage: "eye", action: onOpen)
                Button(isFavorite ? L("favorites.remove") : L("favorites.add"), systemImage: isFavorite ? "star.slash" : "star", action: onToggleFavorite)
                Link(destination: photo.pageURL) {
                    Label(photo.source == .unsplash ? L("card.openInUnsplash") : L("card.openInPexels"), systemImage: "safari")
                }
            }
    }
}
