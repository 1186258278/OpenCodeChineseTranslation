# OpenCode 汉化工具一键安装脚本 (Windows)

$ErrorActionPreference = "Stop"

# 强制设置控制台编码为 UTF-8，解决乱码问题
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 颜色输出
function Write-Color($text, $color) {
    Write-Host $text -ForegroundColor $color
}

Write-Color "==============================================" "Cyan"
Write-Color "   OpenCode 汉化管理工具一键安装脚本   " "Cyan"
Write-Color "==============================================" "Cyan"

# 1. 检查依赖
Write-Color "`n[1/5] 检查环境依赖..." "Yellow"

$hasNode = Get-Command "node" -ErrorAction SilentlyContinue
$hasNpm = Get-Command "npm" -ErrorAction SilentlyContinue
$hasBun = Get-Command "bun" -ErrorAction SilentlyContinue
$runtime = ""

if ($hasNode -and $hasNpm) {
    Write-Color "✓ 检测到 Node.js ($(node -v))" "Green"
    $runtime = "node"
} elseif ($hasBun) {
    Write-Color "✓ 检测到 Bun ($(bun --version))" "Green"
    $runtime = "bun"
} else {
    Write-Color "未检测到 Node.js 或 Bun。" "Yellow"
    Write-Color "正在为您自动安装 Bun 环境..." "Cyan"
    
    # 自动安装 Bun
    try {
        powershell -c "irm bun.sh/install.ps1 | iex"
        
        # 刷新环境变量
        $env:BUN_INSTALL = "$env:USERPROFILE\.bun"
        $env:PATH = "$env:BUN_INSTALL\bin;$env:PATH"
        
        if (Get-Command "bun" -ErrorAction SilentlyContinue) {
            Write-Color "✓ Bun 安装成功 ($(bun --version))" "Green"
            $runtime = "bun"
        } else {
            throw "Bun 安装验证失败"
        }
    } catch {
        Write-Color "错误: 自动安装环境失败。请手动安装 Node.js 或 Bun 后重试。" "Red"
        exit 1
    }
}

# 2. 获取最新版本
Write-Color "`n[2/5] 获取最新版本信息..." "Yellow"
$repo = "1186258278/OpenCodeChineseTranslation"
$apiUrl = "https://api.github.com/repos/$repo/releases/latest"

try {
    $latest = Invoke-RestMethod -Uri $apiUrl
    $tagName = $latest.tag_name
    Write-Color "最新版本: $tagName" "Green"
} catch {
    Write-Color "警告: 无法获取最新版本，尝试使用默认版本 v7.3.2" "Yellow"
    $tagName = "v7.3.2"
}

# 3. 下载
$installDir = "$HOME\.opencode-i18n"
$zipUrl = "https://github.com/$repo/releases/download/$tagName/opencode-i18n-tool-$tagName.zip"
$tempZip = "$env:TEMP\opencode-i18n.zip"

Write-Color "`n[3/5] 下载汉化工具..." "Yellow"
Write-Color "下载地址: $zipUrl" "Gray"

try {
    Invoke-WebRequest -Uri $zipUrl -OutFile $tempZip
    Write-Color "下载成功!" "Green"
} catch {
    Write-Color "下载失败! 请检查网络连接。" "Red"
    Write-Color "如果您在中国大陆，请尝试访问官网下载离线安装包。" "Gray"
    exit 1
}

# 4. 解压安装
Write-Color "`n[4/5] 安装到 $installDir ..." "Yellow"

# 如果当前在安装目录内，先切换出去，否则无法删除
if ((Get-Location).Path.StartsWith($installDir)) {
    Write-Color "检测到当前位于目标目录内，切换到临时目录..." "Gray"
    Set-Location $env:TEMP
}

if (Test-Path $installDir) {
    Write-Color "清理旧版本..." "Gray"
    try {
        Remove-Item -Path $installDir -Recurse -Force -ErrorAction Stop
    } catch {
        Write-Color "清理失败: 目录正被占用。请关闭所有在该目录下的终端窗口或应用后重试。" "Red"
        exit 1
    }
}

New-Item -ItemType Directory -Force -Path $installDir | Out-Null
Expand-Archive -Path $tempZip -DestinationPath $installDir -Force
Remove-Item $tempZip

# 5. 安装依赖
Write-Color "`n[5/5] 安装项目依赖..." "Yellow"
Set-Location "$installDir\scripts"

if ($runtime -eq "bun") {
    bun install --production
} else {
    # 使用淘宝镜像加速 npm 安装
    Write-Color "正在使用 npm 镜像源安装依赖..." "Gray"
    try {
        npm install --production --registry=https://registry.npmmirror.com
    } catch {
        Write-Color "`n[!] 依赖安装失败。" "Red"
        Write-Color "提示: 检测到网络错误。这通常是因为您的 npm 配置了代理但无法连接 (ECONNREFUSED)。" "Yellow"
        Write-Color "请尝试运行以下命令清除代理配置后重试:" "Gray"
        Write-Color "  npm config delete proxy" "Cyan"
        Write-Color "  npm config delete https-proxy" "Cyan"
        Write-Color "或者检查您的代理软件 (Clash 等) 是否开启了 7890/7897 端口。" "Gray"
        exit 1
    }
}

# 链接全局命令 (对于 Windows，我们需要创建一个 cmd wrapper)
Write-Color "`n正在配置全局命令 'opencodenpm'..." "Yellow"

$npmBin = "$env:APPDATA\npm"
if (-not (Test-Path $npmBin)) {
    New-Item -ItemType Directory -Force -Path $npmBin | Out-Null
}

$cmdPath = "$npmBin\opencodenpm.cmd"
$ps1Path = "$npmBin\opencodenpm.ps1"
$scriptPath = "$installDir\scripts\bin\opencodenpm"

if ($runtime -eq "bun") {
    # Bun wrapper
    Set-Content -Path $cmdPath -Value "@ECHO OFF`r`nbun `"$scriptPath`" %*"
} else {
    # Node wrapper
    Set-Content -Path $cmdPath -Value "@ECHO OFF`r`nnode `"$scriptPath`" %*"
}

Write-Color "`n==============================================" "Green"
Write-Color "   安装完成!   " "Green"
Write-Color "==============================================" "Green"
Write-Color "`n请直接在终端运行以下命令启动:" "Gray"
Write-Color "  opencodenpm" "Cyan"
Write-Color "`n注意: 如果提示命令未找到，请重启终端或检查 PATH 环境变量。" "Yellow"
