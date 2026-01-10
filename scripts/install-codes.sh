#!/bin/bash
# ========================================
# Codes 全局安装脚本
# 平台: Linux / macOS
# ========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.codes"
BIN_DIR="$INSTALL_DIR/bin"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Codes 全局安装                                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 创建目录
mkdir -p "$BIN_DIR"

# 复制脚本
echo "→ 复制脚本到 $BIN_DIR..."
cp "$SCRIPT_DIR/codes.sh" "$BIN_DIR/codes"
chmod +x "$BIN_DIR/codes"

# 创建 wrapper
cat > "$BIN_DIR/codes-wrapper" << 'WRAPPER'
#!/bin/bash
# Codes wrapper - 自动加载环境
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# npm bin
if command -v npm &> /dev/null; then
    NPM_BIN="$(npm bin -g 2>/dev/null)"
    [ -n "$NPM_BIN" ] && export PATH="$NPM_BIN:$PATH"
fi

exec ~/.codes/bin/codes "$@"
WRAPPER

chmod +x "$BIN_DIR/codes-wrapper"

# 链接到 /usr/local/bin
if [ -w /usr/local/bin ] || command -v sudo &> /dev/null; then
    echo "→ 创建全局命令..."
    if [ -w /usr/local/bin ]; then
        ln -sf "$BIN_DIR/codes-wrapper" /usr/local/bin/codes
    else
        sudo ln -sf "$BIN_DIR/codes-wrapper" /usr/local/bin/codes
    fi
fi

# 添加到 PATH (如果还没)
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    SHELL_CONFIG="$HOME/.bashrc"

    # 检测 shell
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    fi

    echo ""
    echo "→ 添加到 PATH..."

    # 检查是否已添加
    if ! grep -q 'codes/bin' "$SHELL_CONFIG" 2>/dev/null; then
        echo "" >> "$SHELL_CONFIG"
        echo "# Codes - 开发环境管理工具" >> "$SHELL_CONFIG"
        echo "export PATH=\"\$HOME/.codes/bin:\$PATH\"" >> "$SHELL_CONFIG"
        echo "" >> "$SHELL_CONFIG"
    fi
fi

echo ""
echo "✓ 安装完成!"
echo ""
echo "运行以下命令使更改生效:"
echo "  source ~/.bashrc"
echo ""
echo "然后就可以使用 codes 命令了:"
echo "  codes doctor    # 环境诊断"
echo "  codes --help    # 查看帮助"
