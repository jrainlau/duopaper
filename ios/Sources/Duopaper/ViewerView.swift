import Observation
import Photos
import SwiftUI

/// 当前正在预览的图片，以及展开 / 收起的进度。
/// 蒙层和卡片是两层，都由 `shown` 驱动：蒙层只渐显渐隐，卡片缩放加透明度。
@MainActor
@Observable
final class ViewerState {
    var photo: Photo?
    var shown = false
    private var closing = false

    func open(_ photo: Photo) {
        guard self.photo == nil else { return }
        closing = false
        shown = false
        self.photo = photo
    }

    func close() {
        guard photo != nil, !closing else { return }
        closing = true
        withAnimation(.easeIn(duration: 0.16)) { shown = false }
        Task {
            try? await Task.sleep(for: .milliseconds(170))
            photo = nil
            closing = false
        }
    }
}

/// 蒙层：只做渐显 / 渐隐，不缩放；点击立即开始关闭。
struct ViewerDim: View {
    let shown: Bool
    let onTap: () -> Void

    var body: some View {
        Color.black.opacity(shown ? 0.5 : 0)
            .animation(shown ? .easeOut(duration: 0.3) : .easeIn(duration: 0.16), value: shown)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("关闭预览")
    }
}

/// 预览卡片：宽度贴合原图，原图下方留一条工具栏放按钮。
/// 展开只做一件事：用同一条平滑曲线同时改缩放和透明度，不动布局，所以全程没有速度突变。
struct ViewerOverlay: View {
    let photo: Photo
    let shown: Bool
    let onClose: () -> Void

    var body: some View {
        GeometryReader { geo in
            let barHeight: CGFloat = 60
            let hMargin: CGFloat = 16
            // 上下取两端安全区的较大值做对称边距，卡片才会真正垂直居中。
            let vMargin = max(16, geo.safeAreaInsets.top, geo.safeAreaInsets.bottom)
            let ratio = CGFloat(photo.width) / CGFloat(photo.height)
            let maxWidth = geo.size.width - hMargin * 2
            let maxImageHeight = geo.size.height - vMargin * 2 - barHeight
            let imageWidth = max(1, min(maxWidth, maxImageHeight * ratio))
            let cardWidth = max(imageWidth, min(maxWidth, 340))

            ViewerCard(photo: photo, imageWidth: imageWidth, imageHeight: imageWidth / ratio, barHeight: barHeight, onClose: onClose)
                .frame(width: cardWidth)
                .scaleEffect(shown ? 1 : 0.9)
                .opacity(shown ? 1 : 0)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .ignoresSafeArea(.container, edges: .vertical)
    }
}

private struct ViewerCard: View {
    let photo: Photo
    let imageWidth: CGFloat
    let imageHeight: CGFloat
    let barHeight: CGFloat
    let onClose: () -> Void

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
            .overlay(alignment: .topTrailing) {
                Button(action: onClose) {
                    Image(systemName: "xmark").frame(width: 22, height: 22)
                }
                .buttonStyle(.glass)
                .padding(12)
                .accessibilityLabel("关闭")
            }
            .overlay(alignment: .top) {
                if let toast {
                    Text(toast)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassEffect()
                        .padding(.top, 14)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }

            bar
        }
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 30, y: 10)
        .animation(.smooth(duration: 0.25), value: toast)
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
