import SwiftUI
import WidgetKit

private enum AppTab: Hashable {
    case discover, favorites, settings
}

/// 标准 TabView，固定为 Tab 栏样式（不用侧边栏，避免占掉内屏左侧一大块空间）。
/// iPhone Duo 上 Tab 栏会按系统规则放到侧边的竖条里，和工具栏在一起。
struct RootView: View {
    @State private var tab: AppTab = .discover
    @Environment(ViewerState.self) private var viewer
    @Environment(FavoritesStore.self) private var favorites
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            tabs
                .allowsHitTesting(viewer.photo == nil)
                .disabled(viewer.photo != nil)

            if let photo = viewer.photo {
                ViewerDim(shown: viewer.shown) { viewer.close() }
                ViewerOverlay(photo: photo, shown: viewer.shown) { viewer.close() }
                    .onAppear {
                        withAnimation(.smooth(duration: 0.38)) { viewer.shown = true }
                    }
            }
        }
        // 小组件点击：duopaper://favorites 直接回到收藏页。
        .onOpenURL { url in
            guard url.scheme == "duopaper", url.host == "favorites" else { return }
            viewer.close()
            tab = .favorites
        }
        .task {
            favorites.onChange = { photos in Task { await WidgetSync.shared.sync(photos) } }
            await WidgetSync.shared.sync(favorites.photos)
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active { Task { await WidgetSync.shared.sync(favorites.photos) } }
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
