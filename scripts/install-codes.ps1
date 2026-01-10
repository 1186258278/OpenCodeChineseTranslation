# ========================================
# Codes 全局安装脚本
# 平台: Windows PowerShell
# ========================================

$ErrorActionPreference = "Stop"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$INSTALL_DIR = "$env:USERPROFILE\.codes"
$BIN_DIR = "$INSTALL_DIR\bin"

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Codes 全局安装                                           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 创建目录
if (-not (Test-Path $BIN_DIR)) {
    New-Item -ItemType Directory -Path $BIN_DIR -Force | Out-Null
}

# 复制脚本
Write-Host "→ 复制脚本到 $BIN_DIR..." -ForegroundColor Cyan
Copy-Item "$SCRIPT_DIR\codes.ps1" "$BIN_DIR\codes.ps1" -Force

# 创建 bat wrapper
$batContent = @"
@echo off
REM Codes wrapper
powershell -NoProfile -ExecutionPolicy Bypass -File "$BIN_DIR\codes.ps1" %*
"@
$batContent | Out-File "$BIN_DIR\codes.bat" -Encoding ASCII

# 创建 ps1 wrapper
$ps1Content = @"
# Codes wrapper
Set-Location $SCRIPT_DIR
& "$BIN_DIR\codes.ps1" @args
"@
$ps1Content | Out-File "$BIN_DIR\codes.ps1" -Encoding UTF8

Write-Host ""
Write-Host "✓ 安装完成!" -ForegroundColor Green
Write-Host ""

# 检查是否在 PATH 中
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$BIN_DIR*") {
    Write-Host "→ 添加到 PATH..." -ForegroundColor Cyan

    # 添加到用户 PATH
    [Environment]::SetEnvironmentVariable("Path", $currentPath + ";$BIN_DIR", "User")

    Write-Host ""
    Write-Host "✓ 已添加到用户 PATH" -ForegroundColor Green
    Write-Host ""
    Write-Host "请重启 PowerShell 或命令提示符使更改生效" -ForegroundColor Yellow
} else {
    Write-Host "✓ 已在 PATH 中" -ForegroundColor Green
}

Write-Host ""
Write-Host "然后就可以使用 codes 命令了:" -ForegroundColor Cyan
Write-Host "  codes doctor    # 环境诊断" -ForegroundColor White
Write-Host "  codes --help    # 查看帮助" -ForegroundColor White
Write-Host ""
