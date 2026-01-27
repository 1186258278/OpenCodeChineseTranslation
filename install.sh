#!/bin/bash
set -e

# OpenCode 汉化工具一键安装脚本 (Go CLI 版)
# 支持: Linux x64/ARM64, macOS x64/ARM64 (Apple Silicon)

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

echo -e "${CYAN}==============================================${NC}"
echo -e "${CYAN}   OpenCode 汉化管理工具安装脚本 (v8.6.0)   ${NC}"
echo -e "${CYAN}==============================================${NC}"

# 1. 系统兼容性检测
echo -e "\n${YELLOW}[1/4] 检测系统兼容性...${NC}"
OS_RAW="$(uname -s)"
ARCH_RAW="$(uname -m)"

# 检测操作系统
case "$OS_RAW" in
    Linux)
        OS="linux"
        # 检测是否为 WSL
        if grep -qi microsoft /proc/version 2>/dev/null; then
            echo -e "${GRAY}  检测到 WSL 环境${NC}"
        fi
        # 检测发行版
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            echo -e "${GRAY}  发行版: $NAME $VERSION_ID${NC}"
        fi
        ;;
    Darwin)
        OS="darwin"
        # 检测 macOS 版本
        MACOS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
        echo -e "${GRAY}  macOS 版本: $MACOS_VERSION${NC}"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        echo -e "${RED}✗ 错误: 请使用 PowerShell 安装脚本${NC}"
        echo -e "${RED}  irm https://cdn.jsdelivr.net/gh/1186258278/OpenCodeChineseTranslation@main/install.ps1 | iex${NC}"
        exit 1
        ;;
    *)
        echo -e "${RED}✗ 错误: 不支持的系统: $OS_RAW${NC}"
        echo -e "${RED}  支持的系统: Linux, macOS${NC}"
        exit 1
        ;;
esac

# 检测架构
case "$ARCH_RAW" in
    x86_64|amd64)
        ARCH="amd64"
        ;;
    arm64|aarch64)
        ARCH="arm64"
        ;;
    armv7l|armhf)
        echo -e "${RED}✗ 错误: 不支持 32 位 ARM 架构${NC}"
        echo -e "${RED}  OpenCode 仅支持 64 位系统 (x64/ARM64)${NC}"
        exit 1
        ;;
    i386|i686)
        echo -e "${RED}✗ 错误: 不支持 32 位 x86 架构${NC}"
        echo -e "${RED}  OpenCode 仅支持 64 位系统 (x64/ARM64)${NC}"
        exit 1
        ;;
    *)
        echo -e "${RED}✗ 错误: 不支持的架构: $ARCH_RAW${NC}"
        echo -e "${RED}  支持的架构: x86_64, arm64${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}系统: $OS $ARCH${NC}"

# 2. 解析参数
TARGET_VERSION=""
for arg in "$@"; do
    case $arg in
        --version=*)
            TARGET_VERSION="${arg#*=}"
            shift
            ;;
        --version)
            TARGET_VERSION="$2"
            shift 2
            ;;
    esac
done

# 3. 准备安装目录
INSTALL_DIR="$HOME/.opencode-i18n"
BIN_DIR="$INSTALL_DIR/bin"
mkdir -p "$BIN_DIR"

BINARY_NAME="opencode-cli-$OS-$ARCH"
TARGET_PATH="$BIN_DIR/opencode-cli"

# 4. 检查本地文件 (离线安装支持)
LOCAL_FILE="./$BINARY_NAME"
if [ -f "$LOCAL_FILE" ] && [ -z "$TARGET_VERSION" ]; then
    echo -e "\n${YELLOW}[2/4] 检测到本地安装包...${NC}"
    echo -e "${GREEN}正在从本地安装: $LOCAL_FILE${NC}"
    cp "$LOCAL_FILE" "$TARGET_PATH"
else
    # 5. 在线下载
    echo -e "\n${YELLOW}[2/4] 获取版本信息...${NC}"
    REPO="1186258278/OpenCodeChineseTranslation"
    VERSION="v8.6.0" # 默认 fallback

    if [ -n "$TARGET_VERSION" ]; then
        VERSION="$TARGET_VERSION"
        echo -e "${GREEN}使用指定版本: $VERSION${NC}"
    else
        # 尝试获取最新版本
        if command -v curl >/dev/null 2>&1; then
            LATEST_VERSION=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
            if [ ! -z "$LATEST_VERSION" ]; then
                VERSION="$LATEST_VERSION"
                echo -e "${GREEN}发现最新版本: $VERSION${NC}"
            else
                echo -e "${YELLOW}获取最新版本失败，将使用默认版本: $VERSION${NC}"
            fi
        elif command -v wget >/dev/null 2>&1; then
            # wget 的 stdout 输出比较嘈杂，使用 -qO-
            LATEST_VERSION=$(wget -qO- "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
            if [ ! -z "$LATEST_VERSION" ]; then
                VERSION="$LATEST_VERSION"
                echo -e "${GREEN}发现最新版本: $VERSION${NC}"
            else
                 echo -e "${YELLOW}获取最新版本失败，将使用默认版本: $VERSION${NC}"
            fi
        fi
    fi

    DOWNLOAD_URL="https://github.com/$REPO/releases/download/$VERSION/$BINARY_NAME"

    echo -e "\n${YELLOW}[3/4] 下载管理工具...${NC}"
    echo -e "${NC}地址: $DOWNLOAD_URL${NC}"

    # 备份旧文件
    if [ -f "$TARGET_PATH" ]; then
        mv "$TARGET_PATH" "$TARGET_PATH.old" 2>/dev/null || true
    fi

    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$TARGET_PATH" "$DOWNLOAD_URL"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$TARGET_PATH" "$DOWNLOAD_URL"
    else
        echo -e "${RED}错误: 未找到 curl 或 wget，无法下载。${NC}"
        exit 1
    fi
fi

chmod +x "$TARGET_PATH"
echo -e "${GREEN}安装成功!${NC}"

# 5. 配置环境
echo -e "\n${YELLOW}[4/4] 配置环境变量...${NC}"

SHELL_NAME=$(basename "$SHELL")
RC_FILE=""

case "$SHELL_NAME" in
    bash) RC_FILE="$HOME/.bashrc" ;;
    zsh)  RC_FILE="$HOME/.zshrc" ;;
    fish) RC_FILE="$HOME/.config/fish/config.fish" ;;
    *)    RC_FILE="$HOME/.profile" ;;
esac

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    if [ "$SHELL_NAME" = "fish" ]; then
        echo "set -gx PATH \$PATH $BIN_DIR" >> "$RC_FILE"
    else
        echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$RC_FILE"
    fi
    echo -e "${GREEN}已将 $BIN_DIR 添加到 $RC_FILE${NC}"
    echo -e "${YELLOW}请执行 source $RC_FILE 或重启终端使配置生效${NC}"
else
    echo -e "${GREEN}环境变量已配置${NC}"
fi

echo -e "\n${GREEN}==============================================${NC}"
echo -e "${GREEN}   安装完成!   ${NC}"
echo -e "${GREEN}==============================================${NC}"
echo -e "\n${NC}请重启终端，然后运行以下命令启动:${NC}"
echo -e "${CYAN}  opencode-cli interactive${NC}"
