# ========================================
# OpenCode 中文汉化版 - 管理工具 v3.0
# ========================================

# 配置路径 (使用脚本所在目录，自动适配)
$SCRIPT_DIR = if ($PSScriptRoot) { $PSScriptRoot } else { "." }
# 脚本在 scripts/ 子目录中，需要获取项目根目录
$PROJECT_DIR = if (Test-Path "$SCRIPT_DIR\..\opencode-i18n") {
    (Resolve-Path "$SCRIPT_DIR\..").Path
} else {
    $SCRIPT_DIR
}
$SRC_DIR = "$PROJECT_DIR\opencode-zh-CN"
$PACKAGE_DIR = "$SRC_DIR\packages\opencode"
$OUT_DIR = $PROJECT_DIR
$DOCS_DIR = "$SRC_DIR"
# 汉化配置（支持模块化结构）
$I18N_DIR = "$OUT_DIR\opencode-i18n"
$I18N_CONFIG = "$I18N_DIR\config.json"
$I18N_CONFIG_OLD = "$OUT_DIR\opencode-i18n.json"  # 回退到单文件模式
$BACKUP_DIR = "$OUT_DIR\backup"  # 备份目录

# 自动清理 nul 文件（PowerShell 2>$null 问题产生的）
if (Test-Path $SRC_DIR) {
    Get-ChildItem $SRC_DIR -Filter "nul" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}

# ==================== 脚本自保护 ====================
# 自动备份管理脚本本身，防止被覆盖
$SCRIPT_SELF = $PSCommandPath
if ($SCRIPT_SELF -and (Test-Path $SCRIPT_SELF)) {
    $SCRIPT_BACKUP_DIR = "$OUT_DIR\script_backup"
    $SCRIPT_BACKUP = "$SCRIPT_BACKUP_DIR\opencode-v3.ps1"
    $SCRIPT_BACKUP_OLD = "$SCRIPT_BACKUP_DIR\opencode-v3.ps1.old"

    # 创建备份目录
    if (!(Test-Path $SCRIPT_BACKUP_DIR)) {
        New-Item -ItemType Directory -Path $SCRIPT_BACKUP_DIR -Force | Out-Null
    }

    # 如果主备份和当前脚本不同，先保存为 .old
    if ((Test-Path $SCRIPT_BACKUP) -and ((Get-FileHash $SCRIPT_SELF -ErrorAction SilentlyContinue).Hash -ne (Get-FileHash $SCRIPT_BACKUP -ErrorAction SilentlyContinue).Hash)) {
        Copy-Item $SCRIPT_BACKUP $SCRIPT_BACKUP_OLD -Force -ErrorAction SilentlyContinue
    }

    # 总是保持最新备份
    Copy-Item $SCRIPT_SELF $SCRIPT_BACKUP -Force -ErrorAction SilentlyContinue
}

# ==================== 颜色输出 ====================
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Header {
    Clear-Host
    Write-ColorOutput Cyan "╔════════════════════════════════════╗"
    Write-ColorOutput Cyan "║  OpenCode 中文汉化管理工具 v3.0    ║"
    Write-ColorOutput Cyan "╚════════════════════════════════════╝"
    Write-Output ""
}

function Show-Menu {
    Write-Header

    # 版本状态
    $versionInfo = Get-VersionInfo
    if ($versionInfo.HasGit) {
        if ($versionInfo.NeedsUpdate) {
            $remoteMsg = if ($versionInfo.RemoteCommitMessage.Length -gt 20) { $versionInfo.RemoteCommitMessage.Substring(0, 17) + "..." } else { $versionInfo.RemoteCommitMessage }
            Write-ColorOutput Yellow "  版本: $($versionInfo.LocalCommit) → $($versionInfo.RemoteCommit) ($remoteMsg)"
        } else {
            $localMsg = if ($versionInfo.LocalCommitMessage.Length -gt 25) { $versionInfo.LocalCommitMessage.Substring(0, 22) + "..." } else { $versionInfo.LocalCommitMessage }
            Write-ColorOutput Green "  版本: $($versionInfo.LocalCommit) ($localMsg)"
        }
    }

    # 编译时间
    if (Test-Path "$OUT_DIR\opencode.exe") {
        $exeTime = (Get-Item "$OUT_DIR\opencode.exe").LastWriteTime
        $timeDiff = (Get-Date) - $exeTime
        if ($timeDiff.TotalHours -lt 1) {
            Write-ColorOutput Cyan "  编译: 刚刚"
        } else {
            Write-ColorOutput Cyan "  编译: $($exeTime.ToString('MM-dd HH:mm'))"
        }
    }

    Write-Output ""

    Write-ColorOutput Green "  [1]  一键汉化+部署"
    Write-ColorOutput DarkGray "      → 自动拉取代码 → 应用汉化 → 编译 → 部署"
    Write-Output ""
    Write-ColorOutput Cyan "  [2]  验证汉化      [3]  调试工具"
    Write-ColorOutput DarkGray "      检查汉化效果          诊断问题"
    Write-Output ""
    Write-ColorOutput Cyan "  [4]  版本检测      [5]  备份版本      [L]  更新日志"
    Write-ColorOutput DarkGray "      检查更新状态          保存当前版本          查看提交记录"
    Write-Output ""
    Write-ColorOutput DarkGray "  [6]  高级菜单"
    Write-ColorOutput DarkGray "      → 更多专业功能（拉取/编译/恢复/清理等）"
    Write-Output ""
    Write-ColorOutput Red "  [0]  退出"
    Write-Output ""
}

function Show-AdvancedMenu {
    Write-Header
    Write-ColorOutput Cyan "  高级菜单"
    Write-Output ""

    Write-ColorOutput Green "  [1] 拉取代码    [2] 应用汉化    [3] 编译程序"
    Write-ColorOutput DarkGray "      获取最新      只汉化不拉取   只编译不汉化"
    Write-Output ""
    Write-ColorOutput Yellow "  [4] 版本检测    [5] 备份版本    [6] 恢复备份    [H] 更新日志"
    Write-ColorOutput DarkGray "      检查Git状态   保存备份       选择性恢复      查看提交记录"
    Write-Output ""
    Write-ColorOutput Red "  [R] 源码恢复"
    Write-ColorOutput DarkGray "      → 强制重置到原始代码（丢失所有修改）"
    Write-Output ""
    Write-ColorOutput Cyan "  [7] 还原文件    [8] 打开目录    [9] 替换全局"
    Write-ColorOutput DarkGray "      撤销汉化      文件管理       更新opencode命令"
    Write-Output ""
    Write-ColorOutput Magenta "  [C] 清理工具    [L] 启动 OpenCode"
    Write-ColorOutput DarkGray "      清理缓存/临时文件          运行汉化版"
    Write-Output ""
    Write-ColorOutput DarkGray "  [S] 恢复脚本"
    Write-ColorOutput DarkGray "      → 从自动备份恢复管理脚本本身"
    Write-Output ""
    Write-ColorOutput DarkGray "  [0] 返回主菜单"
    Write-Output ""
}

# ==================== 辅助函数 ====================

function Test-Command {
    param([string]$Name)
    $null = Get-Command $Name -ErrorAction SilentlyContinue
    return $?
}

function Get-BunVersion {
    try {
        $versionOutput = & bun --version 2>&1
        if ($versionOutput -match '(\d+\.\d+\.\d+)') {
            return $matches[1]
        }
    } catch {
        return $null
    }
    return $null
}

function Show-Separator {
    Write-ColorOutput Cyan "────────────────────────────────────────────────────────────"
}

function Get-I18NConfig {
    <#
    .SYNOPSIS
        加载汉化配置（支持模块化结构）
    .DESCRIPTION
        优先加载模块化配置（opencode-i18n/config.json），
        如果不存在则回退到单文件模式（opencode-i18n.json）
    #>
    # 模块化配置路径
    $configPath = "$I18N_DIR\config.json"

    if (!(Test-Path $configPath)) {
        Write-ColorOutput Yellow "[提示] 模块化配置不存在: $configPath"
        Write-ColorOutput Yellow "正在尝试单文件模式..."
        # 回退到单文件模式
        if (!(Test-Path $I18N_CONFIG_OLD)) {
            Write-ColorOutput Red "[错误] 单文件配置也不存在: $I18N_CONFIG_OLD"
            return $null
        }
        try {
            $json = Get-Content $I18N_CONFIG_OLD -Raw -Encoding UTF8
            $config = $json | ConvertFrom-Json
            Write-ColorOutput Green "已加载单文件配置"
            return $config
        } catch {
            Write-ColorOutput Red "[错误] 单文件配置解析失败"
            return $null
        }
    }

    try {
        # 读取主配置
        $mainConfig = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        Write-ColorOutput Red "[错误] 主配置文件解析失败: $configPath"
        return $null
    }

    # 加载所有模块文件
    $allModules = @{}

    # 辅助函数：加载模块列表
    function Load-Modules {
        param(
            [string]$Category,
            [array]$ModuleList
        )
        foreach ($module in $ModuleList) {
            $modulePath = "$I18N_DIR\$module"
            if (Test-Path $modulePath) {
                try {
                    $moduleContent = Get-Content $modulePath -Raw -Encoding UTF8 | ConvertFrom-Json
                    # 生成模块名（从文件名提取，不含扩展名）
                    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($module)
                    # 添加分类前缀以避免同名冲突
                    $moduleKey = "$Category-$moduleName"
                    $allModules[$moduleKey] = $moduleContent
                } catch {
                    Write-ColorOutput Yellow "[警告] 模块加载失败: $module"
                }
            } else {
                Write-ColorOutput Yellow "[警告] 模块文件不存在: $modulePath"
            }
        }
    }

    # 加载各类模块
    if ($mainConfig.modules.dialogs) {
        Load-Modules -Category "dialogs" -ModuleList $mainConfig.modules.dialogs
    }
    if ($mainConfig.modules.routes) {
        Load-Modules -Category "routes" -ModuleList $mainConfig.modules.routes
    }
    if ($mainConfig.modules.components) {
        Load-Modules -Category "components" -ModuleList $mainConfig.modules.components
    }
    if ($mainConfig.modules.common) {
        Load-Modules -Category "common" -ModuleList $mainConfig.modules.common
    }

    # 返回整合后的配置（兼容旧格式）
    return @{
        version = $mainConfig.version
        description = $mainConfig.description
        lastUpdate = $mainConfig.lastUpdate
        patches = $allModules  # 使用 patches 键保持兼容性
        modules = $allModules  # 新增 modules 键
    }
}

# ==================== 版本检测与备份功能 ====================

function Get-VersionInfo {
    <#
    .SYNOPSIS
        获取版本信息，对比本地和远程
    #>
    if (!(Test-Path $SRC_DIR)) {
        return @{
            LocalCommit = "未知"
            RemoteCommit = "未知"
            NeedsUpdate = $false
            HasGit = $false
            SourceDirExists = $false
        }
    }

    Push-Location $SRC_DIR

    # 获取本地版本（确保只取成功输出的字符串）
    $localCommit = git rev-parse HEAD 2>&1
    $localCommit = if ($localCommit -is [System.Management.Automation.ErrorRecord]) { $null } else { $localCommit }
    $localCommitShort = if ($localCommit) { $localCommit.Substring(0, [Math]::Min(8, $localCommit.Length)) } else { "未知" }

    # 获取本地提交消息
    $localCommitMsg = git log -1 --pretty=format:"%s" HEAD 2>&1
    $localCommitMsg = if ($localCommitMsg -is [System.Management.Automation.ErrorRecord]) { "未知" } else { $localCommitMsg }
    if ($localCommitMsg.Length -gt 50) { $localCommitMsg = $localCommitMsg.Substring(0, 47) + "..." }

    # 获取本地提交日期（转换为北京时间 UTC+8）
    $localCommitDateRaw = git log -1 --pretty=format:"%ci" HEAD 2>&1
    $localCommitDateRaw = if ($localCommitDateRaw -is [System.Management.Automation.ErrorRecord]) { $null } else { $localCommitDateRaw }
    $localCommitDate = if ($localCommitDateRaw) {
        try {
            $dt = [DateTime]::Parse($localCommitDateRaw)
            $dt.ToUniversalTime().AddHours(8).ToString("yyyy-MM-dd HH:mm")
        } catch {
            "未知"
        }
    } else { "未知" }

    # 获取远程最新版本
    $null = git fetch origin --quiet 2>&1
    $remoteCommit = git rev-parse origin/dev 2>&1
    $remoteCommit = if ($remoteCommit -is [System.Management.Automation.ErrorRecord]) { $null } else { $remoteCommit }
    $remoteCommitShort = if ($remoteCommit) { $remoteCommit.Substring(0, [Math]::Min(8, $remoteCommit.Length)) } else { "未知" }

    # 获取远程提交消息
    $remoteCommitMsg = git log -1 --pretty=format:"%s" origin/dev 2>&1
    $remoteCommitMsg = if ($remoteCommitMsg -is [System.Management.Automation.ErrorRecord]) { "未知" } else { $remoteCommitMsg }
    if ($remoteCommitMsg.Length -gt 50) { $remoteCommitMsg = $remoteCommitMsg.Substring(0, 47) + "..." }

    # 获取远程提交日期（转换为北京时间 UTC+8）
    $remoteCommitDateRaw = git log -1 --pretty=format:"%ci" origin/dev 2>&1
    $remoteCommitDateRaw = if ($remoteCommitDateRaw -is [System.Management.Automation.ErrorRecord]) { $null } else { $remoteCommitDateRaw }
    $remoteCommitDate = if ($remoteCommitDateRaw) {
        try {
            $dt = [DateTime]::Parse($remoteCommitDateRaw)
            $dt.ToUniversalTime().AddHours(8).ToString("yyyy-MM-dd HH:mm")
        } catch {
            "未知"
        }
    } else { "未知" }

    # 检查是否需要更新
    $needsUpdate = $false
    if ($localCommit -and $remoteCommit) {
        $needsUpdate = $localCommit -ne $remoteCommit
    }

    Pop-Location

    return @{
        LocalCommit = $localCommitShort
        LocalCommitMessage = $localCommitMsg
        LocalCommitDate = $localCommitDate
        RemoteCommit = $remoteCommitShort
        RemoteCommitMessage = $remoteCommitMsg
        RemoteCommitDate = $remoteCommitDate
        NeedsUpdate = $needsUpdate
        HasGit = (Test-Path "$SRC_DIR\.git")
        SourceDirExists = $true
    }
}

