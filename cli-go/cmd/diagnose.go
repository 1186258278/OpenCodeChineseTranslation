package cmd

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"

	"github.com/spf13/cobra"
)

var diagnoseCmd = &cobra.Command{
	Use:   "diagnose",
	Short: "诊断并修复常见问题",
	Long: `自动检测并修复常见问题，包括：
  - 多版本 opencode 冲突
  - PATH 环境变量问题
  - macOS 签名问题
  - 编译环境缺失`,
	Run: func(cmd *cobra.Command, args []string) {
		fix, _ := cmd.Flags().GetBool("fix")
		runDiagnose(fix)
	},
}

func init() {
	rootCmd.AddCommand(diagnoseCmd)
	diagnoseCmd.Flags().Bool("fix", false, "自动修复发现的问题")
}

// DiagnoseIssue 诊断问题
type DiagnoseIssue struct {
	ID          string
	Name        string
	Description string
	Severity    string // "error", "warning", "info"
	FixFunc     func() error
	FixDesc     string
}

func runDiagnose(autoFix bool) {
	fmt.Println("╔══════════════════════════════════════════╗")
	fmt.Println("║      OpenCode 问题诊断与修复工具        ║")
	fmt.Println("╚══════════════════════════════════════════╝")
	fmt.Println()

	var issues []DiagnoseIssue

	// 1. 检测多版本冲突
	fmt.Print("检测 opencode 版本冲突... ")
	conflictIssues := checkOpencodeConflicts()
	issues = append(issues, conflictIssues...)
	if len(conflictIssues) > 0 {
		fmt.Println("发现问题")
	} else {
		fmt.Println("✓")
	}

	// 2. 检测编译环境
	fmt.Print("检测编译环境... ")
	envIssues := checkBuildEnvironment()
	issues = append(issues, envIssues...)
	if len(envIssues) > 0 {
		fmt.Println("发现问题")
	} else {
		fmt.Println("✓")
	}

	// 3. macOS 签名问题检测
	if runtime.GOOS == "darwin" {
		fmt.Print("检测 macOS 签名问题... ")
		macIssues := checkMacOSSignature()
		issues = append(issues, macIssues...)
		if len(macIssues) > 0 {
			fmt.Println("发现问题")
		} else {
			fmt.Println("✓")
		}
	}

	// 4. PATH 配置检测
	fmt.Print("检测 PATH 配置... ")
	pathIssues := checkPathConfiguration()
	issues = append(issues, pathIssues...)
	if len(pathIssues) > 0 {
		fmt.Println("发现问题")
	} else {
		fmt.Println("✓")
	}

	fmt.Println()

	if len(issues) == 0 {
		fmt.Println("════════════════════════════════════════════")
		fmt.Println("✓ 未发现问题，系统状态良好！")
		return
	}

	// 显示问题列表
	fmt.Println("════════════════════════════════════════════")
	fmt.Printf("发现 %d 个问题：\n\n", len(issues))

	for i, issue := range issues {
		icon := "⚠"
		if issue.Severity == "error" {
			icon = "✗"
		} else if issue.Severity == "info" {
			icon = "ℹ"
		}

		fmt.Printf("%d. [%s] %s\n", i+1, icon, issue.Name)
		fmt.Printf("   %s\n", issue.Description)
		if issue.FixDesc != "" {
			fmt.Printf("   修复方案: %s\n", issue.FixDesc)
		}
		fmt.Println()
	}

	// 询问是否修复
	fixableCount := 0
	for _, issue := range issues {
		if issue.FixFunc != nil {
			fixableCount++
		}
	}

	if fixableCount == 0 {
		fmt.Println("以上问题需要手动处理，请参考修复方案。")
		return
	}

	if !autoFix {
		fmt.Printf("其中 %d 个问题可自动修复。是否修复？[y/N]: ", fixableCount)
		reader := bufio.NewReader(os.Stdin)
		input, _ := reader.ReadString('\n')
		input = strings.TrimSpace(strings.ToLower(input))

		if input != "y" && input != "yes" {
			fmt.Println("\n已跳过修复。可使用 --fix 参数自动修复。")
			return
		}
	}

	// 执行修复
	fmt.Println("\n开始修复...")
	fmt.Println()

	successCount := 0
	for _, issue := range issues {
		if issue.FixFunc == nil {
			continue
		}

		fmt.Printf("修复: %s... ", issue.Name)
		if err := issue.FixFunc(); err != nil {
			fmt.Printf("失败: %v\n", err)
		} else {
			fmt.Println("✓")
			successCount++
		}
	}

	fmt.Println()
	fmt.Println("════════════════════════════════════════════")
	fmt.Printf("修复完成: %d/%d\n", successCount, fixableCount)
	if successCount > 0 {
		fmt.Println("\n请重启终端使更改生效。")
	}
}

