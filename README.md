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

## 开发

```bash
npm install
npm run dev       # 本地开发，base 为 /
npm run build     # 构建，base 为 /duopaper/
npm run preview   # 预览构建产物
```

技术栈：React 19 + Vite。

## 部署

部署到 GitHub Pages，由 `.github/workflows/static.yml` 在推送 `main` 时触发：CI 执行 `npm ci && npm run build`，上传 `dist` 并发布。

```bash
npm run deploy -- "提交说明"
```

脚本 `scripts/deploy.sh` 会先本地构建校验，再提交并推送 `main`，之后由 workflow 完成发布。认证使用环境变量或 `~/.zshrc` 中的 `GITHUB_TOKEN`。

## 目录

```
src/components   界面组件
src/hooks        Access Key、列表数据、列数
src/lib          Unsplash 请求、缓存、下载、设备判断
src/styles       设计 token 与样式
public           图标与 manifest
scripts          部署脚本
```

## 致谢

图片来自 Unsplash 及其摄影师，请遵守 [Unsplash License](https://unsplash.com/license) 与 API 使用规范。
