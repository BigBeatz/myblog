#!/usr/bin/env bash
set -euo pipefail

# 设置 Hugo 版本（满足 PaperMod v0.146.0+ 的硬性要求）
HUGO_VERSION="${HUGO_VERSION:-0.146.0}"

# 1. 优化：改用 curl 下载 PaperMod 主题的压缩包并解压（秒级完成，绝不卡死）
THEME_DIR="themes/PaperMod"
echo "Downloading PaperMod theme via ZIP..."
rm -rf "$THEME_DIR"
mkdir -p "$THEME_DIR"

curl -sL https://github.com/adityatelange/hugo-PaperMod/archive/refs/heads/master.zip -o /tmp/papermod.zip
unzip -q /tmp/papermod.zip -d /tmp/
mv /tmp/hugo-PaperMod-master/* "$THEME_DIR/"

# 2. 下载并安装指定版本的 Hugo Extended
OS_NAME="$(uname)"
ARCH_NAME="$(uname -m)"
case "$OS_NAME" in
  Linux) OS_PKG=Linux ;;
  Darwin) OS_PKG=macOS ;;
  *) OS_PKG=Linux ;;
esac
case "$ARCH_NAME" in
  x86_64|amd64) ARCH_PKG=64bit ;;
  aarch64|arm64) ARCH_PKG=ARM64 ;;
  *) ARCH_PKG=64bit ;;
esac

TAR_NAME="hugo_extended_${HUGO_VERSION}_${OS_PKG}-${ARCH_PKG}.tar.gz"
DOWNLOAD_URL="https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${TAR_NAME}"

echo "Downloading Hugo Extended from ${DOWNLOAD_URL}"
curl -sSL "$DOWNLOAD_URL" -o /tmp/hugo.tar.gz
mkdir -p /tmp/hugo_extract
tar -xzf /tmp/hugo.tar.gz -C /tmp/hugo_extract

HUGO_BIN=$(find /tmp/hugo_extract -type f -name hugo -print -quit)
if [ -z "$HUGO_BIN" ]; then
  echo "Failed to find hugo binary in archive" >&2
  exit 1
fi
chmod +x "$HUGO_BIN"

echo "Using downloaded hugo: $($HUGO_BIN version)"

# 3. 执行正式构建
"$HUGO_BIN" --gc --minify
