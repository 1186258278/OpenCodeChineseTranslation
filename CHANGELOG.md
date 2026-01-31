# 更新日志 / Changelog

本文档记录 OpenCode 中文汉化版的所有重要更改。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

---

## [8.6.1] - 2026-01-31

### 🐛 问题修复

- **Linux/macOS 权限错误** - 修复部署后运行 opencode 出现 "Permission denied" 的问题 (Fixes #13)
  - `deploy` 命令现在会自动设置 `chmod +x` 执行权限
  - `download` 命令解压 ZIP 后也会自动设置权限
  - 不再依赖 ZIP 文件携带的权限信息

### ✨ 增强功能

- **env-install 非交互模式** - 新增 CI/CD 友好的命令行参数
  - `--yes/-y`: 自动确认，跳过交互提示
  - `--all/-a`: 一键安装全部缺失环境
  - `--npm-version`: 指定 npm 版本 (如 `latest`, `10`, `9.8.0`)
- **verify 覆盖率优化** - 更精确的汉化覆盖率检测
  - 区分 UI 文件和纯代码文件，避免误报
  - 纯代码文件 (无需翻译) 不计入覆盖率统计
- **单元测试** - 新增 i18n 核心函数测试
  - 18 个测试用例，覆盖配置加载、路径解析、替换逻辑等

### 📝 文档优化

- **README 汉化统计** - 新增翻译文件/规则数量统计表格
- **config.json 规范化** - 添加 `upstream`、`name` 字段，便于追踪上游仓库

---

## [8.6.0] - 2026-01-27

### 🚀 全平台与视觉增强

- **全平台构建支持** - 新增对 Windows ARM64、macOS Intel (x64) 和 Linux ARM64 的官方构建支持
  - 现在覆盖了 Windows (x64/ARM64)、macOS (Apple Silicon/Intel)、Linux (x64/ARM64)
- **视觉模型配置修复** - 修复 Antigravity Tools 配置生成逻辑
  - 正确启用 Gemini/Claude 的 `attachment` 和 `modalities` 属性
  - 修复 OpenCode 中回形针图标不显示/无法识别图片的问题
- **Windows 部署修复** - 彻底解决 Windows 下部署时版本回退的问题
  - 实现“自我复制”更新机制，确保部署的是当前运行的最新二进制文件
  - 自动清理 `npm`/`bun` 残留的全局冲突脚本 (shim files)
- **配置安全性增强** - 重构配置写入逻辑，实现非破坏性更新
  - 在更新 Antigravity 配置时，不再覆盖用户的自定义插件和其他 Provider 配置

### ✨ 新增功能

- **诊断修复** (`diagnose`) - 自动检测并修复常见问题
  - 检测多版本 opencode 冲突 (npm/scoop/brew 安装的官方版)
  - 检测编译环境缺失 (Git/Node.js/Bun)
  - 检测 macOS 签名隔离问题，检测 PATH 配置异常
  - 支持 `--fix` 一键自动修复
- **卸载清理** (`uninstall`) - 一键还原干净环境
  - 清理 CLI 工具、源码目录、配置文件，自动移除 PATH 条目
  - 支持 `--all` 完全清理，`--keep-config` 保留配置
- **环境安装** (`env-install`) - 一键安装编译环境
  - 自动检测并安装 Git/Node.js/Bun
  - 支持 Windows (winget/scoop/choco)、macOS (brew)、Linux (apt/dnf/yum/pacman)

### 🛠️ 开发者体验

- **命令帮助全中文化** - 所有命令的 Short 描述统一为中文
- **安装脚本升级** - 支持指定版本安装 (`--version nightly`)，方便测试和尝鲜
- **官网入口优化** - 主页新增 Nightly 构建切换开关，直达每日最新版本
- **文档更新** - 重写 `CONTRIBUTING.md`，适配最新的 Go CLI 工作流
- **发布脚本升级** - `release.ps1` 支持自动更新官网版本号和多平台下载链接

### 🐛 问题修复

- **汉化配置优化** - 修复重复配置导致的应用失败，新增遗漏翻译
  - 删除重复的 `contexts/context-local.json`（与 `common/local-context.json` 冲突）
  - 新增 `title: "Line up/down"` 翻译（向上/向下滚动）
  - 新增 `title: "toggle"` 翻译（MCP 切换）
  - 新增 `label: "API key"` 翻译
- **全平台构建修复** - 修复 macOS Intel (x64) 平台无法构建的问题 (Fixes #9)
- **环境部署修正** - 修复 Antigravity 和 OhMyOC 快捷部署配置不准确的问题 (Ref #8)
- **汉化流程简化** - 汉化资源内嵌于 CLI 工具，不再强制要求拉取完整项目即可应用汉化 (Ref #8)
- **PowerShell 安装脚本修复** - 修复语法错误导致的解析失败 (Fixes #12)
- **三端目录完全统一** - 所有目录归一到 `~/.opencode-i18n/` 下
  - `bin/` - CLI 工具和汉化版 OpenCode
  - `opencode/` - OpenCode 官方源码
  - `build/` - 编译输出目录
- **开发者支持** - 通过环境变量覆盖默认路径
  - `OPENCODE_SOURCE_DIR` - 覆盖源码目录
  - `OPENCODE_BUILD_DIR` - 覆盖编译输出目录
- **诊断增强** - `diagnose` 命令新增检测
  - 检测所有 opencode-cli 安装位置和版本
  - 检测 PATH 优先级问题（旧版本在新版本前面）
  - 检测 PATH 重复项，一键清理优化

---

## [8.4.0] - 2026-01-24

### 🤖 自动化构建增强

- **Nightly Build 工作流** - 新增 `.github/workflows/nightly.yml`，实现自动跟进上游更新
  - **每小时检测**: 每小时第 0 分钟自动检查 `anomalyco/opencode` 的 `dev` 分支
  - **智能阈值**: 累计 ≥5 个新 commit 时才触发构建，避免频繁构建
  - **增量检测**: 使用 `.nightly-state` 文件记录上次构建的 commit SHA
  - **完整 Changelog**: Release Notes 自动包含上游 OpenCode 的更新日志
  - **固定 Tag**: 发布到固定 `nightly` tag，每次覆盖更新，下载链接始终指向最新版
  - **手动触发**: 支持 `force_build` 强制构建，支持自定义 `min_commits` 阈值

- **文档更新**
  - `AI_MAINTENANCE.md` - 新增"自动化构建 (CI/CD)"章节，详细说明 Nightly 与 Release 工作流
  - `CONTRIBUTING.md` - 新增 CI/CD 工作流说明，包含触发方式和对比表

---

## [8.3.0] - 2026-01-23

### 🚀 架构升级与体验优化

- **自动化发布系统** - 新增 `scripts/release.ps1`，一键自动更新版本号、文档和安装脚本，杜绝版本不一致问题
- **离线安装支持** - 安装脚本 (`install.ps1/sh`) 现在优先检测本地安装包
  - 自动识别同目录下的 `opencode-cli` 二进制文件
  - 支持在无网络环境下手动下载文件后安装
- **GLIBC 兼容性修复** - Linux 二进制文件改为静态链接 (`CGO_ENABLED=0`)
  - 彻底解决旧版 Linux (如 CentOS 7, Ubuntu 18.04) 提示 `GLIBC_2.34 not found` 的问题
- **安装源优化** - 默认安装命令切换为 jsDelivr CDN 加速
  - 解决国内 PowerShell `irm` 无法解析 `raw.githubusercontent.com` 的问题

### 📝 文档更新

- **CONTRIBUTING.md** - 更新版本管理规范，明确使用 `release.ps1` 进行发版
- **官网重构** - 更新视觉图，新增 CLI 工具独立下载入口

---

## [8.2.0] - 2026-01-23 (Internal Release)

- 内部测试版本，包含版本号统一重构
- 官网视觉更新 (01-05.png)

---

## [8.1.0] - 2026-01-23

### 🚀 新增功能

- **下载预编译版** - 新增 `[D] 下载预编译版` 菜单项，无需本地编译环境即可安装汉化版
  - 自动从 GitHub Releases 获取最新版本
  - 智能检测当前平台（Windows/macOS/Linux）
  - 自动解压、部署并配置 PATH 环境变量
  - 适用于无法安装 Bun/Node.js 的用户
  - **修复**: 支持新旧两种文件名格式 (`opencode-zh-CN-v8.1.0-windows-x64.zip`)
- **智谱编码助手** - 修正助手安装功能，改为官方 `@z_ai/coding-helper` 包
  - NPM 包：`@z_ai/coding-helper`
  - 用于统一管理 Claude Code 等 CLI 工具
  - 新增 Node.js >= v18.0.0 版本检测和安装指引

### 🔄 CI/CD 工作流重构 (release.yml)

- **Go CLI 驱动** - 弃用旧版 JS 脚本，改用 Go CLI 驱动全流程
  - `./opencode-cli apply` - 应用汉化
  - `./opencode-cli build --platform xxx` - 交叉编译
- **多平台并行构建** - 使用 GitHub Actions Matrix 同时构建 Windows/macOS/Linux
- **输出文件规范** - 统一命名格式 `opencode-zh-CN-{version}-{platform}.zip`
- **手动触发支持** - 新增 `workflow_dispatch` 可指定版本号手动发布

### 🛡️ 安全增强

- **update.go 安全检查** - 更新源码时验证远程 URL，防止误操作覆盖汉化项目仓库
  ```go
  if strings.Contains(currentRemote, "OpenCodeChineseTranslation") {
      // 中止操作，防止覆盖工作目录
  }
  ```

### 🔧 代码质量改进

- **消除函数重复定义** - 重构公共函数到 `utils.go`
  - `FileExists()` / `DirExists()` - 文件/目录存在检测
  - `Truncate()` - 字符串截断
  - `DetectPlatform()` - 平台检测
- **修复目录切换问题** - `git.go` 中不再使用 `os.Chdir()` 改变全局工作目录
  - 新增 `ExecInDir()` 和 `ExecInDirQuiet()` 函数
- **清理死代码** - 移除 `update.go` 中注释掉的代码
- **版本号统一** - 所有安装脚本和文档默认版本号更新到 v8.1.0

### 📝 文档更新

- **install.ps1 / install.sh** - 默认版本号更新到 v8.1.0
- **docs/index.html** - 官网默认版本号更新
- **README.md** - 新增 `opencode-cli download` 命令说明

---

## [8.0.0] - 2026-01-23 🎉 架构重构

### 🚀 全二进制分发架构

- **Go 语言重写** - 核心管理工具 (`opencode-cli`) 使用 Go 语言完全重写，实现单文件运行。
- **零依赖安装** - 彻底移除 Node.js/Bun 运行时依赖，用户下载即用 (文件大小仅约 7MB)。
- **全平台支持** - 提供 Windows (exe)、macOS (Apple Silicon)、Linux 原生二进制文件。

### 🛠️ 功能增强与规范

- **命令更名** - 管理工具命令统一为 `opencode-cli`，避免与官方 `opencode` 软件命令冲突。
- **桌面快捷方式** - `deploy` 命令支持创建 **"OpenCode CLI"** 桌面快捷方式，方便快速启动。
- **自动更新检测** - 实时检测 CLI 自身及 OpenCode 源码的更新状态。
- **更新日志查看** - 新增 `[L] 更新日志` 功能，可直接查看 OpenCode 官方提交记录。

### 📦 安装脚本升级

- **极速安装** - 新版安装脚本直接从 GitHub Release 下载二进制文件，秒级完成安装。
- **环境隔离** - 安装到用户目录 (`~/.opencode-i18n`)，不污染系统环境。

### 🧹 清理与精简

- **移除冗余备份机制** - 删除 `.i18n-backup` 文件备份功能，完全依赖 Git 进行版本控制和回滚。
  - 删除 `backup.go` 和 `rollback.go`
  - 移除菜单中的"回滚备份"选项
  - 使用 `git checkout/clean` (恢复源码功能) 替代文件系统备份
- **Legacy 迁移** - 旧版 JavaScript 脚本 (`scripts/`) 已移入 `legacy/` 目录并停止维护。

## [7.3.2] - 2026-01-23 (Legacy)

### 🚀 自动化与体验升级

- **一键安装脚本** - (旧版) 支持自动检测和安装 Node.js/Bun 环境
- **Release 日志增强** - 自动抓取 OpenCode 官方仓库最近 15 次提交记录
- **文档优化** - README 新增下载徽章

## [7.2.2] - 2026-01-22

### 📝 文档与发布优化

- **发布样式优化** - GitHub Release 标题现在包含完整的版本名称 (如 "OpenCode 中文汉化版 v7.2.2")
- **文档增强** - README 新增最新版本下载徽章和快捷链接，方便用户直接获取

## [7.2.1] - 2026-01-22

### 🐛 修复

- **版本号同步** - 修复打包脚本读取旧版本号导致发布失败的问题
- **统一版本源** - 确保所有工具统一从 `scripts/core/version.js` 读取版本

## [7.2.0] - 2026-01-22

### 🚀 自动化发布与缓存修复

- **清理缓存功能** - 主菜单新增 `[C] 清理缓存` 选项，解决 `bun install` 时的 EPERM 权限报错 (Fixes #3)
- **智能自动化发布** - 集成 GitHub Actions 自动化工作流，支持一键发布新版本
  - **自动三端构建** - 打 `v*` 标签时自动编译 Windows/macOS/Linux 二进制包
  - **汉化工具打包** - 自动打包 `opencode-i18n-tool.zip` (源码便携版)
  - **手动触发支持** - 支持手动触发发布，并可选择跳过耗时的二进制编译
- **提交规范** - 新增 `CONTRIBUTING.md` 贡献指南，规范化版本管理和代码提交

---

## [7.1.0] - 2026-01-21

### 🛠️ 环境修复与增强

- **Bun 版本校准** - 新增 Bun 版本自动检测与校准功能
- **Windows 兼容性修复** - 解决 Bun v1.3.6 在 Windows 下的 EPERM 权限错误 (Fixes #1)
- **智能交互** - 环境检查 (`env`) 和新菜单项 (`[B] 校准 Bun`) 支持一键自动降级到推荐版本

### 🎨 界面更新

- **状态栏增强** - 主菜单状态栏实时显示 Bun 版本状态（匹配/不匹配/未安装）
- **修复提示** - 版本不匹配时显示醒目的红色警告和推荐版本

---

## [7.0.0] - 2025-01-18 🎉 大版本更新

### 🎨 全新 TUI 界面

- **网格菜单布局** - 3 列网格布局，更直观的功能选择
- **键盘导航** - 支持 ↑↓←→ 方向键、1-9 数字快捷键、Q 快速退出
- **备用屏幕缓冲区** - 使用 ANSI 转义序列实现干净的全屏体验
- **终端居中显示** - 固定宽度 72 字符，自动居中适配各种终端宽度

### 🔄 异步更新检测

- **汉化脚本更新检测** - 通过 `git fetch` 异步检测是否有新版本
- **OpenCode 源码更新检测** - 实时检测上游是否有更新
- **动态状态刷新** - 检测完成后自动更新界面状态栏
- **清晰的状态显示** - 分别显示「汉化脚本最新」和「OpenCode最新」

### 🖥️ 三端兼容性

- **Windows 适配** - PowerShell 集成、PATH 环境变量管理
- **macOS 适配** - Apple Silicon 支持、.app 包创建
- **Linux 适配** - .desktop 快捷方式、shell 配置文件更新
- **统一平台抽象** - `platforms/` 目录提供跨平台 API

### ⚡ 体验优化

- **操作可见性** - 命令输出在主屏幕显示，不再被备用屏幕遮挡
- **优雅退出** - 选择退出后直接关闭，无需 Ctrl+C
- **状态一目了然** - 源码/汉化/编译状态实时显示
- **错误处理改进** - 更友好的错误提示和恢复建议

### 🔧 技术改进

- **`grid-menu.js`** - 全新的网格菜单模块
- **`menu.js` 重构** - 异步更新检测、状态管理优化
- **`utils.js` 修复** - `execLive` 函数三端兼容性修复
- **`windows.js` 修复** - `isInPath` 函数性能优化

---

## [6.0.0] - 2025-01-14

### 🚀 重大更新

- **统一 CLI 工具** - `opencodenpm` 命令取代原有 PowerShell 脚本
- **项目结构重构** - 移除 `-v2` 后缀，统一命名规范
- **Node.js 实现** - 从 PowerShell 迁移到 Node.js，提升跨平台兼容性

### 📦 新增功能

- `opencodenpm deploy` - 部署全局命令
- `opencodenpm package` - 打包三端发布版本
- `opencodenpm rollback` - 回滚到备份版本
- `opencodenpm helper` - 智谱编程助手集成

### 📝 文档

- 添加 Oh My OpenCode 完整使用指南
- 添加 Antigravity Tools 集成教程
- 添加 AI 维护指南

---

## [5.2] - 2026-01-10

### 修复
- 修复汉化配置破坏代码的问题（使用更精确的替换模式）
- 修复 dialog-help.json：`"Help"` → `"Help\n"`
- 修复 dialog-status.json：`"Status"` → `"Status\n"`
- 修复 route-sidebar.json：`"active"` → `"} active"`
- 移除过时的翻译配置项

### 安全增强
- 确保汉化不会破坏代码标识符
- 所有替换规则使用更精确的模式匹配

---

## [5.1] - 2026-01-10

### 新增
- 添加语言包版本适配检测功能
- 显示版本不匹配警告和维护者联系方式

### 修复
- 修复验证失败的2个模块配置（删除过时的替换项）

### 文档
- 添加版本适配说明和联系方式

---

## [5.0] - 2026-01-10

### 优化
- 优化文件标记速度：批量处理（500个文件/批）
- 添加配置加载和应用补丁的进度提示
- 简化应用补丁的输出格式

### 修复
- 修复 git fetch refspec 解析错误（使用 PowerShell 数组传递参数）

---

## [4.9] - 2026-01-10

### 修复
- 修复 git fetch refspec 解析错误（使用 PowerShell 数组传递参数）
- 修复字符串插值导致的 refspec 格式问题

---

## [4.8] - 2026-01-10

### 优化
- 优化代理检测：Clash 端口 7897/7898 优先检测
- 增加超时时间到 2 秒，提高检测成功率

---

## [4.7] - 2026-01-10

### 修复
- 修复批量处理参数过长问题（改为分批500个文件处理）
- 增加更多常见代理端口检测

---

## [4.6] - 2026-01-10

### 优化
- 文件忽略标记解除改为批量处理（2689个文件从分钟级降到秒级）
- git pull 改为指定分支拉取，避免多分支合并冲突

---

## [4.5] - 2026-01-09

### 新增
- 错误消息汉化：剪贴板复制失败提示
- 验证脚本新增字符串匹配测试

### 修复
- 修复验证脚本字符串匹配问题（使用 IndexOf 替代 -like）
- 修复模板字符串变量展开导致的匹配失败

### 文档
- 文档专业化重写，移除 AI 风格表达
- 新增系统兼容性详细说明
- 新增三种部署方式说明
- 新增代理自动检测说明

---

## [4.3] - 2026-01-08

### 新增
- 自动检测本地代理功能（支持 Clash、V2RayN、Surge 等）
- 版本检测页面新增"是否立即更新？"交互选项
- 主菜单新增 `[2] 应用汉化` 选项
- 主菜单新增 `[3] 验证汉化` 选项

### 优化
- 菜单结构优化，将常用功能提升至主菜单
- 高级菜单新增 `[4] 验证汉化` 选项

### 修复
- 修复 assume-unchanged 标记导致 Git Pull 无法更新文件的问题
- 修复版本检测后源码未更新问题
- 修复 Load-Modules 函数作用域问题（通过参数传递 hashtable）

---

## [4.0] - 2026-01-07

### 重构
- 配置文件模块化重构，将单一 JSON 拆分为 36 个独立模块
- 新增按类别组织的配置结构（dialogs、routes、components、common）
- 支持独立模块管理和测试

### 新增
- 模块化验证脚本，支持单独验证各模块
- 配置版本控制机制

---

## [3.1] - 2026-01-06

### 优化
- 菜单项重新排序，常用功能前置
- 改进版本检测输出格式

### 修复
- 修复版本检测显示错误问题
- 修复菜单选项对应关系

---

## [3.0] - 2026-01-05

### 新增
- 一键汉化+部署功能
- 交互式菜单系统
- 自动化拉取、汉化、编译、部署全流程

---

## [1.0] - 2025-12-01

### 初始版本
- 基础汉化配置
- 手动应用脚本
- 支持 OpenCode 基础功能中文化

---

## 版本说明

| 版本类型 | 说明 |
|----------|------|
| Major (主版本) | 架构重构、不兼容更改 |
| Minor (次版本) | 新增功能、模块扩展 |
| Patch (修订版) | Bug 修复、文档更新 |

---

## 路线图

### 计划中
- [ ] 支持更多第三方模型界面汉化
- [ ] 添加翻译贡献者系统
- [ ] 支持自定义翻译覆盖
- [ ] 添加 GUI 配置工具
- [ ] **TODO: 支持 AI 系统提示词 (System Prompts) 汉化**

---

## 链接

- [版本对比](https://github.com/1186258278/OpenCodeChineseTranslation/compare)
- [问题反馈](https://github.com/1186258278/OpenCodeChineseTranslation/issues)
- [贡献指南](CONTRIBUTING.md)
