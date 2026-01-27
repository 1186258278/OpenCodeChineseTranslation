package cmd

import (
	"bufio"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"github.com/spf13/cobra"
)

const DefaultAntigravityEndpoint = "http://127.0.0.1:8045"

var antigravityCmd = &cobra.Command{
	Use:   "antigravity",
	Short: "配置 Antigravity 本地 AI 代理",
	Long:  "Configure Antigravity Tools AI proxy endpoint for OpenCode",
	Run: func(cmd *cobra.Command, args []string) {
		runAntigravity()
	},
}

func init() {
	rootCmd.AddCommand(antigravityCmd)
}

func runAntigravity() {
	fmt.Println("")
	fmt.Println("══════════════════════════════════════════════════")
	fmt.Println("  Antigravity Tools 配置向导")
	fmt.Println("══════════════════════════════════════════════════")
	fmt.Println("")
	fmt.Println("  Antigravity Tools 是本地 AI 模型代理服务")
	fmt.Println("  支持 Claude / GPT / Gemini / DeepSeek 等模型")
	fmt.Printf("  默认端点: %s\n", DefaultAntigravityEndpoint)
	fmt.Println("")

	reader := bufio.NewReader(os.Stdin)

	// 1. Enter endpoint address
	fmt.Println("▶ 步骤 1/3: 配置端点地址")
	fmt.Println("  直接回车使用默认端点，或输入自定义地址")
	fmt.Printf("  端点地址 [%s]: ", DefaultAntigravityEndpoint)

	endpoint, _ := reader.ReadString('\n')
	endpoint = strings.TrimSpace(endpoint)
	if endpoint == "" {
		endpoint = DefaultAntigravityEndpoint
	}

	fmt.Printf("✓ 端点地址: %s\n", endpoint)
	fmt.Println("")

	// 2. Test connection
	fmt.Println("▶ 步骤 2/3: 测试端点连接")
	fmt.Printf("  正在连接 %s...\n", endpoint)

	isOnline := testAntigravityEndpoint(endpoint)
	if !isOnline {
		fmt.Println("✗ 端点无法连接!")
		fmt.Println("")
		fmt.Println("  可能的原因:")
		fmt.Println("    1. Antigravity Tools 服务未启动")
		fmt.Println("    2. 端点地址不正确")
		fmt.Println("    3. 防火墙阻止了连接")
		fmt.Println("")
		fmt.Print("  是否仍要保存配置? [y/N]: ")
		answer, _ := reader.ReadString('\n')
		answer = strings.TrimSpace(strings.ToLower(answer))
		if answer != "y" && answer != "yes" {
			fmt.Println("配置已取消")
			return
		}
	} else {
		fmt.Println("✓ 端点连接成功!")
	}
	fmt.Println("")

	// 3. Optional API Key
	fmt.Println("▶ 步骤 3/3: 配置 API Key (可选)")
	fmt.Println("  本地服务通常无需 API Key，直接回车跳过")
	fmt.Print("  API Key: ")

	apiKey, _ := reader.ReadString('\n')
	apiKey = strings.TrimSpace(apiKey)

	// Confirm configuration
	fmt.Println("")
	fmt.Println("──────────────────────────────────────────────────")
	fmt.Println("  配置预览:")
	fmt.Printf("    端点: %s\n", endpoint)
	if apiKey != "" {
		fmt.Println("    API Key: 已设置 (*****)")
	} else {
		fmt.Println("    API Key: 未设置 (无需认证)")
	}
	fmt.Println("──────────────────────────────────────────────────")
	fmt.Println("")

	fmt.Print("确认保存配置? [Y/n]: ")
	confirm, _ := reader.ReadString('\n')
	confirm = strings.TrimSpace(strings.ToLower(confirm))
	if confirm == "n" || confirm == "no" {
		fmt.Println("配置已取消")
		return
	}

	// Write configuration
	fmt.Println("")
	fmt.Println("▶ 保存配置")

	configPath := getOpencodeConfigPath()

	// Use map[string]interface{} instead of Struct to ensure non-destructive updates
	config := readOpencodeConfigMap(configPath)

	if config["provider"] == nil {
		config["provider"] = make(map[string]interface{})
	}

	// Safely get provider map
	var providers map[string]interface{}
	if p, ok := config["provider"].(map[string]interface{}); ok {
		providers = p
	} else {
		providers = make(map[string]interface{})
	}

	// Configure Antigravity Tools (Gemini)
	geminiBaseURL := fmt.Sprintf("%s/v1beta", endpoint)
	geminiOptions := map[string]interface{}{
		"baseURL": geminiBaseURL,
		"apiKey":  "1",
	}
	if apiKey != "" {
		geminiOptions["apiKey"] = apiKey
	}

	providers["AntigravityToolsGemini"] = map[string]interface{}{
		"npm":     "@ai-sdk/google",
		"name":    "Antigravity (Gemini)",
		"options": geminiOptions,
		"models": map[string]interface{}{
			"gemini-3-pro-high": map[string]interface{}{
				"id":   "gemini-3-pro-high",
				"name": "Gemini 3 Pro High",
				"limit": map[string]int{
					"context": 1000000,
					"output":  20000,
				},
				"attachment": true,
				"modalities": map[string]interface{}{
					"input":  []string{"text", "image"},
					"output": []string{"text"},
				},
			},
			"gemini-3-pro-low": map[string]interface{}{
				"id":   "gemini-3-pro-low",
				"name": "Gemini 3 Pro Low",
				"limit": map[string]int{
					"context": 1000000,
					"output":  20000,
				},
				"attachment": true,
				"modalities": map[string]interface{}{
					"input":  []string{"text", "image"},
					"output": []string{"text"},
				},
			},
		},
	}

	// Configure Antigravity Tools (Claude)
	claudeOptions := map[string]interface{}{
		"baseURL": fmt.Sprintf("%s/v1", endpoint),
		"apiKey":  "1",
	}
	if apiKey != "" {
		claudeOptions["apiKey"] = apiKey
	}

	providers["AntigravityToolsClaude"] = map[string]interface{}{
		"npm":     "@ai-sdk/anthropic",
		"name":    "Antigravity (Claude)",
		"options": claudeOptions,
		"models": map[string]interface{}{
			"claude-opus-4-5-thinking": map[string]interface{}{
				"id":   "claude-opus-4-5-thinking",
				"name": "Claude Opus 4.5 (Thinking)",
				"limit": map[string]int{
					"context": 200000,
					"output":  20000,
				},
				"attachment": true,
				"modalities": map[string]interface{}{
					"input":  []string{"text", "image"},
					"output": []string{"text"},
				},
			},
		},
	}

	// Update provider
	config["provider"] = providers

	// Set default model
	// If the user has not set a model, or the original model is the old antigravity configuration, update it
	currentModel, _ := config["model"].(string)
	if currentModel == "" || strings.HasPrefix(currentModel, "antigravity/") {
		config["model"] = "AntigravityToolsGemini/gemini-3-pro-high"
	}

	if err := writeOpencodeConfigMap(configPath, config); err != nil {
		fmt.Printf("✗ 保存配置失败: %v\n", err)
		return
	}

	fmt.Println("✓ 配置保存成功!")
	fmt.Println("")
	fmt.Println("══════════════════════════════════════════════════")
	fmt.Println("  ✓ Antigravity Tools 配置完成!")
	fmt.Println("══════════════════════════════════════════════════")
	fmt.Println("")
	fmt.Printf("  配置文件: %s\n", configPath)
	fmt.Println("")
	fmt.Println("  已添加 Provider:")
	fmt.Println("    1. AntigravityToolsGemini (推荐)")
	fmt.Println("    2. AntigravityToolsClaude")
	fmt.Println("")
	fmt.Printf("  当前默认模型: %s\n", config["model"])
	fmt.Println("")
	fmt.Println("  下一步操作:")
	fmt.Println("    1. 启动 OpenCode: opencode")
	fmt.Println("    2. 运行 /models 确认模型列表")
	fmt.Println("    3. 开始使用!")
}

