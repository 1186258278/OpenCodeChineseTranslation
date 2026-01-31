package core

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// ========== LoadI18nConfig 测试 ==========

func TestLoadI18nConfig_ValidJSON(t *testing.T) {
	// 创建临时测试文件
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "test-config.json")
	
	content := `{
		"file": "src/app.tsx",
		"replacements": {
			"Hello": "你好",
			"World": "世界"
		}
	}`
	if err := os.WriteFile(configPath, []byte(content), 0644); err != nil {
		t.Fatalf("创建测试文件失败: %v", err)
	}
	
	config, err := LoadI18nConfig(configPath)
	if err != nil {
		t.Fatalf("LoadI18nConfig 失败: %v", err)
	}
	
	if config.File != "src/app.tsx" {
		t.Errorf("File 字段错误: got %q, want %q", config.File, "src/app.tsx")
	}
	
	if len(config.Replacements) != 2 {
		t.Errorf("Replacements 数量错误: got %d, want 2", len(config.Replacements))
	}
	
	if config.Replacements["Hello"] != "你好" {
		t.Errorf("Replacements[Hello] 错误: got %q, want %q", config.Replacements["Hello"], "你好")
	}
}

func TestLoadI18nConfig_FileNotExist(t *testing.T) {
	_, err := LoadI18nConfig("/nonexistent/path/config.json")
	if err == nil {
		t.Error("期望返回错误，但得到 nil")
	}
}

func TestLoadI18nConfig_InvalidJSON(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "invalid.json")
	
	// 无效的 JSON 内容
	if err := os.WriteFile(configPath, []byte("{ invalid json }"), 0644); err != nil {
		t.Fatalf("创建测试文件失败: %v", err)
	}
	
	_, err := LoadI18nConfig(configPath)
	if err == nil {
		t.Error("期望返回错误，但得到 nil")
	}
}

func TestLoadI18nConfig_EmptyFile(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "empty.json")
	
	if err := os.WriteFile(configPath, []byte("{}"), 0644); err != nil {
		t.Fatalf("创建测试文件失败: %v", err)
	}
	
	config, err := LoadI18nConfig(configPath)
	if err != nil {
		t.Fatalf("LoadI18nConfig 失败: %v", err)
	}
	
	if config.File != "" {
		t.Errorf("空 JSON 的 File 应为空字符串, got %q", config.File)
	}
	
	if config.Replacements != nil && len(config.Replacements) != 0 {
		t.Errorf("空 JSON 的 Replacements 应为空")
	}
}

// ========== GetReplacementsList 测试 ==========

func TestGetReplacementsList_Empty(t *testing.T) {
	config := TranslationConfig{
		Replacements: map[string]string{},
	}
	
	list := config.GetReplacementsList()
	if len(list) != 0 {
		t.Errorf("期望空列表, got %d 项", len(list))
	}
}

func TestGetReplacementsList_Multiple(t *testing.T) {
	config := TranslationConfig{
		Replacements: map[string]string{
			"Hello":  "你好",
			"World":  "世界",
			"OpenCode": "开放代码",
		},
	}
	
	list := config.GetReplacementsList()
	if len(list) != 3 {
		t.Errorf("期望 3 项, got %d 项", len(list))
	}
	
	// 验证所有替换规则都在列表中
	found := make(map[string]bool)
	for _, r := range list {
		found[r.From] = true
		if config.Replacements[r.From] != r.To {
			t.Errorf("替换规则不匹配: From=%q, To=%q, expected=%q", 
				r.From, r.To, config.Replacements[r.From])
		}
	}
	
	for key := range config.Replacements {
		if !found[key] {
			t.Errorf("缺少替换规则: %q", key)
		}
	}
}

// ========== GetTargetFilePath 测试 ==========

func TestGetTargetFilePath_WithPackagesPrefix(t *testing.T) {
	i18n := &I18n{
		opencodeDir: "/home/user/opencode",
	}
	
	config := TranslationConfig{
		File: "packages/opencode/src/app.tsx",
	}
	
	result := i18n.GetTargetFilePath(config)
	expected := filepath.Join("/home/user/opencode", "packages/opencode/src/app.tsx")
	
	if result != expected {
		t.Errorf("路径不匹配: got %q, want %q", result, expected)
	}
}

