#!/usr/bin/env bash
# 由 web/wallpaper-h5-icons/app/app-icon-1024.png 生成 iOS 图标（1024 满铺方形，iOS 自动套圆角）。
# 依赖：python3 + Pillow（pip3 install pillow）
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - <<'PY'
from PIL import Image
im = Image.open('../web/wallpaper-h5-icons/app/app-icon-1024.png').convert('RGBA')
inset = 96
c = im.crop((inset, inset, 1024 - inset, 1024 - inset)).resize((1024, 1024), Image.LANCZOS)
bg = Image.new('RGBA', (1024, 1024), (10, 13, 16, 255))
bg.alpha_composite(c)
bg.convert('RGB').save('Sources/Duopaper/Assets.xcassets/AppIcon.appiconset/AppIcon.png')
PY
echo "==> 已生成 iOS AppIcon.png"
