#!/usr/bin/env bash
# 用法：bash macos/scripts/build-app.sh [--install]
# 产物：macos/build/Duopaper.app（ad-hoc 签名，仅本机自用，无需开发者账号）
set -euo pipefail
cd "$(dirname "$0")/.."

xcodebuild -project Duopaper.xcodeproj -scheme Duopaper -configuration Release \
  -derivedDataPath build/dd -skipMacroValidation -skipPackagePluginValidation ${XCODEBUILD_FLAGS:-} build \
  | grep -E "error:|BUILD" || true

APP="build/Duopaper.app"
rm -rf "$APP"
cp -R build/dd/Build/Products/Release/Duopaper.app "$APP"
echo "==> 已生成 $APP"

if [ "${1:-}" = "--install" ]; then
  rm -rf /Applications/Duopaper.app
  cp -R "$APP" /Applications/Duopaper.app
  echo "==> 已安装到 /Applications/Duopaper.app"
fi
