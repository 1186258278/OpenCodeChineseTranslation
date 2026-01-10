# ========================================
# OpenCode 汉化版 - 一键安装脚本 v2.0
# Windows 完整安装
# 使用方式: irm https://gitee.com/QtCodeCreators/OpenCodeChineseTranslation/raw/main/scripts/install.ps1 | iex
# ========================================

$ErrorActionPreference = "Stop"

# 颜色函数
function Print-Banner {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║" -ForegroundColor Cyan -NoNewline
    Write-Host "     OpenCode 中文汉化版 - 一键安装脚本                    " -ForegroundColor White -NoNewline
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
    Write-Host "  $Message" -ForegroundColor White
}

# 项目配置
$REPO_GITEE = "QtCodeCreators/OpenCodeChineseTranslation"
$REPO_NAME = "OpenCodeChineseTranslation"
$PROJECT_DIR = "$HOME\$REPO_NAME"

# 检测命令
function Has-Command {
    param([string]$Cmd)
    $null = Get-Command $Cmd -ErrorAction SilentlyContinue
    return $?
}

# 智能 sudo（Windows 使用管理员权限检测）
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Print-Banner

# 1. 检查环境
Print-Step "1/7 检查系统环境..."

# 检查 Node.js
if (Has-Command "node") {
    $NODE_VER = node -v
    Print-Success "Node.js: $NODE_VER"
} else {
    Print-Info "Node.js: 未安装 (将自动安装)"
}

# 检查 Git
if (Has-Command "git") {
    $GIT_VER = git --version
    Print-Success "Git: $GIT_VER"
} else {
    Print-Info "Git: 未安装 (将自动安装)"
}

Write-Host ""

# 2. 确定安装目录
Print-Step "2/7 确定安装目录..."

# 优先使用当前目录（如果在 git 仓库中）
$currentDir = Get-Location
if (Test-Path "$currentDir\.git") {
    $PROJECT_DIR = $currentDir.Path
    Print-Info "使用当前目录: $PROJECT_DIR"
} else {
    # 检查用户目录
    if (Test-Path "$HOME\$REPO_NAME") {
        $PROJECT_DIR = "$HOME\$REPO_NAME"
        Print-Info "使用已存在目录: $PROJECT_DIR"
    } else {
        $PROJECT_DIR = "$HOME\$REPO_NAME"
        Print-Info "将克隆到: $PROJECT_DIR"
    }
}
Write-Host ""

# 3. 克隆/更新仓库
Print-Step "3/7 获取项目文件..."

# 删除已存在的目录（如果存在但不是 git 仓库）
if ((Test-Path $PROJECT_DIR) -and (-not (Test-Path "$PROJECT_DIR\.git"))) {
    Print-Info "删除非 Git 目录..."
    Remove-Item -Recurse -Force $PROJECT_DIR -ErrorAction SilentlyContinue
}

if (Test-Path "$PROJECT_DIR\.git") {
    Print-Info "更新现有仓库..."
    Set-Location $PROJECT_DIR
    git pull --rebase 2>&1 | Out-Null
} else {
    Print-Info "克隆仓库..."
    $cloneSuccess = $false

    # 如果目录存在，先删除
    if (Test-Path $PROJECT_DIR) {
        Remove-Item -Recurse -Force $PROJECT_DIR -ErrorAction SilentlyContinue
    }

    # 克隆 URL 列表
    $cloneUrls = @(
        "https://gitee.com/$REPO_GITEE.git",
        "https://gitee.com/QtCodeCreators/OpenCodeChineseTranslation.git",
        "https://github.com/1186258278/$REPO_NAME.git"
    )

    $sourceNames = @("Gitee (主)", "Gitee (备用)", "GitHub")

    for ($i = 0; $i -lt $cloneUrls.Count; $i++) {
        $url = $cloneUrls[$i]
        $source = $sourceNames[$i]

        Print-Info "尝试从 $source 克隆..."

        $result = cmd /c "git clone --depth 1 `"$url`" `"$PROJECT_DIR`" 2>&1" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Print-Success "从 $source 克隆成功"
            $cloneSuccess = $true
            break
        } else {
            Print-Info "  $source 失败，尝试下一个..."
        }
    }

    if (-not $cloneSuccess) {
        Print-Error "克隆失败，请检查网络连接"
        Write-Host ""
        Write-Host "可以手动克隆:" -ForegroundColor Yellow
        Write-Host "  git clone https://gitee.com/QtCodeCreators/OpenCodeChineseTranslation.git" -ForegroundColor White
        Write-Host "  cd OpenCodeChineseTranslation" -ForegroundColor White
        Write-Host "  .\scripts\opencode\opencode.ps1" -ForegroundColor White
        exit 1
    }

    Set-Location $PROJECT_DIR
}
Write-Host ""

