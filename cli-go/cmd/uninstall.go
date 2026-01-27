package cmd

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"

	"opencode-cli/internal/core"

	"github.com/spf13/cobra"
)

var uninstallCmd = &cobra.Command{
	Use:   "uninstall",
	Short: "卸载 OpenCode 汉化工具及相关文件",
	Long: `一键清理 OpenCode 汉化工具安装的所有文件，还原干净环境。

清理内容包括：
  - CLI 工具 (opencode-cli)
  - 汉化版 OpenCode 可执行文件
  - OpenCode 源码目录 (可选)
  - 配置文件 (可选)
  - PATH 环境变量中的相关条目`,
	Run: func(cmd *cobra.Command, args []string) {
		force, _ := cmd.Flags().GetBool("force")
		all, _ := cmd.Flags().GetBool("all")
		keepConfig, _ := cmd.Flags().GetBool("keep-config")

		runUninstall(force, all, keepConfig)
	},
}

func init() {
	rootCmd.AddCommand(uninstallCmd)
	uninstallCmd.Flags().BoolP("force", "f", false, "跳过确认，直接执行")
	uninstallCmd.Flags().Bool("all", false, "完全清理 (包括源码目录和配置文件)")
	uninstallCmd.Flags().Bool("keep-config", false, "保留配置文件")
}

// UninstallItem 卸载项目
type UninstallItem struct {
	Name        string
	Path        string
	Type        string // "file", "dir", "path"
	Description string
	Optional    bool
}

func runUninstall(force, all, keepConfig bool) {
	fmt.Println("╔══════════════════════════════════════════╗")
	fmt.Println("║   OpenCode 汉化工具卸载程序              ║")
	fmt.Println("╚══════════════════════════════════════════╝")
	fmt.Println()

	// 收集要清理的项目
	items := collectUninstallItems(all, keepConfig)

	if len(items) == 0 {
		fmt.Println("✓ 未发现需要清理的文件")
		return
	}

	// 显示将要清理的内容
	fmt.Println("将要清理以下内容：")
	fmt.Println()

	for i, item := range items {
		status := "✓"
		if !pathExists(item.Path) {
			status = "○" // 不存在
		}
		optTag := ""
		if item.Optional {
			optTag = " (可选)"
		}
		fmt.Printf("  %d. [%s] %s%s\n", i+1, status, item.Name, optTag)
		fmt.Printf("      %s\n", item.Path)
		if item.Description != "" {
			fmt.Printf("      %s\n", item.Description)
		}
	}

	fmt.Println()
	fmt.Println("图例: ✓=存在 ○=不存在/已清理")
	fmt.Println()

	// 确认
	if !force {
		fmt.Print("确定要卸载吗？此操作不可撤销 [y/N]: ")
		reader := bufio.NewReader(os.Stdin)
		input, _ := reader.ReadString('\n')
		input = strings.TrimSpace(strings.ToLower(input))

		if input != "y" && input != "yes" {
			fmt.Println("\n已取消卸载")
			return
		}
	}

	fmt.Println()
	fmt.Println("开始卸载...")
	fmt.Println()

	// 执行清理
	successCount := 0
	failCount := 0

	for _, item := range items {
		if !pathExists(item.Path) {
			fmt.Printf("  ○ 跳过 %s (不存在)\n", item.Name)
			continue
		}

		var err error
		switch item.Type {
		case "file":
			err = os.Remove(item.Path)
		case "dir":
			err = os.RemoveAll(item.Path)
		case "path":
			err = removeFromPath(item.Path)
		}

		if err != nil {
			fmt.Printf("  ✗ 清理 %s 失败: %v\n", item.Name, err)
			failCount++
		} else {
			fmt.Printf("  ✓ 已清理 %s\n", item.Name)
			successCount++
		}
	}

	fmt.Println()
	fmt.Println("════════════════════════════════════════════")

	if failCount == 0 {
		fmt.Println("✓ 卸载完成！")
		fmt.Println()
		fmt.Println("感谢使用 OpenCode 汉化工具！")
		fmt.Println("如需重新安装，访问:")
		fmt.Println("  https://github.com/1186258278/OpenCodeChineseTranslation")
	} else {
		fmt.Printf("卸载完成，成功 %d 项，失败 %d 项\n", successCount, failCount)
		fmt.Println()
		fmt.Println("部分文件可能因权限问题无法删除，请手动清理：")
		for _, item := range items {
			if pathExists(item.Path) {
				fmt.Printf("  - %s\n", item.Path)
			}
		}
	}

	// 提示重启终端
	fmt.Println()
	fmt.Println("请重启终端以使环境变量更改生效")
}

