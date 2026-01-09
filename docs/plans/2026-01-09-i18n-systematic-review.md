# OpenCode 中文汉化系统性复查计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**目标:** 系统性复查并补全 OpenCode TUI 界面所有英文字符串的中文翻译

**架构:** 逐模块检查 TUI 源码，识别未翻译的 UI 字符串，创建或更新对应的 i18n JSON 配置文件

**技术栈:**
- 源码路径: `opencode-zh-CN/packages/opencode/src/cli/cmd/tui/`
- 配置路径: `opencode-i18n/`
- 配置格式: JSON (replacements 键值对)

---

## 发现的遗漏翻译清单

### 优先级 1 - 用户可见界面字符串

| 文件 | 行号 | 英文原文 | 建议翻译 |
|------|------|----------|----------|
| `dialog-provider.tsx` | 117 | "Copied to clipboard" | "已复制到剪贴板" |
| `dialog-provider.tsx` | 148 | "Waiting for authorization..." | "等待授权..." |
| `dialog-provider.tsx` | 192 | "Invalid code" | "授权码无效" |
| `dialog-provider.tsx` | 221 | "...to get a key" | "...获取密钥" |
| `session/index.tsx` | 942 | "Are you sure you want to restore the reverted messages?" | "确定要恢复已撤销的消息吗？" |
| `session/index.tsx` | 1661 | "Fetching from the web..." | "正在从网络获取..." |
| `prompt/index.tsx` | 54 | "Fix a TODO in the codebase" | "修复代码中的 TODO" |
| `prompt/index.tsx` | 54 | "What is the tech stack of this project?" | "这个项目的技术栈是什么？" |
| `prompt/index.tsx` | 54 | "Fix broken tests" | "修复失败的测试" |
| `prompt/index.tsx` | 420 | "Stash pop" | "弹出存储" |
| `prompt/index.tsx` | 436 | "Stash list" | "存储列表" |
| `local.tsx` | 206 | "Connect a provider" | "连接提供商" |
| `app.tsx` | 460 | "Exit the app" | "退出应用" |

---

## 任务分解

### Task 1: 补全 dialog-provider.tsx 汉化

**文件:**
- 修改: `opencode-i18n/dialogs/dialog-provider.json`

**步骤 1: 检查现有配置**

```bash
cat opencode-i18n/dialogs/dialog-provider.json
```

**步骤 2: 添加遗漏的翻译**

编辑 `opencode-i18n/dialogs/dialog-provider.json`:
```json
{
  "file": "src/cli/cmd/tui/component/dialog-provider.tsx",
  "description": "提供商连接对话框",
  "replacements": {
    "Copied to clipboard": "已复制到剪贴板",
    "Waiting for authorization...": "等待授权...",
    "Invalid code": "授权码无效",
    "to get a key": "获取密钥"
  }
}
```

**步骤 3: 提交**

```bash
git add opencode-i18n/dialogs/dialog-provider.json
git commit -m "feat(i18n): 补全 dialog-provider 汉化"
```

---

### Task 2: 补全 session/index.tsx 汉化

**文件:**
- 修改: `opencode-i18n/routes/route-session.json`

**步骤 1: 检查现有配置**

```bash
cat opencode-i18n/routes/route-session.json
```

**步骤 2: 添加遗漏的翻译**

编辑 `opencode-i18n/routes/route-session.json`:
```json
{
  "file": "src/cli/cmd/tui/routes/session/index.tsx",
  "description": "会话页面主组件",
  "replacements": {
    "Are you sure you want to restore the reverted messages?": "确定要恢复已撤销的消息吗？",
    "Fetching from the web...": "正在从网络获取..."
  }
}
```

**步骤 3: 提交**

```bash
git add opencode-i18n/routes/route-session.json
git commit -m "feat(i18n): 补全 session 页面汉化"
```

---

### Task 3: 创建 component-prompt.json

**文件:**
- 创建: `opencode-i18n/components/component-prompt.json`

**步骤 1: 创建新配置文件**

编辑 `opencode-i18n/components/component-prompt.json`:
```json
{
  "file": "src/cli/cmd/tui/component/prompt/index.tsx",
  "description": "提示输入组件",
  "replacements": {
    "Fix a TODO in the codebase": "修复代码中的 TODO",
    "What is the tech stack of this project?": "这个项目的技术栈是什么？",
    "Fix broken tests": "修复失败的测试",
    "Stash pop": "弹出存储",
    "Stash list": "存储列表"
  }
}
```

