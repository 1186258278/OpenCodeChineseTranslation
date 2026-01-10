#!/bin/bash
# ========================================
# 开发环境一键初始化脚本 v1.0
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
    echo -e "${CYAN}║     开发环境一键初始化脚本 v1.0                             ║${NC}"
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
    if command_exists apt-get; then
        echo "apt"
    elif command_exists yum; then
        echo "yum"
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

    # 检测系统类型并尝试安装
    if [ -f /etc/debian_version ]; then
        print_color "$CYAN" "  检测到 Debian/Ubuntu 系统"
        print_color "$DARK_GRAY" "  apt-get 是系统默认包管理器"
    elif [ -f /etc/redhat-release ]; then
        print_color "$CYAN" "  检测到 RedHat/CentOS 系统"
        print_color "$DARK_GRAY" "  yum 是系统默认包管理器"
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

        if [ "$QUIET" = false ]; then
            read -p "  ? 是否升级到最新版本？(y/N): " answer
            if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                local pm=$(detect_package_manager)
                case $pm in
                    apt)
                        sudo apt-get update && sudo apt-get install -y nodejs npm
                        ;;
                    yum)
                        sudo yum install -y nodejs npm || sudo yum update -y nodejs npm
                        ;;
                    brew)
                        brew upgrade node
                        ;;
                esac
            fi
        fi
        return
    fi

    local pm=$(detect_package_manager)
    case $pm in
        apt)
            # 使用 NodeSource 仓库
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        yum)
            # 先启用 EPEL 仓库
            if ! rpm -q epel-release &>/dev/null; then
                print_color "$DARK_GRAY" "  安装 EPEL 仓库..."
                sudo yum install -y epel-release || sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E '%{rhel}').noarch.rpm
            fi

            # 尝试从 EPEL 安装
            if sudo yum install -y nodejs npm 2>/dev/null; then
                print_color "$GREEN" "  ✓ Node.js 从 EPEL 安装成功"
            else
                # EPEL 安装失败，尝试使用 nvm
                print_color "$YELLOW" "  ! EPEL 安装失败，尝试使用 nvm 安装..."

                if ! command_exists nvm; then
                    # 安装 nvm
                    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
                    export NVM_DIR="$HOME/.nvm"
                    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
                fi

                if command_exists nvm; then
                    nvm install --lts
                    nvm use --lts
                    print_color "$GREEN" "  ✓ Node.js 通过 nvm 安装成功"
                else
                    print_color "$RED" "  ✗ Node.js 安装失败"
                    print_color "$YELLOW" "  请手动安装: yum install nodejs npm"
                fi
            fi
            ;;
        brew)
            brew install node
            ;;
    esac

    if command_exists node; then
        local version=$(get_version node)
        print_color "$GREEN" "  ✓ Node.js 安装成功: $version"
    fi
}

install_bun() {
    print_color "$CYAN" "安装 Bun..."

    if command_exists bun; then
        local version=$(get_version bun)
        print_color "$GREEN" "  ✓ Bun 已安装: $version"
        return
    fi

    # Bun 官方安装脚本
    print_color "$DARK_GRAY" "  使用官方安装脚本..."
    curl -fsSL https://bun.sh/install | bash

    # 添加到 PATH
    if [ -f "$HOME/.bun/bin/bun" ]; then
        export BUN_INSTALL="$HOME/.bun"
        export PATH="$BUN_INSTALL/bin:$PATH"
        print_color "$GREEN" "  ✓ Bun 安装成功"
        print_color "$YELLOW" "  ! 请将以下添加到 ~/.bashrc 或 ~/.zshrc:"
        echo ""
        echo "    export BUN_INSTALL=\"\$HOME/.bun\""
        echo "    export PATH=\"\$BUN_INSTALL/bin:\$PATH\""
    fi
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
        apt)
            sudo apt-get install -y git
            ;;
        yum)
            sudo yum install -y git
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

    local pm=$(detect_package_manager)
    case $pm in
        apt)
            curl -fsSL https://get.docker.com | sh
            sudo usermod -aG docker $USER
            print_color "$YELLOW" "  ! 请注销后重新登录以使用 Docker"
            ;;
        yum)
            curl -fsSL https://get.docker.com | sh
            sudo usermod -aG docker $USER
            ;;
        brew)
            brew install --cask docker
            print_color "$YELLOW" "  ! 请启动 Docker Desktop 应用"
            ;;
    esac
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
        apt)
            sudo apt-get install -y python3 python3-pip
            ;;
        yum)
            sudo yum install -y python3 python3-pip
            ;;
        brew)
            brew install python3
            ;;
    esac

    if command_exists python3; then
        print_color "$GREEN" "  ✓ Python 安装成功"
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

        if [ "$QUIET" = false ]; then
            read -p "  ? 是否升级？(y/N): " answer
            if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                npm install -g @z_ai/coding-helper
                print_color "$GREEN" "  ✓ 升级完成"
            fi
        fi
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
        if [ "$QUIET" = false ]; then
            read -p "  ? 是否重新克隆？(y/N): " answer
            if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                rm -rf "$clone_dir"
                git clone https://github.com/1186258278/OpenCodeChineseTranslation.git "$clone_dir"
                cd "$clone_dir"
            else
                print_color "$DARK_GRAY" "  跳过，使用现有目录"
                cd "$clone_dir"
            fi
        else
            cd "$clone_dir"
        fi
    else
        git clone https://github.com/1186258278/OpenCodeChineseTranslation.git "$clone_dir"
        cd "$clone_dir"
    fi

    echo ""
    print_color "$DARK_GRAY" "  正在初始化汉化版..."

    if [ -f "scripts/init.ps1" ]; then
        if command_exists pwsh; then
            pwsh scripts/init.ps1
        elif command_exists powershell; then
            powershell -File scripts/init.ps1
        else
            print_color "$YELLOW" "  ! 需要安装 PowerShell 来运行初始化"
            print_color "$DARK_GRAY" "  或手动克隆源码到 opencode-zh-CN 目录"
        fi
        echo ""
        print_color "$GREEN" "  ✓ OpenCode 汉化版初始化完成"
    else
        print_color "$YELLOW" "  ! 脚本未找到，请手动初始化"
    fi

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
    echo -e "${YELLOW}   │  [2]  仅安装基础工具 (Node.js, Bun, Git, Docker)${NC}"
    echo -e "${MAGENTA}   │  [3]  仅安装 AI 工具${NC}"
    echo -e "${WHITE}   │  [4]  自定义选择${NC}"
    echo -e "${CYAN}   │  [5]  检查更新${NC}"
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

    # 1. 检测包管理器
    install_package_manager_if_needed
    echo ""

    # 2. 安装基础工具
    print_color "$CYAN" "[1/3] 安装基础工具..."
    echo ""
    install_nodejs
    echo ""
    install_bun
    echo ""
    install_git
    echo ""
    if [ "$SKIP_DOCKER" = false ]; then
        install_docker
        echo ""
    fi
    install_python
    echo ""

    # 3. 安装 AI 工具
    if [ "$SKIP_AI" = false ]; then
        print_color "$CYAN" "[2/3] 安装 AI 工具..."
        echo ""
        install_coding_helper
        echo ""

        if [ "$QUIET" = false ]; then
            echo "选择要安装的 AI 编程工具:"
            echo -e "  ${GREEN}[1] OpenCode 中文汉化版${NC}"
            echo -e "  ${CYAN}[2] Claude Code${NC}"
            echo -e "  ${DARK_GRAY}[3] 都不安装${NC}"
            echo ""
            read -p "请选择: " ai_choice
        else
            ai_choice="3"
        fi

        case $ai_choice in
            1) install_opencode_chinese ;;
            2) install_claude_code ;;
        esac
        echo ""
    fi

    # 4. 完成
    print_color "$CYAN" "[3/3] 安装完成"
    print_separator
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          开发环境初始化完成！                               ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    print_color "$CYAN" "下一步:"
    echo -e "  ${WHITE}- coding-helper 或 chelper 启动智谱助手${NC}"
    echo -e "  ${WHITE}- 查看已安装工具版本，运行脚本并选择 [5]${NC}"
    echo ""
}

