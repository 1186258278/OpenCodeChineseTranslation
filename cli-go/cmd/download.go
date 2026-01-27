package cmd

import (
	"archive/zip"
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strings"

	"opencode-cli/internal/core"

	"github.com/spf13/cobra"
)

const (
	GitHubAPIURL = "https://api.github.com/repos/1186258278/OpenCodeChineseTranslation/releases/latest"
	GitHubRepo   = "1186258278/OpenCodeChineseTranslation"
)

// GitHubRelease GitHub Release API 响应结构
type GitHubRelease struct {
	TagName string `json:"tag_name"`
	Name    string `json:"name"`
	Body    string `json:"body"`
	Assets  []struct {
		Name               string `json:"name"`
		BrowserDownloadURL string `json:"browser_download_url"`
		Size               int64  `json:"size"`
	} `json:"assets"`
}

var downloadCmd = &cobra.Command{
	Use:   "download",
	Short: "下载预编译汉化版 (无需编译环境)",
	Long:  "Download prebuilt OpenCode Chinese version from GitHub Releases (no compilation required)",
	Run: func(cmd *cobra.Command, args []string) {
		runDownload()
	},
}

func init() {
	rootCmd.AddCommand(downloadCmd)
}

// runDownload 下载预编译版
func runDownload() {
	fmt.Println("")
	fmt.Println("══════════════════════════════════════════════════")
	fmt.Println("  下载预编译版 OpenCode 汉化版")
	fmt.Println("══════════════════════════════════════════════════")
	fmt.Println("")
	fmt.Println("  无需本地编译环境，直接从 GitHub Releases 下载")
	fmt.Println("  适用于无法安装 Bun/Node.js 或想快速体验的用户")
	fmt.Println("")

	// 1. 获取最新 Release 信息
	fmt.Println("▶ 正在获取最新版本信息...")

	release, err := getLatestRelease()
	if err != nil {
		fmt.Printf("✗ 获取 Release 信息失败: %v\n", err)
		fmt.Println("")
		fmt.Println("  可能的原因:")
		fmt.Println("    1. 网络连接问题（需要访问 GitHub）")
		fmt.Println("    2. 仓库暂无 Release 发布")
		fmt.Println("")
		fmt.Println("  备选方案:")
		fmt.Printf("    手动下载: https://github.com/%s/releases\n", GitHubRepo)
		return
	}

	fmt.Printf("✓ 最新版本: %s\n", release.TagName)
	fmt.Println("")

	// 2. 匹配当前平台的资源
	platform := core.DetectPlatform()
	
	// 文件名格式可能是：
	//   opencode-zh-CN-windows-x64.zip (无版本号)
	//   opencode-zh-CN-v8.1.0-windows-x64.zip (有版本号)
	// 所以使用模糊匹配

	var downloadURL string
	var fileSize int64
	var assetName string

	for _, asset := range release.Assets {
		name := asset.Name
		// 匹配包含平台标识的 zip 文件
		if strings.HasPrefix(name, "opencode-zh-CN") && 
		   strings.HasSuffix(name, ".zip") &&
		   strings.Contains(name, platform) {
			downloadURL = asset.BrowserDownloadURL
			fileSize = asset.Size
			assetName = name
			break
		}
	}

	if downloadURL == "" {
		fmt.Printf("✗ 未找到适用于当前平台的预编译包: %s\n", platform)
		fmt.Println("")
		fmt.Println("  可用的预编译包:")
		for _, asset := range release.Assets {
			if strings.HasSuffix(asset.Name, ".zip") && strings.HasPrefix(asset.Name, "opencode-") {
				fmt.Printf("    - %s\n", asset.Name)
			}
		}
		fmt.Println("")
		fmt.Printf("  手动下载: https://github.com/%s/releases/tag/%s\n", GitHubRepo, release.TagName)
		return
	}

	fmt.Printf("  平台: %s\n", platform)
	fmt.Printf("  文件: %s\n", assetName)
	fmt.Printf("  大小: %.2f MB\n", float64(fileSize)/(1024*1024))
	fmt.Println("")

	// 3. 确认下载
	reader := bufio.NewReader(os.Stdin)
	fmt.Print("是否下载并安装? [Y/n]: ")
	answer, _ := reader.ReadString('\n')
	answer = strings.TrimSpace(strings.ToLower(answer))
	if answer == "n" || answer == "no" {
		fmt.Println("操作已取消")
		return
	}

	// 4. 创建临时目录
	tempDir := filepath.Join(os.TempDir(), "opencode-download")
	os.RemoveAll(tempDir) // 清理旧的临时文件
	if err := os.MkdirAll(tempDir, 0755); err != nil {
		fmt.Printf("✗ 创建临时目录失败: %v\n", err)
		return
	}
	defer os.RemoveAll(tempDir)

	zipPath := filepath.Join(tempDir, assetName)

	// 5. 下载文件
	fmt.Println("")
	fmt.Println("▶ 正在下载...")

	if err := downloadFile(downloadURL, zipPath); err != nil {
		fmt.Printf("✗ 下载失败: %v\n", err)
		fmt.Println("")
		fmt.Println("  可能的解决方案:")
		fmt.Println("    1. 检查网络连接")
		fmt.Println("    2. 配置代理或使用 VPN")
		fmt.Printf("    3. 手动下载: %s\n", downloadURL)
		return
	}

	fmt.Println("✓ 下载完成")

	// 6. 解压文件
	fmt.Println("")
	fmt.Println("▶ 正在解压...")

	extractDir := filepath.Join(tempDir, "extracted")
	if err := unzip(zipPath, extractDir); err != nil {
		fmt.Printf("✗ 解压失败: %v\n", err)
		return
	}

	fmt.Println("✓ 解压完成")

	// 7. 查找可执行文件
	exeName := "opencode"
	if runtime.GOOS == "windows" {
		exeName = "opencode.exe"
	}

	var exePath string
	filepath.Walk(extractDir, func(path string, info os.FileInfo, err error) error {
		if err == nil && !info.IsDir() && info.Name() == exeName {
			exePath = path
			return filepath.SkipAll
		}
		return nil
	})

	if exePath == "" {
		fmt.Printf("✗ 未在压缩包中找到 %s\n", exeName)
		return
	}

	// 8. 部署到目标目录
	fmt.Println("")
	fmt.Println("▶ 正在部署...")

	binDir, err := getDeployDir()
	if err != nil {
		fmt.Printf("✗ 获取部署目录失败: %v\n", err)
		return
	}

	if err := os.MkdirAll(binDir, 0755); err != nil {
		fmt.Printf("✗ 创建目录失败: %v\n", err)
		return
	}

	targetPath := filepath.Join(binDir, exeName)

	// 复制文件
	if err := copyFileWithProgress(exePath, targetPath); err != nil {
		fmt.Printf("✗ 复制文件失败: %v\n", err)
		return
	}

	// 设置可执行权限 (Unix)
	if runtime.GOOS != "windows" {
		os.Chmod(targetPath, 0755)
	}

	fmt.Printf("✓ 已部署到: %s\n", targetPath)

	// 9. 配置 PATH（复用 deploy 逻辑）
	fmt.Println("")
	fmt.Println("▶ 正在配置系统 PATH...")

	if err := configurePathForDownload(binDir); err != nil {
		fmt.Printf("⚠ PATH 配置失败: %v\n", err)
		fmt.Println("  请手动将以下目录添加到 PATH:")
		fmt.Printf("    %s\n", binDir)
	} else {
		fmt.Println("✓ PATH 配置完成")
	}

	// 10. 完成
	fmt.Println("")
	fmt.Println("══════════════════════════════════════════════════")
	fmt.Println("  ✓ OpenCode 汉化版安装完成!")
	fmt.Println("══════════════════════════════════════════════════")
	fmt.Println("")
	fmt.Printf("  版本: %s\n", release.TagName)
	fmt.Printf("  位置: %s\n", targetPath)
	fmt.Println("")
	fmt.Println("  下一步:")
	fmt.Println("    1. 重新打开终端使 PATH 生效")
	fmt.Println("    2. 运行 'opencode' 启动程序")
	fmt.Println("    3. 输入 /connect 配置 AI 模型")
}

