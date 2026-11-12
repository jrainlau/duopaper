import Nuke
import SwiftUI

@main
struct DuopaperApp: App {
    @State private var favorites = FavoritesStore()
    @State private var history = SearchHistoryStore()

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
        }
        .defaultSize(width: 1100, height: 760)
        .commands { SidebarCommands() }

        Settings {
            SettingsView()
                .tint(Color.appPrimary)
                .environment(history)
        }
    }
}
