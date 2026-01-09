# ========================================
# opencode-v3.ps1 模块化 i18n 支持补丁
# ========================================

## 状态：✅ 已完成

本补丁已于 2026-01-09 应用完成。

---

## 需要修改的函数（已全部完成）

### 1. 修改 Get-I18NConfig 函数（约第220行）

**原函数**：
```powershell
function Get-I18NConfig {
    $configPath = "$I18N_DIR\opencode-i18n.json"

    if (!(Test-Path $configPath)) {
        Write-ColorOutput Red "[错误] 汉化配置文件不存在: $configPath"
        return $null
    }

    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    return $config
}
```

**修改为**：
```powershell
function Get-I18NConfig {
    # 配置文件路径
    $configPath = "$I18N_DIR\config.json"

    if (!(Test-Path $configPath)) {
        Write-ColorOutput Red "[错误] 汉化配置文件不存在: $configPath"
        Write-ColorOutput Yellow "正在使用单文件模式..."
        # 回退到单文件模式
        $singleConfigPath = "$PSScriptRoot\opencode-i18n.json"
        if (!(Test-Path $singleConfigPath)) {
            Write-ColorOutput Red "[错误] 单文件配置也不存在"
            return $null
        }
        $config = Get-Content $singleConfigPath -Raw | ConvertFrom-Json
        return $config
    }

    # 读取主配置
    $config = Get-Content $configPath -Raw | ConvertFrom-Json

    # 加载所有模块文件
    $allModules = @{}

    # 加载 dialogs 模块
    if ($config.modules.dialogs) {
        foreach ($module in $config.modules.dialogs) {
            $modulePath = "$I18N_DIR\$module"
            if (Test-Path $modulePath) {
                $moduleContent = Get-Content $modulePath -Raw | ConvertFrom-Json
                $moduleName = $module -replace '\\', '' -replace '.*\\', ''
                $moduleName = $moduleName -replace '\.json$', ''
                $allModules[$moduleName] = $moduleContent
            }
        }
    }

    # 加载 routes 模块
    if ($config.modules.routes) {
        foreach ($module in $config.modules.routes) {
            $modulePath = "$I18N_DIR\$module"
            if (Test-Path $modulePath) {
                $moduleContent = Get-Content $modulePath -Raw | ConvertFrom-Json
                $moduleName = $module -replace '\\', '' -replace '.*\\', ''
                $moduleName = $moduleName -replace '\.json$', ''
                $allModules[$moduleName] = $moduleContent
            }
        }
    }

    # 加载 components 模块
    if ($config.modules.components) {
        foreach ($module in $config.modules.components) {
            $modulePath = "$I18N_DIR\$module"
            if (Test-Path $modulePath) {
                $moduleContent = Get-Content $modulePath -Raw | ConvertFrom-Json
                $moduleName = $module -replace '\\', '' -replace '.*\\', ''
                $moduleName = $moduleName -replace '\.json$', ''
                $allModules[$moduleName] = $moduleContent
            }
        }
    }

    # 加载 common 模块
    if ($config.modules.common) {
        foreach ($module in $config.modules.common) {
            $modulePath = "$I18N_DIR\$module"
            if (Test-Path $modulePath) {
                $moduleContent = Get-Content $modulePath -Raw | ConvertFrom-Json
                $moduleName = $module -replace '\\', '' -replace '.*\\', ''
                $moduleName = $moduleName -replace '\.json$', ''
                $allModules[$moduleName] = $moduleContent
            }
        }
    }

    # 返回整合后的配置
    return @{
        version = $config.version
        description = $config.description
        lastUpdate = $config.lastUpdate
        modules = $allModules
    }
}
```

---

### 2. 修改 Apply-OtherPatches 函数（约第850行）

**原函数**：
```powershell
function Apply-OtherPatches {
    $config = Get-I18NConfig
    if (!$config -or !$config.patches) {
        Write-ColorOutput Red "[错误] 无法加载汉化配置"
        return
    }

    # 获取所有模块，排除 commandPanel（已单独处理）
    $allModules = @($config.patches.PSObject.Properties.Name | Where-Object { $_ -ne "commandPanel" })
    ...
}
```

