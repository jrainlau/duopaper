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
                ViewerDim { viewer.close() }
                ViewerOverlay(photo: photo, shown: viewer.shown) { viewer.close() }
                    .onAppear {
                        withAnimation(.smooth(duration: 0.38)) { viewer.shown = true }
                    }
            }
        }
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
                SettingsView(onVerified: { tab = .discover })
            }
        }
        .tabViewStyle(.tabBarOnly)
    }
}
