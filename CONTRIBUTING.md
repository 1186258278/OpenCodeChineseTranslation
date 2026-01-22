# 贡献指南 (Contributing Guide)

感谢你对 OpenCode 中文汉化项目的关注和贡献！为了保持项目代码质量和协作效率，请遵守以下规范。

## Git 提交规范 (Commit Convention)

我们遵循 [Angular Commit Message Guidelines](https://github.com/angular/angular/blob/master/CONTRIBUTING.md#commit) 规范。

每次提交信息 (Commit Message) 应该包含三个部分：`Header`, `Body` 和 `Footer`。

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

### 1. Header (必填)

Header 只有一行，包含三个字段：`type` (必填), `scope` (选填), `subject` (必填)。

#### Type (类型)

必须是以下之一：

*   **feat**: 新功能 (A new feature)
*   **fix**: 修补 Bug (A bug fix)
*   **docs**: 文档修改 (Documentation only changes)
*   **style**: 代码格式修改，不影响逻辑 (Changes that do not affect the meaning of the code)
*   **refactor**: 代码重构 (A code change that neither fixes a bug nor adds a feature)
*   **perf**: 性能优化 (A code change that improves performance)
*   **test**: 测试相关 (Adding missing tests or correcting existing tests)
*   **build**: 构建系统或外部依赖变更 (Changes that affect the build system or external dependencies)
*   **ci**: CI 配置文件或脚本修改 (Changes to our CI configuration files and scripts)
*   **chore**: 其他不修改 src 或 test 的变动 (Other changes that don't modify src or test files)
*   **revert**: 回滚提交 (Reverts a previous commit)

#### Scope (范围)

用于说明 commit 影响的范围，例如：
*   `i18n`: 汉化文件相关
*   `scripts`: 脚本工具相关
*   `ui`: 界面相关
*   `docs`: 文档相关

#### Subject (主题)

简短描述本次修改的内容。
*   以动词开头，使用第一人称现在时 (如 "add", "change")
*   首字母小写
*   结尾不加句号 (.)

### 示例

```
feat(i18n): add missing translations for search panel
fix(scripts): fix bun cache clean command error
docs: update contributing guide
chore: upgrade dependencies
```

---

## 开发流程

1.  **Fork** 本仓库
2.  创建一个新的分支 (`git checkout -b feat/my-feature`)
3.  进行修改并提交 (`git commit -m 'feat: add my feature'`)
4.  推送到你的分支 (`git push origin feat/my-feature`)
5.  提交 **Pull Request**

## 汉化指南

*   所有的汉化 JSON 文件位于 `opencode-i18n/` 目录下。
*   请确保 JSON 格式正确，不要包含注释。
*   修改后建议运行 `opencodenpm verify` 进行验证。

## 版本管理

如果你的提交涉及发布新版本，请修改 `scripts/core/version.js` 文件：

```javascript
const VERSION = '7.1.0';   // 修改为新版本号
const VERSION_SHORT = 'v7.1'; // 修改为短版本号
```

修改后，CI/CD 系统在检测到 `v*` 标签时，会自动使用此版本号进行打包发布。

再次感谢你的贡献！