func testAntigravityEndpoint(endpoint string) bool {
	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Get(fmt.Sprintf("%s/v1/models", endpoint))
	if err != nil {
		return false
	}
	defer resp.Body.Close()
	return resp.StatusCode == 200
}

func getOpencodeConfigPath() string {
	var configDir string
	homeDir, _ := os.UserHomeDir()

	switch runtime.GOOS {
	case "windows":
		configDir = filepath.Join(homeDir, ".config", "opencode")
	default:
		configDir = filepath.Join(homeDir, ".config", "opencode")
	}

	jsonc := filepath.Join(configDir, "opencode.jsonc")
	if _, err := os.Stat(jsonc); err == nil {
		return jsonc
	}

	return filepath.Join(configDir, "opencode.json")
}

// readOpencodeConfigMap reads config as a map to preserve unknown fields
func readOpencodeConfigMap(path string) map[string]interface{} {
	config := make(map[string]interface{})

	data, err := os.ReadFile(path)
	if err != nil {
		return config
	}

	// Remove comments simply
	content := string(data)
	lines := strings.Split(content, "\n")
	var cleaned []string
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if !strings.HasPrefix(trimmed, "//") {
			cleaned = append(cleaned, line)
		}
	}

	json.Unmarshal([]byte(strings.Join(cleaned, "\n")), &config)
	return config
}

// writeOpencodeConfigMap writes map config
func writeOpencodeConfigMap(path string, config map[string]interface{}) error {
	configDir := filepath.Dir(path)
	if err := os.MkdirAll(configDir, 0755); err != nil {
		return err
	}

	// Ensure schema exists
	if _, ok := config["$schema"]; !ok {
		config["$schema"] = "https://opencode.ai/config.json"
	}

	data, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(path, data, 0644)
}
