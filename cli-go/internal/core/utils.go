package core

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

// GetProjectDir 获取项目根目录
// 通过查找 cli-go 目录或 opencode-zh-CN 目录来定位
func GetProjectDir() (string, error) {
	// 1. 尝试环境变量 OPENCODE_PROJECT_DIR
	if envDir := os.Getenv("OPENCODE_PROJECT_DIR"); envDir != "" {
		if isProjectRoot(envDir) {
			return envDir, nil
		}
	}

	// 2. 尝试从当前工作目录向上查找
	wd, err := os.Getwd()
	if err == nil {
		if found := findProjectRoot(wd); found != "" {
			return found, nil
		}
	}

	// 3. 尝试从可执行文件目录向上查找
	exePath, err := os.Executable()
	if err == nil {
		exeDir := filepath.Dir(exePath)
		if found := findProjectRoot(exeDir); found != "" {
			return found, nil
		}
	}

	// 4. 如果当前在 cli-go 目录下，父目录就是项目根目录
	if wd, err := os.Getwd(); err == nil {
		if strings.HasSuffix(wd, "cli-go") {
			parent := filepath.Dir(wd)
			return parent, nil
		}
	}

	// 5. 返回当前工作目录作为默认值（CI 环境中通常就是项目根目录）
	if wd, err := os.Getwd(); err == nil {
		return wd, nil
	}

	return "", fmt.Errorf("project root not found")
}

// isProjectRoot 检查目录是否为项目根目录
func isProjectRoot(dir string) bool {
	// 检查是否存在 cli-go 目录（开发环境）
	if _, err := os.Stat(filepath.Join(dir, "cli-go")); err == nil {
		return true
	}
	// 检查是否存在 opencode-zh-CN 目录（CI 环境）
	if _, err := os.Stat(filepath.Join(dir, "opencode-zh-CN")); err == nil {
		return true
	}
	// 检查是否存在 README.md（作为备用标识）
	if _, err := os.Stat(filepath.Join(dir, "README.md")); err == nil {
		return true
	}
	return false
}

// findProjectRoot 从指定目录向上查找项目根目录
func findProjectRoot(startDir string) string {
	currentDir := startDir
	for {
		if isProjectRoot(currentDir) {
			return currentDir
		}
		parentDir := filepath.Dir(currentDir)
		if parentDir == currentDir {
			break
		}
		currentDir = parentDir
	}
	return ""
}

// GetOpencodeDir 获取 OpenCode 源码目录
// 统一使用 ~/.opencode-i18n/opencode，支持环境变量覆盖
func GetOpencodeDir() (string, error) {
	// 环境变量 OPENCODE_SOURCE_DIR (开发者可自定义，用于本地调试)
	if envDir := os.Getenv("OPENCODE_SOURCE_DIR"); envDir != "" {
		return envDir, nil
	}

	// 统一用户目录：~/.opencode-i18n/opencode
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(homeDir, ".opencode-i18n", "opencode"), nil
}

// GetI18nDir 获取外部汉化配置目录
// 如果存在外部配置目录则返回路径，否则返回空字符串表示应使用内嵌资源
// 优先级：项目目录/opencode-i18n > 项目目录/cli-go/internal/core/assets/opencode-i18n
func GetI18nDir() (string, error) {
	projectDir, err := GetProjectDir()
	if err != nil {
		return "", nil // 返回空表示使用内嵌资源
	}

	// 检查项目根目录下的外部 i18n 目录（开发环境）
	externalDir := filepath.Join(projectDir, "opencode-i18n")
	if DirExists(externalDir) {
		return externalDir, nil
	}

	// 检查 cli-go 内的 assets 目录（源码开发环境）
	assetsDir := filepath.Join(projectDir, "cli-go", "internal", "core", "assets", "opencode-i18n")
	if DirExists(assetsDir) {
		return assetsDir, nil
	}

	return "", nil // 返回空表示使用内嵌资源
}

// IsUsingEmbeddedI18n 检查是否使用内嵌的汉化资源
func IsUsingEmbeddedI18n() bool {
	dir, _ := GetI18nDir()
	return dir == ""
}

// HasI18nConfig 检查汉化配置是否可用（内嵌或外部）
func HasI18nConfig() bool {
	// 始终有内嵌资源可用
	return true
}

// GetBinDir 获取编译输出目录
// 统一使用 ~/.opencode-i18n/build，支持环境变量覆盖
func GetBinDir() (string, error) {
	// 环境变量 OPENCODE_BUILD_DIR (开发者可自定义，用于本地调试)
	if envDir := os.Getenv("OPENCODE_BUILD_DIR"); envDir != "" {
		return envDir, nil
	}

	// 统一用户目录：~/.opencode-i18n/build
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(homeDir, ".opencode-i18n", "build"), nil
}

