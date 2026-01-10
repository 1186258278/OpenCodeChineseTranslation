#!/bin/bash
# ========================================
# 开发环境一键初始化脚本 v1.3
# 全平台支持: Linux / macOS
# 特性: 智能检测 + 多备用方案 + 全自动
# ========================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DARK_GRAY='\033[0;90m'
WHITE='\033[1;37m'
NC='\033[0m'

# 全局变量
QUIET=false
SKIP_AI=false
SKIP_DOCKER=false

# 安装结果跟踪
declare -a INSTALL_SUCCESS=()
declare -a INSTALL_FAILED=()
declare -a INSTALL_SKIPPED=()

# 国内镜像配置
NPM_REGISTRY="https://registry.npmmirror.com"
NODE_MIRROR="https://npmmirror.com/mirrors/node"
GHPROXY_PREFIX="https://mirror.ghproxy.com/https://github.com"

# 参数解析
for arg in "$@"; do
    case $arg in
        --quiet) QUIET=true ;;
        --skip-ai) SKIP_AI=true ;;
        --skip-docker) SKIP_DOCKER=true ;;
    esac
done

# ==================== 工具函数 ====================
print_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     开发环境一键初始化脚本 v1.3                             ║${NC}"
    echo -e "${CYAN}║     智能检测 + 多备用方案 + 全自动                           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_separator() {
    echo -e "${DARK_GRAY}────────────────────────────────────────────────────────${NC}"
}

print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

record_success() { INSTALL_SUCCESS+=("$1"); }
record_failed() { INSTALL_FAILED+=("$1: $2"); }
record_skipped() { INSTALL_SKIPPED+=("$1"); }

# ==================== 智能检测函数 ====================
has_cmd() {
    command -v "$1" &> /dev/null && return 0

    if [ -x "$HOME/.nvm/versions/node/*/bin/$1" ] 2>/dev/null; then
        export PATH="$HOME/.nvm/versions/node/*/bin:$PATH"
        return 0
    fi

    if [ "$1" = "bun" ] && [ -x "$HOME/.bun/bin/bun" ] 2>/dev/null; then
        export PATH="$HOME/.bun/bin:$PATH"
        return 0
    fi

    local common_paths=("/usr/local/bin" "/usr/bin" "$HOME/.local/bin")
    for path in "${common_paths[@]}"; do
        [ -x "$path/$1" ] && return 0
    done

    return 1
}

get_ver() {
    if has_cmd "$1"; then
        "$1" --version 2>&1 | head -n 1 | awk '{print $NF}' || echo "unknown"
    else
        echo "not installed"
    fi
}

load_nvm() {
    if [ -d "$HOME/.nvm" ] && [ -s "$HOME/.nvm/nvm.sh" ]; then
        export NVM_DIR="$HOME/.nvm"
        \. "$NVM_DIR/nvm.sh"

        if [ -d "$NVM_DIR/versions/node" ]; then
            local latest_node=$(ls -1 "$NVM_DIR/versions/node" 2>/dev/null | sort -V | tail -1)
            if [ -n "$latest_node" ] && [ -d "$NVM_DIR/versions/node/$latest_node/bin" ]; then
                export PATH="$NVM_DIR/versions/node/$latest_node/bin:$PATH"
            fi
        fi
        return 0
    fi
    return 1
}

load_bun() {
    if [ -d "$HOME/.bun/bin" ]; then
        export BUN_INSTALL="$HOME/.bun"
        export PATH="$BUN_INSTALL/bin:$PATH"
        return 0
    fi
    return 1
}

get_pm() {
    if has_cmd dnf; then echo "dnf"
    elif has_cmd yum; then echo "yum"
    elif has_cmd apt-get; then echo "apt"
    elif has_cmd brew; then echo "brew"
    elif has_cmd pacman; then echo "pacman"
    else echo ""; fi
}

get_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64) echo "x64" ;;
        aarch64|arm64) echo "arm64" ;;
        *) echo "$arch" ;;
    esac
}

# 智能获取 sudo 命令（Docker 容器中可能不需要）
SUDO_CMD=""
if [ "$(id -u)" = "0" ]; then
    SUDO_CMD=""  # 已是 root，不需要 sudo
elif has_cmd sudo; then
    SUDO_CMD="sudo"
else
    SUDO_CMD=""  # 无 sudo 且非 root，将尝试直接运行
fi

