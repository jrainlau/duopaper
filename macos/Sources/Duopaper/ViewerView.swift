import SwiftUI

struct ViewerView: View {
    let photo: Photo
    let accessKey: String

    @Environment(FavoritesStore.self) private var favorites
    @AppStorage("downloadSize") private var sizeRaw = DownloadSize.standard.rawValue
    @State private var downloading = false
    @State private var errorMessage: String?

    private var isFavorite: Bool { favorites.contains(photo) }

    var body: some View {
        VStack(spacing: 0) {
            image
            bar
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(0.12))
        }
        .shadow(color: .black.opacity(0.45), radius: 40, y: 16)
        .alert("下载失败", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("好") {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var image: some View {
        ZStack {
            photo.tint.opacity(0.35)
            RemoteImage(url: UnsplashClient.thumbURL(photo), tint: .clear, contentMode: .fit)
            RemoteImage(url: UnsplashClient.previewURL(photo), tint: .clear, contentMode: .fit)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
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
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? Color.yellow : Color.primary)
            }
            .controlSize(.large)
            .help(isFavorite ? "取消收藏" : "收藏")
            .accessibilityLabel(isFavorite ? "取消收藏" : "收藏")

            Picker("清晰度", selection: $sizeRaw) {
                ForEach(DownloadSize.allCases) { Text($0.title).tag($0.rawValue) }
            }
            .controlSize(.large)
            .frame(width: 160)

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
            .controlSize(.large)
            .disabled(downloading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
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
