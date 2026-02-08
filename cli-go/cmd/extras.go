package cmd

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"opencode-cli/internal/core"

	"github.com/spf13/cobra"
)

// ohmyopencodeCmd Oh-My-OpenCode 命令
var ohmyopencodeCmd = &cobra.Command{
	Use:   "ohmyopencode",
	Short: "安装 Oh-My-OpenCode 插件",
	Long:  "Install Oh-My-OpenCode plugin for enhanced features",
	Run: func(cmd *cobra.Command, args []string) {
		runOhMyOpenCode()
	},
}

// helperCmd 智谱编码助手命令
var helperCmd = &cobra.Command{
	Use:   "helper",
	Short: "安装智谱编码助手",
	Long:  "Install GLM Coding Plan helper for Claude Code CLI management",
	Run: func(cmd *cobra.Command, args []string) {
		runHelper()
	},
}

// fixBunCmd 校准 Bun 命令
var fixBunCmd = &cobra.Command{
	Use:   "fix-bun",
	Short: "校准 Bun 版本",
	Long:  "Calibrate Bun to the recommended version",
	Run: func(cmd *cobra.Command, args []string) {
		runFixBun()
	},
}

func init() {
	rootCmd.AddCommand(ohmyopencodeCmd)
	rootCmd.AddCommand(helperCmd)
	rootCmd.AddCommand(fixBunCmd)
}

