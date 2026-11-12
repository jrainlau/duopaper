import SwiftUI

enum SidebarItem: Hashable {
    case favorites
    case topic(String)
    case history(String)
}

struct ContentView: View {
    @AppStorage("accessKey") private var accessKey = ""
    @AppStorage("query") private var query = "wallpaper"
    @AppStorage("orientation") private var orientationRaw = ""

    @Environment(FavoritesStore.self) private var favorites
    @Environment(SearchHistoryStore.self) private var history
    @Environment(\.openSettings) private var openSettings
    @State private var store = WallpaperStore()
    @State private var searchText = ""
    @State private var sidebar: SidebarItem?
    @State private var refreshToken = 0
    @State private var viewing: Photo?

    private var orientation: Orientation { Orientation(rawValue: orientationRaw) ?? .any }
    private var showingFavorites: Bool { sidebar == .favorites }

    private struct LoadID: Equatable {
        let key: String, query: String, orientation: String, token: Int
    }

    var body: some View {
        ZStack {
            browser
                .allowsHitTesting(viewing == nil)
                .disabled(viewing != nil)

            if let photo = viewing {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { viewing = nil }
                    .transition(.opacity)

                GeometryReader { geo in
                    ViewerView(photo: photo, accessKey: accessKey) { viewing = nil }
                        .frame(width: min(geo.size.width * 0.84, 1180), height: min(geo.size.height * 0.84, 800))
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
                .allowsHitTesting(true)
                .transition(.scale(scale: 0.96).combined(with: .opacity))

                Button("") { viewing = nil }
                    .keyboardShortcut(.cancelAction)
                    .frame(width: 0, height: 0)
                    .opacity(0)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewing?.id)
    }

    private var browser: some View {
        NavigationSplitView {
            List(selection: $sidebar) {
                Section {
                    Label(L("tab.favorites"), systemImage: "star")
                        .tag(SidebarItem.favorites)
                }
                Section(L("discover.categories")) {
                    ForEach(Topic.pinned) { t in
                        Label(t.title, systemImage: t.symbol)
                        .tag(SidebarItem.topic(t.query))
                    }
                }
                if !history.items.isEmpty {
                    Section(L("discover.history")) {
                        ForEach(history.items, id: \.self) { item in
                            Label(item, systemImage: "clock.arrow.circlepath")
                                .tag(SidebarItem.history(item))
                                .contextMenu {
                                    Button(L("history.remove"), systemImage: "trash") {
                                        if let i = history.items.firstIndex(of: item) { history.remove(at: IndexSet(integer: i)) }
                                    }
                                }
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 190, max: 260)
        } detail: {
            detail
                .background(Color.appBackground)
                .navigationTitle(title)
                .navigationSubtitle(subtitle)
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: L("discover.search"))
        .onSubmit(of: .search) {
            let q = searchText.trimmingCharacters(in: .whitespaces)
            query = q.isEmpty ? "wallpaper" : q
            if !q.isEmpty && !Topic.pinned.contains(where: { $0.query == q.lowercased() }) { history.add(q) }
            sidebar = sidebarItem(for: query)
            refreshToken += 1
        }
        .toolbar {
            ToolbarItem {
                Picker(L("discover.filter"), selection: $orientationRaw) {
                    ForEach(Orientation.allCases) { Text($0.title).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
                .disabled(showingFavorites)
            }
            ToolbarItem {
                Button(L("discover.shuffle"), systemImage: "arrow.clockwise") { refreshToken += 1 }
                    .keyboardShortcut("r")
                    .help(L("discover.shuffleHint"))
                    .disabled(showingFavorites)
            }
        }
        .task(id: LoadID(key: accessKey, query: query, orientation: orientationRaw, token: refreshToken)) {
            await store.reload(key: accessKey, source: .unsplash, query: query, orientation: orientation)
        }
        .onChange(of: sidebar) { _, new in
            switch new {
            case let .topic(q), let .history(q):
                if q != query { query = q; searchText = "" }
            default: break
            }
        }
        .onAppear {
            sidebar = sidebarItem(for: query)
            if !Topic.pinned.contains(where: { $0.query == query }) { searchText = query }
        }
    }

    private func sidebarItem(for query: String) -> SidebarItem? {
        if let t = Topic.pinned.first(where: { $0.query == query.lowercased() }) { return .topic(t.query) }
        if let h = history.items.first(where: { $0.caseInsensitiveCompare(query) == .orderedSame }) { return .history(h) }
        return nil
    }

    private var title: String {
        showingFavorites ? L("tab.favorites") : (Topic.all.first { $0.query == query }?.title ?? query)
    }

    private var subtitle: String {
        if showingFavorites { return favorites.photos.isEmpty ? "" : L("favorites.count", ["n": "\(favorites.photos.count)"]) }
        return store.total > 0 ? "\(store.photos.count) / \(store.total)" : ""
    }

    @ViewBuilder
    private var detail: some View {
        if showingFavorites {
            if favorites.photos.isEmpty {
                ContentUnavailableView(L("favorites.empty.title"), systemImage: "star", description: Text(L("favorites.empty.body.hover")))
            } else {
                grid(favorites.photos, paginated: false)
            }
        } else {
            switch store.phase {
            case .idle where accessKey.isEmpty:
                ContentUnavailableView {
                    Label(L("discover.noKey.title"), systemImage: "key")
                } description: {
                    Text(L("discover.noKey.body"))
                } actions: {
                    Button { openSettings() } label: { Text(L("discover.openSettings")).foregroundStyle(Color.appOnPrimary) }.buttonStyle(.borderedProminent)
                }
            case .idle, .loading:
                ProgressView(L("discover.loading")).frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .failed(message):
                ContentUnavailableView {
                    Label(L("discover.loadFailed"), systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button(L("common.retry")) { refreshToken += 1 }
                }
            case .ready where store.photos.isEmpty:
                ContentUnavailableView.search(text: query)
            case .ready:
                grid(store.photos, paginated: true)
            }
        }
    }

    private func grid(_ photos: [Photo], paginated: Bool) -> some View {
        let tail = Set(photos.suffix(6).map(\.id))
        return MasonryGrid(
            photos: photos,
            footer: paginated && store.loadingMore ? AnyView(ProgressView().controlSize(.small)) : nil
        ) { photo, _ in
            PhotoCard(
                photo: photo,
                isFavorite: favorites.contains(photo),
                onOpen: { viewing = photo },
                onToggleFavorite: { favorites.toggle(photo) }
            )
            .onAppear {
                if paginated && tail.contains(photo.id) {
                    Task { await store.loadMore(key: accessKey, source: .unsplash, query: query, orientation: orientation) }
                }
            }
        }
    }
}
