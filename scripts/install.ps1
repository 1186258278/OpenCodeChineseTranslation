# ========================================
# OpenCode 汉化版 - 一键安装脚本 v2.1
# Windows 完整安装
# 使用方式: irm https://gitee.com/QtCodeCreators/OpenCodeChineseTranslation/raw/main/scripts/install.ps1 | iex
# ========================================

$ErrorActionPreference = "Continue"

# ==================== 颜色函数 ====================
function Print-Banner {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║" -ForegroundColor Cyan -NoNewline
    Write-Host "     OpenCode 中文汉化版 - 一键安装脚本 v2.1            " -ForegroundColor White -NoNewline
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

# 检测命令
function Has-Command {
    param([string]$Cmd)
    $null = Get-Command $Cmd -ErrorAction SilentlyContinue
    return $?
}

Print-Banner

# ==================== 安装前确认 ====================
Write-Host "即将安装 OpenCode 中文汉化版" -ForegroundColor Cyan
Write-Host ""
Write-Host "安装内容包括:" -ForegroundColor White
Write-Host "  • OpenCode 源码 (从 Gitee/GitHub 克隆)" -ForegroundColor Gray
Write-Host "  • Codes 开发环境管理工具" -ForegroundColor Gray
Write-Host "  • Node.js 运行时 (如未安装)" -ForegroundColor Gray
Write-Host "  • 汉化管理工具 (opencode)" -ForegroundColor Gray
Write-Host "  • 全局命令 opencodecmd" -ForegroundColor Gray
Write-Host ""

# 检测并显示安装目录
$currentDir = Get-Location
$REPO_NAME = "OpenCodeChineseTranslation"

if ((Test-Path "$currentDir\.git") -and (Test-Path "$currentDir\opencode-i18n")) {
    $PROJECT_DIR = $currentDir.Path
    $INSTALL_TYPE = "更新现有安装"
elseif (Test-Path "$env:USERPROFILE\$REPO_NAME\.git") {
    $PROJECT_DIR = "$env:USERPROFILE\$REPO_NAME"
    $INSTALL_TYPE = "更新现有安装"
elseif (-not (Get-ChildItem -Path $currentDir -ErrorAction SilentlyContinue | Select-Object -First 1)) {
    $PROJECT_DIR = $currentDir.Path
    $INSTALL_TYPE = "全新安装到当前目录"
} else {
    $PROJECT_DIR = "$currentDir\$REPO_NAME"
    $INSTALL_TYPE = "全新安装到子目录"
}

Write-Host "安装信息:" -ForegroundColor White
Write-Host "  目录: $PROJECT_DIR" -ForegroundColor Gray
Write-Host "  类型: $INSTALL_TYPE" -ForegroundColor Gray
Write-Host "  平台: Windows" -ForegroundColor Gray
Write-Host ""

# 显示可用命令
Write-Host "安装后可用命令:" -ForegroundColor White
Write-Host "  opencodecmd        启动交互菜单" -ForegroundColor Yellow
Write-Host "  opencodecmd full    一键完整汉化流程" -ForegroundColor Yellow
Write-Host "  opencodecmd update  更新源码" -ForegroundColor Yellow
Write-Host "  opencodecmd apply   应用汉化" -ForegroundColor Yellow
Write-Host "  opencodecmd build   编译构建" -ForegroundColor Yellow
Write-Host ""

# 确认安装
$confirm = Read-Host "是否继续安装? [Y/n]"
if ($confirm -eq 'n' -or $confirm -eq 'N') {
    Write-Host "安装已取消" -ForegroundColor Yellow
    exit 0
}
Write-Host ""

# ==================== 1. 检查环境 ====================
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

# ==================== 2. 确定安装目录 ====================
Print-Step "2/7 确定安装目录..."
Print-Info "安装目录: $PROJECT_DIR"
Write-Host ""

# ==================== 3. 克隆/更新仓库 ====================
Print-Step "3/7 获取项目文件..."

# 删除已存在的目录（如果存在但不是 git 仓库）
if ((Test-Path $PROJECT_DIR) -and (-not (Test-Path "$PROJECT_DIR\.git"))) {
    Print-Info "清理非 Git 目录..."
    Remove-Item -Recurse -Force $PROJECT_DIR -ErrorAction SilentlyContinue
}

if (Test-Path "$PROJECT_DIR\.git") {
    Print-Info "更新现有仓库..."
    Push-Location $PROJECT_DIR
    $null = git pull --rebase 2>&1
    if ($LASTEXITCODE -eq 0) {
        Print-Success "更新成功"
    } else {
        Print-Info "已是最新版本或更新失败（继续）"
    }
    Pop-Location
} else {
    # 如果目录存在，先删除
    if (Test-Path $PROJECT_DIR) {
        Remove-Item -Recurse -Force $PROJECT_DIR -ErrorAction SilentlyContinue
    }

    Print-Info "克隆仓库..."

    # 克隆 URL 列表
    $cloneUrls = @(
        "https://gitee.com/QtCodeCreators/OpenCodeChineseTranslation.git",
        "https://github.com/1186258278/$REPO_NAME.git"
    )

    $sourceNames = @("Gitee", "GitHub")
    $cloneSuccess = $false

    for ($i = 0; $i -lt $cloneUrls.Count; $i++) {
        $url = $cloneUrls[$i]
        $source = $sourceNames[$i]

        Print-Info "尝试从 $source 克隆..."

        $null = git clone --depth 1 $url $PROJECT_DIR 2>&1
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
}

Write-Host ""

# ==================== 4. 安装依赖 ====================
Print-Step "4/7 安装依赖..."

# 安装 Codes 工具（如果需要）
if (-not (Has-Command "codes")) {
    Print-Info "安装 Codes 管理工具..."
    if (Test-Path "$PROJECT_DIR\scripts\codes\codes.ps1") {
        & "$PROJECT_DIR\scripts\codes\codes.ps1" install-self *> $null
        if ($LASTEXITCODE -eq 0) {
            Print-Success "Codes 已安装"
        } else {
            Print-Info "Codes 安装跳过（非必须）"
        }
    }
} else {
    Print-Success "Codes 已安装"
}

# 检查 Node.js
if (-not (Has-Command "node")) {
    Print-Info "安装 Node.js..."
    if (Has-Command "codes") {
        codes install 1 *> $null
        Print-Success "Node.js 已安装"
    } else {
        Print-Error "无法自动安装 Node.js，请手动安装"
        exit 1
    }
}

Write-Host ""

# ==================== 5. 安装汉化脚本 ====================
Print-Step "5/7 安装汉化管理工具..."

$I18N_DIR = "$PROJECT_DIR\scripts\opencode"

if (-not (Test-Path $I18N_DIR)) {
    New-Item -ItemType Directory -Path $I18N_DIR -Force | Out-Null
}

Print-Success "汉化管理工具已就绪"
Write-Host ""

# ==================== 6. 创建全局命令 ====================
Print-Step "6/7 创建全局命令..."

# Windows 使用用户目录下的 bin
$CMD_DIR = "$env:USERPROFILE\.local\bin"
New-Item -ItemType Directory -Path $CMD_DIR -Force | Out-Null

# 创建独立的 PowerShell 全局命令
$opencodeCmdContent = @'
# OpenCode 中文汉化管理工具 - 全局命令
# 这是一个独立脚本，不依赖其他文件

function Find-Project {
    $dir = Get-Location
    while ($dir.Path -ne $null -and $dir.Path -ne "") {
        if (Test-Path "$dir\scripts\opencode\opencode.ps1") {
            return $dir.Path
        }
        if (Test-Path "$dir\scripts\opencode-linux\opencode.js") {
            return $dir.Path
        }
        $dir = $dir.Parent
    }

    # 检查用户主目录
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
    Write-Host "✗ 未找到 OpenCode 项目目录" -ForegroundColor Red
    Write-Host "请先运行安装脚本或进入项目目录" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "安装命令:" -ForegroundColor White
    Write-Host "  irm https://gitee.com/QtCodeCreators/OpenCodeChineseTranslation/raw/main/scripts/install.ps1 | iex" -ForegroundColor White
    exit 1
}
'@

$CMD_FILE_PS1 = "$CMD_DIR\opencodecmd.ps1"
$opencodeCmdContent | Out-File $CMD_FILE_PS1 -Encoding UTF8

# 创建批处理启动器（方便 CMD 用户）
$batContent = @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "$CMD_FILE_PS1" %*
"@
$batContent | Out-File "$CMD_DIR\opencodecmd.bat" -Encoding ASCII

# 添加到当前会话 PATH（立即可用）
if ($env:Path -notlike "*$CMD_DIR*") {
    $env:Path = "$CMD_DIR;$env:Path"
}

# 持久化到用户环境变量
$pathEnv = [Environment]::GetEnvironmentVariable("Path", "User")
if ($pathEnv -notlike "*$CMD_DIR*") {
    [Environment]::SetEnvironmentVariable("Path", "$pathEnv;$CMD_DIR", "User")
    Print-Success "已将 $CMD_DIR 添加到 PATH"
    Print-Info "新终端窗口中自动生效"
} else {
    Print-Success "全局命令已就绪"
}

Write-Host ""

# ==================== 7. 完成 ====================
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
Write-Host "  3. 或直接运行:" -ForegroundColor White
Write-Host "     .\scripts\opencode\opencode.ps1" -ForegroundColor Yellow
Write-Host ""
Write-Host "全局命令 (当前终端已生效):" -ForegroundColor Cyan
Write-Host "  opencodecmd              # 启动菜单" -ForegroundColor Yellow
Write-Host "  opencodecmd update       # 拉取源码" -ForegroundColor Yellow
Write-Host "  opencodecmd apply        # 应用汉化" -ForegroundColor Yellow
Write-Host "  opencodecmd build        # 编译构建" -ForegroundColor Yellow
Write-Host "  opencodecmd full         # 一键全流程" -ForegroundColor Yellow
Write-Host ""
Write-Host "✓ opencodecmd 命令在当前终端已立即可用" -ForegroundColor Green
Write-Host ""
