#!/usr/bin/env bash
# 把 design/ 里的主题色和图标同步到三个端。改了 design/ 里的任何东西后执行一次：
#   bash design/sync.sh
# 然后重新构建（macOS：macos/scripts/build-app.sh；iOS：Xcode ⌘R；Web：cd web && npm run build）。
set -euo pipefail
cd "$(dirname "$0")/.."

# 主题色
rm -rf shared/Colors.xcassets
cp -R design/theme/Colors.xcassets shared/Colors.xcassets          # iOS + macOS 共用的颜色资源（含 Light / Dark）
cp design/theme/Theme.swift shared/Theme.swift                      # Color.appPrimary 等
cp design/theme/theme.css web/src/styles/theme.css                  # Web 的 CSS 变量

# 图标
cp design/icons/ios/AppIcon-1024.png ios/Sources/Duopaper/Assets.xcassets/AppIcon.appiconset/AppIcon.png
cp design/icons/macos/AppIcon.icns macos/Sources/Duopaper/AppIcon.icns
W=design/icons/web
cp $W/favicon.ico $W/favicon.svg $W/favicon-16x16.png $W/favicon-32x32.png $W/apple-touch-icon.png $W/icon-maskable-512.png web/public/
cp $W/icon-192.png web/public/android-chrome-192x192.png
cp $W/icon-512.png web/public/android-chrome-512x512.png

echo "==> 已同步主题色与图标"
