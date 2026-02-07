package core

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"
)

// Builder 构建器
type Builder struct {
	opencodeDir string
	buildDir    string
	bunPath     string
}

// NewBuilder 创建构建器
func NewBuilder() (*Builder, error) {
	opencodeDir, err := GetOpencodeDir()
	if err != nil {
		return nil, err
	}
	buildDir := filepath.Join(opencodeDir, "packages", "opencode")
	bunPath := "bun" // 假设 bun 在 PATH 中

	// 简单的环境检查
	if _, err := Exec("bun", "--version"); err != nil {
		return nil, fmt.Errorf("未找到 Bun，请先安装: npm install -g bun")
	}

	return &Builder{
		opencodeDir: opencodeDir,
		buildDir:    buildDir,
		bunPath:     bunPath,
	}, nil
}

// CheckEnvironment 检查构建环境
func (b *Builder) CheckEnvironment() error {
	if !Exists(b.buildDir) {
		return fmt.Errorf("构建目录不存在: %s", b.buildDir)
	}
	return nil
}

// PatchBunVersionCheck 修复 Bun 版本检查
// 支持两种上游模式：
//   - 旧版 (<=1.1.36): if (process.versions.bun !== expectedBunVersion) — 严格相等
//   - 新版 (>=1.1.37): semver.satisfies(process.versions.bun, expectedBunVersionRange) — 语义化范围
func (b *Builder) PatchBunVersionCheck() (bool, error) {
	scriptPath := filepath.Join(b.opencodeDir, "packages", "script", "src", "index.ts")

	if !Exists(scriptPath) {
		return false, nil
	}

	contentBytes, err := os.ReadFile(scriptPath)
	if err != nil {
		return false, err
	}
	content := string(contentBytes)

	// 检查是否已经修复过（旧版补丁标记 或 新版补丁标记）
	if strings.Contains(content, "isCompatible") || strings.Contains(content, "// [opencode-i18n] version check bypassed") {
		return true, nil
	}

	patchApplied := false

	// === 模式 1: 新版 semver 检查 (>=1.1.37) ===
	semverCheck := "if (!semver.satisfies(process.versions.bun, expectedBunVersionRange))"
	if strings.Contains(content, semverCheck) {
		// 将 semver 检查替换为始终通过 + 仅打印警告
		lines := strings.Split(content, "\n")
		var newLines []string

		for i := 0; i < len(lines); i++ {
			line := lines[i]
			if strings.Contains(line, semverCheck) {
				// 替换为警告而非报错
				newLines = append(newLines, "// [opencode-i18n] version check bypassed: allow any bun version >= required")
				newLines = append(newLines, "if (!semver.satisfies(process.versions.bun, expectedBunVersionRange)) {")
				newLines = append(newLines, "  console.warn(`[opencode-i18n] Warning: expected bun@${expectedBunVersionRange}, using bun@${process.versions.bun}`)")
				newLines = append(newLines, "}")
				// 跳过原来的 throw 和 }
				i += 2
				patchApplied = true
			} else {
				newLines = append(newLines, line)
			}
		}

		if patchApplied {
			if err := os.WriteFile(scriptPath, []byte(strings.Join(newLines, "\n")), 0644); err != nil {
				return false, err
			}
			return true, nil
		}
	}

	// === 模式 2: 旧版严格相等检查 (<=1.1.36) ===
	strictCheck := "if (process.versions.bun !== expectedBunVersion)"
	if strings.Contains(content, strictCheck) {
		newCode := `// [opencode-i18n] version check bypassed: 放宽版本检查，允许使用相同或更高版本的 Bun
const [expectedMajor, expectedMinor, expectedPatch] = expectedBunVersion.split(".").map(Number)
const [actualMajor, actualMinor, actualPatch] = (process.versions.bun || "0.0.0").split(".").map(Number)

const isCompatible =
  actualMajor > expectedMajor ||
  (actualMajor === expectedMajor && actualMinor > expectedMinor) ||
  (actualMajor === expectedMajor && actualMinor === expectedMinor && actualPatch >= expectedPatch)

if (!isCompatible) {
  throw new Error(` + "`" + `This script requires bun@${expectedBunVersion}+, but you are using bun@${process.versions.bun}` + "`" + `)
}`

		lines := strings.Split(content, "\n")
		var newLines []string

		for i := 0; i < len(lines); i++ {
			line := lines[i]
			if strings.Contains(line, strictCheck) {
				newLines = append(newLines, newCode)
				// 跳过原来的 throw 和 }
				i += 2
				patchApplied = true
			} else {
				newLines = append(newLines, line)
			}
		}

		if patchApplied {
			if err := os.WriteFile(scriptPath, []byte(strings.Join(newLines, "\n")), 0644); err != nil {
				return false, err
			}
			return true, nil
		}
	}

	// 没有找到任何已知的版本检查模式，可能已被上游移除或使用新方式
	return false, nil
}

