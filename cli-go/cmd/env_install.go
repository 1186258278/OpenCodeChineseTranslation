package cmd

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"

	"opencode-cli/internal/core"

	"github.com/spf13/cobra"
)

var envInstallCmd = &cobra.Command{
	Use:   "env-install",
	Short: "一键安装编译环境 (Git/Node.js/Bun)",
	Long:  "One-click installation of the required build environment for OpenCode",
	Run: func(cmd *cobra.Command, args []string) {
		runEnvInstall()
	},
}

func init() {
	rootCmd.AddCommand(envInstallCmd)
}

// EnvStatus 环境状态
type EnvStatus struct {
	Name      string
	Installed bool
	Version   string
	Required  string
}

// runEnvInstall 运行环境安装
func runEnvInstall() {
	fmt.Println("")
	fmt.Println("══════════════════════════════════════════════════")
	fmt.Println("  OpenCode 编译环境一键安装")
	fmt.Println("══════════════════════════════════════════════════")
	fmt.Println("")

	// 1. 检测当前系统
	fmt.Printf("▶ 系统检测\n")
	platform := core.DetectPlatform()
	fmt.Printf("  平台: %s\n", platform)
	fmt.Printf("  系统: %s/%s\n", runtime.GOOS, runtime.GOARCH)
	fmt.Println("")

	// 2. 检查现有环境
	fmt.Println("▶ 环境检查")
	envList := checkAllEnvironments()

	allInstalled := true
	for _, env := range envList {
		if env.Installed {
			fmt.Printf("  ✓ %s: %s (需要: %s)\n", env.Name, env.Version, env.Required)
		} else {
			fmt.Printf("  ✗ %s: 未安装 (需要: %s)\n", env.Name, env.Required)
			allInstalled = false
		}
	}
	fmt.Println("")

	if allInstalled {
		fmt.Println("✓ 所有编译环境已就绪！")
		fmt.Println("  您可以直接运行 'opencode-cli build' 进行编译。")
		return
	}

	// 3. 显示安装选项
	fmt.Println("▶ 安装选项")
	fmt.Println("")
	fmt.Println("  [1] 一键安装全部缺失环境 (推荐)")
	fmt.Println("  [2] 仅安装 Git")
	fmt.Println("  [3] 仅安装 Node.js (LTS)")
	fmt.Println("  [4] 仅安装 Bun (v1.3.5+)")
	fmt.Println("  [5] 安装/更新 npm 到指定版本")
	fmt.Println("  [0] 返回")
	fmt.Println("")

	reader := bufio.NewReader(os.Stdin)
	fmt.Print("请选择 [0-5]: ")
	choice, _ := reader.ReadString('\n')
	choice = strings.TrimSpace(choice)

	switch choice {
	case "1":
		installAllMissing(envList)
	case "2":
		installGit()
	case "3":
		installNodeJS()
	case "4":
		installBun()
	case "5":
		installNpmVersion()
	case "0":
		return
	default:
		fmt.Println("无效选择")
	}
}

// checkAllEnvironments 检查所有环境
func checkAllEnvironments() []EnvStatus {
	return []EnvStatus{
		{
			Name:      "Git",
			Installed: checkCommandExists("git"),
			Version:   getCommandVersion("git", "--version"),
			Required:  "任意版本",
		},
		{
			Name:      "Node.js",
			Installed: checkCommandExists("node"),
			Version:   getCommandVersion("node", "--version"),
			Required:  "v18.0.0+",
		},
		{
			Name:      "Bun",
			Installed: checkCommandExists("bun"),
			Version:   getCommandVersion("bun", "--version"),
			Required:  "v1.3.5+",
		},
	}
}

// checkCommandExists 检查命令是否存在
func checkCommandExists(name string) bool {
	_, err := exec.LookPath(name)
	return err == nil
}

