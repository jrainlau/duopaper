import SwiftUI

struct DiscoverView: View {
    @AppStorage("accessKey") private var accessKey = ""
    @AppStorage("query") private var query = "wallpaper"
    @AppStorage("orientation") private var orientationRaw = ""

    @State private var store = WallpaperStore()
    @State private var searchText = ""
    @State private var refreshToken = 0

    private var orientation: Orientation { Orientation(rawValue: orientationRaw) ?? .any }

    private struct LoadID: Equatable {
        let key: String, query: String, orientation: String, token: Int
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TopicChips(selected: query) { topic in
                    searchText = ""
                    query = topic.query
                }
                content
            }
            .navigationTitle(Topic.all.first { $0.query == query }?.title ?? query)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "搜索")
            .onSubmit(of: .search) {
                let q = searchText.trimmingCharacters(in: .whitespaces)
                query = q.isEmpty ? "wallpaper" : q
                refreshToken += 1
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Menu {
                        Picker("方向", selection: $orientationRaw) {
                            ForEach(Orientation.allCases) { Text($0.title).tag($0.rawValue) }
                        }
                        Divider()
                        Button("换一批", systemImage: "arrow.clockwise") { refreshToken += 1 }
                    } label: {
                        Label("筛选", systemImage: "line.3.horizontal.decrease")
                    }
                }
            }
        }
        .task(id: LoadID(key: accessKey, query: query, orientation: orientationRaw, token: refreshToken)) {
            await store.reload(key: accessKey, query: query, orientation: orientation)
        }
        .onAppear {
            if !Topic.all.contains(where: { $0.query == query }) { searchText = query }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .idle where accessKey.isEmpty:
            ContentUnavailableView {
                Label("尚未配置 Access Key", systemImage: "key")
            } description: {
                Text("到「设置」里填入你的 Unsplash Access Key 后即可开始取片。")
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
                    .buttonStyle(.borderedProminent)
            }
        case .ready where store.photos.isEmpty:
            ContentUnavailableView.search(text: query)
        case .ready:
            PhotoGridView(
                photos: store.photos,
                footer: store.loadingMore ? AnyView(ProgressView().padding(.bottom, 12)) : nil,
                onNearEnd: { Task { await store.loadMore(key: accessKey, query: query, orientation: orientation) } }
            )
            .refreshable { refreshToken += 1 }
        }
    }
}
