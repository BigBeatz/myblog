#!/usr/bin/env bash
set -euo pipefail

# 设置你需要的 Hugo 版本
HUGO_VERSION="${HUGO_VERSION:-0.146.0}"

# 1. 核心修复：不管三七二十一，先检查并把 PaperMod 主题从 GitHub 实时克隆到构建环境中
THEME_DIR="themes/PaperMod"
echo "Checking and downloading PaperMod theme..."
rm -rf "$THEME_DIR"
mkdir -p themes
git clone --depth 1 https://github.com/adityatelange/hugo-PaperMod.git "$THEME_DIR"

# 2. 自动下载指定版本的 Hugo Extended（确保渲染正常）
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

# 3. 正式执行构建
"$HUGO_BIN" --gc --minify
