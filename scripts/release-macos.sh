#!/usr/bin/env bash
# 用法：bash scripts/release-macos.sh [版本号]
# 版本号省略时取 macos/Info.plist 的 CFBundleShortVersionString。
# 流程：本地构建 Release -> 打 DMG -> 创建/更新 GitHub Release（tag: macos-v<版本>）并上传 DMG。
# 认证：环境变量 GITHUB_TOKEN，或 ~/.zshrc 里的 `export GITHUB_TOKEN=...`。
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"

REPO="jrainlau/duopaper"
VERSION="${1:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' macos/Info.plist)}"
TAG="macos-v$VERSION"
DMG_NAME="Duopaper-$VERSION-arm64.dmg"
DMG="$ROOT/macos/build/$DMG_NAME"

if [ -z "${GITHUB_TOKEN:-}" ]; then
  GITHUB_TOKEN=$(grep -E '^export GITHUB_TOKEN=' "$HOME/.zshrc" | head -1 | sed -E 's/^export GITHUB_TOKEN=//; s/^["'"'"']//; s/["'"'"']$//')
fi
[ -n "$GITHUB_TOKEN" ] || { echo "未找到 GITHUB_TOKEN"; exit 1; }

# 发布的提交必须已推送，否则 tag 会指向远端不存在的提交
if [ -n "$(git status --porcelain)" ]; then echo "工作区有未提交改动，请先提交并推送"; exit 1; fi
BRANCH=$(git rev-parse --abbrev-ref HEAD)
git fetch -q origin "$BRANCH" 2>/dev/null || true
if [ "$(git rev-parse HEAD)" != "$(git rev-parse "origin/$BRANCH" 2>/dev/null || echo none)" ]; then
  echo "当前提交尚未推送到 origin/$BRANCH，请先推送"; exit 1
fi
SHA=$(git rev-parse HEAD)

echo "==> 构建 macOS App ($VERSION)"
bash macos/scripts/build-app.sh
APP="$ROOT/macos/build/Duopaper.app"
[ -d "$APP" ] || { echo "构建失败：未找到 $APP"; exit 1; }

echo "==> 打包 DMG"
STAGE=$(mktemp -d)
cp -R "$APP" "$STAGE/Duopaper.app"
ln -s /Applications "$STAGE/Applications"
rm -f "$DMG"
hdiutil create -volname "Duopaper" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"
echo "    $DMG ($(du -h "$DMG" | cut -f1))"

api() { curl -sS -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" "$@"; }
json() { python3 -c "import sys,json; d=json.load(sys.stdin); print($1)"; }

echo "==> 创建 / 更新 GitHub Release $TAG"
RELEASE=$(api "https://api.github.com/repos/$REPO/releases/tags/$TAG")
RID=$(echo "$RELEASE" | json "d.get('id','')")
if [ -z "$RID" ]; then
  PAYLOAD=$(python3 - "$TAG" "$SHA" "$VERSION" <<'PY'
import json, sys
tag, sha, ver = sys.argv[1:4]
body = (f"macOS（Apple Silicon）版 Duopaper {ver}。\n\n"
        "安装：打开 DMG，把 Duopaper 拖进「应用程序」。\n\n"
        "未使用开发者账号签名，首次打开请右键 App 选「打开」；"
        "如提示已损坏，执行：`xattr -cr /Applications/Duopaper.app`")
print(json.dumps({"tag_name": tag, "target_commitish": sha, "name": f"Duopaper macOS {ver}", "body": body}))
PY
)
  RELEASE=$(api -X POST "https://api.github.com/repos/$REPO/releases" -d "$PAYLOAD")
  RID=$(echo "$RELEASE" | json "d['id']")
else
  # 同名资源先删除，实现覆盖上传
  for AID in $(echo "$RELEASE" | json "' '.join(str(a['id']) for a in d.get('assets',[]) if a['name']=='$DMG_NAME')"); do
    api -X DELETE "https://api.github.com/repos/$REPO/releases/assets/$AID" >/dev/null
  done
fi

echo "==> 上传 $DMG_NAME"
UP=$(api -X POST -H "Content-Type: application/x-apple-diskimage" --data-binary @"$DMG" \
  "https://uploads.github.com/repos/$REPO/releases/$RID/assets?name=$DMG_NAME")
URL=$(echo "$UP" | json "d['browser_download_url']")
echo "==> 完成：$URL"
echo "    https://github.com/$REPO/releases/tag/$TAG"
