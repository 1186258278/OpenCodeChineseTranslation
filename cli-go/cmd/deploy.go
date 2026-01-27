package cmd

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"opencode-cli/internal/core"

	"github.com/spf13/cobra"
)

var deployCmd = &cobra.Command{
	Use:   "deploy",
	Short: "部署到系统 PATH",
	Long:  "Deploy the compiled opencode binary to system PATH for global access",
	Run: func(cmd *cobra.Command, args []string) {
		createShortcut, _ := cmd.Flags().GetBool("shortcut")
		runDeploy(createShortcut)
	},
}

func init() {
	deployCmd.Flags().BoolP("shortcut", "s", false, "Create desktop shortcut")
	rootCmd.AddCommand(deployCmd)
}

func runDeploy(createShortcut bool) {
	fmt.Println("\n▶ 部署全局命令")

	binDir, err := core.GetBinDir()
	if err != nil {
		fmt.Printf("✗ 获取 bin 目录失败: %v\n", err)
		return
	}

	exeName := "opencode-cli"
	if runtime.GOOS == "windows" {
		if core.Exists(filepath.Join(binDir, "opencode-cli.exe")) {
			exeName = "opencode-cli.exe"
		} else {
			exeName = "opencode.exe"
		}
	} else {
		if core.Exists(filepath.Join(binDir, "opencode-cli")) {
			exeName = "opencode-cli"
		} else {
			exeName = "opencode"
		}
	}

	// 获取当前执行文件路径作为源文件
	// 修复：不再从 bin 目录查找，而是直接使用当前运行的程序
	// 这样可以确保部署的是当前这个新版本
	sourcePath, err := os.Executable()
	if err != nil {
		fmt.Printf("✗ 获取当前程序路径失败: %v\n", err)
		// 降级：尝试从 bin 目录获取
		binDir, err := core.GetBinDir()
		if err == nil {
			sourcePath = filepath.Join(binDir, exeName)
		}
	} else {
		// 解析符号链接（如果有）
		realSource, err := filepath.EvalSymlinks(sourcePath)
		if err == nil {
			sourcePath = realSource
		}
	}

	if !core.Exists(sourcePath) {
		fmt.Println("✗ 未找到 opencode-cli 编译产物")
		fmt.Println("")
		fmt.Println("  请选择一种方式获取:")
		fmt.Println("  1. 运行 'opencode-cli build'    (从源码编译)")
		fmt.Println("  2. 运行 'opencode-cli download' (下载官方预编译版)")
		return
	}

	// 获取部署目标目录
	// 策略变更：优先检测系统 PATH 中是否已存在 opencode-cli
	// 如果存在，直接覆盖该位置（原地升级），而不是盲目安装到默认目录
	// 这样可以兼容各种奇怪的安装路径 (npm, bun, scoop, choco, etc.)
	var deployDir string
	existingPath, err := exec.LookPath(exeName)
	if err == nil && existingPath != "" {
		// 解析符号链接，找到真实路径
		realPath, _ := filepath.EvalSymlinks(existingPath)
		if realPath != "" {
			deployDir = filepath.Dir(realPath)
			fmt.Printf("✓ 检测到已安装版本: %s\n", realPath)
			fmt.Println("  将在该位置进行原地升级...")
		}
	}

	// 如果未找到旧版本，或者解析失败，则使用默认推荐目录
	if deployDir == "" {
		deployDir, err = getDeployDir()
		if err != nil {
			fmt.Printf("✗ 获取部署目录失败: %v\n", err)
			return
		}
	}

	// 确保部署目录存在
	if err := os.MkdirAll(deployDir, 0755); err != nil {
		fmt.Printf("✗ 创建部署目录失败: %v\n", err)
		return
	}

	// 检查并添加 PATH
	addToPath(deployDir)

	// 部署 opencode-cli
	targetPath := filepath.Join(deployDir, exeName)
	if err := copyFileDeploy(sourcePath, targetPath); err != nil {
		fmt.Printf("✗ 部署 opencode-cli 失败: %v\n", err)
		return
	}

	// Windows: 强制清理可能存在的同名无后缀文件 (避免 "打开方式" 弹窗冲突)
	if runtime.GOOS == "windows" {
		noExtName := strings.TrimSuffix(exeName, filepath.Ext(exeName))
		noExtPath := filepath.Join(deployDir, noExtName)
		if core.Exists(noExtPath) {
			_ = os.Remove(noExtPath)
		}
	}

	// Windows 创建 CMD 包装器（如果是 opencode-cli.exe）
	if runtime.GOOS == "windows" && filepath.Ext(exeName) == ".exe" {
		cmdName := exeName[:len(exeName)-4]
		createCmdWrapper(deployDir, cmdName, exeName)
	}

	fmt.Printf("✓ 已部署 opencode-cli: %s\n", targetPath)

	if createShortcut {
		if runtime.GOOS == "windows" {
			createWindowsShortcut(targetPath)
		} else {
			createUnixShortcut(targetPath)
		}
	}

	// 尝试部署 opencode (软件本身)
	opencodeExeName := "opencode"
	if runtime.GOOS == "windows" {
		opencodeExeName = "opencode.exe"
	}
	opencodeSource := filepath.Join(binDir, opencodeExeName)

	if core.Exists(opencodeSource) {
		fmt.Println("\n▶ 部署 OpenCode 软件命令")

		checkRunningProcess(opencodeExeName)

		appTargetPath := filepath.Join(deployDir, opencodeExeName)
		if err := copyFileDeploy(opencodeSource, appTargetPath); err != nil {
			fmt.Printf("✗ 部署 OpenCode 失败: %v\n", err)
		} else {
			fmt.Printf("✓ 已部署 opencode: %s\n", appTargetPath)

			// Windows: 强制清理可能存在的同名无后缀文件 (避免 "打开方式" 弹窗冲突)
			if runtime.GOOS == "windows" {
				noExtOpencode := filepath.Join(deployDir, "opencode")
				if core.Exists(noExtOpencode) {
					_ = os.Remove(noExtOpencode)
				}
			}

			// Windows 创建 CMD 包装器
			if runtime.GOOS == "windows" {
				createCmdWrapper(deployDir, "opencode", opencodeExeName)
			}

			// 检查并自动清理 PATH 冲突 (V3: Global Scan & Destroy)
			checkPathPriority("opencode", appTargetPath)
		}
	} else {
		fmt.Println("\n提示: 未找到编译好的 OpenCode 软件 (bin/opencode)，跳过部署 'opencode' 命令。")
		fmt.Println("      如需启用 'opencode' 全局命令，请先运行 build。")
	}

	fmt.Println("")
	fmt.Println("部署完成！")
	fmt.Printf("  部署位置: %s\n", deployDir)
}