func runOhMyOpenCode() {
	fmt.Println("")
	fmt.Println("══════════════════════════════════════════════════")
	fmt.Println("  Oh-My-OpenCode 安装向导")
	fmt.Println("══════════════════════════════════════════════════")
	fmt.Println("")
	fmt.Println("  正在初始化官方安装器...")
	fmt.Println("  这将帮助您配置智能体、订阅和插件集成")
	fmt.Println("")

	// 1. 检查 Bun 环境
	if _, err := exec.LookPath("bun"); err != nil {
		fmt.Println("✗ 未检测到 Bun 环境")
		fmt.Println("  Oh-My-OpenCode 需要 Bun 来运行安装程序")
		fmt.Println("")
		fmt.Println("  请先运行: opencode-cli fix-bun")
		return
	}

	// 2. 收集用户订阅信息
	reader := bufio.NewReader(os.Stdin)

	// Antigravity (最优先)
	fmt.Println("❓ [1/1] 您是否使用 Antigravity Tools (Google OAuth) 作为主要模型源? [Y/n]")
	fmt.Println("   (如果您已运行 'opencode-cli antigravity' 配置过，请选 Yes)")
	fmt.Print("   请选择 [Y/n]: ")
	antigravityAns, _ := reader.ReadString('\n')
	antigravityAns = strings.TrimSpace(strings.ToLower(antigravityAns))

	isAntigravityMode := false
	if antigravityAns == "" || antigravityAns == "y" || antigravityAns == "yes" {
		isAntigravityMode = true
	}

	claudeFlag := "no"
	openaiFlag := "no"
	geminiFlag := "no"
	// copilotFlag := "no"
	// zenFlag := "no"
	// zaiFlag := "no"

	if !isAntigravityMode {
		// 如果不使用 Antigravity，则询问官方订阅
		fmt.Println("\n❓ [1/3] 您是否有 Claude Pro/Max 订阅?")
		fmt.Println("   [y] 是 (标准版)")
		fmt.Println("   [m] 是 (Max 20倍速模式)")
		fmt.Println("   [n] 否")
		fmt.Print("   请选择 [y/m/n]: ")
		claudeAns, _ := reader.ReadString('\n')
		claudeAns = strings.TrimSpace(strings.ToLower(claudeAns))

		if claudeAns == "m" || claudeAns == "max" {
			claudeFlag = "max20"
		} else if claudeAns == "y" || claudeAns == "yes" {
			claudeFlag = "yes"
		}

		if claudeFlag == "no" {
			fmt.Println("")
			fmt.Println("⚠️  警告: 未检测到 Claude 订阅")
			fmt.Println("   Sisyphus (编排智能体) 在没有 Claude Opus/3.5 的情况下体验会显著下降。")
			fmt.Println("   建议至少配置一个高智商模型。")
			time.Sleep(2 * time.Second)
		}

		fmt.Print("\n❓ [2/3] 您是否有 OpenAI/ChatGPT Plus 订阅? [y/N]: ")
		openaiAns, _ := reader.ReadString('\n')
		openaiAns = strings.TrimSpace(strings.ToLower(openaiAns))
		if openaiAns == "y" || openaiAns == "yes" {
			openaiFlag = "yes"
		}

		fmt.Print("\n❓ [3/3] 您是否要集成 Google Gemini 模型? [y/N]: ")
		geminiAns, _ := reader.ReadString('\n')
		geminiAns = strings.TrimSpace(strings.ToLower(geminiAns))
		if geminiAns == "y" || geminiAns == "yes" {
			geminiFlag = "yes"
		}

		// 暂时隐藏不支持的选项
		/*
			fmt.Print("\n❓ [4/6] 您是否有 GitHub Copilot 订阅? [y/N]: ")
			copilotAns, _ := reader.ReadString('\n')
			copilotAns = strings.TrimSpace(strings.ToLower(copilotAns))
			if copilotAns == "y" || copilotAns == "yes" {
				copilotFlag = "yes"
			}

			fmt.Print("\n❓ [5/6] 您是否有 Z.ai Coding Plan 订阅? [y/N]: ")
			zaiAns, _ := reader.ReadString('\n')
			zaiAns = strings.TrimSpace(strings.ToLower(zaiAns))
			if zaiAns == "y" || zaiAns == "yes" {
				zaiFlag = "yes"
			}

			fmt.Print("\n❓ [6/6] 您是否有 OpenCode Zen 权限? [y/N]: ")
			zenAns, _ := reader.ReadString('\n')
			zenAns = strings.TrimSpace(strings.ToLower(zenAns))
			if zenAns == "y" || zenAns == "yes" {
				zenFlag = "yes"
			}
		*/
	} else {
		fmt.Println("\n✅ 已启用 Antigravity 模式")
		fmt.Println("   将自动配置智能体使用 AntigravityToolsClaude/Gemini 模型")
	}

	// 3. 构建并执行安装命令
	fmt.Println("")
	fmt.Println("🚀 正在启动官方安装程序...")
	fmt.Println("   (Bunx 将自动下载并执行 oh-my-opencode)")
	fmt.Println("")

	args := []string{
		"oh-my-opencode", "install",
		"--no-tui",
		fmt.Sprintf("--claude=%s", claudeFlag),
		fmt.Sprintf("--chatgpt=%s", openaiFlag), // 修正参数名: --openai -> --chatgpt
		fmt.Sprintf("--gemini=%s", geminiFlag),
		// 下列参数在当前发布的 oh-my-opencode 版本中可能不支持，暂时移除以防报错
		// fmt.Sprintf("--copilot=%s", copilotFlag),
		// fmt.Sprintf("--opencode-zen=%s", zenFlag),
		// fmt.Sprintf("--zai-coding-plan=%s", zaiFlag),
	}

	var cmd *exec.Cmd
	if runtime.GOOS == "windows" {
		// 直接调用 bun，不通过 cmd /c
		// 这样可以避免 "exec: \"cmd\": executable file not found in %PATH%" 的问题
		cmd = exec.Command("bun", append([]string{"x"}, args...)...)
	} else {
		fullArgs := append([]string{"x"}, args...)
		cmd = exec.Command("bun", fullArgs...)
	}

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	if err := cmd.Run(); err != nil {
		fmt.Println("")
		fmt.Printf("✗ 安装失败: %v\n", err)
		fmt.Println("  请尝试手动安装: bunx oh-my-opencode install")
		return
	}

	// 4. Antigravity 后处理配置
	if isAntigravityMode {
		fmt.Println("")
		fmt.Println("🔧 正在配置 Antigravity...")

		// 一站式配置：插件 + Provider + Agent
		if err := configureAntigravityAllInOne(); err != nil {
			fmt.Printf("✗ 配置失败: %v\n", err)
		} else {
			fmt.Println("✓ Antigravity 插件已注册")
			fmt.Println("✓ 模型 Provider 已配置")
			fmt.Println("✓ 智能体 (Agents) 已映射")
		}
	}

	fmt.Println("")
	fmt.Println("══════════════════════════════════════════════════")
	fmt.Println("  🎉 安装成功!")
	fmt.Println("══════════════════════════════════════════════════")
	fmt.Println("")
	fmt.Println("  下一步:")
	fmt.Println("  1. 重启 OpenCode 终端")
	fmt.Println("  2. 享受您的全新 AI 编程体验!")
	fmt.Println("")
}

