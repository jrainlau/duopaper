import SwiftUI

enum SidebarItem: Hashable {
    case favorites
    case topic(String)
}

struct ContentView: View {
    @AppStorage("accessKey") private var accessKey = ""
    @AppStorage("query") private var query = "wallpaper"
    @AppStorage("orientation") private var orientationRaw = ""

    @Environment(FavoritesStore.self) private var favorites
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
                    ViewerView(photo: photo, accessKey: accessKey)
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
                    Label { Text("收藏") } icon: { Image(systemName: "star.fill").foregroundStyle(.yellow) }
                        .tag(SidebarItem.favorites)
                }
                Section("分类") {
                    ForEach(Topic.all) { t in
                        Label { Text(t.title) } icon: {
                            Image(systemName: t.symbol).symbolRenderingMode(.hierarchical).foregroundStyle(t.tint)
                        }
                        .tag(SidebarItem.topic(t.query))
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 190, max: 260)
        } detail: {
            detail
                .navigationTitle(title)
                .navigationSubtitle(subtitle)
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: "搜索")
        .onSubmit(of: .search) {
            let q = searchText.trimmingCharacters(in: .whitespaces)
            query = q.isEmpty ? "wallpaper" : q
            sidebar = Topic.all.first { $0.query == query.lowercased() }.map { .topic($0.query) }
            refreshToken += 1
        }
        .toolbar {
            ToolbarItem {
                Picker("方向", selection: $orientationRaw) {
                    ForEach(Orientation.allCases) { Text($0.title).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
                .disabled(showingFavorites)
            }
            ToolbarItem {
                Button("换一批", systemImage: "arrow.clockwise") { refreshToken += 1 }
                    .keyboardShortcut("r")
                    .help("换一批（随机取片）")
                    .disabled(showingFavorites)
            }
        }
        .task(id: LoadID(key: accessKey, query: query, orientation: orientationRaw, token: refreshToken)) {
            await store.reload(key: accessKey, query: query, orientation: orientation)
        }
        .onChange(of: sidebar) { _, new in
            if case let .topic(q) = new, q != query {
                query = q
                searchText = ""
            }
        }
        .onAppear {
            sidebar = .topic(query)
            if !Topic.all.contains(where: { $0.query == query }) { searchText = query }
        }
    }

    private var title: String {
        showingFavorites ? "收藏" : (Topic.all.first { $0.query == query }?.title ?? query)
    }

    private var subtitle: String {
        if showingFavorites { return favorites.photos.isEmpty ? "" : "\(favorites.photos.count) 张" }
        return store.total > 0 ? "\(store.photos.count) / \(store.total)" : ""
    }

    @ViewBuilder
    private var detail: some View {
        if showingFavorites {
            if favorites.photos.isEmpty {
                ContentUnavailableView("还没有收藏", systemImage: "star", description: Text("把鼠标移到图片上，点右上角的星即可收藏。"))
            } else {
                grid(favorites.photos, paginated: false)
            }
        } else {
            switch store.phase {
            case .idle where accessKey.isEmpty:
                ContentUnavailableView {
                    Label("尚未配置 Access Key", systemImage: "key")
                } description: {
                    Text("填入你的 Unsplash Access Key 后即可开始取片。")
                } actions: {
                    Button("打开设置") { openSettings() }.buttonStyle(.borderedProminent)
                }
            case .idle, .loading:
                ProgressView("正在取片…").frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .failed(message):
                ContentUnavailableView {
                    Label("无法加载", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("重试") { refreshToken += 1 }
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
                    Task { await store.loadMore(key: accessKey, query: query, orientation: orientation) }
                }
            }
        }
    }
}
