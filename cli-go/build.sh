#!/bin/bash
# OpenCode CLI 跨平台编译脚本

set -e

APP_NAME="opencode-cli"
VERSION="8.6.0"

# 输出目录
OUTPUT_DIR="dist"
mkdir -p "$OUTPUT_DIR"

echo "📦 构建 $APP_NAME v$VERSION"
echo ""

# 构建函数
build() {
    local GOOS=$1
    local GOARCH=$2
    local EXT=$3
    local OUTPUT="${OUTPUT_DIR}/${APP_NAME}-${GOOS}-${GOARCH}${EXT}"
    
    echo "  → 构建 ${GOOS}/${GOARCH}..."
    GOOS=$GOOS GOARCH=$GOARCH go build -ldflags="-s -w" -o "$OUTPUT" .
    echo "    ✓ $OUTPUT"
}

# Windows
build windows amd64 .exe
build windows arm64 .exe

# macOS
build darwin amd64 ""
build darwin arm64 ""

# Linux
build linux amd64 ""
build linux arm64 ""

echo ""
echo "✓ 构建完成!"
echo ""
ls -lh "$OUTPUT_DIR"
