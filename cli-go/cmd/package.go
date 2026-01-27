package cmd

import (
	"fmt"
	"opencode-cli/internal/core"
	"path/filepath"
	"runtime"

	"github.com/spf13/cobra"
)

var packageCmd = &cobra.Command{
	Use:   "package",
	Short: "打包发布版 (支持六平台)",
	Run: func(cmd *cobra.Command, args []string) {
		platform, _ := cmd.Flags().GetString("platform")
		all, _ := cmd.Flags().GetBool("all")
		// skipBinaries, _ := cmd.Flags().GetBool("skip-binaries")

		packager, err := core.NewPackager()
		if err != nil {
			fmt.Printf("错误: 初始化打包器失败: %v\n", err)
			return
		}

		opencodeInfo := core.GetOpencodeInfo()
		fmt.Printf("打包 v%s (基于 OpenCode v%s)\n", core.VERSION, opencodeInfo.Version)

		versionDir := filepath.Join(packager.GetReleasesDir(), fmt.Sprintf("v%s", core.VERSION))
		if err := core.EnsureDir(versionDir); err != nil {
			fmt.Printf("错误: 创建发布目录失败: %v\n", err)
			return
		}

		var platforms []string
		if all {
			// v8.5.0+ 支持的全部 6 个平台
			platforms = []string{
				"windows-x64",
				"windows-arm64",
				"darwin-arm64",
				"darwin-x64",
				"linux-x64",
				"linux-arm64",
			}
		} else if platform != "" {
			platforms = []string{platform}
		} else {
			// 自动识别当前平台
			goos := runtime.GOOS
			goarch := runtime.GOARCH

			// 映射架构名称
			archMap := map[string]string{
				"amd64": "x64",
				"arm64": "arm64",
			}

			targetArch, ok := archMap[goarch]
			if !ok {
				// 默认为 x64，或者直接使用 goarch
				targetArch = "x64"
			}

			// 构建目标名称 (如 windows-x64, linux-arm64)
			target := fmt.Sprintf("%s-%s", goos, targetArch)

			fmt.Printf("提示: 未指定平台，自动识别为: %s\n", target)
			platforms = []string{target}
		}

		var packages []*core.PackageInfo

		for _, p := range platforms {
			pkgInfo, err := packager.PackagePlatform(p, versionDir)
			if err != nil {
				fmt.Printf("打包 %s 失败: %v\n", p, err)
			} else {
				packages = append(packages, pkgInfo)
			}
		}

		if len(packages) > 0 {
			if err := packager.GenerateReleaseNotes(opencodeInfo, packages, versionDir); err != nil {
				fmt.Printf("警告: 生成发布说明失败: %v\n", err)
			} else {
				fmt.Println("生成发布说明: RELEASE_NOTES.md")
			}

			if err := packager.GenerateChecksumsFile(packages, versionDir); err != nil {
				fmt.Printf("警告: 生成校验文件失败: %v\n", err)
			} else {
				fmt.Println("生成校验文件: checksums.txt")
			}
		}

		fmt.Println("\n打包流程结束")
		fmt.Printf("版本目录: %s\n", versionDir)
	},
}

func init() {
	rootCmd.AddCommand(packageCmd)
	packageCmd.Flags().StringP("platform", "p", "", "Target platform")
	packageCmd.Flags().Bool("all", false, "Package all platforms")
	packageCmd.Flags().Bool("skip-binaries", false, "Skip binary packaging")
}
