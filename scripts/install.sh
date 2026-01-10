#!/bin/bash
# ========================================
# OpenCode 汉化版 - 一键安装脚本 v2.2
# Linux/macOS 完整安装
# 使用方式: curl -fsSL https://gitee.com/QtCodeCreators/OpenCodeChineseTranslation/raw/main/scripts/install.sh | bash
# ========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

print_banner() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}${WHITE}     OpenCode 中文汉化版 - 一键安装脚本 v2.2            ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}${WHITE}     Linux/macOS                                           ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}" >&2
}

print_info() {
    echo -e "${GRAY}  $1${NC}"
}

# 清理旧脚本
cleanup_old_scripts() {
    echo -e "${GRAY}[清理] 检查旧脚本...${NC}"

    local cleaned=false

    # 清理旧的全局命令
    if [ -f "$HOME/.local/bin/opencodecmd" ]; then
        rm -f "$HOME/.local/bin/opencodecmd"
        echo -e "${GRAY}  ✓ 删除旧的 opencodecmd${NC}"
        cleaned=true
    fi

    # 清理旧的 Codes 脚本
    if [ -f "$HOME/.local/bin/codes" ]; then
        rm -f "$HOME/.local/bin/codes"
        echo -e "${GRAY}  ✓ 删除旧的 codes 命令${NC}"
        cleaned=true
    fi

    # 清理旧的 Codes 库目录
    if [ -d "$HOME/.local/share/codes" ]; then
        rm -rf "$HOME/.local/share/codes"
        echo -e "${GRAY}  ✓ 删除旧的 Codes 库${NC}"
        cleaned=true
    fi

    if [ "$cleaned" = true ]; then
        echo -e "${GREEN}✓ 清理完成${NC}"
    else
        echo -e "${GRAY}  无需清理${NC}"
    fi
    echo ""
}

print_banner
cleanup_old_scripts

# 检测系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

has_cmd() {
    command -v "$1" &> /dev/null
}

# 确定安装目录
CURRENT_DIR="$(pwd)"
REPO_NAME="OpenCodeChineseTranslation"

if [ -d "$CURRENT_DIR/.git" ] && [ -d "$CURRENT_DIR/opencode-i18n" ]; then
    PROJECT_DIR="$CURRENT_DIR"
elif [ -d "$HOME/$REPO_NAME/.git" ]; then
    PROJECT_DIR="$HOME/$REPO_NAME"
elif [ -z "$(ls -A "$CURRENT_DIR" 2>/dev/null)" ]; then
    PROJECT_DIR="$CURRENT_DIR"
else
    PROJECT_DIR="$CURRENT_DIR/$REPO_NAME"
fi

# ==================== 安装前确认 ====================
echo -e "${CYAN}即将安装 OpenCode 中文汉化版${NC}"
echo ""
echo -e "${WHITE}安装目录:${NC} ${GRAY}$PROJECT_DIR${NC}"
echo -e "${WHITE}内容包括:${NC}"
echo -e "  ${GRAY}• 自动清理旧脚本${NC}"
echo -e "  ${GRAY}• OpenCode 源码${NC}"
echo -e "  ${GRAY}• Codes 工具${NC}"
echo -e "  ${GRAY}• 汉化管理工具${NC}"
echo -e "  ${GRAY}• 全局命令 opencodecmd${NC}"
echo ""
echo -n -e "${YELLOW}按 Enter 继续，Ctrl+C 取消...${NC} "
read
echo ""

# ==================== 1/7 检查环境 ====================
print_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}" >&2
}

print_info() {
    echo -e "${GRAY}  $1${NC}"
}

# ==================== 1/7 检查环境 ====================
print_step "1/7 检查系统环境..."
OS_TYPE=$(detect_os)
print_info "操作系统: $OS_TYPE"

if has_cmd node; then
    NODE_VER=$(node -v)
    print_success "Node.js: $NODE_VER"
else
    print_info "Node.js: 未安装 (将自动安装)"
fi

if has_cmd git; then
    GIT_VER=$(git --version | awk '{print $3}')
    print_success "Git: $GIT_VER"
else
    print_info "Git: 未安装 (将自动安装)"
fi
echo ""

