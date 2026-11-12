import SwiftUI

struct PhotoCard: View {
    let photo: Photo
    let isFavorite: Bool
    let onOpen: () -> Void
    let onToggleFavorite: () -> Void

    @State private var hovering = false

    var body: some View {
        Rectangle()
            .fill(.quaternary)
            .overlay {
                AsyncImage(url: UnsplashClient.thumbURL(photo)) { phase in
                    switch phase {
                    case let .success(image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: "photo").font(.title).foregroundStyle(.secondary)
                    default:
                        ProgressView().controlSize(.small)
                    }
                }
            }
            .overlay {
                if hovering && !isFavorite {
                    Color.black.opacity(0.3).transition(.opacity)
                }
            }
            .overlay(alignment: .topTrailing) {
                if hovering || isFavorite {
                    Button(action: onToggleFavorite) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .font(.title3)
                            .foregroundStyle(isFavorite ? Color.yellow : Color.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
                            .padding(8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(isFavorite ? "取消收藏" : "收藏")
                    .accessibilityLabel(isFavorite ? "取消收藏" : "收藏")
                    .transition(.opacity)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .onHover { hovering = $0 }
            .animation(.easeOut(duration: 0.15), value: hovering)
            .onTapGesture(perform: onOpen)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(photo.user.name) 的壁纸")
            .accessibilityAddTraits(.isButton)
            .contextMenu {
                Button("预览", systemImage: "eye", action: onOpen)
                Button(isFavorite ? "取消收藏" : "收藏", systemImage: isFavorite ? "star.slash" : "star", action: onToggleFavorite)
                Link(destination: photo.links.html) {
                    Label("在 Unsplash 中打开", systemImage: "safari")
                }
            }
    }
}
