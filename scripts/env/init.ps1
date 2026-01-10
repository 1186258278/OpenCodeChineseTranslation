# ========================================
# 开发环境一键初始化脚本 v1.4
# 平台: Windows PowerShell
# 特性: 智能检测 + 多备用方案 + 全自动
# ========================================

param(
    [switch]$Quiet = $false,
    [switch]$SkipAI = $false,
    [switch]$SkipDocker = $false
)

# 安装结果跟踪
$Script:INSTALL_SUCCESS = @()
$Script:INSTALL_FAILED = @()
$Script:INSTALL_SKIPPED = @()

# 国内镜像配置
$Script:NPM_REGISTRY = "https://registry.npmmirror.com"

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
    Write-Host "║     开发环境一键初始化脚本 v1.3                             ║" -ForegroundColor Cyan
    Write-Host "║     智能检测 + 多备用方案 + 全自动                           ║" -ForegroundColor Cyan
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

# 记录安装结果
function Add-Success {
    param([string]$Item)
    $Script:INSTALL_SUCCESS += $Item
}

function Add-Failed {
    param([string]$Item, [string]$Reason)
    $Script:INSTALL_FAILED += "$Item`: $Reason"
}

function Add-Skipped {
    param([string]$Item)
    $Script:INSTALL_SKIPPED += $Item
}

# 打印安装汇总报告
function Show-Summary {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    安装汇总报告                             ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    # 成功列表
    if ($Script:INSTALL_SUCCESS.Count -gt 0) {
        Write-Host "✓ 安装成功 ($($Script:INSTALL_SUCCESS.Count)):" -ForegroundColor Green
        foreach ($item in $Script:INSTALL_SUCCESS) {
            Write-Host "  ✔ $item" -ForegroundColor Green
        }
        Write-Host ""
    }

    # 跳过列表
    if ($Script:INSTALL_SKIPPED.Count -gt 0) {
        Write-Host "⊙ 已安装，跳过 ($($Script:INSTALL_SKIPPED.Count)):" -ForegroundColor Yellow
        foreach ($item in $Script:INSTALL_SKIPPED) {
            Write-Host "  ⊙ $item" -ForegroundColor Yellow
        }
        Write-Host ""
    }

    # 失败列表
    if ($Script:INSTALL_FAILED.Count -gt 0) {
        Write-Host "✗ 安装失败 ($($Script:INSTALL_FAILED.Count)):" -ForegroundColor Red
        foreach ($item in $Script:INSTALL_FAILED) {
            Write-Host "  ✗ $item" -ForegroundColor Red
        }
        Write-Host ""
    }

    # 统计
    $total = $Script:INSTALL_SUCCESS.Count + $Script:INSTALL_FAILED.Count + $Script:INSTALL_SKIPPED.Count
    $successRate = if ($total -gt 0) { [math]::Floor(100 * $Script:INSTALL_SUCCESS.Count / $total) } else { 0 }

    Write-Separator
    Write-Host "  总计: $total | 成功: $($Script:INSTALL_SUCCESS.Count) | 跳过: $($Script:INSTALL_SKIPPED.Count) | 失败: $($Script:INSTALL_FAILED.Count) | 成功率: $successRate%" -ForegroundColor White
    Write-Separator
    Write-Host ""

    # 环境变量提示
    if ($Script:INSTALL_SUCCESS.Count -gt 0) {
        Write-Host "! 请重启终端使环境变量生效" -ForegroundColor Yellow
        Write-Host ""
    }

    # 命令验证
    if ($Script:INSTALL_SUCCESS.Count -gt 0) {
        Write-Host "已安装命令验证:" -ForegroundColor Cyan
        if (Test-Command "node") { Write-Host "  ✔ node $(Get-InstalledVersion 'node')" -ForegroundColor Green }
        if (Test-Command "npm") { Write-Host "  ✔ npm $(Get-InstalledVersion 'npm')" -ForegroundColor Green }
        if (Test-Command "bun") { Write-Host "  ✔ bun $(Get-InstalledVersion 'bun')" -ForegroundColor Green }
        if (Test-Command "git") { Write-Host "  ✔ git $(Get-InstalledVersion 'git')" -ForegroundColor Green }
        if (Test-Command "python") { Write-Host "  ✔ python $(Get-InstalledVersion 'python')" -ForegroundColor Green }
        if (Test-Command "chelper") { Write-Host "  ✔ coding-helper" -ForegroundColor Green }
        Write-Host ""
    }
}

