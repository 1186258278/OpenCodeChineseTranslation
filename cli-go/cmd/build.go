package cmd

import (
	"fmt"
	"opencode-cli/internal/core"

	"github.com/spf13/cobra"
)

var buildCmd = &cobra.Command{
	Use:   "build",
	Short: "编译构建 OpenCode",
	Run: func(cmd *cobra.Command, args []string) {
		platform, _ := cmd.Flags().GetString("platform")
		deploy, _ := cmd.Flags().GetBool("deploy")
		silent, _ := cmd.Flags().GetBool("silent")

		RunBuild(platform, deploy, silent)
	},
}

func init() {
	rootCmd.AddCommand(buildCmd)
	buildCmd.Flags().StringP("platform", "p", "", "Target platform (windows-x64, darwin-arm64, linux-x64)")
	buildCmd.Flags().BoolP("deploy", "d", true, "Deploy to local bin directory")
	buildCmd.Flags().Bool("silent", false, "Suppress output")
}

// RunBuild 供外部调用的构建函数
// platform: 目标平台（如 windows-x64, darwin-arm64, linux-x64），空字符串自动检测
// deploy: 构建后是否部署到本地 bin 目录
// silent: 是否抑制输出
// 返回: 构建错误，nil 表示成功
func RunBuild(platform string, deploy bool, silent bool) error {
	if platform == "" {
		platform = core.DetectPlatform()
	}

	builder, err := core.NewBuilder()
	if err != nil {
		fmt.Printf("错误: 初始化构建器失败: %v\n", err)
		return err
	}

	err = builder.Build(platform, silent)
	if err != nil {
		fmt.Printf("错误: 构建失败: %v\n", err)
		return err
	}

	if deploy {
		err = builder.DeployToLocal(platform, silent)
		if err != nil {
			fmt.Printf("错误: 部署失败: %v\n", err)
			return err
		}
	}

	if !silent {
		fmt.Println("构建完成！")
	}
	return nil
}
