# ========================================
# Codes - 开发环境管理工具 v1.1
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

$VERSION = "1.1.0"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# 国内镜像
$NPM_REGISTRY = "https://registry.npmmirror.com"
$NVM_INSTALL_SCRIPT = "https://ghp.ci/https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh"

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

# 加载 nvm 环境
function Initialize-Nvm {
    if (Test-Path "$env:USERPROFILE\.nvm") {
        $env:NVM_DIR = "$env:USERPROFILE\.nvm"
        $nvmSh = "$env:NVM_DIR\nvm.sh"
        if (Test-Path $nvmSh) {
            # Windows 使用 nvm-windows，直接加载
        }
        # 查找最新 Node.js 版本
        $nodeVersions = "$env:NVM_DIR\versions\node"
        if (Test-Path $nodeVersions) {
            $latestNode = Get-ChildItem $nodeVersions | Sort-Object Name -Descending | Select-Object -First 1
            if ($latestNode) {
                $nodeBin = "$($latestNode.FullName)"
                if ($env:PATH -notcontains [regex]::Escape($nodeBin)) {
                    $env:PATH = "$nodeBin;$env:PATH"
                }
            }
        }
        return $true
    }
    return $false
}

# 加载 bun 环境
function Initialize-Bun {
    $bunBin = "$env:USERPROFILE\.bun\bin"
    if (Test-Path $bunBin) {
        $env:BUN_INSTALL = "$env:USERPROFILE\.bun"
        if ($env:PATH -notcontains [regex]::Escape($bunBin)) {
            $env:PATH = "$bunBin;$env:PATH"
        }
        return $true
    }
    return $false
}

# ==================== 组件列表 ====================
$Script:COMPONENTS = @(
    @{ Id="1"; Name="Node.js"; Function="Install-NodeJS"; Check="node" }
    @{ Id="2"; Name="Bun"; Function="Install-Bun"; Check="bun" }
    @{ Id="3"; Name="Git"; Function="Install-Git"; Check="git" }
    @{ Id="4"; Name="Python"; Function="Install-Python"; Check="python" }
    @{ Id="5"; Name="nvm"; Function="Install-Nvm"; Check="nvm" }
    @{ Id="6"; Name="coding-helper"; Function="Install-CodingHelper"; Check="chelper" }
)

# 解析组件编号
function Parse-Component {
    param([string]$Id)
    $comp = $Script:COMPONENTS | Where-Object { $_.Id -eq $Id }
    if ($comp) {
        return $comp
    }
    return $null
}

# ==================== 安装函数 ====================

# 安装 nvm (Windows 使用 nvm-windows)
function Install-Nvm {
    Write-ColorOutput "[5/5] 安装 nvm..." "Cyan"

    # 检查是否已安装
    if (Test-Command "nvm") {
        Write-ColorOutput "  ⊙ nvm 已安装" "Yellow"
        return $true
    }

    Write-ColorOutput "  在 Windows 上推荐使用 nvm-windows" "DarkGray"
    Write-ColorOutput "  访问: https://github.com/coreybutler/nvm-windows/releases" "Cyan"
    Write-Host ""

    # 尝试使用 winget 安装
    if (Test-Command "winget") {
        Write-ColorOutput "  使用 winget 安装..." "DarkGray"
        winget install --id CoreyButler.NVMforWindows -e --accept-source-agreements --accept-package-agreements 2>$null | Out-Null

        if (Test-Command "nvm") {
            Write-ColorOutput "  ✓ nvm 安装成功" "Green"
            return $true
        }
    }

    Write-ColorOutput "  ⊙ nvm 安装跳过（请手动安装）" "Yellow"
    return $false
}