func TestGetTargetFilePath_WithoutPackagesPrefix(t *testing.T) {
	i18n := &I18n{
		opencodeDir: "/home/user/opencode",
	}
	
	config := TranslationConfig{
		File: "src/components/Dialog.tsx",
	}
	
	result := i18n.GetTargetFilePath(config)
	// 应该自动添加 packages/opencode/ 前缀
	if !strings.Contains(result, "packages") || !strings.Contains(result, "opencode") {
		t.Errorf("应该包含 packages/opencode 前缀: got %q", result)
	}
}

func TestGetTargetFilePath_EmptyFile(t *testing.T) {
	i18n := &I18n{
		opencodeDir: "/home/user/opencode",
	}
	
	config := TranslationConfig{
		File: "",
	}
	
	result := i18n.GetTargetFilePath(config)
	if result != "" {
		t.Errorf("空 File 应返回空字符串, got %q", result)
	}
}

// ========== ApplyConfig 测试 ==========

func TestApplyConfig_DryRun(t *testing.T) {
	tmpDir := t.TempDir()
	
	// 创建目标文件
	targetPath := filepath.Join(tmpDir, "packages", "opencode", "src", "app.tsx")
	if err := os.MkdirAll(filepath.Dir(targetPath), 0755); err != nil {
		t.Fatalf("创建目录失败: %v", err)
	}
	if err := os.WriteFile(targetPath, []byte("Hello World"), 0644); err != nil {
		t.Fatalf("创建目标文件失败: %v", err)
	}
	
	i18n := &I18n{
		opencodeDir: tmpDir,
	}
	
	config := TranslationConfig{
		File: "packages/opencode/src/app.tsx",
		Replacements: map[string]string{
			"Hello": "你好",
		},
	}
	
	// Dry run 模式
	result := i18n.ApplyConfig(config, true)
	
	if result.Skipped {
		t.Errorf("不应该跳过: %s", result.SkipReason)
	}
	
	if result.Replacements.Success != 1 {
		t.Errorf("应该有 1 个成功替换, got %d", result.Replacements.Success)
	}
	
	// 验证文件内容未改变（dry run）
	content, _ := os.ReadFile(targetPath)
	if string(content) != "Hello World" {
		t.Errorf("Dry run 不应修改文件, got %q", string(content))
	}
}

func TestApplyConfig_ActualReplace(t *testing.T) {
	tmpDir := t.TempDir()
	
	// 创建目标文件
	targetPath := filepath.Join(tmpDir, "packages", "opencode", "src", "app.tsx")
	if err := os.MkdirAll(filepath.Dir(targetPath), 0755); err != nil {
		t.Fatalf("创建目录失败: %v", err)
	}
	if err := os.WriteFile(targetPath, []byte("Hello World"), 0644); err != nil {
		t.Fatalf("创建目标文件失败: %v", err)
	}
	
	i18n := &I18n{
		opencodeDir: tmpDir,
	}
	
	config := TranslationConfig{
		File: "packages/opencode/src/app.tsx",
		Replacements: map[string]string{
			"Hello": "你好",
			"World": "世界",
		},
	}
	
	// 实际替换
	result := i18n.ApplyConfig(config, false)
	
	if !result.Success {
		t.Error("替换应该成功")
	}
	
	if result.Replacements.Success != 2 {
		t.Errorf("应该有 2 个成功替换, got %d", result.Replacements.Success)
	}
	
	// 验证文件内容已改变
	content, _ := os.ReadFile(targetPath)
	if string(content) != "你好 世界" {
		t.Errorf("文件内容不正确, got %q, want %q", string(content), "你好 世界")
	}
}

func TestApplyConfig_FileNotExist(t *testing.T) {
	i18n := &I18n{
		opencodeDir: "/nonexistent/path",
	}
	
	config := TranslationConfig{
		File: "packages/opencode/src/app.tsx",
		Replacements: map[string]string{
			"Hello": "你好",
		},
	}
	
	result := i18n.ApplyConfig(config, false)
	
	if !result.Skipped {
		t.Error("目标文件不存在时应该跳过")
	}
	
	if result.SkipReason != "目标文件不存在" {
		t.Errorf("跳过原因不正确: %q", result.SkipReason)
	}
}

