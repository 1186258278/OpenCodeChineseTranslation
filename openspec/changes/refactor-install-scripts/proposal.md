# 提案：重构安装脚本系统

## 背景

当前安装脚本存在多个严重问题，影响用户体验：

1. **目录定位逻辑错误**
   - Windows/Linux 都安装到用户目录而不是当前终端目录
   - 用户在任意目录运行安装，却被安装到固定位置

2. **Linux 全局命令损坏**
   - `opencodecmd` 引用了 install.sh 中的函数（print_info 等）
   - 这些函数在全局命令脚本中不存在

3. **错误输出未正确处理**
   - Windows git pull 输出被当作错误显示
   - `2>&1 | Out-Null` 应该是 `2>&1 >$null` 或使用 `$null = ...`

4. **安装流程不连贯**
   - 安装后用户需要手动 source 配置
   - 没有自动刷新环境变量
   - Windows 的 PATH 需要重启终端才生效

5. **跨平台不一致**
   - Windows 使用 `~/.local/bin`（Linux 风格）
   - Linux 使用 `~/.local/bin`（正确）
   - 但 Windows 应该用 `%LOCALAPPDATA%` 或添加到 `Path` 用户变量

## 目标

创建**真正傻瓜式**的一键安装体验：

- [x] 用户在哪个目录运行，就安装到哪里
- [x] 全局命令立即可用，无需重启终端
- [x] 错误信息清晰，无干扰输出
- [x] Windows/Linux 体验一致

## 变更概述

### 1. 目录策略重构

**旧逻辑**：
```bash
# 强制安装到用户目录
PROJECT_DIR="$HOME/OpenCodeChineseTranslation"
```

**新逻辑**：
```bash
# 优先当前目录（如果是 git 仓库）
if [ -d .git ]; then
    PROJECT_DIR="$(pwd)"
elif [ -d "$HOME/OpenCodeChineseTranslation/.git" ]; then
    PROJECT_DIR="$HOME/OpenCodeChineseTranslation"
else
    # 询问用户
    echo "选择安装目录："
    echo "  [1] 当前目录: $(pwd)"
    echo "  [2] 用户目录: $HOME/OpenCodeChineseTranslation"
fi
```

### 2. 全局命令独立化

**问题**：install.sh 中的函数被 opencodecmd 引用

**解决**：opencodecmd 必须是自包含的，不依赖外部函数

```bash
#!/bin/bash
# opencodecmd - 独立脚本，不依赖 install.sh

# 查找项目目录
find_project() {
    local dir="$(pwd)"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/scripts/opencode-linux/opencode.js" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    # 检查用户目录
    if [ -f "$HOME/OpenCodeChineseTranslation/scripts/opencode-linux/opencode.js" ]; then
        echo "$HOME/OpenCodeChineseTranslation"
        return 0
    fi
    return 1
}

# 主逻辑
PROJECT=$(find_project)
if [ -n "$PROJECT" ]; then
    cd "$PROJECT" && node "$PROJECT/scripts/opencode-linux/opencode.js" "$@"
else
    echo "错误: 未找到 OpenCode 项目" >&2
    echo "请先运行安装脚本或进入项目目录" >&2
    exit 1
fi
```

### 3. Windows 全局命令路径修正

**问题**：Windows 使用 `~/.local/bin` 不合适

**解决**：
- 创建批处理文件到 `%USERPROFILE%\AppData\Local\Microsoft\WindowsApps`
- 或创建到自定义目录并添加到用户 PATH

### 4. 立即生效机制

**Linux**：
```bash
# 安装后立即刷新当前 shell
export PATH="$HOME/.local/bin:$PATH"
hash -r
```

**Windows**：
```powershell
# 添加到当前会话
$env:Path += ";$CMD_DIR"

# 添加到用户环境变量（持久）
[Environment]::SetEnvironmentVariable("Path", "...", "User")
```

### 5. 错误输出静默

**PowerShell**：
```powershell
# 错误写法
git pull --rebase 2>&1 | Out-Null  # 仍会输出到 stderr

# 正确写法
$null = git pull --rebase 2>&1
# 或
git pull --rebase *> $null
```

## 文件变更

| 文件 | 变更类型 | 说明 |
|------|----------|------|
| `scripts/install.sh` | MODIFIED | 重写目录逻辑，修复全局命令生成 |
| `scripts/install.ps1` | MODIFIED | 重写目录逻辑，修复错误处理 |
| `scripts/opencode-linux/install-global.sh` | MODIFIED | 确保独立运行 |
| `scripts/opencode/install-global.ps1` | NEW | 创建 Windows 全局命令安装脚本 |

## 验收标准

1. **Windows 用户**：
   ```powershell
   # 在任意目录运行
   cd D:\MyProjects
   irm https://.../install.ps1 | iex

   # 结果：安装到 D:\MyProjects\OpenCodeChineseTranslation
   # opencodecmd.bat 立即可用
   ```

2. **Linux 用户**：
   ```bash
   # 在任意目录运行
   cd /opt/my-projects
   curl .../install.sh | bash

   # 结果：安装到 /opt/my-projects/OpenCodeChineseTranslation
   # opencodecmd 立即可用
   ```

3. **全局命令测试**：
   - `opencodecmd` 启动菜单（无错误）
   - `opencodecmd full` 执行全流程
   - 从任意目录运行都能找到项目

## 实施任务

详见 [tasks.md](./tasks.md)

## 风险评估

- **低风险**：重构安装脚本，不影响已安装用户
- **测试要求**：需要在 Windows 和 Linux 上分别测试
