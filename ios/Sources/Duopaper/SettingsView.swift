import Nuke
import SwiftUI
import WidgetKit

/// 设置：侧边栏是栏目，详情在右侧。
/// 用标准 NavigationSplitView：regular 宽度（Duo 内屏、横屏）左右并排，
/// compact（Duo 外屏、竖屏 iPhone）自动变成「栏目列表 → 点进详情」。
struct SettingsView: View {
    let onVerified: () -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selection: SettingsSection?

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.symbol)
                .tag(section)
                .listRowBackground(Color.clear)
            }
            // 侧边栏整列统一用 Surface 铺满（含安全区），不再只有行区域有底色。
            .scrollContentBackground(.hidden)
            .background(Color.appSurface, ignoresSafeAreaEdges: .all)
            .navigationTitle("设置")
        } detail: {
            if let selection {
                detail(for: selection)
                    .navigationTitle(selection.title)
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                ContentUnavailableView("选择一个栏目", systemImage: "gearshape")
            }
        }
        .onAppear { selectDefaultIfWide() }
        .onChange(of: sizeClass) { selectDefaultIfWide() }
    }

    private func selectDefaultIfWide() {
        if sizeClass == .regular && selection == nil { selection = .key }
    }

    @ViewBuilder
    private func detail(for section: SettingsSection) -> some View {
        switch section {
        case .key: KeySettingsView(onVerified: onVerified)
        case .history: HistorySettingsView()
        case .download: DownloadSettingsView()
        case .widget: WidgetSettingsView()
        case .cache: CacheSettingsView()
        case .about: AboutSettingsView()
        }
    }
}

// MARK: - 密钥

private struct KeySettingsView: View {
    let onVerified: () -> Void

    @AppStorage("accessKey") private var accessKey = ""
    @State private var draft = ""
    @State private var verifying = false
    @State private var errorMessage: String?

