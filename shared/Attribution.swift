import SwiftUI

/// 署名：「Photo by 摄影师 on Unsplash / Pexels」，
/// 摄影师链到他的主页，品牌名链到图源官网；Unsplash 的链接带 UTM（API 规范要求）。
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
                Link(photo.source.title, destination: photo.source.home)
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
                    Link(photo.source.title, destination: photo.source.home)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
