# OpenCode 中文汉化发行版

[![Release](https://img.shields.io/github/v/release/1186258278/OpenCodeChineseTranslation?label=最新汉化版&style=flat-square&color=blue)](https://github.com/1186258278/OpenCodeChineseTranslation/releases/latest)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg?style=flat-square)](#)
[![Build Status](https://img.shields.io/github/actions/workflow/status/1186258278/OpenCodeChineseTranslation/release.yml?label=每日构建&style=flat-square)](https://github.com/1186258278/OpenCodeChineseTranslation/actions)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)
[![Downloads](https://img.shields.io/github/downloads/1186258278/OpenCodeChineseTranslation/total?style=flat-square&color=orange)](https://github.com/1186258278/OpenCodeChineseTranslation/releases)

> 🚀 **OpenCode 汉化发行版 | ⚡️ 每日自动同步官方最新版 | 全自动构建三端安装包 (Win/Mac/Linux)**
> 
> 🎉 **访问官方网站**：[https://1186258278.github.io/OpenCodeChineseTranslation/](https://1186258278.github.io/OpenCodeChineseTranslation/)

[English Documentation](README_EN.md)

---

## 项目简介

**OpenCode 汉化发行版** 是一个全自动化的 OpenCode 本地化项目。我们基于 GitHub Actions 构建了一套完整的自动化流水线，**每日定时**从官方仓库拉取最新源码，自动应用汉化补丁，并构建适用于 Windows、macOS 和 Linux 的中文安装包。

**主要特性：**
*   ⚡️ **每日自动更新**：紧跟官方节奏，第一时间体验新特性。
*   📦 **全平台支持**：提供 Windows、macOS (Apple Silicon)、Linux 二进制包。
*   🚀 **一键安装**：提供 CDN 加速的安装脚本，解决国内网络问题。
*   🔧 **完整汉化**：覆盖 TUI、对话框及核心交互流程。

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

本发行版开箱即用，只需确保系统中安装了基础运行环境（如需使用源码管理工具）：
*   **Node.js**: >= 18.0.0 (可选)
*   **Git**: 最新版本 (可选)

### 2. 一键安装 (推荐)

使用我们提供的 CDN 加速脚本，自动检测系统环境并安装最新汉化版。

**Linux / macOS**
```bash
curl -fsSL https://cdn.jsdelivr.net/gh/1186258278/OpenCodeChineseTranslation@main/install.sh | bash
```

**Windows (PowerShell)**
```powershell
irm https://cdn.jsdelivr.net/gh/1186258278/OpenCodeChineseTranslation@main/install.ps1 | iex
```

> 💡 **提示**: 以上命令使用了 jsDelivr CDN 加速，解决了 GitHub `raw.githubusercontent.com` 在国内访问不稳定的问题。

### 3. 手动下载

您也可以直接访问 [Releases 页面](https://github.com/1186258278/OpenCodeChineseTranslation/releases/latest) 下载对应平台的压缩包，解压后即可直接运行。

---

## 开发者指南

如果您希望参与汉化贡献或自己构建版本，可以使用内置的 `opencodenpm` 管理工具。

### 安装管理工具
```bash
cd scripts
npm install
npm link
```

### 常用命令
| 命令 | 说明 |
|------|------|
| `opencodenpm` | 启动交互式管理菜单 |
| `opencodenpm update` | 更新官方源码 |
| `opencodenpm apply` | 应用汉化补丁 |
| `opencodenpm build -p <platform>` | 编译指定平台版本 |

---

## 进阶文档

*   [📅 更新日志 (CHANGELOG)](CHANGELOG.md)
*   [🚀 Antigravity 集成指南](docs/ANTIGRAVITY_INTEGRATION.md)
*   [🛠️ AI 维护指南](docs/AI_MAINTENANCE.md)
*   [📦 Oh My OpenCode 指南](docs/OH_MY_OPENCODE_GUIDE.md)

---

## 常见问题

**Q: 汉化后部分界面仍显示英文？**
A: OpenCode 更新较快，部分新功能可能尚未收录到汉化配置中。您可以提交 Issue 反馈缺失的翻译。

**Q: 如何使用自定义模型？**
A: 推荐使用 `opencodenpm antigravity` 命令一键配置，或手动修改 `~/.config/opencode/opencode.json` 文件中的 `provider` 配置。

---

## 许可证

本项目基于 [MIT License](LICENSE) 开源。
OpenCode 原项目版权归 [Anomaly Company](https://anomaly.company/) 所有。
