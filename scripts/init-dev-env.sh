#!/bin/bash
# ========================================
# 开发环境一键初始化脚本 v1.1
# 全平台支持: Linux / macOS
# ========================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
DARK_GRAY='\033[0;90m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 全局变量
QUIET=false
SKIP_AI=false
SKIP_DOCKER=false

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
    echo -e "${CYAN}║     开发环境一键初始化脚本 v1.1                             ║${NC}"
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

command_exists() {
    command -v "$1" &> /dev/null
}

get_version() {
    if command_exists "$1"; then
        "$1" --version 2>&1 | head -n 1 || echo "unknown"
    fi
}

# ==================== 系统检测 ====================
show_system_status() {
    print_color "$CYAN" "  系统环境检测"
    print_separator

    declare -A tools=(
        ["Node.js"]="node"
        ["npm"]="npm"
        ["Bun"]="bun"
        ["Git"]="git"
        ["Docker"]="docker"
        ["Python"]="python3"
        ["coding-helper"]="chelper"
    )

    for name in "${!tools[@]}"; do
        cmd="${tools[$name]}"
        if command_exists "$cmd"; then
            version=$(get_version "$cmd")
            echo -e "  [$name] ${GREEN}✓${NC} $version"
        else
            echo -e "  [$name] ${RED}✗${NC} 未安装"
        fi
    done
    print_separator
    echo ""
}

# ==================== 包管理器检测 ====================
detect_package_manager() {
    if command_exists dnf; then
        echo "dnf"
    elif command_exists yum; then
        echo "yum"
    elif command_exists apt-get; then
        echo "apt"
    elif command_exists brew; then
        echo "brew"
    elif command_exists pacman; then
        echo "pacman"
    else
        echo ""
    fi
}

install_package_manager_if_needed() {
    print_color "$CYAN" "检查包管理器..."

    local pm=$(detect_package_manager)
    if [ -n "$pm" ]; then
        print_color "$GREEN" "  ✓ 检测到包管理器: $pm"
        echo "$pm"
        return
    fi

    print_color "$YELLOW" "  ! 未检测到常用包管理器"

    # 检测系统类型
    if [ -f /etc/tencentos-release ]; then
        print_color "$CYAN" "  检测到 TencentOS 系统"
    elif [ -f /etc/redhat-release ]; then
        print_color "$CYAN" "  检测到 RedHat/CentOS 系统"
    elif [ -f /etc/debian_version ]; then
        print_color "$CYAN" "  检测到 Debian/Ubuntu 系统"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        print_color "$CYAN" "  检测到 macOS 系统"
        print_color "$YELLOW" "  建议安装 Homebrew:"
        echo ""
        echo "    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    fi

    echo ""
}

