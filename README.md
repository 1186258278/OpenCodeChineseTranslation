# OpenCode 中文汉化版

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://microsoft.com/PowerShell)
[![OpenCode](https://img.shields.io/badge/OpenCode-dev-green.svg)](https://github.com/anomalyco/opencode)

[中文](#中文文档) | [English](README_EN.md)

---

## 中文文档

### 项目简介

> **OpenCode** 是由 [Anomaly Company](https://anomaly.company/) 开发的**开源 AI 编程代理**，提供终端界面 (TUI)、桌面应用和 IDE 扩展等多种使用方式。

**OpenCode 中文汉化版**是对 OpenCode 项目的本地化改造，通过模块化汉化配置和自动化脚本实现完整中文化，降低国内用户使用门槛。

**核心功能：**
- 🤖 AI 辅助编程 - 解释代码、添加功能、重构修改
- 📋 Plan 模式 - 先规划后实施，支持图片参考和迭代讨论
- ↩️ 撤销/重做 - `/undo` 和 `/redo` 命令轻松回退
- 🔗 对话分享 - 生成链接与团队协作
- 🔌 多模型支持 - 兼容各类 LLM 提供商

**本项目解决的问题：**

| 问题 | 解决方案 |
|------|----------|
| 全英文界面降低使用效率 | 完整汉化所有用户可见文本 |
| 每次更新需重新手动修改 | 自动化脚本支持一键更新和汉化 |
| 不熟悉命令行操作 | 提供交互式菜单，简化操作流程 |
| 担心修改破坏原功能 | 保留源码结构，仅替换显示文本 |

---

### 系统要求

| 组件 | 最低版本 | 推荐版本 | 说明 |
|------|----------|----------|------|
| 操作系统 | Windows 10 1809+ | Windows 11 22H2+ | 需要 PowerShell 5.1+ |
| PowerShell | 5.1 | 7.2+ | Windows 10 自带 5.1 |
| Git | 2.25+ | 2.40+ | 用于代码管理和子模块操作 |
| Bun | 1.3+ | 最新版 | OpenCode 编译依赖 |

**支持的系统版本：**
- Windows 10 版本 1809（2018年10月更新）及更高版本
- Windows 11 所有版本
- Windows Server 2019 及更高版本

---

### 🛠️ 开发环境初始化（新服务器必用）

> **适用于**：新服务器、全新开发环境、一键安装所有依赖

#### 一键安装 Codes 管理工具（推荐）

安装后自动获得 `codes` 全局命令，用于管理开发环境：

```powershell
# Windows PowerShell
irm https://raw.githubusercontent.com/1186258278/OpenCodeChineseTranslation/main/scripts/install.sh | iex
```

```bash
# Linux/macOS (GitHub)
curl -fsSL https://raw.githubusercontent.com/1186258278/OpenCodeChineseTranslation/main/scripts/install.sh | bash
```

> **国内用户**：脚本会自动尝试 GitHub，失败时切换到 Gitee 镜像。也可以直接使用 Gitee 链接：
> ```bash
> curl -fsSL https://gitee.com/QtCodeCreators/OpenCodeChineseTranslation/raw/main/scripts/install.sh | bash
> ```

安装完成后重启终端，即可使用 `codes` 命令：

```bash
# 环境诊断 - 检查所有工具状态
codes doctor

# 安装缺失的组件
codes install

# 切换 Node.js 版本
codes node lts     # 切换到 LTS
codes node 22      # 切换到 v22

# 查看帮助
codes --help
```

#### 支持的组件

| 基础工具 | AI 工具 |
|----------|---------|
| Node.js + npm | @z_ai/coding-helper (智谱助手) |
| Bun | OpenCode 中文汉化版 |
| Git | Claude Code |
| Python | |
| Docker | |

#### Codes 命令参考

| 命令 | 说明 |
|------|------|
| `codes doctor` | 环境诊断 - 检查所有工具状态 |
| `codes install` | 安装组件 - 安装缺失的工具 |
| `codes upgrade` | 升级组件 - 升级已安装的工具 |
| `codes node lts` | Node 管理 - 切换到 LTS 版本 |
| `codes node 22` | Node 管理 - 切换到 v22 |
| `codes helper` | 启动 coding-helper |
| `codes env` | 显示环境变量 |

> 详细文档请查看 [scripts/README.md](scripts/README.md)

---

### 安装部署

> **重要**：本项目使用**相对路径**设计，可放置在任意目录运行。首次运行会自动初始化上游源码。

#### 方式一：一键安装（推荐）

```powershell
# 1. 克隆本仓库
git clone https://github.com/1186258278/OpenCodeChineseTranslation.git
cd OpenCodeChineseTranslation

# 2. 首次运行会自动初始化（克隆上游源码）
.\scripts\opencode.ps1
```

**首次运行自动执行：**
- 检查 Git 和 Bun 环境
- 自动克隆上游 OpenCode 源码到 `opencode-zh-CN/`
- 如果 Git 克隆失败，提供备用下载方案

#### 方式二：手动初始化

```powershell
# 1. 克隆本仓库（不含源码）
git clone https://github.com/1186258278/OpenCodeChineseTranslation.git
cd OpenCodeChineseTranslation

# 2. 手动初始化上游源码
.\scripts\init.ps1
# 或使用 -Force 强制重新初始化
.\scripts\init.ps1 -Force
```

**手动安装适用场景：**
- Git 克隆失败，使用备用下载方式
- 需要指定特定分支或版本的源码
- 网络环境需要特殊配置

#### 方式三：从 GitHub Releases 部署

1. 访问 [Releases 页面](https://github.com/1186258278/OpenCodeChineseTranslation/releases)
2. 下载最新版本的预编译包
3. 解压到任意目录
4. 运行 `.\scripts\opencode.ps1`

---

### 使用方法

#### 一键汉化+部署

首次使用推荐选择此选项，自动完成以下流程：

```
拉取最新代码 → 应用汉化补丁 → 编译程序 → 部署到本地
```

```powershell
.\scripts\opencode.ps1
# 选择 [1] 一键汉化+部署
```

#### 分步操作

适用于了解流程或需要自定义的用户：

| 步骤 | 菜单选项 | 说明 |
|------|----------|------|
| 拉取代码 | 高级菜单 → [1] | 从官方仓库获取最新源码 |
| 应用汉化 | 高级菜单 → [2] | 应用中文翻译到源码 |
| 编译程序 | 高级菜单 → [3] | 使用 Bun 编译项目 |
| 部署 | 高级菜单 → [9] | 替换全局 OpenCode 版本 |

#### 版本更新

```powershell
.\scripts\opencode.ps1
# 选择 [5] 版本检测
# 如有新版本，按提示输入 y 确认更新
```

---

### 菜单说明

#### 主菜单

| 选项 | 功能 | 适用场景 |
|------|------|----------|
| [1] | 一键汉化+部署 | 首次使用或需要完整更新 |
| [2] | 应用汉化 | 仅应用翻译，不编译 |
| [3] | 验证汉化 | 检查翻译覆盖率 |
| [4] | 调试工具 | 排查汉化问题 |
| [5] | 版本检测 | 检查并更新官方版本 |
| [6] | 备份版本 | 备份当前汉化版本 |
| [7] | 高级菜单 | 更多高级选项 |
| [R] | 恢复纯净 | 撤销汉化，恢复到出厂状态 |

#### 高级菜单

| 选项 | 功能 |
|------|------|
| [1] | 拉取最新代码（支持自动检测代理） |
| [2] | 应用汉化补丁 |
| [3] | 编译程序 |
| [4] | 版本检测 |
| [5] | 备份源码和编译产物 |
| [6] | 从备份恢复 |
| [7] | 恢复原始文件 |
| [8] | 打开输出目录 |
| [9] | 替换全局版本 |
| [C] | 清理工具（缓存、临时文件） |
| [L] | 启动 OpenCode |
| [R] | 源码恢复（强制重置） |
| [S] | 恢复脚本 |

---

### 汉化范围

| 模块 | 覆盖内容 |
|------|----------|
| 命令面板 | 会话管理、模型选择、智能体切换 |
| 对话框 | 智能体选择器、会话列表、消息处理 |
| 侧边栏 | 上下文管理、MCP 状态显示 |
| 顶部栏 | 子智能体导航 |
| 权限系统 | 文件操作权限请求 |
| 通知提示 | 70+ 条操作提示信息 |

---

### 项目结构

```
OpenCodeChineseTranslation/
├── scripts/                 # 管理脚本目录
│   ├── opencode.ps1         # 主脚本（4700+ 行）
│   └── init.ps1             # 自动初始化脚本
├── opencode-i18n/           # 汉化配置目录
│   ├── config.json          # 主配置文件（版本控制）
│   ├── dialogs/             # 对话框汉化（21+ 个模块）
│   ├── routes/              # 路由汉化（3+ 个模块）
│   ├── components/          # 组件汉化（6+ 个模块）
│   └── common/              # 通用汉化（6+ 个模块）
├── opencode-zh-CN/          # OpenCode 源码（自动克隆，Git 忽略）
├── dist/                    # 编译输出（Git 忽略）
└── docs/                    # 项目文档
```

**目录说明：**
- `scripts/` - PowerShell 管理脚本，支持相对路径运行
- `opencode-i18n/` - 模块化汉化配置，JSON 格式
- `opencode-zh-CN/` - 上游源码（首次运行自动克隆，.gitignore 忽略）

---

### 常见问题

| 问题 | 原因 | 解决方法 |
|------|------|----------|
| 执行策略错误 | PowerShell 默认禁止运行脚本 | `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` |
| 编译失败 | Bun 未安装或版本过低 | 运行 `bun upgrade` 或重新安装 Bun |
| 汉化未生效 | 源码被 Git 更新覆盖 | 运行 `[2] 应用汉化` 重新应用 |
| 网络超时 | 访问 GitHub 速度慢 | 脚本会自动检测并使用本地代理 |
| 源码目录为空 | 首次运行未初始化 | 运行 `.\scripts\init.ps1` 自动克隆 |
| 全局命令冲突 | 已安装官方 opencode | 脚本会自动检测并提供选项 |
| 需要恢复纯净 | 汉化出现问题或想重置 | 运行 `[R] 恢复纯净` 一键重置 |

---

### 代理配置

脚本支持自动检测常见代理端口，无需手动配置：

| 代理软件 | 默认端口 | 检测状态 |
|----------|----------|----------|
| Clash | 7890, 7891 | 自动 |
| V2RayN | 10809, 10808 | 自动 |
| Surge | 1087, 1080 | 自动 |
| 其他 | 8080 | 自动 |

如需手动指定代理，运行以下命令：

```powershell
git config --global http.proxy http://127.0.0.1:端口
git config --global https.proxy http://127.0.0.1:端口
```

---

### 版本适配

语言包通过 Git Commit 确保与 OpenCode 源码版本匹配。

**版本检测机制：**

| 检测项 | 说明 |
|--------|------|
| 支持版本 | 语言包配置中记录测试通过的 Commit Hash |
| 当前版本 | 运行时检测 OpenCode 子模块的实际 Commit |
| 不匹配处理 | 显示警告并提示联系维护者更新 |

**版本不匹配时可能出现的问题：**
- 部分新增文本无法汉化
- 已修改的文本汉化显示错误
- 界面元素显示异常

**如何更新语言包：**

如果遇到版本不匹配警告，请通过以下方式联系维护者：

| 联系方式 | 说明 |
|----------|------|
| 微信 | CodeCreator |
| GitHub | [提交 Issue](https://github.com/1186258278/OpenCodeChineseTranslation/issues) |

**维护者信息：**

```json
{
  "name": "CodeCreator",
  "wechat": "CodeCreator",
  "github": "https://github.com/1186258278/OpenCodeChineseTranslation"
}
```

---

### 贡献指南

欢迎贡献代码和翻译！

1. **修复翻译错误**：提交 PR 修改 `opencode-i18n/` 下的 JSON 文件
2. **新增汉化模块**：在对应目录添加新的 JSON 文件并更新 `config.json`
3. **脚本优化**：提交 PR 修改 `scripts/opencode.ps1`
4. **报告问题**：提交 Issue 并附上错误日志

详细指南请参考 [CONTRIBUTING.md](CONTRIBUTING.md)

---

### 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

OpenCode 原项目采用 MIT 许可证，版权归 [Anomaly Company](https://anomaly.company/) 所有。

---

### 相关链接

- [OpenCode 官方仓库](https://github.com/anomalyco/opencode)
- [OpenCode 官方文档](https://opencode.ai/docs)
- [Anomaly Company](https://anomaly.company/)
- [问题反馈](https://github.com/1186258278/OpenCodeChineseTranslation/issues)
- [更新日志](CHANGELOG.md)

---

### 版本历史

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| 5.4 | 2026-01-10 | 新用户友好：自动初始化、备用下载、一键恢复纯净模式 |
| 5.3 | 2026-01-10 | 改进版本检测与自动更新，修复汉化污染问题 |
| 5.2 | 2026-01-09 | 修复汉化配置破坏代码的问题 |
| 5.1 | 2026-01-09 | 添加语言包版本适配检测 |
| 5.0 | 2026-01-08 | 优化文件标记速度和进度提示 |
| 4.5 | 2026-01-09 | 新增错误消息翻译，修复验证脚本 |
| 4.3 | 2026-01-08 | 完善菜单结构，添加自动代理检测 |
| 4.0 | 2026-01-07 | 模块化重构，支持独立模块管理 |
| 3.1 | 2026-01-06 | 菜单优化，修复版本检测 |
| 3.0 | 2026-01-05 | 添加一键汉化功能 |
| 1.0 | 2025-12-01 | 初始版本 |