func collectUninstallItems(all, keepConfig bool) []UninstallItem {
	var items []UninstallItem

	// 1. CLI 工具部署目录
	deployDir := getDeployDirectory()
	if deployDir != "" {
		items = append(items, UninstallItem{
			Name:        "CLI 工具目录",
			Path:        deployDir,
			Type:        "dir",
			Description: "包含 opencode-cli 和 opencode 可执行文件",
		})

		// PATH 条目
		items = append(items, UninstallItem{
			Name:        "PATH 环境变量",
			Path:        deployDir,
			Type:        "path",
			Description: "从用户 PATH 中移除",
		})
	}

	// 2. 安装目录 (~/.opencode-i18n)
	homeDir, _ := os.UserHomeDir()
	installDir := filepath.Join(homeDir, ".opencode-i18n")
	if pathExists(installDir) {
		items = append(items, UninstallItem{
			Name:        "安装目录",
			Path:        installDir,
			Type:        "dir",
			Description: "一键安装脚本创建的目录",
		})
	}

	// 3. OpenCode 源码目录 (可选)
	if all {
		opencodeDir, _ := core.GetOpencodeDir()
		if opencodeDir != "" && pathExists(opencodeDir) {
			items = append(items, UninstallItem{
				Name:        "OpenCode 源码",
				Path:        opencodeDir,
				Type:        "dir",
				Description: "Git 克隆的 OpenCode 源码目录",
				Optional:    true,
			})
		}
	}

	// 4. 配置文件 (可选)
	if all && !keepConfig {
		configDir := getConfigDirectory()
		if configDir != "" && pathExists(configDir) {
			items = append(items, UninstallItem{
				Name:        "配置文件",
				Path:        configDir,
				Type:        "dir",
				Description: "OpenCode 配置和数据目录",
				Optional:    true,
			})
		}
	}

	// 5. 构建输出目录
	binDir, _ := core.GetBinDir()
	if binDir != "" && pathExists(binDir) && binDir != deployDir {
		items = append(items, UninstallItem{
			Name:        "构建输出目录",
			Path:        binDir,
			Type:        "dir",
			Description: "本地编译生成的二进制文件",
			Optional:    true,
		})
	}

	return items
}

func getDeployDirectory() string {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return ""
	}

	// 统一目录：~/.opencode-i18n/bin (三端一致)
	return filepath.Join(homeDir, ".opencode-i18n", "bin")
}

func getConfigDirectory() string {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return ""
	}

	if runtime.GOOS == "windows" {
		appData := os.Getenv("APPDATA")
		if appData != "" {
			return filepath.Join(appData, "opencode")
		}
		return filepath.Join(homeDir, "AppData", "Roaming", "opencode")
	}

	// macOS/Linux: ~/.config/opencode
	return filepath.Join(homeDir, ".config", "opencode")
}

func pathExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

func removeFromPath(dirToRemove string) error {
	if runtime.GOOS == "windows" {
		return removeFromPathWindows(dirToRemove)
	}
	// Unix 系统通常不需要自动移除，只是提示用户
	fmt.Printf("      提示: 请手动从 shell 配置文件中移除 PATH 条目\n")
	return nil
}

func removeFromPathWindows(dirToRemove string) error {
	// 读取当前用户 PATH
	script := fmt.Sprintf(`
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$paths = $userPath -split ";"
$newPaths = $paths | Where-Object { $_ -ne "%s" -and $_ -ne "" }
$newPath = $newPaths -join ";"
[Environment]::SetEnvironmentVariable("Path", $newPath, "User")
`, dirToRemove)

	cmd := exec.Command("powershell", "-NoProfile", "-Command", script)
	return cmd.Run()
}
