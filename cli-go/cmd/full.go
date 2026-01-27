package cmd

import (
	"github.com/spf13/cobra"
)

var fullCmd = &cobra.Command{
	Use:   "full",
	Short: "一键全流程 (更新→汉化→验证→编译→部署)",
	Long: `Executes the complete OpenCode Chinese Translation workflow in one go:
1. Clean: Restore source code to original state (git checkout)
2. Update: Pull latest changes from official repository
3. Apply: Apply Chinese translation patches
4. Verify: Verify translation integrity
5. Build: Compile the binary using Bun
6. Deploy: Install to system path`,
	Run: func(cmd *cobra.Command, args []string) {
		runFullWorkflow()
	},
}

func init() {
	rootCmd.AddCommand(fullCmd)
}