# ==================== 组件安装 ====================
install_nodejs() {
    print_color "$CYAN" "安装 Node.js..."

    if command_exists node; then
        local version=$(get_version node)
        print_color "$GREEN" "  ✓ Node.js 已安装: $version"
        return
    fi

    # 检测系统类型
    local os_type=""
    if [ -f /etc/tencentos-release ]; then
        os_type="tencentos"
    elif [ -f /etc/redhat-release ]; then
        os_type="redhat"
    elif [ -f /etc/debian_version ]; then
        os_type="debian"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="macos"
    fi

    # 使用 nvm 安装（通用方案）
    print_color "$YELLOW" "  使用 nvm 安装 Node.js..."

    if ! command_exists nvm; then
        print_color "$DARK_GRAY" "  正在安装 nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    fi

    # 加载 nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if command_exists nvm; then
        nvm install --lts
        nvm alias default lts/*

        # 重新加载环境
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        if command_exists node; then
            local version=$(get_version node)
            print_color "$GREEN" "  ✓ Node.js 安装成功: $version"

            # 添加到 bashrc
            if ! grep -q 'NVM_DIR' ~/.bashrc 2>/dev/null; then
                echo "" >> ~/.bashrc
                echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
                echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
                print_color "$YELLOW" "  ! 已添加 nvm 配置到 ~/.bashrc"
            fi
        fi
    else
        print_color "$RED" "  ✗ nvm 安装失败"
        return 1
    fi
}

# 添加 Bun 到 bashrc 的辅助函数
_add_bun_to_bashrc() {
    if ! grep -q 'BUN_INSTALL' ~/.bashrc 2>/dev/null; then
        echo "" >> ~/.bashrc
        echo 'export BUN_INSTALL="$HOME/.bun"' >> ~/.bashrc
        echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> ~/.bashrc
        print_color "$YELLOW" "  ! 已添加 bun 配置到 ~/.bashrc"
    fi
}

install_bun() {
    print_color "$CYAN" "安装 Bun..."

    if command_exists bun; then
        local version=$(get_version bun)
        print_color "$GREEN" "  ✓ Bun 已安装: $version"
        return
    fi

    # 方法1: 官方安装脚本
    print_color "$DARK_GRAY" "  方法1: 官方安装脚本..."
    if curl -fsSL https://bun.sh/install | bash 2>/dev/null; then
        if [ -f "$HOME/.bun/bin/bun" ]; then
            export BUN_INSTALL="$HOME/.bun"
            export PATH="$BUN_INSTALL/bin:$PATH"
            print_color "$GREEN" "  ✓ Bun 安装成功"
            _add_bun_to_bashrc
            return
        fi
    fi

    # 方法2: 使用 npm 安装（备用方案）
    print_color "$YELLOW" "  官方脚本失败，尝试使用 npm 安装..."
    if command_exists npm; then
        npm install -g bun 2>/dev/null
        if command_exists bun; then
            print_color "$GREEN" "  ✓ Bun 安装成功 (通过 npm)"
            return
        fi
    fi

    # 方法3: 手动下载二进制（备用方案）
    print_color "$YELLOW" "  npm 安装失败，请手动安装 Bun:"
    echo ""
    echo "    # 方式1: 使用代理访问 GitHub"
    echo "    curl -fsSL https://bun.sh/install | bash"
    echo ""
    echo "    # 方式2: 下载二进制到 /tmp 后解压"
    echo "    # 访问 https://github.com/oven-sh/bun/releases"
    echo ""
}

install_git() {
    print_color "$CYAN" "安装 Git..."

    if command_exists git; then
        local version=$(get_version git)
        print_color "$GREEN" "  ✓ Git 已安装: $version"
        return
    fi

    local pm=$(detect_package_manager)
    case $pm in
        dnf|yum)
            sudo $pm install -y git
            ;;
        apt)
            sudo apt-get install -y git
            ;;
        brew)
            brew install git
            ;;
        pacman)
            sudo pacman -S --noconfirm git
            ;;
    esac

    if command_exists git; then
        print_color "$GREEN" "  ✓ Git 安装成功"
    fi
}

install_docker() {
    print_color "$CYAN" "安装 Docker..."

    if command_exists docker; then
        local version=$(get_version docker)
        print_color "$GREEN" "  ✓ Docker 已安装: $version"
        return
    fi

    print_color "$YELLOW" "  ! Docker 需要手动安装"
    print_color "$DARK_GRAY" ""
    print_color "$DARK_GRAY" "  CentOS/RHEL/TencentOS:"
    echo "    sudo yum install -y yum-utils"
    echo "    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo"
    echo "    sudo yum install -y docker-ce docker-ce-cli containerd.io"
    echo ""
    print_color "$DARK_GRAY" "  Ubuntu/Debian:"
    echo "    curl -fsSL https://get.docker.com | sh"
    echo ""
}

install_python() {
    print_color "$CYAN" "安装 Python..."

    if command_exists python3; then
        local version=$(get_version python3)
        print_color "$GREEN" "  ✓ Python 已安装: $version"
        return
    fi

    local pm=$(detect_package_manager)
    case $pm in
        dnf|yum)
            sudo $pm install -y python3 python3-pip
            ;;
        apt)
            sudo apt-get install -y python3 python3-pip
            ;;
        brew)
            brew install python3
            ;;
    esac

    if command_exists python3; then
        print_color "$GREEN" "  ✓ Python 安装成功"
    fi
}

# ==================== GitHub CLI 安装 ====================
install_gh_cli() {
    print_color "$CYAN" "安装 GitHub CLI (gh)..."

    if command_exists gh; then
        local version=$(gh --version 2>&1)
        print_color "$GREEN" "  ✓ gh CLI 已安装: $version"
        return
    fi

    local pm=$(detect_package_manager)
    case $pm in
        dnf|yum)
            # 添加 GitHub CLI 仓库
            sudo dnf install -y dnf-plugins-core
            sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
            sudo $pm install -y gh
            ;;
        apt)
            sudo apt-get install -y gh
            ;;
        *)
            # 直接下载二进制
            local gh_version="v2.48.0"
            local arch=$(uname -m)
            case $arch in
                x86_64) local gh_arch="amd64" ;;
                aarch64) local gh_arch="arm64" ;;
                *) local gh_arch="$arch" ;;
            esac

            curl -L "https://github.com/cli/cli/releases/download/${gh_version}/gh-${gh_version}-linux-${gh_arch}.tar.gz" -o /tmp/gh.tar.gz
            tar -xzf /tmp/gh.tar.gz -C /tmp
            sudo mv /tmp/gh_${gh_version}_linux_${gh_arch}/gh /usr/local/bin/
            rm -rf /tmp/gh_${gh_version}_linux_${gh_arch} /tmp/gh.tar.gz
            ;;
    esac

    if command_exists gh; then
        print_color "$GREEN" "  ✓ gh CLI 安装成功"
        print_color "$YELLOW" "  ! 首次使用需要运行: gh auth login"
    fi
}

# ==================== AI 工具安装 ====================
install_coding_helper() {
    print_color "$CYAN" "安装 @z_ai/coding-helper..."

    if ! command_exists npm; then
        print_color "$RED" "  ✗ 需要先安装 npm"
        return
    fi

    if command_exists chelper; then
        print_color "$GREEN" "  ✓ coding-helper 已安装"
        return
    fi

    print_color "$DARK_GRAY" "  正在安装..."
    npm install -g @z_ai/coding-helper

    if command_exists chelper; then
        print_color "$GREEN" "  ✓ coding-helper 安装成功"
        print_color "$DARK_GRAY" "  运行命令: chelper 或 coding-helper"
    fi
}

install_opencode_chinese() {
    print_color "$CYAN" "安装 OpenCode 中文汉化版..."

    if ! command_exists git; then
        print_color "$RED" "  ✗ 需要先安装 Git"
        return
    fi

    local clone_dir="$HOME/OpenCodeChineseTranslation"

    if [ -d "$clone_dir" ]; then
        print_color "$YELLOW" "  ! 目录已存在: $clone_dir"
        cd "$clone_dir" && git pull || true
    else
        git clone https://github.com/1186258278/OpenCodeChineseTranslation.git "$clone_dir"
        cd "$clone_dir"
    fi

    echo ""
    print_color "$DARK_GRAY" "  已克隆到: $clone_dir"
    print_color "$YELLOW" "  下一步: cd $clone_dir && ./scripts/init.ps1 (需要 PowerShell)"
    print_color "$YELLOW" "           或: cd $clone_dir && ./scripts/opencode.ps1"

    cd - > /dev/null
}

install_claude_code() {
    print_color "$CYAN" "安装 Claude Code..."

    if ! command_exists npm; then
        print_color "$RED" "  ✗ 需要先安装 npm"
        return
    fi

    if command_exists claude; then
        print_color "$GREEN" "  ✓ Claude Code 已安装"
        return
    fi

    npm install -g @anthropic-ai/claude-code

    if command_exists claude; then
        print_color "$GREEN" "  ✓ Claude Code 安装成功"
    fi
}

# ==================== 主菜单 ====================
show_menu() {
    print_header
    show_system_status

    echo -e "${CYAN}   ┌─── 安装模式 ─────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}   │${NC}"
    echo -e "${GREEN}   │  [1]  一键安装全部 (推荐)${NC}"
    echo -e "${YELLOW}   │  [2]  仅安装基础工具 (Node.js, Bun, Git, Python)${NC}"
    echo -e "${MAGENTA}   │  [3]  仅安装 AI 工具${NC}"
    echo -e "${WHITE}   │  [4]  自定义选择${NC}"
    echo -e "${CYAN}   │  [5]  安装 GitHub CLI (gh)${NC}"
    echo -e "${CYAN}   │  [6]  检查更新${NC}"
    echo -e "${CYAN}   │${NC}"
    echo -e "${RED}   │  [0]  退出${NC}"
    echo -e "${CYAN}   │${NC}"
    echo -e "${CYAN}   └───────────────────────────────────────────────────────┘${NC}"
    echo ""
}

install_all() {
    print_header
    print_color "$YELLOW" "       一键安装全部组件"
    print_separator
    echo ""

    # 1. 安装基础工具
    print_color "$CYAN" "[1/2] 安装基础工具..."
    echo ""
    install_nodejs
    echo ""
    install_bun
    echo ""
    install_git
    echo ""
    install_python
    echo ""

    # 2. 安装 AI 工具
    if [ "$SKIP_AI" = false ]; then
        print_color "$CYAN" "[2/2] 安装 AI 工具..."
        echo ""
        install_coding_helper
        echo ""
    fi

    # 完成
    print_color "$CYAN" "安装完成"
    print_separator
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          开发环境初始化完成！                               ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    print_color "$CYAN" "下一步:"
    echo -e "  ${WHITE}- coding-helper 或 chelper 启动智谱助手${NC}"
    echo -e "  ${WHITE}- 运行 'source ~/.bashrc' 使环境变量生效${NC}"
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

    print_color "$GREEN" "基础工具安装完成！"
    print_color "$YELLOW" "请运行 'source ~/.bashrc' 使环境变量生效"
    echo ""
}

install_ai_tools() {
    print_header
    print_color "$YELLOW" "       安装 AI 工具"
    print_separator
    echo ""

    install_coding_helper
    echo ""

    print_color "$GREEN" "AI 工具安装完成！"
    echo ""
}

custom_install() {
    print_header
    print_color "$YELLOW" "       自定义安装"
    print_separator
    echo ""

    echo "选择要安装的组件 (输入编号，用空格分隔):"
    echo ""

    local choices=(
        "Node.js + npm"
        "Bun"
        "Git"
        "Python"
        "GitHub CLI (gh)"
        "@z_ai/coding-helper"
        "OpenCode 汉化版"
        "Claude Code"
    )

    for i in "${!choices[@]}"; do
        echo "  [$(($i+1))] ${choices[$i]}"
    done
    echo ""
    read -p "输入编号 (如: 1 3 5): " selection

    echo ""
    for num in $selection; do
        idx=$((num-1))
        if [ $idx -ge 0 ] && [ $idx -lt ${#choices[@]} ]; then
            case $idx in
                0) install_nodejs ;;
                1) install_bun ;;
                2) install_git ;;
                3) install_python ;;
                4) install_gh_cli ;;
                5) install_coding_helper ;;
                6) install_opencode_chinese ;;
                7) install_claude_code ;;
            esac
            echo ""
        fi
    done

    print_color "$GREEN" "自定义安装完成！"
    print_color "$YELLOW" "请运行 'source ~/.bashrc' 使环境变量生效"
    echo ""
}

check_updates() {
    print_header
    print_color "$YELLOW" "       检查更新"
    print_separator
    echo ""

    print_color "$CYAN" "已安装组件版本:"
    echo ""

    declare -A tools=(
        ["Node.js"]="node"
        ["Bun"]="bun"
        ["npm"]="npm"
        ["Git"]="git"
        ["Python"]="python3"
    )

    for name in "${!tools[@]}"; do
        cmd="${tools[$name]}"
        if command_exists "$cmd"; then
            version=$(get_version "$cmd")
            echo -e "  [$name] $version" "${DARK_GRAY}"
        fi
    done

    echo ""
    print_color "$YELLOW" "更新命令:"
    echo -e "  ${DARK_GRAY}nvm install --lts --reinstall-packages-from=default${NC}"
    echo -e "  ${DARK_GRAY}bun upgrade${NC}"
    echo ""
}

# ==================== 主循环 ====================
# 检测是否在管道模式（非交互）
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
        4) custom_install ;;
        5) install_gh_cli ;;
        6) check_updates ;;
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