// configureAntigravityAllInOne 一站式配置
func configureAntigravityAllInOne() error {
	homeDir, _ := os.UserHomeDir()
	configDir := filepath.Join(homeDir, ".config", "opencode")

	// 1. 更新 opencode.json (添加插件和 Provider)
	opencodeConfigPath := filepath.Join(configDir, "opencode.json")
	// 尝试读取 jsonc
	if _, err := os.Stat(opencodeConfigPath + "c"); err == nil {
		opencodeConfigPath += "c"
	}

	// 重新读取为 map 以保持灵活性
	var rawConfig map[string]interface{}
	data, err := os.ReadFile(opencodeConfigPath)
	if err != nil {
		rawConfig = make(map[string]interface{})
	} else {
		// 去除注释
		content := string(data)
		lines := strings.Split(content, "\n")
		var cleaned []string
		for _, line := range lines {
			trimmed := strings.TrimSpace(line)
			if !strings.HasPrefix(trimmed, "//") {
				cleaned = append(cleaned, line)
			}
		}
		json.Unmarshal([]byte(strings.Join(cleaned, "\n")), &rawConfig)
	}

	// 1.1 添加插件
	pluginName := "opencode-antigravity-auth@1.2.8"
	hasPlugin := false

	// 处理插件数组
	var plugins []interface{}
	if p, ok := rawConfig["plugin"]; ok {
		if pList, ok := p.([]interface{}); ok {
			plugins = pList
		}
	}

	for _, p := range plugins {
		if str, ok := p.(string); ok && strings.Contains(str, "opencode-antigravity-auth") {
			hasPlugin = true
			break
		}
	}

	if !hasPlugin {
		plugins = append(plugins, pluginName)
		rawConfig["plugin"] = plugins
	}

	// 1.2 添加 Provider
	providers, ok := rawConfig["provider"].(map[string]interface{})
	if !ok {
		providers = make(map[string]interface{})
	}

	// 注入 Antigravity Provider 配置
	endpoint := "http://127.0.0.1:8045" // 默认

	// Gemini
	providers["AntigravityToolsGemini"] = map[string]interface{}{
		"npm":  "@ai-sdk/google",
		"name": "Antigravity (Gemini)",
		"options": map[string]interface{}{
			"baseURL": fmt.Sprintf("%s/v1beta", endpoint),
			"apiKey":  "1",
		},
		"models": map[string]interface{}{
			"gemini-3-pro-high": map[string]interface{}{
				"id":   "gemini-3-pro-high",
				"name": "Gemini 3 Pro High",
				"limit": map[string]int{
					"context": 1000000,
					"output":  20000,
				},
			},
			"gemini-3-pro-low": map[string]interface{}{
				"id":   "gemini-3-pro-low",
				"name": "Gemini 3 Pro Low",
				"limit": map[string]int{
					"context": 1000000,
					"output":  20000,
				},
			},
		},
	}

	// Claude
	providers["AntigravityToolsClaude"] = map[string]interface{}{
		"npm":  "@ai-sdk/anthropic",
		"name": "Antigravity (Claude)",
		"options": map[string]interface{}{
			"baseURL": fmt.Sprintf("%s/v1", endpoint),
			"apiKey":  "1",
		},
		"models": map[string]interface{}{
			"claude-opus-4-5-thinking": map[string]interface{}{
				"id":   "claude-opus-4-5-thinking",
				"name": "Claude Opus 4.5 (Thinking)",
				"limit": map[string]int{
					"context": 200000,
					"output":  20000,
				},
			},
		},
	}

	rawConfig["provider"] = providers

	// 写入 opencode.json
	if err := writeJSON(opencodeConfigPath, rawConfig); err != nil {
		return fmt.Errorf("写入 opencode.json 失败: %v", err)
	}

	// 2. 写入 oh-my-opencode.json (Agent 映射),//AntigravityToolsClaude/claude-opus-4-5-thinking
	ohMyConfigPath := filepath.Join(configDir, "oh-my-opencode.json")
	ohMyConfig := `{
  "google_auth": false,
  "agents": {
    "Sisyphus": {
      "enabled": true,
      "model": "AntigravityToolsGemini/gemini-3-pro-high",
      "description": "编排智能体，负责任务分解和协调"
    },
    "oracle": {
      "enabled": true,
      "model": "AntigravityToolsGemini/gemini-3-pro-high",
      "description": "分析智能体，负责代码分析和建议"
    },
    "librarian": {
      "enabled": true,
      "model": "AntigravityToolsGemini/gemini-3-pro-low",
      "description": "研究智能体，负责文档和资料查询"
    },
    "explore": {
      "enabled": true,
      "model": "AntigravityToolsGemini/gemini-3-pro-low",
      "description": "探索智能体，负责代码库搜索"
    },
    "frontend-ui-ux-engineer": {
      "enabled": true,
      "model": "AntigravityToolsGemini/gemini-3-pro-high",
      "description": "前端智能体，负责 UI/UX 开发"
    },
    "document-writer": {
      "enabled": true,
      "model": "AntigravityToolsGemini/gemini-3-pro-low",
      "description": "文档智能体，负责撰写技术文档"
    }
  },
  "features": {
    "multiModel": true,
    "promptOptimization": true,
    "backgroundTasks": true
  },
  "background_task": {
    "defaultConcurrency": 5
  }
}`
	if err := os.WriteFile(ohMyConfigPath, []byte(ohMyConfig), 0644); err != nil {
		return fmt.Errorf("写入 oh-my-opencode.json 失败: %v", err)
	}

	return nil
}