// checkOpencodeConflicts 检测多版本冲突
func checkOpencodeConflicts() []DiagnoseIssue {
	var issues []DiagnoseIssue
	homeDir, _ := os.UserHomeDir()
	expectedDir := filepath.Join(homeDir, ".opencode-i18n", "bin")

	// 查找所有 opencode 相关可执行文件（详细信息）
	locations := findAllOpencodeDetailed()

	// 分析冲突情况
	var oldVersions []OpencodeLocation
	var expectedVersion OpencodeLocation
	versionMap := make(map[string][]OpencodeLocation)

	for _, loc := range locations {
		// 按版本分组
		versionMap[loc.Version] = append(versionMap[loc.Version], loc)

		// 检查是否在预期目录
		if strings.HasPrefix(loc.Path, expectedDir) {
			expectedVersion = loc
		} else if loc.Type == "opencode-cli" {
			// 非预期目录的 opencode-cli 是冲突
			oldVersions = append(oldVersions, loc)
		}
	}

	// 检测多个 opencode-cli 安装
	if len(oldVersions) > 0 {
		desc := "发现非统一目录的 opencode-cli 安装:\n"
		for _, loc := range oldVersions {
			inPathStr := ""
			if loc.InPath {
				inPathStr = " [在 PATH 中]"
			}
			desc += fmt.Sprintf("      - %s (v%s)%s\n", loc.Path, loc.Version, inPathStr)
		}
		if expectedVersion.Path != "" {
			desc += fmt.Sprintf("      统一目录版本: %s (v%s)\n", expectedVersion.Path, expectedVersion.Version)
		}

		issues = append(issues, DiagnoseIssue{
			ID:          "multi-cli-install",
			Name:        "多处 opencode-cli 安装",
			Description: desc,
			Severity:    "error",
			FixFunc: func() error {
				return cleanConflictingCLI(oldVersions, expectedDir)
			},
			FixDesc: "清理旧安装，保留统一目录版本",
		})
	}

	// 检测版本不一致
	if len(versionMap) > 1 {
		desc := "发现多个不同版本的 opencode-cli:\n"
		for version, locs := range versionMap {
			desc += fmt.Sprintf("      v%s:\n", version)
			for _, loc := range locs {
				desc += fmt.Sprintf("        - %s\n", loc.Path)
			}
		}

		// 如果上面没有添加多安装问题，这里添加版本冲突问题
		if len(oldVersions) == 0 {
			issues = append(issues, DiagnoseIssue{
				ID:          "version-mismatch",
				Name:        "版本不一致",
				Description: desc,
				Severity:    "warning",
				FixDesc:     "建议运行 opencode-cli deploy 更新到统一版本",
			})
		}
	}

	// 检测 npm 全局安装的 opencode
	npmGlobalPath := getNpmGlobalPath()
	if npmGlobalPath != "" {
		npmOpencode := filepath.Join(npmGlobalPath, "opencode")
		npmOpencodeCmd := filepath.Join(npmGlobalPath, "opencode.cmd")
		if runtime.GOOS == "windows" {
			npmOpencode = npmOpencodeCmd
		}
		if fileExists(npmOpencode) || fileExists(npmOpencodeCmd) {
			issues = append(issues, DiagnoseIssue{
				ID:          "npm-opencode",
				Name:        "npm 全局安装的 opencode",
				Description: fmt.Sprintf("位置: %s\n      可能与汉化版冲突", npmGlobalPath),
				Severity:    "warning",
				FixFunc: func() error {
					cmd := exec.Command("npm", "uninstall", "-g", "opencode")
					return cmd.Run()
				},
				FixDesc: "运行 npm uninstall -g opencode",
			})
		}
	}

	return issues
}

