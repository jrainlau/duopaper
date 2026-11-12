import Photos
import SwiftUI

/// 预览 sheet：用标准 NavigationStack + 工具栏，Duo 上工具栏会按系统规则自动移到侧边。
/// 没有关闭按钮，下拉 sheet 即可关闭；收藏、清晰度、下载都在右下角。
struct ViewerView: View {
    let photo: Photo

    @AppStorage("accessKey") private var accessKey = ""
    @AppStorage("downloadSize") private var sizeRaw = DownloadSize.standard.rawValue
    @Environment(FavoritesStore.self) private var favorites
    @State private var downloading = false
    @State private var toast: String?

    private var isFavorite: Bool { favorites.contains(photo) }

    var body: some View {
        NavigationStack {
            ZStack {
                photo.tint.opacity(0.25).ignoresSafeArea()
                RemoteImage(url: UnsplashClient.thumbURL(photo), tint: .clear, contentMode: .fit)
                RemoteImage(url: UnsplashClient.previewURL(photo), tint: .clear, contentMode: .fit)
            }
            .overlay(alignment: .top) {
                if let toast {
                    Text(toast)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassEffect()
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.35), value: toast)
            .navigationTitle(photo.user.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()

                    Button(isFavorite ? "取消收藏" : "收藏", systemImage: isFavorite ? "star.fill" : "star") {
                        favorites.toggle(photo)
                    }
                    .tint(isFavorite ? .yellow : nil)

                    Picker("清晰度", selection: $sizeRaw) {
                        ForEach(DownloadSize.allCases) { Text($0.title).tag($0.rawValue) }
                    }
                    .pickerStyle(.menu)

                    Button(action: download) {
                        if downloading {
                            ProgressView()
                        } else {
                            Label("保存到相册", systemImage: "arrow.down.circle")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(downloading)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func download() {
        let size = DownloadSize(rawValue: sizeRaw) ?? .standard
        downloading = true
        Task {
            defer { downloading = false }
            do {
                let file = try await WallpaperStore.download(photo, size: size, key: accessKey, into: FileManager.default.temporaryDirectory)
                defer { try? FileManager.default.removeItem(at: file) }
                try await saveToPhotos(file)
                show("已保存到相册")
            } catch {
                show("保存失败：\(error.localizedDescription)")
            }
        }
    }

    private func show(_ text: String) {
        toast = text
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            if toast == text { toast = nil }
        }
    }

    private func saveToPhotos(_ file: URL) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw NSError(domain: "Duopaper", code: 1, userInfo: [NSLocalizedDescriptionKey: "没有相册写入权限，请在系统设置中允许。"])
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.forAsset().addResource(with: .photo, fileURL: file, options: nil)
        }
    }
}