    private var trimmed: String { draft.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        Form {
            Section {
                SecureField("Access Key", text: $draft, prompt: Text(accessKey.isEmpty ? "粘贴 Access Key" : "已配置 · 输入新 Key 可替换"))
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.go)
                    .onSubmit(saveAndVerify)

                Button(action: saveAndVerify) {
                    HStack {
                        Text("保存并验证")
                        if verifying { Spacer(); ProgressView() }
                    }
                }
                .disabled(trimmed.isEmpty || verifying)
            } header: {
                Text("Access Key")
            } footer: {
                Text("到 [Unsplash Developers](https://unsplash.com/developers) 免费创建应用，复制 Access Key（不是 Secret Key）。Demo 应用限额 50 次 / 小时。密钥只保存在本机，只发送给 api.unsplash.com。保存时会先用一个最轻的接口验证，通过后才会保存并回到首页。")
            }
            .appRows()

            if !accessKey.isEmpty {
                Section {
                    Label("已配置", systemImage: "checkmark.seal.fill").foregroundStyle(Color.appSuccess)
                    Button("清除密钥", role: .destructive) { accessKey = "" }
                }
                .appRows()
            }
        }
        .appPage()
        .alert("验证失败", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("好") {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func saveAndVerify() {
        let key = trimmed
        guard !key.isEmpty, !verifying else { return }
        verifying = true
        Task {
            defer { verifying = false }
            do {
                try await UnsplashClient(key: key).validate()
                accessKey = key
                draft = ""
                onVerified()
            } catch {
                errorMessage = "\(error.localizedDescription)\n\n密钥未保存。"
            }
        }
    }
}

// MARK: - 搜索历史

private struct HistorySettingsView: View {
    @Environment(SearchHistoryStore.self) private var history

    var body: some View {
        Group {
            if history.items.isEmpty {
                ContentUnavailableView("暂无搜索历史", systemImage: "clock.arrow.circlepath", description: Text("搜索过的关键词会出现在首页的分类菜单里，方便下次直接使用。"))
            } else {
                List {
                    Section {
                        ForEach(history.items, id: \.self) { item in
                            Label(item, systemImage: "magnifyingglass")
                        }
                        .onDelete { history.remove(at: $0) }
                        .onMove { history.move(from: $0, to: $1) }
                    } footer: {
                        Text("点右上角「编辑」可以拖动排序；左滑可以删除。排在前面的会先出现在分类菜单里。")
                    }
                    .appRows()
                    Section {
                        Button("清空全部历史", role: .destructive) { history.removeAll() }
                    }
                    .appRows()
                }
                .appPage()
            }
        }
        .toolbar {
            if !history.items.isEmpty { EditButton() }
        }
    }
}

// MARK: - 下载

private struct DownloadSettingsView: View {
    @AppStorage("downloadSize") private var sizeRaw = DownloadSize.standard.rawValue

    var body: some View {
        Form {
            Section {
                Picker("清晰度", selection: $sizeRaw) {
                    ForEach(DownloadSize.allCases) { Text($0.title).tag($0.rawValue) }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("默认清晰度")
            } footer: {
                Text("预览里也可以随时切换。图片会保存到系统相册，首次保存需要允许写入相册。")
            }
            .appRows()
        }
        .appPage()
    }
}

// MARK: - 小组件

private struct WidgetSettingsView: View {
    @Environment(FavoritesStore.self) private var favorites
    @State private var interval = WidgetShared.interval
    @State private var status = WidgetSync.status()
    @State private var syncing = false

    private let options: [(title: String, seconds: TimeInterval)] = [
        ("1 分钟", 60), ("5 分钟", 300), ("15 分钟", 900), ("30 分钟", 1800), ("1 小时", 3600),
    ]

    var body: some View {
        Form {
            Section {
                Picker("切换间隔", selection: $interval) {
                    ForEach(options, id: \.seconds) { Text($0.title).tag($0.seconds) }
                }
                .pickerStyle(.inline)
                .labelsHidden()
                .onChange(of: interval) {
                    WidgetShared.interval = interval
                    WidgetCenter.shared.reloadTimelines(ofKind: WidgetShared.kind)
                }
            } header: {
                Text("轮播切换间隔")
            } footer: {
                Text("小组件会渐隐渐显地轮播收藏里的图片；桌面上有多个小组件时，各自随机、互不同步。系统对小组件刷新有节流，实际切换时间可能略有偏差。")
            }
            .appRows()

            Section {
                LabeledContent("数据通道") {
                    Label(status.groupAvailable ? "正常" : "不可用", systemImage: status.groupAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(status.groupAvailable ? Color.appSuccess : Color.appWarning)
                }
                LabeledContent("小组件缩略图", value: "\(status.thumbs) / \(favorites.photos.count) 张")
                Button {
                    syncing = true
                    Task {
                        await WidgetSync.shared.sync(favorites.photos)
                        status = WidgetSync.status()
                        syncing = false
                    }
                } label: {
                    HStack {
                        Text("立即同步")
                        if syncing { Spacer(); ProgressView() }
                    }
                }
                .disabled(syncing)
            } header: {
                Text("状态")
            } footer: {
                Text(status.groupAvailable
                    ? "收藏图片时会自动保存一份很小的缩略图给小组件使用（每张约几十 KB）。点击小组件会直接打开收藏页。"
                    : "App Group 不可用：请在 Xcode 的 Signing & Capabilities 里为 Duopaper 和 DuopaperWidgetExtension 两个 target 开启同一个 App Group（group.com.jrainlau.duopaper）。")
            }
            .appRows()
        }
        .appPage()
        .onAppear { status = WidgetSync.status() }
    }
}

// MARK: - 缓存

private struct CacheSettingsView: View {
    @State private var cleared = false
    @State private var size = CacheTools.imageCacheSize()

    var body: some View {
        Form {
            Section {
                LabeledContent("图片缓存占用", value: CacheTools.format(size))
                Button("清除图片与接口缓存", role: .destructive) {
                    CacheTools.clearAll()
                    size = CacheTools.imageCacheSize()
                    cleared = true
                }
            } footer: {
                Text(cleared ? "已清除。" : "会清除浏览过的图片、App 里的缩略图和接口缓存（接口结果缓存 6 小时，节省每小时 50 次的额度）。\n\n你收藏的图片的小组件专用缩略图单独保存，不属于缓存，清除后小组件仍能正常显示；收藏页里的图片会重新联网加载。")
            }
            .appRows()
        }
        .appPage()
    }
}

// MARK: - 关于

private struct AboutSettingsView: View {
    private var version: String {
        let info = Bundle.main.infoDictionary
        return "\(info?["CFBundleShortVersionString"] as? String ?? "1.0") (\(info?["CFBundleVersion"] as? String ?? "1"))"
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("版本", value: version)
            }
            .appRows()
            Section {
                Link("Unsplash License", destination: URL(string: "https://unsplash.com/license")!)
                Link("Unsplash API 使用规范", destination: URL(string: "https://help.unsplash.com/en/articles/2511245-unsplash-api-guidelines")!)
            } footer: {
                Text("Photos provided by Unsplash 及其摄影师。每张图片都标注了摄影师并链接到其 Unsplash 主页；每次保存图片都会按 API 规范向 Unsplash 上报一次下载。")
            }
            .appRows()
        }
        .appPage()
    }
}
