#!/bin/bash
# diskc 卸载脚本
set -e

PREFIX="${PREFIX:-$HOME/.local}"
BIN="$PREFIX/bin"
APPS="$PREFIX/share/applications"
ICONS="$PREFIX/share/icons/hicolor"

rm -f "$BIN/diskc" "$BIN/diskc-gui"
rm -f "$APPS/diskc.desktop"
rm -f "$ICONS/scalable/apps/diskc.svg"
for size in 24 32 48 64 128 256; do
    rm -f "$ICONS/${size}x${size}/apps/diskc.png"
done

command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -f -t "$ICONS" 2>/dev/null || true
command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" 2>/dev/null || true

echo "已卸载。"
