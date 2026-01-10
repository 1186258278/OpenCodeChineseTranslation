# OpenCode 中文汉化版 - 自动初始化脚本
# 用于首次运行时自动设置上游源码

param(
    [switch]$Force = $false
)

# 颜色输出函数
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# 获取项目根目录（脚本所在目录的父目录）
$SCRIPT_DIR = $PSScriptRoot
if (!$SCRIPT_DIR) {
    $SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$PROJECT_DIR = Split-Path -Parent $SCRIPT_DIR
$SRC_DIR = "$PROJECT_DIR\opencode-zh-CN"
$UPSTREAM_REPO = "https://github.com/anomalyco/opencode.git"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  OpenCode 中文汉化版 - 环境检查                              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 检查 Git 是否安装
$gitInstalled = Get-Command git -ErrorAction SilentlyContinue
if (!$gitInstalled) {
    Write-ColorOutput "❌ Git 未安装或不在 PATH 中" "Red"
    Write-Host "   请先安装 Git: https://git-scm.com/downloads" -ForegroundColor DarkGray
    Write-Host ""
    exit 1
}

# 检查 Bun 是否安装
$bunInstalled = Get-Command bun -ErrorAction SilentlyContinue
if (!$bunInstalled) {
    Write-ColorOutput "⚠️  Bun 未安装，正在自动安装..." "Yellow"

    # 尝试安装 Bun
    try {
        Write-Host "   正在从官方源安装..." -ForegroundColor Gray

        # 方式1: 官方安装脚本
        irm https://bun.sh/install.ps1 | iex

        # 添加到 PATH
        $bunPath = "$env:USERPROFILE\.bun\bin"
        if ($env:Path -notlike "*$bunPath*") {
            $env:Path = "$bunPath;$env:Path"
        }

        # 刷新命令
        $bunInstalled = Get-Command bun -ErrorAction SilentlyContinue

        if ($bunInstalled) {
            $version = bun --version 2>$null
            Write-ColorOutput "✓ Bun 已安装: $version" "Green"
        } else {
            throw "官方安装失败"
        }
    } catch {
        Write-Host "   官方安装失败，尝试 npm..." -ForegroundColor Yellow

        # 方式2: npm 全局安装
        try {
            npm install -g bun *> $null

            # npm 全局路径
            $npmGlobal = npm config get prefix
            $npmBinPath = "$npmGlobal"
            if ($env:Path -notlike "*$npmBinPath*") {
                $env:Path = "$npmBinPath;$env:Path"
            }

            $bunInstalled = Get-Command bun -ErrorAction SilentlyContinue

            if ($bunInstalled) {
                $version = bun --version 2>$null
                Write-ColorOutput "✓ Bun 已安装 (通过 npm): $version" "Green"
            } else {
                throw "npm 安装失败"
            }
        } catch {
            Write-ColorOutput "❌ Bun 自动安装失败" "Red"
            Write-Host "   请手动安装: npm install -g bun" -ForegroundColor DarkGray
            Write-Host ""
            exit 1
        }
    }
    Write-Host ""
}

Write-ColorOutput "✅ Git 已安装" "Green"
Write-ColorOutput "✅ Bun 已安装" "Green"
Write-Host ""

# 检查源码目录状态
if (!(Test-Path $SRC_DIR)) {
    Write-ColorOutput "📁 创建源码目录: $SRC_DIR" "Cyan"
    New-Item -ItemType Directory -Path $SRC_DIR -Force | Out-Null
}

# 检查是否已初始化
$isInitialized = Test-Path "$SRC_DIR\.git"

if ($isInitialized -and !$Force) {
    Write-ColorOutput "✅ 源码已初始化，跳过克隆步骤" "Green"
    Write-Host "   如需重新初始化，请运行: .\scripts\init.ps1 -Force" -ForegroundColor DarkGray
    Write-Host ""
    exit 0
}

if ($Force -and $isInitialized) {
    Write-ColorOutput "⚠️  强制重新初始化模式" "Yellow"
    $confirm = Read-Host "确定要删除现有源码并重新克隆？(yes/NO)"
    if ($confirm -ne "yes" -and $confirm -ne "YES") {
        Write-ColorOutput "已取消" "DarkGray"
        exit 0
    }

    Write-Host "   删除现有源码..." -ForegroundColor Yellow
    Remove-Item $SRC_DIR -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $SRC_DIR -Force | Out-Null
    Write-Host ""
}

# 克隆上游代码
Write-ColorOutput "🔄 正在克隆上游代码..." "Cyan"
Write-Host "   仓库: $UPSTREAM_REPO" -ForegroundColor DarkGray
Write-Host ""

$cloneArgs = @("clone", "--depth=1", $UPSTREAM_REPO, $SRC_DIR)
$cloneResult = & git @cloneArgs 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-ColorOutput "✅ 初始化完成！" "Green"
    Write-Host ""
    Write-ColorOutput "下一步:" "Cyan"
    Write-Host "   运行 .\scripts\opencode.ps1 开始汉化" -ForegroundColor White
    Write-Host ""
    exit 0
}

