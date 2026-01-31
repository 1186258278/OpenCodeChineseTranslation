package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"opencode-cli/internal/core"

	"github.com/spf13/cobra"
)

var verifyCmd = &cobra.Command{
	Use:   "verify",
	Short: "验证汉化配置完整性",
	Long:  "Verify the i18n configuration files, check variables and coverage",
	Run: func(cmd *cobra.Command, args []string) {
		detailed, _ := cmd.Flags().GetBool("detailed")
		dryRun, _ := cmd.Flags().GetBool("dry-run")
		runVerify(detailed, dryRun)
	},
}

func init() {
	verifyCmd.Flags().BoolP("detailed", "d", false, "Show detailed information")
	verifyCmd.Flags().Bool("dry-run", false, "Simulate the apply process")
	rootCmd.AddCommand(verifyCmd)
}

func runVerify(detailed, dryRun bool) {
	fmt.Println("\n▶ 验证汉化配置")

	// 1. 初始化 I18n
	i18n, err := core.NewI18n()
	if err != nil {
		fmt.Printf("✗ 初始化失败: %v\n", err)
		return
	}

	// 2. 加载配置（自动处理内嵌资源）
	configs, err := i18n.LoadConfig()
	if err != nil {
		fmt.Printf("✗ 加载配置失败: %v\n", err)
		return
	}

	opencodeDir, err := core.GetOpencodeDir()
	if err != nil {
		fmt.Printf("✗ 无法获取源码目录: %v\n", err)
		return
	}

	// 3. 验证配置完整性
	fmt.Println("\n[1/4] 验证配置完整性...")

	totalConfigs := len(configs)
	totalReplacements := 0
	categoryStats := make(map[string]int)

	for _, config := range configs {
		replacements := len(config.Replacements)
		totalReplacements += replacements
		categoryStats[config.Category] += replacements
	}

	fmt.Printf("  ✓ 配置文件: %d 个\n", totalConfigs)
	fmt.Printf("  ✓ 翻译条目: %d 条\n", totalReplacements)

	if detailed {
		fmt.Println("\n  分类统计:")
		for category, count := range categoryStats {
			fmt.Printf("    - %s: %d 条\n", category, count)
		}
	}

	// 4. 变量保护检查
	fmt.Println("\n[2/4] 检查变量保护...")

	variableIssues := 0
	for _, config := range configs {
		for from, to := range config.Replacements {
			// 检查 {xxx} 格式的变量
			origVars := extractVariables(from)
			transVars := extractVariables(to)

			if !sameVariables(origVars, transVars) {
				variableIssues++
				if detailed {
					fmt.Printf("  ⚠️ %s/%s\n", config.Category, config.FileName)
					fmt.Printf("     原文: %s\n", core.Truncate(from, 50))
					fmt.Printf("     译文: %s\n", core.Truncate(to, 50))
					fmt.Printf("     缺失变量: %v\n", diffVariables(origVars, transVars))
				}
			}
		}
	}

	if variableIssues > 0 {
		fmt.Printf("  ⚠️ 发现 %d 处变量问题\n", variableIssues)
	} else {
		fmt.Println("  ✓ 变量保护验证通过")
	}

	// 5. 模拟运行检查（如果启用）
	if dryRun {
		fmt.Println("\n[3/4] 模拟运行检查...")

		matchCount := 0
		missCount := 0

		for _, config := range configs {
			// 使用与 apply 相同的路径处理逻辑
			targetFile := i18n.GetTargetFilePath(config)
			if targetFile == "" || !core.Exists(targetFile) {
				missCount += len(config.Replacements)
				continue
			}

			content, err := os.ReadFile(targetFile)
			if err != nil {
				missCount += len(config.Replacements)
				continue
			}

			contentStr := string(content)
			for from := range config.Replacements {
				// 简单的字符串包含检查（未考虑正则边界，仅供参考）
				if strings.Contains(contentStr, from) {
					matchCount++
				} else {
					missCount++
				}
			}
		}

		fmt.Printf("  📝 替换: %d/%d 可匹配\n", matchCount, matchCount+missCount)
		if missCount > 0 {
			fmt.Printf("  ⚠️ %d 条翻译在源码中找不到匹配\n", missCount)
		}
	} else {
		fmt.Println("\n[3/4] 跳过模拟运行（使用 --dry-run 启用）")
	}

	// 6. 检查覆盖率
	fmt.Println("\n[4/4] 检查汉化覆盖率...")

	sourceDir := filepath.Join(opencodeDir, "packages", "opencode", "src")
	if core.Exists(sourceDir) {
		var uiFiles []string  // 包含 UI 字符串的文件
		var codeOnlyFiles []string // 纯代码文件

		filepath.Walk(sourceDir, func(path string, info os.FileInfo, err error) error {
			if err == nil && !info.IsDir() {
				ext := filepath.Ext(path)
				if ext == ".tsx" || ext == ".jsx" {
					// 检查文件是否包含 UI 字符串
					if hasUIStrings(path) {
						uiFiles = append(uiFiles, path)
					} else {
						codeOnlyFiles = append(codeOnlyFiles, path)
					}
				}
			}
			return nil
		})

		// 统计已配置的文件
		configuredFiles := make(map[string]bool)
		for _, config := range configs {
			if config.File != "" {
				configuredFiles[config.File] = true
			}
		}

		// 只计算包含 UI 字符串的文件的覆盖率
		totalUIFiles := len(uiFiles)
		if totalUIFiles == 0 {
			totalUIFiles = 1 // 防止除以 0
		}
		coverage := float64(len(configuredFiles)) / float64(totalUIFiles) * 100
		if coverage > 100 {
			coverage = 100 // 可能有些配置对应的文件已被删除，限制最大 100%
		}

		fmt.Printf("  源码文件: %d 个 (UI: %d, 纯代码: %d)\n", len(uiFiles)+len(codeOnlyFiles), len(uiFiles), len(codeOnlyFiles))
		fmt.Printf("  已配置: %d 个\n", len(configuredFiles))
		fmt.Printf("  覆盖率: %.1f%% (基于包含 UI 字符串的文件)\n", coverage)
		
		if detailed && len(codeOnlyFiles) > 0 {
			fmt.Printf("\n  📁 纯代码文件 (%d 个，无需翻译):\n", len(codeOnlyFiles))
			for i, f := range codeOnlyFiles {
				if i >= 5 {
					fmt.Printf("    ... 还有 %d 个\n", len(codeOnlyFiles)-5)
					break
				}
				relPath, _ := filepath.Rel(sourceDir, f)
				fmt.Printf("    - %s\n", relPath)
			}
		}
	} else {
		fmt.Println("  ⚠️ 源码目录不存在，跳过覆盖率检查")
	}

	fmt.Println("\n✓ 验证完成")
}