install_basic_tools() {
    print_header
    print_color "$YELLOW" "       安装基础工具"
    print_separator
    echo ""

    install_package_manager_if_needed
    echo ""

    install_nodejs
    echo ""
    install_bun
    echo ""
    install_git
    echo ""
    if [ "$SKIP_DOCKER" = false ]; then
        install_docker
        echo ""
    fi
    install_python
    echo ""

    print_color "$GREEN" "基础工具安装完成！"
    echo ""
}

install_ai_tools() {
    print_header
    print_color "$YELLOW" "       安装 AI 工具"
    print_separator
    echo ""

    install_coding_helper
    echo ""

    echo "选择要安装的 AI 编程工具:"
    echo -e "  ${GREEN}[1] OpenCode 中文汉化版${NC}"
    echo -e "  ${CYAN}[2] Claude Code${NC}"
    echo -e "  ${WHITE}[3] 两者都安装${NC}"
    echo -e "  ${DARK_GRAY}[0] 返回${NC}"
    echo ""
    read -p "请选择: " ai_choice

    case $ai_choice in
        1) install_opencode_chinese ;;
        2) install_claude_code ;;
        3)
            install_opencode_chinese
            echo ""
            install_claude_code
            ;;
    esac

    echo ""
    print_color "$GREEN" "AI 工具安装完成！"
    echo ""
}

check_updates() {
    print_header
    print_color "$YELLOW" "       检查更新"
    print_separator
    echo ""

    print_color "$CYAN" "检查可更新的组件..."
    echo ""

    declare -A tools=(
        ["Node.js"]="node"
        ["Bun"]="bun"
        ["npm"]="npm"
        ["@z_ai/coding-helper"]="chelper"
    )

    for name in "${!tools[@]}"; do
        cmd="${tools[$name]}"
        if command_exists "$cmd"; then
            version=$(get_version "$cmd")
            echo -e "  [$name] 当前: $version" "${DARK_GRAY}"
        fi
    done

    echo ""
    print_color "$YELLOW" "提示: 使用各包管理器的 upgrade 命令更新"
    echo -e "  ${DARK_GRAY}npm update -g @z_ai/coding-helper${NC}"
    echo -e "  ${DARK_GRAY}bun upgrade${NC}"
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
        "Docker"
        "Python"
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
                3) install_docker ;;
                4) install_python ;;
                5) install_coding_helper ;;
                6) install_opencode_chinese ;;
                7) install_claude_code ;;
            esac
            echo ""
        fi
    done

    print_color "$GREEN" "自定义安装完成！"
    echo ""
}

# ==================== 主循环 ====================
# 检测是否在管道模式（非交互）
if [ ! -t 0 ]; then
    # stdin 不是终端，说明是管道模式
    print_color "$YELLOW" "检测到管道模式（非交互），自动执行一键安装..."
    print_color "$DARK_GRAY" "如需交互模式，请先下载脚本再运行:"
    echo ""
    echo "  wget https://raw.githubusercontent.com/1186258278/OpenCodeChineseTranslation/main/scripts/init-dev-env.sh"
    echo "  chmod +x init-dev-env.sh"
    echo "  ./init-dev-env.sh"
    echo ""
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
        5) check_updates ;;
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
