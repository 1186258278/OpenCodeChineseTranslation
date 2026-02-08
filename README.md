# OpenCode 中文汉化发行版

[![Release](https://img.shields.io/github/v/release/1186258278/OpenCodeChineseTranslation?label=最新正式版&style=flat-square&color=blue)](https://github.com/1186258278/OpenCodeChineseTranslation/releases/latest)
[![Nightly](https://img.shields.io/badge/Nightly-自动构建-orange?style=flat-square)](https://github.com/1186258278/OpenCodeChineseTranslation/releases/tag/nightly)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg?style=flat-square)](#)
[![Build Status](https://img.shields.io/github/actions/workflow/status/1186258278/OpenCodeChineseTranslation/release.yml?label=构建状态&style=flat-square)](https://github.com/1186258278/OpenCodeChineseTranslation/actions)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)

> 🚀 **OpenCode 汉化发行版** | ⚡️ **每小时自动同步官方更新** | 全自动构建三端安装包 (Win/Mac/Linux)
> 
> 🔥 **每日构建 (Nightly)**：[点击下载最新开发版](https://github.com/1186258278/OpenCodeChineseTranslation/releases/tag/nightly) (每小时更新 · 推荐开发者)
> 
> 🎉 **访问官方网站**：[https://1186258278.github.io/OpenCodeChineseTranslation/](https://1186258278.github.io/OpenCodeChineseTranslation/)

---

## 项目简介

**OpenCode 汉化发行版** 是一个全自动化的 OpenCode 本地化项目。我们基于 GitHub Actions 构建了一套完整的自动化流水线：

- **🕐 每小时检测** 官方仓库更新
- **📊 智能触发** 累计 ≥5 个新 commit 时自动构建
- **📝 完整日志** Release Notes 自动包含官方更新日志

**主要特性：**
*   ⚡️ **实时跟进**：每小时检测上游更新，第一时间体验新特性
*   📦 **全平台支持**：提供 Windows、macOS (Apple Silicon)、Linux 二进制包
*   🚀 **一键安装**：Go 语言编写的管理工具，无需任何运行时依赖
*   🔧 **完整汉化**：覆盖 TUI、对话框及核心交互流程

### 📊 汉化统计

| 指标 | 数量 | 说明 |
|------|------|------|
| 📁 翻译文件 | **41** 个 | 模块化 JSON 配置 |
| 📝 翻译规则 | **397** 条 | 精准字符串替换 |
| 🎯 覆盖模块 | **5** 个 | dialogs/routes/components/common/root |
| ✅ 测试覆盖 | **100%** | 18 个单元测试用例 |

<details>
<summary>📂 模块分布详情</summary>

| 分类 | 文件数 | 说明 |
|------|--------|------|
| **dialogs** | 21 | 对话框 (Agent/Model/MCP/Session 等) |
| **routes** | 6 | 路由页面 (Home/Session/Sidebar 等) |
| **components** | 6 | 组件 (Prompt/Question/Sidebar 等) |
| **common** | 6 | 通用 (Toast/Error/Messages 等) |
| **root** | 1 | 应用入口 |

</details>

---

## 界面预览

### CLI 管理工具

<p align="center">
  <img src="docs/01.png" alt="OpenCode 汉化管理工具" width="800">
</p>

**全功能 TUI 界面** - 一键完成更新、汉化、编译、部署

### 汉化后的 OpenCode

<p align="center">
  <img src="docs/02.png" alt="OpenCode 主编辑器" width="800">
</p>

**沉浸式中文编程体验** - 命令面板、侧边栏、对话框完整汉化

### MCP 服务器配置

<p align="center">
  <img src="docs/05.png" alt="MCP 配置界面" width="800">
</p>

**MCP 服务器管理** - 状态监控、工具配置、资源管理

> 📸 更多截图请查看 [功能演示文档](docs/SCREENSHOTS.md)

---

## 快速开始

### 1. 一键安装 (推荐)

全新的安装脚本会自动下载 **Go 版本 CLI 工具**，无需安装 Node.js 或 Bun。

**Windows (PowerShell)**
```powershell
powershell -c "irm https://cdn.jsdelivr.net/gh/1186258278/OpenCodeChineseTranslation@main/install.ps1 | iex"
```

**Linux / macOS**
```bash
curl -fsSL https://cdn.jsdelivr.net/gh/1186258278/OpenCodeChineseTranslation@main/install.sh | bash
```

> 💡 使用 jsDelivr CDN 加速，解决国内网络问题

### 2. 使用方法

安装完成后，直接在终端运行：

```bash
opencode-cli
```

启动交互式菜单，通过方向键选择功能。

### 3. 下载预编译版 (推荐新手)

如果您已安装 `opencode-cli`，可以直接使用内置的下载功能：

```bash
opencode-cli download
```

此命令会自动从 GitHub Releases 下载最新的预编译汉化版 OpenCode，无需本地编译环境。

### 4. 手动下载

**稳定版 (Stable)** - 推荐普通用户使用：
访问 [Releases 页面](https://github.com/1186258278/OpenCodeChineseTranslation/releases/latest) 下载最新 v8.x.x 版本。

**每日构建 (Nightly)** - 推荐开发者/尝鲜用户：
访问 [Nightly 页面](https://github.com/1186258278/OpenCodeChineseTranslation/releases/tag/nightly) 下载最新自动构建版本。

| 平台 | 管理工具 (CLI) |
|------|----------------|
| Windows x64 | [opencode-cli-windows-amd64.exe](https://github.com/1186258278/OpenCodeChineseTranslation/releases/latest/download/opencode-cli-windows-amd64.exe) |
| Windows ARM64 | [opencode-cli-windows-arm64.exe](https://github.com/1186258278/OpenCodeChineseTranslation/releases/latest/download/opencode-cli-windows-arm64.exe) |
| macOS Apple Silicon | [opencode-cli-darwin-arm64](https://github.com/1186258278/OpenCodeChineseTranslation/releases/latest/download/opencode-cli-darwin-arm64) |
| macOS Intel | [opencode-cli-darwin-amd64](https://github.com/1186258278/OpenCodeChineseTranslation/releases/latest/download/opencode-cli-darwin-amd64) |
| Linux x64 | [opencode-cli-linux-amd64](https://github.com/1186258278/OpenCodeChineseTranslation/releases/latest/download/opencode-cli-linux-amd64) |
| Linux ARM64 | [opencode-cli-linux-arm64](https://github.com/1186258278/OpenCodeChineseTranslation/releases/latest/download/opencode-cli-linux-arm64) |

> 💡 **提示**: 汉化版 OpenCode 请在 [Releases 页面](https://github.com/1186258278/OpenCodeChineseTranslation/releases/latest) 下载 ZIP 包。[Nightly 构建](https://github.com/1186258278/OpenCodeChineseTranslation/releases/tag/nightly) 每小时更新。

---

## 版本说明

本项目提供两种版本：

| 版本 | Tag | 说明 | 推荐用户 |
|------|-----|------|----------|
| **正式版** | `v8.x.x` | 经过测试的稳定版本 | 普通用户 |
| **Nightly** | `nightly` | 每小时自动跟进上游更新 | 开发者/测试者 |

**Nightly 版本特点：**
- 每小时检测上游更新，累计 ≥5 个 commit 时自动构建
- Release Notes 包含 OpenCode 官方更新日志
- 固定 `nightly` tag，下载链接始终指向最新构建

---

## CLI 工具功能

| 命令 | 说明 |
|------|------|
| `opencode-cli` | 启动交互式管理菜单 |
| `opencode-cli download` | 下载预编译汉化版，无需本地编译环境 |
| `opencode-cli env-install` | 一键安装编译环境 (Git/Node.js/Bun) |
| `opencode-cli update` | 更新 OpenCode 源码 |
| `opencode-cli apply` | 应用汉化补丁 |
| `opencode-cli verify` | 验证汉化配置完整性 |
| `opencode-cli build` | 编译构建 OpenCode |
| `opencode-cli deploy` | 部署到系统 PATH |
| `opencode-cli diagnose` | **诊断修复** 版本冲突、环境问题 |
| `opencode-cli uninstall` | 卸载清理，还原干净环境 |
| `opencode-cli antigravity` | 配置 Antigravity 本地 AI 代理 |

---

## 相关文档

| 文档 | 说明 |
|------|------|
| [📅 更新日志](CHANGELOG.md) | 版本更新记录 |
| [📸 功能截图](docs/SCREENSHOTS.md) | 界面预览与演示 |
| [🔧 贡献指南](CONTRIBUTING.md) | 开发者参与指南 |
| [🚀 Antigravity 集成](docs/ANTIGRAVITY_INTEGRATION.md) | 本地 AI 网关配置 |
| [🤖 AI 维护指南](docs/AI_MAINTENANCE.md) | AI 助手维护手册 |

---

## 环境要求

**使用预编译版（推荐新手）**：无需任何环境，直接下载运行。

**本地编译**：
- Git (用于拉取源码)
- Node.js 18+ (OpenCode 依赖)
- Bun 1.3.8+ (构建工具，需与上游 OpenCode 版本匹配)

> 没装这些？运行 `opencode-cli env-install` 一键搞定。

---

## 常见问题 (FAQ)

### 遇到问题？先运行诊断！
```bash
opencode-cli diagnose
```
自动检测版本冲突、环境缺失、PATH 问题，一键修复。

---

### Q: 运行 opencode 还是英文版？
运行 `opencode-cli diagnose` 自动检测并清理冲突版本。

手动处理：
```bash
npm uninstall -g opencode          # 卸载 npm 版
Get-Command opencode -All          # Windows 查看所有位置
which -a opencode                  # macOS/Linux
```

### Q: 编译失败？
```bash
opencode-cli env-install    # 一键安装 Git/Node/Bun
opencode-cli download       # 或直接下载预编译版（不用装环境）
```

### Q: 汉化失效了？
下载 [Nightly 版本](https://github.com/1186258278/OpenCodeChineseTranslation/releases/tag/nightly)（每小时自动跟进官方更新）

### Q: 安装目录在哪？
三端统一目录结构 `~/.opencode-i18n/`：
- `bin/` - CLI 工具和汉化版 OpenCode
- `opencode/` - OpenCode 源码
- `build/` - 编译输出

Windows 实际路径: `%USERPROFILE%\.opencode-i18n\`

### Q: 本地开发怎么配置？
开发者可通过环境变量覆盖默认路径：
```bash
export OPENCODE_SOURCE_DIR=/path/to/opencode   # 源码目录（覆盖 ~/.opencode-i18n/opencode）
export OPENCODE_BUILD_DIR=/path/to/bin         # 编译输出（覆盖 ~/.opencode-i18n/build）
```
不设置环境变量时，统一使用 `~/.opencode-i18n/` 目录。

### Q: 想卸载干净？
```bash
opencode-cli uninstall --all
```

### Q: macOS 提示"无法验证开发者"？
```bash
xattr -cr /path/to/opencode
```
或运行 `opencode-cli diagnose --fix` 自动修复。

---

## 许可证

本项目基于 [MIT License](LICENSE) 开源。

OpenCode 原项目版权归 [Anomaly Company](https://anomaly.company/) 所有。
