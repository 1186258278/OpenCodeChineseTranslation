package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"opencode-cli/internal/core"

	"github.com/spf13/cobra"
)

var updateCmd = &cobra.Command{
	Use:   "update",
	Short: "更新 OpenCode 源码",
	Run: func(cmd *cobra.Command, args []string) {
		repoURL := "https://github.com/anomalyco/opencode.git"
		// 使用 Gitee 镜像加速 (可选，可以通过 flag 控制)
		// repoURL = "https://gitee.com/mirrors/opencode.git"

		opencodeDir, err := core.GetOpencodeDir()
		if err != nil {
			fmt.Printf("错误: 无法获取源码目录: %v\n", err)
			return
		}

		if core.Exists(opencodeDir) {
			fmt.Println("检测到现有源码，正在更新...")
			
			// 检查远程 URL（安全验证）
			currentRemote, err := core.GetGitRemoteURL(opencodeDir)
			if err != nil {
				fmt.Printf("警告: 无法获取远程 URL: %v\n", err)
			} else {
				fmt.Printf("当前远程: %s\n", currentRemote)
				
				// 安全检查：确保不是汉化项目仓库
				if strings.Contains(currentRemote, "OpenCodeChineseTranslation") {
					fmt.Println("❌ 错误: 目标目录似乎是汉化项目仓库，而非 OpenCode 源码目录！")
					fmt.Println("   这可能导致覆盖你的工作。操作已中止。")
					fmt.Printf("   目录: %s\n", opencodeDir)
					fmt.Printf("   远程: %s\n", currentRemote)
					return
				}
			}

			// 暂存更改（如果有）
			if err := core.GitStash(opencodeDir); err != nil {
				fmt.Printf("警告: 暂存失败: %v\n", err)
			}

			// 拉取远程更新
			core.ExecLive("git", "-C", opencodeDir, "fetch", "origin")

			// 尝试切换到 dev 分支
			// 1. 如果本地已有 dev，直接 checkout
			if err := core.GitCheckout(opencodeDir, "dev"); err == nil {
				// 成功切换，拉取最新
				if err := core.GitPull(opencodeDir); err != nil {
					fmt.Printf("警告: 更新 dev 分支失败: %v\n", err)
				}
			} else {
				// 2. 如果本地没有 dev，尝试从 origin/dev 创建
				fmt.Println("正在创建本地 dev 分支...")
				if err := core.ExecLive("git", "-C", opencodeDir, "checkout", "-b", "dev", "origin/dev"); err != nil {
					fmt.Printf("警告: 无法切换到 dev 分支，回退到 main: %v\n", err)
					if err := core.GitCheckout(opencodeDir, "main"); err != nil {
						fmt.Printf("错误: 切换分支失败: %v\n", err)
						return
					}
					core.GitPull(opencodeDir)
				}
			}
			
		} else {
			fmt.Println("正在克隆 OpenCode 源码...")
			fmt.Printf("目标目录: %s\n", opencodeDir)
			
			// 确保父目录存在
			parentDir := filepath.Dir(opencodeDir)
			if err := os.MkdirAll(parentDir, 0755); err != nil {
				fmt.Printf("错误: 创建目录失败: %v\n", err)
				return
			}
			
			if err := core.GitClone(repoURL, opencodeDir); err != nil {
				fmt.Printf("错误: 克隆失败: %v\n", err)
				// 克隆失败，清理目录
				os.RemoveAll(opencodeDir)
				return
			}
		}

		fmt.Println("源码更新完成！")
	},
}

func init() {
	rootCmd.AddCommand(updateCmd)
}
