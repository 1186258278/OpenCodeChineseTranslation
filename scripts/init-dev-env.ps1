# ========================================
# 开发环境一键初始化脚本 v1.0
# 全平台支持: Windows / Linux / macOS
# ========================================

param(
    [switch]$Quiet = $false,
    [switch]$SkipAI = $false,
    [switch]$SkipDocker = $false
)

# 颜色输出函数
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
    Write-Host "║     开发环境一键初始化脚本 v1.0                             ║" -ForegroundColor Cyan
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
        $version = & $Command --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            return "$version".Trim()
        }
    } catch {}
    return $null
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
    # 检测可用的包管理器
    if (Test-Command "winget") {
        return "winget"
    }
    if (Get-Command "scoop" -ErrorAction SilentlyContinue) {
        return "scoop"
    }
    if (Get-Command "choco" -ErrorAction SilentlyContinue) {
        return "choco"
    }
    return $null
}

function Install-PackageManagerIfNeeded {
    Write-ColorOutput Cyan "检查包管理器..."

    $pm = Get-PackageManager
    if ($pm) {
        Write-ColorOutput Green "  ✓ 检测到包管理器: $pm"
        return $pm
    }

    Write-ColorOutput Yellow "  ! 未检测到包管理器"
    Write-Host ""
    Write-Host "正在安装 winget..." -ForegroundColor Cyan

    try {
        # 尝试从 GitHub 安装 winget
        $wingetUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        Write-ColorOutput DarkGray "  下载地址: $wingetUrl"
        Write-ColorOutput Yellow "  请手动访问并安装 winget，或安装 Scoop:"
        Write-Host ""
        Write-Host "    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor White
        Write-Host "    irm get.scoop.sh | iex" -ForegroundColor White
        Write-Host ""
    } catch {
        Write-ColorOutput Red "  自动安装失败，请手动安装包管理器"
    }

    return $null
}

# ==================== 组件安装 ====================
function Install-NodeJS {
    Write-ColorOutput Cyan "安装 Node.js..."

    $pm = Get-PackageManager
    $hasNode = Test-Command "node"

    if ($hasNode) {
        $version = Get-InstalledVersion "node"
        Write-ColorOutput Green "  ✓ Node.js 已安装: $version"

        # 检查是否需要升级
        Write-ColorOutput Yellow "  ? 是否升级到最新版本？(y/N)"
        if ($Quiet -or $Host.UI.RawUI.KeyAvailable) {
            $answer = "n"
        } else {
            $answer = Read-Host
        }
        if ($answer -eq "y" -or $answer -eq "Y") {
            switch ($pm) {
                "winget" { winget upgrade OpenJS.NodeJS }
                "scoop" { scoop upgrade nodejs }
                "choco" { choco upgrade nodejs }
            }
        }
        return
    }

    switch ($pm) {
        "winget" {
            winget install OpenJS.NodeJS --accept-package-agreements --accept-source-agreements
        }
        "scoop" {
            scoop install nodejs
        }
        "choco" {
            choco install nodejs -y
        }
        default {
            Write-ColorOutput Yellow "  手动安装: https://nodejs.org/"
        }
    }

    if (Test-Command "node") {
        Write-ColorOutput Green "  ✓ Node.js 安装成功"
    }
}

function Install-Bun {
    Write-ColorOutput Cyan "安装 Bun..."

    $hasBun = Test-Command "bun"

    if ($hasBun) {
        $version = Get-InstalledVersion "bun"
        Write-ColorOutput Green "  ✓ Bun 已安装: $version"
        return
    }

    # Bun 提供了跨平台安装脚本
    Write-ColorOutput DarkGray "  使用官方安装脚本..."
    try {
        irm bun.sh/install.ps1 | iex
        if (Test-Command "bun") {
            Write-ColorOutput Green "  ✓ Bun 安装成功"
        }
    } catch {
        Write-ColorOutput Red "  ✗ Bun 安装失败: $_"
    }
}