// 辅助函数: 写入 JSON (简单版)
func writeJSON(path string, v interface{}) error {
	if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
		return err
	}
	file, err := os.Create(path)
	if err != nil {
		return err
	}
	defer file.Close()
	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	return encoder.Encode(v)
}

// runHelper 安装智谱编码助手 (GLM Coding Plan)
func runHelper() {
	fmt.Println("")
	fmt.Println("══════════════════════════════════════════════════")
	fmt.Println("  智谱编码助手安装向导")
	fmt.Println("══════════════════════════════════════════════════")
	fmt.Println("")
	fmt.Println("  GLM Coding Plan - 智谱编码助手")
	fmt.Println("  NPM 包: @z_ai/coding-helper")
	fmt.Println("  统一管理 Claude Code 等 CLI 工具")
	fmt.Println("")

	// 检查 Node.js 版本
	nodeVersion := ""
	if out, err := exec.Command("node", "--version").Output(); err == nil {
		nodeVersion = strings.TrimSpace(string(out))
	}

	if nodeVersion == "" {
		fmt.Println("✗ 未检测到 Node.js")
		fmt.Println("")
		fmt.Println("  智谱编码助手需要 Node.js >= v18.0.0")
		fmt.Println("")
		fmt.Println("  安装方式:")
		switch runtime.GOOS {
		case "windows":
			fmt.Println("    方法 1: winget install OpenJS.NodeJS.LTS")
			fmt.Println("    方法 2: scoop install nodejs-lts")
			fmt.Println("    方法 3: 官网下载 https://nodejs.org/")
		case "darwin":
			fmt.Println("    方法 1: brew install node@20")
			fmt.Println("    方法 2: 使用 nvm: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash")
			fmt.Println("            然后: nvm install 20")
		default:
			fmt.Println("    方法 1: 使用包管理器 (apt/yum/pacman) 安装 nodejs")
			fmt.Println("    方法 2: 使用 nvm: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash")
			fmt.Println("            然后: nvm install 20")
		}
		return
	}

	// 解析版本号
	versionStr := strings.TrimPrefix(nodeVersion, "v")
	parts := strings.Split(versionStr, ".")
	majorVersion := 0
	if len(parts) > 0 {
		fmt.Sscanf(parts[0], "%d", &majorVersion)
	}

	if majorVersion < 18 {
		fmt.Printf("✗ Node.js 版本过低: %s (需要 >= v18.0.0)\n", nodeVersion)
		fmt.Println("")
		fmt.Println("  请升级 Node.js:")
		switch runtime.GOOS {
		case "windows":
			fmt.Println("    winget upgrade OpenJS.NodeJS.LTS")
		case "darwin":
			fmt.Println("    brew upgrade node")
		default:
			fmt.Println("    使用包管理器或 nvm 升级到 v18+")
		}
		return
	}

	fmt.Printf("✓ Node.js 版本: %s (满足要求)\n", nodeVersion)
	fmt.Println("")

	// 检查 npx 是否可用
	if _, err := exec.LookPath("npx"); err != nil {
		fmt.Println("✗ 未找到 npx 命令")
		fmt.Println("  请确保 Node.js 安装正确，npx 通常随 npm 一起安装")
		return
	}

	reader := bufio.NewReader(os.Stdin)
	fmt.Print("是否安装智谱编码助手? [Y/n]: ")
	answer, _ := reader.ReadString('\n')
	answer = strings.TrimSpace(strings.ToLower(answer))
	if answer == "n" || answer == "no" {
		fmt.Println("安装已取消")
		return
	}

	fmt.Println("")
	fmt.Println("▶ 正在安装 @z_ai/coding-helper...")
	fmt.Println("  (首次安装可能需要较长时间)")

	// 使用 npm install -g 全局安装
	cmd := exec.Command("npm", "install", "-g", "@z_ai/coding-helper")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Printf("✗ 安装失败: %v\n", err)
		fmt.Println("")
		fmt.Println("  可能的解决方案:")
		if runtime.GOOS != "windows" {
			fmt.Println("    0. 权限不足? 尝试使用: sudo npm install -g @z_ai/coding-helper")
		}
		fmt.Println("    1. 检查网络连接")
		fmt.Println("    2. 尝试使用淘宝镜像: npm config set registry https://registry.npmmirror.com")
		fmt.Println("    3. Windows 用户尝试以管理员身份运行")
		return
	}

	fmt.Println("")
	fmt.Println("✓ 智谱编码助手安装完成!")
	fmt.Println("")
	fmt.Println("  使用方式:")
	fmt.Println("    coding-helper          # 启动助手")
	fmt.Println("    coding-helper --help   # 查看帮助")
}

