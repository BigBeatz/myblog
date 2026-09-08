#!/usr/bin/env bash
set -euo pipefail
# cf-pages-build.sh
# Lightweight build helper for Cloudflare Pages:
# - initializes git submodules (themes)
# - downloads Hugo Extended if not present
# - runs hugo to produce the site in ./public

# Set desired Hugo version (can be overridden via CF environment variable HUGO_VERSION)
HUGO_VERSION="${HUGO_VERSION:-0.111.3}"

# init submodules (themes)
git submodule update --init --recursive

# if we have hugo and it's extended, use it
if command -v hugo >/dev/null 2>&1; then
  if hugo version | grep -qi "extended"; then
    echo "Using system hugo (extended): $(hugo version)"
    hugo --gc --minify
    exit 0
  else
    echo "System hugo found but not extended; will download hugo_extended ${HUGO_VERSION}"
  fi
fi

# Download Hugo Extended binary for the build environment
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

# Hugo release file naming uses mixed-case for macOS; ensure exact name for Linux.
TAR_NAME="hugo_extended_${HUGO_VERSION}_${OS_PKG}-${ARCH_PKG}.tar.gz"
DOWNLOAD_URL="https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${TAR_NAME}"

echo "Downloading Hugo Extended from ${DOWNLOAD_URL}"

# download and extract locally
curl -sSL "$DOWNLOAD_URL" -o /tmp/hugo.tar.gz
mkdir -p /tmp/hugo_extract
tar -xzf /tmp/hugo.tar.gz -C /tmp/hugo_extract
# find the hugo binary
HUGO_BIN=$(find /tmp/hugo_extract -type f -name hugo -print -quit)
if [ -z "$HUGO_BIN" ]; then
  echo "Failed to find hugo binary in archive" >&2
  ls -la /tmp/hugo_extract
  exit 1
fi
chmod +x "$HUGO_BIN"
export PATH="/tmp/hugo_extract:$PATH"

echo "Using downloaded hugo: $($HUGO_BIN version)"
# build
"$HUGO_BIN" --gc --minify