// extractVariables 提取文本中的简单变量 {xxx}
// 只提取由字母、数字、下划线组成的变量，忽略复杂表达式
func extractVariables(s string) []string {
	var vars []string
	inVar := false
	var current strings.Builder

	for _, c := range s {
		if c == '{' {
			inVar = true
			current.Reset()
		} else if c == '}' && inVar {
			val := current.String()
			// 过滤复杂表达式：如果包含空格、点号、引号等，视为代码逻辑而非简单变量
			if !strings.ContainsAny(val, " .\"'()[]?") {
				vars = append(vars, val)
			}
			inVar = false
		} else if inVar {
			current.WriteRune(c)
		}
	}
	return vars
}

// sameVariables 检查两个变量列表是否相同
func sameVariables(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	aMap := make(map[string]int)
	for _, v := range a {
		aMap[v]++
	}
	for _, v := range b {
		if aMap[v] <= 0 {
			return false
		}
		aMap[v]--
	}
	return true
}

// diffVariables 返回 a 中有但 b 中没有的变量
func diffVariables(a, b []string) []string {
	bMap := make(map[string]bool)
	for _, v := range b {
		bMap[v] = true
	}
	var diff []string
	for _, v := range a {
		if !bMap[v] {
			diff = append(diff, v)
		}
	}
	return diff
}

// hasUIStrings 检查文件是否包含需要翻译的硬编码 UI 字符串
// 更精确的判断：检查硬编码的英文字符串属性，而非代码结构
func hasUIStrings(filePath string) bool {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return false
	}

	contentStr := string(content)

	// 1. 检查是否包含中文字符（已翻译的文件，说明需要翻译配置）
	for _, r := range contentStr {
		if r >= 0x4e00 && r <= 0x9fff {
			return true
		}
	}

	// 2. 检查硬编码的英文 UI 字符串模式
	// 简单检查：包含引号后跟大写字母的 title 属性
	if strings.Contains(contentStr, `title="`) && !strings.Contains(contentStr, `title={`) {
		// 可能有硬编码的 title，检查常见的英文开头
		if strings.Contains(contentStr, `title="S`) || 
		   strings.Contains(contentStr, `title="C`) ||
		   strings.Contains(contentStr, `title="E`) ||
		   strings.Contains(contentStr, `title="A`) ||
		   strings.Contains(contentStr, `title="M`) {
			return true
		}
	}

	// 3. 检查常见的需要翻译的组件导出
	needsTranslation := []string{
		"DialogSelect",
		"DialogSession",
		"DialogModel",
		"DialogProvider",
		"DialogExport",
		"DialogHelp",
		"DialogMcp",
		"DialogStash",
		"DialogStatus",
		"tips",
		"Autocomplete",
	}

	for _, component := range needsTranslation {
		if strings.Contains(contentStr, "export function "+component) ||
		   strings.Contains(contentStr, "export const "+component) {
			return true
		}
	}

	return false
}
