#!/bin/bash
# 构建可分发的安装包:deb(双击安装) + 源码 tar.gz
# 用法: ./build.sh [版本号]
set -e

cd "$(dirname "$0")"
VERSION="${1:-${VERSION:-1.2.0}}"
PKG=disk-cleaner
BUILD=build
DIST=dist
ROOT="$BUILD/${PKG}_${VERSION}_all"

rm -rf "$BUILD" "$DIST"
mkdir -p "$DIST" "$ROOT/DEBIAN" \
         "$ROOT/usr/bin" \
         "$ROOT/usr/share/applications" \
         "$ROOT/usr/share/doc/$PKG" \
         "$ROOT/usr/share/icons/hicolor/scalable/apps"

for s in 24x24 32x32 48x48 64x64 128x128 256x256; do
    mkdir -p "$ROOT/usr/share/icons/hicolor/$s/apps"
done

# 程序
install -m 755 diskc "$ROOT/usr/bin/diskc"
install -m 755 diskc-gui "$ROOT/usr/bin/diskc-gui"

# 图标
install -m 644 assets/diskc.svg "$ROOT/usr/share/icons/hicolor/scalable/apps/diskc.svg"
python3 - "$ROOT/usr/share/icons/hicolor" "$PWD/assets/diskc.svg" <<'PY'
import os
import sys

import gi
gi.require_version('GdkPixbuf', '2.0')
from gi.repository import GdkPixbuf

icons, src = sys.argv[1], sys.argv[2]
for size in (24, 32, 48, 64, 128, 256):
    d = os.path.join(icons, '%dx%d' % (size, size), 'apps')
    os.makedirs(d, exist_ok=True)
    GdkPixbuf.Pixbuf.new_from_file_at_scale(src, size, size, True) \
        .savev(os.path.join(d, 'diskc.png'), 'png', [], [])
PY

# polkit 动作:让 pkexec 的授权框显示友好文案
mkdir -p "$ROOT/usr/share/polkit-1/actions"
install -m 644 packaging/org.diskcleaner.policy \
    "$ROOT/usr/share/polkit-1/actions/org.diskcleaner.policy"

# 文档
install -m 644 README.md "$ROOT/usr/share/doc/$PKG/README.md"
install -m 644 LICENSE "$ROOT/usr/share/doc/$PKG/copyright"

# 启动器条目
cat > "$ROOT/usr/share/applications/disk-cleaner.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=Disk Cleaner
Name[zh_CN]=磁盘垃圾清理
GenericName=Disk Cleaner
Comment=Scan and clean system logs, packages, WeCom cache and other junk files
Comment[zh_CN]=扫描并清理系统日志、安装包、企业微信缓存等垃圾文件
Exec=/usr/bin/diskc-gui
Icon=diskc
Terminal=false
Categories=System;Utility;
Keywords=disk;clean;junk;cache;清理;垃圾;磁盘;缓存;
StartupNotify=false
EOF

# changelog(避免 lintian 报缺文件)
mkdir -p "$ROOT/usr/share/doc/$PKG"
{
    echo "$PKG ($VERSION) unstable; urgency=low"
    echo
    echo "  * 首次发布:图形界面 + 命令行,18 个清理类别,风险分级。"
    echo
    echo " -- 王少君 <wangshaojun@uniontech.com>  $(date -R)"
} | gzip -9n > "$ROOT/usr/share/doc/$PKG/changelog.Debian.gz"

# control
SIZE=$(du -sk --exclude=DEBIAN "$ROOT" | cut -f1)
cat > "$ROOT/DEBIAN/control" <<EOF
Package: $PKG
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Installed-Size: $SIZE
Depends: python3 (>= 3.5), python3-gi, gir1.2-gtk-3.0
Recommends: dde-file-manager
Maintainer: 王少君 <wangshaojun@uniontech.com>
Description: 磁盘垃圾清理工具(图形界面 + 命令行)
 扫描并清理系统日志、apt 缓存、崩溃转储、企业微信下载的日志包与
 解压目录、deb 安装包、视频和各类开发缓存。按风险分为安全、谨慎、
 高风险三级,默认只勾选安全项,每个类别都能展开查看具体文件并在
 文件管理器中定位。
EOF

# 构建
dpkg-deb --build --root-owner-group "$ROOT" "$DIST/${PKG}_${VERSION}_all.deb" >/dev/null

# 源码包(只含 git 跟踪的文件)
if git rev-parse --git-dir >/dev/null 2>&1; then
    git archive --format=tar.gz --prefix="${PKG}-${VERSION}/" \
        -o "$DIST/${PKG}-${VERSION}.tar.gz" HEAD
fi

echo "构建完成:"
ls -lh "$DIST"