function Install-Git {
    Write-ColorOutput Cyan "安装 Git..."

    $hasGit = Test-Command "git"

    if ($hasGit) {
        $version = Get-InstalledVersion "git"
        Write-ColorOutput Green "  ✓ Git 已安装: $version"
        return
    }

    $pm = Get-PackageManager
    switch ($pm) {
        "winget" {
            winget install Git.Git --accept-package-agreements --accept-source-agreements
        }
        "scoop" {
            scoop install git
        }
        "choco" {
            choco install git -y
        }
    }
}

function Install-Docker {
    Write-ColorOutput Cyan "安装 Docker..."

    $hasDocker = Test-Command "docker"

    if ($hasDocker) {
        $version = Get-InstalledVersion "docker"
        Write-ColorOutput Green "  ✓ Docker 已安装: $version"
        return
    }

    $pm = Get-PackageManager
    Write-ColorOutput Yellow "  Docker Desktop 需要手动安装或重启后生效"
    switch ($pm) {
        "winget" {
            winget install Docker.DockerDesktop --accept-package-agreements --accept-source-agreements
        }
        "scoop" {
            scoop install docker
        }
        "choco" {
            choco install docker-desktop -y
        }
    }
}

function Install-Python {
    Write-ColorOutput Cyan "安装 Python..."

    $hasPython = Test-Command "python"

    if ($hasPython) {
        $version = Get-InstalledVersion "python"
        Write-ColorOutput Green "  ✓ Python 已安装: $version"
        return
    }

    $pm = Get-PackageManager
    switch ($pm) {
        "winget" {
            winget install Python.Python.3.12 --accept-package-agreements --accept-source-agreements
        }
        "scoop" {
            scoop install python
        }
        "choco" {
            choco install python -y
        }
    }
}

# ==================== AI 工具安装 ====================
function Install-CodingHelper {
    Write-ColorOutput Cyan "安装 @z_ai/coding-helper..."

    $hasHelper = Test-Command "chelper"
    $hasNpm = Test-Command "npm"

    if (!$hasNpm) {
        Write-ColorOutput Red "  ✗ 需要先安装 npm"
        return
    }

    if ($hasHelper) {
        $version = npm list -g @z_ai/coding-helper 2>&1
        Write-ColorOutput Green "  ✓ coding-helper 已安装"
        Write-ColorOutput Yellow "  ? 是否升级？(y/N)"
        $answer = if ($Quiet) { "n" } else { Read-Host }
        if ($answer -eq "y" -or $answer -eq "Y") {
            npm install -g @z_ai/coding-helper
            Write-ColorOutput Green "  ✓ 升级完成"
        }
        return
    }

    Write-Host "  正在安装..." -ForegroundColor DarkGray
    npm install -g @z_ai/coding-helper

    if (Test-Command "chelper") {
        Write-ColorOutput Green "  ✓ coding-helper 安装成功"
        Write-Host "  运行命令: chelper 或 coding-helper" -ForegroundColor DarkGray
    }
}

function Install-OpenCodeChinese {
    Write-ColorOutput Cyan "安装 OpenCode 中文汉化版..."

    $hasGit = Test-Command "git"
    if (!$hasGit) {
        Write-ColorOutput Red "  ✗ 需要先安装 Git"
        return
    }

    $cloneDir = "$HOME\OpenCodeChineseTranslation"

    if (Test-Path $cloneDir) {
        Write-ColorOutput Yellow "  ! 目录已存在: $cloneDir"
        Write-ColorOutput Yellow "  ? 是否重新克隆？(y/N)"
        $answer = if ($Quiet) { "n" } else { Read-Host }
        if ($answer -ne "y" -and $answer -ne "Y") {
            Write-ColorOutput DarkGray "  跳过，使用现有目录"
            Push-Location $cloneDir
        } else {
            Remove-Item $cloneDir -Recurse -Force
            git clone https://github.com/1186258278/OpenCodeChineseTranslation.git $cloneDir
            Push-Location $cloneDir
        }
    } else {
        git clone https://github.com/1186258278/OpenCodeChineseTranslation.git $cloneDir
        Push-Location $cloneDir
    }

    Write-Host ""
    Write-Host "  正在初始化汉化版..." -ForegroundColor DarkGray

    # 运行初始化和汉化
    if (Test-Path ".\scripts\init.ps1") {
        & .\scripts\init.ps1
        Write-Host ""
        Write-ColorOutput Green "  ✓ OpenCode 汉化版初始化完成"
        Write-Host "  下一步: 运行 .\scripts\opencode.ps1 开始汉化" -ForegroundColor DarkGray
    } else {
        Write-ColorOutput Yellow "  ! 脚本未找到，请手动初始化"
    }

    Pop-Location
}

