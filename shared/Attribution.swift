import SwiftUI

/// Unsplash API 规范要求的署名：「Photo by 摄影师 on Unsplash」，
/// 摄影师链到他的 Unsplash 主页，Unsplash 链到 Unsplash，链接都带 UTM。
struct Attribution: View {
    enum Style {
        /// 卡片角标：「摄影师 / Unsplash」，一行，适合窄列。
        case compact
        /// 预览里：两行「Photo by 摄影师」「on Unsplash」。
        case full
    }

    let photo: Photo
    var style: Style = .full
    var onDark = false

    var body: some View {
        switch style {
        case .compact:
            HStack(spacing: 3) {
                Link(photo.user.name, destination: photo.photographerURL)
                    .lineLimit(1)
                Text("/")
                Link("Unsplash", destination: UnsplashLink.home)
                    .layoutPriority(1)
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(onDark ? Color.white : Color.primary)
            .tint(onDark ? Color.white : nil)
        case .full:
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 3) {
                    Text("Photo by")
                    Link(photo.user.name, destination: photo.photographerURL).lineLimit(1)
                }
                HStack(spacing: 3) {
                    Text("on")
                    Link("Unsplash", destination: UnsplashLink.home)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