// Exec 执行命令并返回输出
func Exec(name string, args ...string) (string, error) {
	cmd := exec.Command(name, args...)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return string(out), fmt.Errorf("command failed: %s %v\n%s", name, args, err)
	}
	return strings.TrimSpace(string(out)), nil
}

// ExecLive 实时执行命令，输出到 stdout
func ExecLive(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	return cmd.Run()
}

// ExecLiveEnv 实时执行命令（带环境变量）
func ExecLiveEnv(name string, args []string, env []string) error {
	cmd := exec.Command(name, args...)
	cmd.Env = env
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	return cmd.Run()
}

// Exists 检查路径是否存在
func Exists(path string) bool {
	_, err := os.Stat(path)
	return !os.IsNotExist(err)
}

// EnsureDir 确保目录存在
func EnsureDir(path string) error {
	return os.MkdirAll(path, 0755)
}

// CopyFile 复制文件
func CopyFile(src, dst string) error {
	sourceFileStat, err := os.Stat(src)
	if err != nil {
		return err
	}

	if !sourceFileStat.Mode().IsRegular() {
		return fmt.Errorf("%s is not a regular file", src)
	}

	source, err := os.Open(src)
	if err != nil {
		return err
	}
	defer source.Close()

	if err := EnsureDir(filepath.Dir(dst)); err != nil {
		return err
	}

	// Windows 特殊处理：如果目标存在且被占用，尝试重命名
	if runtime.GOOS == "windows" {
		if _, err := os.Stat(dst); err == nil {
			// 使用时间戳防止冲突
			timestamp := time.Now().Format("20060102150405")
			oldFile := fmt.Sprintf("%s.old.%s", dst, timestamp)

			// 尝试清理旧的 .old 文件（如果有的话，且未被占用）
			os.Remove(dst + ".old")

			// 重命名当前文件
			if err := os.Rename(dst, oldFile); err != nil {
				// 仅记录警告，继续尝试直接覆盖
				// fmt.Printf("警告: 无法重命名旧文件: %v\n", err)
			}
		}
	} else {
		// Unix: 如果存在，先删除，确保 inode 更新
		if _, err := os.Stat(dst); err == nil {
			os.Remove(dst)
		}
	}

	destination, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer destination.Close()

	_, err = io.Copy(destination, source)
	return err
}

// ReadJSON 读取 JSON 文件
func ReadJSON(path string, v interface{}) error {
	file, err := os.Open(path)
	if err != nil {
		return err
	}
	defer file.Close()
	return json.NewDecoder(file).Decode(v)
}

// WriteJSON 写入 JSON 文件
func WriteJSON(path string, v interface{}) error {
	if err := EnsureDir(filepath.Dir(path)); err != nil {
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

// IsWindows 检查是否为 Windows
func IsWindows() bool {
	return runtime.GOOS == "windows"
}

// FileExists 检查文件是否存在（非目录）
func FileExists(path string) bool {
	info, err := os.Stat(path)
	if err != nil {
		return false
	}
	return !info.IsDir()
}

// DirExists 检查目录是否存在
func DirExists(path string) bool {
	info, err := os.Stat(path)
	if err != nil {
		return false
	}
	return info.IsDir()
}

// Truncate 截断字符串到指定长度
// 如果超过 maxLen，添加省略号
func Truncate(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen] + "..."
}

// DetectPlatform 检测当前平台，返回 OpenCode 构建目标格式
// 返回值如：windows-x64, darwin-arm64, linux-x64
// 支持的平台：windows-x64, windows-arm64, darwin-x64, darwin-arm64, linux-x64, linux-arm64
func DetectPlatform() string {
	osName := runtime.GOOS
	arch := runtime.GOARCH

	// 架构映射：Go 的 amd64 对应 OpenCode 的 x64
	archName := arch
	if arch == "amd64" {
		archName = "x64"
	}

	// 平台映射
	switch osName {
	case "windows":
		if archName == "x64" || archName == "arm64" {
			return "windows-" + archName
		}
	case "darwin":
		if archName == "x64" || archName == "arm64" {
			return "darwin-" + archName
		}
	case "linux":
		if archName == "x64" || archName == "arm64" {
			return "linux-" + archName
		}
	}

	// 默认回退到当前系统-x64
	return osName + "-x64"
}
