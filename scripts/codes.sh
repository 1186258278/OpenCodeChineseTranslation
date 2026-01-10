#!/bin/bash
# ========================================
# Codes - 开发环境管理工具 v1.0
# 全局命令: codes
# 功能: 环境诊断 / 组件管理 / 快捷启动
# ========================================

VERSION="1.0.0"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
DARK_GRAY='\033[0;90m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_SCRIPT="$SCRIPT_DIR/init-dev-env.sh"

# ==================== 工具函数 ====================
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     Codes - 开发环境管理工具 v${VERSION}                       ║${NC}"
    echo -e "${CYAN}║     环境诊断 • 组件管理 • 快捷启动                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_separator() {
    echo -e "${DARK_GRAY}────────────────────────────────────────────────────────${NC}"
}

# 加载 init 脚本中的函数
load_init_functions() {
    if [ -f "$INIT_SCRIPT" ]; then
        # 加载所有函数
        source "$INIT_SCRIPT"

        # 重新定义颜色变量（因为加载可能覆盖）
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        CYAN='\033[0;36m'
        DARK_GRAY='\033[0;90m'
        WHITE='\033[1;37m'
        NC='\033[0m'
        return 0
    else
        echo "错误: 找不到 init-dev-env.sh" >&2
        return 1
    fi
}

# 命令检测
has_cmd() {
    command -v "$1" &> /dev/null && return 0

    # 检查 nvm 路径
    if [ -x "$HOME/.nvm/versions/node/*/bin/$1" ] 2>/dev/null; then
        export PATH="$HOME/.nvm/versions/node/*/bin:$PATH"
        return 0
    fi

    # 检查 bun 路径
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

# 加载 nvm
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

# 加载 bun
load_bun() {
    if [ -d "$HOME/.bun/bin" ]; then
        export BUN_INSTALL="$HOME/.bun"
        export PATH="$BUN_INSTALL/bin:$PATH"
        return 0
    fi
    return 1
}

# 获取版本
get_ver() {
    if has_cmd "$1"; then
        "$1" --version 2>&1 | head -n 1 | awk '{print $NF}' || echo "unknown"
    else
        echo "not installed"
    fi
}

# 获取包管理器
get_pm() {
    if has_cmd dnf; then echo "dnf"
    elif has_cmd yum; then echo "yum"
    elif has_cmd apt-get; then echo "apt"
    elif has_cmd brew; then echo "brew"
    elif has_cmd pacman; then echo "pacman"
    else echo ""; fi
}

# 获取架构
get_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64) echo "x64" ;;
        aarch64|arm64) echo "arm64" ;;
        *) echo "$arch" ;;
    esac
}

# 智能 sudo
SUDO_CMD=""
if [ "$(id -u)" = "0" ]; then
    SUDO_CMD=""
elif has_cmd sudo; then
    SUDO_CMD="sudo"
else
    SUDO_CMD=""
fi

# ==================== 环境诊断 ====================
show_status() {
    local tool_name=$1
    local cmd_name=$2
    local required=$3

    if has_cmd "$cmd_name"; then
        local version=$(get_ver "$cmd_name")
        echo -e "  ${GREEN}[✓]${NC} $tool_name: ${WHITE}$version${NC}"
    elif [ "$required" = "yes" ]; then
        echo -e "  ${RED}[✗]${NC} $tool_name: ${YELLOW}未安装${NC}"
    else
        echo -e "  ${DARK_GRAY}[⊙]${NC} $tool_name: ${DARK_GRAY}未安装（可选）${NC}"
    fi
}