func TestApplyConfig_EmptyFile(t *testing.T) {
	i18n := &I18n{
		opencodeDir: "/some/path",
	}
	
	config := TranslationConfig{
		File: "",
		Replacements: map[string]string{
			"Hello": "你好",
		},
	}
	
	result := i18n.ApplyConfig(config, false)
	
	if !result.Skipped {
		t.Error("空 File 时应该跳过")
	}
}

func TestApplyConfig_EmptyReplacements(t *testing.T) {
	i18n := &I18n{
		opencodeDir: "/some/path",
	}
	
	config := TranslationConfig{
		File:         "src/app.tsx",
		Replacements: map[string]string{},
	}
	
	result := i18n.ApplyConfig(config, false)
	
	if !result.Skipped {
		t.Error("空 Replacements 时应该跳过")
	}
}

func TestApplyConfig_NoMatch(t *testing.T) {
	tmpDir := t.TempDir()
	
	// 创建目标文件
	targetPath := filepath.Join(tmpDir, "packages", "opencode", "src", "app.tsx")
	if err := os.MkdirAll(filepath.Dir(targetPath), 0755); err != nil {
		t.Fatalf("创建目录失败: %v", err)
	}
	if err := os.WriteFile(targetPath, []byte("Goodbye World"), 0644); err != nil {
		t.Fatalf("创建目标文件失败: %v", err)
	}
	
	i18n := &I18n{
		opencodeDir: tmpDir,
	}
	
	config := TranslationConfig{
		File: "packages/opencode/src/app.tsx",
		Replacements: map[string]string{
			"Hello": "你好",  // 文件中不存在 "Hello"
		},
	}
	
	result := i18n.ApplyConfig(config, false)
	
	if result.Replacements.Success != 0 {
		t.Errorf("不应有成功匹配, got %d", result.Replacements.Success)
	}
	
	if result.Replacements.Failed != 1 {
		t.Errorf("应有 1 个失败匹配, got %d", result.Replacements.Failed)
	}
}

func TestApplyConfig_CRLFNormalization(t *testing.T) {
	tmpDir := t.TempDir()
	
	// 创建包含 CRLF 换行的目标文件
	targetPath := filepath.Join(tmpDir, "packages", "opencode", "src", "app.tsx")
	if err := os.MkdirAll(filepath.Dir(targetPath), 0755); err != nil {
		t.Fatalf("创建目录失败: %v", err)
	}
	if err := os.WriteFile(targetPath, []byte("Hello\r\nWorld"), 0644); err != nil {
		t.Fatalf("创建目标文件失败: %v", err)
	}
	
	i18n := &I18n{
		opencodeDir: tmpDir,
	}
	
	config := TranslationConfig{
		File: "packages/opencode/src/app.tsx",
		Replacements: map[string]string{
			"Hello\nWorld": "你好\n世界",  // 使用 LF 换行
		},
	}
	
	result := i18n.ApplyConfig(config, false)
	
	// 应该能够匹配（因为 CRLF 会被规范化为 LF）
	if result.Replacements.Success != 1 {
		t.Errorf("CRLF 应该被规范化后匹配, got success=%d, failed=%d", 
			result.Replacements.Success, result.Replacements.Failed)
	}
}

// ========== 辅助函数测试 ==========

func TestDirExists(t *testing.T) {
	tmpDir := t.TempDir()
	
	if !DirExists(tmpDir) {
		t.Errorf("DirExists 应返回 true for %q", tmpDir)
	}
	
	if DirExists(filepath.Join(tmpDir, "nonexistent")) {
		t.Error("DirExists 应返回 false for 不存在的目录")
	}
	
	// 测试文件（非目录）
	filePath := filepath.Join(tmpDir, "file.txt")
	os.WriteFile(filePath, []byte("test"), 0644)
	if DirExists(filePath) {
		t.Error("DirExists 应返回 false for 文件")
	}
}

func TestExists(t *testing.T) {
	tmpDir := t.TempDir()
	
	filePath := filepath.Join(tmpDir, "test.txt")
	os.WriteFile(filePath, []byte("test"), 0644)
	
	if !Exists(filePath) {
		t.Errorf("Exists 应返回 true for %q", filePath)
	}
	
	if Exists(filepath.Join(tmpDir, "nonexistent.txt")) {
		t.Error("Exists 应返回 false for 不存在的文件")
	}
}
