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

## 改颜色与图标

| 要改的 | 位置 |
|---|---|
| App 图标源图 | `web/wallpaper-h5-icons/app/app-icon-1024.png`（1024×1024） |
| 重新生成 macOS 图标 | `bash macos/scripts/make-icon.sh`（需要 `pip3 install pillow`），输出 `macos/Sources/Duopaper/AppIcon.icns` |
| 重新生成 iOS 图标 | `bash ios/scripts/make-icon.sh`，输出 `ios/Sources/Duopaper/Assets.xcassets/AppIcon.appiconset/AppIcon.png` |
| iOS 强调色 | `ios/Sources/Duopaper/Assets.xcassets/AccentColor.colorset/Contents.json` |
| macOS 强调色 | 默认跟随系统设置里的强调色，无需修改 |
| 分类图标颜色 | `shared/Models.swift` 里 `Topic.all` 的 `tint` |
| Web 配色 | `web/src/styles/tokens.css` |

改完图标后重新构建并安装；iOS 桌面图标缓存有时需要删掉 App 重装才会更新。

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

## 致谢

图片来自 Unsplash 及其摄影师，请遵守 [Unsplash License](https://unsplash.com/license) 与 API 使用规范。
