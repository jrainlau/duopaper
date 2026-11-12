import SwiftUI

struct SettingsView: View {
    @AppStorage("accessKey") private var accessKey = ""
    @State private var draft = ""

    var body: some View {
        Form {
            Section {
                SecureField("Access Key", text: $draft, prompt: Text(accessKey.isEmpty ? "粘贴 Access Key" : "已配置 · 输入新 Key 可替换"))
                HStack {
                    Spacer()
                    if !accessKey.isEmpty {
                        Button("清除", role: .destructive) { accessKey = "" }
                    }
                    Button("保存") {
                        accessKey = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                        draft = ""
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } header: {
                Text("Unsplash")
            } footer: {
                Text("到 [Unsplash Developers](https://unsplash.com/developers) 免费创建应用，复制 Access Key（不是 Secret Key）。Demo 应用限额 50 次 / 小时。密钥仅保存在本机，只发送给 api.unsplash.com。")
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 230)
    }
}
