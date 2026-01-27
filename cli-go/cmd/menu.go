package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"

	"opencode-cli/internal/core"
	"opencode-cli/internal/tui"

	"github.com/spf13/cobra"
)

var menuCmd = &cobra.Command{
	Use:   "interactive",
	Short: "启动交互式菜单",
	Run: func(cmd *cobra.Command, args []string) {
		RunMenu()
	},
}

// RunMenu 运行交互式菜单循环
func RunMenu() {
	for {
		// 获取状态信息
		status := getStatus()

		// 运行菜单
		title := fmt.Sprintf("OpenCode 汉化管理工具 v%s", core.VERSION)
		result, err := tui.Run(
			title,
			tui.MainMenuItems,
			tui.Tutorials,
			status,
		)

		if err != nil {
			fmt.Printf("菜单错误: %v\n", err)
			return
		}

		// 处理选择结果
		if result == "exit" || result == "" {
			fmt.Println("\n再见!")
			return
		}

		// 执行操作
		executeAction(result)

		// 等待用户按键继续
		fmt.Println("\n✓ 操作完成，按回车键返回菜单...")
		fmt.Scanln()

		// 强制清屏，防止上一命令的输出残留影响 TUI 渲染
		if runtime.GOOS == "windows" {
			cmd := exec.Command("cmd", "/c", "cls")
			cmd.Stdout = os.Stdout
			cmd.Run()
		} else {
			fmt.Print("\033[H\033[2J")
		}
	}
}

// getStatus 获取当前状态
func getStatus() tui.StatusInfo {
	opencodeDir, _ := core.GetOpencodeDir()
	binDir, _ := core.GetBinDir()

	// 判断文件是否存在
	sourceExists := core.DirExists(opencodeDir)
	
	// 汉化配置：使用 HasI18nConfig()，始终有内嵌资源可用
	i18nExists := core.HasI18nConfig()

	// 判断二进制是否存在
	exeName := "opencode"
	if runtime.GOOS == "windows" {
		exeName = "opencode.exe"
	}
	binaryExists := core.FileExists(filepath.Join(binDir, exeName))

	// 获取 Bun 版本
	bunVersion := getBunVersion()

	return tui.StatusInfo{
		Version:       "v" + core.VERSION,
		Path:          opencodeDir,
		SourceExists:  sourceExists,
		I18nExists:    i18nExists,
		BinaryExists:  binaryExists,
		BunVersion:    bunVersion,
		BunRecommend:  "1.3.5",
		CheckComplete: false, // 暂时不检测更新
	}
}

// getBunVersion 获取 Bun 版本
func getBunVersion() string {
	cmd := exec.Command("bun", "--version")
	output, err := cmd.Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(output))
}

