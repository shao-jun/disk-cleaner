#!/bin/bash
# diskc 安装脚本:装到 ~/.local,不需要 root
set -e

SRC="$(cd "$(dirname "$0")" && pwd)"
PREFIX="${PREFIX:-$HOME/.local}"
BIN="$PREFIX/bin"
APPS="$PREFIX/share/applications"
ICONS="$PREFIX/share/icons/hicolor"

mkdir -p "$BIN" "$APPS" "$ICONS/scalable/apps"
install -m 755 "$SRC/diskc" "$BIN/diskc"
install -m 755 "$SRC/diskc-gui" "$BIN/diskc-gui"
install -m 644 "$SRC/assets/diskc.svg" "$ICONS/scalable/apps/diskc.svg"

# 生成各尺寸 png(部分环境对 svg 图标支持不佳),失败不影响安装
python3 - "$SRC/assets/diskc.svg" "$ICONS" <<'PY' 2>/dev/null || true
import os
import sys

import gi
gi.require_version('GdkPixbuf', '2.0')
from gi.repository import GdkPixbuf

src, icons = sys.argv[1], sys.argv[2]
for size in (24, 32, 48, 64, 128, 256):
    d = os.path.join(icons, '%dx%d' % (size, size), 'apps')
    os.makedirs(d, exist_ok=True)
    pb = GdkPixbuf.Pixbuf.new_from_file_at_scale(src, size, size, True)
    pb.savev(os.path.join(d, 'diskc.png'), 'png', [], [])
PY

command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -f -t "$ICONS" 2>/dev/null || true

sed "s|@EXEC@|$BIN/diskc-gui|g" "$SRC/diskc.desktop.in" > "$APPS/diskc.desktop"
command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" 2>/dev/null || true

echo "安装完成:"
echo "  启动器搜索「磁盘垃圾清理」"
echo "  或终端执行 diskc"
