package core

import (
	"embed"
	"encoding/json"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

//go:embed assets/opencode-i18n
var embeddedAssets embed.FS

// TranslationConfig 汉化配置结构
type TranslationConfig struct {
	Category     string
	FileName     string
	ConfigPath   string
	File         string            `json:"file"`
	Replacements map[string]string `json:"replacements"`
}

// Replacement 单条替换规则（用于 verify 命令）
type Replacement struct {
	From string
	To   string
}

// GetReplacementsList 获取替换规则列表
func (c *TranslationConfig) GetReplacementsList() []Replacement {
	var list []Replacement
	for from, to := range c.Replacements {
		list = append(list, Replacement{From: from, To: to})
	}
	return list
}

// LoadI18nConfig 从单个 JSON 文件加载配置
func LoadI18nConfig(path string) (*TranslationConfig, error) {
	var config TranslationConfig
	if err := ReadJSON(path, &config); err != nil {
		return nil, err
	}
	config.ConfigPath = path
	return &config, nil
}

// I18n 汉化处理器
type I18n struct {
	i18nDir     string
	opencodeDir string
	useEmbedded bool
}

// NewI18n 创建 I18n 实例
func NewI18n() (*I18n, error) {
	i18nDir, err := GetI18nDir()
	useEmbedded := false

	// 如果获取目录失败或目录不存在，尝试使用内置资源
	if err != nil || !DirExists(i18nDir) {
		useEmbedded = true
		i18nDir = "assets/opencode-i18n" // embedded 中的相对路径
	}

	opencodeDir, err := GetOpencodeDir()
	if err != nil {
		// 如果连 OpenCode 源码目录都找不到，那就真的无法继续了
		return nil, err
	}

	if useEmbedded {
		fmt.Println("提示: 使用内置汉化配置")
	} else {
		fmt.Printf("提示: 使用外部汉化配置: %s\n", i18nDir)
	}

	return &I18n{
		i18nDir:     i18nDir,
		opencodeDir: opencodeDir,
		useEmbedded: useEmbedded,
	}, nil
}

// LoadConfig 读取所有汉化配置文件
func (i *I18n) LoadConfig() ([]TranslationConfig, error) {
	var configs []TranslationConfig
	var entries []fs.DirEntry
	var err error

	if i.useEmbedded {
		entries, err = fs.ReadDir(embeddedAssets, i.i18nDir)
	} else {
		entries, err = os.ReadDir(i.i18nDir)
	}

	if err != nil {
		return nil, err
	}

	for _, entry := range entries {
		if entry.IsDir() {
			// 处理子目录中的配置文件
			categoryName := entry.Name()

			var files []fs.DirEntry
			if i.useEmbedded {
				// Embedded FS 路径必须使用正斜杠
				embedPath := i.i18nDir + "/" + categoryName
				files, err = fs.ReadDir(embeddedAssets, embedPath)
			} else {
				categoryDir := filepath.Join(i.i18nDir, categoryName)
				files, err = os.ReadDir(categoryDir)
			}

			if err != nil {
				continue
			}

			for _, file := range files {
				if strings.HasSuffix(file.Name(), ".json") {
					config := i.loadSingleConfig(categoryName, file.Name())
					if config != nil {
						configs = append(configs, *config)
					}
				}
			}
		} else if strings.HasSuffix(entry.Name(), ".json") {
			// 处理根目录下的配置文件（如 app.json）
			// 跳过 config.json（元信息文件，不是汉化规则）
			if entry.Name() == "config.json" {
				continue
			}
			config := i.loadSingleConfig("root", entry.Name())
			if config != nil {
				configs = append(configs, *config)
			}
		}
	}

	return configs, nil
}

// loadSingleConfig 加载单个配置文件
func (i *I18n) loadSingleConfig(category, fileName string) *TranslationConfig {
	var config TranslationConfig
	var configPath string
	var readErr error

	if i.useEmbedded {
		if category == "root" {
			configPath = i.i18nDir + "/" + fileName
		} else {
			configPath = i.i18nDir + "/" + category + "/" + fileName
		}
		var data []byte
		data, readErr = fs.ReadFile(embeddedAssets, configPath)
		if readErr == nil {
			readErr = json.Unmarshal(data, &config)
		}
	} else {
		if category == "root" {
			configPath = filepath.Join(i.i18nDir, fileName)
		} else {
			configPath = filepath.Join(i.i18nDir, category, fileName)
		}
		readErr = ReadJSON(configPath, &config)
	}

	if readErr != nil {
		fmt.Printf("警告: 解析配置文件失败 %s: %v\n", configPath, readErr)
		return nil
	}

	config.Category = category
	config.FileName = fileName
	config.ConfigPath = configPath
	return &config
}

// ApplyResult 应用结果
type ApplyResult struct {
	File         string
	Success      bool
	Replacements struct {
		Total   int
		Success int
		Failed  int
	}
	Skipped    bool
	SkipReason string
}

// GetTargetFilePath 获取汉化配置对应的目标文件完整路径
// 统一 verify 和 apply 的路径处理逻辑
func (i *I18n) GetTargetFilePath(config TranslationConfig) string {
	if config.File == "" {
		return ""
	}

	relativePath := config.File
	// 如果路径不以 packages/ 开头，自动添加 packages/opencode/ 前缀
	if !strings.HasPrefix(relativePath, "packages/") {
		relativePath = filepath.Join("packages", "opencode", relativePath)
	}

	return filepath.Join(i.opencodeDir, relativePath)
}

// ApplyConfig 应用单个配置文件的替换规则
func (i *I18n) ApplyConfig(config TranslationConfig, dryRun bool) ApplyResult {
	result := ApplyResult{
		File: config.File,
	}

	if config.File == "" || len(config.Replacements) == 0 {
		result.Skipped = true
		result.SkipReason = "缺少 file 或 replacements 字段"
		return result
	}

	targetPath := i.GetTargetFilePath(config)

	if !Exists(targetPath) {
		result.Skipped = true
		result.SkipReason = "目标文件不存在"
		return result
	}

	contentBytes, err := os.ReadFile(targetPath)
	if err != nil {
		result.Skipped = true
		result.SkipReason = fmt.Sprintf("读取文件失败: %v", err)
		return result
	}
	content := string(contentBytes)
	// 规范化换行符
	content = strings.ReplaceAll(content, "\r\n", "\n")
	originalContent := content

	result.Replacements.Total = len(config.Replacements)

	for find, replace := range config.Replacements {
		// 规范化查找字符串
		normalizedFind := strings.ReplaceAll(find, "\r\n", "\n")

		// 判断是否为简单单词（只包含字母和数字）
		isSimpleWord, _ := regexp.MatchString("^[a-zA-Z0-9]+$", normalizedFind)

		matched := false
		if isSimpleWord {
			// 简单单词使用单词边界
			wordBoundaryPattern := regexp.MustCompile(`\b` + regexp.QuoteMeta(normalizedFind) + `\b`)
			if wordBoundaryPattern.MatchString(content) {
				if !dryRun {
					content = wordBoundaryPattern.ReplaceAllString(content, replace)
				}
				matched = true
			}
		} else {
			// 复杂模式使用普通替换
			if strings.Contains(content, normalizedFind) {
				if !dryRun {
					content = strings.ReplaceAll(content, normalizedFind, replace)
				}
				matched = true
			}
		}

		if matched {
			result.Replacements.Success++
		} else {
			result.Replacements.Failed++
		}
	}

	if !dryRun && content != originalContent {
		if err := os.WriteFile(targetPath, []byte(content), 0644); err != nil {
			result.Success = false
			fmt.Printf("错误: 写入文件失败 %s: %v\n", targetPath, err)
		} else {
			result.Success = result.Replacements.Success > 0
		}
	} else {
		result.Success = result.Replacements.Success > 0
	}

	return result
}
