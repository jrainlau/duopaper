import SwiftUI

struct PhotoCard: View {
    let photo: Photo
    let isFavorite: Bool
    let onOpen: () -> Void
    let onToggleFavorite: () -> Void

    @State private var hovering = false

    var body: some View {
        Rectangle()
            .fill(photo.tint)
            .overlay { RemoteImage(url: UnsplashClient.thumbURL(photo), tint: photo.tint) }
            .overlay {
                if hovering && !isFavorite {
                    LinearGradient(
                        colors: [.black.opacity(0.35), .clear, .black.opacity(0.55)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .transition(.opacity)
                }
            }
            .overlay(alignment: .bottomLeading) {
                // 署名（Unsplash API 规范）：悬停时显示，收藏过的也显示。
                if hovering {
                    Attribution(photo: photo, style: .compact, onDark: true)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.45), in: Capsule())
                        .padding(8)
                        .transition(.opacity)
                }
            }
            .overlay(alignment: .topTrailing) {
                if hovering || isFavorite {
                    Button(action: onToggleFavorite) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isFavorite ? Color.yellow : Color.white)
                            .frame(width: 28, height: 28)
                            .background(.black.opacity(isFavorite ? 0.25 : 0.35), in: Circle())
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                    .help(isFavorite ? "取消收藏" : "收藏")
                    .accessibilityLabel(isFavorite ? "取消收藏" : "收藏")
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.white.opacity(hovering ? 0.28 : 0.08), lineWidth: 1)
            }
            .shadow(color: .black.opacity(hovering ? 0.35 : 0.15), radius: hovering ? 12 : 4, y: hovering ? 6 : 2)
            .scaleEffect(hovering ? 1.015 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .onHover { hovering = $0 }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hovering)
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
