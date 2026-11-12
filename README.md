# duopaper

沉浸式壁纸浏览与下载的移动优先 H5 应用，图源为 [Unsplash](https://unsplash.com)。纯前端，无后端。

在线访问：https://jrainlau.github.io/duopaper/

## 功能

- 搜索、分类、方向（横屏 / 竖屏 / 方图）筛选，瀑布流浏览
- 点击卡片下载，同时按 Unsplash API 规范上报 download 统计
- 下载尺寸可选：缩略图（600px，约 50KB）、标准、2.5K、4K、原始
- iOS 长按卡片可直接「存储图像」（展示图强制 jpeg）
- 可添加到主屏幕（PWA manifest + apple-touch-icon）
- 接口结果本地缓存 6 小时（IndexedDB），节省 50 次/小时的配额

## 使用

页面不内置任何密钥。首次打开点「设置 Access Key」，填入你自己的 Unsplash Access Key：

1. 到 [Unsplash Developers](https://unsplash.com/developers) 创建应用
2. 复制 **Access Key**（不是 Secret Key）
3. 粘贴到页面设置中，仅保存在浏览器本地（localStorage）

## 目录结构

```
web/    H5 版（React + Vite），部署到 GitHub Pages
ios/    iOS 原生版（SwiftUI，适配 iPhone Duo）
macos/  macOS 原生版（SwiftUI，遵循 Apple HIG）
shared/ iOS 与 macOS 共用的 Swift 代码（模型、Unsplash 请求、收藏、瀑布流）
```

## 安装与分发（没有开发者账号）

| 平台 | 自己用 | 给别人用 |
|---|---|---|
| Web | 打开 https://jrainlau.github.io/duopaper/ | 同左，发链接即可 |
| macOS | `bash macos/scripts/build-app.sh --install`，装到 `/Applications`，可长期使用 | 在 GitHub Releases 下载 DMG（`发 MacOS` 流程见 `AGENTS.md`），未公证，对方首次要右键「打开」，提示已损坏时执行 `xattr -cr /Applications/Duopaper.app` |
| iOS | 用 Xcode 个人 Team 装到自己的手机，**7 天过期**，到期后重新运行一次即可（数据不丢） | 免费账号无法分发。可以让对方自己 clone 仓库用 Xcode 装，或者直接用 Web 版（可添加到主屏幕） |

要想让别人在 iOS 上方便地安装（TestFlight / App Store / 免 7 天限制），需要付费的 Apple Developer Program（99 美元 / 年）。

## macOS 版

需要 Xcode。使用 ad-hoc 签名，不需要开发者账号：

```bash
bash macos/scripts/build-app.sh            # 生成 macos/build/Duopaper.app
bash macos/scripts/build-app.sh --install  # 同时安装到 /Applications
```

用 Xcode 调试：打开 `macos/Duopaper.xcodeproj`，⌘R。Access Key 在 App 的「设置」（⌘,）里填，保存时会先联网验证。

## iOS 版（含 iPhone Duo）

用 Xcode 打开 `ios/Duopaper.xcodeproj`，设备选 iPhone Duo 模拟器（Device Hub 里可开合、旋转）或自己的手机，⌘R 运行。

**装到自己的手机（免费账号）**
1. 手机开启开发者模式（设置 → 隐私与安全性），用数据线连 Mac 并信任。
2. Xcode → Settings → Accounts 登录 Apple ID。
3. 选中 `Duopaper` 和 `DuopaperWidgetExtension` 两个 target，Signing & Capabilities 里 Team 选个人团队；两个 target 都要有同一个 App Group：`group.com.jrainlau.duopaper`。
4. 选中手机，⌘R。第一次要在手机「设置 → 通用 → VPN 与设备管理」里信任开发者。
5. 免费账号签名 7 天过期，过期后 App 打不开，重新 ⌘R 一次即可。

功能：瀑布流浏览、收藏、预览与下载（保存到名为 Duopaper 的相册）、搜索历史、「收藏轮播」桌面小组件（小 / 中，点击进入收藏，切换间隔在设置里调）。列表只在手动刷新、换分类 / 搜索 / 方向时加载。

适配 iPhone Duo：只用标准 `TabView`、`NavigationStack` 与工具栏，按尺寸类而不是设备型号布局；瀑布流在折叠屏上用偶数列。

## 主题色与图标（design/）

所有设计资源集中在 `design/`，三个端共用同一套：

```
design/
  theme/    主题色：Colors.xcassets（Light / Dark）、Theme.swift、theme.css、tokens.json、preview.html（预览）
  icons/
    ios/    iOS 图标 1024
    macos/  macOS 图标 AppIcon.icns + 1024 预览
    web/    favicon / apple-touch-icon / PWA 图标
    source/ 矢量源文件与原图
  sync.sh   把上面的内容同步到各端
```

主色为紫色：Light `#7A3FD0`、Dark `#BD89E8`，完整色表见 `design/theme/tokens.json`。

**改了 `design/` 里的颜色或图标之后：**

```bash
bash design/sync.sh
```

它会把主题色同步到 `shared/Colors.xcassets` + `shared/Theme.swift`（iOS / macOS）和 `web/src/styles/theme.css`（Web），并把图标覆盖到 iOS 的 `AppIcon.appiconset`、macOS 的 `AppIcon.icns`、Web 的 `public/`。然后重新构建：macOS 用 `bash macos/scripts/build-app.sh --install`，iOS 在 Xcode 里 ⌘R，Web 用 `cd web && npm run build`。iOS 桌面图标有缓存，不更新时删掉 App 重装。

各端怎么用：iOS / macOS 的强调色来自 `Primary`（`ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME`），页面和分组背景用 `Color.appBackground` / `Color.appSurface`，主按钮文字用 `Color.appOnPrimary`；Web 在 `tokens.css` 里把旧变量名映射到 `theme.css`，自动跟随系统明暗。macOS 的系统强调色如果不是「多彩」，系统设置里选的颜色会覆盖侧边栏选中色。

## Web 开发（在 web/ 目录下）

```bash
cd web
npm install
npm run dev       # 本地开发，base 为 /
npm run build     # 构建，base 为 /duopaper/
npm run preview   # 预览构建产物
```

技术栈：React 19 + Vite。

## 部署

部署到 GitHub Pages，由 `.github/workflows/static.yml` 在推送 `main` 时触发：CI 在 `web/` 下执行 `npm ci && npm run build`，上传 `web/dist` 并发布。

```bash
npm run deploy -- "提交说明"
```

脚本 `scripts/deploy.sh` 会先本地构建校验，再提交并推送 `main`，之后由 workflow 完成发布。认证使用环境变量或 `~/.zshrc` 中的 `GITHUB_TOKEN`。

## 目录

```
web/src/components   界面组件
web/src/hooks        Access Key、列表数据、列数
web/src/lib          Unsplash 请求、缓存、下载、设备判断
web/src/styles       设计 token 与样式
web/public           图标与 manifest
web/scripts          部署脚本
```

## Unsplash 合规

- 每张展示的图片都标注「摄影师 / Unsplash」，摄影师链到其 Unsplash 主页，Unsplash 链到 unsplash.com，所有链接带 `utm_source=duopaper&utm_medium=referral`（Web：`web/src/lib/unsplash.js` 的 `unsplashLink`；原生：`shared/Models.swift` 的 `UnsplashLink`、`shared/Attribution.swift`）。
- 图片直接 hotlink `images.unsplash.com`，调整参数时保留 `ixid`。
- 每次保存 / 下载前向 `download_location` 上报一次。
- 不内置密钥，由用户填自己的 Access Key（Demo 50 次 / 小时）。如果要内置官方 key 或面向大量用户，需先到 Unsplash Developers 申请 Production 权限。
- 小组件里是文字署名（小组件只能整块点击，无法放可点链接）。

## 致谢

图片来自 Unsplash 及其摄影师，请遵守 [Unsplash License](https://unsplash.com/license) 与 API 使用规范。