**步骤 2: 更新 config.json**

编辑 `opencode-i18n/config.json`，在 components 数组中添加:
```json
"components/component-prompt.json"
```

**步骤 3: 提交**

```bash
git add opencode-i18n/components/component-prompt.json opencode-i18n/config.json
git commit -m "feat(i18n): 新增 component-prompt 汉化模块"
```

---

### Task 4: 补全 local.tsx 上下文汉化

**文件:**
- 创建: `opencode-i18n/contexts/context-local.json`

**步骤 1: 创建新配置文件**

编辑 `opencode-i18n/contexts/context-local.json`:
```json
{
  "file": "src/cli/cmd/tui/context/local.tsx",
  "description": "本地上下文",
  "replacements": {
    "Connect a provider": "连接提供商"
  }
}
```

**步骤 2: 更新 config.json 添加 contexts 分类**

编辑 `opencode-i18n/config.json`，添加 contexts 数组:
```json
"contexts": [
  "contexts/context-local.json"
]
```

**步骤 3: 提交**

```bash
git add opencode-i18n/contexts/context-local.json opencode-i18n/config.json
git commit -m "feat(i18n): 新增 context-local 汉化模块"
```

---

### Task 5: 补全 app.tsx 汉化

**文件:**
- 创建: `opencode-i18n/app.json`

**步骤 1: 创建新配置文件**

编辑 `opencode-i18n/app.json`:
```json
{
  "file": "src/cli/cmd/tui/app.tsx",
  "description": "应用主入口",
  "replacements": {
    "Exit the app": "退出应用"
  }
}
```

**步骤 2: 更新 config.json 添加根级模块**

编辑 `opencode-i18n/config.json`，添加根级数组:
```json
"root": [
  "app.json"
]
```

**步骤 3: 提交**

```bash
git add opencode-i18n/app.json opencode-i18n/config.json
git commit -m "feat(i18n): 新增 app 主入口汉化"
```

---

### Task 6: 系统性扫描验证

**步骤 1: 扫描所有可能遗漏的英文标题**

```bash
cd opencode-zh-CN/packages/opencode/src/cli/cmd/tui
grep -r 'title="' --include="*.tsx" | grep -E '"[A-Z][a-z]+ [a-z]+' | grep -v "title=\""
```

**步骤 2: 扫描所有可能遗漏的描述文本**

```bash
cd opencode-zh-CN/packages/opencode/src/cli/cmd/tui
grep -r 'description:' --include="*.tsx" | grep -E '"[A-Z]' | head -20
```

**步骤 3: 扫描 toast 消息**

```bash
cd opencode-zh-CN/packages/opencode/src/cli/cmd/tui
grep -r 'message:' --include="*.tsx" | grep -E '"[A-Z][a-z]+ [a-z]+'
```

**步骤 4: 确认无遗漏后更新版本号**

编辑 `opencode-i18n/config.json`:
```json
{
  "version": "4.3",
  "description": "OpenCode 中文汉化配置文件（模块化结构）",
  "lastUpdate": "2026-01-09",
  ...
}
```

---

### Task 7: 最终验证

**步骤 1: 运行汉化脚本测试**

```bash
cd /c/DATA/PC/OpenCode
pwsh -File scripts/apply-i18n.ps1
```

**步骤 2: 检查是否有语法错误**

```bash
cd opencode-zh-CN/packages/opencode
bun run build 2>&1 | head -50
```

**步骤 3: 提交最终版本**

```bash
git add opencode-i18n/config.json
git commit -m "chore(i18n): 版本升级至 4.3，完成系统性复查"
git push origin main
```

---

## 验收标准

1. ✅ 所有 TUI 对话框标题已汉化
2. ✅ 所有按钮文本已汉化
3. ✅ 所有提示/帮助信息已汉化
4. ✅ 所有状态消息已汉化
5. ✅ 构建无错误

---

## 执行选项

**计划已保存到 `docs/plans/2026-01-09-i18n-systematic-review.md`。两种执行方式：**

**1. 子代理驱动（当前会话）** - 我逐个任务派遣子代理，任务间审查，快速迭代

**2. 独立会话执行** - 在新工作树中打开新会话，批量执行与检查点

**选择哪种方式？**
