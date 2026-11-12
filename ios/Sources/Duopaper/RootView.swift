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
                ViewerOverlay(
                    photo: photo,
                    shown: viewer.shown,
                    onDelete: viewer.onDelete.map { delete in { delete(photo); viewer.close() } }
                ) { viewer.close() }
                    .onAppear {
                        withAnimation(.smooth(duration: 0.38)) { viewer.shown = true }
                    }
            }
        }
        // 外部 URL scheme 入口：
        // duopaper://favorites 回到收藏页；duopaper://photo/<id> 是小组件「打开 App」模式，用 Viewer 弹出这张图。
        .onOpenURL { url in
            guard url.scheme == "duopaper" else { return }
            if url.host == "photo" { openWidgetPhoto(id: url.lastPathComponent); return }
            guard url.host == "favorites" else { return }
            viewer.close()
            // 等场景激活的转场结束后再切换，并且不带动画，避免在转场中途改选中项。
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(60))
                var transaction = Transaction(animation: nil)
                transaction.disablesAnimations = true
                withTransaction(transaction) { tab = .favorites }
            }
        }
        .task {
            favorites.onChange = { photos in Task { await WidgetSync.shared.sync(favorites: photos, favoritesChanged: true) } }
            await WidgetSync.shared.sync(favorites: favorites.photos)
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active { Task { await WidgetSync.shared.sync(favorites: favorites.photos) } }
        }
    }

    /// 小组件里的图可能来自收藏，也可能来自关键词缓存，两边都找一下。
    private func openWidgetPhoto(id: String) {
        guard let photo = favorites.photos.first(where: { $0.id == id }) ?? WidgetSource.photo(id: id) else { return }
        Task { @MainActor in
            // 已经开着别的预览时，先收起再开新的；冷启动时等场景激活转场结束。
            if viewer.photo != nil {
                viewer.close()
                try? await Task.sleep(for: .milliseconds(250))
            } else {
                try? await Task.sleep(for: .milliseconds(60))
            }
            viewer.open(photo)
        }
    }

    private var tabs: some View {
        TabView(selection: $tab) {
            Tab(L("tab.discover"), systemImage: "photo.on.rectangle.angled", value: AppTab.discover) {
                DiscoverView()
            }
            Tab(L("tab.favorites"), systemImage: "star", value: AppTab.favorites) {
                FavoritesView()
            }
            Tab(L("tab.settings"), systemImage: "gearshape", value: AppTab.settings) {
                SettingsView(onVerified: { tab = .discover })
            }
        }
        .tabViewStyle(.tabBarOnly)
    }
}
