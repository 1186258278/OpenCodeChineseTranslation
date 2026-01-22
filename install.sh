#!/bin/bash

# OpenCode 汉化工具一键安装脚本 (v2.0)
# 自动解决依赖，支持 Linux/macOS

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="$HOME/.opencode-i18n"
BIN_DIR="$INSTALL_DIR/bin"
WRAPPER_SCRIPT="$BIN_DIR/opencodenpm"

echo -e "${CYAN}==============================================${NC}"
echo -e "${CYAN}   OpenCode 汉化管理工具一键安装脚本   ${NC}"
echo -e "${CYAN}==============================================${NC}"

# --- 1. 基础工具检查 ---
echo -e "\n${YELLOW}[1/6] 检查系统工具...${NC}"

has_cmd() {
    command -v "$1" &> /dev/null
}

if ! has_cmd curl; then
    echo -e "${RED}错误: 未找到 curl。请先安装: sudo apt install curl 或 brew install curl${NC}"
    exit 1
fi

if ! has_cmd unzip; then
    echo -e "${YELLOW}未找到 unzip，尝试自动安装...${NC}"
    if has_cmd apt-get; then
        sudo apt-get update && sudo apt-get install -y unzip
    elif has_cmd yum; then
        sudo yum install -y unzip
    else
        echo -e "${RED}错误: 无法自动安装 unzip。请手动安装后重试。${NC}"
        exit 1
    fi
fi

# --- 2. 运行时环境检查与安装 ---
echo -e "\n${YELLOW}[2/6] 检查运行时环境 (Node.js / Bun)...${NC}"

RUNTIME=""

# 优先检查 Node.js
if has_cmd node; then
    echo -e "${GREEN}✓ 检测到 Node.js ($(node -v))${NC}"
    RUNTIME="node"
# 其次检查 Bun
elif has_cmd bun; then
    echo -e "${GREEN}✓ 检测到 Bun ($(bun -v))${NC}"
    RUNTIME="bun"
else
    echo -e "${YELLOW}未检测到 Node.js 或 Bun。${NC}"
    echo -e "${CYAN}正在为您自动安装 Bun 环境...${NC}"
    
    # 自动安装 Bun
    echo -e "尝试安装 Bun..."
    if curl -fsSL https://bun.sh/install | bash; then
        export BUN_INSTALL="$HOME/.bun"
        export PATH="$BUN_INSTALL/bin:$PATH"
        
        # 验证 Bun 是否可用 (检查 glibc 等问题)
        if "$BUN_INSTALL/bin/bun" --version >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Bun 安装成功 ($("$BUN_INSTALL/bin/bun" --version))${NC}"
            RUNTIME="bun"
        else
            echo -e "${YELLOW}Bun 安装成功但无法运行 (可能是系统 glibc 版本过低)。${NC}"
            echo -e "${YELLOW}尝试回退安装 Node.js...${NC}"
        fi
    else
        echo -e "${YELLOW}Bun 下载失败。尝试安装 Node.js...${NC}"
    fi

    # 如果 Bun 不可用，尝试安装 Node.js
    if [ -z "$RUNTIME" ]; then
        echo -e "正在安装 Node.js LTS..."
        # 使用 nvm 安装 node (更通用)
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        if command -v nvm >/dev/null 2>&1; then
            nvm install --lts
            RUNTIME="node"
        else
            echo -e "${RED}错误: 无法自动安装运行时环境。${NC}"
            echo -e "${YELLOW}请您的系统版本较旧，请手动安装 Node.js (v18+) 后重试。${NC}"
            exit 1
        fi
    fi
fi

