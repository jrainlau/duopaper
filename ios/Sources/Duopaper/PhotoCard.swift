import SwiftUI

struct PhotoCard: View {
    let photo: Photo
    let isFavorite: Bool
    let onOpen: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        Rectangle()
            .fill(photo.tint)
            .overlay { RemoteImage(url: UnsplashClient.thumbURL(photo), tint: photo.tint) }
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
                .accessibilityLabel("取消收藏")
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onTapGesture(perform: onOpen)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(photo.user.name) 的壁纸")
            .accessibilityAddTraits(.isButton)
            .contextMenu {
                Button("预览", systemImage: "eye", action: onOpen)
                Button(isFavorite ? "取消收藏" : "收藏", systemImage: isFavorite ? "star.slash" : "star", action: onToggleFavorite)
                Link(destination: photo.pageURL) {
                    Label("在 Unsplash 中打开", systemImage: "safari")
                }
            }
    }
}
