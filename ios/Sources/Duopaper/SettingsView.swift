import Nuke
import SwiftUI

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
                Label {
                    Text(section.title)
                } icon: {
                    Image(systemName: section.symbol).foregroundStyle(section.tint)
                }
                .tag(section)
            }
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

            if !accessKey.isEmpty {
                Section {
                    Label("已配置", systemImage: "checkmark.seal.fill").foregroundStyle(.green)
                    Button("清除密钥", role: .destructive) { accessKey = "" }
                }
            }
        }
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
                    Section {
                        Button("清空全部历史", role: .destructive) { history.removeAll() }
                    }
                }
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
        }
    }
}

// MARK: - 缓存

private struct CacheSettingsView: View {
    @State private var cleared = false

    var body: some View {
        Form {
            Section {
                Button("清除图片与接口缓存", role: .destructive) {
                    ImagePipeline.shared.cache.removeAll()
                    PageCache.clear()
                    cleared = true
                }
            } footer: {
                Text(cleared ? "已清除。" : "接口结果会缓存 6 小时以节省每小时 50 次的额度，图片缓存用于加快浏览。")
            }
        }
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
            Section {
                Link("Unsplash License", destination: URL(string: "https://unsplash.com/license")!)
                Link("Unsplash API 使用规范", destination: URL(string: "https://help.unsplash.com/en/articles/2511245-unsplash-api-guidelines")!)
            } footer: {
                Text("图片来自 Unsplash 及其摄影师，请遵守相关许可与规范。")
            }
        }
    }
}
