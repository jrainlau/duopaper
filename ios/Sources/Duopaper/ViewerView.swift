import Observation
import Photos
import SwiftUI

/// 当前正在预览的图片。放在根视图的浮层里展示，这样蒙层能盖住 Tab 栏和工具栏。
@MainActor
@Observable
final class ViewerState {
    var photo: Photo?
}

/// 预览浮层：半透明黑色蒙层 + 宽度贴合原图的卡片，原图下方留一条工具栏放按钮。
/// 点蒙层关闭。
struct ViewerOverlay: View {
    let photo: Photo
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onClose)
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("关闭预览")

            GeometryReader { geo in
                let barHeight: CGFloat = 60
                let margin: CGFloat = 16
                let ratio = CGFloat(photo.width) / CGFloat(photo.height)
                let maxWidth = geo.size.width - margin * 2
                let maxImageHeight = geo.size.height - margin * 2 - barHeight
                let imageWidth = max(1, min(maxWidth, maxImageHeight * ratio))
                let cardWidth = max(imageWidth, min(maxWidth, 340))

                ViewerCard(photo: photo, imageWidth: imageWidth, imageHeight: imageWidth / ratio, barHeight: barHeight)
                    .frame(width: cardWidth)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
    }
}

private struct ViewerCard: View {
    let photo: Photo
    let imageWidth: CGFloat
    let imageHeight: CGFloat
    let barHeight: CGFloat

    @AppStorage("accessKey") private var accessKey = ""
    @AppStorage("downloadSize") private var sizeRaw = DownloadSize.standard.rawValue
    @Environment(FavoritesStore.self) private var favorites
    @State private var downloading = false
    @State private var toast: String?

    private var isFavorite: Bool { favorites.contains(photo) }
    private var size: DownloadSize { DownloadSize(rawValue: sizeRaw) ?? .standard }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                photo.tint
                RemoteImage(url: UnsplashClient.thumbURL(photo), tint: .clear, contentMode: .fill)
                RemoteImage(url: UnsplashClient.previewURL(photo), tint: .clear, contentMode: .fill)
            }
            .frame(width: imageWidth, height: imageHeight)
            .clipped()
            .overlay(alignment: .top) {
                if let toast {
                    Text(toast)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassEffect()
                        .padding(.top, 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }

            bar
        }
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 30, y: 10)
        .animation(.spring(duration: 0.35), value: toast)
    }

    private var bar: some View {
        HStack(spacing: 10) {
            Text(photo.user.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            Spacer(minLength: 8)

            Button { favorites.toggle(photo) } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? Color.yellow : Color.primary)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.glass)
            .accessibilityLabel(isFavorite ? "取消收藏" : "收藏")

            Menu {
                Picker("清晰度", selection: $sizeRaw) {
                    ForEach(DownloadSize.allCases) { Text($0.title).tag($0.rawValue) }
                }
            } label: {
                Text(size.title).frame(minWidth: 30)
            }
            .buttonStyle(.glass)
            .accessibilityLabel("清晰度")

            Button(action: download) {
                Group {
                    if downloading { ProgressView() } else { Image(systemName: "arrow.down.circle") }
                }
                .frame(width: 22, height: 22)
            }
            .buttonStyle(.glassProminent)
            .disabled(downloading)
            .accessibilityLabel("保存到相册")
        }
        .padding(.horizontal, 14)
        .frame(height: barHeight)
    }

    private func download() {
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