function Install-ClaudeCode {
    Write-ColorOutput Cyan "安装 Claude Code..."

    $hasNpm = Test-Command "npm"

    if (!$hasNpm) {
        Write-ColorOutput Red "  ✗ 需要先安装 npm"
        return
    }

    $hasClaude = Test-Command "claude"

    if ($hasClaude) {
        Write-ColorOutput Green "  ✓ Claude Code 已安装"
        return
    }

    npm install -g @anthropic-ai/claude-code

    if (Test-Command "claude") {
        Write-ColorOutput Green "  ✓ Claude Code 安装成功"
    }
}

# ==================== 主菜单 ====================
function Show-Menu {
    Write-Header
    Show-SystemStatus

    Write-Host "   ┌─── 安装模式 ─────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "   │" -ForegroundColor Cyan
    Write-Host "   │  [1]  一键安装全部 (推荐)" -ForegroundColor Green
    Write-Host "   │  [2]  仅安装基础工具 (Node.js, Bun, Git, Docker)" -ForegroundColor Yellow
    Write-Host "   │  [3]  仅安装 AI 工具" -ForegroundColor Magenta
    Write-Host "   │  [4]  自定义选择" -ForegroundColor White
    Write-Host "   │  [5]  检查更新" -ForegroundColor Cyan
    Write-Host "   │" -ForegroundColor Cyan
    Write-Host "   │  [0]  退出" -ForegroundColor Red
    Write-Host "   │" -ForegroundColor Cyan
    Write-Host "   └───────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
}

function Install-All {
    Write-Header
    Write-ColorOutput Yellow "       一键安装全部组件"
    Write-Separator
    Write-Host ""

    # 1. 安装包管理器
    Install-PackageManagerIfNeeded
    Write-Host ""

    # 2. 安装基础工具
    Write-ColorOutput Cyan "[1/3] 安装基础工具..."
    Write-Host ""
    Install-NodeJS
    Write-Host ""
    Install-Bun
    Write-Host ""
    Install-Git
    Write-Host ""
    if (!$SkipDocker) {
        Install-Docker
        Write-Host ""
    }
    Install-Python
    Write-Host ""

    # 3. 安装 AI 工具
    if (!$SkipAI) {
        Write-ColorOutput Cyan "[2/3] 安装 AI 工具..."
        Write-Host ""
        Install-CodingHelper
        Write-Host ""

        Write-Host "选择要安装的 AI 编程工具:" -ForegroundColor Yellow
        Write-Host "  [1] OpenCode 中文汉化版" -ForegroundColor Green
        Write-Host "  [2] Claude Code" -ForegroundColor Cyan
        Write-Host "  [3] 都不安装" -ForegroundColor DarkGray
        Write-Host ""
        $aiChoice = if ($Quiet) { "3" } else { Read-Host "请选择" }

        switch ($aiChoice) {
            "1" { Install-OpenCodeChinese }
            "2" { Install-ClaudeCode }
        }
        Write-Host ""
    }

    # 4. 完成
    Write-ColorOutput Cyan "[3/3] 安装完成"
    Write-Separator
    Write-Host ""
    Write-ColorOutput Green "╔════════════════════════════════════════════════════════════╗"
    Write-ColorOutput Green "║          开发环境初始化完成！                               ║"
    Write-ColorOutput Green "╚════════════════════════════════════════════════════════════╝"
    Write-Host ""
    Write-ColorOutput Cyan "下一步:"
    Write-Host "  - coding-helper 或 chelper 启动智谱助手" -ForegroundColor White
    Write-Host "  - 查看已安装工具版本，运行脚本并选择 [5]" -ForegroundColor White
    Write-Host ""
}

