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
	Short: "Verify i18n configuration",
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
			targetFile := filepath.Join(opencodeDir, config.File)
			if !core.Exists(targetFile) {
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
		var tsxFiles []string
		filepath.Walk(sourceDir, func(path string, info os.FileInfo, err error) error {
			if err == nil && !info.IsDir() {
				ext := filepath.Ext(path)
				if ext == ".tsx" || ext == ".jsx" {
					tsxFiles = append(tsxFiles, path)
				}
			}
			return nil
		})

		totalSourceFiles := len(tsxFiles)

		// 统计已配置的文件
		configuredFiles := make(map[string]bool)
		for _, config := range configs {
			if config.File != "" {
				configuredFiles[config.File] = true
			}
		}

		coverage := float64(len(configuredFiles)) / float64(totalSourceFiles) * 100

		fmt.Printf("  源码文件: %d 个\n", totalSourceFiles)
		fmt.Printf("  已汉化: %d 个\n", len(configuredFiles))
		fmt.Printf("  覆盖率: %.1f%%\n", coverage)
	} else {
		fmt.Println("  ⚠️ 源码目录不存在，跳过覆盖率检查")
	}

	fmt.Println("\n✓ 验证完成")
}

// findJSONFiles 查找目录下所有 JSON 文件
func findJSONFiles(dir string) ([]string, error) {
	var files []string
	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && strings.HasSuffix(info.Name(), ".json") {
			files = append(files, path)
		}
		return nil
	})
	return files, err
}

// extractVariables 提取文本中的变量 {xxx}
func extractVariables(s string) []string {
	var vars []string
	inVar := false
	var current strings.Builder

	for _, c := range s {
		if c == '{' {
			inVar = true
			current.Reset()
		} else if c == '}' && inVar {
			vars = append(vars, current.String())
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
