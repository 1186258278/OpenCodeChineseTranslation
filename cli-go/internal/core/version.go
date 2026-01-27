package core

import (
	"fmt"
	"path/filepath"
	"strings"
)

const (
	VERSION  = "8.6.0"
	APP_NAME = "OpenCode 汉化管理工具"
)

// OpencodeInfo 包含 OpenCode 源码的版本信息
type OpencodeInfo struct {
	Version    string
	BunVersion string
	Commit     string
	CommitDate string
}

// GetOpencodeInfo 获取 OpenCode 版本信息
func GetOpencodeInfo() OpencodeInfo {
	info := OpencodeInfo{
		Version:    "unknown",
		BunVersion: "unknown",
		Commit:     "unknown",
		CommitDate: "unknown",
	}

	opencodeDir, err := GetOpencodeDir()
	if err != nil {
		return info
	}

	// 读取 package.json 获取 bun 版本
	type PackageJSON struct {
		PackageManager string `json:"packageManager"`
		Version        string `json:"version"`
	}

	rootPkgPath := filepath.Join(opencodeDir, "package.json")
	var rootPkg PackageJSON
	if err := ReadJSON(rootPkgPath, &rootPkg); err == nil {
		parts := strings.Split(rootPkg.PackageManager, "@")
		if len(parts) > 1 {
			info.BunVersion = parts[1]
		}
	}

	// 读取 packages/opencode/package.json 获取 opencode 版本
	appPkgPath := filepath.Join(opencodeDir, "packages", "opencode", "package.json")
	var appPkg PackageJSON
	if err := ReadJSON(appPkgPath, &appPkg); err == nil {
		info.Version = appPkg.Version
	}

	// 获取 git 信息
	if out, err := Exec("git", "-C", opencodeDir, "rev-parse", "--short", "HEAD"); err == nil {
		info.Commit = out
	}
	if out, err := Exec("git", "-C", opencodeDir, "log", "-1", "--format=%ci"); err == nil {
		info.CommitDate = strings.Split(out, " ")[0]
	}

	return info
}

// GetOpencodeChangelog 获取 OpenCode 更新日志
func GetOpencodeChangelog(limit int) string {
	opencodeDir, err := GetOpencodeDir()
	if err != nil {
		return "- 无法获取更新日志 (源码目录不存在)"
	}

	// 尝试获取最新数据（忽略错误，因为可能离线）
	Exec("git", "-C", opencodeDir, "fetch", "--quiet")

	// 优先查看 origin/dev (官方开发分支)，其次 origin/main，最后本地 HEAD
	target := "HEAD"
	if _, err := Exec("git", "-C", opencodeDir, "rev-parse", "--verify", "origin/dev"); err == nil {
		target = "origin/dev"
	} else if _, err := Exec("git", "-C", opencodeDir, "rev-parse", "--verify", "origin/main"); err == nil {
		target = "origin/main"
	}

	out, err := Exec("git", "-C", opencodeDir, "log", target, "-n", fmt.Sprintf("%d", limit), "--format=- %s ([%h](https://github.com/anomalyco/opencode/commit/%H))")

	if err != nil {
		return fmt.Sprintf("- 无法获取更新日志: %v", err)
	}
	if strings.TrimSpace(out) == "" {
		return "- 暂无更新日志"
	}

	header := fmt.Sprintf("显示 %s 分支的最近更新:\n", target)
	return header + out
}