// installAllMissing 安装所有缺失的环境
func installAllMissing(envList []EnvStatus) {
	fmt.Println("")
	fmt.Println("▶ 开始安装缺失环境...")
	fmt.Println("")

	for _, env := range envList {
		if !env.Installed {
			switch env.Name {
			case "Git":
				installGit()
			case "Node.js":
				installNodeJS()
			case "Bun":
				installBun()
			}
			fmt.Println("")
		}
	}

	fmt.Println("══════════════════════════════════════════════════")
	fmt.Println("  安装完成！")
	fmt.Println("══════════════════════════════════════════════════")
	fmt.Println("")
	fmt.Println("请重启终端使环境变量生效，然后运行:")
	fmt.Println("  opencode-cli env  (验证环境)")
	fmt.Println("  opencode-cli build  (编译 OpenCode)")
}

// installGit 安装 Git
func installGit() {
	fmt.Println("▶ 安装 Git...")

	switch runtime.GOOS {
	case "windows":
		// 尝试 winget
		if checkCommandExists("winget") {
			fmt.Println("  使用 winget 安装...")
			runInstallCommand("winget", "install", "--id", "Git.Git", "-e", "--source", "winget")
			return
		}
		// 尝试 scoop
		if checkCommandExists("scoop") {
			fmt.Println("  使用 scoop 安装...")
			runInstallCommand("scoop", "install", "git")
			return
		}
		// 尝试 chocolatey
		if checkCommandExists("choco") {
			fmt.Println("  使用 chocolatey 安装...")
			runInstallCommand("choco", "install", "git", "-y")
			return
		}
		// 提示手动安装
		fmt.Println("  ✗ 未找到包管理器 (winget/scoop/choco)")
		fmt.Println("  请手动下载安装: https://git-scm.com/download/win")

	case "darwin":
		if checkCommandExists("brew") {
			fmt.Println("  使用 Homebrew 安装...")
			runInstallCommand("brew", "install", "git")
		} else {
			fmt.Println("  请安装 Xcode Command Line Tools:")
			fmt.Println("  xcode-select --install")
		}

	case "linux":
		// 检测包管理器
		if checkCommandExists("apt-get") {
			fmt.Println("  使用 apt 安装...")
			runInstallCommand("sudo", "apt-get", "update")
			runInstallCommand("sudo", "apt-get", "install", "-y", "git")
		} else if checkCommandExists("dnf") {
			fmt.Println("  使用 dnf 安装...")
			runInstallCommand("sudo", "dnf", "install", "-y", "git")
		} else if checkCommandExists("yum") {
			fmt.Println("  使用 yum 安装...")
			runInstallCommand("sudo", "yum", "install", "-y", "git")
		} else if checkCommandExists("pacman") {
			fmt.Println("  使用 pacman 安装...")
			runInstallCommand("sudo", "pacman", "-S", "--noconfirm", "git")
		} else {
			fmt.Println("  ✗ 未找到支持的包管理器")
			fmt.Println("  请手动安装 Git")
		}
	}
}

