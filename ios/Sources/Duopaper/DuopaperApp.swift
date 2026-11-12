import Nuke
import SwiftUI

@main
struct DuopaperApp: App {
    @State private var favorites = FavoritesStore()

    init() {
        ImagePipeline.shared = ImagePipeline(configuration: .withDataCache(name: "com.jrainlau.duopaper.images", sizeLimit: 512 << 20))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(favorites)
        }
    }
}