# --- 3. 获取最新版本 ---
echo -e "\n${YELLOW}[3/6] 获取最新版本信息...${NC}"
REPO="1186258278/OpenCodeChineseTranslation"
# 使用 GitHub API 获取最新 release tag，如果失败则尝试 default (容错)
LATEST_JSON=$(curl -s --max-time 10 "https://api.github.com/repos/$REPO/releases/latest")
TAG_NAME=$(echo "$LATEST_JSON" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$TAG_NAME" ]; then
    echo -e "${YELLOW}警告: 无法获取最新版本，尝试使用默认版本 v7.3.2${NC}"
    TAG_NAME="v7.3.2"
else
    echo -e "最新版本: ${GREEN}${TAG_NAME}${NC}"
fi

# --- 4. 下载与解压 ---
echo -e "\n${YELLOW}[4/6] 下载汉化工具...${NC}"
ZIP_URL="https://github.com/$REPO/releases/download/$TAG_NAME/opencode-i18n-tool-$TAG_NAME.zip"
TEMP_ZIP="/tmp/opencode-i18n.zip"

echo -e "下载地址: $ZIP_URL"
if curl -L --progress-bar -o "$TEMP_ZIP" "$ZIP_URL"; then
    echo -e "${GREEN}下载成功!${NC}"
else
    echo -e "${RED}下载失败! 请检查网络连接或版本号。${NC}"
    exit 1
fi

echo -e "安装到: $INSTALL_DIR"
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
fi
mkdir -p "$INSTALL_DIR"
unzip -q "$TEMP_ZIP" -d "$INSTALL_DIR"
rm "$TEMP_ZIP"

# --- 5. 安装依赖 ---
echo -e "\n${YELLOW}[5/6] 安装项目依赖...${NC}"
cd "$INSTALL_DIR/scripts"

if [ "$RUNTIME" == "bun" ]; then
    bun install --production
else
    npm install --production
fi

# --- 6. 创建启动脚本 ---
echo -e "\n${YELLOW}[6/6] 配置全局命令...${NC}"

mkdir -p "$BIN_DIR"

# 创建 wrapper 脚本
cat > "$WRAPPER_SCRIPT" <<EOF
#!/bin/bash
export PATH="\$HOME/.bun/bin:\$PATH"
if command -v node >/dev/null 2>&1; then
    exec node "$INSTALL_DIR/scripts/bin/opencodenpm" "\$@"
elif command -v bun >/dev/null 2>&1; then
    exec bun "$INSTALL_DIR/scripts/bin/opencodenpm" "\$@"
else
    echo "Error: Runtime not found. Please install Node.js or Bun."
    exit 1
fi
EOF

chmod +x "$WRAPPER_SCRIPT"

# 尝试链接到系统路径
LINK_SUCCESS=false
TARGET_LINK="/usr/local/bin/opencodenpm"

if [ -w "/usr/local/bin" ]; then
    ln -sf "$WRAPPER_SCRIPT" "$TARGET_LINK"
    LINK_SUCCESS=true
else
    echo -e "${YELLOW}尝试使用 sudo 创建全局链接...${NC}"
    if sudo ln -sf "$WRAPPER_SCRIPT" "$TARGET_LINK"; then
        LINK_SUCCESS=true
    fi
fi

echo -e "\n${GREEN}==============================================${NC}"
if [ "$LINK_SUCCESS" = true ]; then
    echo -e "${GREEN}   安装成功!   ${NC}"
    echo -e "${GREEN}==============================================${NC}"
    echo -e "\n现在你可以在任意位置运行: ${CYAN}opencodenpm${NC}"
else
    echo -e "${YELLOW}   安装完成 (未创建全局链接)   ${NC}"
    echo -e "${GREEN}==============================================${NC}"
    echo -e "\n请手动将以下路径添加到 PATH，或直接运行:"
    echo -e "  ${CYAN}$WRAPPER_SCRIPT${NC}"
fi

# 提示 Bun 环境变量
if [ "$RUNTIME" == "bun" ] && [[ ":$PATH:" != *":$HOME/.bun/bin:"* ]]; then
    echo -e "\n${YELLOW}注意: 检测到您使用自动安装的 Bun。${NC}"
    echo -e "请执行以下命令使其生效 (或重启终端):"
    echo -e "  ${CYAN}export PATH=\"\$HOME/.bun/bin:\$PATH\"${NC}"
fi
