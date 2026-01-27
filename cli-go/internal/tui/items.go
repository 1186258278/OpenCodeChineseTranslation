package tui

// MenuItem 菜单项
type MenuItem struct {
	Key   string // 快捷键显示，如 [*]
	Name  string // 显示名称
	Value string // 操作标识
	Desc  string // 详细描述
}

// Tutorial 教程标签页
type Tutorial struct {
	Title   string
	Content []string
}

// 主菜单项目 (24个功能)
var MainMenuItems = []MenuItem{
	{Key: "[*]", Name: "一键全流程", Value: "full", Desc: "一键全流程：清理 + 更新 + 汉化 + 验证 + 编译 + 部署。推荐首次使用。"},
	{Key: "[D]", Name: "下载预编译版", Value: "download", Desc: "从 GitHub Releases 下载预编译的汉化版，无需 Bun/Node.js 环境。"},
	{Key: "[E]", Name: "安装编译环境", Value: "env-install", Desc: "一键安装编译所需环境 (Git/Node.js/Bun/npm)，支持 Windows/macOS/Linux。"},
	{Key: "[>]", Name: "更新源码", Value: "update", Desc: "从 GitHub 获取最新 OpenCode 源码。如遇冲突可选择强制覆盖。"},
	{Key: "[~]", Name: "恢复源码", Value: "restore", Desc: "使用 Git 清除所有本地修改，恢复到纯净状态。用于解决汉化冲突或重置。"},
	{Key: "[W]", Name: "应用汉化", Value: "apply", Desc: "将 opencode-i18n 中的汉化配置注入到源码中。包含变量保护机制。"},
	{Key: "[V]", Name: "验证汉化", Value: "verify", Desc: "检查汉化配置格式、变量完整性以及翻译覆盖率。推荐在编译前运行。"},
	{Key: "[#]", Name: "编译构建", Value: "build", Desc: "使用 Bun 编译生成 OpenCode 可执行文件。自动处理多平台构建。"},
	{Key: "[^]", Name: "部署命令", Value: "deploy", Desc: "将 opencode-cli 和 opencode (如果已编译) 部署到系统 PATH。"},
	{Key: "[=]", Name: "打包六端", Value: "package-all", Desc: "为 Win/Mac/Linux (x64/arm64) 打包发布版 ZIP 文件，生成 Release Notes。"},
	{Key: "[P]", Name: "启动OpenCode", Value: "launch", Desc: "直接启动当前已编译好的 OpenCode 程序。支持后台运行模式。"},
	{Key: "[A]", Name: "Antigravity", Value: "antigravity", Desc: "配置 Antigravity 本地 AI 代理服务 (Claude/GPT/Gemini)，用于智能体功能。"},
	{Key: "[O]", Name: "Oh-My-OC", Value: "ohmyopencode", Desc: "安装 Oh-My-OpenCode 插件，启用智能体、Git 增强、LSP 等高级功能。"},
	{Key: "[@]", Name: "智谱助手", Value: "helper", Desc: "安装智谱编码助手 (@z_ai/coding-helper)，统一管理 Claude Code 等 CLI 工具。"},
	{Key: "[G]", Name: "GitHub仓库", Value: "github", Desc: "在浏览器中打开项目仓库 (GitHub/Gitee)，查看源码或提交 Issue。"},
	{Key: "[?]", Name: "检查环境", Value: "env", Desc: "检查 Node.js, Bun, Git 等开发环境是否满足编译要求。"},
	{Key: "[F]", Name: "诊断修复", Value: "diagnose", Desc: "自动检测版本冲突、环境问题并一键修复。遇到问题先试这个！"},
	{Key: "[B]", Name: "校准 Bun", Value: "fix-bun", Desc: "强制将 Bun 版本校准为项目推荐版本 (v1.3.5)，解决兼容性问题。"},
	{Key: "[C]", Name: "清理缓存", Value: "clean-cache", Desc: "执行 bun pm cache rm 清理全局缓存，解决安装依赖报错问题。"},
	{Key: "[U]", Name: "更新脚本", Value: "update-script", Desc: "从 Git 更新本汉化管理脚本到最新版本。不影响 OpenCode 源码。"},
	{Key: "[L]", Name: "更新日志", Value: "changelog", Desc: "查看 OpenCode 官方仓库的最近更新日志 (需要源码)。"},
	{Key: "[S]", Name: "显示配置", Value: "config", Desc: "显示当前项目、源码、汉化、输出目录的路径配置信息。"},
	{Key: "[!]", Name: "卸载清理", Value: "uninstall", Desc: "一键卸载汉化工具，清理所有相关文件，还原干净环境。"},
	{Key: "[X]", Name: "退出", Value: "exit", Desc: "退出管理工具。"},
}

// 教程数据
var Tutorials = []Tutorial{
	{
		Title: "OpenCode 基础",
		Content: []string{
			"核心功能：开源 AI 编程助手，TUI 界面，支持鼠标",
			"1. 连接模型：运行后输入 /connect 配置 API Key",
			"2. 汉化流程：更新源码 -> 应用汉化 -> 编译构建",
			"3. 常用命令：/theme 换肤，/share 分享对话",
			"推荐使用 [一键全流程] 完成汉化和编译",
		},
	},
	{
		Title: "Oh-My-OpenCode",
		Content: []string{
			"OpenCode 的增强扩展插件 (类似 Oh My Zsh)",
			"• 智能体：Sisyphus(编排), Oracle(分析), Librarian(研究)",
			"• 功能：多模型协作, 提示词优化, 后台任务管理",
			"• 安装：运行 [O] Oh-My-OC 菜单一键安装",
			"配置文件: ~/.config/opencode/oh-my-opencode.json",
		},
	},
	{
		Title: "自定义模型",
		Content: []string{
			"配置文件: ~/.config/opencode/opencode.json",
			"1. 一键配置：使用 [A] Antigravity 配置本地模型",
			"2. 手动配置：在 provider 字段添加 OpenAI 兼容接口",
			"   (如 DeepSeek, Claude, Gemini, GLM 等)",
			"支持配置 baseURL, apiKey 和自定义 models 列表",
		},
	},
	{
		Title: "汉化工具指南",
		Content: []string{
			"• 导航：↑↓←→ 移动, Enter 确认, 1-9 数字键快捷选择",
			"• Tab键：切换下方教程板块",
			"• 故障恢复：[~] 恢复源码 使用 Git 还原纯净状态",
			"• 版本回滚：直接使用 git checkout 或 git stash",
			"项目地址: github.com/1186258278/OpenCodeChineseTranslation",
		},
	},
}