// getDeployDir 获取部署目录
// 三端统一使用 ~/.opencode-i18n/bin，与安装脚本保持一致
func getDeployDir() (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}

	// 统一目录：~/.opencode-i18n/bin
	// Windows: %USERPROFILE%\.opencode-i18n\bin
	// macOS/Linux: ~/.opencode-i18n/bin
	return filepath.Join(homeDir, ".opencode-i18n", "bin"), nil
}

// addToPath 检查并提示/自动添加 PATH
func addToPath(dir string) {
	// 在 Windows 上，我们需要检查 User PATH，而不仅仅是 os.Getenv("PATH") (它包含 System + User)
	if runtime.GOOS == "windows" {
		// 获取当前的 User PATH
		cmd := exec.Command("powershell", "-NoProfile", "-Command", `[Environment]::GetEnvironmentVariable("Path", "User")`)
		output, err := cmd.Output()
		if err == nil {
			userPath := strings.TrimSpace(string(output))
			// 如果 User PATH 中已经包含了该目录，就不再添加
			// 注意：这里简单的字符串检查可能不够精确，但通常足够，且避免重复添加
			if strings.Contains(strings.ToLower(userPath), strings.ToLower(dir)) {
				// 虽然在 User PATH 中，但可能不在当前 Session PATH 中 (需要重启终端)
				if !containsPath(os.Getenv("PATH"), dir) {
					fmt.Printf("\n提示: 部署目录已在用户 PATH 中，但未在当前终端生效。\n")
					fmt.Printf("      请尝试重启终端或注销/登录。\n")
				}
				return
			}
		}
	} else {
		// Unix: 检查当前 PATH
		pathVar := os.Getenv("PATH")
		if containsPath(pathVar, dir) {
			return
		}
	}

	fmt.Printf("\n提示: 部署目录不在 PATH 环境变量中\n")
	fmt.Printf("      %s\n", dir)

	if runtime.GOOS == "windows" {
		// 尝试自动添加 PATH (Windows)
		fmt.Println("正在尝试自动添加到用户环境变量...")

		// 使用 PowerShell 添加 PATH (PREPEND - 插入到最前面)
		// 这样可以确保我们的命令优先级高于 npm 全局安装的版本
		psCommand := fmt.Sprintf(
			`$currentPath = [Environment]::GetEnvironmentVariable("Path", "User"); if (-not $currentPath.ToLower().Contains("%s".ToLower())) { [Environment]::SetEnvironmentVariable("Path", "%s;" + $currentPath, "User") }`,
			dir, dir,
		)

		cmd := exec.Command("powershell", "-NoProfile", "-Command", psCommand)
		if err := cmd.Run(); err != nil {
			fmt.Printf("✗ 自动添加失败: %v\n", err)
			fmt.Println("请手动将该目录添加到系统 PATH 环境变量的前部")
		} else {
			fmt.Println("✓ 已将部署目录添加到用户 PATH (最高优先级)")
			fmt.Println("注意: 您需要重启终端才能生效")
		}
	} else {
		// Unix 提示
		fmt.Println("请将以下行添加到您的 shell 配置文件中 (~/.bashrc, ~/.zshrc 等):")
		fmt.Printf("export PATH=\"%s:$PATH\"\n", dir)
	}
	fmt.Println("")
}

