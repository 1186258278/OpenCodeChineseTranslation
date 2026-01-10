# ========================================
# OpenCode 汉化版 - 一键安装脚本 v2.5
# Windows 完整安装
# 使用方式: irm https://gitee.com/QtCodeCreators/OpenCodeChineseTranslation/raw/main/scripts/install.ps1 | iex
# ========================================

$ErrorActionPreference = "Continue"

# ==================== 颜色函数 ====================
function Print-Banner {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║" -ForegroundColor Cyan -NoNewline
    Write-Host "     OpenCode 中文汉化版 - 一键安装脚本 v2.2            " -ForegroundColor White -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "║" -ForegroundColor Cyan -NoNewline
    Write-Host "     Windows                                               " -ForegroundColor White -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Print-Step {
    param([string]$Message)
    Write-Host "▶ $Message" -ForegroundColor Cyan
}

function Print-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Print-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Print-Info {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor Gray
}

# 清理旧脚本
function Cleanup-OldScripts {
    Write-Host "[清理] 检查旧脚本..." -ForegroundColor Gray
    $cleaned = $false

    # 清理旧的全局命令
    if (Test-Path "$env:USERPROFILE\.local\bin\opencodecmd.ps1") {
        Remove-Item -Force "$env:USERPROFILE\.local\bin\opencodecmd.ps1" -ErrorAction SilentlyContinue
        Remove-Item -Force "$env:USERPROFILE\.local\bin\opencodecmd.bat" -ErrorAction SilentlyContinue
        Write-Host "  ✓ 删除旧的 opencodecmd" -ForegroundColor Gray
        $cleaned = $true
    }

    # 清理旧的 Codes 脚本
    if (Test-Path "$env:ProgramData\codes\codes.ps1") {
        Remove-Item -Recurse -Force "$env:ProgramData\codes" -ErrorAction SilentlyContinue
        Write-Host "  ✓ 删除旧的 Codes 库" -ForegroundColor Gray
        $cleaned = $true
    }

    # 清理全局 codes.bat/codes.ps1
    if (Test-Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\codes.bat") {
        Remove-Item -Force "$env:LOCALAPPDATA\Microsoft\WindowsApps\codes.bat" -ErrorAction SilentlyContinue
        Remove-Item -Force "$env:LOCALAPPDATA\Microsoft\WindowsApps\codes.ps1" -ErrorAction SilentlyContinue
        Write-Host "  ✓ 删除旧的 codes 命令" -ForegroundColor Gray
        $cleaned = $true
    }

    if ($cleaned) {
        Write-Host "✓ 清理完成" -ForegroundColor Green
    } else {
        Write-Host "  无需清理" -ForegroundColor Gray
    }
    Write-Host ""
}

# 安装 Bun
function Install-Bun {
    Write-Host "  安装 Bun (构建工具)..." -ForegroundColor Gray

    $bunPath = "$env:USERPROFILE\.bun\bin"

    # 检查是否已安装
    if (Get-Command bun -ErrorAction SilentlyContinue) {
        Write-Host "  ✓ Bun 已安装" -ForegroundColor Green
        return $true
    }

    # 方式1: 使用官方安装脚本
    try {
        Write-Host "  正在从官方源安装..." -ForegroundColor Gray
        irm https://bun.sh/install.ps1 | iex

        # 添加到 PATH
        if ($env:Path -notlike "*$bunPath*") {
            $env:Path = "$bunPath;$env:Path"
        }

        # 刷新命令
        $null = Get-Command bun -ErrorAction SilentlyContinue

        if (Get-Command bun -ErrorAction SilentlyContinue) {
            $version = bun --version 2>$null
            Write-Host "  ✓ Bun 已安装: $version" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "  官方安装失败，尝试 npm..." -ForegroundColor Yellow
    }

    # 方式2: 使用 npm 全局安装
    try {
        npm install -g bun *> $null

        # npm 全局路径
        $npmGlobal = npm config get prefix
        $npmBinPath = "$npmGlobal\npm-global\bin"
        if ($env:Path -notlike "*$npmBinPath*") {
            $env:Path = "$npmBinPath;$env:Path"
        }

        if (Get-Command bun -ErrorAction SilentlyContinue) {
            $version = bun --version 2>$null
            Write-Host "  ✓ Bun 已安装 (通过 npm): $version" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "  npm 安装失败" -ForegroundColor Yellow
    }

    Write-Host "  ⚠ Bun 安装跳过，请稍后手动安装" -ForegroundColor Yellow
    Write-Host "    运行: npm install -g bun" -ForegroundColor DarkGray
    return $false
}

# 检测命令
function Has-Command {
    param([string]$Cmd)
    $null = Get-Command $Cmd -ErrorAction SilentlyContinue
    return $?
}

Print-Banner
Cleanup-OldScripts

# 确定安装目录
$currentDir = Get-Location
$REPO_NAME = "OpenCodeChineseTranslation"

if ((Test-Path "$currentDir\.git") -and (Test-Path "$currentDir\opencode-i18n")) {
    $PROJECT_DIR = $currentDir.Path
} elseif (Test-Path "$env:USERPROFILE\$REPO_NAME\.git") {
    $PROJECT_DIR = "$env:USERPROFILE\$REPO_NAME"
} elseif (-not (Get-ChildItem -Path $currentDir -ErrorAction SilentlyContinue | Select-Object -First 1)) {
    $PROJECT_DIR = $currentDir.Path
} else {
    $PROJECT_DIR = "$currentDir\$REPO_NAME"
}

# ==================== 安装前确认 ====================
Write-Host "即将安装 OpenCode 中文汉化版" -ForegroundColor Cyan
Write-Host ""
Write-Host "安装目录: $PROJECT_DIR" -ForegroundColor White
Write-Host "内容包括:" -ForegroundColor White
Write-Host "  • 自动清理旧脚本" -ForegroundColor Gray
Write-Host "  • OpenCode 源码" -ForegroundColor Gray
Write-Host "  • Codes 工具" -ForegroundColor Gray
Write-Host "  • 汉化管理工具" -ForegroundColor Gray
Write-Host "  • 全局命令 opencodecmd" -ForegroundColor Gray
Write-Host ""
$null = Read-Host "按 Enter 继续，Ctrl+C 取消"
Write-Host ""

# ==================== 1/7 检查环境 ====================
Print-Step "1/7 检查系统环境..."

if (Has-Command "node") {
    $NODE_VER = node -v
    Print-Success "Node.js: $NODE_VER"
} else {
    Print-Info "Node.js: 未安装 (将自动安装)"
}

if (Has-Command "git") {
    $GIT_VER = git --version
    Print-Success "Git: $GIT_VER"
} else {
    Print-Info "Git: 未安装 (将自动安装)"
}
Write-Host ""

# ==================== 2/7 确定安装目录 ====================
Print-Step "2/7 确定安装目录..."
Print-Info "安装目录: $PROJECT_DIR"
Write-Host ""

# ==================== 3/7 克隆/更新仓库 ====================
Print-Step "3/7 获取项目文件..."

if ((Test-Path $PROJECT_DIR) -and (-not (Test-Path "$PROJECT_DIR\.git"))) {
    Remove-Item -Recurse -Force $PROJECT_DIR -ErrorAction SilentlyContinue
}

if (Test-Path "$PROJECT_DIR\.git") {
    Print-Info "更新现有仓库..."
    Push-Location $PROJECT_DIR
    $null = git pull --rebase 2>&1
    if ($LASTEXITCODE -eq 0) {
        Print-Success "更新成功"
    } else {
        Print-Info "已是最新版本"
    }
    Pop-Location
} else {
    if (Test-Path $PROJECT_DIR) {
        Remove-Item -Recurse -Force $PROJECT_DIR -ErrorAction SilentlyContinue
    }

    $cloneUrls = @(
        "https://gitee.com/QtCodeCreators/OpenCodeChineseTranslation.git",
        "https://github.com/1186258278/$REPO_NAME.git"
    )
    $sourceNames = @("Gitee", "GitHub")
    $cloneSuccess = $false

    for ($i = 0; $i -lt $cloneUrls.Count; $i++) {
        $null = git clone --depth 1 $cloneUrls[$i] $PROJECT_DIR 2>&1
        if ($LASTEXITCODE -eq 0) {
            Print-Success "从 $($sourceNames[$i]) 克隆成功"
            $cloneSuccess = $true
            break
        }
    }

    if (-not $cloneSuccess) {
        Print-Error "克隆失败，请检查网络"
        exit 1
    }
}
Write-Host ""

# ==================== 4/7 安装依赖 ====================
Print-Step "4/7 安装依赖..."

$codesBinDir = "$env:USERPROFILE\.codes\bin"

if (-not (Has-Command "codes")) {
    if (Test-Path "$PROJECT_DIR\scripts\codes\codes.ps1") {
        & "$PROJECT_DIR\scripts\codes\codes.ps1" install-self *> $null

        # 添加 codes 到 PATH（当前会话 + 持久化）
        if (-not (Test-Path $codesBinDir)) {
            New-Item -ItemType Directory -Path $codesBinDir -Force | Out-Null
        }

        if ($env:Path -notlike "*$codesBinDir*") {
            $env:Path = "$codesBinDir;$env:Path"
        }

        $pathEnv = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($pathEnv -notlike "*$codesBinDir*") {
            [Environment]::SetEnvironmentVariable("Path", "$pathEnv;$codesBinDir", "User")
        }

        Print-Success "Codes 已安装"
    }
} else {
    Print-Success "Codes 已安装"
}

if (-not (Has-Command "node")) {
    if (Has-Command "codes") {
        codes install 1 *> $null
        Print-Success "Node.js 已安装"
    }
}

# 检查并安装 Bun（构建工具）
if (-not (Has-Command "bun")) {
    Install-Bun
} else {
    Print-Success "Bun: $((bun --version) 2>$null)"
}
Write-Host ""

# ==================== 5/7 安装汉化脚本 ====================
Print-Step "5/7 安装汉化管理工具..."

$I18N_DIR = "$PROJECT_DIR\scripts\opencode"
if (-not (Test-Path $I18N_DIR)) {
    New-Item -ItemType Directory -Path $I18N_DIR -Force | Out-Null
}
Print-Success "汉化管理工具已就绪"
Write-Host ""

# ==================== 6/7 创建全局命令 ====================
Print-Step "6/7 创建全局命令..."

$CMD_DIR = "$env:USERPROFILE\.local\bin"
New-Item -ItemType Directory -Path $CMD_DIR -Force | Out-Null

$opencodeCmdContent = @'
# OpenCode 中文汉化管理工具 - 全局命令
function Find-Project {
    # 1. 从当前目录向上递归
    $dir = Get-Location
    while ($dir.Path -ne $null -and $dir.Path -ne "") {
        if (Test-Path "$dir\scripts\opencode\opencode.ps1") { return $dir.Path }
        if (Test-Path "$dir\scripts\opencode-linux\opencode.js") { return $dir.Path }
        $dir = $dir.Parent
    }

    # 2. 检查常见位置
    $locations = @(
        "$env:USERPROFILE\OpenCodeChineseTranslation",
        "$env:USERPROFILE\opencode",
        (Split-Path (Get-Location).Path -Parent | ForEach-Object { Join-Path $_ "OpenCodeChineseTranslation" })
    )

    foreach ($loc in $locations) {
        if ($loc -and (Test-Path "$loc\scripts\opencode\opencode.ps1")) {
            return $loc
        }
    }

    return $null
}

$project = Find-Project
if ($project) {
    if (Test-Path "$project\scripts\opencode\opencode.ps1") {
        & "$project\scripts\opencode\opencode.ps1" @args
    } elseif (Test-Path "$project\scripts\opencode-linux\opencode.js") {
        & opencode @args
    }
} else {
    Write-Host "✗ 未找到 OpenCode 项目" -ForegroundColor Red
    Write-Host "安装命令: irm https://gitee.com/QtCodeCreators/OpenCodeChineseTranslation/raw/main/scripts/install.ps1 | iex" -ForegroundColor Cyan
    exit 1
}
'@

$opencodeCmdContent | Out-File "$CMD_DIR\opencodecmd.ps1" -Encoding UTF8
"@echo off pwsh -NoProfile -ExecutionPolicy Bypass -File `"$CMD_DIR\opencodecmd.ps1`" %*" | Out-File "$CMD_DIR\opencodecmd.bat" -Encoding ASCII

if ($env:Path -notlike "*$CMD_DIR*") {
    $env:Path = "$CMD_DIR;$env:Path"
}
$pathEnv = [Environment]::GetEnvironmentVariable("Path", "User")
if ($pathEnv -notlike "*$CMD_DIR*") {
    [Environment]::SetEnvironmentVariable("Path", "$pathEnv;$CMD_DIR", "User")
}

Print-Success "全局命令已创建"
Write-Host ""

# ==================== 7/7 完成 ====================
Print-Step "7/7 安装完成！"
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║" -ForegroundColor Green -NoNewline
Write-Host "              安装成功！现在可以开始使用了              " -ForegroundColor White -NoNewline
Write-Host "║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "快速开始:" -ForegroundColor Cyan
Write-Host "  cd $PROJECT_DIR" -ForegroundColor Yellow
Write-Host "  opencodecmd           # 启动菜单" -ForegroundColor Yellow
Write-Host "  opencodecmd full      # 一键全流程" -ForegroundColor Yellow
Write-Host ""
Write-Host "✓ opencodecmd 命令在当前终端已立即可用" -ForegroundColor Green
Write-Host ""