func runFixBun() {
	fmt.Println("")
	fmt.Println("▶ 校准 Bun 版本")

	// 获取推荐版本
	recommendedVersion := "1.3.8"

	// 获取源码目录
	opencodeDir, err := core.GetOpencodeDir()
	if err == nil && core.Exists(opencodeDir) {
		// 尝试从 package.json 读取
		pkgPath := filepath.Join(opencodeDir, "package.json")
		if data, err := os.ReadFile(pkgPath); err == nil {
			content := string(data)
			if strings.Contains(content, "packageManager") {
				// 简单解析
				if idx := strings.Index(content, "bun@"); idx != -1 {
					start := idx + 4
					end := start
					for end < len(content) && (content[end] >= '0' && content[end] <= '9' || content[end] == '.') {
						end++
					}
					if end > start {
						recommendedVersion = content[start:end]
					}
				}
			}
		}
	}

	// 获取当前版本
	currentVersion := ""
	if out, err := exec.Command("bun", "--version").Output(); err == nil {
		currentVersion = strings.TrimSpace(string(out))
	}

	if currentVersion == "" {
		fmt.Println("✗ Bun 未安装")
		fmt.Println("")
		fmt.Println("  安装 Bun:")
		switch runtime.GOOS {
		case "windows":
			fmt.Println("    powershell -c \"irm bun.sh/install.ps1 | iex\"")
		default:
			fmt.Println("    curl -fsSL https://bun.sh/install | bash")
		}
		return
	}

	fmt.Printf("  当前版本: %s\n", currentVersion)
	fmt.Printf("  推荐版本: %s\n", recommendedVersion)

	if currentVersion == recommendedVersion {
		fmt.Println("")
		fmt.Println("✓ Bun 版本已是推荐版本，无需校准")
		return
	}

	fmt.Println("")

	reader := bufio.NewReader(os.Stdin)
	fmt.Printf("是否将 Bun 升级/降级到 v%s? [Y/n]: ", recommendedVersion)
	answer, _ := reader.ReadString('\n')
	answer = strings.TrimSpace(strings.ToLower(answer))
	if answer == "n" || answer == "no" {
		fmt.Println("操作已取消")
		return
	}

	fmt.Println("")
	fmt.Printf("▶ 正在安装 Bun v%s...\n", recommendedVersion)

	var cmd *exec.Cmd
	switch runtime.GOOS {
	case "windows":
		cmd = exec.Command("powershell", "-Command",
			fmt.Sprintf("irm https://bun.sh/install.ps1 | iex; bun upgrade --version %s", recommendedVersion))
	default:
		cmd = exec.Command("bash", "-c",
			fmt.Sprintf("curl -fsSL https://bun.sh/install | bash -s bun-v%s", recommendedVersion))
	}

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Printf("✗ 安装失败: %v\n", err)
		return
	}

	fmt.Println("")
	fmt.Printf("✓ Bun v%s 安装完成\n", recommendedVersion)
	fmt.Println("  请重新打开终端使更改生效")
}
