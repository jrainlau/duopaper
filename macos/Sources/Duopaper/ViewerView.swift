import SwiftUI

struct ViewerView: View {
    let photo: Photo
    let accessKey: String

    @Environment(FavoritesStore.self) private var favorites
    @Environment(\.dismiss) private var dismiss
    @AppStorage("downloadSize") private var sizeRaw = DownloadSize.standard.rawValue
    @State private var downloading = false
    @State private var errorMessage: String?

    private var isFavorite: Bool { favorites.contains(photo) }

    var body: some View {
        VStack(spacing: 0) {
            image
            Divider()
            bar
        }
        .frame(minWidth: 640, idealWidth: 940, minHeight: 460, idealHeight: 660)
        .alert("下载失败", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("好") {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var image: some View {
        Rectangle()
            .fill(.quaternary)
            .overlay {
                AsyncImage(url: UnsplashClient.previewURL(photo)) { phase in
                    switch phase {
                    case let .success(image):
                        image.resizable().scaledToFit()
                    case .failure:
                        Image(systemName: "photo").font(.largeTitle).foregroundStyle(.secondary)
                    default:
                        AsyncImage(url: UnsplashClient.thumbURL(photo)) { thumb in
                            if let img = thumb.image { img.resizable().scaledToFit() }
                        }
                        .overlay { ProgressView().controlSize(.regular) }
                    }
                }
            }
    }

    private var bar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(photo.user.name).font(.headline).lineLimit(1)
                Link("在 Unsplash 查看", destination: photo.links.html).font(.caption)
            }
            Spacer()
            Button {
                favorites.toggle(photo)
            } label: {
                Label(isFavorite ? "取消收藏" : "收藏", systemImage: isFavorite ? "star.fill" : "star")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(isFavorite ? Color.yellow : Color.primary)
            }
            .help(isFavorite ? "取消收藏" : "收藏")

            Picker("清晰度", selection: $sizeRaw) {
                ForEach(DownloadSize.allCases) { Text($0.title).tag($0.rawValue) }
            }
            .frame(width: 150)

            Button {
                download()
            } label: {
                if downloading {
                    ProgressView().controlSize(.small)
                } else {
                    Label("下载", systemImage: "arrow.down.circle")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(downloading)

            Button("完成") { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
        .padding(12)
        .background(.bar)
    }

    private func download() {
        let size = DownloadSize(rawValue: sizeRaw) ?? .standard
        downloading = true
        Task {
            defer { downloading = false }
            do { try await WallpaperStore.download(photo, size: size, key: accessKey) }
            catch { errorMessage = error.localizedDescription }
        }
    }
}
