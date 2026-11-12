import NukeUI
import SwiftUI

/// 基于 Nuke 的远程图：内存 + 磁盘缓存，加载失败自动重试，淡入显示。
struct RemoteImage: View {
    let url: URL
    var tint: Color = Color.gray.opacity(0.25)
    var contentMode: ContentMode = .fill

    @State private var attempt = 0

    var body: some View {
        LazyImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.25))) { state in
            if let image = state.image {
                image.resizable().aspectRatio(contentMode: contentMode)
            } else if state.error != nil {
                tint
                    .overlay { Image(systemName: "arrow.clockwise").foregroundStyle(.secondary) }
                    .task {
                        guard attempt < 3 else { return }
                        try? await Task.sleep(for: .seconds(1.5))
                        attempt += 1
                    }
            } else {
                tint
            }
        }
        .id(attempt)
    }
}