# 安装 Node.js
function Install-NodeJS {
    Write-ColorOutput "[1/5] 安装 Node.js..." "Cyan"

    if (Test-Command "node") {
        $version = Get-InstalledVersion "node"
        Write-ColorOutput "  ⊙ Node.js 已安装: $version" "Yellow"
        return $true
    }

    # 尝试使用 nvm 安装
    if (Test-Command "nvm") {
        Write-ColorOutput "  使用 nvm 安装 LTS..." "DarkGray"
        nvm install lts 2>$null | Out-Null
        nvm use lts 2>$null | Out-Null

        if (Test-Command "node") {
            $version = node -v
            Write-ColorOutput "  ✓ Node.js 安装成功: $version" "Green"

            # 配置 npm 镜像
            npm config set registry $NPM_REGISTRY 2>$null | Out-Null
            Write-ColorOutput "  ✓ npm 已配置国内镜像" "DarkGray"
            return $true
        }
    }

    # 尝试使用 winget
    if (Test-Command "winget") {
        Write-ColorOutput "  使用 winget 安装..." "DarkGray"
        winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements 2>$null | Out-Null

        # 刷新环境变量
        $env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

        if (Test-Command "node") {
            $version = node -v
            Write-ColorOutput "  ✓ Node.js 安装成功: $version" "Green"
            npm config set registry $NPM_REGISTRY 2>$null | Out-Null
            return $true
        }
    }

    Write-ColorOutput "  ✗ Node.js 安装失败" "Red"
    return $false
}

# 安装 Bun
function Install-Bun {
    Write-ColorOutput "[2/5] 安装 Bun..." "Cyan"

    if (Test-Command "bun") {
        $version = Get-InstalledVersion "bun"
        Write-ColorOutput "  ⊙ Bun 已安装: $version" "Yellow"
        return $true
    }

    Write-ColorOutput "  使用官方安装脚本..." "DarkGray"

    # 尝试使用 PowerShell 安装脚本
    $installScript = "irm bun.sh/install.ps1|iex"
    try {
        Invoke-Expression -Command $installScript -ErrorAction Stop 2>$null

        # 加载 bun 环境
        Initialize-Bun

        if (Test-Command "bun") {
            $version = bun --version
            Write-ColorOutput "  ✓ Bun 安装成功: $version" "Green"
            return $true
        }
    } catch {
        # 忽略错误
    }

    # 尝试使用 winget
    if (Test-Command "winget") {
        Write-ColorOutput "  使用 winget 安装..." "DarkGray"
        winget install --id Oven-sh.Bun -e --accept-source-agreements --accept-package-agreements 2>$null | Out-Null

        # 刷新环境变量
        $env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

        if (Test-Command "bun") {
            $version = bun --version
            Write-ColorOutput "  ✓ Bun 安装成功: $version" "Green"
            return $true
        }
    }

    Write-ColorOutput "  ⊙ Bun 安装跳过（网络问题）" "Yellow"
    return $false
}

# 安装 Git
function Install-Git {
    Write-ColorOutput "[3/5] 安装 Git..." "Cyan"

    if (Test-Command "git") {
        $version = Get-InstalledVersion "git"
        Write-ColorOutput "  ⊙ Git 已安装: $version" "Yellow"
        return $true
    }

    # 尝试使用 winget
    if (Test-Command "winget") {
        Write-ColorOutput "  使用 winget 安装..." "DarkGray"
        winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements 2>$null | Out-Null

        # 刷新环境变量
        $env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

        if (Test-Command "git") {
            Write-ColorOutput "  ✓ Git 安装成功" "Green"
            return $true
        }
    }

    Write-ColorOutput "  ✗ Git 安装失败" "Red"
    return $false
}

# 安装 Python
function Install-Python {
    Write-ColorOutput "[4/5] 安装 Python..." "Cyan"

    if (Test-Command "python") {
        $version = Get-InstalledVersion "python"
        Write-ColorOutput "  ⊙ Python 已安装: $version" "Yellow"
        return $true
    }

    # 尝试使用 winget
    if (Test-Command "winget") {
        Write-ColorOutput "  使用 winget 安装..." "DarkGray"
        winget install --id Python.Python.3.12 -e --accept-source-agreements --accept-package-agreements 2>$null | Out-Null

        # 刷新环境变量
        $env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

        if (Test-Command "python") {
            Write-ColorOutput "  ✓ Python 安装成功" "Green"
            return $true
        }
    }

    Write-ColorOutput "  ⊙ Python 安装跳过" "Yellow"
    return $false
}

