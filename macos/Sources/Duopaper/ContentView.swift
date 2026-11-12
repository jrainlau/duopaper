import SwiftUI

struct ContentView: View {
    @AppStorage("accessKey") private var accessKey = ""
    @AppStorage("query") private var query = "wallpaper"
    @AppStorage("orientation") private var orientationRaw = ""
    @AppStorage("downloadSize") private var sizeRaw = DownloadSize.standard.rawValue

    @State private var store = WallpaperStore()
    @State private var searchText = ""
    @State private var topic: Topic.ID?
    @State private var refreshToken = 0
    @Environment(\.openSettings) private var openSettings

    private var orientation: Orientation { Orientation(rawValue: orientationRaw) ?? .any }
    private var size: DownloadSize { DownloadSize(rawValue: sizeRaw) ?? .standard }

    private struct LoadID: Equatable {
        let key: String, query: String, orientation: String, token: Int
    }

    var body: some View {
        NavigationSplitView {
            List(Topic.all, selection: $topic) { t in
                Label(t.title, systemImage: t.symbol)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 190, max: 260)
        } detail: {
            detail
                .navigationTitle(Topic.all.first { $0.query == query }?.title ?? query)
                .navigationSubtitle(store.total > 0 ? "\(store.photos.count) / \(store.total)" : "")
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: "搜索")
        .onSubmit(of: .search) {
            let q = searchText.trimmingCharacters(in: .whitespaces)
            query = q.isEmpty ? "wallpaper" : q
            topic = Topic.all.first { $0.query == query.lowercased() }?.id
            refreshToken += 1
        }
        .toolbar {
            ToolbarItem {
                Picker("方向", selection: $orientationRaw) {
                    ForEach(Orientation.allCases) { Text($0.title).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
            }
            ToolbarItem {
                Picker("下载尺寸", selection: $sizeRaw) {
                    ForEach(DownloadSize.allCases) { Text($0.title).tag($0.rawValue) }
                }
                .help("下载尺寸")
            }
            ToolbarItem {
                Button("刷新", systemImage: "arrow.clockwise") { refreshToken += 1 }
                    .keyboardShortcut("r")
                    .help("重新取片（忽略缓存）")
            }
        }
        .task(id: LoadID(key: accessKey, query: query, orientation: orientationRaw, token: refreshToken)) {
            await store.reload(key: accessKey, query: query, orientation: orientation, force: refreshToken > 0 && lastForcedToken != refreshToken)
            lastForcedToken = refreshToken
        }
        .onChange(of: topic) { _, new in
            guard let new, new != query else { return }
            query = new
            searchText = ""
        }
        .onAppear {
            topic = Topic.all.first { $0.query == query }?.id
            if topic == nil { searchText = query }
        }
        .alert("下载失败", isPresented: Binding(get: { store.downloadError != nil }, set: { if !$0 { store.downloadError = nil } })) {
            Button("好") {}
        } message: {
            Text(store.downloadError ?? "")
        }
    }

    @State private var lastForcedToken = 0

    @ViewBuilder
    private var detail: some View {
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
            grid
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260, maximum: 420), spacing: 16)], spacing: 16) {
                ForEach(store.photos) { photo in
                    PhotoCard(photo: photo, isDownloading: store.downloadingID == photo.id) {
                        Task { await store.download(photo, size: size, key: accessKey) }
                    }
                    .onAppear {
                        if photo.id == store.photos.last?.id {
                            Task { await store.loadMore(key: accessKey, query: query, orientation: orientation) }
                        }
                    }
                }
            }
            .padding(20)
            if store.loadingMore {
                ProgressView().controlSize(.small).padding(.bottom, 20)
            }
        }
    }
}
