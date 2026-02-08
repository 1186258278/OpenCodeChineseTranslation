# 预编译版本发布说明

## 编译环境

本次预编译版本的编译环境如下：

| 项目 | 版本 |
|------|------|
| 构建工具 | Bun 1.3.8+ |
| Node.js | >= 18.0.0 |
| 汉化版本 | v6.2 |

## 支持的平台

预编译版本支持以下平台：

- **Windows**: x64
- **Linux**: x64
- **macOS**: arm64

## 快速开始

### 方式一：下载预编译版本（推荐）

1. 从 [Releases](https://github.com/1186258278/OpenCodeChineseTranslation/releases) 下载对应平台的压缩包
2. 解压到任意目录
3. 运行 `opencode` (Windows 为 `opencode.exe`)

### 方式二：使用 opencodenpm 编译

```bash
# 1. 安装 opencodenpm
npm install -g opencodenpm

# 2. 检查环境
opencodenpm env

# 3. 完整工作流（更新→汉化→编译）
opencodenpm full

# 4. 启动
opencodenpm launch
```

## opencodenpm 命令参考

| 命令 | 说明 |
|------|------|
| `opencodenpm` | 交互式菜单 |
| `opencodenpm update` | 更新 OpenCode 源码 |
| `opencodenpm apply` | 应用汉化配置 |
| `opencodenpm build` | 编译构建 OpenCode |
| `opencodenpm verify` | 验证汉化覆盖率 |
| `opencodenpm full` | 完整工作流 |
| `opencodenpm launch` | 启动已编译的 OpenCode |
| `opencodenpm package` | 打包 Releases |
| `opencodenpm deploy` | 部署全局命令 |
| `opencodenpm env` | 检查编译环境 |

## 打包发布

```bash
# 打包当前平台
opencodenpm package

# 打包指定平台
opencodenpm package -p windows-x64

# 打包所有平台
opencodenpm package --all
```

生成的文件位于 `releases/` 目录。

## 兼容性说明

- 预编译版本仅包含核心二进制文件
- 汉化资源已内置到编译产物中
- 预编译版本适用于快速体验，完整功能建议使用源码编译

## 相关链接

| 链接 | 说明 |
|------|------|
| [Gitee 仓库](https://gitee.com/QtCodeCreators/OpenCodeChineseTranslation) | 国内镜像 |
| [GitHub 仓库](https://github.com/1186258278/OpenCodeChineseTranslation) | GitHub 主页 |
| [OpenCode 官方](https://github.com/anomalyco/opencode) | 原项目 |
| [问题反馈](https://github.com/1186258278/OpenCodeChineseTranslation/issues) | 提交 Issue |