function Show-VersionInfo {
    Write-Header
    Show-Separator
    Write-Output "   版本检测"
    Show-Separator
    Write-Output ""

    $info = Get-VersionInfo

    # 检查源码目录是否存在
    if (!$info.SourceDirExists) {
        Write-ColorOutput Red "   源码目录不存在"
        Write-Output "   期望路径: $SRC_DIR"
        Write-Output ""
        Write-ColorOutput Yellow "   请先初始化子模块："
        Write-ColorOutput Cyan "   git submodule update --init opencode-zh-CN"
        Write-Output ""
        Read-Host "按回车键继续"
        return
    }

    if (!$info.HasGit) {
        Write-ColorOutput Red "   不是一个 git 仓库"
        Write-Output ""
        Read-Host "按回车键继续"
        return
    }

    Write-Output "   本地版本:"
    Write-Output "     Commit: $($info.LocalCommit)"
    Write-Output "     消息: $($info.LocalCommitMessage)"
    Write-Output "     时间: $($info.LocalCommitDate)"
    Write-Output ""
    Write-Output "   远程版本:"
    Write-Output "     Commit: $($info.RemoteCommit)"
    Write-Output "     消息: $($info.RemoteCommitMessage)"
    Write-Output "     时间: $($info.RemoteCommitDate)"
    Write-Output ""

    if ($info.NeedsUpdate) {
        Write-ColorOutput Yellow "   √ 有新版本可用"
        Write-ColorOutput Cyan "   建议：运行 [1] 拉取最新代码"
    } else {
        Write-ColorOutput Green "   ✓ 已是最新版本"
    }

    Write-Output ""
    Read-Host "按回车键继续"
}

function Show-Changelog {
    <#
    .SYNOPSIS
        查看更新日志（交互式）
    .DESCRIPTION
        显示最近提交记录，支持选择查看详情、打开浏览器
    #>
    $info = Get-VersionInfo

    # 检查源码目录是否存在
    if (!$info.SourceDirExists) {
        Write-Header
        Show-Separator
        Write-Output "   更新日志"
        Show-Separator
        Write-Output ""
        Write-ColorOutput Red "   源码目录不存在"
        Write-Output "   期望路径: $SRC_DIR"
        Write-Output ""
        Write-ColorOutput Yellow "   请先初始化子模块："
        Write-ColorOutput Cyan "   git submodule update --init opencode-zh-CN"
        Write-Output ""
        Read-Host "按回车键继续"
        return
    }

    if (!$info.HasGit) {
        Write-Header
        Show-Separator
        Write-Output "   更新日志"
        Show-Separator
        Write-Output ""
        Write-ColorOutput Red "   不是一个 git 仓库"
        Write-Output ""
        Read-Host "按回车键继续"
        return
    }

    # 获取远程仓库 URL（用于打开浏览器）
    $repoUrl = $null
    Push-Location $SRC_DIR
    $remoteUrl = git remote get-url origin 2>&1
    if ($LASTEXITCODE -eq 0) {
        # 转换为浏览器 URL
        if ($remoteUrl -match "github\.com[:/](.+?)\.git") {
            $repoUrl = "https://github.com/$($matches[1])"
        } elseif ($remoteUrl -match "github\.com[:/](.+)") {
            $repoUrl = "https://github.com/$($matches[1])"
        }
    }
    Pop-Location

    # 主循环
    do {
        Write-Header
        Show-Separator
        Write-Output "   更新日志"
        Show-Separator
        Write-Output ""

        Push-Location $SRC_DIR

        # 获取最近15条提交（更多信息）
        $logFormat = "%H|%ci|%an|%s"
        $commitLogs = git log -15 --pretty=format:"$logFormat" HEAD 2>&1

        if ($LASTEXITCODE -ne 0) {
            Pop-Location
            Write-ColorOutput Red "   获取提交日志失败"
            Write-Output ""
            Read-Host "按回车键继续"
            return
        }

        Pop-Location

        # 解析日志到列表
        $commits = @()
        $logs = $commitLogs -split "`n" | Where-Object { $_ -match "^[a-f0-9]+\|" }

        foreach ($log in $logs) {
            $parts = $log -split "\|", 4
            if ($parts.Count -ge 4) {
                $commits += @{
                    Hash = $parts[0]
                    ShortHash = $parts[0].Substring(0, 8)
                    Time = $parts[1]
                    Author = $parts[2]
                    Message = $parts[3]
                }
            }
        }

        # 获取文件变更统计
        Push-Location $SRC_DIR
        for ($i = 0; $i -lt $commits.Count; $i++) {
            $stat = git diff-tree --shortstat $commits[$i].Hash 2>&1
            if ($stat -match "(\d+) file.*?(\d+) insert.*?(\d+) delete") {
                $commits[$i].Files = $matches[1]
                $commits[$i].Insertions = $matches[2]
                $commits[$i].Deletions = $matches[3]
            } elseif ($stat -match "(\d+) file.*?(\d+) insert") {
                $commits[$i].Files = $matches[1]
                $commits[$i].Insertions = $matches[2]
                $commits[$i].Deletions = "0"
            } else {
                $commits[$i].Files = "-"
                $commits[$i].Insertions = "-"
                $commits[$i].Deletions = "-"
            }
        }
        Pop-Location

        # 格式化时间函数（转换为北京时间 UTC+8）
        function Format-CommitTime {
            param([string]$isoTime)
            try {
                # 解析 ISO 8601 时间（包含时区）
                $commitDate = [DateTime]::Parse($isoTime)

                # 转换为北京时间 (UTC+8)
                $beijingTime = $commitDate.ToUniversalTime().AddHours(8)

                # 计算相对时间（基于本地时间）
                $localNow = Get-Date
                $diff = $localNow - $commitDate

                # 格式化北京时间
                $timeStr = $beijingTime.ToString("MM-dd HH:mm")

                # 相对时间显示
                if ($diff.TotalDays -lt 1) {
                    if ($diff.TotalHours -lt 1) {
                        if ($diff.TotalMinutes -lt 1) {
                            return "$timeStr (刚刚)"
                        }
                        return "$timeStr ($([int]$diff.TotalMinutes)分钟前)"
                    }
                    return "$timeStr ($([int]$diff.TotalHours)小时前)"
                } elseif ($diff.TotalDays -lt 7) {
                    return "$timeStr ($([int]$diff.TotalDays)天前)"
                }

                return $beijingTime.ToString("yyyy-MM-dd HH:mm")
            } catch {
                return $isoTime
            }
        }

        # 显示版本状态
        if ($info.NeedsUpdate) {
            $newCommits = git log --oneline "$($info.LocalCommit)..$($info.RemoteCommit)" 2>&1
            if ($LASTEXITCODE -eq 0) {
                $newCount = ($newCommits -split "`n" | Where-Object { $_ -match "^[a-f0-9]+" }).Count
                Write-ColorOutput Yellow "   √ 有 $newCount 个新提交 | 本地: $($info.LocalCommit)"
            }
        } else {
            Write-ColorOutput Green "   ✓ 已是最新版本 | $($info.LocalCommit)"
        }
        Write-Output ""

        # 显示提交列表
        Write-ColorOutput Cyan "   ┌────────────────────────────────────────────────────────────────────────"
        Write-ColorOutput Cyan "   │  #  Hash      │ 作者    │ 时间     │ 变更   │ 消息"
        Write-ColorOutput Cyan "   ├────────────────────────────────────────────────────────────────────────"

        $localFound = $false
        for ($i = 0; $i -lt $commits.Count; $i++) {
            $c = $commits[$i]
            $num = $i + 1

            # 检查是否是本地版本
            $isLocal = $c.Hash.StartsWith($info.LocalCommit)
            if ($isLocal) { $localFound = $true }

            # 格式化消息
            $msg = if ($c.Message.Length -gt 28) { $c.Message.Substring(0, 25) + "..." } else { $c.Message }

            # 格式化作者名
            $author = if ($c.Author.Length -gt 6) { $c.Author.Substring(0, 6) } else { $c.Author }

            # 格式化变更
            $changes = if ($c.Files -ne "-") { "+$($c.Insertions)/-$($c.Deletions)" } else { "-" }

            # 格式化时间（相对时间）
            $timeDisplay = Format-CommitTime $c.Time

            # 输出行
            if ($isLocal) {
                Write-ColorOutput Yellow ("   │  {0}. [{1}] │ {2,-6} │ {3,-7} │ {4,-6} │ {5}" -f $num, $c.ShortHash, $author, $timeDisplay, $changes, $msg)
            } else {
                Write-Output ("   │  {0}. [{1}] │ {2,-6} │ {3,-7} │ {4,-6} │ {5}" -f $num, $c.ShortHash, $author, $timeDisplay, $changes, $msg)
            }
        }

        Write-ColorOutput Cyan "   └────────────────────────────────────────────────────────────────────────"
        Write-Output ""

        # 如果本地版本不在列表中
        if (!$localFound) {
            Write-ColorOutput DarkGray "   (本地版本不在最近15条内)"
            Write-Output ""
        }

        # 操作提示
        Write-ColorOutput Cyan "   操作:"
        Write-Output "     [1-15] 查看提交详情"
        if ($repoUrl) {
            Write-Output "     [O]    在浏览器中打开最新提交"
        }
        Write-Output "     [R]    刷新列表"
        Write-Output "     [0]    返回主菜单"
        Write-Output ""

        $choice = Read-Host "   请选择"

        # 处理选择
        if ($choice -match "^\d+$" -and [int]$choice -ge 1 -and [int]$choice -le $commits.Count) {
            $idx = [int]$choice - 1
            Show-CommitDetail -Commit $commits[$idx] -RepoUrl $repoUrl
        } elseif ($choice -eq "O" -or $choice -eq "o") {
            if ($repoUrl -and $commits.Count -gt 0) {
                $url = "$repoUrl/commit/$($commits[0].Hash)"
                Start-Process $url
                Write-ColorOutput Green "   已打开浏览器: $url"
                Write-Output ""
                Read-Host "   按回车继续"
            } else {
                Write-ColorOutput Red "   无法获取仓库 URL"
                Write-Output ""
                Read-Host "   按回车继续"
            }
        } elseif ($choice -ne "R" -and $choice -ne "r" -and $choice -ne "0") {
            Write-ColorOutput DarkGray "   无效选择"
            Start-Sleep -Milliseconds 500
        }

    } while ($choice -eq "R" -or $choice -eq "r" -or ($choice -match "^\d+$" -and [int]$choice -ge 1 -and [int]$choice -le $commits.Count) -or $choice -eq "O" -or $choice -eq "o")
}

function Show-CommitDetail {
    <#
    .SYNOPSIS
        显示单个提交的详细信息
    #>
    param(
        [hashtable]$Commit,
        [string]$RepoUrl
    )

    Write-Header
    Show-Separator
    Write-Output "   提交详情"
    Show-Separator
    Write-Output ""

    # 基本信息
    Write-ColorOutput Cyan "   Commit: $($Commit.ShortHash)"
    Write-ColorOutput DarkGray "   $($Commit.Hash)"
    Write-Output ""
    Write-ColorOutput Cyan "   作者: $($Commit.Author)"

    # 格式化时间
    $formattedTime = Format-CommitTime $Commit.Time
    Write-ColorOutput Cyan "   时间: $formattedTime"
    Write-Output ""
    Write-ColorOutput Cyan "   消息:"
    Write-ColorOutput White ("   $($Commit.Message)")
    Write-Output ""

    # 变更统计
    Write-ColorOutput Cyan "   变更:"
    Write-ColorOutput DarkGray ("   文件: $($Commit.Files) | +$($Commit.Insertions)行 | -$($Commit.Deletions)行")
    Write-Output ""

    # 获取变更的文件列表
    Push-Location $SRC_DIR
    $fileChanges = git show --name-status --pretty="" $Commit.Hash 2>&1 | Where-Object { $_ -match "^[MAD]" }
    Pop-Location

    if ($fileChanges) {
        Write-ColorOutput Cyan "   文件列表:"
        foreach ($change in $fileChanges) {
            $parts = $change -split "`t"
            $status = $parts[0]
            $file = if ($parts.Count -gt 1) { $parts[1] } else { "" }

            $statusText = switch ($status) {
                "M" { "修改" }
                "A" { "新增" }
                "D" { "删除" }
                "R" { "重命名" }
                "C" { "复制" }
                default { $status }
            }
            $color = switch ($status) {
                "A" { "Green" }
                "D" { "Red" }
                "M" { "Yellow" }
                default { "DarkGray" }
            }

            # 只显示相对路径
            $displayFile = if ($file -match "packages/opencode/(.+)") { $matches[1] } else { $file }
            if ($displayFile.Length -gt 50) {
                $displayFile = "..." + $displayFile.Substring($displayFile.Length - 47)
            }

            Write-ColorOutput $color ("     [$statusText] $displayFile")
        }
        Write-Output ""
    }

    # 操作选项
    Write-ColorOutput Cyan "   操作:"
    if ($RepoUrl) {
        $url = "$RepoUrl/commit/$($Commit.Hash)"
        Write-Output "     [O] 在浏览器中打开"
        Write-ColorOutput DarkGray "         $url"
    }
    Write-Output "     [H] 查看完整 diff"
    Write-Output "     [0] 返回"
    Write-Output ""

    $detailChoice = Read-Host "   请选择"

    if ($detailChoice -eq "O" -or $detailChoice -eq "o") {
        if ($RepoUrl) {
            Start-Process $url
            Write-ColorOutput Green "   已打开浏览器"
            Write-Output ""
            Read-Host "   按回车继续"
        }
    } elseif ($detailChoice -eq "H" -or $detailChoice -eq "h") {
        # 显示完整 diff
        Write-Output ""
        Write-ColorOutput Cyan "   完整 Diff:"
        Write-Output ""

        Push-Location $SRC_DIR
        $diff = git show $Commit.Hash 2>&1
        Pop-Location

        # 分页显示
        $lines = $diff -split "`n"
        $page = 0
        $pageSize = 30

        for ($i = 0; $i -lt $lines.Count; $i += $pageSize) {
            Clear-Host
            Write-Header
            Show-Separator
            Write-Output "   Diff: $($Commit.ShortHash) - 第 $($page + 1) 页"
            Show-Separator
            Write-Output ""

            $end = [Math]::Min($i + $pageSize, $lines.Count)
            for ($j = $i; $j -lt $end; $j++) {
                $line = $lines[$j]
                if ($line -match "^[\+\-]") {
                    if ($line -match "^\+") {
                        Write-ColorOutput Green $line
                    } else {
                        Write-ColorOutput Red $line
                    }
                } else {
                    Write-Output $line
                }
            }

            Write-Output ""
            if ($end -lt $lines.Count) {
                Read-Host "按回车继续..."
                $page++
            } else {
                Read-Host "到底了，按回车返回"
                break
            }
        }
    }
}