// cleanConflictingCLI 清理冲突的 opencode-cli 安装
func cleanConflictingCLI(oldVersions []OpencodeLocation, expectedDir string) error {
	for _, loc := range oldVersions {
		// 跳过预期目录
		if strings.HasPrefix(loc.Path, expectedDir) {
			continue
		}

		fmt.Printf("  清理: %s (v%s)\n", loc.Path, loc.Version)

		// 尝试删除
		if err := os.Remove(loc.Path); err != nil {
			// 尝试重命名备份
			backupPath := loc.Path + ".bak"
			if err := os.Rename(loc.Path, backupPath); err != nil {
				fmt.Printf("    警告: 无法清理 %s: %v\n", loc.Path, err)
			} else {
				fmt.Printf("    已备份为: %s\n", backupPath)
			}
		}
	}

	return nil
}

// checkBuildEnvironment 检测编译环境
func checkBuildEnvironment() []DiagnoseIssue {
	var issues []DiagnoseIssue

	// Git
	if _, err := exec.LookPath("git"); err != nil {
		issues = append(issues, DiagnoseIssue{
			ID:          "missing-git",
			Name:        "未安装 Git",
			Description: "编译和更新源码需要 Git",
			Severity:    "warning",
			FixDesc:     "运行 opencode-cli env-install 安装",
		})
	}

	// Node.js
	if _, err := exec.LookPath("node"); err != nil {
		issues = append(issues, DiagnoseIssue{
			ID:          "missing-node",
			Name:        "未安装 Node.js",
			Description: "编译 OpenCode 需要 Node.js 18+",
			Severity:    "warning",
			FixDesc:     "运行 opencode-cli env-install 安装",
		})
	}

	// Bun
	if _, err := exec.LookPath("bun"); err != nil {
		issues = append(issues, DiagnoseIssue{
			ID:          "missing-bun",
			Name:        "未安装 Bun",
			Description: "编译 OpenCode 需要 Bun 构建工具",
			Severity:    "warning",
			FixDesc:     "运行 opencode-cli env-install 安装",
		})
	}

	return issues
}

// checkMacOSSignature 检测 macOS 签名问题
func checkMacOSSignature() []DiagnoseIssue {
	var issues []DiagnoseIssue

	// 检查 opencode 是否有 quarantine 属性
	opencodeLocations := findAllOpencode()
	for _, loc := range opencodeLocations {
		cmd := exec.Command("xattr", "-l", loc)
		output, _ := cmd.Output()
		if strings.Contains(string(output), "com.apple.quarantine") {
			issues = append(issues, DiagnoseIssue{
				ID:          "macos-quarantine",
				Name:        "macOS 隔离属性",
				Description: fmt.Sprintf("文件被标记为不受信任: %s", loc),
				Severity:    "error",
				FixFunc: func() error {
					cmd := exec.Command("xattr", "-cr", loc)
					return cmd.Run()
				},
				FixDesc: fmt.Sprintf("运行 xattr -cr %s", loc),
			})
		}
	}

	return issues
}