# ==================== 系统检测 ====================
function Show-SystemStatus {
    Write-ColorOutput Cyan "  系统环境检测"
    Write-Separator

    $tools = @{
        "Node.js" = "node"
        "npm" = "npm"
        "Bun" = "bun"
        "Git" = "git"
        "Docker" = "docker"
        "Python" = "python"
        "coding-helper" = "chelper"
    }

    foreach ($tool in $tools.GetEnumerator()) {
        $name = $tool.Key
        $cmd = $tool.Value
        $installed = Test-Command $cmd
        $version = if ($installed) { Get-InstalledVersion $cmd } else { "未安装" }

        if ($installed) {
            Write-Host "  [$name] " -NoNewline
            Write-Host "✓" -ForegroundColor Green -NoNewline
            Write-Host " $version"
        } else {
            Write-Host "  [$name] " -NoNewline
            Write-Host "✗" -ForegroundColor Red -NoNewline
            Write-Host " 未安装"
        }
    }
    Write-Separator
    Write-Host ""
}

# ==================== 包管理器检测 ====================
function Get-PackageManager {
    if (Test-Command "winget") { return "winget" }
    if (Get-Command "scoop" -ErrorAction SilentlyContinue) { return "scoop" }
    if (Get-Command "choco" -ErrorAction SilentlyContinue) { return "choco" }
    return $null
}

# ==================== 组件安装 ====================
function Install-NodeJS {
    Write-ColorOutput Cyan "[1/4] 安装 Node.js..."

    if (Test-Command "node") {
        $version = Get-InstalledVersion "node"
        Write-ColorOutput Yellow "  ⊙ Node.js 已安装: $version"
        Add-Skipped "Node.js ($version)"
        return
    }

    $pm = Get-PackageManager
    $installed = $false

    switch ($pm) {
        "winget" {
            winget install OpenJS.NodeJS --accept-package-agreements --accept-source-agreements -h 2>$null
            $installed = $?
        }
        "scoop" {
            scoop install nodejs 2>$null
            $installed = $?
        }
        "choco" {
            choco install nodejs -y 2>$null
            $installed = $?
        }
    }

    if (Test-Command "node") {
        $version = Get-InstalledVersion "node"
        Write-ColorOutput Green "  ✓ Node.js 安装成功: $version"
        Add-Success "Node.js ($version)"

        # 配置 npm 国内镜像
        npm config set registry $Script:NPM_REGISTRY 2>$null
        Write-ColorOutput DarkGray "  ✓ npm 已配置国内镜像"
    } else {
        Write-ColorOutput Red "  ✗ Node.js 安装失败"
        Write-ColorOutput Yellow "  请手动安装: https://nodejs.org/"
        Add-Failed "Node.js" "请手动下载安装"
    }
}

function Install-Bun {
    Write-ColorOutput Cyan "[2/4] 安装 Bun..."

    if (Test-Command "bun") {
        $version = Get-InstalledVersion "bun"
        Write-ColorOutput Yellow "  ⊙ Bun 已安装: $version"
        Add-Skipped "Bun ($version)"
        return
    }

    Write-ColorOutput DarkGray "  使用官方安装脚本..."
    try {
        irm bun.sh/install.ps1 | iex 2>$null
        if (Test-Command "bun") {
            $version = Get-InstalledVersion "bun"
            Write-ColorOutput Green "  ✓ Bun 安装成功: $version"
            Add-Success "Bun ($version)"
            return
        }
    } catch {}

    # 备用：使用 npm 安装
    if (Test-Command "npm") {
        Write-ColorOutput Yellow "  尝试使用 npm 安装..."
        npm install -g bun 2>$null
        if (Test-Command "bun") {
            $version = Get-InstalledVersion "bun"
            Write-ColorOutput Green "  ✓ Bun 安装成功 (通过 npm): $version"
            Add-Success "Bun (via npm, $version)"
            return
        }
    }

    Write-ColorOutput Yellow "  ⊙ Bun 安装跳过（网络问题）"
    Write-ColorOutput DarkGray "  请手动安装: https://bun.sh/docs/installation"
    Add-Failed "Bun" "网络连接失败"
}