// getLatestRelease 获取最新 Release 信息
func getLatestRelease() (*GitHubRelease, error) {
	client := &http.Client{}
	req, err := http.NewRequest("GET", GitHubAPIURL, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "application/vnd.github.v3+json")
	req.Header.Set("User-Agent", "OpenCode-CLI")

	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("HTTP %d: %s", resp.StatusCode, resp.Status)
	}

	var release GitHubRelease
	if err := json.NewDecoder(resp.Body).Decode(&release); err != nil {
		return nil, err
	}

	return &release, nil
}

// downloadFile 下载文件（带进度显示）
func downloadFile(url, dest string) error {
	resp, err := http.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return fmt.Errorf("HTTP %d: %s", resp.StatusCode, resp.Status)
	}

	out, err := os.Create(dest)
	if err != nil {
		return err
	}
	defer out.Close()

	// 简单进度显示
	totalSize := resp.ContentLength
	downloaded := int64(0)
	buf := make([]byte, 32*1024)

	for {
		n, err := resp.Body.Read(buf)
		if n > 0 {
			out.Write(buf[:n])
			downloaded += int64(n)

			if totalSize > 0 {
				percent := float64(downloaded) / float64(totalSize) * 100
				fmt.Printf("\r  进度: %.1f%% (%.2f / %.2f MB)", percent,
					float64(downloaded)/(1024*1024),
					float64(totalSize)/(1024*1024))
			}
		}
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}
	}

	fmt.Println()
	return nil
}

