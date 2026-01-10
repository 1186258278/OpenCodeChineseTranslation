#!/bin/bash
# ========================================
# Codes 一键安装脚本
# 使用方式: curl -fsSL https://raw.githubusercontent.com/1186258278/OpenCodeChineseTranslation/main/scripts/install.sh | bash
# ========================================

set -e

REPO="1186258278/OpenCodeChineseTranslation"
BRANCH="main"
REPO_GITEE="QtCodeCreators/OpenCodeChineseTranslation"
LIB_DIR="/usr/local/lib/codes"
BIN_DIR="/usr/local/bin"

# 智能 sudo
SUDO_CMD=""
if [ "$(id -u)" != "0" ]; then
    if command -v sudo &> /dev/null; then
        SUDO_CMD="sudo"
    else
        echo "错误: 需要 root 权限"
        echo "请运行: sudo bash $0"
        exit 1
    fi
fi

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Codes 一键安装                                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 创建库目录
echo "→ 创建安装目录..."
$SUDO_CMD mkdir -p "$LIB_DIR"

# 下载脚本（GitHub 失败则尝试 Gitee）
echo "→ 下载 codes.sh..."

# GitHub 源
GITHUB_URL="https://raw.githubusercontent.com/$REPO/$BRANCH/scripts/codes.sh"
# Gitee 备用源
GITEE_URL="https://gitee.com/$REPO_GITEE/raw/main/scripts/codes.sh"

downloaded=false
if curl -fsSL --max-time 10 "$GITHUB_URL" -o "$LIB_DIR/codes.sh" 2>/dev/null; then
    echo "  ✓ 从 GitHub 下载成功"
    downloaded=true
elif curl -fsSL --max-time 10 "$GITEE_URL" -o "$LIB_DIR/codes.sh" 2>/dev/null; then
    echo "  ✓ 从 Gitee 下载成功（备用源）"
    downloaded=true
else
    # 尝试 wget
    if command -v wget &> /dev/null; then
        if wget -q --timeout=10 -O "$LIB_DIR/codes.sh" "$GITHUB_URL" 2>/dev/null; then
            echo "  ✓ 从 GitHub 下载成功 (wget)"
            downloaded=true
        elif wget -q --timeout=10 -O "$LIB_DIR/codes.sh" "$GITEE_URL" 2>/dev/null; then
            echo "  ✓ 从 Gitee 下载成功 (wget备用源)"
            downloaded=true
        fi
    fi
fi

if [ "$downloaded" = false ]; then
    echo "  ✗ 下载失败，请检查网络"
    echo ""
    echo "手动下载链接:"
    echo "  GitHub: $GITHUB_URL"
    echo "  Gitee:  $GITEE_URL"
    exit 1
fi

$SUDO_CMD chmod +x "$LIB_DIR/codes.sh"

# 创建 wrapper 脚本
echo "→ 创建 codes 命令..."
cat << 'EOF' | $SUDO_CMD tee "$BIN_DIR/codes" > /dev/null
#!/bin/bash
SCRIPT_DIR="/usr/local/lib/codes"
bash "$SCRIPT_DIR/codes.sh" "$@"
EOF

$SUDO_CMD chmod +x "$BIN_DIR/codes"

echo ""
echo "✓ 安装完成!"
echo ""
echo "使用方法:"
echo "  codes doctor       # 环境诊断"
echo "  codes install      # 安装组件"
echo "  codes install 1    # 只安装 Node.js"
echo "  codes node lts     # 切换到 LTS"
echo "  codes --help       # 更多帮助"
echo ""
