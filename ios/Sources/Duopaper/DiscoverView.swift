import SwiftUI

struct DiscoverView: View {
    @AppStorage("accessKey") private var accessKey = ""
    @AppStorage("query") private var query = "wallpaper"
    @AppStorage("orientation") private var orientationRaw = ""

    @Environment(SearchHistoryStore.self) private var history
    @State private var store = WallpaperStore()
    @State private var searchText = ""
    @State private var refreshToken = 0
    @State private var loadTask: Task<Void, Never>?
    @State private var didInitialLoad = false

    private var topicBinding: Binding<String> {
        Binding(
            get: { query },
            set: { searchText = ""; query = $0 }
        )
    }

    private var orientation: Orientation { Orientation(rawValue: orientationRaw) ?? .any }

    private struct LoadID: Equatable {
        let key: String, query: String, orientation: String, token: Int
    }

    var body: some View {
        NavigationStack {
            content
                .background(Color.appBackground)
                .navigationTitle(Topic.all.first { $0.query == query }?.title ?? query)
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $searchText, prompt: "搜索")
                .searchToolbarBehavior(.minimize)
                .onSubmit(of: .search) {
                    let q = searchText.trimmingCharacters(in: .whitespaces)
                    query = q.isEmpty ? "wallpaper" : q
                    if !q.isEmpty && !Topic.pinned.contains(where: { $0.query == q.lowercased() }) { history.add(q) }
                    refreshToken += 1
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Picker("分类", selection: topicBinding) {
                                ForEach(Topic.pinned) { topic in
                                    Label(topic.title, systemImage: topic.symbol).tag(topic.query)
                                }
                            }
                            .pickerStyle(.inline)
                            if !history.items.isEmpty {
                                Section("历史搜索") {
                                    Picker("历史搜索", selection: topicBinding) {
                                        ForEach(history.items, id: \.self) { item in
                                            Label(item, systemImage: "clock.arrow.circlepath").tag(item)
                                        }
                                    }
                                    .pickerStyle(.inline)
                                }
                            }
                        } label: {
                            Label("分类", systemImage: "square.grid.2x2")
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Picker("方向", selection: $orientationRaw) {
                                ForEach(Orientation.allCases) { Text($0.title).tag($0.rawValue) }
                            }
                        } label: {
                            Label("筛选", systemImage: "line.3.horizontal.decrease")
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("刷新", systemImage: "arrow.clockwise") { refreshToken += 1 }
                    }
                }
        }
        // 只在「用户明确操作」时加载：首次进入、换分类 / 搜索 / 方向、换密钥、点刷新。
        // 不用 .task(id:)：它会在切 Tab 回来（视图重新出现）时重新执行，造成意外刷新。
        .onChange(of: LoadID(key: accessKey, query: query, orientation: orientationRaw, token: refreshToken)) {
            startLoad()
        }
        .onAppear {
            if !Topic.all.contains(where: { $0.query == query }) { searchText = query }
            guard !didInitialLoad else { return }
            didInitialLoad = true
            startLoad()
        }
    }

    /// 加载任务挂在 @State 上而不是视图生命周期上：切走 Tab 不会取消它，切回来也不会重新触发。
    private func startLoad() {
        loadTask?.cancel()
        let key = accessKey, query = query, orientation = orientation
        loadTask = Task { await store.reload(key: key, query: query, orientation: orientation) }
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
                Button { refreshToken += 1 } label: {
                    Text("重试").foregroundStyle(Color.appOnPrimary)
                }
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