// executeAction 执行菜单操作
func executeAction(action string) {
	switch action {
	case "full":
		fmt.Println("\n▶ 开始完整工作流...")
		runFullWorkflow()

	case "update":
		fmt.Println("\n▶ 更新源码...")
		updateCmd.Run(updateCmd, []string{})

	case "restore":
		fmt.Println("\n▶ 恢复源码...")
		if dir, err := core.GetOpencodeDir(); err == nil {
			err := core.CleanRepo(dir)
			if err == nil {
				fmt.Print("\n是否立即编译并部署英文版 (重置为原版)? (y/N): ")
				var input string
				fmt.Scanln(&input)
				if strings.ToLower(input) == "y" {
					fmt.Println("\n▶ 编译英文版...")
					buildCmd.Run(buildCmd, []string{})
					fmt.Println("\n▶ 部署英文版...")
					runDeploy(false)
				}
			}
		}

	case "apply":
		fmt.Println("\n▶ 应用汉化...")
		applyCmd.Run(applyCmd, []string{})

	case "verify":
		runVerify(true, false)

	case "build":
		fmt.Println("\n▶ 编译构建...")
		buildCmd.Run(buildCmd, []string{})

	case "download":
		runDownload()

	case "deploy":
		// 菜单中默认不创建快捷方式，或者可以增加子菜单询问
		// 这里简化为不创建快捷方式，因为菜单操作通常是临时的
		runDeploy(false)

	case "package-all":
		fmt.Println("\n▶ 打包六端 (Win/Mac/Linux x64/arm64)...")
		packageCmd.Run(packageCmd, []string{})

	case "launch":
		fmt.Println("\n▶ 启动 OpenCode...")
		launchOpenCode()

	case "antigravity":
		runAntigravity()

	case "ohmyopencode":
		runOhMyOpenCode()

	case "helper":
		runHelper()

	case "github":
		fmt.Println("\n▶ 打开 GitHub 仓库...")
		openBrowser("https://github.com/1186258278/OpenCodeChineseTranslation")

	case "env":
		fmt.Println("\n▶ 检查环境...")
		checkEnvironment()

	case "diagnose":
		fmt.Println("\n▶ 诊断修复...")
		diagnoseCmd.Run(diagnoseCmd, []string{})

	case "env-install":
		runEnvInstall()

	case "fix-bun":
		runFixBun()

	case "clean-cache":
		fmt.Println("\n▶ 清理缓存...")
		cleanCache()

	case "changelog":
		fmt.Println("\n▶ OpenCode 更新日志 (最近 15 条):")
		fmt.Println(core.GetOpencodeChangelog(15))

	case "update-script":
		fmt.Println("\n▶ 更新脚本...")
		updateScript()

	case "config":
		fmt.Println("\n▶ 显示配置:")
		homeDir, _ := os.UserHomeDir()
		projectDir, _ := core.GetProjectDir()
		opencodeDir, _ := core.GetOpencodeDir()
		i18nDir, _ := core.GetI18nDir()
		binDir, _ := core.GetBinDir()
		deployDir, _ := getDeployDir()
		
		fmt.Println("\n  [统一安装目录]")
		fmt.Printf("    根目录: %s/.opencode-i18n/\n", homeDir)
		fmt.Printf("    部署目录: %s\n", deployDir)
		fmt.Printf("    源码目录: %s\n", opencodeDir)
		fmt.Printf("    构建目录: %s\n", binDir)
		
		fmt.Println("\n  [开发环境]")
		fmt.Printf("    项目目录: %s\n", projectDir)
		if i18nDir != "" {
			fmt.Printf("    汉化目录: %s (外部)\n", i18nDir)
		} else {
			fmt.Println("    汉化目录: 使用内嵌资源")
		}
		
		// 检查目录状态
		fmt.Println("\n  [目录状态]")
		if core.DirExists(opencodeDir) {
			fmt.Println("    源码: ✓ 已克隆")
		} else {
			fmt.Println("    源码: ✗ 未克隆 (运行 update 获取)")
		}
		if core.DirExists(deployDir) {
			fmt.Println("    部署: ✓ 已配置")
		} else {
			fmt.Println("    部署: ✗ 未部署")
		}

	case "uninstall":
		fmt.Println("\n▶ 卸载清理...")
		uninstallCmd.Run(uninstallCmd, []string{})

	default:
		fmt.Printf("\n未实现的操作: %s\n", action)
	}
}

// runFullWorkflow 完整工作流
func runFullWorkflow() {
	// 0. 恢复源码 (确保纯净环境)
	fmt.Println("▶ 正在准备纯净环境...")
	if dir, err := core.GetOpencodeDir(); err == nil {
		if err := core.CleanRepo(dir); err != nil {
			fmt.Printf("警告: 清理源码失败: %v\n", err)
		}
	}

	fmt.Println("\n[1/5] 更新 OpenCode 源码")
	updateCmd.Run(updateCmd, []string{})

	fmt.Println("\n[2/5] 应用汉化配置")
	applyCmd.Run(applyCmd, []string{})

	fmt.Println("\n[3/5] 验证汉化配置")
	runVerify(false, false)

	fmt.Println("\n[4/5] 编译构建")
	if err := RunBuild("", true, false); err != nil {
		fmt.Println("\n❌ 全流程中断: 构建失败")
		return
	}

	fmt.Println("\n[5/5] 部署全局命令")
	runDeploy(false)

	fmt.Println("\n✓ 完整工作流执行完成!")
}