// checkPathConfiguration 检测 PATH 配置
func checkPathConfiguration() []DiagnoseIssue {
	var issues []DiagnoseIssue
	homeDir, _ := os.UserHomeDir()
	expectedDir := filepath.Join(homeDir, ".opencode-i18n", "bin")

	// 检查汉化版 CLI 是否在 PATH 中
	cliPath, err := exec.LookPath("opencode-cli")
	if err != nil {
		// 检查文件是否存在但不在 PATH 中
		cliExe := "opencode-cli"
		if runtime.GOOS == "windows" {
			cliExe = "opencode-cli.exe"
		}
		expectedCli := filepath.Join(expectedDir, cliExe)
		if fileExists(expectedCli) {
			expectedDirCopy := expectedDir // 复制到局部变量避免闭包问题
			issues = append(issues, DiagnoseIssue{
				ID:          "cli-not-in-path",
				Name:        "opencode-cli 不在 PATH 中",
				Description: fmt.Sprintf("CLI 已安装: %s\n      但未加入 PATH 环境变量", expectedCli),
				Severity:    "error",
				FixFunc: func() error {
					return addDirToPath(expectedDirCopy)
				},
				FixDesc: "添加统一目录到 PATH 并置顶",
			})
		} else {
			issues = append(issues, DiagnoseIssue{
				ID:          "cli-not-installed",
				Name:        "opencode-cli 未安装",
				Description: "未找到 opencode-cli，请运行安装脚本",
				Severity:    "error",
				FixDesc:     "运行安装脚本或手动部署",
			})
		}
	} else {
		// 检查是否是预期的路径 (统一目录: ~/.opencode-i18n/bin)
		if !strings.HasPrefix(cliPath, expectedDir) {
			issues = append(issues, DiagnoseIssue{
				ID:          "cli-unexpected-path",
				Name:        "opencode-cli 位置异常",
				Description: fmt.Sprintf("当前使用: %s\n      预期目录: %s", cliPath, expectedDir),
				Severity:    "warning",
				FixDesc:     "如果是开发环境可忽略，否则运行 diagnose --fix",
			})
		}
	}

	// 检测 PATH 中的重复项
	pathEnv := os.Getenv("PATH")
	pathDirs := strings.Split(pathEnv, string(os.PathListSeparator))
	seen := make(map[string]int)
	var duplicates []string

	for _, dir := range pathDirs {
		normalizedDir := strings.ToLower(filepath.Clean(dir))
		seen[normalizedDir]++
		if seen[normalizedDir] == 2 {
			duplicates = append(duplicates, dir)
		}
	}

	if len(duplicates) > 0 {
		desc := "PATH 中存在重复目录:\n"
		for _, d := range duplicates {
			desc += fmt.Sprintf("      - %s (出现 %d 次)\n", d, seen[strings.ToLower(filepath.Clean(d))])
		}
		issues = append(issues, DiagnoseIssue{
			ID:          "path-duplicates",
			Name:        "PATH 包含重复项",
			Description: desc,
			Severity:    "info",
			FixFunc: func() error {
				return cleanPathDuplicates()
			},
			FixDesc: "清理重复项并优化 PATH 顺序",
		})
	}

	// 检测统一目录是否在 PATH 前面
	expectedDirIdx := -1
	otherOpencodeIdx := -1
	for i, dir := range pathDirs {
		normalizedDir := strings.ToLower(filepath.Clean(dir))
		expectedNorm := strings.ToLower(filepath.Clean(expectedDir))
		if normalizedDir == expectedNorm {
			expectedDirIdx = i
		} else if strings.Contains(strings.ToLower(dir), "opencode") {
			if otherOpencodeIdx == -1 {
				otherOpencodeIdx = i
			}
		}
	}

	if expectedDirIdx > 0 && (otherOpencodeIdx >= 0 && otherOpencodeIdx < expectedDirIdx) {
		issues = append(issues, DiagnoseIssue{
			ID:          "path-priority",
			Name:        "PATH 优先级问题",
			Description: fmt.Sprintf("统一目录排在第 %d 位，但其他 opencode 目录在第 %d 位\n      这会导致系统优先使用旧版本", expectedDirIdx+1, otherOpencodeIdx+1),
			Severity:    "error",
			FixFunc: func() error {
				return optimizePathPriority(expectedDir)
			},
			FixDesc: "调整 PATH 顺序，将统一目录置顶",
		})
	}

	return issues
}

