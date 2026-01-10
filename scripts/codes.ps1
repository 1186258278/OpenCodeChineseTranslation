# ========================================
# Codes - 开发环境管理工具 v1.0
# 全局命令: codes
# 平台: Windows PowerShell
# 功能: 环境诊断 / 组件管理 / 快捷启动
# ========================================

param(
    [Parameter(Position=0)]
    [string]$Command = "menu",

    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Args
)

$VERSION = "1.0.0"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$INIT_SCRIPT = Join-Path $SCRIPT_DIR "init-dev-env.ps1"

# ==================== 工具函数 ====================
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    Write-Host $Message -ForegroundColor $ForegroundColor
}

function Write-Header {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     Codes - 开发环境管理工具 v$VERSION                       ║" -ForegroundColor Cyan
    Write-Host "║     环境诊断 • 组件管理 • 快捷启动                            ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Separator {
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor DarkGray
}

function Test-Command {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Get-InstalledVersion {
    param([string]$Command)
    try {
        $version = & $Command --version 2>&1 | Select-Object -First 1
        if ($LASTEXITCODE -eq 0 -or $?) {
            return "$version".Trim()
        }
    } catch {}
    return $null
}

# 加载 init 脚本函数
function Load-InitFunctions {
    if (Test-Path $INIT_SCRIPT) {
        . $INIT_SCRIPT
        return $true
    } else {
        Write-ColorOutput "错误: 找不到 init-dev-env.ps1" "Red"
        return $false
    }
}

# ==================== 环境诊断 ====================
function Show-Status {
    param(
        [string]$ToolName,
        [string]$CommandName,
        [bool]$Required = $true
    )

    if (Test-Command $CommandName) {
        $version = Get-InstalledVersion $CommandName
        Write-Host "  [✓] " -NoNewline -ForegroundColor Green
        Write-Host "$ToolName`: " -NoNewline
        Write-Host "$version" -ForegroundColor White
    } elseif ($Required) {
        Write-Host "  [✗] " -NoNewline -ForegroundColor Red
        Write-Host "$ToolName`: " -NoNewline
        Write-Host "未安装" -ForegroundColor Yellow
    } else {
        Write-Host "  [⊙] " -NoNewline -ForegroundColor DarkGray
        Write-Host "$ToolName`: " -NoNewline
        Write-Host "未安装（可选）" -ForegroundColor DarkGray
    }
}

function Command-Doctor {
    Write-Header
    Write-ColorOutput "       环境诊断" "Yellow"
    Write-Separator
    Write-Host ""

    Write-ColorOutput "核心工具:" "Cyan"
    Show-Status "Node.js" "node" $true
    Show-Status "npm" "npm" $true
    Show-Status "Bun" "bun" $false
    Write-Host ""

    Write-ColorOutput "开发工具:" "Cyan"
    Show-Status "Git" "git" $true
    Show-Status "Python" "python" $false
    Write-Host ""

    Write-ColorOutput "AI 工具:" "Cyan"
    Show-Status "coding-helper" "chelper" $false
    Show-Status "coding-helper" "coding-helper" $false
    Write-Host ""

    # 显示包管理器
    Write-ColorOutput "包管理器:" "Cyan"
    if (Test-Command "winget") { Write-Host "  [✓] winget" -ForegroundColor Green }
    if (Get-Command "scoop" -ErrorAction SilentlyContinue) { Write-Host "  [✓] scoop" -ForegroundColor Green }
    if (Get-Command "choco" -ErrorAction SilentlyContinue) { Write-Host "  [✓] chocolatey" -ForegroundColor Green }
    Write-Host ""

    Write-Separator
    Write-ColorOutput "快捷命令:" "Cyan"
    Write-Host "  codes install     - 安装缺失的组件" -ForegroundColor DarkGray
    Write-Host "  codes upgrade     - 升级已安装的组件" -ForegroundColor DarkGray
    Write-Host "  codes helper      - 启动 coding-helper" -ForegroundColor DarkGray
    Write-Host ""
}

# ==================== 组件管理 ====================
function Command-Install {
    Write-Header
    Write-ColorOutput "       安装组件" "Yellow"
    Write-Separator
    Write-Host ""

    # 加载安装函数
    if (-not (Load-InitFunctions)) {
        return
    }

    # 检查需要安装的组件
    $needInstall = @()

    if (-not (Test-Command "node")) { $needInstall += "Node.js" }
    if (-not (Test-Command "bun")) { $needInstall += "Bun" }
    if (-not (Test-Command "git")) { $needInstall += "Git" }
    if (-not (Test-Command "python")) { $needInstall += "Python" }

    if ($needInstall.Count -eq 0) {
        Write-ColorOutput "  ✓ 所有核心组件已安装" "Green"
        Write-Host ""

        $installHelper = Read-Host "是否要安装 coding-helper? (y/N)"
        if ($installHelper -eq "y" -or $installHelper -eq "Y") {
            Install-CodingHelper
        }
        return
    }

    Write-ColorOutput "  需要安装的组件:" "Yellow"
    foreach ($item in $needInstall) {
        Write-Host "    - $item"
    }
    Write-Host ""

    $confirm = Read-Host "是否继续? (Y/n)"
    if ($confirm -eq "n" -or $confirm -eq "N") {
        return
    }

    Write-Host ""

    # 安装缺失的组件
    if (-not (Test-Command "node")) { Install-NodeJS; Write-Host "" }
    if (-not (Test-Command "bun")) { Install-Bun; Write-Host "" }
    if (-not (Test-Command "git")) { Install-Git; Write-Host "" }
    if (-not (Test-Command "python")) { Install-Python; Write-Host "" }

    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
    Write-ColorOutput "  AI 工具" "Cyan"
    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
    Write-Host ""

    Install-CodingHelper
    Write-Host ""

    # 显示汇总
    Show-Summary
}

function Command-Upgrade {
    Write-Header
    Write-ColorOutput "       升级组件" "Yellow"
    Write-Separator
    Write-Host ""

    Write-ColorOutput "可用升级:" "Cyan"
    Write-Host ""

    # Node.js 升级
    if (Test-Command "node") {
        $currentVer = node -v
        Write-ColorOutput "  Node.js 当前版本: $currentVer" "White"
        Write-Host "    使用 winget 升级: winget upgrade OpenJS.NodeJS" -ForegroundColor DarkGray
        Write-Host ""
    }

    # Bun 升级
    if (Test-Command "bun") {
        $currentVer = bun --version
        Write-ColorOutput "  Bun 当前版本: $currentVer" "White"
        Write-Host "    bun upgrade" -ForegroundColor DarkGray
        Write-Host ""
    }

    # coding-helper 升级
    if (Test-Command "npm") {
        Write-ColorOutput "  coding-helper:" "White"
        Write-Host "    npm update -g @z_ai/coding-helper" -ForegroundColor DarkGray
        Write-Host ""
    }

    Write-Separator
    $confirm = Read-Host "是否自动执行升级? (y/N)"
    if ($confirm -eq "y" -or $confirm -eq "Y") {
        Write-Host ""
        if (Test-Command "winget") { winget upgrade --id OpenJS.NodeJS --accept-package-agreements --accept-source-agreements -h 2>$null }
        if (Test-Command "bun") { bun upgrade 2>$null }
        if (Test-Command "npm") { npm update -g @z_ai/coding-helper 2>$null }
        Write-Host ""
        Write-ColorOutput "  ✓ 升级完成" "Green"
        Write-Host ""
        Write-ColorOutput "  ! 请重启终端使环境变量生效" "Yellow"
    }
}

# ==================== 快捷启动 ====================
function Command-Helper {
    if (Test-Command "coding-helper") {
        & coding-helper $Args
    } elseif (Test-Command "chelper") {
        & chelper $Args
    } else {
        Write-ColorOutput "  ✗ coding-helper 未安装" "Red"
        Write-Host ""
        Write-Host "  运行 'codes install' 来安装" -ForegroundColor DarkGray
        return 1
    }
}

function Command-Env {
    Write-Header
    Write-ColorOutput "       环境变量" "Yellow"
    Write-Separator
    Write-Host ""

    Write-ColorOutput "当前环境:" "Cyan"
    Write-Host ""

    # Node.js
    if (Test-Command "node") {
        $nodePath = Get-Command node | Select-Object -ExpandProperty Source
        Write-Host "  Node.js: " -NoNewline -ForegroundColor Green
        Write-Host "$(node -v) at $nodePath" -ForegroundColor White
        $npmPath = Get-Command npm | Select-Object -ExpandProperty Source
        Write-Host "  npm: " -NoNewline -ForegroundColor Green
        Write-Host "$(npm -v) at $npmPath" -ForegroundColor White
    }
    Write-Host ""

    # Bun
    if (Test-Command "bun") {
        $bunPath = Get-Command bun | Select-Object -ExpandProperty Source
        Write-Host "  Bun: " -NoNewline -ForegroundColor Green
        Write-Host "$(bun --version) at $bunPath" -ForegroundColor White
    }
    Write-Host ""

    # npm 配置
    if (Test-Command "npm") {
        Write-ColorOutput "npm 配置:" "Cyan"
        npm config get registry 2>$null | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    }
    Write-Host ""
}

function Command-Init {
    if (Test-Path $INIT_SCRIPT) {
        & $INIT_SCRIPT
    } else {
        Write-ColorOutput "  ✗ 找不到 init-dev-env.ps1" "Red"
        return 1
    }
}

# ==================== 主菜单 ====================
function Show-Menu {
    Write-Header

    # 快速状态
    $nodeVer = if (Test-Command "node") { Get-InstalledVersion "node" } else { "未安装" }
    $bunVer = if (Test-Command "bun") { Get-InstalledVersion "bun" } else { "未安装" }

    Write-Host "   ┌─── 状态 ─────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "   │" -ForegroundColor Cyan
    Write-Host "   │   Node: " -NoNewline -ForegroundColor Cyan
    Write-Host "$nodeVer" -ForegroundColor White
    Write-Host "   │   Bun:  " -NoNewline -ForegroundColor Cyan
    Write-Host "$bunVer" -ForegroundColor White
    Write-Host "   │" -ForegroundColor Cyan
    Write-Host "   └───────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "   ┌─── 主菜单 ────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "   │" -ForegroundColor Cyan
    Write-Host "   │  [1]  环境诊断      - 检查所有工具状态" -ForegroundColor Green
    Write-Host "   │  [2]  安装组件      - 安装缺失的工具" -ForegroundColor Yellow
    Write-Host "   │  [3]  升级组件      - 升级已安装的工具" -ForegroundColor Blue
    Write-Host "   │  [4]  coding-helper - 启动智谱编码助手" -ForegroundColor Cyan
    Write-Host "   │  [5]  环境变量      - 显示/导出环境变量" -ForegroundColor Cyan
    Write-Host "   │  [6]  初始化安装    - 运行完整安装脚本" -ForegroundColor Cyan
    Write-Host "   │" -ForegroundColor Cyan
    Write-Host "   │  [0]  退出" -ForegroundColor Red
    Write-Host "   │" -ForegroundColor Cyan
    Write-Host "   └───────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "提示: 也可以直接运行 'codes <命令>'，如: codes doctor" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-Help {
    @"
Codes - 开发环境管理工具 v$VERSION

用法:
  codes [命令] [参数]

命令:
  doctor       环境诊断 - 检查所有工具状态
  install      安装组件 - 安装缺失的工具
  upgrade      升级组件 - 升级已安装的工具
  helper [...] coding-helper - 启动智谱编码助手
  env          环境变量 - 显示/导出环境变量
  init         初始化安装 - 运行完整安装脚本
  menu         显示交互菜单
  --version    显示版本信息
  --help       显示此帮助信息

示例:
  codes doctor              # 诊断环境
  codes helper auth         # 运行 coding-helper auth
  codes install             # 安装缺失组件

全局安装:
  codes --install-self      # 安装 codes 为全局命令

"@
}

# ==================== 全局安装 ====================
function Command-InstallSelf {
    Write-Header
    Write-ColorOutput "       安装 codes 为全局命令" "Yellow"
    Write-Separator
    Write-Host ""

    # 创建安装目录
    $installDir = "$env:USERPROFILE\.codes"
    $binDir = "$env:USERPROFILE\.codes\bin"

    if (-not (Test-Path $binDir)) {
        New-Item -ItemType Directory -Path $binDir -Force | Out-Null
    }

    # 复制脚本
    Write-ColorOutput "  复制脚本到 $installDir..." "Cyan"
    Copy-Item $SCRIPT_DIR\codes.ps1 "$binDir\codes.ps1" -Force

    # 创建 wrapper 脚本
    $wrapperBat = @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "$binDir\codes.ps1" %*
"@
    $wrapperBat | Out-File "$binDir\codes.bat" -Encoding ASCII

    # 创建 wrapper ps1
    $wrapperPs1 = @"
# Codes wrapper
& "$binDir\codes.ps1" @args
"@
    $wrapperPs1 | Out-File "$binDir\codes.ps1" -Encoding UTF8

    Write-ColorOutput "  ✓ 安装成功!" "Green"
    Write-Host ""
    Write-Host "  添加到 PATH:" -ForegroundColor Yellow
    Write-Host "    $binDir" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  或运行:" -ForegroundColor Yellow
    Write-Host "    [Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User') + ';$binDir', 'User')" -ForegroundColor DarkGray
    Write-Host ""
}

# ==================== 主入口 ====================
switch ($Command) {
    "doctor" { Command-Doctor }
    "install" { Command-Install }
    "upgrade" { Command-Upgrade }
    "helper" { Command-Helper $Args }
    "env" { Command-Env }
    "init" { Command-Init }
    "menu" {
        Show-Menu
        $choice = Read-Host "请选择"

        switch ($choice) {
            "1" { Command-Doctor }
            "2" { Command-Install }
            "3" { Command-Upgrade }
            "4" { Command-Helper }
            "5" { Command-Env }
            "6" { Command-Init }
            "0" {
                Write-ColorOutput "再见！" "DarkGray"
                exit
            }
            default {
                Write-ColorOutput "无效选择" "Red"
            }
        }

        if ($choice -ne "0") {
            Write-Host ""
            Read-Host "按回车键继续"
        }
    }
    "--version" { Write-Host "Codes v$VERSION" }
    "--help" { Show-Help }
    "--install-self" { Command-InstallSelf }
    default {
        Write-ColorOutput "未知命令: $Command" "Red"
        Write-Host ""
        Show-Help
        exit 1
    }
}
