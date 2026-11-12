import SwiftUI

private enum AppTab: Hashable {
    case discover, favorites, settings
}

/// 标准 TabView：iPhone 外屏是底部 Tab 栏；Duo 内屏（regular 宽度）自动变成可收起的侧边栏，
/// 横屏 / 分屏时 Tab 栏会按系统规则移到侧边，不需要自己处理。
struct RootView: View {
    @State private var tab: AppTab = .discover

    var body: some View {
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
        .tabViewStyle(.sidebarAdaptable)
        .modifier(DuoSidebarPlacement())
    }
}

/// iOS 27.1+：iPhone Duo 内屏默认使用侧边栏导航；更早的系统保持系统默认。
private struct DuoSidebarPlacement: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            content.defaultTabBarPlacement(.sidebar)
        } else {
            content
        }
    }
}