# 安装 coding-helper
function Install-CodingHelper {
    Write-ColorOutput "安装 @z_ai/coding-helper..." "Cyan"

    # 确保 npm 可用
    if (-not (Test-Command "npm")) {
        Write-ColorOutput "  npm 未找到，尝试先安装 Node.js..." "Yellow"
        Install-NodeJS
    }

    if (-not (Test-Command "npm")) {
        Write-ColorOutput "  ✗ 需要先安装 npm" "Red"
        return $false
    }

    # 检查是否已安装
    if (Test-Command "chelper" -or (Test-Command "coding-helper")) {
        Write-ColorOutput "  ⊙ coding-helper 已安装" "Yellow"
        return $true
    }

    Write-ColorOutput "  使用国内镜像安装..." "DarkGray"
    npm install -g @z_ai/coding-helper --registry=$NPM_REGISTRY 2>$null | Out-Null

    if (Test-Command "chelper" -or (Test-Command "coding-helper")) {
        Write-ColorOutput "  ✓ coding-helper 安装成功" "Green"
        return $true
    }

    # 备用：官方源
    Write-ColorOutput "  尝试官方源..." "Yellow"
    npm install -g @z_ai/coding-helper 2>$null | Out-Null

    if (Test-Command "chelper" -or (Test-Command "coding-helper")) {
        Write-ColorOutput "  ✓ coding-helper 安装成功" "Green"
        return $true
    }

    Write-ColorOutput "  ⊙ coding-helper 安装跳过（包不存在或网络问题）" "Yellow"
    return $false
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

    # 显示环境变量
    Write-ColorOutput "环境变量:" "Cyan"
    if ($env:NVM_DIR) {
        Write-Host "  [✓] " -NoNewline -ForegroundColor Green
        Write-Host "NVM_DIR=$env:NVM_DIR" -ForegroundColor White
    } else {
        Write-Host "  [⊙] NVM_DIR 未设置" -ForegroundColor DarkGray
    }
    if ($env:BUN_INSTALL) {
        Write-Host "  [✓] " -NoNewline -ForegroundColor Green
        Write-Host "BUN_INSTALL=$env:BUN_INSTALL" -ForegroundColor White
    } else {
        Write-Host "  [⊙] BUN_INSTALL 未设置" -ForegroundColor DarkGray
    }
    Write-Host ""

    # 显示包管理器
    Write-ColorOutput "包管理器:" "Cyan"
    if (Test-Command "winget") { Write-Host "  [✓] winget" -ForegroundColor Green }
    if (Get-Command "scoop" -ErrorAction SilentlyContinue) { Write-Host "  [✓] scoop" -ForegroundColor Green }
    if (Get-Command "choco" -ErrorAction SilentlyContinue) { Write-Host "  [✓] chocolatey" -ForegroundColor Green }
    Write-Host ""

    Write-Separator
    Write-ColorOutput "快捷命令:" "Cyan"
    Write-Host "  codes install [编号] - 安装组件（可指定编号）" -ForegroundColor DarkGray
    Write-Host "  codes upgrade       - 升级已安装的工具" -ForegroundColor DarkGray
    Write-Host "  codes node <ver>    - 切换 Node.js 版本" -ForegroundColor DarkGray
    Write-Host "  codes helper        - 启动 coding-helper" -ForegroundColor DarkGray
    Write-Host ""
}

