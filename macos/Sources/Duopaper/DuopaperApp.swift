import Nuke
import SwiftUI

@main
struct DuopaperApp: App {
    @State private var favorites = FavoritesStore()
    @State private var history = SearchHistoryStore()
    // 语言切换时用 .id 强制重建视图树，让所有文案重新取值。
    @AppStorage(LanguageStore.storageKey) private var language = AppLanguage.system.rawValue

    init() {
        ImagePipeline.shared = ImagePipeline(configuration: .withDataCache(name: "com.jrainlau.duopaper.images", sizeLimit: 1 << 30))
    }

    var body: some Scene {
        WindowGroup("Duopaper", id: "main") {
            ContentView()
                .environment(favorites)
                .environment(history)
                .tint(Color.appPrimary)
                .frame(minWidth: 760, minHeight: 520)
                .id(language)
        }
        .defaultSize(width: 1100, height: 760)
        .commands { SidebarCommands() }

        Settings {
            SettingsView()
                .tint(Color.appPrimary)
                .environment(history)
                .id(language)
        }
    }
}