// addDirToPath 添加目录到 PATH (诊断模块专用)
func addDirToPath(dir string) error {
	if runtime.GOOS == "windows" {
		// Windows: 修改用户级 PATH
		cmd := exec.Command("powershell", "-Command", fmt.Sprintf(`
			$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
			$newPath = "%s;" + $currentPath
			[Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
		`, dir))
		return cmd.Run()
	} else {
		// Unix: 提示用户手动添加
		shell := os.Getenv("SHELL")
		rcFile := "~/.bashrc"
		if strings.Contains(shell, "zsh") {
			rcFile = "~/.zshrc"
		}
		fmt.Printf("请手动添加以下内容到 %s:\n", rcFile)
		fmt.Printf("  export PATH=\"%s:$PATH\"\n", dir)
		return nil
	}
}

// cleanPathDuplicates 清理 PATH 中的重复项
func cleanPathDuplicates() error {
	if runtime.GOOS == "windows" {
		cmd := exec.Command("powershell", "-Command", `
			$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
			$items = $userPath -split ';' | Where-Object { $_ -ne '' } | Select-Object -Unique
			$newPath = $items -join ';'
			[Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
			Write-Host "已清理 PATH 重复项"
		`)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		return cmd.Run()
	}
	return fmt.Errorf("请手动清理 PATH 重复项")
}

// optimizePathPriority 优化 PATH 顺序，将统一目录置顶
func optimizePathPriority(expectedDir string) error {
	if runtime.GOOS == "windows" {
		cmd := exec.Command("powershell", "-Command", fmt.Sprintf(`
			$targetDir = "%s"
			$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
			$items = $userPath -split ';' | Where-Object { $_ -ne '' } | Select-Object -Unique

			# 移除目标目录（如果存在）
			$items = $items | Where-Object { $_.ToLower() -ne $targetDir.ToLower() }

			# 将目标目录添加到最前面
			$items = @($targetDir) + $items
			$newPath = $items -join ';'
			[Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
			Write-Host "已将 $targetDir 置于 PATH 最前面"
		`, expectedDir))
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		return cmd.Run()
	}

	// Unix: 提示用户
	fmt.Printf("请确保 %s 在 PATH 最前面\n", expectedDir)
	return nil
}

// OpencodeLocation 记录 opencode 安装位置信息
type OpencodeLocation struct {
	Path    string
	Version string
	Type    string // "opencode-cli" or "opencode"
	InPath  bool
}

// findAllOpencode 查找所有 opencode 可执行文件
func findAllOpencode() []string {
	locations := findAllOpencodeDetailed()
	var paths []string
	for _, loc := range locations {
		paths = append(paths, loc.Path)
	}
	return paths
}