function Install-BasicTools {
    Write-Header
    Write-ColorOutput Yellow "       安装基础工具"
    Write-Separator
    Write-Host ""

    Install-PackageManagerIfNeeded
    Write-Host ""

    Install-NodeJS
    Write-Host ""
    Install-Bun
    Write-Host ""
    Install-Git
    Write-Host ""
    if (!$SkipDocker) {
        Install-Docker
        Write-Host ""
    }
    Install-Python
    Write-Host ""

    Write-ColorOutput Green "基础工具安装完成！"
    Write-Host ""
}

function Install-AITools {
    Write-Header
    Write-ColorOutput Yellow "       安装 AI 工具"
    Write-Separator
    Write-Host ""

    Install-CodingHelper
    Write-Host ""

    Write-Host "选择要安装的 AI 编程工具:" -ForegroundColor Yellow
    Write-Host "  [1] OpenCode 中文汉化版" -ForegroundColor Green
    Write-Host "  [2] Claude Code" -ForegroundColor Cyan
    Write-Host "  [3] 两者都安装" -ForegroundColor White
    Write-Host "  [0] 返回" -ForegroundColor DarkGray
    Write-Host ""
    $aiChoice = Read-Host "请选择"

    switch ($aiChoice) {
        "1" { Install-OpenCodeChinese }
        "2" { Install-ClaudeCode }
        "3" {
            Install-OpenCodeChinese
            Write-Host ""
            Install-ClaudeCode
        }
    }

    Write-Host ""
    Write-ColorOutput Green "AI 工具安装完成！"
    Write-Host ""
}

function Check-Updates {
    Write-Header
    Write-ColorOutput Yellow "       检查更新"
    Write-Separator
    Write-Host ""

    Write-ColorOutput Cyan "检查可更新的组件..."
    Write-Host ""

    $tools = @{
        "Node.js" = "node"
        "Bun" = "bun"
        "npm" = "npm"
        "@z_ai/coding-helper" = "chelper"
    }

    $updates = @()
    foreach ($tool in $tools.GetEnumerator()) {
        $name = $tool.Key
        $cmd = $tool.Value
        if (Test-Command $cmd) {
            $version = Get-InstalledVersion $cmd
            Write-Host "  [$name] 当前: $version" -ForegroundColor DarkGray
            # TODO: 添加实际版本检查逻辑
        }
    }

    Write-Host ""
    Write-ColorOutput Yellow "提示: 使用各包管理器的 upgrade 命令更新"
    Write-Host "  npm update -g @z_ai/coding-helper" -ForegroundColor DarkGray
    Write-Host "  bun upgrade" -ForegroundColor DarkGray
    Write-Host ""
}

function Custom-Install {
    Write-Header
    Write-ColorOutput Yellow "       自定义安装"
    Write-Separator
    Write-Host ""

    Write-Host "选择要安装的组件 (空格选择，回车确认):" -ForegroundColor Cyan
    Write-Host ""

    $choices = @(
        "Node.js + npm",
        "Bun",
        "Git",
        "Docker",
        "Python",
        "@z_ai/coding-helper",
        "OpenCode 汉化版",
        "Claude Code"
    )

    for ($i = 0; $i -lt $choices.Count; $i++) {
        Write-Host "  [$($i+1)] $($choices[$i])"
    }
    Write-Host ""
    Write-Host "输入编号 (如: 1 3 5):" -ForegroundColor Yellow

    $selection = Read-Host
    $selected = $selection -split '\s+' | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_-1 }

    Write-Host ""

    foreach ($idx in $selected) {
        if ($idx -ge 0 -and $idx -lt $choices.Count) {
            switch ($idx) {
                0 { Install-NodeJS }
                1 { Install-Bun }
                2 { Install-Git }
                3 { Install-Docker }
                4 { Install-Python }
                5 { Install-CodingHelper }
                6 { Install-OpenCodeChinese }
                7 { Install-ClaudeCode }
            }
            Write-Host ""
        }
    }

    Write-ColorOutput Green "自定义安装完成！"
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
        "4" { Custom-Install }
        "5" { Check-Updates }
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