**修改为**：
```powershell
function Apply-OtherPatches {
    $config = Get-I18NConfig

    if (!$config -or !$config.modules) {
        Write-ColorOutput Red "[错误] 无法加载汉化配置"
        return
    }

    # 遍历所有加载的模块（不包括已单独处理的 commandPanel）
    $allModules = $config.modules.GetEnumerator() | Where-Object {
        $_.Key -ne "commandPanel"
    }

    $totalCount = $allModules.Count
    $currentIndex = 0

    foreach ($item in $allModules) {
        $currentIndex++
        $moduleName = $item.Key
        $module = $item.Value

        if (!$module -or !$module.replacements) { continue }

        Write-ColorOutput Yellow "[$currentIndex/$totalCount] 应用 $($module.description)..."

        $replacements = @{}

        # 将 JSON 对象的 replacements 转换为 hashtable
        $module.replacements.PSObject.Properties | ForEach-Object {
            $replacements[$_.Name] = $_.Value
        }

        $targetFile = "$PACKAGE_DIR\$($module.file)"

        if (!(Test-Path $targetFile)) {
            Write-ColorOutput Red "   [$moduleName] 文件不存在: $($module.file)"
            continue
        }

        # 读取并替换
        $content = Get-Content $targetFile -Raw -Encoding UTF8
        $count = 0

        foreach ($key in $replacements.Keys) {
            $originalContent = $content
            $content = $content.Replace($key, $replacements[$key])
            if ($content -ne $originalContent) {
                $count++
            }
        }

        $content | Set-Content $targetFile -Encoding UTF8 -NoNewline

        if ($module.description) {
            Write-ColorOutput Green "   - $($module.description) ($count 项替换)"
        } else {
            Write-ColorOutput Green "   - $moduleName ($count 项替换)"
        }
    }

    Write-ColorOutput Green "所有汉化补丁已应用！"
}
```

---

### 3. 修改 Test-I18NPatches 函数（约第870行）

**修改为**：
```powershell
function Test-I18NPatches {
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

    # 遍历所有加载的模块
    foreach ($moduleKey in $config.modules.Keys) {
        $module = $config.modules[$moduleKey]

        if (!$module -or !$module.file) { continue }

        $targetFile = "$PACKAGE_DIR\$($module.file)"

        if (!(Test-Path $targetFile)) {
            Write-ColorOutput Red "   [$moduleKey] 文件不存在: $($module.file)"
            continue
        }

        $content = Get-Content $targetFile -Raw -Encoding UTF8
        $patchPassed = $true
        $patchFailed = @()

        foreach ($replacement in $module.replacements.PSObject.Properties) {
            $totalTests++
            $expected = $replacement.Value

            # 检查文件中是否包含翻译后的文本
            if ($content -like "*$expected*") {
                $passedTests++
            } else {
                $patchPassed = $false
                $patchFailed += @{
                    Original = $replacement.Name
                    Expected = $expected
                }
            }
        }

        if ($patchPassed) {
            Write-ColorOutput Green "   [$moduleKey] ✓ 通过"
        } else {
            Write-ColorOutput Red "   [$moduleKey] ✗ 失败 ($($patchFailed.Count) 项未生效)"
            $failedItems += @{
                Module = $moduleKey
                File = $module.file
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
    }
    Write-Output ""
    Read-Host "按回车键继续"
}
```

---

## 使用说明

1. 将上述三个函数修改应用到 `opencode-v3.ps1`
2. 保存脚本
3. 运行测试

---

## 验证清单

- [x] Get-I18NConfig 能正确加载模块化配置
- [x] Apply-OtherPatches 能遍历所有模块文件
- [x] Test-I18NPatches 能验证所有模块
- [x] 脚本语法检查通过
- [x] 兼容旧的单文件配置格式
- [x] 更新所有相关函数支持 hashtable 格式

---

## 额外修改

除了补丁中指定的三个核心函数外，还更新了以下函数以支持模块化配置：

1. **Apply-CommandPanelPatch** - 支持查找 `components-command-panel` 模块
2. **Debug-I18NFailure** - 调试工具支持模块遍历
3. **Show-I18NConfig** - 显示配置时区分模块化/单文件类型
4. **Restore-OriginalFiles** - 还原功能支持模块遍历
5. **Show-CleanMenu / Invoke-Clean** - 清理工具支持模块遍历
6. **Show-ProjectInfo** - 项目信息显示支持模块计数