# 4. 安装依赖
Print-Step "4/7 安装依赖..."

# 安装 Codes 工具
if (-not (Has-Command "codes")) {
    Print-Info "安装 Codes 管理工具..."
    & "$PROJECT_DIR\scripts\codes\codes.ps1" install-self
    if ($?) {
        Print-Success "Codes 已安装"
    }
} else {
    Print-Success "Codes 已安装"
}

# 检查 Node.js
if (-not (Has-Command "node")) {
    Print-Info "安装 Node.js..."
    codes install 1
}

Write-Host ""

# 5. 安装汉化脚本
Print-Step "5/7 安装汉化管理工具..."

$I18N_DIR = "$PROJECT_DIR\scripts\opencode"

if (-not (Test-Path $I18N_DIR)) {
    New-Item -ItemType Directory -Path $I18N_DIR -Force | Out-Null
}

Print-Success "汉化管理工具已就绪"
Write-Host ""

# 6. 创建全局命令
Print-Step "6/7 创建全局命令..."

# 创建 opencodecmd 命令
$CMD_DIR = "$HOME\.local\bin"
New-Item -ItemType Directory -Path $CMD_DIR -Force | Out-Null

$opencodeCmdContent = @'
#!/usr/bin/env pwsh
# OpenCode 中文汉化管理工具 - 全局命令

function Find-Project {
    $dir = Get-Location
    while ($dir.Path -ne "") {
        if (Test-Path "$dir\scripts\opencode\opencode.ps1") {
            return $dir.Path
        }
        if (Test-Path "$dir\scripts\opencode-linux\opencode.js") {
            return $dir.Path
        }
        $dir = $dir.Parent
    }
    # 检查用户目录
    if (Test-Path "$env:USERPROFILE\OpenCodeChineseTranslation\scripts\opencode\opencode.ps1") {
        return "$env:USERPROFILE\OpenCodeChineseTranslation"
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
    Write-Host "错误: 未找到 OpenCode 项目目录" -ForegroundColor Red
    Write-Host "请先进入项目目录或运行: codes i18n" -ForegroundColor White
    exit 1
}
'@

$CMD_FILE = "$CMD_DIR\opencodecmd.ps1"
$opencodeCmdContent | Out-File $CMD_FILE -Encoding UTF8

# 创建简短的 bat 启动器
$batContent = @"
@echo off
pwsh -NoProfile -ExecutionPolicy Bypass -File "$CMD_FILE" %*
"@
$batContent | Out-File "$CMD_DIR\opencodecmd.bat" -Encoding ASCII

# 添加到 PATH
$pathEnv = [Environment]::GetEnvironmentVariable("Path", "User")
if ($pathEnv -notlike "*$CMD_DIR*") {
    [Environment]::SetEnvironmentVariable("Path", "$pathEnv;$CMD_DIR", "User")
    Print-Success "已将 $CMD_DIR 添加到 PATH"
    Print-Info "重启终端后生效"
} else {
    Print-Success "全局命令已就绪"
}
Write-Host ""

# 7. 完成
Print-Step "7/7 安装完成！"
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║" -ForegroundColor Green -NoNewline
Write-Host "              安装成功！现在可以开始使用了              " -ForegroundColor White -NoNewline
Write-Host "║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "快速开始:" -ForegroundColor Cyan
Write-Host "  1. 进入项目目录:" -ForegroundColor White
Write-Host "     cd $PROJECT_DIR" -ForegroundColor Yellow
Write-Host ""
Write-Host "  2. 运行汉化脚本:" -ForegroundColor White
Write-Host "     opencodecmd           # 交互菜单" -ForegroundColor Yellow
Write-Host "     opencodecmd full      # 一键全流程" -ForegroundColor Yellow
Write-Host ""
Write-Host "  3. 或使用 Codes 工具:" -ForegroundColor White
Write-Host "     codes run             # 启动汉化脚本" -ForegroundColor Yellow
Write-Host "     codes i18n            # 重新安装汉化工具" -ForegroundColor Yellow
Write-Host ""
Write-Host "全局命令 (任意位置):" -ForegroundColor Cyan
Write-Host "  opencodecmd              # 启动菜单" -ForegroundColor Yellow
Write-Host "  opencodecmd update       # 拉取源码" -ForegroundColor Yellow
Write-Host "  opencodecmd apply        # 应用汉化" -ForegroundColor Yellow
Write-Host "  opencodecmd build        # 编译构建" -ForegroundColor Yellow
Write-Host "  opencodecmd full         # 一键全流程" -ForegroundColor Yellow
Write-Host ""
Write-Host "提示: 如果命令未生效，请重启终端" -ForegroundColor Magenta
Write-Host ""
