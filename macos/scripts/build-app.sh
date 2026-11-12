#!/usr/bin/env bash
# 用法：bash macos/scripts/build-app.sh [--install]
# 产物：macos/build/Duopaper.app（ad-hoc 签名，仅本机自用，无需开发者账号）
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build/Duopaper.app"
ICON_SRC="../web/wallpaper-h5-icons/app/app-icon-1024.png"

swift build --disable-sandbox -c release --arch arm64 --arch x86_64
BIN="$(swift build --disable-sandbox -c release --arch arm64 --arch x86_64 --show-bin-path)/Duopaper"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Duopaper"
cp Info.plist "$APP/Contents/Info.plist"

ICONSET="build/AppIcon.iconset"
rm -rf "$ICONSET" && mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
  sips -z $s $s "$ICON_SRC" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) "$ICON_SRC" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET"

codesign --force --deep --sign - --entitlements Duopaper.entitlements "$APP"
echo "==> 已生成 $APP"

if [ "${1:-}" = "--install" ]; then
  rm -rf /Applications/Duopaper.app
  cp -R "$APP" /Applications/Duopaper.app
  echo "==> 已安装到 /Applications/Duopaper.app"
fi