// InstallDependencies 安装依赖
func (b *Builder) InstallDependencies(silent bool) error {
	if !silent {
		fmt.Println("正在安装依赖...")
	}

	nodeModulesPath := filepath.Join(b.buildDir, "node_modules")
	if Exists(nodeModulesPath) {
		if !silent {
			fmt.Println("依赖已存在，跳过安装")
		}
		return nil
	}

	if err := os.Chdir(b.buildDir); err != nil {
		return err
	}

	return ExecLive(b.bunPath, "install")
}

// Build 执行构建
func (b *Builder) Build(platform string, silent bool) error {
	if !silent {
		fmt.Println("开始编译构建...")
	}

	if err := b.CheckEnvironment(); err != nil {
		return err
	}

	if patched, err := b.PatchBunVersionCheck(); err != nil {
		fmt.Printf("警告: Bun 版本兼容性修复失败: %v\n", err)
	} else if patched && !silent {
		fmt.Println("  已应用 Bun 版本兼容性修复")
	}

	if err := b.InstallDependencies(silent); err != nil {
		return err
	}

	args := []string{"run", "script/build.ts"}

	if platform != "" {
		// 简单的平台匹配逻辑
		currentOs := runtime.GOOS
		currentArch := runtime.GOARCH

		targetParts := strings.Split(platform, "-")
		if len(targetParts) == 2 {
			targetOs := targetParts[0]
			if targetOs == "win32" {
				targetOs = "windows"
			}
			targetArch := targetParts[1]
			// amd64 在 Node.js 中通常称为 x64
			if currentArch == "amd64" {
				currentArch = "x64"
			}

			if targetOs == currentOs && targetArch == currentArch {
				args = append(args, "--single")
			}
		}
	}

	if !silent {
		fmt.Printf("执行: %s %s\n", b.bunPath, strings.Join(args, " "))
	}

	if err := os.Chdir(b.buildDir); err != nil {
		return err
	}

	// 尝试绕过 SSL 验证错误
	// 这是一个临时修复，因为 models.dev 的证书在某些环境中可能验证失败
	env := os.Environ()
	env = append(env, "BUN_TLS_REJECT_UNAUTHORIZED=0")
	env = append(env, "NODE_TLS_REJECT_UNAUTHORIZED=0")

	return ExecLiveEnv(b.bunPath, args, env)
}

// GetDistPath 获取编译产物路径
func (b *Builder) GetDistPath(platform string) string {
	ext := ""
	if strings.HasPrefix(platform, "windows") {
		ext = ".exe"
	}
	return filepath.Join(b.buildDir, "dist", "opencode-"+platform, "bin", "opencode"+ext)
}

// DeployToLocal 部署到本地 bin 目录 (统一目录: ~/.opencode-i18n/build)
func (b *Builder) DeployToLocal(platform string, silent bool) error {
	if !silent {
		fmt.Println("正在部署到本地环境...")
	}

	binDir, err := GetBinDir()
	if err != nil {
		return err
	}

	if err := EnsureDir(binDir); err != nil {
		return err
	}

	sourcePath := b.GetDistPath(platform)
	ext := ""
	if strings.HasPrefix(platform, "windows") {
		ext = ".exe"
	}
	destPath := filepath.Join(binDir, "opencode"+ext)

	if !Exists(sourcePath) {
		return fmt.Errorf("编译产物不存在: %s", sourcePath)
	}

	if err := CopyFile(sourcePath, destPath); err != nil {
		return err
	}

	if !silent {
		fmt.Printf("已部署到: %s\n", destPath)
	}
	return nil
}
