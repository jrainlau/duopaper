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
    @State private var showQuotaToast = false

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
                .searchable(text: $searchText, prompt: L("discover.search"))
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
                            Picker(L("discover.categories"), selection: topicBinding) {
                                ForEach(Topic.pinned) { topic in
                                    Label(topic.title, systemImage: topic.symbol).tag(topic.query)
                                }
                            }
                            .pickerStyle(.inline)
                            if !history.items.isEmpty {
                                Section(L("discover.history")) {
                                    Picker(L("discover.history"), selection: topicBinding) {
                                        ForEach(history.items, id: \.self) { item in
                                            Label(item, systemImage: "clock.arrow.circlepath").tag(item)
                                        }
                                    }
                                    .pickerStyle(.inline)
                                }
                            }
                        } label: {
                            Label(L("discover.categories"), systemImage: "square.grid.2x2")
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Picker(L("discover.filter"), selection: $orientationRaw) {
                                ForEach(Orientation.allCases) { Text($0.title).tag($0.rawValue) }
                            }
                        } label: {
                            Label(L("discover.filter"), systemImage: "line.3.horizontal.decrease")
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button(L("discover.refresh"), systemImage: "arrow.clockwise") { refreshToken += 1 }
                        // 配额耗尽提示：系统 popover 锚定在刷新按钮上，iOS 26 自带液态玻璃背景，点外部自动消失。
                        .popover(isPresented: $showQuotaToast, arrowEdge: .leading) {
                            quotaExhaustedToast
                                .presentationCompactAdaptation(.popover)
                        }
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
        loadTask = Task {
            await store.reload(key: key, query: query, orientation: orientation)
            // 默认不展示任何配额信息；只有配额耗尽才弹一次气泡。
            if QuotaTracker.shared.exhausted { showQuotaToast = true }
        }
    }

    /// popover 内容：背景由系统提供（iOS 26 为液态玻璃），这里只放图标和文案。
    private var quotaExhaustedToast: some View {
        Label(L("quota.hourlyExhausted"), systemImage: "hourglass")
            .font(.subheadline.weight(.medium))
            .frame(maxWidth: 280, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .idle where accessKey.isEmpty:
            ContentUnavailableView {
                Label(L("discover.noKey.title"), systemImage: "key")
            } description: {
                Text(L("discover.noKey.body"))
            }
        case .idle, .loading:
            ProgressView(L("discover.loading")).frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .failed(message):
            ContentUnavailableView {
                Label(L("discover.loadFailed"), systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button { refreshToken += 1 } label: {
                    Text(L("common.retry")).foregroundStyle(Color.appOnPrimary)
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