# ==================== 2. 确定安装目录 ====================
print_step "2/7 确定安装目录..."
print_info "安装目录: $PROJECT_DIR"
echo ""

# ==================== 3. 克隆/更新仓库 ====================
print_step "3/7 获取项目文件..."

if [ -d "$PROJECT_DIR/.git" ]; then
    print_info "更新现有仓库..."
    cd "$PROJECT_DIR"
    if git pull --rebase > /dev/null 2>&1; then
        print_success "更新成功"
    else
        print_info "已是最新版本或更新失败（继续）"
    fi
else
    # 如果目录存在但不是 git 仓库，先删除
    if [ -d "$PROJECT_DIR" ] && [ ! -d "$PROJECT_DIR/.git" ]; then
        print_info "清理非 Git 目录..."
        rm -rf "$PROJECT_DIR"
    fi

    print_info "克隆仓库..."

    # 克隆 URL 列表（按优先级）
    CLONE_URLS=(
        "https://gitee.com/QtCodeCreators/OpenCodeChineseTranslation.git"
        "https://github.com/1186258278/OpenCodeChineseTranslation.git"
    )

    SOURCE_NAMES=("Gitee" "GitHub")
    CLONE_SUCCESS=false

    for i in "${!CLONE_URLS[@]}"; do
        URL="${CLONE_URLS[$i]}"
        SOURCE="${SOURCE_NAMES[$i]}"

        print_info "尝试从 $SOURCE 克隆..."

        if git clone --depth 1 "$URL" "$PROJECT_DIR" > /dev/null 2>&1; then
            print_success "从 $SOURCE 克隆成功"
            CLONE_SUCCESS=true
            break
        fi
    done

    if [ "$CLONE_SUCCESS" = false ]; then
        print_error "克隆失败，请检查网络连接"
        echo ""
        echo -e "${YELLOW}可以手动克隆:${NC}"
        echo "  git clone https://gitee.com/QtCodeCreators/OpenCodeChineseTranslation.git"
        echo "  cd OpenCodeChineseTranslation"
        echo "  ./scripts/opencode-linux/opencode.js"
        exit 1
    fi

    cd "$PROJECT_DIR"
fi
echo ""

# ==================== 4. 安装依赖 ====================
print_step "4/7 安装依赖..."

# 安装 Codes 工具（如果需要）
if ! has_cmd codes; then
    print_info "安装 Codes 管理工具..."
    if bash "$PROJECT_DIR/scripts/codes/install.sh" > /dev/null 2>&1; then
        export PATH="$HOME/.local/bin:$PATH"
        hash -r 2>/dev/null
        print_success "Codes 已安装"
    else
        print_info "Codes 安装跳过（非必须）"
    fi
else
    print_success "Codes 已安装"
fi

# 检查 Node.js
if ! has_cmd node; then
    print_info "安装 Node.js..."
    if has_cmd codes; then
        codes install 1 > /dev/null 2>&1
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        export PATH="$NVM_DIR/versions/node/*/bin:$PATH"
        print_success "Node.js 已安装"
    else
        print_error "无法自动安装 Node.js，请手动安装"
        exit 1
    fi
fi
echo ""

# ==================== 5. 安装汉化脚本 ====================
print_step "5/7 安装汉化管理工具..."

I18N_DIR="$PROJECT_DIR/scripts/opencode-linux"

if [ ! -d "$I18N_DIR" ]; then
    mkdir -p "$I18N_DIR/lib"
fi

# 安装 npm 依赖
if [ ! -d "$I18N_DIR/node_modules" ]; then
    print_info "安装 npm 依赖..."
    cd "$I18N_DIR" && npm install > /dev/null 2>&1
    cd "$PROJECT_DIR"
fi

print_success "汉化管理工具已就绪"
echo ""

# ==================== 6. 创建全局命令 ====================
print_step "6/7 创建全局命令..."

CMD_DIR="$HOME/.local/bin"
mkdir -p "$CMD_DIR" 2>/dev/null

