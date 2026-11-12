import AppKit
import Nuke
import SwiftUI

/// 设置：左侧栏目，右侧详情，和 iOS 版一致。
struct SettingsView: View {
    @State private var selection: SettingsSection = .language

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List(SettingsSection.macCases, selection: $selection) { section in
                Label(section.title, systemImage: section.symbol)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(190)
            // 设置窗口的侧边栏固定显示，不提供收起按钮。
            .toolbar(removing: .sidebarToggle)
        } detail: {
            detail
                .navigationTitle(selection.title)
        }
        .frame(width: 760, height: 480)
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .language: LanguageSettingsView()
        case .key: KeySettingsView()
        case .history: HistorySettingsView()
        case .download: DownloadSettingsView()
        case .widget: EmptyView()
        case .cache: CacheSettingsView()
        case .about: AboutSettingsView()
        }
    }
}

// MARK: - 语言

private struct LanguageSettingsView: View {
    @AppStorage(LanguageStore.storageKey) private var language = AppLanguage.system.rawValue

    var body: some View {
        Form {
            Section {
                Picker(L("settings.language"), selection: $language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.title).tag(lang.rawValue)
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
                // @AppStorage 直接写入 UserDefaults，LanguageStore 读同一个 key，无需手动同步。
            } footer: {
                Text(L("settings.language.footer"))
            }
        }
        .formStyle(.grouped)
        .appPage()
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
                SecureField("Access Key", text: $draft, prompt: Text(accessKey.isEmpty ? L("key.placeholder.empty") : L("key.placeholder.configured")))
                    .onSubmit(saveAndVerify)
                HStack {
                    if verifying { ProgressView().controlSize(.small) }
                    Spacer()
                    if !accessKey.isEmpty {
                        Button(L("key.clearShort"), role: .destructive) { accessKey = "" }
                    }
                    Button(L("key.saveAndVerify"), action: saveAndVerify)
                        .keyboardShortcut(.defaultAction)
                        .disabled(trimmed.isEmpty || verifying)
                }
            } header: {
                Text("Access Key")
            } footer: {
                Text(L("key.footer"))
            }
            if !accessKey.isEmpty {
                Section {
                    Label(L("key.configured"), systemImage: "checkmark.seal.fill").foregroundStyle(Color.appSuccess)
                }
            }
        }
        .formStyle(.grouped)
        .appPage()
        .alert(L("key.verifyFailed"), isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button(L("common.ok")) {}
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
                errorMessage = "\(error.localizedDescription)\n\n\(L("key.notSaved"))"
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
            ContentUnavailableView(L("history.empty.title"), systemImage: "clock.arrow.circlepath", description: Text(L("history.empty.body.sidebar")))
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
                            .help(L("common.delete"))
                            .accessibilityLabel(L("history.deleteItem", ["item": item]))
                        }
                    }
                    .onMove { history.move(from: $0, to: $1) }
                    .onDelete { history.remove(at: $0) }
                }
                Divider()
                HStack {
                    Text(L("history.dragHint"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(L("history.clearAll"), role: .destructive) { history.removeAll() }
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
                Picker(L("download.quality"), selection: $sizeRaw) {
                    ForEach(DownloadSize.allCases) { Text($0.title).tag($0.rawValue) }
                }
                .pickerStyle(.radioGroup)
            } header: {
                Text(L("download.default"))
            } footer: {
                Text(L("download.footer.downloads"))
            }
        }
        .formStyle(.grouped)
        .appPage()
    }
}

// MARK: - 缓存

private struct CacheSettingsView: View {
    @State private var cleared = false
    @State private var size = CacheTools.imageCacheSize()

    var body: some View {
        Form {
            Section {
                LabeledContent(L("cache.usage"), value: CacheTools.format(size))
                Button(L("cache.clear"), role: .destructive) {
                    CacheTools.clearAll()
                    size = CacheTools.imageCacheSize()
                    cleared = true
                }
            } footer: {
                Text(cleared ? L("cache.cleared") : L("cache.footer.mac"))
            }
        }
        .formStyle(.grouped)
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
                LabeledContent(L("about.version"), value: version)
            }
            Section {
                Link("Unsplash License", destination: URL(string: "https://unsplash.com/license")!)
                Link(L("about.apiGuidelines"), destination: URL(string: "https://help.unsplash.com/en/articles/2511245-unsplash-api-guidelines")!)
            } footer: {
                Text(L("about.footer"))
            }
        }
        .formStyle(.grouped)
        .appPage()
    }
}