# Git 克隆失败，尝试备用方案
Write-ColorOutput "⚠️  Git 克隆失败" "Yellow"
Write-Host "   错误: $cloneResult" -ForegroundColor DarkGray
Write-Host ""

Write-ColorOutput "📦 尝试备用方案: 下载源码压缩包..." "Cyan"
Write-Host ""

# 检测是否有 curl
$hasCurl = Get-Command curl -ErrorAction SilentlyContinue

if ($hasCurl) {
    $downloadUrl = "https://codeload.github.com/anomalyco/opencode/zip/refs/heads/main"
    $zipPath = "$PROJECT_DIR\opencode-main.zip"

    Write-Host "   下载地址: $downloadUrl" -ForegroundColor DarkGray
    Write-Host "   保存位置: $zipPath" -ForegroundColor DarkGray
    Write-Host ""

    Write-ColorOutput "⬇️  正在下载..." "Cyan"
    & curl.exe -L -o $zipPath $downloadUrl

    if (Test-Path $zipPath) {
        Write-ColorOutput "✅ 下载完成" "Green"
        Write-Host "   正在解压..." -ForegroundColor Cyan

        try {
            # 使用 PowerShell 解压
            Expand-Archive -Path $zipPath -DestinationPath $PROJECT_DIR -Force
            $extractedDir = "$PROJECT_DIR\opencode-main"

            if (Test-Path $extractedDir) {
                # 移动文件到目标目录
                if (Test-Path $SRC_DIR) {
                    Remove-Item $SRC_DIR -Recurse -Force
                }
                Move-Item $extractedDir $SRC_DIR

                # 清理压缩包
                Remove-Item $zipPath -Force

                Write-ColorOutput "✅ 初始化完成！" "Green"
                Write-Host ""
                Write-ColorOutput "下一步:" "Cyan"
                Write-Host "   运行 .\scripts\opencode.ps1 开始汉化" -ForegroundColor White
                Write-Host ""
                exit 0
            }
        } catch {
            Write-ColorOutput "❌ 解压失败: $_" "Red"
        }
    }
}

# 所有方案都失败
Write-ColorOutput "❌ 自动初始化失败" "Red"
Write-Host ""
Write-ColorOutput "📋 手动安装步骤:" "Cyan"
Write-Host "   1. 浏览器访问: https://github.com/anomalyco/opencode" -ForegroundColor White
Write-Host "   2. 点击绿色 'Code' 按钮 → 'Download ZIP'" -ForegroundColor White
Write-Host "   3. 解压到: $SRC_DIR" -ForegroundColor White
Write-Host "   4. 运行: .\scripts\opencode.ps1" -ForegroundColor White
Write-Host ""
Write-ColorOutput "💡 常见问题:" "Yellow"
Write-Host "   - 网络问题: 尝试配置 Git 代理" -ForegroundColor DarkGray
Write-Host "   - 认证失败: 检查 Git 配置或使用下载方式" -ForegroundColor DarkGray
Write-Host ""
exit 1
