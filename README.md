# OpenCode 中文汉化项目

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-v7.0-green.svg)](scripts/package.json)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-blue.svg)](#)

[English Documentation](README_EN.md)

---

## 项目简介

**OpenCode 中文汉化版** 是针对开源 AI 编程代理工具 [OpenCode](https://github.com/anomalyco/opencode) 的本地化与增强发行版。本项目旨在降低国内开发者的使用门槛，提供完整的汉化支持、自动化构建流程以及针对国内网络环境的优化。

通过内置的 `opencodenpm` 管理工具，您可以轻松实现源码更新、汉化补丁应用、编译构建以及多平台发布。

### 核心特性

*   **完整汉化支持**：覆盖 TUI 界面、对话框、提示信息及核心交互流程。
*   **自动化工作流**：提供一键更新、汉化、验证、编译的全自动脚本。
*   **多平台兼容性**：完美支持 Windows、macOS 和 Linux 系统。
*   **增强插件集成**：内置 Oh-My-OpenCode 和 Antigravity 配置向导，解锁多智能体协作与本地模型支持。
*   **专业管理工具**：提供 TUI 交互式菜单，操作直观高效。

## 界面预览

<p align="center">
  <img src="docs/0-1.png" alt="OpenCode 汉化管理工具主界面" width="800">
</p>

<p align="center">
  <img src="docs/1-1.png" alt="MCP 服务器汉化" width="45%">
  <img src="docs/2-2.png" alt="状态对话框汉化" width="45%">
</p>

---

## 快速开始

### 1. 环境准备

在开始之前，请确保您的开发环境满足以下要求：

*   **Node.js**: >= 18.0.0
*   **Bun**: >= 1.3.0 (用于快速编译)
*   **Git**: 最新版本

### 2. 安装管理工具

推荐全局安装 `opencodenpm` 管理工具，以便在任意位置管理项目。

```bash
# 进入脚本目录
cd scripts

# 安装依赖并链接全局命令
npm install
npm link
```

### 3. 运行交互式菜单

安装完成后，在终端直接输入以下命令启动管理界面：

```bash
opencodenpm
```

您将看到一个网格化的交互菜单，支持使用方向键或数字键选择功能。

---

## 命令行参考

除了交互式菜单，`opencodenpm` 还支持丰富的命令行参数，方便集成到 CI/CD 或脚本中。

| 命令 | 参数 | 说明 |
|------|------|------|
| **full** | `-y, --auto` | 执行完整工作流（更新->汉化->编译），`--auto` 跳过确认 |
| **update** | `-f, --force` | 更新 OpenCode 源码，`--force` 强制重新克隆 |
| **apply** | `-b, --backup`<br>`-r, --report` | 应用汉化配置。`-b` 备份源码，`-r` 生成报告 |
| **build** | `-p <platform>` | 编译构建。平台可选 `windows-x64`, `linux-x64`, `darwin-arm64` |
| **verify** | `-d, --detailed` | 验证汉化覆盖率和配置完整性 |
| **deploy** | - | 将 `opencode` 和 `opencodenpm` 部署到系统 PATH |
| **rollback** | `-l, --list`<br>`-i <id>` | 回滚备份。`-l` 列出备份，`-i` 回滚到指定 ID |
| **package** | `-a, --all`<br>`-p <platform>` | 打包发布版 ZIP。`-a` 打包所有平台 |
| **launch** | `-b, --background` | 启动 OpenCode，`-b` 后台运行 |
| **antigravity** | - | 配置 Antigravity 本地 AI 网关 |
| **ohmyopencode** | - | 安装 Oh-My-OpenCode 增强插件 |
| **helper** | `-i, --install` | 安装/启动智谱编码助手 |
| **env** | - | 检查开发环境 |

**示例：**

```bash
# 强制更新源码并应用汉化
opencodenpm update --force
opencodenpm apply

# 为 Linux 平台编译
opencodenpm build -p linux-x64

# 部署全局命令
opencodenpm deploy
```

---

## 进阶文档

*   [📅 更新日志 (CHANGELOG)](CHANGELOG.md)
*   [🚀 Antigravity 集成指南](docs/ANTIGRAVITY_INTEGRATION.md)
*   [🛠️ AI 维护指南](docs/AI_MAINTENANCE.md)
*   [📦 Oh My OpenCode 指南](docs/OH_MY_OPENCODE_GUIDE.md)

---

## 常见问题

**Q: 编译失败，提示缺少 bun 命令？**
A: 本项目依赖 Bun 进行快速构建。请访问 [bun.sh](https://bun.sh) 安装，或使用 `npm install -g bun`。

**Q: 汉化后部分界面仍显示英文？**
A: OpenCode 更新较快，部分新功能可能尚未收录到汉化配置中。您可以提交 Issue 反馈缺失的翻译。

**Q: 如何使用自定义模型？**
A: 推荐使用 `opencodenpm antigravity` 命令一键配置，或手动修改 `~/.config/opencode/opencode.json` 文件中的 `provider` 配置。

---

## 许可证

本项目基于 [MIT License](LICENSE) 开源。
OpenCode 原项目版权归 [Anomaly Company](https://anomaly.company/) 所有。