# ==================== 打印汇总报告 ====================
print_summary() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    安装汇总报告                             ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ ${#INSTALL_SUCCESS[@]} -gt 0 ]; then
        print_color "$GREEN" "✓ 安装成功 (${#INSTALL_SUCCESS[@]}):"
        for item in "${INSTALL_SUCCESS[@]}"; do
            echo -e "  ${GREEN}✔${NC} $item"
        done
        echo ""
    fi

    if [ ${#INSTALL_SKIPPED[@]} -gt 0 ]; then
        print_color "$YELLOW" "⊙ 已安装，跳过 (${#INSTALL_SKIPPED[@]}):"
        for item in "${INSTALL_SKIPPED[@]}"; do
            echo -e "  ${YELLOW}⊙${NC} $item"
        done
        echo ""
    fi

    if [ ${#INSTALL_FAILED[@]} -gt 0 ]; then
        print_color "$RED" "✗ 安装失败 (${#INSTALL_FAILED[@]}):"
        for item in "${INSTALL_FAILED[@]}"; do
            echo -e "  ${RED}✗${NC} $item"
        done
        echo ""
    fi

    local total=$((${#INSTALL_SUCCESS[@]} + ${#INSTALL_FAILED[@]} + ${#INSTALL_SKIPPED[@]}))
    local rate=0
    [ $total -gt 0 ] && rate=$((100 * ${#INSTALL_SUCCESS[@]} / total))

    print_separator
    echo -e "  总计: ${WHITE}$total${NC} | ${GREEN}成功: ${#INSTALL_SUCCESS[@]}${NC} | ${YELLOW}跳过: ${#INSTALL_SKIPPED[@]}${NC} | ${RED}失败: ${#INSTALL_FAILED[@]}${NC} | 成功率: ${rate}%"
    print_separator
    echo ""

    if [ ${#INSTALL_SUCCESS[@]} -gt 0 ]; then
        print_color "$CYAN" "已安装命令验证:"
        has_cmd node && echo -e "  ${GREEN}✔${NC} node $(get_ver node)"
        has_cmd npm && echo -e "  ${GREEN}✔${NC} npm $(get_ver npm)"
        has_cmd bun && echo -e "  ${GREEN}✔${NC} bun $(get_ver bun)"
        has_cmd git && echo -e "  ${GREEN}✔${NC} git $(get_ver git)"
        has_cmd python3 && echo -e "  ${GREEN}✔${NC} python3 $(get_ver python3)"
        has_cmd chelper && echo -e "  ${GREEN}✔${NC} coding-helper"
        echo ""
    fi
}

# ==================== 组件安装 ====================
install_nodejs() {
    print_color "$CYAN" "[1/4] 安装 Node.js..."

    load_nvm

    if has_cmd node; then
        local version=$(get_ver node)
        print_color "$YELLOW" "  ⊙ Node.js 已安装: $version"
        record_skipped "Node.js ($version)"
        has_cmd npm && npm config set registry "$NPM_REGISTRY" 2>/dev/null
        return 0
    fi

    local pm=$(get_pm)
    local arch=$(get_arch)
    local installed=false

    # 方法1: 使用 nvm（Gitee 镜像）
    if [ ! -d "$HOME/.nvm" ]; then
        print_color "$DARK_GRAY" "  方法1: 使用 nvm 安装..."
        if curl -o- https://gitee.com/mirrors/nvm/raw/master/install.sh 2>/dev/null | bash 2>/dev/null; then
            load_nvm
            if has_cmd nvm; then
                nvm install --lts 2>/dev/null && nvm alias default lts/* 2>/dev/null
                load_nvm
                has_cmd node && installed=true
            fi
        fi
    else
        print_color "$YELLOW" "  nvm 目录已存在，尝试使用..."
        load_nvm
        if has_cmd nvm; then
            nvm install --lts 2>/dev/null && nvm alias default lts/* 2>/dev/null
            load_nvm
            has_cmd node && installed=true
        fi
    fi

    # 方法2: 直接下载 Node.js 二进制
    if ! $installed; then
        print_color "$YELLOW" "  方法2: 直接下载 Node.js 二进制..."
        local node_version="v22.12.0"
        local node_url="https://npmmirror.com/mirrors/node/${node_version}/node-${node_version}-linux-${arch}.tar.xz"

        cd /tmp
        if curl -L "$node_url" -o node.tar.xz 2>/dev/null; then
            tar -xf node.tar.xz 2>/dev/null
            if [ -d "node-${node_version}-linux-${arch}" ]; then
                $SUDO_CMD rm -rf /usr/local/node 2>/dev/null
                $SUDO_CMD mv "node-${node_version}-linux-${arch}" /usr/local/node
                $SUDO_CMD ln -sf /usr/local/node/bin/* /usr/local/bin/ 2>/dev/null
                export PATH="/usr/local/node/bin:$PATH"
                has_cmd node && installed=true
            fi
            rm -rf node.tar.xz "node-${node_version}-linux-${arch}" 2>/dev/null
        fi
        cd - > /dev/null
    fi

    # 方法3: 系统包管理器
    if ! $installed; then
        print_color "$YELLOW" "  方法3: 使用系统包管理器..."
        case $pm in
            dnf|yum)
                curl -fsSL https://rpm.nodesource.com/setup_lts.x | $SUDO_CMD bash - 2>/dev/null
                $SUDO_CMD $pm install -y nodejs npm 2>/dev/null && installed=true
                ;;
            apt)
                curl -fsSL https://deb.nodesource.com/setup_lts.x | $SUDO_CMD -E bash - 2>/dev/null
                $SUDO_CMD apt-get install -y nodejs 2>/dev/null && installed=true
                ;;
        esac
    fi

    load_nvm
    if has_cmd node; then
        local version=$(get_ver node)
        print_color "$GREEN" "  ✓ Node.js 安装成功: $version"
        record_success "Node.js ($version)"

        if has_cmd npm; then
            npm config set registry "$NPM_REGISTRY" 2>/dev/null
            print_color "$DARK_GRAY" "  ✓ npm 已配置国内镜像"
        fi

        if ! grep -q 'NVM_DIR' ~/.bashrc 2>/dev/null; then
            echo "" >> ~/.bashrc
            echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
        fi
        return 0
    fi

    print_color "$RED" "  ✗ Node.js 安装失败"
    record_failed "Node.js" "所有安装方法均失败"
    return 1
}

install_bun() {
    print_color "$CYAN" "[2/4] 安装 Bun..."

    load_bun
    if has_cmd bun; then
        local version=$(get_ver bun)
        print_color "$YELLOW" "  ⊙ Bun 已安装: $version"
        record_skipped "Bun ($version)"
        return 0
    fi

    local installed=false

    print_color "$DARK_GRAY" "  方法1: 官方安装脚本..."
    if curl -fsSL "${GHPROXY_PREFIX}/oven-sh/bun/raw/main/install.sh" 2>/dev/null | bash 2>/dev/null; then
        load_bun
        has_cmd bun && installed=true
    fi

    if ! $installed && has_cmd npm; then
        print_color "$YELLOW" "  方法2: 使用 npm 安装..."
        if npm install -g bun 2>/dev/null; then
            load_bun
            has_cmd bun && installed=true
        fi
    fi

    if ! $installed; then
        print_color "$YELLOW" "  方法3: 直接下载二进制..."
        local arch=$(get_arch)
        cd /tmp
        if curl -L "${GHPROXY_PREFIX}/oven-sh/bun/releases/latest/download/bun-${arch}.zip" -o bun.zip 2>/dev/null; then
            unzip -o bun.zip 2>/dev/null
            chmod +x bun 2>/dev/null
            mkdir -p ~/.bun/bin 2>/dev/null
            mv bun ~/.bun/bin/
            load_bun
            has_cmd bun && installed=true
        fi
        rm -rf bun.zip 2>/dev/null
        cd - > /dev/null
    fi

    if has_cmd bun; then
        local version=$(get_ver bun)
        print_color "$GREEN" "  ✓ Bun 安装成功: $version"
        record_success "Bun ($version)"
        return 0
    fi

    print_color "$YELLOW" "  ⊙ Bun 安装跳过（网络问题）"
    record_failed "Bun" "网络连接失败"
    return 1
}

install_git() {
    print_color "$CYAN" "[3/4] 安装 Git..."

    if has_cmd git; then
        local version=$(get_ver git)
        print_color "$YELLOW" "  ⊙ Git 已安装: $version"
        record_skipped "Git ($version)"
        return 0
    fi

    local pm=$(get_pm)
    case $pm in
        dnf|yum) $SUDO_CMD $pm install -y git 2>/dev/null ;;
        apt) $SUDO_CMD apt-get update -qq && $SUDO_CMD apt-get install -y git 2>/dev/null ;;
        pacman) $SUDO_CMD pacman -S --noconfirm git 2>/dev/null ;;
    esac

    if has_cmd git; then
        print_color "$GREEN" "  ✓ Git 安装成功"
        record_success "Git"
        return 0
    fi

    print_color "$RED" "  ✗ Git 安装失败"
    record_failed "Git" "请手动安装"
    return 1
}

install_python() {
    print_color "$CYAN" "[4/4] 安装 Python..."

    if has_cmd python3; then
        local version=$(get_ver python3)
        print_color "$YELLOW" "  ⊙ Python 已安装: $version"
        record_skipped "Python ($version)"
        return 0
    fi

    local pm=$(get_pm)
    case $pm in
        dnf|yum) $SUDO_CMD $pm install -y python3 python3-pip 2>/dev/null ;;
        apt) $SUDO_CMD apt-get update -qq && $SUDO_CMD apt-get install -y python3 python3-pip 2>/dev/null ;;
    esac

    if has_cmd python3; then
        print_color "$GREEN" "  ✓ Python 安装成功"
        record_success "Python"
        return 0
    fi

    print_color "$RED" "  ✗ Python 安装失败"
    record_failed "Python" "请手动安装"
    return 1
}

install_coding_helper() {
    print_color "$CYAN" "安装 @z_ai/coding-helper..."

    load_nvm
    load_bun

    if ! has_cmd npm; then
        print_color "$YELLOW" "  npm 未找到，尝试先安装 Node.js..."
        install_nodejs
        load_nvm
    fi

    if ! has_cmd npm; then
        print_color "$RED" "  ✗ 需要先安装 npm"
        record_failed "coding-helper" "npm 未安装"
        return 1
    fi

    # 将 npm bin 目录加到 PATH
    local npm_bin="$(npm bin -g 2>/dev/null)"
    if [ -n "$npm_bin" ]; then
        export PATH="$npm_bin:$PATH"
    fi

    if has_cmd chelper || has_cmd coding-helper; then
        print_color "$YELLOW" "  ⊙ coding-helper 已安装"
        record_skipped "coding-helper"
        return 0
    fi

    print_color "$DARK_GRAY" "  使用国内镜像安装..."
    local installed=false

    if npm install -g @z_ai/coding-helper --registry="$NPM_REGISTRY" 2>/dev/null; then
        installed=true
    fi

    if ! $installed; then
        print_color "$YELLOW" "  尝试官方源..."
        if npm install -g @z_ai/coding-helper 2>/dev/null; then
            installed=true
        fi
    fi

    if $installed; then
        # 重新加载 npm bin 目录
        npm_bin="$(npm bin -g 2>/dev/null)"
        if [ -n "$npm_bin" ]; then
            export PATH="$npm_bin:$PATH"
        fi

        # 验证命令是否可用
        if has_cmd chelper || has_cmd coding-helper; then
            print_color "$GREEN" "  ✓ coding-helper 安装成功"
            record_success "coding-helper"

            # 创建软链接到 /usr/local/bin (如果需要)
            if [ -n "$npm_bin" ] && [ -f "$npm_bin/chelper" ]; then
                $SUDO_CMD ln -sf "$npm_bin/chelper" /usr/local/bin/chelper 2>/dev/null
                $SUDO_CMD ln -sf "$npm_bin/coding-helper" /usr/local/bin/coding-helper 2>/dev/null
            fi
            return 0
        fi
    fi

    print_color "$RED" "  ✗ coding-helper 安装失败"
    record_failed "coding-helper" "网络问题"
    return 1
}

# ==================== 主安装流程 ====================
install_all() {
    print_header
    print_color "$YELLOW" "       一键安装全部组件"
    print_separator
    echo ""

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${CYAN}  第一阶段: 基础工具"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    install_nodejs
    echo ""
    install_bun
    echo ""
    install_git
    echo ""
    install_python
    echo ""

    if [ "$SKIP_AI" = false ]; then
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${CYAN}  第二阶段: AI 工具"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        install_coding_helper
        echo ""
    fi

    print_summary

    # 自动安装 codes 命令
    install_codes
}

# ==================== 安装 codes ====================
install_codes() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${CYAN}  安装 Codes 管理工具"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local install_dir="$HOME/.codes"
    local bin_dir="$install_dir/bin"

    mkdir -p "$bin_dir" 2>/dev/null

    # 复制脚本
    if [ -f "$script_dir/codes.sh" ]; then
        cp "$script_dir/codes.sh" "$bin_dir/codes" 2>/dev/null
        chmod +x "$bin_dir/codes" 2>/dev/null

        # 创建 wrapper
        cat > "$bin_dir/codes-wrapper" 2>/dev/null << 'WRAPPER'
#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
if command -v npm &> /dev/null; then
    NPM_BIN="$(npm bin -g 2>/dev/null)"
    [ -n "$NPM_BIN" ] && export PATH="$NPM_BIN:$PATH"
fi
exec ~/.codes/bin/codes "$@"
WRAPPER
        chmod +x "$bin_dir/codes-wrapper" 2>/dev/null

        # 创建软链接
        $SUDO_CMD ln -sf "$bin_dir/codes-wrapper" /usr/local/bin/codes 2>/dev/null

        # 添加到 .bashrc
        local shell_config="$HOME/.bashrc"
        [ -n "$ZSH_VERSION" ] && shell_config="$HOME/.zshrc"

        if ! grep -q 'codes/bin' "$shell_config" 2>/dev/null; then
            echo "" >> "$shell_config"
            echo "# Codes - 开发环境管理工具" >> "$shell_config"
            echo "export PATH=\"\$HOME/.codes/bin:\$PATH\"" >> "$shell_config"
        fi

        print_color "$GREEN" "  ✓ codes 已安装到 $install_dir"
        print_color "$YELLOW" "  ! 运行 'source ~/.bashrc' 使更改生效"
        print_color "$DARK_GRAY" "  ! 或直接使用: ~/.codes/bin/codes doctor"
    else
        print_color "$YELLOW" "  ⊙ codes.sh 不存在，跳过安装"
    fi
    echo ""
}

install_basic_tools() {
    print_header
    print_color "$YELLOW" "       安装基础工具"
    print_separator
    echo ""

    install_nodejs
    echo ""
    install_bun
    echo ""
    install_git
    echo ""
    install_python
    echo ""

    print_summary
}

install_ai_tools() {
    print_header
    print_color "$YELLOW" "       安装 AI 工具"
    print_separator
    echo ""

    install_coding_helper
    echo ""

    print_summary
}

show_menu() {
    print_header

    echo -e "${CYAN}   ┌─── 安装模式 ─────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}   │${NC}"
    echo -e "${GREEN}   │  [1]  一键安装全部 (推荐)${NC}"
    echo -e "${YELLOW}   │  [2]  仅安装基础工具${NC}"
    echo -e "${MAGENTA}   │  [3]  仅安装 AI 工具${NC}"
    echo -e "${CYAN}   │  [4]  检查更新${NC}"
    echo -e "${CYAN}   │${NC}"
    echo -e "${RED}   │  [0]  退出${NC}"
    echo -e "${CYAN}   │${NC}"
    echo -e "${CYAN}   └───────────────────────────────────────────────────────┘${NC}"
    echo ""
}

check_updates() {
    print_header
    print_color "$YELLOW" "       检查更新"
    print_separator
    echo ""

    print_color "$CYAN" "已安装组件:"
    echo ""
    has_cmd node && echo "  Node.js: $(get_ver node)"
    has_cmd npm && echo "  npm: $(get_ver npm)"
    has_cmd bun && echo "  Bun: $(get_ver bun)"
    has_cmd git && echo "  Git: $(get_ver git)"
    has_cmd python3 && echo "  Python: $(get_ver python3)"
    echo ""

    print_color "$YELLOW" "更新命令:"
    echo -e "  ${DARK_GRAY}nvm install --lts${NC}"
    echo -e "  ${DARK_GRAY}npm update -g @z_ai/coding-helper${NC}"
    echo ""
}

# ==================== 主循环 ====================
if [ ! -t 0 ]; then
    print_color "$YELLOW" "检测到管道模式（非交互），自动执行一键安装..."
    install_all
    exit 0
fi

if [ "$QUIET" = true ]; then
    install_all
    exit 0
fi

while true; do
    show_menu
    read -p "请选择: " choice

    case $choice in
        1) install_all ;;
        2) install_basic_tools ;;
        3) install_ai_tools ;;
        4) check_updates ;;
        0)
            print_color "$DARK_GRAY" "再见！"
            exit 0
            ;;
        *)
            print_color "$RED" "无效选择"
            sleep 0.5
            ;;
    esac

    if [ "$choice" != "0" ]; then
        echo ""
        read -p "按回车键继续..."
    fi
done