// findAllOpencodeDetailed 查找所有 opencode 相关可执行文件（详细信息）
func findAllOpencodeDetailed() []OpencodeLocation {
	var locations []OpencodeLocation
	seen := make(map[string]bool)

	homeDir, _ := os.UserHomeDir()
	pathEnv := os.Getenv("PATH")
	pathDirs := strings.Split(pathEnv, string(os.PathListSeparator))

	// 要搜索的可执行文件名
	exeNames := []string{"opencode-cli", "opencode"}
	if runtime.GOOS == "windows" {
		exeNames = []string{"opencode-cli.exe", "opencode.exe", "opencode-cli.cmd", "opencode.cmd"}
	}

	// 1. 搜索 PATH 中的所有目录
	for _, dir := range pathDirs {
		if dir == "" {
			continue
		}
		for _, exeName := range exeNames {
			fullPath := filepath.Join(dir, exeName)
			if fileExists(fullPath) && !seen[fullPath] {
				seen[fullPath] = true
				loc := OpencodeLocation{
					Path:   fullPath,
					Type:   strings.TrimSuffix(strings.TrimSuffix(exeName, ".exe"), ".cmd"),
					InPath: true,
				}
				// 获取版本
				if version := getExecutableVersion(fullPath); version != "" {
					loc.Version = version
				}
				locations = append(locations, loc)
			}
		}
	}

	// 2. 检查常见安装位置
	var commonPaths []string
	if runtime.GOOS == "windows" {
		localAppData := os.Getenv("LOCALAPPDATA")
		appData := os.Getenv("APPDATA")
		commonPaths = []string{
			filepath.Join(localAppData, "OpenCode", "bin"),
			filepath.Join(homeDir, ".opencode-i18n", "bin"),
			filepath.Join(appData, "npm"),
			filepath.Join(homeDir, ".bun", "bin"),
			filepath.Join(homeDir, "scoop", "shims"),
		}
	} else {
		commonPaths = []string{
			filepath.Join(homeDir, ".local", "bin"),
			filepath.Join(homeDir, ".opencode-i18n", "bin"),
			"/usr/local/bin",
			filepath.Join(homeDir, ".bun", "bin"),
		}
	}

	for _, dir := range commonPaths {
		if !fileExists(dir) {
			continue
		}
		for _, exeName := range exeNames {
			fullPath := filepath.Join(dir, exeName)
			if fileExists(fullPath) && !seen[fullPath] {
				seen[fullPath] = true
				inPath := false
				for _, pd := range pathDirs {
					if pd == dir {
						inPath = true
						break
					}
				}
				loc := OpencodeLocation{
					Path:   fullPath,
					Type:   strings.TrimSuffix(strings.TrimSuffix(exeName, ".exe"), ".cmd"),
					InPath: inPath,
				}
				if version := getExecutableVersion(fullPath); version != "" {
					loc.Version = version
				}
				locations = append(locations, loc)
			}
		}
	}

	return locations
}

// getExecutableVersion 获取可执行文件的版本
func getExecutableVersion(path string) string {
	cmd := exec.Command(path, "--version")
	output, err := cmd.Output()
	if err != nil {
		return ""
	}
	// 解析版本号，通常格式为 "opencode-cli version X.X.X"
	line := strings.TrimSpace(string(output))
	if strings.Contains(line, "version") {
		parts := strings.Fields(line)
		if len(parts) >= 3 {
			return parts[len(parts)-1]
		}
	}
	return line
}

// cleanConflictingOpencode 清理冲突的 opencode（兼容旧接口）
func cleanConflictingOpencode(locations []string) error {
	// 确定要保留的版本（汉化版）- 统一目录
	homeDir, _ := os.UserHomeDir()
	keepPath := filepath.Join(homeDir, ".opencode-i18n", "bin")

	for _, loc := range locations {
		// 保留汉化版目录下的
		if strings.HasPrefix(loc, keepPath) || strings.Contains(loc, ".opencode-i18n") {
			continue
		}

		// 尝试删除或重命名
		fmt.Printf("  清理: %s\n", loc)
		if err := os.Remove(loc); err != nil {
			// 尝试重命名备份
			if err := os.Rename(loc, loc+".bak"); err != nil {
				fmt.Printf("    警告: 无法清理 %s: %v\n", loc, err)
			}
		}
	}

	return nil
}

// getNpmGlobalPath 获取 npm 全局安装路径
func getNpmGlobalPath() string {
	cmd := exec.Command("npm", "root", "-g")
	output, err := cmd.Output()
	if err != nil {
		return ""
	}
	// npm root -g 返回 node_modules 目录，我们需要上一级的 bin
	npmRoot := strings.TrimSpace(string(output))
	return filepath.Dir(npmRoot)
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