# ==================== 组件管理 ====================
function Command-Install {
    param([string]$TargetNum = $null)

    Write-Header
    Write-ColorOutput "       安装组件" "Yellow"
    Write-Separator
    Write-Host ""

    # 加载环境
    Initialize-Nvm | Out-Null
    Initialize-Bun | Out-Null

    # 指定编号安装
    if ($TargetNum) {
        $comp = Parse-Component $TargetNum
        if ($comp) {
            Write-ColorOutput "安装 $($comp.Name)..." "Cyan"
            Write-Host ""
            & $comp.Function
            Write-Host ""
            return
        } else {
            Write-ColorOutput "  ✗ 无效编号: $TargetNum" "Red"
            Write-Host ""
            Write-ColorOutput "可用编号:" "Cyan"
            foreach ($c in $Script:COMPONENTS) {
                Write-Host "  [$($c.Id)] " -NoNewline -ForegroundColor Green
                Write-Host "$($c.Name)"
            }
            Write-Host ""
            Write-ColorOutput "用法: codes install [编号]" "Yellow"
            Write-Host "示例: codes install 1  # 安装 Node.js" -ForegroundColor DarkGray
            Write-Host ""
            return
        }
    }

    # 检查需要安装的组件
    $needInstall = @()

    if (-not (Test-Command "node")) { $needInstall += "1" }
    if (-not (Test-Command "bun")) { $needInstall += "2" }
    if (-not (Test-Command "git")) { $needInstall += "3" }
    if (-not (Test-Command "python")) { $needInstall += "4" }

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
    foreach ($num in $needInstall) {
        $comp = Parse-Component $num
        Write-Host "    [$num] $($comp.Name)"
    }
    Write-Host ""

    $confirm = Read-Host "是否继续? (Y/n)"
    if ($confirm -eq "n" -or $confirm -eq "N") {
        return
    }

    Write-Host ""

    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
    Write-ColorOutput "  基础工具" "Cyan"
    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
    Write-Host ""

    # 安装缺失的组件
    foreach ($num in $needInstall) {
        $comp = Parse-Component $num
        & $comp.Function
        Write-Host ""
    }

    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
    Write-ColorOutput "  AI 工具" "Cyan"
    Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
    Write-Host ""

    Install-CodingHelper
    Write-Host ""
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

    # 环境变量
    Write-ColorOutput "环境变量:" "Cyan"
    $nvmDir = if ($env:NVM_DIR) { $env:NVM_DIR } else { "未设置" }
    $bunInstall = if ($env:BUN_INSTALL) { $env:BUN_INSTALL } else { "未设置" }
    Write-Host "  NVM_DIR=$nvmDir" -ForegroundColor DarkGray
    Write-Host "  BUN_INSTALL=$bunInstall" -ForegroundColor DarkGray
    Write-Host ""

    # npm 配置
    if (Test-Command "npm") {
        Write-ColorOutput "npm 配置:" "Cyan"
        npm config get registry 2>$null | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    }
    Write-Host ""

    # 导出命令
    Write-ColorOutput "环境变量设置（PowerShell）:" "Yellow"
    Write-Host '`$env:NVM_DIR = "$env:USERPROFILE\.nvm"' -ForegroundColor DarkGray
    Write-Host '`$env:BUN_INSTALL = "$env:USERPROFILE\.bun"' -ForegroundColor DarkGray
    Write-Host ""
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
    Write-Host "   │  [4]  Node 管理    - 切换 Node.js 版本" -ForegroundColor Magenta
    Write-Host "   │  [5]  coding-helper - 启动智谱编码助手" -ForegroundColor Cyan
    Write-Host "   │  [6]  环境变量      - 显示/导出环境变量" -ForegroundColor Cyan
    Write-Host "   │" -ForegroundColor Cyan
    Write-Host "   │  [0]  退出" -ForegroundColor Red
    Write-Host "   │" -ForegroundColor Cyan
    Write-Host "   └───────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "提示: 也可以直接运行 'codes <命令>'，如: codes doctor" -ForegroundColor DarkGray
    Write-Host "      'codes install [编号]' 可指定安装组件" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-Help {
    @"
Codes - 开发环境管理工具 v$VERSION

用法:
  codes [命令] [参数]

命令:
  doctor           环境诊断 - 检查所有工具状态
  install [编号]   安装组件 - 安装缺失的工具（可指定编号）
                   编号: 1=Node.js 2=Bun 3=Git 4=Python 5=nvm 6=coding-helper
  upgrade          升级组件 - 升级已安装的工具
  node [ver]       Node 管理 - 切换 Node.js 版本
                   可用: lts, latest, 或具体版本号 (如 20, 22)
  helper [...]     coding-helper - 启动智谱编码助手
  env              环境变量 - 显示/导出环境变量
  menu             显示交互菜单
  --version        显示版本信息
  --help           显示此帮助信息

示例:
  codes doctor              # 诊断环境
  codes install             # 安装缺失组件
  codes install 1           # 只安装 Node.js
  codes node lts            # 切换到 LTS 版本
  codes node 22             # 切换到 v22
  codes helper auth         # 运行 coding-helper auth

安装编号:
  [1] Node.js    [2] Bun    [3] Git    [4] Python
  [5] nvm        [6] coding-helper

"@
}

# ==================== Node 管理 ====================
function Command-Node {
    param([string]$TargetVersion = $null)

    Initialize-Nvm | Out-Null
    Initialize-Bun | Out-Null

    if (-not (Test-Command "nvm")) {
        Write-ColorOutput "  ✗ nvm 未安装" "Red"
        Write-Host ""
        Write-ColorOutput "  运行 'codes install 5' 安装 nvm" "Yellow"
        return $false
    }

    if (-not $TargetVersion) {
        # 显示当前版本和可用版本
        Write-Header
        Write-ColorOutput "       Node.js 版本管理" "Yellow"
        Write-Separator
        Write-Host ""

        if (Test-Command "node") {
            $current = node -v
            Write-ColorOutput "  当前版本: $current" "Green"
        }

        Write-Host ""
        Write-ColorOutput "  已安装版本:" "Cyan"
        nvm list 2>$null | ForEach-Object { Write-Host "    $_" }
        Write-Host ""

        Write-ColorOutput "  常用命令:" "Cyan"
        Write-Host "    codes node lts     - 安装/切换到 LTS" -ForegroundColor DarkGray
        Write-Host "    codes node latest  - 安装/切换到最新版" -ForegroundColor DarkGray
        Write-Host "    codes node 20      - 安装/切换到 v20" -ForegroundColor DarkGray
        Write-Host "    codes node 22      - 安装/切换到 v22" -ForegroundColor DarkGray
        Write-Host ""
        return $true
    }

    # 处理特殊版本名
    switch ($TargetVersion) {
        "lts" {
            Write-ColorOutput "  切换到 LTS 版本..." "Cyan"
            nvm install lts 2>$null | Out-Null
            nvm use lts 2>$null | Out-Null
        }
        "latest" {
            Write-ColorOutput "  切换到最新版本..." "Cyan"
            nvm install latest 2>$null | Out-Null
            nvm use latest 2>$null | Out-Null
        }
        default {
            # 确保版本号以 v 开头
            if (-not $TargetVersion.StartsWith("v")) {
                $TargetVersion = "v$TargetVersion"
            }
            Write-ColorOutput "  切换到 $TargetVersion..." "Cyan"
            nvm install $TargetVersion 2>$null | Out-Null
            nvm use $TargetVersion 2>$null | Out-Null
        }
    }

    Initialize-Nvm | Out-Null

    if (Test-Command "node") {
        Write-ColorOutput "  ✓ 当前版本: $(node -v)" "Green"
        Write-ColorOutput "  ! 请重启终端使更改生效" "Yellow"
    } else {
        Write-ColorOutput "  ✗ 切换失败" "Red"
        return $false
    }
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
    "install" { Command-Install -TargetNum $Args[0] }
    "upgrade" { Command-Upgrade }
    "node" { Command-Node -TargetVersion $Args[0] }
    "helper" { Command-Helper $Args }
    "env" { Command-Env }
    "menu" {
        Show-Menu
        $choice = Read-Host "请选择"

        switch ($choice) {
            "1" { Command-Doctor }
            "2" { Command-Install }
            "3" { Command-Upgrade }
            "4" { Command-Node }
            "5" { Command-Helper }
            "6" { Command-Env }
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
