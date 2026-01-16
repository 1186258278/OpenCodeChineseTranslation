# OpenCode 中文汉化版

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/i18n-v6.0-green.svg)](opencode-i18n)
[![AI](https://img.shields.io/badge/AI%20%E7%BB%B4%E6%8A%A4-purple.svg)](docs/AI_MAINTENANCE.md)

[中文](#中文文档) | [English](#english-documentation)

---

## 中文文档

### 项目简介

> **OpenCode** 是由 [Anomaly Company](https://anomaly.company/) 开发的**开源 AI 编程代理**，提供终端界面 (TUI)、桌面应用和 IDE 扩展等多种使用方式。

**OpenCode 中文汉化版**是对 OpenCode 项目的本地化改造，通过模块化汉化配置和自动化脚本实现完整中文化，降低国内用户使用门槛。

<!-- 截图展示 -->
<p align="center">
  <img src="docs/0.png" alt="OpenCode 主界面" width="800">
  <img src="docs/1.png" alt="Plan 模式" width="800">
  <img src="docs/2.png" alt="AI 对话" width="800">
</p>

<!-- 汉化效果展示 -->
<p align="center">
  <img src="docs/3.png" alt="MCP 服务器汉化" width="800">
  <img src="docs/4.png" alt="状态对话框汉化" width="800">
</p>

**核心功能：**
- 🤖 AI 辅助编程 - 解释代码、添加功能、重构修改
- 📋 Plan 模式 - 先规划后实施，支持图片参考和迭代讨论
- ↩️ 撤销/重做 - `/undo` 和 `/redo` 命令轻松回退
- 🔗 对话分享 - 生成链接与团队协作
- 🔌 多模型支持 - 兼容各类 LLM 提供商

---

### 🚀 快速开始

#### 方式一：使用预编译版本（推荐）

[下载预编译版本](https://github.com/1186258278/OpenCodeChineseTranslation/releases)

```powershell
# Windows - 下载后直接运行
opencode.exe

# Linux/macOS - 下载后添加执行权限
chmod +x opencode
./opencode
```

#### 方式二：完整安装

##### 步骤 1：安装 opencodenpm 管理工具

```bash
# 全局安装 npm 包
npm install -g opencodenpm

# 或从本地安装
cd /path/to/OpenCodeChineseTranslation/scripts
npm install -g .
```

##### 步骤 2：检查编译环境

```bash
opencodenpm env
```

##### 步骤 3：完整工作流

```bash
# 交互式菜单（推荐）
opencodenpm

# 或直接执行完整流程
opencodenpm full
```

---

### 🛠️ opencodenpm 命令参考

**opencodenpm** 是 OpenCode 中文汉化管理工具，提供一键更新、汉化、编译等功能。

#### 命令列表

| 命令 | 别名 | 说明 |
|------|------|------|
| `opencodenpm` | `ui` | 交互式菜单 |
| `opencodenpm update` | - | 更新 OpenCode 源码 |
| `opencodenpm apply` | - | 应用汉化配置 |
| `opencodenpm build` | - | 编译构建 OpenCode |
| `opencodenpm verify` | - | 验证汉化覆盖率 |
| `opencodenpm full` | - | 完整工作流（更新→汉化→编译） |
| `opencodenpm launch` | `start` | 启动已编译的 OpenCode |
| `opencodenpm package` | `pack` | 打包 Releases |
| `opencodenpm deploy` | - | 部署全局命令 |
| `opencodenpm helper` | - | 智谱助手 |
| `opencodenpm env` | - | 检查编译环境 |
| `opencodenpm config` | - | 显示当前配置 |

#### 命令详解

**更新源码**
```bash
opencodenpm update              # 更新到最新版本
opencodenpm update --force      # 强制重新克隆
```

**应用汉化**
```bash
opencodenpm apply               # 应用汉化配置
opencodenpm apply --silent      # 静默模式
```

**编译构建**
```bash
opencodenpm build               # 编译当前平台
opencodenpm build -p linux-x64  # 编译指定平台
opencodenpm build --no-deploy   # 不部署到 bin 目录
```

**验证汉化**
```bash
opencodenpm verify              # 验证汉化
opencodenpm verify -d           # 显示详细信息
```

**打包发布**
```bash
opencodenpm package -p windows-x64   # 打包指定平台
opencodenpm package -a               # 打包所有平台
```

---

### 📂 项目结构

```
OpenCodeChineseTranslation/
├── scripts/                 # 管理脚本目录
│   ├── commands/            # 命令模块
│   │   ├── update.js        # 更新源码
│   │   ├── apply.js         # 应用汉化
│   │   ├── build.js         # 编译构建
│   │   ├── verify.js        # 验证汉化
│   │   ├── full.js          # 完整工作流
│   │   ├── launch.js        # 启动程序
│   │   ├── helper.js        # 智谱助手
│   │   ├── package.js       # 打包发布
│   │   └── deploy.js        # 部署命令
│   ├── core/                # 核心模块
│   │   ├── cli.js           # CLI 入口
│   │   ├── menu.js          # 交互菜单
│   │   ├── utils.js         # 工具函数
│   │   ├── git.js           # Git 操作
│   │   ├── i18n.js          # 汉化应用
│   │   ├── build.js         # 编译逻辑
│   │   ├── env.js           # 环境检查
│   │   ├── colors.js        # 输出样式
│   │   └── version.js       # 版本检测
│   ├── bin/                 # CLI 入口
│   │   └── opencodenpm      # 命令行工具
│   └── package.json         # 依赖配置
├── opencode-i18n/           # 汉化配置目录
│   ├── config.json          # 主配置文件
│   ├── dialogs/             # 对话框汉化
│   ├── routes/              # 路由汉化
│   ├── components/          # 组件汉化
│   └── common/              # 通用汉化
├── opencode-zh-CN/          # OpenCode 源码（自动克隆）
├── bin/                     # 编译输出目录
├── releases/                # 打包发布目录
└── docs/                    # 项目文档
```

---

### 🔧 编译环境要求

| 工具 | 版本要求 | 说明 |
|------|----------|------|
| Node.js | >= 18.0.0 | JavaScript 运行时 |
| Bun | >= 1.3.0 | 快速 JavaScript 运行时 |
| Git | latest | 版本控制 |

**环境检查**：
```bash
opencodenpm env
```

---

### 📊 汉化范围

| 模块 | 覆盖内容 | 覆盖率 |
|------|----------|--------|
| 命令面板 | 会话管理、模型选择、智能体切换 | 100% |
| 对话框 | 智能体选择器、会话列表、消息处理 | 100% |
| 路由 | 各类页面路由文本 | 100% |
| 组件 | UI 组件文本 | 80% |
| 通用 | 通用提示信息 | 100% |

---

### 🔧 常见问题

| 问题 | 解决方法 |
|------|----------|
| 编译失败 | `opencodenpm env` 检查环境 |
| 汉化未生效 | `opencodenpm apply` 重新应用 |
| 源码目录为空 | `opencodenpm update` 克隆源码 |
| 跨平台打包 | 在对应平台上执行 build 命令 |

---

### 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

OpenCode 原项目采用 MIT 许可证，版权归 [Anomaly Company](https://anomaly.company/) 所有。

---

### 🔗 相关链接

| 链接 | 说明 |
|------|------|
| [Gitee 仓库](https://gitee.com/QtCodeCreators/OpenCodeChineseTranslation) | 国内镜像 |
| [GitHub 仓库](https://github.com/1186258278/OpenCodeChineseTranslation) | GitHub 主页 |
| [OpenCode 官方](https://github.com/anomalyco/opencode) | 原项目 |
| [问题反馈](https://github.com/1186258278/OpenCodeChineseTranslation/issues) | 提交 Issue |

---

## English Documentation

### Project Overview

> **OpenCode** is an **open-source AI coding agent** developed by [Anomaly Company](https://anomaly.company/), providing TUI, desktop app, and IDE extensions.

**OpenCode Chinese Translation** is a localized version with complete Chinese translation through modular configuration and automated scripts.

**Key Features:**
- 🤖 AI-assisted coding - Explain, add features, refactor
- 📋 Plan mode - Plan first, execute later
- ↩️ Undo/Redo - Easy rollback with `/undo` and `/redo`
- 🔗 Share conversations - Generate links for collaboration
- 🔌 Multi-model support - Compatible with various LLM providers

---

### Quick Start

#### Step 1: Install opencodenpm

```bash
# Global install
npm install -g opencodenpm

# Or install from local source
cd /path/to/OpenCodeChineseTranslation/scripts
npm install -g .
```

#### Step 2: Check Environment

```bash
opencodenpm env
```

#### Step 3: Run Full Workflow

```bash
# Interactive menu
opencodenpm

# Or direct execution
opencodenpm full
```

---

### Command Reference

| Command | Alias | Description |
|---------|-------|-------------|
| `opencodenpm` | - | Interactive menu |
| `opencodenpm update` | - | Update source code |
| `opencodenpm apply` | - | Apply translation |
| `opencodenpm build` | - | Build OpenCode |
| `opencodenpm verify` | - | Verify coverage |
| `opencodenpm full` | - | Full workflow |
| `opencodenpm launch` | `start` | Launch OpenCode |
| `opencodenpm package` | `pack` | Package releases |
| `opencodenpm deploy` | - | Deploy global command |
| `opencodenpm helper` | - | Coding helper |
| `opencodenpm env` | - | Check environment |
| `opencodenpm config` | - | Show config |

---

### License

This project is licensed under MIT. See [LICENSE](LICENSE) for details.

OpenCode original project is also MIT licensed, copyright by [Anomaly Company](https://anomaly.company/).

---

### Links

| Link | Description |
|------|-------------|
| [Gitee Repository](https://gitee.com/QtCodeCreators/OpenCodeChineseTranslation) | China mirror |
| [GitHub Repository](https://github.com/1186258278/OpenCodeChineseTranslation) | GitHub home |
| [OpenCode Official](https://github.com/anomalyco/opencode) | Original project |
| [Issue Tracker](https://github.com/1186258278/OpenCodeChineseTranslation/issues) | Report issues |