# 创建独立的 opencodecmd 脚本（不依赖 install.sh 的函数）
cat > "$CMD_DIR/opencodecmd" << 'OPENCODECMD_EOF'
#!/bin/bash
# OpenCode 中文汉化管理工具 - 全局命令

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 查找项目目录
find_project() {
    # 1. 从当前目录向上递归
    local dir="$(pwd)"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/scripts/opencode-linux/opencode.js" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done

    # 2. 检查用户主目录下的可能位置
    local locations=(
        "$HOME/OpenCodeChineseTranslation"
        "$HOME/OpenCodeChineseTranslation"
        "$HOME/opencode"
        "$(dirname "$(pwd)")/OpenCodeChineseTranslation"
    )

    for loc in "${locations[@]}"; do
        if [ -f "$loc/scripts/opencode-linux/opencode.js" ]; then
            echo "$loc"
            return 0
        fi
    done

    return 1
}

PROJECT=$(find_project)

if [ -z "$PROJECT" ]; then
    echo -e "${RED}✗ 未找到 OpenCode 项目${NC}" >&2
    echo -e "${CYAN}安装命令:${NC}" >&2
    echo "  curl -fsSL https://gitee.com/QtCodeCreators/OpenCodeChineseTranslation/raw/main/scripts/install.sh | bash" >&2
    exit 1
fi

# 执行脚本
if [ -f "$PROJECT/scripts/opencode-linux/opencode.js" ]; then
    cd "$PROJECT" && node "$PROJECT/scripts/opencode-linux/opencode.js" "$@"
else
    echo -e "${RED}✗ 找不到汉化脚本: $PROJECT/scripts/opencode-linux/opencode.js${NC}" >&2
    exit 1
fi
OPENCODECMD_EOF

chmod +x "$CMD_DIR/opencodecmd"

# 添加到 PATH（当前会话 + 持久化）
if [[ ":$PATH:" != *":$CMD_DIR:"* ]]; then
    export PATH="$CMD_DIR:$PATH"

    # 添加到 .bashrc（如果还没有）
    if ! grep -q "$CMD_DIR" ~/.bashrc 2>/dev/null; then
        echo '' >> ~/.bashrc
        echo '# OpenCode 汉化工具' >> ~/.bashrc
        echo "export PATH=\"$CMD_DIR:\$PATH\"" >> ~/.bashrc
    fi

    # 添加到 .zshrc（如果存在）
    if [ -f ~/.zshrc ] && ! grep -q "$CMD_DIR" ~/.zshrc 2>/dev/null; then
        echo '' >> ~/.zshrc
        echo '# OpenCode 汉化工具' >> ~/.zshrc
        echo "export PATH=\"$CMD_DIR:\$PATH\"" >> ~/.zshrc
    fi

    print_success "已将 $CMD_DIR 添加到 PATH"
else
    print_success "全局命令已就绪"
fi
echo ""

# ==================== 7. 完成 ====================
print_step "7/7 安装完成！"
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}${WHITE}              安装成功！现在可以开始使用了              ${NC}${GREEN}║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}快速开始:${NC}"
echo -e "  ${WHITE}1. 进入项目目录:${NC}"
echo -e "     ${YELLOW}cd $PROJECT_DIR${NC}"
echo ""
echo -e "  ${WHITE}2. 运行汉化脚本:${NC}"
echo -e "     ${YELLOW}opencodecmd${NC}           # 交互菜单"
echo -e "     ${YELLOW}opencodecmd full${NC}       # 一键全流程"
echo ""
echo -e "  ${WHITE}3. 或直接运行:${NC}"
echo -e "     ${YELLOW}cd scripts/opencode-linux${NC}"
echo -e "     ${YELLOW}./opencode.js${NC}"
echo ""
echo -e "${CYAN}全局命令 (任意位置):${NC}"
echo -e "  ${YELLOW}opencodecmd${NC}              # 启动菜单"
echo -e "  ${YELLOW}opencodecmd update${NC}       # 拉取源码"
echo -e "  ${YELLOW}opencodecmd apply${NC}        # 应用汉化"
echo -e "  ${YELLOW}opencodecmd build${NC}        # 编译构建"
echo -e "  ${YELLOW}opencodecmd full${NC}         # 一键全流程"
echo ""
echo -e "${GREEN}✓ opencode命令已立即可用，无需重启终端${NC}"
echo ""
