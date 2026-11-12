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

## macOS 版

需要 Xcode。无需开发者账号，使用 ad-hoc 签名，仅供本机使用：

```bash
bash macos/scripts/build-app.sh            # 生成 macos/build/Duopaper.app
bash macos/scripts/build-app.sh --install  # 同时安装到 /Applications
```

首次打开如被 Gatekeeper 拦截，右键 App 选「打开」。Access Key 在 App 的「设置」（⌘,）中填写。

## iOS 版（含 iPhone Duo）

用 Xcode 打开 `ios/Duopaper.xcodeproj`，选 iPhone Duo 模拟器（Device Hub 里可开合、旋转），⌘R 运行。Access Key 在「设置」页填写。真机安装需要在 Xcode 的 Signing 里登录 Apple ID 选个人 Team。

适配方式：只用标准 `TabView`（`.sidebarAdaptable`）、`NavigationStack`、sheet 与工具栏，按尺寸类而不是设备型号布局；外屏是 iPhone 布局，内屏自动变 regular 宽度，系统会把 Tab 栏和工具栏移到侧边；瀑布流在折叠屏上用偶数列。

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
