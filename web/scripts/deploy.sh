#!/usr/bin/env bash
# 用法：npm run deploy -- "提交说明"   （说明可省略）
# 流程：本地构建校验 -> 提交 -> 推送 main -> 触发 GitHub Actions 部署 Pages
set -euo pipefail
cd "$(dirname "$0")/.."
WEB_DIR="$PWD"
cd ..
ROOT_DIR="$PWD"

REPO="jrainlau/duopaper"
MSG="${1:-deploy: $(date '+%Y-%m-%d %H:%M:%S')}"

echo "==> 本地构建校验"
(cd "$WEB_DIR" && npm run build)

# 从 ~/.zshrc 读取 GITHUB_TOKEN，仅通过一次性 header 注入，不写入 git 配置
if [ -z "${GITHUB_TOKEN:-}" ]; then
  GITHUB_TOKEN=$(grep -E '^export GITHUB_TOKEN=' "$HOME/.zshrc" | head -1 | sed -E 's/^export GITHUB_TOKEN=//; s/^["'"'"']//; s/["'"'"']$//')
fi
[ -n "$GITHUB_TOKEN" ] || { echo "未找到 GITHUB_TOKEN"; exit 1; }
AUTH=$(printf 'x-access-token:%s' "$GITHUB_TOKEN" | base64)

git add -A
if git diff --cached --quiet; then
  echo "==> 没有新改动，直接重新推送触发（空提交）"
  git commit --allow-empty -q -m "$MSG"
else
  git commit -q -m "$MSG"
fi

echo "==> 推送 main"
git -c "http.extraheader=Authorization: Basic $AUTH" push origin HEAD:main

echo "==> 已推送，workflow 构建中："
echo "    https://github.com/$REPO/actions"
echo "    站点：https://jrainlau.github.io/duopaper/"
