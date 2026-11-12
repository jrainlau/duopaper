import SwiftUI

@main
struct DuopaperApp: App {
    @State private var favorites = FavoritesStore()

    init() {
        URLCache.shared = URLCache(memoryCapacity: 128 << 20, diskCapacity: 1 << 30)
    }

    var body: some Scene {
        WindowGroup("Duopaper") {
            ContentView()
                .environment(favorites)
                .frame(minWidth: 760, minHeight: 520)
        }
        .defaultSize(width: 1100, height: 760)
        .commands { SidebarCommands() }

        Settings {
            SettingsView()
        }
    }
}