// launchOpenCode 启动 OpenCode
func launchOpenCode() {
	exeName := "opencode"
	if runtime.GOOS == "windows" {
		exeName = "opencode.exe"
	}

	// 1. 尝试从构建目录查找 (开发环境)
	binDir, _ := core.GetBinDir()
	buildPath := filepath.Join(binDir, exeName)
	if core.FileExists(buildPath) {
		runExe(buildPath)
		return
	}

	// 2. 尝试从当前 CLI 所在目录查找 (部署环境)
	if selfPath, err := os.Executable(); err == nil {
		selfDir := filepath.Dir(selfPath)
		deployPath := filepath.Join(selfDir, exeName)
		if core.FileExists(deployPath) {
			runExe(deployPath)
			return
		}
	}

	// 3. 尝试从 PATH 查找
	if path, err := exec.LookPath(exeName); err == nil {
		runExe(path)
		return
	}

	fmt.Println("✗ 未找到 OpenCode 可执行文件")
	fmt.Println("  请先运行 [编译构建] 或 [部署命令]")
}

// runExe 运行可执行文件
func runExe(path string) {
	fmt.Printf("启动: %s\n", path)
	cmd := exec.Command(path)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	// 在后台启动，不阻塞 CLI
	if err := cmd.Start(); err != nil {
		fmt.Printf("启动失败: %v\n", err)
	} else {
		fmt.Println("✓ OpenCode 已在后台启动")
	}
}

// checkEnvironment 检查环境
func checkEnvironment() {
	// Node.js
	nodeVersion := getCommandVersion("node", "--version")
	if nodeVersion != "" {
		fmt.Printf("  ✓ Node.js: %s\n", nodeVersion)
	} else {
		fmt.Println("  ✗ Node.js: 未安装")
	}

	// Bun
	bunVersion := getCommandVersion("bun", "--version")
	if bunVersion != "" {
		fmt.Printf("  ✓ Bun: %s\n", bunVersion)
	} else {
		fmt.Println("  ✗ Bun: 未安装")
	}

	// Git
	gitVersion := getCommandVersion("git", "--version")
	if gitVersion != "" {
		fmt.Printf("  ✓ Git: %s\n", gitVersion)
	} else {
		fmt.Println("  ✗ Git: 未安装")
	}
}

// cleanCache 清理缓存
func cleanCache() {
	cmd := exec.Command("bun", "pm", "cache", "rm")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		fmt.Printf("清理缓存失败: %v\n", err)
	} else {
		fmt.Println("✓ 缓存已清理")
	}
}

// updateScript 更新脚本
func updateScript() {
	projectDir, _ := core.GetProjectDir()
	cmd := exec.Command("git", "pull", "--ff-only")
	cmd.Dir = projectDir
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		fmt.Printf("更新失败: %v\n", err)
	} else {
		fmt.Println("✓ 脚本已更新")
	}
}

// openBrowser 打开浏览器
func openBrowser(url string) {
	var cmd *exec.Cmd
	switch runtime.GOOS {
	case "windows":
		// 优先尝试 rundll32，因为它不依赖 cmd.exe
		cmd = exec.Command("rundll32", "url.dll,FileProtocolHandler", url)
		if err := cmd.Start(); err != nil {
			// 如果 rundll32 失败，尝试 cmd /c start
			// 使用 cmd /c start "" "url" 是最稳健的方式
			cmd = exec.Command("cmd", "/c", "start", "", url)
		} else {
			return // rundll32 启动成功
		}
	case "darwin":
		cmd = exec.Command("open", url)
	default:
		cmd = exec.Command("xdg-open", url)
	}
	// 将输出重定向到空，防止干扰 TUI
	cmd.Stdout = nil
	cmd.Stderr = nil

	err := cmd.Start() // 使用 Start 而不是 Run，让它在后台运行
	if err != nil {
		fmt.Printf("无法打开浏览器: %v\n", err)
	}
}

// getCommandVersion 获取命令版本
func getCommandVersion(name string, arg string) string {
	cmd := exec.Command(name, arg)
	output, err := cmd.Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(output))
}

func init() {
	rootCmd.AddCommand(menuCmd)
}
