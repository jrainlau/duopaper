# AGENTS.md

仓库结构：`web/`（H5，部署 GitHub Pages）、`macos/`（SwiftUI macOS App）、`ios/`（SwiftUI iOS App，适配 iPhone Duo）、`shared/`（macOS 与 iOS 共用的 Swift 代码，两个 Xcode 工程都以文件夹引用它，改动会同时影响两端，改完要两端都编译）。

## 发 macOS 版（用户说“发 MacOS”时执行）

1. 确认当前分支改动已提交并推送（`git status` 干净，`HEAD` 等于 `origin/<分支>`）；否则先提交并推送。
2. 如需升版本，修改 `macos/Info.plist` 的 `CFBundleShortVersionString`（和 `CFBundleVersion`），提交并推送。用户没提版本就沿用现有版本。
3. 在仓库根目录执行（需要在沙箱外运行，且 Xcode 首次会下载 Nuke 依赖，需联网）：

   ```bash
   XCODEBUILD_FLAGS='-IDEPackageSupportDisableManifestSandbox=1 OTHER_SWIFT_FLAGS=-disable-sandbox' bash scripts/release-macos.sh
   ```

   在用户自己的终端里直接 `bash scripts/release-macos.sh` 即可，不需要 `XCODEBUILD_FLAGS`。
4. 脚本会：本地构建 Release（ad-hoc 签名，arm64）-> 生成 `macos/build/Duopaper-<版本>-arm64.dmg` -> 创建或更新 GitHub Release `macos-v<版本>` 并上传 DMG（同版本重复发布会覆盖同名文件）。
5. 把脚本最后输出的下载链接告诉用户。

认证用 `GITHUB_TOKEN` 环境变量或 `~/.zshrc` 里的 `export GITHUB_TOKEN=...`，不要把 token 写进仓库或输出到对话里。

## 其他约定

- macOS 图标源自 `web/wallpaper-h5-icons/app/app-icon-1024.png`，改了源图后执行 `bash macos/scripts/make-icon.sh` 重新生成 `macos/Sources/Duopaper/AppIcon.icns`（需要 Pillow）并提交。
- iOS：`ios/Duopaper.xcodeproj`，设计遵循 Apple HIG 的 iPhone Duo 章节（按尺寸类布局、不假设设备型号、系统控件自动适配侧边工具栏、折叠屏偶数列）。命令行构建模拟器版：`xcodebuild -project ios/Duopaper.xcodeproj -scheme Duopaper -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`（沙箱内需加 `-IDEPackageSupportDisableManifestSandbox=1 OTHER_SWIFT_FLAGS=-disable-sandbox`）。
- 本地调试 macOS App：用 Xcode 打开 `macos/Duopaper.xcodeproj`，⌘R。仅构建 `.app`：`bash macos/scripts/build-app.sh`。
- Web 的 GitHub Pages 由 `.github/workflows/static.yml` 在推送 `main` 时部署，不要在其他分支触发或改动其路径约定（`web/dist`）。
- 不要擅自合并到 `main`，除非用户明确要求。