cmd_doctor() {
    print_header
    print_color "${YELLOW}" "       环境诊断"
    print_separator
    echo ""

    print_color "${CYAN}" "核心工具:"
    show_status "Node.js" "node" "yes"
    show_status "npm" "npm" "yes"
    show_status "Bun" "bun" "no"
    echo ""

    print_color "${CYAN}" "开发工具:"
    show_status "Git" "git" "yes"
    show_status "Python3" "python3" "no"
    echo ""

    print_color "${CYAN}" "AI 工具:"
    show_status "coding-helper" "chelper" "no"
    show_status "coding-helper" "coding-helper" "no"
    echo ""

    # 显示环境变量
    print_color "${CYAN}" "环境变量:"
    [ -n "$NVM_DIR" ] && echo -e "  ${GREEN}[✓]${NC} NVM_DIR=$NVM_DIR" || echo -e "  ${DARK_GRAY}[⊙]${NC} NVM_DIR 未设置"
    [ -n "$BUN_INSTALL" ] && echo -e "  ${GREEN}[✓]${NC} BUN_INSTALL=$BUN_INSTALL" || echo -e "  ${DARK_GRAY}[⊙]${NC} BUN_INSTALL 未设置"
    echo ""

    # 检查 PATH
    if has_cmd node && ! echo "$PATH" | grep -q "$(npm bin -g 2>/dev/null)"; then
        print_color "${YELLOW}" "  [!] npm 全局 bin 目录可能不在 PATH 中"
    fi
    echo ""

    print_separator
    print_color "${CYAN}" "快捷命令:"
    echo -e "  ${DARK_GRAY}codes install${NC}     - 安装缺失的组件"
    echo -e "  ${DARK_GRAY}codes upgrade${NC}     - 升级已安装的组件"
    echo -e "  ${DARK_GRAY}codes node <ver>${NC}  - 切换 Node.js 版本"
    echo -e "  ${DARK_GRAY}codes helper${NC}      - 启动 coding-helper"
    echo ""
}

