import AppKit
import SwiftUI

struct ViewerView: View {
    let photo: Photo
    let accessKey: String
    let onClose: () -> Void

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
        .alert(L("viewer.downloadFailed"), isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button(L("common.ok")) {}
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
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 28, height: 28)
                    .background(.regularMaterial, in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(12)
            .help(L("common.close"))
            .accessibilityLabel(L("common.close"))
        }
    }

    private var bar: some View {
        HStack(spacing: 12) {
            Attribution(photo: photo, style: .full)
            Spacer()
            Button {
                favorites.toggle(photo)
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? Color.yellow : Color.primary)
            }
            .controlSize(.large)
            .help(isFavorite ? L("favorites.remove") : L("favorites.add"))
            .accessibilityLabel(isFavorite ? L("favorites.remove") : L("favorites.add"))

            Picker(L("viewer.quality"), selection: $sizeRaw) {
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
                    Label(L("viewer.download"), systemImage: "arrow.down.circle")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appPrimary)
            .foregroundStyle(Color.appOnPrimary)
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
            do {
                let dir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
                let file = try await WallpaperStore.download(photo, size: size, into: dir)
                NSWorkspace.shared.activateFileViewerSelecting([file])
            }
            catch { errorMessage = error.localizedDescription }
        }
    }
}
