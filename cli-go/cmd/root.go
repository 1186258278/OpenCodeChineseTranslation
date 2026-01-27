package cmd

import (
	"fmt"
	"os"

	"opencode-cli/internal/core"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:     "opencode-cli",
	Short:   "OpenCode 汉化管理工具",
	Long:    `OpenCode 中文汉化版管理工具 - 更新、汉化、编译、部署一站式解决`,
	Version: core.VERSION,
	Run: func(cmd *cobra.Command, args []string) {
		// 默认启动交互式菜单
		RunMenu()
	},
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
