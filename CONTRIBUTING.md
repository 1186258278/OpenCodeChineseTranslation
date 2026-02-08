# 贡献指南 (Contributing Guide)

感谢你对 OpenCode 中文汉化项目的关注和贡献！为了保持项目代码质量和协作效率，请遵守以下规范。

## 核心架构变更说明

从 v7.3 开始，本项目已全面迁移到 **Go 语言** 开发的 CLI 管理工具。旧的 Node.js/JavaScript 脚本 (`scripts/`) 已被标记为过时，并移入 `legacy/` 目录。

新的 CLI 源码位于 `cli-go/` 目录。

---

## 开发环境搭建

### 1. 基础要求
*   **Go**: v1.21+ (推荐 v1.25+)
*   **Git**: 用于版本控制
*   **Node.js 18+** / **Bun 1.3.8+** (可选): 仅当需要编译 OpenCode 源码时需要

### 2. 目录结构

CLI 统一使用 `~/.opencode-i18n/` 目录：

```
~/.opencode-i18n/
├── bin/              # CLI 工具和 OpenCode 可执行文件
├── opencode/         # OpenCode 源码
└── build/            # 编译输出
```

**本地开发时**，可通过环境变量覆盖：
```bash
export OPENCODE_SOURCE_DIR=/path/to/opencode   # 覆盖源码目录
export OPENCODE_BUILD_DIR=/path/to/bin         # 覆盖编译输出
```

汉化配置已内嵌到二进制文件中，无需外部文件。

### 3. 编译 CLI 工具

```bash
cd cli-go

# 编译当前平台版本
go build -o opencode-cli.exe .

# 运行测试
go test ./...
```

### 4. 交叉编译

我们提供了一键编译脚本：

```bash
# Windows
.\build.ps1

# macOS/Linux
./build.sh
```

---

## 汉化指南

从 v8.5+ 开始，汉化资源已内嵌到 CLI 工具中：

*   汉化 JSON 文件位于 `cli-go/internal/core/assets/opencode-i18n/` 目录下
*   修改后需要重新编译 CLI 工具才能生效
*   验证汉化配置：
    ```bash
    opencode-cli verify --detailed
    ```
*   JSON 文件格式要求：无注释，UTF-8 编码

---

## Git 提交规范 (Commit Convention)

我们遵循 [Angular Commit Message Guidelines](https://github.com/angular/angular/blob/master/CONTRIBUTING.md#commit) 规范。

```
<type>(<scope>): <subject>
```

### Type (类型)
*   **feat**: 新功能 (A new feature)
*   **fix**: 修补 Bug (A bug fix)
*   **docs**: 文档修改 (Documentation only changes)
*   **style**: 代码格式修改 (Changes that do not affect the meaning of the code)
*   **refactor**: 代码重构 (A code change that neither fixes a bug nor adds a feature)
*   **perf**: 性能优化 (A code change that improves performance)
*   **test**: 测试相关 (Adding missing tests or correcting existing tests)
*   **build**: 构建系统或外部依赖变更 (Changes that affect the build system or external dependencies)
*   **ci**: CI 配置文件或脚本修改 (Changes to our CI configuration files and scripts)
*   **chore**: 其他变动 (Other changes that don't modify src or test files)

### Scope (范围)
*   `cli`: Go CLI 工具相关
*   `i18n`: 汉化文件相关
*   `docs`: 文档相关
*   `ci`: GitHub Actions 相关

### 示例
```
feat(cli): add shortcut creation support for deploy command
fix(i18n): correct translation for search panel
docs: update installation guide for go cli
chore: cleanup legacy scripts
```

---

## 版本管理

版本号由 `cli-go/internal/core/version.go` 中的 `VERSION` 常量统一管理：

```go
const VERSION = "8.6.0"
```

发布新版本时：
1. 更新 `cli-go/internal/core/version.go` 中的 `VERSION` 常量
2. 更新 `CHANGELOG.md` 添加版本说明
3. 提交并打上对应的 git tag（如 `v8.2.0`）
4. GitHub Actions 会自动触发构建并发布 Release

---

## CI/CD 工作流

本项目使用 GitHub Actions 实现自动化构建，包含两个主要工作流：

### Release (正式发布)

*   **文件**: `.github/workflows/release.yml`
*   **触发条件**: 推送 `v*` 格式的 Tag 或手动触发
*   **产物**: 正式版 Release，包含三平台二进制文件

```bash
# 使用 release.ps1 脚本发布（推荐）
.\release.ps1 -Version 8.4.0 -Message "新功能说明"

# 或手动触发
gh workflow run release.yml -f tag_name=v8.4.0
```

### Nightly (自动跟进构建)

*   **文件**: `.github/workflows/nightly.yml`
*   **触发条件**: 每小时检测上游，累计 ≥5 个新 commit 时自动构建
*   **产物**: Nightly 预发布版本，自动跟进上游更新，包含官方更新日志

```bash
# 手动触发
gh workflow run nightly.yml

# 强制构建（跳过 commit 数量检测）
gh workflow run nightly.yml -f force_build=true

# 自定义阈值（例如累计 3 个 commit 就触发）
gh workflow run nightly.yml -f min_commits=3
```

**Nightly 构建逻辑：**

1. 每小时检查 `anomalyco/opencode` 的 `dev` 分支是否有新 commit
2. 与 `.nightly-state` 文件记录的上次构建 commit 对比
3. 计算新增 commit 数量，≥5 时触发构建
4. 构建完成后：
   - 生成包含上游更新日志的 Release Notes
   - 发布到固定 `nightly` tag（覆盖更新）
   - 更新 `.nightly-state` 文件

| 对比项 | Release | Nightly |
|--------|---------|---------|
| 版本号 | `v8.x.x` | `nightly` (固定) |
| 检测频率 | 手动 | 每小时 |
| 触发条件 | 推送 Tag | ≥5 个新 commit |
| 稳定性 | 经过测试 | 可能不稳定 |
| Tag | 永久保留 | 滚动覆盖 |
| 推荐用户 | 普通用户 | 开发者/测试者 |

---

再次感谢你的贡献！
