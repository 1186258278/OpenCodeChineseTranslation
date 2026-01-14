# 代码审计报告

## 审计概要

| 项目 | 内容 |
|------|------|
| **审计对象** | opencode-zh-CN（packages/opencode/src） |
| **审计时间** | 2026-01-14 14:20:54 |
| **审计范围** | C:\Data\PC\OpenCode\opencode-zh-CN |
| **代码行数** | 约 45034 行（packages/opencode/src） |
| **审计重点** | 翻译字段是否影响程序逻辑/标识符 |
| **发现问题** | **总计 2** (Critical: 0, High: 1, Medium: 1, Low: 0, Info: 0) |

---

## Critical 级别问题 🔴

> 共发现 0 个问题

---

## High 级别问题 🟠

> 共发现 1 个问题

### [H-001] 翻译导致关键参数名被替换成中文，触发运行时/编译错误 ✅ 已修复
- **位置**: `packages/opencode/src/cli/cmd/tui/ui/dialog-export-options.tsx:9`；`packages/opencode/src/cli/cmd/tui/ui/dialog-export-options.tsx:176`；`packages/opencode/src/cli/cmd/tui/ui/dialog-export-options.tsx:101`
- **类型**: 代码缺陷 - 标识符被翻译
- **代码**:
  ```tsx
  // 修复前（错误）:
  export type DialogExportOptionsProps = {
    default文件名: string
  }
  // 修复后（正确）:
  export type DialogExportOptionsProps = {
    defaultFilename: string
  }
  ```
- **问题描述**: `default文件名` 被作为参数/类型字段名写入代码，但实际使用仍是 `defaultFilename`。这会导致 TS 类型不匹配，并在运行时引用未定义变量（`defaultFilename`）。
- **影响**: 导出对话框逻辑无法正常执行，可能直接抛错或阻塞功能。
- **修复状态**: ✅ 已修复 (2026-01-14)
  - `defaultFilename` 标识符已恢复为正确的英文字段名
  - 类型定义、函数参数、调用处保持一致
  - i18n 配置中未发现此错误规则，可能是手动汉化时引入

---

## Medium 级别问题 🟡

> 共发现 1 个问题

### [M-001] 属性名被翻译成中文导致逻辑失效 ✅ 已修复
- **位置**: `packages/opencode/src/cli/cmd/tui/component/dialog-agent.tsx:15`
- **类型**: 逻辑错误 - 字段名被翻译
- **代码**:
  ```tsx
  // 修复前（错误）:
  description: item.原生 ? "原生" : item.description,
  // 修复后（正确）:
  description: item.native ? "原生" : item.description,
  ```
- **问题描述**: `item.原生` 是中文属性名，极可能不是实际数据结构字段（原字段应为 `native`/`builtin` 等）。该条件永远为 `false`，导致"原生"标识失效。
- **影响**: 智能体列表的"原生"标识无法正确显示，信息误导用户。
- **修复状态**: ✅ 已修复 (2026-01-14)
  - `item.native` 属性名已恢复为正确的英文字段名
  - 显示文本"原生"保持中文翻译
  - i18n 配置中未发现此错误规则，可能是手动汉化时引入

---

## Low 级别问题 🟢

> 共发现 0 个问题

---

## Info 级别建议 🔵

> 共发现 0 个建议

---

## 统计汇总

| 严重程度 | 发现数 | 已修复 | 占比 | 优先级 |
|----------|------|------|------|--------|
| Critical 🔴 | 0 | 0 | 0% | P0 - 立即修复 |
| High 🟠 | 1 | 1 | 50% | P1 - 尽快修复 |
| Medium 🟡 | 1 | 1 | 50% | P2 - 建议修复 |
| Low 🟢 | 0 | 0 | 0% | P3 - 逐步优化 |
| Info 🔵 | 0 | 0 | 0% | P4 - 参考优化 |
| **合计** | **2** | **2** | **100%** | - |

---

## 总体风险评级

根据发现的问题数量和严重程度，本次审计的总体风险等级为：

### **无风险** ✅ 所有问题已修复

**原风险分数**: 0 × 10 + 1 × 5 + 1 × 2 + 0 × 1 = 7 (中风险)
**当前风险分数**: 0 (无风险)

---

*报告生成时间: 2026-01-14 14:20:54*
*报告版本: v1.1*
*最后更新: 2026-01-14*
