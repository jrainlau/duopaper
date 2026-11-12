import Nuke
import SwiftUI

@main
struct DuopaperApp: App {
    @State private var favorites = FavoritesStore()
    @State private var viewer = ViewerState()
    @State private var history = SearchHistoryStore()
    // 语言切换时用 .id 强制重建整棵视图树，让所有文案重新取值。
    @AppStorage(LanguageStore.storageKey) private var language = AppLanguage.system.rawValue

    init() {
        ImagePipeline.shared = ImagePipeline(configuration: .withDataCache(name: "com.jrainlau.duopaper.images", sizeLimit: 512 << 20))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(favorites)
                .environment(viewer)
                .environment(history)
                .id(language)
        }
    }
}