// unzip 解压 ZIP 文件
func unzip(src, dest string) error {
	r, err := zip.OpenReader(src)
	if err != nil {
		return err
	}
	defer r.Close()

	for _, f := range r.File {
		fpath := filepath.Join(dest, f.Name)

		// 安全检查：防止 Zip Slip 漏洞
		if !strings.HasPrefix(fpath, filepath.Clean(dest)+string(os.PathSeparator)) {
			return fmt.Errorf("非法文件路径: %s", fpath)
		}

		if f.FileInfo().IsDir() {
			os.MkdirAll(fpath, 0755)
			continue
		}

		if err := os.MkdirAll(filepath.Dir(fpath), 0755); err != nil {
			return err
		}

		outFile, err := os.OpenFile(fpath, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, f.Mode())
		if err != nil {
			return err
		}

		rc, err := f.Open()
		if err != nil {
			outFile.Close()
			return err
		}

		_, err = io.Copy(outFile, rc)
		outFile.Close()
		rc.Close()

		if err != nil {
			return err
		}
	}

	return nil
}

// copyFileWithProgress 复制文件
func copyFileWithProgress(src, dst string) error {
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

// configurePathForDownload 配置 PATH 环境变量
func configurePathForDownload(binDir string) error {
	switch runtime.GOOS {
	case "windows":
		// 检查是否已在 PATH 中
		currentPath := os.Getenv("PATH")
		if strings.Contains(strings.ToLower(currentPath), strings.ToLower(binDir)) {
			return nil // 已在 PATH 中
		}

		// 使用 PowerShell 添加到用户 PATH
		script := fmt.Sprintf(`
$userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
if (-not $userPath.ToLower().Contains('%s'.ToLower())) {
    $newPath = '%s;' + $userPath
    [Environment]::SetEnvironmentVariable('PATH', $newPath, 'User')
}
`, binDir, binDir)

		return core.ExecLive("powershell", "-NoProfile", "-Command", script)

	default:
		// Unix: 提示用户手动配置
		homeDir, _ := os.UserHomeDir()
		shellRC := filepath.Join(homeDir, ".bashrc")
		if _, err := os.Stat(filepath.Join(homeDir, ".zshrc")); err == nil {
			shellRC = filepath.Join(homeDir, ".zshrc")
		}

		// 检查是否已配置
		if data, err := os.ReadFile(shellRC); err == nil {
			if strings.Contains(string(data), binDir) {
				return nil
			}
		}

		// 追加到配置文件
		exportLine := fmt.Sprintf("\n# OpenCode\nexport PATH=\"%s:$PATH\"\n", binDir)
		f, err := os.OpenFile(shellRC, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		if err != nil {
			return err
		}
		defer f.Close()
		_, err = f.WriteString(exportLine)
		return err
	}
}