// createCmdWrapper 创建 Windows CMD 包装器
func createCmdWrapper(dir, cmdName, targetName string) {
	cmdPath := filepath.Join(dir, cmdName+".cmd")
	cmdContent := fmt.Sprintf(`@echo off
"%%~dp0%s" %%*
`, targetName)
	_ = os.WriteFile(cmdPath, []byte(cmdContent), 0644)
}

func createWindowsShortcut(targetPath string) {
	fmt.Println("正在创建桌面快捷方式...")
	homeDir, _ := os.UserHomeDir()
	desktopPath := filepath.Join(homeDir, "Desktop", "OpenCode CLI.lnk")

	script := fmt.Sprintf(`
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("%s")
$Shortcut.TargetPath = "%s"
$Shortcut.Description = "OpenCode 汉化管理工具"
$Shortcut.Save()`, desktopPath, targetPath)

	cmd := core.ExecLive("powershell", "-Command", script)
	if cmd != nil {
		fmt.Printf("✗ 创建快捷方式失败: %v\n", cmd)
	} else {
		fmt.Printf("✓ 已创建快捷方式: %s\n", desktopPath)
	}
}

func createUnixShortcut(targetPath string) {
	fmt.Println("正在创建桌面启动器...")
	homeDir, _ := os.UserHomeDir()
	desktopPath := filepath.Join(homeDir, "Desktop", "OpenCode CLI.command")

	content := fmt.Sprintf(`#!/bin/bash
"%s" interactive
`, targetPath) // 默认进入交互模式

	if err := os.WriteFile(desktopPath, []byte(content), 0755); err != nil {
		fmt.Printf("✗ 创建启动器失败: %v\n", err)
	} else {
		fmt.Printf("✓ 已创建启动器: %s\n", desktopPath)
	}

	// 尝试创建 Linux .desktop 文件
	if runtime.GOOS == "linux" {
		createLinuxDesktopFile(targetPath)
	}
}

func createLinuxDesktopFile(targetPath string) {
	homeDir, _ := os.UserHomeDir()
	appsDir := filepath.Join(homeDir, ".local", "share", "applications")

	// 如果目录不存在，尝试创建
	if !core.DirExists(appsDir) {
		_ = os.MkdirAll(appsDir, 0755)
	}

	if core.DirExists(appsDir) {
		desktopFile := filepath.Join(appsDir, "opencode-cli.desktop")
		content := fmt.Sprintf(`[Desktop Entry]
Type=Application
Name=OpenCode CLI
Comment=OpenCode 汉化管理工具
Exec="%s" interactive
Terminal=true
Categories=Development;
`, targetPath)

		if err := os.WriteFile(desktopFile, []byte(content), 0644); err == nil {
			fmt.Printf("✓ 已创建 Linux 菜单快捷方式: %s\n", desktopFile)
		}
	}
}

