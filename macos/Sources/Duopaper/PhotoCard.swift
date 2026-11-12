import SwiftUI

struct PhotoCard: View {
    let photo: Photo
    let isDownloading: Bool
    let onDownload: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: onDownload) {
            Color.clear
                .aspectRatio(3 / 2, contentMode: .fit)
                .overlay {
                    AsyncImage(url: UnsplashClient.displayURL(photo)) { phase in
                        switch phase {
                        case let .success(image):
                            image.resizable().scaledToFill()
                        case .failure:
                            Image(systemName: "photo").font(.largeTitle).foregroundStyle(.secondary)
                        default:
                            Rectangle().fill(.quaternary).overlay { ProgressView().controlSize(.small) }
                        }
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    if hovering || isDownloading {
                        HStack(spacing: 8) {
                            if isDownloading { ProgressView().controlSize(.small) }
                            Text(photo.user.name).font(.callout).lineLimit(1)
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.down.circle")
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(.regularMaterial)
                        .transition(.opacity)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering)
        .help("下载 \(photo.user.name) 的壁纸")
        .accessibilityLabel("下载 \(photo.user.name) 的壁纸")
        .contextMenu {
            Button("下载", systemImage: "arrow.down.circle", action: onDownload)
            Link(destination: photo.links.html) {
                Label("在 Unsplash 中打开", systemImage: "safari")
            }
        }
    }
}