// installNodeJS 安装 Node.js
func installNodeJS() {
	fmt.Println("▶ 安装 Node.js (LTS)...")

	switch runtime.GOOS {
	case "windows":
		// 尝试 winget
		if checkCommandExists("winget") {
			fmt.Println("  使用 winget 安装...")
			runInstallCommand("winget", "install", "--id", "OpenJS.NodeJS.LTS", "-e", "--source", "winget")
			return
		}
		// 尝试 scoop
		if checkCommandExists("scoop") {
			fmt.Println("  使用 scoop 安装...")
			runInstallCommand("scoop", "install", "nodejs-lts")
			return
		}
		// 尝试 chocolatey
		if checkCommandExists("choco") {
			fmt.Println("  使用 chocolatey 安装...")
			runInstallCommand("choco", "install", "nodejs-lts", "-y")
			return
		}
		// 提示手动安装
		fmt.Println("  ✗ 未找到包管理器")
		fmt.Println("  请手动下载安装: https://nodejs.org/")

	case "darwin":
		if checkCommandExists("brew") {
			fmt.Println("  使用 Homebrew 安装...")
			runInstallCommand("brew", "install", "node@20")
		} else {
			fmt.Println("  请先安装 Homebrew:")
			fmt.Println("  /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"")
		}

	case "linux":
		// 检测包管理器并安装
		if checkCommandExists("apt-get") {
			// Debian/Ubuntu: 使用 NodeSource
			fmt.Println("  使用 NodeSource 安装脚本 (Debian/Ubuntu)...")
			if checkCommandExists("curl") {
				cmd := exec.Command("bash", "-c", "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt-get install -y nodejs")
				cmd.Stdout = os.Stdout
				cmd.Stderr = os.Stderr
				if err := cmd.Run(); err != nil {
					fmt.Printf("  ✗ 安装失败: %v\n", err)
					fmt.Println("  请手动安装: https://nodejs.org/")
				}
			} else {
				fmt.Println("  ✗ 需要 curl")
				runInstallCommand("sudo", "apt-get", "install", "-y", "curl")
			}
		} else if checkCommandExists("dnf") {
			// Fedora/RHEL 8+
			fmt.Println("  使用 dnf 安装...")
			runInstallCommand("sudo", "dnf", "module", "install", "-y", "nodejs:20/common")
		} else if checkCommandExists("yum") {
			// CentOS/RHEL 7
			fmt.Println("  使用 NodeSource 安装脚本 (RHEL/CentOS)...")
			if checkCommandExists("curl") {
				cmd := exec.Command("bash", "-c", "curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash - && sudo yum install -y nodejs")
				cmd.Stdout = os.Stdout
				cmd.Stderr = os.Stderr
				cmd.Run()
			}
		} else if checkCommandExists("pacman") {
			// Arch Linux
			fmt.Println("  使用 pacman 安装...")
			runInstallCommand("sudo", "pacman", "-S", "--noconfirm", "nodejs", "npm")
		} else if checkCommandExists("zypper") {
			// openSUSE
			fmt.Println("  使用 zypper 安装...")
			runInstallCommand("sudo", "zypper", "install", "-y", "nodejs20")
		} else {
			fmt.Println("  ✗ 未找到支持的包管理器")
			fmt.Println("  请手动安装: https://nodejs.org/")
		}
	}
}

// installBun 安装 Bun
func installBun() {
	fmt.Println("▶ 安装 Bun (v1.3.5+)...")

	switch runtime.GOOS {
	case "windows":
		// Windows: 优先尝试包管理器，否则使用官方脚本
		if checkCommandExists("scoop") {
			fmt.Println("  使用 scoop 安装...")
			if err := runInstallCommand("scoop", "install", "bun"); err == nil {
				fmt.Println("  ✓ Bun 安装成功！")
				return
			}
		}

		// 使用 PowerShell 官方安装脚本
		fmt.Println("  使用官方安装脚本...")
		cmd := exec.Command("powershell", "-ExecutionPolicy", "Bypass", "-Command",
			"irm bun.sh/install.ps1 | iex")
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		cmd.Stdin = os.Stdin
		if err := cmd.Run(); err != nil {
			fmt.Printf("  ✗ 安装失败: %v\n", err)
			fmt.Println("")
			fmt.Println("  备选方案:")
			fmt.Println("    1. npm install -g bun")
			fmt.Println("    2. scoop install bun")
			fmt.Println("    3. 手动下载: https://bun.sh/docs/installation")
		} else {
			fmt.Println("  ✓ Bun 安装成功！")
			fmt.Println("  请重启终端使环境变量生效")
		}

	case "darwin":
		// macOS: 优先使用 Homebrew
		if checkCommandExists("brew") {
			fmt.Println("  使用 Homebrew 安装...")
			if err := runInstallCommand("brew", "install", "oven-sh/bun/bun"); err == nil {
				fmt.Println("  ✓ Bun 安装成功！")
				return
			}
		}
		// 备选：官方脚本
		fmt.Println("  使用官方安装脚本...")
		cmd := exec.Command("bash", "-c", "curl -fsSL https://bun.sh/install | bash")
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			fmt.Printf("  ✗ 安装失败: %v\n", err)
			fmt.Println("  请手动安装: https://bun.sh/docs/installation")
		} else {
			fmt.Println("  ✓ Bun 安装成功！")
		}

	case "linux":
		// Linux: 使用官方脚本
		fmt.Println("  使用官方安装脚本...")
		cmd := exec.Command("bash", "-c", "curl -fsSL https://bun.sh/install | bash")
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			fmt.Printf("  ✗ 安装失败: %v\n", err)
			fmt.Println("  请手动安装: https://bun.sh/docs/installation")
		} else {
			fmt.Println("  ✓ Bun 安装成功！")
		}
	}
}