// copyFileDeploy 复制文件
func copyFileDeploy(src, dst string) error {
	// Windows 特殊处理：如果目标存在且被占用，尝试重命名
	if runtime.GOOS == "windows" {
		if _, err := os.Stat(dst); err == nil {
			// 使用时间戳防止冲突
			timestamp := time.Now().Format("20060102150405")
			oldFile := fmt.Sprintf("%s.old.%s", dst, timestamp)

			// 尝试清理旧的 .old 文件
			os.Remove(dst + ".old")

			// 重命名当前文件
			if err := os.Rename(dst, oldFile); err != nil {
				// 仅记录警告，继续尝试直接覆盖（也许没被占用呢）
				// fmt.Printf("警告: 无法重命名旧文件: %v\n", err)
			}
		}
	}

	// 如果目标文件存在，先删除
	if core.Exists(dst) {
		if err := os.Remove(dst); err != nil {
			return fmt.Errorf("删除旧文件失败（可能正在使用中）: %v", err)
		}
	}

	sourceFile, err := os.Open(src)
	if err != nil {
		return err
	}
	defer sourceFile.Close()

	destFile, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer destFile.Close()

	_, err = io.Copy(destFile, sourceFile)
	return err
}

// containsPath 检查 PATH 是否包含指定目录
func containsPath(pathVar, dir string) bool {
	separator := ":"
	if runtime.GOOS == "windows" {
		separator = ";"
	}

	paths := filepath.SplitList(pathVar)
	// 标准化路径比较
	cleanDir := filepath.Clean(strings.ToLower(dir))

	for _, p := range paths {
		if filepath.Clean(strings.ToLower(p)) == cleanDir {
			return true
		}
	}
	_ = separator
	return false
}

// checkRunningProcess 检查进程是否运行
func checkRunningProcess(name string) {
	// 简单的进程检查 (需要 ps 或 tasklist)
	var cmd *exec.Cmd
	if runtime.GOOS == "windows" {
		cmd = exec.Command("tasklist", "/FI", fmt.Sprintf("IMAGENAME eq %s", name))
	} else {
		cmd = exec.Command("pgrep", "-f", name)
	}

	output, _ := cmd.CombinedOutput()
	outputStr := string(output)

	// Windows tasklist 输出包含进程名即为存在
	// Unix pgrep 输出 PID 即为存在
	isRunning := false
	if runtime.GOOS == "windows" {
		if strings.Contains(outputStr, name) {
			isRunning = true
		}
	} else {
		if len(strings.TrimSpace(outputStr)) > 0 {
			isRunning = true
		}
	}

	if isRunning {
		fmt.Printf("\n⚠️  警告: 检测到 %s 正在运行！\n", name)
		fmt.Println("   请立即关闭相关程序，否则文件替换可能会失败。")
		fmt.Println("   按回车键继续部署，或按 Ctrl+C 取消...")
		fmt.Scanln()
	}
}

// checkPathPriority 检查 PATH 优先级并执行全局清理
func checkPathPriority(cmdName, deployedPath string) {
	fmt.Println("\n▶ 执行环境冲突扫描...")

	pathVar := os.Getenv("PATH")
	paths := filepath.SplitList(pathVar)

	// 我们要找的目标文件名
	targets := []string{"opencode", "opencode.cmd", "opencode.ps1", "opencode.exe", "opencode-cli", "opencode-cli.cmd", "opencode-cli.exe"}

	cleanedCount := 0

	for _, dir := range paths {
		// 跳过我们自己的部署目录
		if strings.EqualFold(filepath.Clean(dir), filepath.Clean(filepath.Dir(deployedPath))) {
			continue
		}

		for _, target := range targets {
			fullPath := filepath.Join(dir, target)
			if core.Exists(fullPath) {
				fmt.Printf("🔍 发现冲突文件: %s\n", fullPath)

				// 尝试删除
				err := os.Remove(fullPath)
				if err == nil {
					fmt.Printf("   ✓ 已删除\n")
					cleanedCount++
				} else {
					// 尝试重命名后删除
					tempName := fullPath + ".old"
					os.Rename(fullPath, tempName)
					if err := os.Remove(tempName); err == nil {
						fmt.Printf("   ✓ 已删除 (重命名方式)\n")
						cleanedCount++
					} else {
						fmt.Printf("   ✗ 删除失败: %v\n", err)
						fmt.Println("   👉 请手动删除此文件！")
					}
				}
			}
		}
	}

	if cleanedCount > 0 {
		fmt.Printf("\n✓ 已清理 %d 个冲突文件。环境现在应该是纯净的。\n", cleanedCount)
	} else {
		fmt.Println("✓ 未发现其他冲突文件。")
	}
}
