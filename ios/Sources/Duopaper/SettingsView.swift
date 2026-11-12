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
            .navigationTitle(L("settings.title"))
        } detail: {
            if let selection {
                detail(for: selection)
                    .navigationTitle(selection.title)
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                ContentUnavailableView(L("settings.pickSection"), systemImage: "gearshape")
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
        case .language: LanguageSettingsView()
        case .key: KeySettingsView(onVerified: onVerified)
        case .history: HistorySettingsView()
        case .download: DownloadSettingsView()
        case .widget: WidgetSettingsView()
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
                .pickerStyle(.inline)
                .labelsHidden()
                // @AppStorage 直接写入 UserDefaults，LanguageStore 读同一个 key，无需手动同步。
            } footer: {
                Text(L("settings.language.footer"))
            }
            .appRows()
        }
        .appPage()
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
                SecureField("Access Key", text: $draft, prompt: Text(accessKey.isEmpty ? L("key.placeholder.empty") : L("key.placeholder.configured")))
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.go)
                    .onSubmit(saveAndVerify)

                Button(action: saveAndVerify) {
                    HStack {
                        Text(L("key.saveAndVerify"))
                        if verifying { Spacer(); ProgressView() }
                    }
                }
                .disabled(trimmed.isEmpty || verifying)
            } header: {
                Text("Access Key")
            } footer: {
                Lmd("key.footer")
            }
            .appRows()

            if !accessKey.isEmpty {
                Section {
                    Label(L("key.configured"), systemImage: "checkmark.seal.fill").foregroundStyle(Color.appSuccess)
                    Button(L("key.clear"), role: .destructive) { accessKey = "" }
                }
                .appRows()
            }
        }
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
                onVerified()
            } catch {
                errorMessage = "\(error.localizedDescription)\n\n\(L("key.notSaved"))"
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
                ContentUnavailableView(L("history.empty.title"), systemImage: "clock.arrow.circlepath", description: Text(L("history.empty.body.tab")))
            } else {
                List {
                    Section {
                        ForEach(history.items, id: \.self) { item in
                            Label(item, systemImage: "magnifyingglass")
                        }
                        .onDelete { history.remove(at: $0) }
                        .onMove { history.move(from: $0, to: $1) }
                    } footer: {
                        Text(L("history.editHint"))
                    }
                    .appRows()
                    Section {
                        Button(L("history.clearAllAll"), role: .destructive) { history.removeAll() }
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
                Picker(L("download.quality"), selection: $sizeRaw) {
                    ForEach(DownloadSize.allCases) { Text($0.title).tag($0.rawValue) }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text(L("download.default"))
            } footer: {
                Text(L("download.footer.photos"))
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

    // WidgetKit 有最小刷新间隔和每日刷新预算，分钟级档位在真机上不生效。
    // 最短档取 15 分钟：12 个条目能覆盖 3 小时，期间无需依赖会被节流的后台刷新。
    private let options: [(title: String, seconds: TimeInterval)] = [
        (L("widget.intervalMinutes", ["n": "15"]), 900),
        (L("widget.intervalMinutes", ["n": "30"]), 1800),
        (L("widget.intervalHours", ["n": "1"]), 3600),
        (L("widget.intervalHours", ["n": "2"]), 7200),
    ]

    var body: some View {
        Form {
            Section {
                Picker(L("widget.interval"), selection: $interval) {
                    ForEach(options, id: \.seconds) { Text($0.title).tag($0.seconds) }
                }
                .pickerStyle(.inline)
                .labelsHidden()
                .onChange(of: interval) {
                    WidgetShared.interval = interval
                    WidgetCenter.shared.reloadTimelines(ofKind: WidgetShared.kind)
                }
            } header: {
                Text(L("widget.carouselInterval"))
            } footer: {
                Text(L("widget.intervalFooter"))
            }
            .appRows()

            Section {
                LabeledContent(L("widget.dataChannel")) {
                    Label(status.groupAvailable ? L("widget.statusOk") : L("widget.statusUnavailable"), systemImage: status.groupAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(status.groupAvailable ? Color.appSuccess : Color.appWarning)
                }
                LabeledContent(L("widget.thumbs"), value: L("widget.thumbsValue", ["shown": "\(status.thumbs)", "total": "\(favorites.photos.count)"]))
                Button {
                    syncing = true
                    Task {
                        await WidgetSync.shared.sync(favorites.photos)
                        status = WidgetSync.status()
                        syncing = false
                    }
                } label: {
                    HStack {
                        Text(L("widget.syncNow"))
                        if syncing { Spacer(); ProgressView() }
                    }
                }
                .disabled(syncing)
            } header: {
                Text(L("widget.status"))
            } footer: {
                Text(status.groupAvailable
                    ? L("widget.statusFooterOk")
                    : L("widget.statusFooterBad"))
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
                LabeledContent(L("cache.usage"), value: CacheTools.format(size))
                Button(L("cache.clear"), role: .destructive) {
                    CacheTools.clearAll()
                    size = CacheTools.imageCacheSize()
                    cleared = true
                }
            } footer: {
                Text(cleared ? L("cache.cleared") : L("cache.footer.ios"))
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
                LabeledContent(L("about.version"), value: version)
            }
            .appRows()
            Section {
                Link("Unsplash License", destination: URL(string: "https://unsplash.com/license")!)
                Link(L("about.apiGuidelines"), destination: URL(string: "https://help.unsplash.com/en/articles/2511245-unsplash-api-guidelines")!)
            } footer: {
                Text(L("about.footer"))
            }
            .appRows()
        }
        .appPage()
    }
}