function Install-Git {
    Write-ColorOutput Cyan "[3/4] 安装 Git..."

    if (Test-Command "git") {
        $version = Get-InstalledVersion "git"
        Write-ColorOutput Yellow "  ⊙ Git 已安装: $version"
        Add-Skipped "Git ($version)"
        return
    }

    $pm = Get-PackageManager
    switch ($pm) {
        "winget" {
            winget install Git.Git --accept-package-agreements --accept-source-agreements -h 2>$null
        }
        "scoop" {
            scoop install git 2>$null
        }
        "choco" {
            choco install git -y 2>$null
        }
    }

    if (Test-Command "git") {
        Write-ColorOutput Green "  ✓ Git 安装成功"
        Add-Success "Git"
    } else {
        Write-ColorOutput Red "  ✗ Git 安装失败"
        Add-Failed "Git" "请手动安装"
    }
}

function Install-Python {
    Write-ColorOutput Cyan "[4/4] 安装 Python..."

    if (Test-Command "python") {
        $version = Get-InstalledVersion "python"
        Write-ColorOutput Yellow "  ⊙ Python 已安装: $version"
        Add-Skipped "Python ($version)"
        return
    }

    $pm = Get-PackageManager
    switch ($pm) {
        "winget" {
            winget install Python.Python.3.12 --accept-package-agreements --accept-source-agreements -h 2>$null
        }
        "scoop" {
            scoop install python 2>$null
        }
        "choco" {
            choco install python -y 2>$null
        }
    }

    if (Test-Command "python") {
        Write-ColorOutput Green "  ✓ Python 安装成功"
        Add-Success "Python"
    } else {
        Write-ColorOutput Red "  ✗ Python 安装失败"
        Add-Failed "Python" "请手动安装"
    }
}

function Install-CodingHelper {
    Write-ColorOutput Cyan "安装 @z_ai/coding-helper..."

    if (!(Test-Command "npm")) {
        Write-ColorOutput Yellow "  npm 未找到，尝试先安装 Node.js..."
        Install-NodeJS
    }

    if (!(Test-Command "npm")) {
        Write-ColorOutput Red "  ✗ 需要先安装 npm"
        Add-Failed "coding-helper" "npm 未安装"
        return
    }

    if (Test-Command "chelper") {
        Write-ColorOutput Yellow "  ⊙ coding-helper 已安装"
        Add-Skipped "coding-helper"
        return
    }

    Write-ColorOutput DarkGray "  使用国内镜像安装..."
    npm install -g @z_ai/coding-helper --registry=$Script:NPM_REGISTRY 2>$null

    if (Test-Command "chelper") {
        Write-ColorOutput Green "  ✓ coding-helper 安装成功"
        Add-Success "coding-helper"
        return
    }

    # 备用：官方源
    Write-ColorOutput Yellow "  尝试官方源..."
    npm install -g @z_ai/coding-helper 2>$null
    if (Test-Command "chelper") {
        Write-ColorOutput Green "  ✓ coding-helper 安装成功"
        Add-Success "coding-helper"
        return
    }

    Write-ColorOutput Red "  ✗ coding-helper 安装失败"
    Add-Failed "coding-helper" "包不存在或网络问题"
}

# ==================== 主安装流程 ====================
function Install-All {
    Write-Header
    Write-ColorOutput Yellow "       一键安装全部组件"
    Write-Separator
    Write-Host ""

    # 安装基础工具
    Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-ColorOutput Cyan "  第一阶段: 基础工具"
    Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host ""

    Install-NodeJS
    Write-Host ""
    Install-Bun
    Write-Host ""
    Install-Git
    Write-Host ""
    Install-Python
    Write-Host ""

    # 安装 AI 工具
    if (!$SkipAI) {
        Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        Write-ColorOutput Cyan "  第二阶段: AI 工具"
        Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        Write-Host ""

        Install-CodingHelper
        Write-Host ""
    }

    # 显示汇总报告
    Show-Summary

    # 安装 codes 命令
    Install-Codes
}

