#!/usr/bin/env bash
# 由 web/wallpaper-h5-icons/app/app-icon-1024.png 生成 macOS 图标 AppIcon.icns。
# 按 Apple 图标网格把图标缩到 824/1024，四周留透明边距，与系统其他图标视觉大小一致。
# 依赖：python3 + Pillow（pip3 install pillow）
set -euo pipefail
cd "$(dirname "$0")/.."

SRC="../web/wallpaper-h5-icons/app/app-icon-1024.png"
OUT="Sources/Duopaper/AppIcon.icns"
SET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$SET"

python3 - "$SRC" "$SET" <<'PY'
import sys
from PIL import Image
src, out = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGBA")
canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
inner = im.resize((824, 824), Image.LANCZOS)
canvas.paste(inner, (100, 100), inner)
for s in (16, 32, 128, 256, 512):
    canvas.resize((s, s), Image.LANCZOS).save(f"{out}/icon_{s}x{s}.png")
    canvas.resize((s * 2, s * 2), Image.LANCZOS).save(f"{out}/icon_{s}x{s}@2x.png")
PY

iconutil -c icns "$SET" -o "$OUT"
echo "==> 已生成 $OUT"
