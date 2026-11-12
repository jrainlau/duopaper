import AppKit
import Nuke
import SwiftUI

/// 设置：左侧栏目，右侧详情，和 iOS 版一致。
struct SettingsView: View {
    @State private var selection: SettingsSection = .key

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.macCases, selection: $selection) { section in
                Label {
                    Text(section.title)
                } icon: {
                    Image(systemName: section.symbol).foregroundStyle(section.tint)
                }
                .tag(section)
            }
            .navigationSplitViewColumnWidth(190)
        } detail: {
            detail
                .navigationTitle(selection.title)
        }
        .frame(width: 760, height: 480)
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .key: KeySettingsView()
        case .history: HistorySettingsView()
        case .download: DownloadSettingsView()
        case .widget: EmptyView()
        case .cache: CacheSettingsView()
        case .about: AboutSettingsView()
        }
    }
}

// MARK: - 密钥

private struct KeySettingsView: View {
    @AppStorage("accessKey") private var accessKey = ""
    @Environment(\.openWindow) private var openWindow
    @State private var draft = ""
    @State private var verifying = false
    @State private var errorMessage: String?

    private var trimmed: String { draft.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        Form {
            Section {
                SecureField("Access Key", text: $draft, prompt: Text(accessKey.isEmpty ? "粘贴 Access Key" : "已配置 · 输入新 Key 可替换"))
                    .onSubmit(saveAndVerify)
                HStack {
                    if verifying { ProgressView().controlSize(.small) }
                    Spacer()
                    if !accessKey.isEmpty {
                        Button("清除", role: .destructive) { accessKey = "" }
                    }
                    Button("保存并验证", action: saveAndVerify)
                        .keyboardShortcut(.defaultAction)
                        .disabled(trimmed.isEmpty || verifying)
                }
            } header: {
                Text("Access Key")
            } footer: {
                Text("到 [Unsplash Developers](https://unsplash.com/developers) 免费创建应用，复制 Access Key（不是 Secret Key）。Demo 应用限额 50 次 / 小时。密钥只保存在本机，只发送给 api.unsplash.com。保存时会先用一个最轻的接口验证，通过后才会保存并回到首页。")
            }
            if !accessKey.isEmpty {
                Section {
                    Label("已配置", systemImage: "checkmark.seal.fill").foregroundStyle(.green)
                }
            }
        }
        .formStyle(.grouped)
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
                goHome()
            } catch {
                errorMessage = "\(error.localizedDescription)\n\n密钥未保存。"
            }
        }
    }

    /// 关闭设置窗口并回到主窗口；主窗口已被关掉时重新打开。
    private func goHome() {
        let settingsWindow = NSApp.keyWindow
        settingsWindow?.close()
        if let main = NSApp.windows.first(where: { $0 !== settingsWindow && $0.isVisible && $0.canBecomeMain }) {
            main.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: "main")
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - 搜索历史

private struct HistorySettingsView: View {
    @Environment(SearchHistoryStore.self) private var history

    var body: some View {
        if history.items.isEmpty {
            ContentUnavailableView("暂无搜索历史", systemImage: "clock.arrow.circlepath", description: Text("搜索过的关键词会出现在主窗口侧边栏的「历史搜索」里，方便下次直接使用。"))
        } else {
            VStack(spacing: 0) {
                List {
                    ForEach(history.items, id: \.self) { item in
                        HStack {
                            Label(item, systemImage: "magnifyingglass")
                            Spacer()
                            Button {
                                if let i = history.items.firstIndex(of: item) { history.remove(at: IndexSet(integer: i)) }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .help("删除")
                            .accessibilityLabel("删除 \(item)")
                        }
                    }
                    .onMove { history.move(from: $0, to: $1) }
                    .onDelete { history.remove(at: $0) }
                }
                Divider()
                HStack {
                    Text("拖动调整顺序，排在前面的在侧边栏里也靠前。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("清空全部", role: .destructive) { history.removeAll() }
                }
                .padding(12)
            }
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
                .pickerStyle(.radioGroup)
            } header: {
                Text("默认清晰度")
            } footer: {
                Text("预览里也可以随时切换。图片保存到「下载」文件夹，并在 Finder 中选中。")
            }
        }
        .formStyle(.grouped)
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
                Text(cleared ? "已清除。" : "接口结果会缓存 6 小时以节省每小时 50 次的额度，图片缓存用于加快浏览。")
            }
        }
        .formStyle(.grouped)
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
        .formStyle(.grouped)
    }
}