function Backup-All {
    <#
    .SYNOPSIS
        备份源码和编译产物（支持自定义名称 + 版本号）
    #>
    Write-Header
    Show-Separator
    Write-Output "   备份源码和编译产物"
    Show-Separator
    Write-Output ""

    # 获取版本信息
    $versionInfo = Get-VersionInfo
    $versionTag = if ($versionInfo.HasGit) {
        "v$($versionInfo.LocalCommit)"
    } else {
        "no-git"
    }

    Write-ColorOutput Cyan "当前版本: $versionTag"
    Write-Output ""

    # 询问备份名称
    $customName = Read-Host "输入备份名称 (留空使用默认格式)"
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

    if ($customName -and $customName.Trim() -ne "") {
        # 自定义名称 + 版本号
        $backupName = "$customName`_$versionTag"
    } else {
        # 默认格式：时间戳_版本号
        $backupName = "${timestamp}_$versionTag"
    }

    $backupPath = "$BACKUP_DIR\$backupName"

    Write-ColorOutput Cyan "正在备份到: $backupPath"
    Write-Output ""

    # 创建备份目录
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

    # 询问是否备份完整源码
    Write-ColorOutput Yellow "是否备份完整源码？(纯净版，约81MB)"
    Write-Output "  [1] 是 - 备份完整源码"
    Write-Output "  [2] 否 - 只备份汉化文件"
    $sourceBackupChoice = Read-Host "请选择"

    if ($sourceBackupChoice -eq "1") {
        # 备份完整源码
        Write-ColorOutput Yellow "正在备份源码..."
        $sourceBackup = "$backupPath\source"
        New-Item -ItemType Directory -Path $sourceBackup -Force | Out-Null
        # 使用 Copy-Item 替代 robocopy，排除 node_modules 和 dist
        Get-ChildItem $SRC_DIR -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            $relPath = $_.FullName.Substring($SRC_DIR.Length + 1)
            # 排除 node_modules、dist 和 nul 文件
            if ($relPath -match '^node_modules\\' -or $relPath -match '^dist\\' -or $relPath -eq 'nul') { return }
            $destPath = "$sourceBackup\$relPath"
            $destDir = Split-Path $destPath -Parent
            if (!(Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
            if ($_.PSIsContainer -eq $false) {
                Copy-Item $_.FullName $destPath -Force -ErrorAction SilentlyContinue
            }
        }
        Write-ColorOutput Green "   - 源码: 已备份 (排除 node_modules/dist)"

        # 询问是否备份 node_modules（环境备份）
        Write-Output ""
        Write-ColorOutput Yellow "是否备份 node_modules？(依赖环境，约1-2GB，但恢复很快)"
        Write-Output "  [1] 是 - 备份依赖环境"
        Write-Output "  [2] 否 - 跳过（可以用 bun install 重新安装）"
        $depsBackupChoice = Read-Host "请选择"

        if ($depsBackupChoice -eq "1") {
            Write-ColorOutput Yellow "正在备份 node_modules (这可能需要几分钟)..."
            $depsBackup = "$backupPath\node_modules"
            New-Item -ItemType Directory -Path $depsBackup -Force | Out-Null

            # 使用 robocopy 快速复制（如果可用）或 Copy-Item
            $robocopyAvailable = Get-Command robocopy -ErrorAction SilentlyContinue
            if ($robocopyAvailable) {
                # 使用 robocopy 的 /E 参数复制所有子目录，/XD 排除 .bun 缓存
                $robocopyResult = robocopy "$SRC_DIR\node_modules" $depsBackup /E /XD ".bun" /NFL /NDL /NJH /NJS 2>&1
            } else {
                # 回退到 Copy-Item
                Copy-Item "$SRC_DIR\node_modules" $depsBackup -Recurse -Force -ErrorAction SilentlyContinue
            }

            $depsSize = (Get-ChildItem $depsBackup -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
            Write-ColorOutput Green "   - node_modules: 已备份 ({0:N2} GB)" -f $depsSize
        }
    }

    # 备份源码中的 TUI 文件（已汉化的）
    $tuiBackup = "$backupPath\tui"
    if (Test-Path "$PACKAGE_DIR\src\cli\cmd\tui") {
        Copy-Item "$PACKAGE_DIR\src\cli\cmd\tui" $tuiBackup -Recurse -Force
        $tuiFiles = (Get-ChildItem $tuiBackup -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-ColorOutput Green "   - TUI 文件: $tuiFiles 个"
    }

    # 备份编译产物
    $exeBackup = "$backupPath\compiled"
    if (Test-Path "$OUT_DIR\opencode.exe") {
        New-Item -ItemType Directory -Path $exeBackup -Force | Out-Null
        Copy-Item "$OUT_DIR\opencode.exe" "$exeBackup\" -Force
        Copy-Item $I18N_CONFIG "$exeBackup\" -Force -ErrorAction SilentlyContinue
        Write-ColorOutput Green "   - 编译产物: 已备份"
    }

    # 备份配置
    $configBackup = "$backupPath\config"
    New-Item -ItemType Directory -Path $configBackup -Force | Out-Null
    Copy-Item $I18N_CONFIG "$configBackup\" -Force

    # 保存版本信息到文件
    $versionInfoFile = "$backupPath\version.txt"
    $versionContent = @"
备份名称: $backupName
创建时间: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
本地版本: $($versionInfo.LocalCommit)
远程版本: $($versionInfo.RemoteCommit)
是否最新: if ($versionInfo.NeedsUpdate) { "否" } else { "是" }
"@
    $versionContent | Out-File -FilePath $versionInfoFile -Encoding UTF8

    Write-Output ""
    Write-ColorOutput Green "备份完成！"
    Write-Output "   备份位置: $backupPath"
    Write-Output ""

    # 显示备份列表
    Write-ColorOutput Cyan "现有备份:"
    if (!(Test-Path $BACKUP_DIR)) {
        Write-ColorOutput DarkGray "   (暂无备份)"
    } else {
        $backups = Get-ChildItem $BACKUP_DIR -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 5
        if ($backups) {
            foreach ($b in $backups) {
                $size = (Get-ChildItem $b.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
                $versionFile = "$($b.FullName)\version.txt"
                $versionInfoText = if (Test-Path $versionFile) {
                    $lines = Get-Content $versionFile -First 3
                    $lines[2]  # 本地版本行
                } else {
                    $b.Name
                }
                Write-Output "   - $($b.Name)"
                $sizeStr = "{0:N2}" -f $size
                Write-ColorOutput DarkGray ("      " + $versionInfoText + " (" + $sizeStr + " MB)")
            }
        } else {
            Write-ColorOutput DarkGray "   (暂无备份)"
        }
    }

    Write-Output ""
    Read-Host "按回车键继续"
}

function Restore-Source {
    <#
    .SYNOPSIS
        源码恢复 - 强制重置到最新远程版本
    .DESCRIPTION
        当源码被破坏或需要恢复到未修改的原始状态时使用
        此操作会丢弃所有本地更改！
    #>
    Write-Header
    Show-Separator
    Write-Output "   源码恢复 (强制重置)"
    Show-Separator
    Write-Output ""

    Write-ColorOutput Red "警告：此操作将强制重置源码到最新远程版本！"
    Write-ColorOutput Red "      所有本地修改将会丢失！"
    Write-Output ""

    if (!(Test-Path $SRC_DIR)) {
        Write-ColorOutput Red "[错误] 源码目录不存在: $SRC_DIR"
        Read-Host "按回车键继续"
        return
    }

    Push-Location $SRC_DIR
    if (!(Test-Path ".git")) {
        Write-ColorOutput Red "[错误] 不是一个 git 仓库"
        Pop-Location
        Read-Host "按回车键继续"
        return
    }
    Pop-Location

    # 显示当前状态
    Push-Location $SRC_DIR
    $versionInfo = Get-VersionInfo
    Write-ColorOutput Cyan "当前状态:"
    Write-Output "  本地版本: $($versionInfo.LocalCommit)"
    Write-Output "  远程版本: $($versionInfo.RemoteCommit)"
    if ($versionInfo.NeedsUpdate) {
        Write-ColorOutput Yellow "  √ 有新版本可用"
    } else {
        Write-ColorOutput Green "  ✓ 已是最新版本"
    }
    Write-Output ""

    # 检查是否有未提交的更改
    $gitStatus = git status --short 2>&1
    if ($gitStatus) {
        Write-ColorOutput Yellow "检测到未提交的更改:"
        $gitStatus | Write-Output
        Write-Output ""
    }

    Pop-Location

    $confirm1 = Read-Host "确定要继续吗？(yes/NO)"
    if ($confirm1 -ne "yes" -and $confirm1 -ne "YES" -and $confirm1 -ne "y") {
        Write-Output "已取消"
        Write-Output ""
        Read-Host "按回车键继续"
        return
    }

    Write-Output ""
    $confirm2 = Read-Host "再次确认：这将丢弃所有本地修改！继续？(yes/NO)"
    if ($confirm2 -ne "yes" -and $confirm2 -ne "YES" -and $confirm2 -ne "y") {
        Write-Output "已取消"
        Write-Output ""
        Read-Host "按回车键继续"
        return
    }

    Write-Output ""
    Write-ColorOutput Yellow "正在恢复源码..."
    Push-Location $SRC_DIR

    # 步骤 1: 清理未追踪的文件
    Write-ColorOutput Cyan "   - 清理未追踪文件..."
    $null = git clean -fdx 2>&1

    # 步骤 2: 重置到远程分支
    Write-ColorOutput Cyan "   - 重置到远程版本..."
    $null = git fetch origin 2>&1
    git reset --hard origin/dev 2>&1 | Out-Host

    # 步骤 3: 拉取最新代码
    Write-ColorOutput Cyan "   - 拉取最新代码..."

    # 处理代理问题
    $result = git pull 2>&1
    $success = $LASTEXITCODE -eq 0

    if (!$success -and ($result -match "127\.0\.0\.1" -or $result -match "proxy")) {
        Write-ColorOutput Yellow "   检测到代理问题，自动修复..."
        $oldProxy = git config --get http.proxy
        git config --unset http.proxy
        git config --unset https.proxy
        $result = git pull 2>&1
        $success = $LASTEXITCODE -eq 0
        if ($oldProxy) { git config http.proxy $oldProxy }
    }

    Pop-Location

    Write-Output ""
    if ($success) {
        Write-ColorOutput Green "源码恢复完成！"
        Write-Output ""
        Write-ColorOutput Yellow "现在可以执行以下操作:"
        Write-Output "  1. 运行 [2] 应用汉化补丁"
        Write-Output "  2. 运行 [3] 编译程序"
    } else {
        Write-ColorOutput Red "恢复失败，请检查网络连接"
    }

    Write-Output ""
    Read-Host "按回车键继续"
}

function Restore-Backup {
    <#
    .SYNOPSIS
        从备份恢复（选择性恢复）
    #>
    Write-Header
    Show-Separator
    Write-Output "   从备份恢复"
    Show-Separator
    Write-Output ""

    if (!(Test-Path $BACKUP_DIR)) {
        Write-ColorOutput Red "备份目录不存在: $BACKUP_DIR"
        Write-Output "请先执行 [5] 备份当前版本"
        Write-Output ""
        Read-Host "按回车键继续"
        return
    }

    $backups = Get-ChildItem $BACKUP_DIR -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if (!$backups) {
        Write-ColorOutput Red "没有找到备份"
        Write-Output ""
        Read-Host "按回车键继续"
        return
    }

    Write-ColorOutput Cyan "可用备份:"
    Write-Output ""

    for ($i = 0; $i -lt $backups.Count; $i++) {
        $b = $backups[$i]
        $versionFile = "$($b.FullName)\version.txt"
        $infoStr = if (Test-Path $versionFile) {
            $lines = Get-Content $versionFile -First 2 -ErrorAction SilentlyContinue
            if ($lines) { $lines[0] } else { $b.Name }
        } else {
            $b.Name
        }
        Write-Output "  [$($i+1)] $($b.Name)"
        Write-ColorOutput DarkGray "      $infoStr"
    }

    Write-Output ""
    $selection = Read-Host "选择备份 (0 取消)"

    if ($selection -eq "0" -or !$selection) { return }

    $index = [int]$selection - 1
    if ($index -lt 0 -or $index -ge $backups.Count) {
        Write-ColorOutput Red "无效选择"
        Read-Host "按回车键继续"
        return
    }

    $selectedBackup = $backups[$index].FullName

    Write-Output ""
    Write-ColorOutput Cyan "备份内容:"
    Write-Output ""

    # 检查备份中有什么内容
    $hasTui = Test-Path "$selectedBackup\tui"
    $hasCompiled = Test-Path "$selectedBackup\compiled"
    $hasConfig = Test-Path "$selectedBackup\config"
    $hasSource = Test-Path "$selectedBackup\source"
    $hasNodeModules = Test-Path "$selectedBackup\node_modules"

    if ($hasTui) { Write-Output "  [1] TUI 汉化文件" }
    if ($hasCompiled) { Write-Output "  [2] 编译产物 (opencode.exe)" }
    if ($hasConfig) { Write-Output "  [3] 配置文件 (opencode-i18n.json)" }
    if ($hasSource) { Write-Output "  [4] 完整源码" }
    if ($hasNodeModules) { Write-ColorOutput Yellow "  [5] node_modules 依赖环境" }
    Write-Output "  [A] 全部恢复"
    Write-Output ""

    $restoreChoice = Read-Host "选择要恢复的内容"

    if ($restoreChoice -eq "0" -or !$restoreChoice) {
        Write-Output "已取消"
        Read-Host "按回车键继续"
        return
    }

    Write-Output ""
    Write-ColorOutput Yellow "确定要恢复吗？"
    $confirm = Read-Host "确认？(y/N)"

    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Output "已取消"
        Read-Host "按回车键继续"
        return
    }

    Write-Output ""
    Write-ColorOutput Cyan "正在恢复..."

    # 选择性恢复
    if ($restoreChoice -eq "1" -or $restoreChoice -eq "a" -or $restoreChoice -eq "A") {
        # 恢复 TUI 文件
        if ($hasTui) {
            Copy-Item "$selectedBackup\tui\*" "$PACKAGE_DIR\src\cli\cmd\tui\" -Recurse -Force
            Write-ColorOutput Green "   - TUI 文件已恢复"
        }
    }

    if ($restoreChoice -eq "2" -or $restoreChoice -eq "a" -or $restoreChoice -eq "A") {
        # 恢复编译产物
        if ($hasCompiled) {
            Copy-Item "$selectedBackup\compiled\opencode.exe" "$OUT_DIR\" -Force
            Write-ColorOutput Green "   - 编译产物已恢复"
        }
    }

    if ($restoreChoice -eq "3" -or $restoreChoice -eq "a" -or $restoreChoice -eq "A") {
        # 恢复配置
        if ($hasConfig) {
            Copy-Item "$selectedBackup\config\*" "$OUT_DIR\" -Force -ErrorAction SilentlyContinue
            Write-ColorOutput Green "   - 配置文件已恢复"
        }
    }

    if ($restoreChoice -eq "4" -or $restoreChoice -eq "a" -or $restoreChoice -eq "A") {
        # 恢复完整源码
        if ($hasSource) {
            # 先确认，因为这是危险操作
            Write-ColorOutput Yellow "   警告：恢复源码将覆盖当前源码目录！"
            $sourceConfirm = Read-Host "   继续？(y/N)"
            if ($sourceConfirm -eq "y" -or $sourceConfirm -eq "Y") {
                Write-ColorOutput Yellow "   正在恢复源码..."
                Copy-Item "$selectedBackup\source\*" "$SRC_DIR\" -Recurse -Force
                Write-ColorOutput Green "   - 源码已恢复"
            }
        }
    }

    if ($restoreChoice -eq "5" -or $restoreChoice -eq "a" -or $restoreChoice -eq "A") {
        # 恢复 node_modules
        if ($hasNodeModules) {
            Write-ColorOutput Yellow "   正在恢复 node_modules (可能需要几分钟)..."
            # 删除现有的 node_modules
            if (Test-Path "$SRC_DIR\node_modules") {
                Remove-Item "$SRC_DIR\node_modules" -Recurse -Force -ErrorAction SilentlyContinue
            }
            # 复制备份
            $robocopyAvailable = Get-Command robocopy -ErrorAction SilentlyContinue
            if ($robocopyAvailable) {
                robocopy "$selectedBackup\node_modules" "$SRC_DIR\node_modules" /E /NFL /NDL /NJH /NJS 2>&1 | Out-Null
            } else {
                Copy-Item "$selectedBackup\node_modules" "$SRC_DIR\" -Recurse -Force
            }
            Write-ColorOutput Green "   - node_modules 已恢复"
        }
    }

    Write-Output ""
    Write-ColorOutput Green "恢复完成！"
    Write-Output ""
    Read-Host "按回车键继续"
}

# ==================== 功能函数 ====================

function Update-Source {
    Write-Header
    Show-Separator
    Write-Output "   拉取最新代码"
    Show-Separator
    Write-Output ""

    if (!(Test-Path $SRC_DIR)) {
        Write-ColorOutput Red "[错误] 源码目录不存在: $SRC_DIR"
        Read-Host "按回车键继续"
        return
    }

    Push-Location $SRC_DIR
    if (!(Test-Path ".git")) {
        Write-ColorOutput Red "[错误] 不是一个 git 仓库"
        Pop-Location
        Read-Host "按回车键继续"
        return
    }

    Write-ColorOutput Yellow "正在拉取最新代码..."

    # 尝试 git pull
    $result = git pull 2>&1
    $success = $LASTEXITCODE -eq 0

    if (!$success) {
        # 检查是否是代理错误
        if ($result -match "127\.0\.0\.1" -or $result -match "proxy" -or $result -match "Could not connect") {
            Write-ColorOutput Yellow "检测到代理问题，尝试自动修复..."

            # 临时清除代理
            $oldHttpProxy = git config --get http.proxy
            $oldHttpsProxy = git config --get https.proxy

            git config --unset http.proxy
            git config --unset https.proxy

            Write-ColorOutput Yellow "重试拉取..."
            $result = git pull 2>&1
            $success = $LASTEXITCODE -eq 0

            # 恢复代理设置（如果之前有）
            if ($oldHttpProxy) {
                git config http.proxy $oldHttpProxy
            }
            if ($oldHttpsProxy) {
                git config https.proxy $oldHttpsProxy
            }
        }
    }

    Pop-Location

    if ($success) {
        Write-ColorOutput Green "代码更新完成！"
    } else {
        Write-ColorOutput Yellow "git pull 失败（可能网络问题），但不影响汉化"
    }

    Write-Output ""
    Read-Host "按回车键继续"
}

function Apply-SinglePatch {
    param(
        [string]$Name,
        [string]$File,
        [hashtable]$Replacements,
        [string]$Description
    )

    $targetFile = "$PACKAGE_DIR\$File"

    if (!(Test-Path $targetFile)) {
        Write-ColorOutput Red "   文件不存在: $targetFile"
        return $false
    }

    # 备份原文件
    $bakFile = "$targetFile.bak"
    if (!(Test-Path $bakFile)) {
        Copy-Item $targetFile $bakFile -Force
        Write-Output "   - 已备份: $(Split-Path $File -Leaf)"
    }

    # 读取并替换内容
    $content = Get-Content $targetFile -Raw -Encoding UTF8
    $count = 0

    foreach ($key in $Replacements.Keys) {
        $originalContent = $content
        # 使用字符串替换，不使用正则（精确匹配）
        $content = $content.Replace($key, $Replacements[$key])
        if ($content -ne $originalContent) {
            $count++
        }
    }

    $content | Set-Content $targetFile -Encoding UTF8 -NoNewline

    if ($Description) {
        Write-ColorOutput Green "   - $Description ($count 项替换)"
    } else {
        Write-ColorOutput Green "   - $Name ($count 项替换)"
    }

    return $true
}

function Apply-CommandPanelPatch {
    <#
    .SYNOPSIS
        应用命令面板汉化补丁
    .DESCRIPTION
        在模块化配置中查找 command-panel 模块并应用
    #>
    $config = Get-I18NConfig
    if (!$config) {
        Write-ColorOutput Red "[错误] 无法加载汉化配置"
        return
    }

    # 在模块化配置中查找 command-panel 模块
    # 可能的键名: commandPanel (旧格式) 或 components-command-panel (新格式)
    $patch = $null
    $patchKey = $null

    if ($config.patches) {
        # 尝试新格式（带分类前缀）
        if ($config.patches["components-command-panel"]) {
            $patchKey = "components-command-panel"
            $patch = $config.patches[$patchKey]
        }
        # 尝试旧格式
        elseif ($config.patches.PSObject.Properties.Name -contains "commandPanel") {
            $patchKey = "commandPanel"
            $patch = $config.patches.$patchKey
        }
    }

    if (!$patch) {
        Write-ColorOutput Red "[错误] 无法找到命令面板汉化配置"
        Write-ColorOutput Yellow "请检查 opencode-i18n/components/command-panel.json 是否存在"
        return
    }

    Write-ColorOutput Yellow "[1/$($config.patches.Count)] 应用命令面板汉化..."

    $replacements = @{}

    # 将 JSON 对象转换为 hashtable
    if ($patch.replacements) {
        if ($patch.replacements -is [System.Management.Automation.PSCustomObject]) {
            $patch.replacements.PSObject.Properties | ForEach-Object {
                $replacements[$_.Name] = $_.Value
            }
        } elseif ($patch.replacements -is [hashtable]) {
            $replacements = $patch.replacements
        }
    }

    Apply-SinglePatch -Name "命令面板" -File $patch.file -Replacements $replacements -Description $patch.description
}

function Apply-OtherPatches {
    <#
    .SYNOPSIS
        应用除命令面板外的其他汉化补丁
    .DESCRIPTION
        遍历所有模块并应用汉化，排除已单独处理的命令面板
    #>
    $config = Get-I18NConfig
    if (!$config -or !$config.patches) {
        Write-ColorOutput Red "[错误] 无法加载汉化配置"
        return
    }

    # 获取所有模块，排除命令面板（已单独处理）
    # 兼容新旧格式：commandPanel (旧) 和 components-command-panel (新)
    $allModules = @()

    # 判断 patches 是否是 hashtable
    if ($config.patches -is [hashtable]) {
        $allModules = @($config.patches.Keys | Where-Object {
            $_ -ne "commandPanel" -and $_ -ne "components-command-panel"
        })
    } else {
        # PSObject 格式（旧配置）
        $allModules = @($config.patches.PSObject.Properties.Name | Where-Object {
            $_ -ne "commandPanel" -and $_ -ne "components-command-panel"
        })
    }

    $totalCount = $allModules.Count
    $currentIndex = 0

    foreach ($patchKey in $allModules) {
        $currentIndex++
        $patch = $null

        # 兼容 hashtable 和 PSObject
        if ($config.patches -is [hashtable]) {
            $patch = $config.patches[$patchKey]
        } else {
            $patch = $config.patches.$patchKey
        }

        if (!$patch) { continue }

        Write-ColorOutput Yellow "[$currentIndex/$totalCount] 应用 $($patch.description)..."

        $replacements = @{}

        # 将 replacements 转换为 hashtable
        if ($patch.replacements) {
            if ($patch.replacements -is [System.Management.Automation.PSCustomObject]) {
                $patch.replacements.PSObject.Properties | ForEach-Object {
                    $replacements[$_.Name] = $_.Value
                }
            } elseif ($patch.replacements -is [hashtable]) {
                $replacements = $patch.replacements
            }
        }

        Apply-SinglePatch -Name $patchKey -File $patch.file -Replacements $replacements -Description $patch.description
    }

    Write-ColorOutput Green "所有汉化补丁已应用！"
}

function Test-I18NPatches {
    <#
    .SYNOPSIS
        验证汉化补丁是否成功应用
    .DESCRIPTION
        检查目标文件是否包含预期的中文翻译，返回验证结果
    #>
    Write-Header
    Show-Separator
    Write-Output "   验证汉化补丁"
    Show-Separator
    Write-Output ""

    $config = Get-I18NConfig
    if (!$config) {
        Read-Host "按回车键继续"
        return
    }

    $totalTests = 0
    $passedTests = 0
    $failedItems = @()

    Write-ColorOutput Cyan "正在验证汉化结果..."
    Write-Output ""

    # 获取所有模块键名（兼容 hashtable 和 PSObject）
    $patchKeys = @()
    if ($config.patches -is [hashtable]) {
        $patchKeys = @($config.patches.Keys)
    } else {
        $patchKeys = @($config.patches.PSObject.Properties.Name)
    }

    foreach ($patchKey in $patchKeys) {
        $patch = $null
        # 兼容 hashtable 和 PSObject
        if ($config.patches -is [hashtable]) {
            $patch = $config.patches[$patchKey]
        } else {
            $patch = $config.patches.$patchKey
        }

        if (!$patch -or !$patch.file) { continue }

        $targetFile = "$PACKAGE_DIR\$($patch.file)"

        if (!(Test-Path $targetFile)) {
            Write-ColorOutput Red "   [$patchKey] 文件不存在: $($patch.file)"
            continue
        }

        $content = Get-Content $targetFile -Raw -Encoding UTF8
        $patchPassed = $true
        $patchFailed = @()

        # 获取 replacements
        $replacements = $patch.replacements
        if ($replacements -is [System.Management.Automation.PSCustomObject]) {
            $replacementsProps = $replacements.PSObject.Properties
        } elseif ($replacements -is [hashtable]) {
            $replacementsProps = $replacements.GetEnumerator()
        } else {
            continue
        }

        foreach ($replacement in $replacementsProps) {
            $totalTests++
            $original = if ($replacement -is [System.Management.Automation.PSPropertyInfo]) {
                $replacement.Name
            } else {
                $replacement.Key
            }
            $expected = if ($replacement -is [System.Management.Automation.PSPropertyInfo]) {
                $replacement.Value
            } else {
                $replacement.Value
            }

            # 检查文件中是否包含翻译后的文本
            if ($content -like "*$expected*") {
                $passedTests++
            } else {
                $patchPassed = $false
                $patchFailed += @{
                    Original = $original
                    Expected = $expected
                }
            }
        }

        if ($patchPassed) {
            Write-ColorOutput Green "   [$patchKey] ✓ 通过"
        } else {
            Write-ColorOutput Red "   [$patchKey] ✗ 失败 ($($patchFailed.Count) 项未生效)"
            $failedItems += @{
                Module = $patchKey
                File = $patch.file
                Failures = $patchFailed
            }
        }
    }

    Write-Output ""
    Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if ($failedItems.Count -eq 0) {
        Write-ColorOutput Green "✓ 所有汉化验证通过！($passedTests/$totalTests)"
    } else {
        Write-ColorOutput Red "✗ 汉化验证失败！($passedTests/$totalTests 通过)"
        Write-Output ""
        Write-ColorOutput Yellow "失败的模块:"
        foreach ($item in $failedItems) {
            Write-Output "  [$($item.Module)] $($item.File)"
            Write-ColorOutput Yellow "    失败项 (前3个):"
            for ($i = 0; $i -lt [Math]::Min(3, $item.Failures.Count); $i++) {
                $f = $item.Failures[$i]
                Write-Output "      原文: $($f.Original)"
                Write-Output "      期望: $($f.Expected)"
            }
        }
        Write-Output ""
        Write-ColorOutput Yellow "可能原因:"
        Write-Output "  1. 原文已被更新，请检查源文件"
        Write-Output "  2. 配置文件中的匹配模式需要调整"
        Write-Output "  3. 运行 [3] 调试工具 查看详情"
    }

    Write-Output ""
    Read-Host "按回车键继续"

    return $failedItems.Count -eq 0
}

function Debug-I18NFailure {
    <#
    .SYNOPSIS
        汉化失败调试工具
    .DESCRIPTION
        帮助定位汉化失败的原因，显示原文内容上下文
    #>
    Write-Header
    Show-Separator
    Write-Output "   汉化调试工具"
    Show-Separator
    Write-Output ""

    $config = Get-I18NConfig
    if (!$config) {
        Read-Host "按回车键继续"
        return
    }

    Write-ColorOutput Cyan "选择要调试的模块:"
    Write-Output ""

    # 获取所有模块键名（兼容 hashtable 和 PSObject）
    $patches = @()
    if ($config.patches -is [hashtable]) {
        $patches = @($config.patches.Keys)
    } else {
        $patches = @($config.patches.PSObject.Properties.Name)
    }

    for ($i = 0; $i -lt $patches.Count; $i++) {
        $patch = if ($config.patches -is [hashtable]) {
            $config.patches[$patches[$i]]
        } else {
            $config.patches.($patches[$i])
        }
        Write-Output "  [$($i+1)] $($patches[$i]) - $($patch.description)"
    }
    Write-Output "  [0] 返回"
    Write-Output ""

    $selection = Read-Host "请选择"
    if ($selection -eq "0" -or !$selection) {
        return
    }

    $index = [int]$selection - 1
    if ($index -lt 0 -or $index -ge $patches.Count) {
        Write-ColorOutput Red "无效选择"
        Read-Host "按回车键继续"
        return
    }

    $patchKey = $patches[$index]
    $patch = if ($config.patches -is [hashtable]) {
        $config.patches[$patchKey]
    } else {
        $config.patches.$patchKey
    }
    $targetFile = "$PACKAGE_DIR\$($patch.file)"

    if (!(Test-Path $targetFile)) {
        Write-ColorOutput Red "文件不存在: $targetFile"
        Read-Host "按回车键继续"
        return
    }

    Write-Output ""
    Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-ColorOutput Cyan "模块: $patchKey"
    Write-ColorOutput Cyan "文件: $($patch.file)"
    Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Output ""

    $content = Get-Content $targetFile -Raw -Encoding UTF8

    # 获取 replacements（兼容不同格式）
    $replacements = $patch.replacements
    if ($replacements -is [System.Management.Automation.PSCustomObject]) {
        $replacementsProps = $replacements.PSObject.Properties
    } elseif ($replacements -is [hashtable]) {
        $replacementsProps = $replacements.GetEnumerator()
    } else {
        Write-ColorOutput Red "无法读取替换配置"
        Read-Host "按回车键继续"
        return
    }

    foreach ($replacement in $replacementsProps) {
        $original = if ($replacement -is [System.Management.Automation.PSPropertyInfo]) {
            $replacement.Name
        } else {
            $replacement.Key
        }
        $expected = if ($replacement -is [System.Management.Automation.PSPropertyInfo]) {
            $replacement.Value
        } else {
            $replacement.Value
        }

        $hasOriginal = $content -like "*$original*"
        $hasExpected = $content -like "*$expected*"

        if ($hasExpected) {
            Write-ColorOutput Green "  ✓ $original → $expected"
        } elseif ($hasOriginal) {
            Write-ColorOutput Red "  ✗ $original → $expected"
            Write-ColorOutput Yellow "    状态: 原文存在但替换失败"
        } else {
            Write-ColorOutput Yellow "  ? $original → $expected"
            Write-ColorOutput Yellow "    状态: 原文不存在（可能已更新）"
        }
    }

    Write-Output ""
    Write-ColorOutput Yellow "调试建议:"
    Write-Output "  1. 如果'原文不存在'，需要更新配置中的匹配模式"
    Write-Output "  2. 运行 [0] 退出后用编辑器打开源文件查看实际内容"
    Write-Output "  3. 配置文件路径: $I18N_DIR"
    Write-Output ""

    $openFile = Read-Host "是否打开源文件查看？(Y/n)"
    if ($openFile -ne "n" -and $openFile -ne "N") {
        & code $targetFile 2>&1 | Out-Null
        if (!$?) {
            & notepad $targetFile
        }
    }

    Write-Output ""
    Read-Host "按回车键继续"
}

function Apply-Patches {
    Write-Header
    Show-Separator
    Write-Output "   应用汉化补丁"
    Show-Separator
    Write-Output ""

    if (!(Test-Path $PACKAGE_DIR)) {
        Write-ColorOutput Red "[错误] 包目录不存在: $PACKAGE_DIR"
        Read-Host "按回车键继续"
        return
    }

    Apply-CommandPanelPatch
    Apply-OtherPatches

    Write-Output ""
    Write-ColorOutput Green "汉化补丁应用完成！"
    Write-Output ""
    Read-Host "按回车键继续"
}

function Build-Project {
    param([switch]$Quiet = $false)

    if (!$Quiet) {
        Write-Header
        Write-ColorOutput Cyan "  编译程序"
        Write-Output ""
    }

    # 检查 node_modules 是否存在
    $nodeModulesPath = "$SRC_DIR\node_modules"
    $bunCachePath = "$SRC_DIR\node_modules\.bun"

    # 强制策略：编译前总是清理 bun 缓存（修复依赖解析问题）
    if ((Test-Path $nodeModulesPath) -and (Test-Path $bunCachePath)) {
        Write-ColorOutput Cyan "→ 步骤 1/4: 清理 bun 缓存..."
        Remove-Item -Recurse -Force $bunCachePath -ErrorAction SilentlyContinue
        Write-ColorOutput Cyan "→ 步骤 2/4: 刷新依赖..."
        Push-Location $SRC_DIR
        bun install 2>&1 | Write-Host
        Pop-Location
        Write-ColorOutput Green "✓ 依赖就绪"
        Write-Output ""
    }

    # 自动修复：检查 bun 缓存是否存在，如果不存在则初始化
    if ((Test-Path $nodeModulesPath) -and !(Test-Path $bunCachePath)) {
        Write-ColorOutput Yellow "→ 初始化 bun 缓存..."
        Push-Location $SRC_DIR
        bun install 2>&1 | Write-Host
        Pop-Location
        Write-ColorOutput Green "✓ 缓存已初始化"
        Write-Output ""
    }

    # 检查 node_modules 是否存在
    if (!(Test-Path $nodeModulesPath)) {
        Write-ColorOutput Yellow "→ 步骤 1/4: 安装依赖（首次运行，需要几分钟）..."
        Write-Output ""
        Push-Location $SRC_DIR
        bun install 2>&1 | Write-Host
        Pop-Location
        Write-Output ""

        if (!(Test-Path $nodeModulesPath)) {
            Write-ColorOutput Red "[错误] 依赖安装失败，请手动运行: cd $SRC_DIR && bun install"
            if (!$Quiet) { Read-Host "按回车键继续" }
            return $false
        }
        Write-ColorOutput Green "✓ 依赖安装完成！"
        Write-Output ""
    }

    $bunVersion = Get-BunVersion
    if (!$bunVersion) {
        Write-ColorOutput Red "[错误] Bun 未安装或不在 PATH 中"
        Write-Output "请安装 Bun: npm install -g bun"
        if (!$Quiet) { Read-Host "按回车键继续" }
        return $false
    }
    Write-Output "  Bun 版本: $bunVersion"

    Write-ColorOutput Yellow "关闭现有进程..."
    Get-Process opencode -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process bun -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 1
    Write-Output ""

    Write-ColorOutput Yellow "开始编译..."
    Push-Location $SRC_DIR

    $buildOutput = & bun run --cwd packages/opencode script/build.ts --single 2>&1
    $buildSuccess = $LASTEXITCODE -eq 0

    Pop-Location

    if (!$buildSuccess) {
        Write-Output ""
        Write-ColorOutput Red "[错误] 编译失败！"
        Write-Output ""

        # 分析错误类型并自动修复
        if ($buildOutput -match "Cannot find module") {
            Write-ColorOutput Yellow "检测到依赖问题，自动修复中..."

            # 自动清理缓存并重装
            if (Test-Path $bunCachePath) {
                Write-ColorOutput Cyan "  → 清理 bun 缓存..."
                Remove-Item -Recurse -Force $bunCachePath -ErrorAction SilentlyContinue
            }

            Write-ColorOutput Cyan "  → 重新安装依赖..."
            Push-Location $SRC_DIR
            bun install 2>&1 | Out-Null
            Pop-Location

            Write-ColorOutput Cyan "  → 重试编译..."
            Push-Location $SRC_DIR
            & bun run --cwd packages/opencode script/build.ts --single 2>&1 | Out-Host
            $buildSuccess = $LASTEXITCODE -eq 0
            Pop-Location

            if ($buildSuccess) {
                Write-ColorOutput Green "✓ 修复成功！"
            } else {
                Write-ColorOutput Red "✗ 自动修复失败，请检查网络或手动运行: bun install"
            }
        } elseif ($buildOutput -match "Unexpected token" -or $buildOutput -match "SyntaxError") {
            Write-ColorOutput Yellow "检测到语法错误，可能是汉化配置导致"
            Write-Output ""

            $fixIt = Read-Host "是否自动还原源文件并重试？(Y/n)"
            if ($fixIt -ne "n" -and $fixIt -ne "N") {
                Write-ColorOutput Yellow "正在还原源文件..."
                Push-Location $SRC_DIR
                git checkout -- packages/opencode/src/cli/cmd/tui/ 2>&1 | Out-Null
                Pop-Location
                Write-ColorOutput Green "源文件已还原！"
                Write-Output ""

                Write-ColorOutput Yellow "正在重试编译..."
                Push-Location $SRC_DIR
                & bun run --cwd packages/opencode script/build.ts --single 2>&1 | Out-Host
                $buildSuccess = $LASTEXITCODE -eq 0
                Pop-Location

                if ($buildSuccess) {
                    Write-ColorOutput Green "编译成功！"
                    Write-Output ""
                    Write-ColorOutput Yellow "建议：检查 opencode-i18n.json 中的配置是否有误"

                    # 复制文件
                    Write-ColorOutput Yellow "复制文件..."
                    $exeSource = "$PACKAGE_DIR\dist\opencode-windows-x64\bin\opencode.exe"
                    $exeDest = "$OUT_DIR\opencode.exe"
                    if (Test-Path $exeSource) {
                        Copy-Item $exeSource $exeDest -Force
                        Write-ColorOutput Green "文件已复制到: $exeDest"
                    }
                } else {
                    Write-ColorOutput Red "重试后仍然失败，请检查配置"
                }
            }
        } else {
            # 显示编译错误
            Write-ColorOutput Yellow "编译错误信息:"
            Write-Output $buildOutput
        }

        Write-Output ""
        if (!$Quiet) { Read-Host "按回车键继续" }
        return $false
    }

    Write-ColorOutput Yellow "复制文件..."
    if (!(Test-Path $OUT_DIR)) {
        New-Item -ItemType Directory -Path $OUT_DIR | Out-Null
    }

    $exeSource = "$PACKAGE_DIR\dist\opencode-windows-x64\bin\opencode.exe"
    $exeDest = "$OUT_DIR\opencode.exe"

    if (!(Test-Path $exeSource)) {
        Write-ColorOutput Red "[错误] 编译产物不存在: $exeSource"
        if (!$Quiet) { Read-Host "按回车键继续" }
        return $false
    }

    Copy-Item $exeSource $exeDest -Force

    $fileInfo = Get-Item $exeDest
    $sizeInMB = [math]::Round($fileInfo.Length / 1MB, 2)

    Write-Output ""
    Write-ColorOutput Green "╔════════════════════════════════════════════════╗"
    Write-ColorOutput Green "║              编译完成！                        ║"
    Write-ColorOutput Green "╚════════════════════════════════════════════════╝"
    Write-Output ""
    Write-Output "   输出位置: $exeDest"
    Write-Output "   文件大小: $sizeInMB MB"
    Write-Output ""

    if (!$Quiet) { Read-Host "按回车键继续" }
    return $true
}

function Invoke-FullBuild {
    Write-Header
    Show-Separator
    Write-Output "   完整构建流程"
    Show-Separator
    Write-Output ""

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    Update-Source
    Apply-Patches
    $success = Build-Project -Quiet

    $stopwatch.Stop()

    if ($success) {
        Write-Output ""
        Write-ColorOutput Green "╔════════════════════════════════════════════════╗"
        Write-ColorOutput Green "║              完整构建完成！                    ║"
        Write-ColorOutput Green "╚════════════════════════════════════════════════╝"
        Write-Output ""
        Write-Output "   总耗时: $($stopwatch.Elapsed.ToString('mm\:ss'))"
        Write-Output ""
    }

    Read-Host "按回车键继续"
}

function Invoke-OneClickFull {
    Write-Header
    Show-Separator
    Write-ColorOutput Yellow "       一键汉化全部"
    Show-Separator
    Write-Output ""

    # 检测版本
    $versionInfo = Get-VersionInfo
    if ($versionInfo.HasGit) {
        Write-ColorOutput Cyan "版本状态:"
        Write-Output "  本地: $($versionInfo.LocalCommit)"
        Write-Output "  远程: $($versionInfo.RemoteCommit)"
        if ($versionInfo.NeedsUpdate) {
            Write-ColorOutput Yellow "  √ 有新版本可用"
        } else {
            Write-ColorOutput Green "  ✓ 已是最新版本"
        }
        Write-Output ""
    }

    Write-ColorOutput Cyan "此操作将依次执行："
    if ($versionInfo.NeedsUpdate) {
        Write-Output "  1. [可选] 拉取最新代码"
    } else {
        Write-Output "  1. 跳过拉取 (已是最新)"
    }
    Write-Output "  2. 应用所有汉化补丁"
    Write-Output "  3. 关闭现有进程"
    Write-Output "  4. 编译程序"
    Write-Output "  5. 复制文件到输出目录"
    Write-Output "  6. 替换全局版本 (opencode 命令)"
    Write-Output "  7. 验证汉化结果"
    Write-Output ""

    Write-Output ""
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # 步骤 1: 拉取代码（可选）
    $stepNum = 1
    if ($versionInfo.NeedsUpdate) {
        Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        Write-ColorOutput Cyan "步骤 1/7: 拉取最新代码"
        Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        Write-Output ""

        if (!(Test-Path $SRC_DIR)) {
            Write-ColorOutput Red "[错误] 源码目录不存在: $SRC_DIR"
            Read-Host "按回车键继续"
            return
        }

        Push-Location $SRC_DIR
        if (!(Test-Path ".git")) {
            Write-ColorOutput Red "[错误] 不是一个 git 仓库"
            Pop-Location
            Read-Host "按回车键继续"
            return
        }

        $pullConfirm = Read-Host "检测到新版本，是否拉取？(Y/n)"
        if ($pullConfirm -ne "n" -and $pullConfirm -ne "N") {
            Write-ColorOutput Yellow "执行 git pull..."

            # 智能拉取（处理代理问题）
            $result = git pull 2>&1
            $success = $LASTEXITCODE -eq 0

            if (!$success) {
                if ($result -match "127\.0\.0\.1" -or $result -match "proxy" -or $result -match "Could not connect") {
                    Write-ColorOutput Yellow "检测到代理问题，尝试自动修复..."
                    $oldHttpProxy = git config --get http.proxy
                    $oldHttpsProxy = git config --get https.proxy
                    git config --unset http.proxy
                    git config --unset https.proxy
                    $result = git pull 2>&1
                    $success = $LASTEXITCODE -eq 0
                    if ($oldHttpProxy) { git config http.proxy $oldHttpProxy }
                    if ($oldHttpsProxy) { git config https.proxy $oldHttpsProxy }
                }
            }

            Pop-Location

            if ($success) {
                Write-ColorOutput Green "代码已更新！"
            } else {
                Write-ColorOutput Yellow "拉取失败（可能网络问题），继续使用本地版本"
            }
        } else {
            Write-ColorOutput Yellow "跳过拉取，使用本地版本"
            Pop-Location
        }
    } else {
        Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        Write-ColorOutput Green "步骤 1/7: 跳过拉取 (已是最新版本)"
        Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        Write-Output ""
    }

    Write-Output ""

    Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-ColorOutput Cyan "步骤 2/7: 应用汉化补丁"
    Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Output ""

    if (!(Test-Path $PACKAGE_DIR)) {
        Write-ColorOutput Red "[错误] 包目录不存在: $PACKAGE_DIR"
        Read-Host "按回车键继续"
        return
    }

    Apply-CommandPanelPatch
    Apply-OtherPatches

    Write-ColorOutput Green "汉化补丁应用完成！"
    Write-Output ""

    Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-ColorOutput Cyan "步骤 3/7: 关闭现有进程"
    Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Output ""

    Write-ColorOutput Yellow "关闭 opencode.exe 和 bun 进程..."
    Get-Process opencode -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process bun -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 1
    Write-ColorOutput Green "完成！"
    Write-Output ""

    Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-ColorOutput Cyan "步骤 4/7: 编译程序"
    Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Output ""

    $bunVersion = Get-BunVersion
    if (!$bunVersion) {
        Write-ColorOutput Red "[错误] Bun 未安装或不在 PATH 中"
        Write-Output "请安装 Bun: npm install -g bun"
        Read-Host "按回车键继续"
        return
    }
    Write-Output "   Bun 版本: $bunVersion"
    Write-Output ""

    Write-ColorOutput Yellow "执行编译 (可能需要几分钟)..."
    Write-Output ""

    # 调用统一的编译函数（包含自动修复逻辑）
    $buildSuccess = Build-Project -Quiet

    if (!$buildSuccess) {
        Write-ColorOutput Red "编译失败，流程终止"
        Read-Host "按回车键继续"
        return
    }

    Write-ColorOutput Green "✓ 编译完成！"
    Write-Output ""

    Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-ColorOutput Cyan "步骤 5/7: 复制文件到输出目录"
    Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Output ""

    if (!(Test-Path $OUT_DIR)) {
        New-Item -ItemType Directory -Path $OUT_DIR | Out-Null
    }

    $exeSource = "$PACKAGE_DIR\dist\opencode-windows-x64\bin\opencode.exe"
    $exeDest = "$OUT_DIR\opencode.exe"

    if (!(Test-Path $exeSource)) {
        Write-ColorOutput Red "[错误] 编译产物不存在: $exeSource"
        Read-Host "按回车键继续"
        return
    }

    Copy-Item $exeSource $exeDest -Force

    $fileInfo = Get-Item $exeDest
    $sizeInMB = [math]::Round($fileInfo.Length / 1MB, 2)

    Write-ColorOutput Green "文件已复制！"
    Write-Output ""

    Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-ColorOutput Cyan "步骤 6/7: 替换全局版本"
    Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Output ""

    $globalReplaced = $false
    $globalCmd = Get-Command opencode -ErrorAction SilentlyContinue

    if ($globalCmd) {
        $globalPath = $globalCmd.Source
        Write-Output "检测到全局安装: $globalPath"
        Write-Output ""

        if ($globalPath -like "*npm*" -or $globalPath -like "*bun*") {
            Write-ColorOutput Yellow "将汉化版复制到全局目录..."
            Copy-Item $exeDest $globalPath -Force
            Write-ColorOutput Green "全局版本已替换！"
            Write-Output ""
            Write-ColorOutput Green "现在 'opencode' 命令将直接使用汉化版"
            $globalReplaced = $true
        } else {
            Write-ColorOutput Yellow "将汉化版复制到: $globalPath"
            Copy-Item $exeDest $globalPath -Force
            Write-ColorOutput Green "完成！"
            $globalReplaced = $true
        }
    } else {
        Write-ColorOutput Yellow "未检测到全局 opencode 安装"
        Write-Output "运行 'npm install -g opencode-windows-x64' 后可自动替换"
    }

    Write-Output ""

    Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-ColorOutput Cyan "步骤 7/7: 验证汉化结果"
    Write-ColorOutput Cyan "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Output ""

    # 快速验证关键汉化点
    $appFile = "$PACKAGE_DIR\src\cli\cmd\tui\app.tsx"
    $validationPassed = $false
    if (Test-Path $appFile) {
        $content = Get-Content $appFile -Raw -Encoding UTF8
        $hasChinese = $content -like "*切换会话*" -and $content -like "*新建会话*"
        if ($hasChinese) {
            Write-ColorOutput Green "汉化验证通过！关键中文文本已应用"
            $validationPassed = $true
        } else {
            Write-ColorOutput Yellow "警告: 汉化可能未完全生效"
            Write-Output "可运行 [12] 验证汉化结果 查看详情"
        }
    }

    Write-Output ""

    $stopwatch.Stop()

    Write-ColorOutput Green "╔════════════════════════════════════════════════════════════╗"
    Write-ColorOutput Green "║          一键汉化+部署完成！                               ║"
    Write-ColorOutput Green "╚════════════════════════════════════════════════════════════╝"
    Write-Output ""
    Write-Output "   输出位置: $exeDest"
    Write-Output "   文件大小: $sizeInMB MB"
    Write-Output "   总耗时: $($stopwatch.Elapsed.ToString('mm\:ss'))"

    if ($globalReplaced) {
        Write-Output ""
        Write-ColorOutput Green "   √ 全局版本已替换"
        Write-ColorOutput Yellow "   直接运行 'opencode' 即可启动汉化版"
    } else {
        Write-Output ""
        Write-ColorOutput Yellow "   运行 .\opencode.exe 启动汉化版"
        Write-ColorOutput Yellow "   或运行 [10] 替换全局版本"
    }

    if ($validationPassed) {
        Write-ColorOutput Green "   √ 汉化验证通过"
    }

    Write-Output ""

    Read-Host "按回车键继续"
    return $true
}

function Show-Documentation {
    Write-Header
    Show-Separator
    Write-Output "   汉化指南"
    Show-Separator
    Write-Output ""

    $docFile = "$DOCS_DIR\汉化指南.md"
    if (Test-Path $docFile) {
        Get-Content $docFile -Encoding UTF8 | Write-Output
    } else {
        Write-ColorOutput Red "文档不存在: $docFile"
        Write-Output ""
        Write-Output "已汉化的文件："
        Write-Output "  - app.tsx (命令面板 - 24项)"
        Write-Output "  - dialog-agent.tsx (Agent选择对话框)"
        Write-Output "  - dialog-session-list.tsx (会话列表对话框)"
        Write-Output "  - sidebar.tsx (侧边栏)"
        Write-Output "  - header.tsx (头部导航)"
    }

    Write-Output ""
    Show-Separator
    Write-Output ""
    Read-Host "按回车键继续"
}

function Open-OutputDirectory {
    if (!(Test-Path $OUT_DIR)) {
        New-Item -ItemType Directory -Path $OUT_DIR -Force | Out-Null
    }
    Start-Process explorer.exe -ArgumentList $OUT_DIR
    Write-ColorOutput Green "已打开输出目录: $OUT_DIR"
    Start-Sleep -Seconds 0.5
}

function Restore-OriginalFiles {
    Write-Header
    Write-ColorOutput Cyan "  还原原始文件"
    Write-Output ""

    Write-ColorOutput Yellow "选择还原方式："
    Write-Output "  [1] 从备份文件还原 (.bak)"
    Write-Output "  [2] 从 Git 还原 (强制重置)"
    Write-Output ""

    $method = Read-Host "请选择"

    if ($method -eq "2") {
        # Git 还原 - 最彻底的方式
        Write-Output ""
        Write-ColorOutput Yellow "警告：这将丢弃所有本地修改！"
        $confirm2 = Read-Host "确定继续？(yes/NO)"
        if ($confirm2 -ne "yes" -and $confirm2 -ne "YES") {
            return
        }

        Push-Location $SRC_DIR
        $null = git checkout -- packages/opencode/src/cli/cmd/tui/ 2>&1
        Pop-Location

        Write-ColorOutput Green "Git 还原完成！"
        Read-Host "按回车继续"
        return
    }

    # 从 .bak 文件还原
    Write-Output ""
    Write-ColorOutput Yellow "正在从备份还原..."

    # 从配置读取所有需要汉化的文件
    $config = Get-I18NConfig
    $filesToRestore = @()

    # 兼容 hashtable 和 PSObject
    $patchKeys = @()
    if ($config.patches -is [hashtable]) {
        $patchKeys = @($config.patches.Keys)
    } else {
        $patchKeys = @($config.patches.PSObject.Properties.Name)
    }

    foreach ($patchKey in $patchKeys) {
        $patch = if ($config.patches -is [hashtable]) {
            $config.patches[$patchKey]
        } else {
            $config.patches.$patchKey
        }
        if (!$patch.file) { continue }
        $relPath = $patch.file
        $fullPath = "$SRC_DIR\$relPath"
        $bakPath = "$fullPath.bak"

        if (Test-Path $bakPath) {
            $filesToRestore += @{
                Source = $bakPath
                Dest = $fullPath
                Name = Split-Path $relPath -Leaf
            }
        }
    }

    $restoredCount = 0
    foreach ($file in $filesToRestore) {
        try {
            Copy-Item $file.Source $file.Dest -Force
            Write-ColorOutput Green "  √ $($file.Name)"
            $restoredCount++
        } catch {
            Write-ColorOutput Red "  × $($file.Name) - $_"
        }
    }

    Write-Output ""
    if ($restoredCount -eq 0) {
        Write-ColorOutput Yellow "未找到备份文件，尝试 Git 还原..."
        Push-Location $SRC_DIR
        $null = git checkout -- packages/opencode/src/cli/cmd/tui/ 2>&1
        Pop-Location
        Write-ColorOutput Green "Git 还原完成！"
    } else {
        Write-ColorOutput Green "还原完成！共还原 $restoredCount 个文件。"
    }
    Write-Output ""
    Read-Host "按回车继续"
}

# ==================== 清理和启动功能 ====================

function Show-CleanMenu {
    Write-Header
    Write-ColorOutput Magenta "  清理工具"
    Write-Output ""

    # 显示当前状态
    $bakCount = 0
    $config = Get-I18NConfig
    if ($config) {
        # 兼容 hashtable 和 PSObject
        $patchKeys = @()
        if ($config.patches -is [hashtable]) {
            $patchKeys = @($config.patches.Keys)
        } else {
            $patchKeys = @($config.patches.PSObject.Properties.Name)
        }

        foreach ($patchKey in $patchKeys) {
            $patch = if ($config.patches -is [hashtable]) {
                $config.patches[$patchKey]
            } else {
                $config.patches.$patchKey
            }
            if (!$patch.file) { continue }
            $fullPath = "$SRC_DIR\$($patch.file)"
            $bakPath = "$fullPath.bak"
            if (Test-Path $bakPath) { $bakCount++ }
        }
    }

    $backupCount = 0
    if (Test-Path $BACKUP_DIR) {
        $backupCount = (Get-ChildItem $BACKUP_DIR -Directory -ErrorAction SilentlyContinue | Measure-Object).Count
    }

    $distSize = 0
    if (Test-Path "$PACKAGE_DIR\dist") {
        $distSize = (Get-ChildItem "$PACKAGE_DIR\dist" -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
    }

    Write-ColorOutput DarkGray "  当前状态:"
    Write-Output "    .bak 文件: $bakCount 个"
    Write-Output "    备份文件夹: $backupCount 个"
    Write-Output "    编译产物: $("{0:N1}" -f $distSize) MB"
    Write-Output ""

    Write-ColorOutput Green "  [1] 清理 .bak 文件"
    Write-ColorOutput DarkGray "      → 删除汉化时创建的原始文件备份"
    Write-Output ""
    Write-ColorOutput Yellow "  [2] 清理旧备份"
    Write-ColorOutput DarkGray "      → 删除手动创建的版本备份文件夹"
    Write-Output ""
    Write-ColorOutput Cyan "  [3] 清理编译产物"
    Write-ColorOutput DarkGray "      → 删除 dist 目录（可重新编译）"
    Write-Output ""
    Write-ColorOutput Red "  [4] 清理源码"
    Write-ColorOutput DarkGray "      → 删除整个源码目录（可重新拉取）"
    Write-Output ""
    Write-ColorOutput Magenta "  [A] 全部清理"
    Write-ColorOutput DarkGray "      → 清理以上所有项目"
    Write-Output ""
    Write-ColorOutput DarkGray "  [0] 返回"
    Write-Output ""
}

function Invoke-Clean {
    param([string]$Mode)

    switch ($Mode) {
        "1" {
            # 清理 .bak 文件
            Write-ColorOutput Yellow "正在清理 .bak 文件..."
            $config = Get-I18NConfig
            $count = 0
            if ($config) {
                # 兼容 hashtable 和 PSObject
                $patchKeys = @()
                if ($config.patches -is [hashtable]) {
                    $patchKeys = @($config.patches.Keys)
                } else {
                    $patchKeys = @($config.patches.PSObject.Properties.Name)
                }

                foreach ($patchKey in $patchKeys) {
                    $patch = if ($config.patches -is [hashtable]) {
                        $config.patches[$patchKey]
                    } else {
                        $config.patches.$patchKey
                    }
                    if (!$patch.file) { continue }
                    $fullPath = "$SRC_DIR\$($patch.file)"
                    $bakPath = "$fullPath.bak"
                    if (Test-Path $bakPath) {
                        Remove-Item $bakPath -Force
                        $count++
                    }
                }
            }
            Write-ColorOutput Green "已删除 $count 个 .bak 文件"
        }
        "2" {
            # 清理旧备份
            Write-ColorOutput Yellow "正在清理旧备份..."
            if (!(Test-Path $BACKUP_DIR)) {
                Write-ColorOutput Cyan "备份目录不存在"
                return
            }
            $backups = Get-ChildItem $BACKUP_DIR -Directory -ErrorAction SilentlyContinue
            $count = 0
            foreach ($backup in $backups) {
                Remove-Item $backup.FullName -Recurse -Force
                $count++
            }
            Write-ColorOutput Green "已删除 $count 个备份文件夹"
        }
        "3" {
            # 清理编译产物
            Write-ColorOutput Yellow "正在清理编译产物..."
            $distPath = "$PACKAGE_DIR\dist"
            if (Test-Path $distPath) {
                Remove-Item $distPath -Recurse -Force
                Write-ColorOutput Green "已删除 dist 目录"
            } else {
                Write-ColorOutput Cyan "dist 目录不存在"
            }
            $nodeModulesPath = "$PACKAGE_DIR\node_modules\.cache"
            if (Test-Path $nodeModulesPath) {
                Remove-Item $nodeModulesPath -Recurse -Force
                Write-ColorOutput Green "已删除 bun 缓存"
            }
        }
        "4" {
            # 清理源码
            Write-ColorOutput Red "警告：这将删除整个源码目录！"
            $confirm = Read-Host "确定继续？(yes/NO)"
            if ($confirm -eq "yes" -or $confirm -eq "YES") {
                Write-ColorOutput Yellow "正在删除源码..."
                if (Test-Path $SRC_DIR) {
                    Remove-Item $SRC_DIR -Recurse -Force
                    Write-ColorOutput Green "源码已删除，可运行 [1] 拉取代码 重新获取"
                } else {
                    Write-ColorOutput Cyan "源码目录不存在"
                }
            } else {
                Write-ColorOutput DarkGray "已取消"
            }
        }
        "A" {
            # 全部清理
            Write-ColorOutput Red "警告：这将清理所有临时文件！"
            $confirm = Read-Host "确定继续？(yes/NO)"
            if ($confirm -eq "yes" -or $confirm -eq "YES") {
                Write-Output ""

                # 清理 .bak
                Write-ColorOutput Yellow "清理 .bak 文件..."
                $config = Get-I18NConfig
                if ($config) {
                    # 兼容 hashtable 和 PSObject
                    $patchKeys = @()
                    if ($config.patches -is [hashtable]) {
                        $patchKeys = @($config.patches.Keys)
                    } else {
                        $patchKeys = @($config.patches.PSObject.Properties.Name)
                    }

                    foreach ($patchKey in $patchKeys) {
                        $patch = if ($config.patches -is [hashtable]) {
                            $config.patches[$patchKey]
                        } else {
                            $config.patches.$patchKey
                        }
                        if (!$patch.file) { continue }
                        $bakPath = "$SRC_DIR\$($patch.file).bak"
                        if (Test-Path $bakPath) { Remove-Item $bakPath -Force }
                    }
                }

                # 清理旧备份
                Write-ColorOutput Yellow "清理旧备份..."
                if (Test-Path $BACKUP_DIR) {
                    Get-ChildItem $BACKUP_DIR -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                        Remove-Item $_.FullName -Recurse -Force
                    }
                }

                # 清理编译产物
                Write-ColorOutput Yellow "清理编译产物..."
                if (Test-Path "$PACKAGE_DIR\dist") { Remove-Item "$PACKAGE_DIR\dist" -Recurse -Force }
                if (Test-Path "$PACKAGE_DIR\node_modules\.cache") { Remove-Item "$PACKAGE_DIR\node_modules\.cache" -Recurse -Force }

                Write-ColorOutput Green "全部清理完成！"
            } else {
                Write-ColorOutput DarkGray "已取消"
            }
        }
    }
}

function Launch-OpenCode {
    $exePath = "$OUT_DIR\opencode.exe"
    if (!(Test-Path $exePath)) {
        Write-ColorOutput Red "汉化版不存在，请先运行 [1] 一键汉化+部署"
        Start-Sleep -Seconds 2
        return
    }

    Write-ColorOutput Green "正在启动 OpenCode 汉化版..."
    Start-Process $exePath
    Write-ColorOutput Green "已启动！"
    Start-Sleep -Seconds 1
}

function Restore-Script {
    <#
    .SYNOPSIS
        恢复管理脚本本身（从自动备份中恢复）
    #>
    Write-Header
    Show-Separator
    Write-Output "   恢复管理脚本"
    Show-Separator
    Write-Output ""

    $scriptBackupDir = "$OUT_DIR\script_backup"
    if (!(Test-Path $scriptBackupDir)) {
        Write-ColorOutput Red "脚本备份目录不存在"
        Write-Output "脚本会在每次运行时自动备份到: $scriptBackupDir"
        Write-Output ""
        Read-Host "按回车键继续"
        return
    }

    # 显示可用的脚本备份
    Write-ColorOutput Cyan "可用备份:"
    Write-Output ""

    $mainBackup = "$scriptBackupDir\opencode-v3.ps1"
    $oldBackup = "$scriptBackupDir\opencode-v3.ps1.old"

    $hasMain = Test-Path $mainBackup
    $hasOld = Test-Path $oldBackup

    if ($hasMain) {
        $mainTime = (Get-Item $mainBackup).LastWriteTime
        Write-Output "  [1] 主备份 - $($mainTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    }
    if ($hasOld) {
        $oldTime = (Get-Item $oldBackup).LastWriteTime
        Write-Output "  [2] 旧版本 - $($oldTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    }

    if (!$hasMain -and !$hasOld) {
        Write-ColorOutput Red "没有找到脚本备份"
        Write-Output ""
        Read-Host "按回车键继续"
        return
    }

    Write-Output ""
    $selection = Read-Host "选择要恢复的备份 (0 取消)"

    if ($selection -eq "0" -or !$selection) { return }

    $sourceFile = if ($selection -eq "1" -and $hasMain) {
        $mainBackup
    } elseif ($selection -eq "2" -and $hasOld) {
        $oldBackup
    } else {
        Write-ColorOutput Red "无效选择"
        Read-Host "按回车键继续"
        return
    }

    Write-Output ""
    Write-ColorOutput Yellow "确定要恢复脚本吗？"
    $confirm = Read-Host "确认？(y/N)"

    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Output "已取消"
        Read-Host "按回车键继续"
        return
    }

    # 恢复脚本
    Copy-Item $sourceFile $SCRIPT_SELF -Force
    Write-ColorOutput Green "脚本已恢复！"
    Write-Output ""
    Write-ColorOutput Yellow "请重新运行脚本以加载更新后的版本"
    Write-Output ""
    Read-Host "按回车键退出"
    exit
}

function Show-Status {
    Write-Header
    Show-Separator
    Write-Output "   当前状态"
    Show-Separator
    Write-Output ""

    Write-Output "源码目录: $SRC_DIR"
    Write-Output "包目录: $PACKAGE_DIR"
    Write-Output "输出目录: $OUT_DIR"
    Write-Output ""

    Write-Output "备份文件:"
    $backupFiles = @(
        "$PACKAGE_DIR\src\cli\cmd\tui\app.tsx.bak",
        "$PACKAGE_DIR\src\cli\cmd\tui\component\dialog-agent.tsx.bak",
        "$PACKAGE_DIR\src\cli\cmd\tui\component\dialog-session-list.tsx.bak",
        "$PACKAGE_DIR\src\cli\cmd\tui\routes\session\sidebar.tsx.bak",
        "$PACKAGE_DIR\src\cli\cmd\tui\routes\session\header.tsx.bak"
    )

    $backupCount = 0
    foreach ($bakFile in $backupFiles) {
        if (Test-Path $bakFile) {
            Write-ColorOutput Green "  √ $(Split-Path $bakFile -Leaf)"
            $backupCount++
        } else {
            Write-ColorOutput Red "  × $(Split-Path $bakFile -Leaf)"
        }
    }

    Write-Output ""
    Write-Output "编译产物:"
    if (Test-Path "$OUT_DIR\opencode.exe") {
        $fileInfo = Get-Item "$OUT_DIR\opencode.exe"
        $sizeInMB = [math]::Round($fileInfo.Length / 1MB, 2)
        $modifiedDate = $fileInfo.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        Write-ColorOutput Green "  √ opencode.exe ($sizeInMB MB, $modifiedDate)"
    } else {
        Write-ColorOutput Red "  × opencode.exe"
    }

    Write-Output ""
    Write-Output "环境检查:"
    $bunVersion = Get-BunVersion
    if ($bunVersion) {
        Write-ColorOutput Green "  √ Bun $bunVersion"
    } else {
        Write-ColorOutput Red "  × Bun (未安装)"
    }

    $hasSed = Test-Command "sed"
    if ($hasSed) {
        Write-ColorOutput Green "  √ sed (可用)"
    } else {
        Write-ColorOutput Yellow "  ○ sed (未安装，可选)"
    }

    Write-Output ""
    Write-Output "全局版本:"
    $globalOpencode = Get-Command opencode -ErrorAction SilentlyContinue
    if ($globalOpencode) {
        $globalPath = $globalOpencode.Source
        $globalSource = if ($globalPath -like "*npm*") { "npm" } elseif ($globalPath -like "*bun*") { "bun" } else { "其他" }
        $isOurVersion = if ($globalPath -eq "$OUT_DIR\opencode.exe") { $true } else { $false }
        if ($isOurVersion) {
            Write-ColorOutput Green "  √ 已替换为汉化版"
        } else {
            Write-ColorOutput Yellow "  ⚠ $globalSource 版本 ($globalPath)"
            Write-ColorOutput Cyan "     输入 [10] 替换为汉化版"
        }
    } else {
        Write-ColorOutput Yellow "  ○ 未安装全局版本"
    }

    Write-Output ""
    Write-Output "Git 状态:"
    Push-Location $SRC_DIR
    $gitStatus = git status --short 2>&1
    if ($gitStatus) {
        $changeCount = ($gitStatus | Measure-Object).Count
        if ($changeCount -gt 0) {
            Write-ColorOutput Yellow "  ⚠ 有 $changeCount 个未提交的更改"
        }
    } else {
        Write-ColorOutput Green "  √ 工作区干净"
    }
    Pop-Location

    Write-Output ""
    Read-Host "按回车键继续"
}

function Install-Global {
    Write-Header
    Show-Separator
    Write-Output "   替换全局版本"
    Show-Separator
    Write-Output ""

    $ourExe = "$OUT_DIR\opencode.exe"
    if (!(Test-Path $ourExe)) {
        Write-ColorOutput Red "[错误] 汉化版不存在: $ourExe"
        Write-Output "请先执行 [3] 编译程序 或 [5] 一键汉化全部"
        Read-Host "按回车键继续"
        return
    }

    $globalCmd = Get-Command opencode -ErrorAction SilentlyContinue
    if (!$globalCmd) {
        Write-ColorOutput Red "[错误] 未找到全局 opencode 安装"
        Write-Output "请先运行: npm install -g opencode-windows-x64"
        Read-Host "按回车键继续"
        return
    }

    $globalPath = $globalCmd.Source
    Write-Output "当前全局版本: $globalPath"

    # 检测是 npm 还是 bun 安装的
    if ($globalPath -like "*npm*") {
        $npmGlobalDir = Split-Path $globalPath -Parent
        Write-Output ""
        Write-ColorOutput Yellow "将汉化版复制到 npm 全局目录..."
        Copy-Item $ourExe $globalPath -Force
        Write-ColorOutput Green "完成！现在 'opencode' 命令将使用汉化版"
    } elseif ($globalPath -like "*bun*") {
        $bunGlobalDir = Split-Path $globalPath -Parent
        Write-Output ""
        Write-ColorOutput Yellow "将汉化版复制到 bun 全局目录..."
        Copy-Item $ourExe $globalPath -Force
        Write-ColorOutput Green "完成！现在 'opencode' 命令将使用汉化版"
    } else {
        Write-Output ""
        Write-ColorOutput Yellow "将汉化版复制到: $globalPath"
        Copy-Item $ourExe $globalPath -Force
        Write-ColorOutput Green "完成！"
    }

    Write-Output ""
    Read-Host "按回车键继续"
}

function Show-I18NConfig {
    Write-Header
    Show-Separator
    Write-Output "   汉化配置信息"
    Show-Separator
    Write-Output ""

    $config = Get-I18NConfig
    if (!$config) {
        Read-Host "按回车键继续"
        return
    }

    # 确定配置类型
    $configType = if ($config.patches -is [hashtable]) { "模块化" } else { "单文件" }
    $configPath = if ($config.patches -is [hashtable]) { $I18N_DIR } else { $I18N_CONFIG_OLD }

    Write-ColorOutput Cyan "配置类型: $configType"
    Write-ColorOutput Cyan "配置路径: $configPath"
    Write-ColorOutput Cyan "版本: $($config.version)"
    Write-ColorOutput Cyan "描述: $($config.description)"
    Write-ColorOutput Cyan "最后更新: $($config.lastUpdate)"
    Write-Output ""
    Write-ColorOutput Yellow "汉化模块:"

    $patchIndex = 1
    $totalReplacements = 0

    # 兼容 hashtable 和 PSObject
    if ($config.patches -is [hashtable]) {
        foreach ($kvp in $config.patches.GetEnumerator()) {
            $patchName = $kvp.Key
            $patch = $kvp.Value
            $replacementsCount = 0
            if ($patch.replacements) {
                if ($patch.replacements -is [System.Management.Automation.PSCustomObject]) {
                    $replacementsCount = ($patch.replacements.PSObject.Properties | Measure-Object).Count
                } elseif ($patch.replacements -is [hashtable]) {
                    $replacementsCount = $patch.replacements.Count
                }
            }
            $totalReplacements += $replacementsCount

            Write-Output "  [$patchIndex] $patchName"
            Write-Output "      文件: $($patch.file)"
            Write-Output "      描述: $($patch.description)"
            Write-Output "      替换数: $replacementsCount 项"
            Write-Output ""
            $patchIndex++
        }
    } else {
        $config.patches.PSObject.Properties | ForEach-Object {
            $patchName = $_.Name
            $patch = $_.Value
            $replacementsCount = ($patch.replacements.PSObject.Properties | Measure-Object).Count
            $totalReplacements += $replacementsCount

            Write-Output "  [$patchIndex] $patchName"
            Write-Output "      文件: $($patch.file)"
            Write-Output "      描述: $($patch.description)"
            Write-Output "      替换数: $replacementsCount 项"
            Write-Output ""
            $patchIndex++
        }
    }

    $moduleCount = if ($config.patches -is [hashtable]) { $config.patches.Count } else { $config.patches.PSObject.Properties.Count }
    Write-ColorOutput Green "总计: $moduleCount 个模块, $totalReplacements 项替换"
    Write-Output ""
    Write-ColorOutput Yellow "编辑配置文件即可添加/修改汉化内容"
    Write-ColorOutput Cyan "配置路径: $configPath"
    Write-Output ""
    Read-Host "按回车键继续"
}

function Show-ProjectInfo {
    <#
    .SYNOPSIS
        生成项目信息供 AI 维护使用
    .DESCRIPTION
        输出结构化的项目信息，可直接复制给 AI 进行维护
    #>
    Write-Header
    Show-Separator
    Write-Output "   项目信息 (AI 维护用)"
    Show-Separator
    Write-Output ""

    $info = @"
# OpenCode 中文汉化管理工具 - 项目信息

## 基本信息
- 项目名称: OpenCode 中文汉化管理工具
- 版本: v3.0
- 脚本路径: $PSCommandPath
- 配置文件: $I18N_CONFIG
- 源码目录: $SRC_DIR
- 包目录: $PACKAGE_DIR
- 输出目录: $OUT_DIR

## 目录结构
```
$SCRIPT_DIR\
├── opencode-v3.ps1          # 主管理脚本
├── opencode-i18n.json       # 汉化配置文件
├── opencode.exe             # 编译输出
└── opencode-zh-CN\          # OpenCode 源码
    └── packages\opencode\
        └── src\cli\cmd\tui\ # 汉化目标文件
```

## 汉化配置结构
配置文件 (opencode-i18n.json) 结构:
```json
{
  "version": "1.0",
  "patches": {
    "模块名": {
      "file": "src/相对路径.tsx",
      "description": "模块描述",
      "replacements": {
        "原文": "译文"
      }
    }
  }
}
```

## 核心函数
- `Get-I18NConfig()` - 加载配置
- `Apply-SinglePatch()` - 应用单个补丁
- `Apply-CommandPanelPatch()` - 命令面板汉化
- `Apply-OtherPatches()` - 其他模块汉化
- `Test-I18NPatches()` - 验证汉化结果
- `Debug-I18NFailure()` - 调试工具
- `Invoke-OneClickFull()` - 一键汉化+部署

## 添加新汉化项流程
1. 编辑 `opencode-i18n.json` 添加新模块
2. 运行 `[2] 应用汉化补丁` 测试
3. 运行 `[12] 验证汉化结果` 检查
4. 如失败，运行 `[13] 汉化调试工具` 定位

## 编译命令
```bash
cd $SRC_DIR
bun run --cwd packages/opencode script/build.ts --single
```

## 当前状态
"@

    # 添加当前状态
    $config = Get-I18NConfig
    if ($config) {
        $info += "`n### 汉化配置`n"
        $info += "- 版本: $($config.version)`n"
        $info += "- 最后更新: $($config.lastUpdate)`n"
        $moduleCount = if ($config.patches -is [hashtable]) { $config.patches.Count } else { $config.patches.PSObject.Properties.Count }
        $info += "- 模块数: $moduleCount`n"
    }

    $info += "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n"
    $info += "`n将以上内容复制给 AI 即可进行维护工作`n"

    Write-ColorOutput White $info
    Write-Output ""

    # 询问是否保存到文件
    $save = Read-Host "是否保存到文件？(Y/n)"
    if ($save -ne "n" -and $save -ne "N") {
        $infoFile = "$OUT_DIR\PROJECT_INFO.md"
        $info | Out-File -FilePath $infoFile -Encoding UTF8
        Write-ColorOutput Green "已保存到: $infoFile"
    }

    Write-Output ""
    Read-Host "按回车键继续"
}

function Install-OpenCodeCmd {
    <#
    .SYNOPSIS
        安装 opencodecmd 全局命令
    .DESCRIPTION
        创建 opencodecmd.bat 到 npm 全局目录，实现全局调用
    #>
    Write-Header
    Show-Separator
    Write-Output "   安装 opencodecmd 全局命令"
    Show-Separator
    Write-Output ""

    # 获取 npm 全局目录
    $npmGlobalDir = npm config get prefix 2>&1
    if (!$npmGlobalDir) {
        Write-ColorOutput Red "[错误] 无法获取 npm 全局目录"
        Read-Host "按回车键继续"
        return
    }

    $batDest = "$npmGlobalDir\opencodecmd.bat"

    Write-Output "目标位置: $batDest"
    Write-Output ""

    $batContent = "@echo off
powershell.exe -ExecutionPolicy Bypass -File `"$PSCommandPath`"
"

    # 创建 bat 文件
    try {
        $batContent | Out-File -FilePath $batDest -Encoding ASCII
        Write-ColorOutput Green "创建成功: $batDest"
        Write-Output ""
        Write-ColorOutput Yellow "现在可以在任意位置运行:"
        Write-ColorOutput Cyan "  opencodecmd"
        Write-Output ""
        Write-ColorOutput Yellow "卸载命令:"
        Write-ColorOutput Cyan "  del $batDest"
    } catch {
        Write-ColorOutput Red "[错误] 创建失败: $_"
    }

    Write-Output ""
    Read-Host "按回车键继续"
}

# ==================== 主循环 ====================

do {
    Show-Menu
    $choice = Read-Host "请选择"

    switch ($choice) {
        "1" {
            $success = Invoke-OneClickFull
            if ($success) {
                Write-Output ""
                $autoValidate = Read-Host "是否验证汉化结果？(Y/n)"
                if ($autoValidate -ne "n" -and $autoValidate -ne "N") {
                    $passed = Test-I18NPatches
                    if (!$passed) {
                        Write-Output ""
                        Write-ColorOutput Red "汉化验证失败，建议运行调试工具"
                        $runDebug = Read-Host "是否立即调试？(Y/n)"
                        if ($runDebug -ne "n" -and $runDebug -ne "N") {
                            Debug-I18NFailure
                        }
                    }
                }
            }
        }
        "2" { Test-I18NPatches }
        "3" { Debug-I18NFailure }
        "4" { Show-VersionInfo }
        "5" { Backup-All }
        "L" { Show-Changelog }
        "l" { Show-Changelog }
        "6" {
            # 高级菜单
            do {
                Show-AdvancedMenu
                $advChoice = Read-Host "请选择"

                switch ($advChoice) {
                    "1" { Update-Source }
                    "2" { Apply-Patches }
                    "3" { Build-Project }
                    "4" { Show-VersionInfo }
                    "5" { Backup-All }
                    "6" { Restore-Backup }
                    "H" { Show-Changelog }
                    "h" { Show-Changelog }
                    "7" { Restore-OriginalFiles }
                    "8" { Open-OutputDirectory }
                    "9" { Install-Global }
                    "R" { Restore-Source }
                    "r" { Restore-Source }
                    "C" {
                        # 清理菜单循环
                        do {
                            Show-CleanMenu
                            $cleanChoice = Read-Host "请选择"
                            switch ($cleanChoice) {
                                "1" { Invoke-Clean "1"; Read-Host "按回车继续" }
                                "2" { Invoke-Clean "2"; Read-Host "按回车继续" }
                                "3" { Invoke-Clean "3"; Read-Host "按回车继续" }
                                "4" { Invoke-Clean "4"; Read-Host "按回车继续" }
                                "A" { Invoke-Clean "A"; Read-Host "按回车继续" }
                                "a" { Invoke-Clean "A"; Read-Host "按回车继续" }
                                "0" { break }
                                "q" { break }
                                "Q" { break }
                                default {
                                    Write-ColorOutput DarkGray "无效选择"
                                    Read-Host
                                }
                            }
                        } while ($cleanChoice -ne "0" -and $cleanChoice -ne "q" -and $cleanChoice -ne "Q")
                    }
                    "c" {
                        # 清理菜单循环（小写）
                        do {
                            Show-CleanMenu
                            $cleanChoice = Read-Host "请选择"
                            switch ($cleanChoice) {
                                "1" { Invoke-Clean "1"; Read-Host "按回车继续" }
                                "2" { Invoke-Clean "2"; Read-Host "按回车继续" }
                                "3" { Invoke-Clean "3"; Read-Host "按回车继续" }
                                "4" { Invoke-Clean "4"; Read-Host "按回车继续" }
                                "A" { Invoke-Clean "A"; Read-Host "按回车继续" }
                                "a" { Invoke-Clean "A"; Read-Host "按回车继续" }
                                "0" { break }
                                "q" { break }
                                "Q" { break }
                                default {
                                    Write-ColorOutput DarkGray "无效选择"
                                    Read-Host
                                }
                            }
                        } while ($cleanChoice -ne "0" -and $cleanChoice -ne "q" -and $cleanChoice -ne "Q")
                    }
                    "L" { Launch-OpenCode }
                    "l" { Launch-OpenCode }
                    "S" { Restore-Script }
                    "s" { Restore-Script }
                    "0" { break }
                    "q" { break }
                    "Q" { break }
                    default {
                        Write-ColorOutput DarkGray "无效选择"
                        Read-Host
                    }
                }
            } while ($advChoice -ne "0" -and $advChoice -ne "q" -and $advChoice -ne "Q")
        }
        "0" { break }
        "q" { break }
        "Q" { break }
        default {
            Write-ColorOutput DarkGray "无效选择"
            Read-Host
        }
    }
} while ($choice -ne "0" -and $choice -ne "q" -and $choice -ne "Q")

Clear-Host
Write-ColorOutput Cyan "感谢使用 OpenCode 中文汉化管理工具！"
Write-Output ""
Start-Sleep -Seconds 1