# ==================== 安装 Codes ====================
function Install-Codes {
    Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-ColorOutput Cyan "  安装 Codes 管理工具"
    Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host ""

    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $installDir = "$env:USERPROFILE\.codes"
    $binDir = "$installDir\bin"

    # 创建目录
    if (-not (Test-Path $binDir)) {
        New-Item -ItemType Directory -Path $binDir -Force | Out-Null
    }

    # 复制脚本
    if (Test-Path "$scriptDir\codes.ps1") {
        Copy-Item "$scriptDir\codes.ps1" "$binDir\codes.ps1" -Force

        # 创建 bat wrapper
        $batContent = @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "$binDir\codes.ps1" %*
"@
        $batContent | Out-File "$binDir\codes.bat" -Encoding ASCII

        # 添加到 PATH
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($currentPath -notlike "*$binDir*") {
            [Environment]::SetEnvironmentVariable("Path", $currentPath + ";$binDir", "User")
            Write-ColorOutput "  ✓ codes 已安装到 $installDir" "Green"
            Write-ColorOutput "  ! 已添加到用户 PATH，请重启终端生效" "Yellow"
        } else {
            Write-ColorOutput "  ✓ codes 已安装到 $installDir" "Green"
        }
        Write-Host ""
    } else {
        Write-ColorOutput "  ⊙ codes.ps1 不存在，跳过安装" "Yellow"
        Write-Host ""
    }
}

function Install-BasicTools {
    Write-Header
    Write-ColorOutput Yellow "       安装基础工具"
    Write-Separator
    Write-Host ""

    Install-NodeJS
    Write-Host ""
    Install-Bun
    Write-Host ""
    Install-Git
    Write-Host ""
    Install-Python
    Write-Host ""

    Show-Summary
}

function Install-AITools {
    Write-Header
    Write-ColorOutput Yellow "       安装 AI 工具"
    Write-Separator
    Write-Host ""

    Install-CodingHelper
    Write-Host ""

    Show-Summary
}

# ==================== 主菜单 ====================
function Show-Menu {
    Write-Header
    Show-SystemStatus

    Write-Host "   ┌─── 安装模式 ─────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "   │" -ForegroundColor Cyan
    Write-Host "   │  [1]  一键安装全部 (推荐)" -ForegroundColor Green
    Write-Host "   │  [2]  仅安装基础工具 (Node.js, Bun, Git, Python)" -ForegroundColor Yellow
    Write-Host "   │  [3]  仅安装 AI 工具" -ForegroundColor Magenta
    Write-Host "   │  [4]  检查更新" -ForegroundColor Cyan
    Write-Host "   │" -ForegroundColor Cyan
    Write-Host "   │  [0]  退出" -ForegroundColor Red
    Write-Host "   │" -ForegroundColor Cyan
    Write-Host "   └───────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
}

function Check-Updates {
    Write-Header
    Write-ColorOutput Yellow "       检查更新"
    Write-Separator
    Write-Host ""

    Write-ColorOutput Cyan "已安装组件版本:"
    Write-Host ""

    $tools = @{
        "Node.js" = "node"
        "Bun" = "bun"
        "npm" = "npm"
        "Git" = "git"
        "Python" = "python"
    }

    foreach ($tool in $tools.GetEnumerator()) {
        $name = $tool.Key
        $cmd = $tool.Value
        if (Test-Command $cmd) {
            $version = Get-InstalledVersion $cmd
            Write-Host "  [$name] $version"
        }
    }

    Write-Host ""
    Write-ColorOutput Yellow "更新命令:"
    Write-Host "  winget upgrade --id OpenJS.NodeJS" -ForegroundColor DarkGray
    Write-Host "  bun upgrade" -ForegroundColor DarkGray
    Write-Host "  npm update -g @z_ai/coding-helper" -ForegroundColor DarkGray
    Write-Host ""
}

# ==================== 主循环 ====================
if ($Quiet) {
    Install-All
    exit
}

do {
    Show-Menu
    $choice = Read-Host "请选择"

    switch ($choice) {
        "1" { Install-All }
        "2" { Install-BasicTools }
        "3" { Install-AITools }
        "4" { Check-Updates }
        "0" {
            Write-ColorOutput DarkGray "再见！"
            exit
        }
        default {
            Write-ColorOutput Red "无效选择"
            Start-Sleep -Milliseconds 500
        }
    }

    if ($choice -ne "0") {
        Write-Host ""
        Read-Host "按回车键继续"
    }
} while ($choice -ne "0")
