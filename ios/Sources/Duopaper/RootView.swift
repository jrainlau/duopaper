import SwiftUI

private enum AppTab: Hashable {
    case discover, favorites, settings
}

/// 标准 TabView，固定为 Tab 栏样式（不用侧边栏，避免占掉内屏左侧一大块空间）。
/// iPhone Duo 上 Tab 栏会按系统规则放到侧边的竖条里，和工具栏在一起。
struct RootView: View {
    @State private var tab: AppTab = .discover
    @Environment(ViewerState.self) private var viewer

    var body: some View {
        ZStack {
            tabs
                .allowsHitTesting(viewer.photo == nil)
                .disabled(viewer.photo != nil)

            if let photo = viewer.photo {
                ViewerOverlay(photo: photo) { viewer.photo = nil }
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .animation(.spring(duration: 0.35), value: viewer.photo?.id)
    }

    private var tabs: some View {
        TabView(selection: $tab) {
            Tab("发现", systemImage: "photo.on.rectangle.angled", value: AppTab.discover) {
                DiscoverView()
            }
            Tab("收藏", systemImage: "star", value: AppTab.favorites) {
                FavoritesView()
            }
            Tab("设置", systemImage: "gearshape", value: AppTab.settings) {
                SettingsView()
            }
        }
        .tabViewStyle(.tabBarOnly)
    }
}