# ==================== 组件管理 ====================
cmd_install() {
    print_header
    print_color "${YELLOW}" "       安装组件"
    print_separator
    echo ""

    # 加载安装函数
    load_init_functions || return 1

    # 检查需要安装的组件
    local need_install=()

    ! has_cmd node && need_install+=("Node.js")
    ! has_cmd bun && need_install+=("Bun")
    ! has_cmd git && need_install+=("Git")
    ! has_cmd python3 && need_install+=("Python")

    if [ ${#need_install[@]} -eq 0 ]; then
        print_color "${GREEN}" "  ✓ 所有核心组件已安装"
        echo ""
        read -p "是否要安装 coding-helper? (y/N): " install_helper
        if [[ $install_helper =~ ^[Yy]$ ]]; then
            install_coding_helper
        fi
        return 0
    fi

    print_color "${YELLOW}" "  需要安装的组件:"
    for item in "${need_install[@]}"; do
        echo -e "    - $item"
    done
    echo ""

    read -p "是否继续? (Y/n): " confirm
    if [[ $confirm =~ ^[Nn]$ ]]; then
        return 0
    fi

    echo ""

    # 安装缺失的组件
    ! has_cmd node && { install_nodejs; echo ""; }
    ! has_cmd bun && { install_bun; echo ""; }
    ! has_cmd git && { install_git; echo ""; }
    ! has_cmd python3 && { install_python; echo ""; }

    print_color "${CYAN}" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "${CYAN}" "  AI 工具"
    print_color "${CYAN}" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    install_coding_helper
    echo ""

    # 显示汇总
    if declare -f print_summary > /dev/null; then
        print_summary
    fi
}

cmd_upgrade() {
    print_header
    print_color "${YELLOW}" "       升级组件"
    print_separator
    echo ""

    load_nvm
    load_bun

    print_color "${CYAN}" "可用升级:"
    echo ""

    # Node.js 升级
    if has_cmd nvm && has_cmd node; then
        local current_ver=$(node -v)
        print_color "${WHITE}" "  Node.js 当前版本: $current_ver"
        echo -e "    ${DARK_GRAY}nvm install --lts${NC} - 安装最新 LTS"
        echo -e "    ${DARK_GRAY}nvm install --lts && nvm alias default lts/*${NC} - 设为默认"
        echo ""
    fi

    # Bun 升级
    if has_cmd bun; then
        local current_ver=$(bun --version)
        print_color "${WHITE}" "  Bun 当前版本: $current_ver"
        echo -e "    ${DARK_GRAY}bun upgrade${NC} - 升级到最新版"
        echo ""
    fi

    # coding-helper 升级
    if has_cmd npm; then
        print_color "${WHITE}" "  coding-helper:"
        echo -e "    ${DARK_GRAY}npm update -g @z_ai/coding-helper${NC} - 升级到最新版"
        echo ""
    fi

    print_separator
    read -p "是否自动执行升级? (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        echo ""
        has_cmd nvm && nvm install --lts 2>/dev/null && nvm alias default lts/* 2>/dev/null
        has_cmd bun && bun upgrade 2>/dev/null
        has_cmd npm && npm update -g @z_ai/coding-helper 2>/dev/null
        echo ""
        print_color "${GREEN}" "  ✓ 升级完成"
        echo ""
        print_color "${YELLOW}" "  ! 请重新加载终端或运行: source ~/.bashrc"
    fi
}

# ==================== Node 管理 ====================
cmd_node() {
    local target_version=$1

    load_nvm

    if ! has_cmd nvm; then
        print_color "${RED}" "  ✗ nvm 未安装"
        return 1
    fi

    if [ -z "$target_version" ]; then
        # 显示当前版本和可用版本
        print_header
        print_color "${YELLOW}" "       Node.js 版本管理"
        print_separator
        echo ""

        if has_cmd node; then
            local current=$(node -v)
            print_color "${GREEN}" "  当前版本: $current"
        fi

        echo ""
        print_color "${CYAN}" "  已安装版本:"
        nvm ls 2>/dev/null | grep -v "N/A" || echo "    无"
        echo ""

        print_color "${CYAN}" "  常用命令:"
        echo -e "    ${DARK_GRAY}codes node lts${NC}     - 安装/切换到 LTS"
        echo -e "    ${DARK_GRAY}codes node latest${NC}  - 安装/切换到最新版"
        echo -e "    ${DARK_GRAY}codes node 20${NC}      - 安装/切换到 v20"
        echo -e "    ${DARK_GRAY}codes node 22${NC}      - 安装/切换到 v22"
        echo ""
        return 0
    fi

    # 处理特殊版本名
    case $target_version in
        lts|LTS)
            target_version="--lts"
            print_color "${CYAN}" "  切换到 LTS 版本..."
            ;;
        latest)
            target_version="node"
            print_color "${CYAN}" "  切换到最新版本..."
            ;;
        *)
            # 确保版本号以 v 开头
            [[ ! $target_version =~ ^v ]] && target_version="v$target_version"
            print_color "${CYAN}" "  切换到 $target_version..."
            ;;
    esac

    nvm install "$target_version" 2>/dev/null
    nvm alias default "$target_version" 2>/dev/null
    nvm use "$target_version" 2>/dev/null

    load_nvm

    if has_cmd node; then
        print_color "${GREEN}" "  ✓ 当前版本: $(node -v)"
        print_color "${YELLOW}" "  ! 运行 'source ~/.bashrc' 使更改生效"
    else
        print_color "${RED}" "  ✗ 切换失败"
        return 1
    fi
}

# ==================== 快捷启动 ====================
cmd_helper() {
    load_nvm
    load_bun

    # 确保 npm bin 在 PATH 中
    local npm_bin="$(npm bin -g 2>/dev/null)"
    if [ -n "$npm_bin" ]; then
        export PATH="$npm_bin:$PATH"
    fi

    if has_cmd coding-helper; then
        coding-helper "$@"
    elif has_cmd chelper; then
        chelper "$@"
    else
        print_color "${RED}" "  ✗ coding-helper 未安装"
        echo ""
        echo -e "  运行 ${DARK_GRAY}codes install${NC} 来安装"
        return 1
    fi
}

cmd_env() {
    print_header
    print_color "${YELLOW}" "       环境变量"
    print_separator
    echo ""

    load_nvm
    load_bun

    print_color "${CYAN}" "当前环境:"
    echo ""

    # Node.js
    if has_cmd node; then
        echo -e "  ${GREEN}Node.js${NC}: $(node -v) at $(which node)"
        echo -e "  ${GREEN}npm${NC}: $(npm -v) at $(which npm)"
    fi
    echo ""

    # Bun
    if has_cmd bun; then
        echo -e "  ${GREEN}Bun${NC}: $(bun --version) at $(which bun)"
    fi
    echo ""

    # 环境变量
    print_color "${CYAN}" "环境变量:"
    echo "  NVM_DIR=${NVM_DIR:-未设置}"
    echo "  BUN_INSTALL=${BUN_INSTALL:-未设置}"
    echo ""

    # npm 配置
    if has_cmd npm; then
        print_color "${CYAN}" "npm 配置:"
        npm config get registry 2>/dev/null | sed 's/^/  /'
    fi
    echo ""

    # 导出命令
    print_color "${YELLOW}" "导出环境变量（复制到其他终端使用）:"
    echo -e "${DARK_GRAY}"
    if [ -n "$NVM_DIR" ]; then
        echo "export NVM_DIR=\"$NVM_DIR\""
        echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\""
    fi
    if [ -n "$BUN_INSTALL" ]; then
        echo "export BUN_INSTALL=\"$BUN_INSTALL\""
        echo "export PATH=\"\$BUN_INSTALL/bin:\$PATH\""
    fi
    if has_cmd npm; then
        local npm_bin=$(npm bin -g 2>/dev/null)
        if [ -n "$npm_bin" ]; then
            echo "export PATH=\"$npm_bin:\$PATH\""
        fi
    fi
    echo -e "${NC}"
}

cmd_init() {
    if [ -f "$INIT_SCRIPT" ]; then
        bash "$INIT_SCRIPT"
    else
        print_color "${RED}" "  ✗ 找不到 init-dev-env.sh"
        return 1
    fi
}

# ==================== 主菜单 ====================
show_menu() {
    print_header

    # 快速状态
    local node_ver=$(has_cmd node && get_ver node || echo "未安装")
    local bun_ver=$(has_cmd bun && get_ver bun || echo "未安装")

    echo -e "${CYAN}   ┌─── 状态 ─────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}   │${NC}   Node: ${WHITE}$node_ver${NC}"
    echo -e "${CYAN}   │${NC}   Bun:  ${WHITE}$bun_ver${NC}"
    echo -e "${CYAN}   └───────────────────────────────────────────────────┘${NC}"
    echo ""

    echo -e "${CYAN}   ┌─── 主菜单 ────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}   │${NC}"
    echo -e "${GREEN}   │  [1]  环境诊断      - 检查所有工具状态${NC}"
    echo -e "${YELLOW}   │  [2]  安装组件      - 安装缺失的工具${NC}"
    echo -e "${BLUE}   │  [3]  升级组件      - 升级已安装的工具${NC}"
    echo -e "${MAGENTA}   │  [4]  Node 管理    - 切换 Node.js 版本${NC}"
    echo -e "${CYAN}   │  [5]  coding-helper - 启动智谱编码助手${NC}"
    echo -e "${CYAN}   │  [6]  环境变量      - 显示/导出环境变量${NC}"
    echo -e "${CYAN}   │  [7]  初始化安装    - 运行完整安装脚本${NC}"
    echo -e "${CYAN}   │${NC}"
    echo -e "${RED}   │  [0]  退出${NC}"
    echo -e "${CYAN}   │${NC}"
    echo -e "${CYAN}   └───────────────────────────────────────────────────┘${NC}"
    echo ""

    echo -e "${DARK_GRAY}提示: 也可以直接运行 'codes <命令>'，如: codes doctor${NC}"
    echo ""
}

# ==================== 帮助 ====================
show_help() {
    cat << EOF
${BOLD}Codes${NC} - 开发环境管理工具 v${VERSION}

${CYAN}用法:${NC}
  codes [命令] [参数]

${CYAN}命令:${NC}
  ${GREEN}doctor${NC}       环境诊断 - 检查所有工具状态
  ${GREEN}install${NC}      安装组件 - 安装缺失的工具
  ${GREEN}upgrade${NC}      升级组件 - 升级已安装的工具
  ${GREEN}node${NC} [ver]   Node 管理 - 切换 Node.js 版本
                  可用: lts, latest, 或具体版本号 (如 20, 22)
  ${GREEN}helper${NC} [...]  coding-helper - 启动智谱编码助手
  ${GREEN}env${NC}          环境变量 - 显示/导出环境变量
  ${GREEN}init${NC}         初始化安装 - 运行完整安装脚本
  ${GREEN}menu${NC}         显示交互菜单
  ${GREEN}--version${NC}    显示版本信息
  ${GREEN}--help${NC}       显示此帮助信息

${CYAN}示例:${NC}
  codes doctor              # 诊断环境
  codes node lts            # 切换到 LTS 版本
  codes node 22             # 切换到 v22
  codes helper auth         # 运行 coding-helper auth
  codes install             # 安装缺失组件

${CYAN}全局安装:${NC}
  codes --install-self      # 安装 codes 为全局命令

EOF
}

# ==================== 全局安装 ====================
cmd_install_self() {
    print_header
    print_color "${YELLOW}" "       安装 codes 为全局命令"
    print_separator
    echo ""

    local install_dir="/usr/local/bin"
    local script_source="$SCRIPT_DIR/codes.sh"

    # 检查权限
    if [ "$(id -u)" != "0" ] && ! has_cmd sudo; then
        print_color "${RED}" "  ✗ 需要 root 权限"
        echo ""
        echo "  请运行: sudo bash $0 --install-self"
        return 1
    fi

    # 复制脚本
    print_color "${CYAN}" "  复制脚本到 $install_dir..."
    $SUDO_CMD cp "$script_source" "$install_dir/codes" 2>/dev/null

    if [ $? -eq 0 ]; then
        $SUDO_CMD chmod +x "$install_dir/codes" 2>/dev/null
        print_color "${GREEN}" "  ✓ 安装成功!"
        echo ""
        echo "  现在可以在任何位置运行 ${GREEN}codes${NC} 命令"
        return 0
    else
        print_color "${RED}" "  ✗ 安装失败"
        return 1
    fi
}

# ==================== 主入口 ====================
main() {
    # 加载 init 脚本函数
    load_init_functions

    local command=${1:-menu}

    case $command in
        doctor|diag|check)
            cmd_doctor
            ;;
        install|add)
            cmd_install
            ;;
        upgrade|update)
            cmd_upgrade
            ;;
        node)
            cmd_node "$2"
            ;;
        helper|chelper|coding-helper)
            shift
            cmd_helper "$@"
            ;;
        env|environment)
            cmd_env
            ;;
        init|setup)
            cmd_init
            ;;
        menu|interactive)
            # 交互式菜单
            if [ ! -t 0 ]; then
                # 非交互模式，显示状态
                cmd_doctor
                exit 0
            fi

            while true; do
                show_menu
                read -p "请选择: " choice

                case $choice in
                    1) cmd_doctor ;;
                    2) cmd_install ;;
                    3) cmd_upgrade ;;
                    4) cmd_node ;;
                    5) cmd_helper ;;
                    6) cmd_env ;;
                    7) cmd_init ;;
                    0)
                        print_color "${DARK_GRAY}" "再见！"
                        exit 0
                        ;;
                    *)
                        print_color "${RED}" "无效选择"
                        ;;
                esac

                echo ""
                read -p "按回车键继续..."
            done
            ;;
        --version|-v)
            echo "Codes v${VERSION}"
            ;;
        --help|-h)
            show_help
            ;;
        --install-self)
            cmd_install_self
            ;;
        *)
            print_color "${RED}" "未知命令: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