// installNpmVersion 安装/更新 npm 到指定版本
func installNpmVersion() {
	fmt.Println("▶ npm 版本管理")
	fmt.Println("")

	// 检查 node/npm 是否存在
	if !checkCommandExists("npm") {
		fmt.Println("  ✗ npm 未安装。请先安装 Node.js。")
		return
	}

	currentVersion := getCommandVersion("npm", "--version")
	fmt.Printf("  当前 npm 版本: %s\n", currentVersion)
	fmt.Println("")
	fmt.Println("  推荐版本:")
	fmt.Println("    [1] npm@latest (最新版)")
	fmt.Println("    [2] npm@10 (Node 20+ 推荐)")
	fmt.Println("    [3] npm@9 (Node 18+ 稳定版)")
	fmt.Println("    [4] 自定义版本")
	fmt.Println("    [0] 返回")
	fmt.Println("")

	reader := bufio.NewReader(os.Stdin)
	fmt.Print("请选择 [0-4]: ")
	choice, _ := reader.ReadString('\n')
	choice = strings.TrimSpace(choice)

	var targetVersion string
	switch choice {
	case "1":
		targetVersion = "latest"
	case "2":
		targetVersion = "10"
	case "3":
		targetVersion = "9"
	case "4":
		fmt.Print("请输入目标版本 (如 10.2.0): ")
		ver, _ := reader.ReadString('\n')
		targetVersion = strings.TrimSpace(ver)
	case "0":
		return
	default:
		fmt.Println("无效选择")
		return
	}

	fmt.Printf("\n正在安装 npm@%s...\n", targetVersion)
	runInstallCommand("npm", "install", "-g", "npm@"+targetVersion)

	newVersion := getCommandVersion("npm", "--version")
	fmt.Printf("\n✓ npm 已更新: %s -> %s\n", currentVersion, newVersion)
}

// runInstallCommand 运行安装命令
func runInstallCommand(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	if err := cmd.Run(); err != nil {
		fmt.Printf("  ✗ 命令执行失败: %v\n", err)
		return err
	}
	return nil
}

// CheckSystemCompatibility 检查系统兼容性
func CheckSystemCompatibility() (bool, string) {
	platform := core.DetectPlatform()
	
	// 支持的平台列表
	supportedPlatforms := map[string]bool{
		"windows-x64":   true,
		"windows-arm64": true,
		"darwin-x64":    true,
		"darwin-arm64":  true,
		"linux-x64":     true,
		"linux-arm64":   true,
	}

	if !supportedPlatforms[platform] {
		return false, fmt.Sprintf("不支持的平台: %s", platform)
	}

	// 检查是否为 WSL
	if runtime.GOOS == "linux" {
		if _, err := os.Stat("/proc/sys/fs/binfmt_misc/WSLInterop"); err == nil {
			return true, fmt.Sprintf("%s (WSL)", platform)
		}
	}

	return true, platform
}
