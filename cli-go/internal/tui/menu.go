package tui

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"opencode-cli/internal/core"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// MenuModel BubbleTea 菜单模型
type MenuModel struct {
	Items        []MenuItem
	Tutorials    []Tutorial
	Selected     int
	CurrentTab   int
	Width        int
	Height       int
	Title        string
	Status       StatusInfo
	Quitting     bool
	Result       string
	MenuStartRow int // 菜单区域起始行（用于鼠标定位）
}

// StatusInfo 状态栏信息
type StatusInfo struct {
	Version       string
	Path          string
	SourceExists  bool
	I18nExists    bool
	BinaryExists  bool
	BunVersion    string
	BunRecommend  string
	ScriptUpdate  bool
	SourceUpdate  bool
	CheckComplete bool
}

// StatusUpdateMsg 状态更新消息
type StatusUpdateMsg struct {
	ScriptUpdate  bool
	SourceUpdate  bool
	CheckComplete bool
}

// NewMenuModel 创建新的菜单模型
func NewMenuModel(title string, items []MenuItem, tutorials []Tutorial) MenuModel {
	return MenuModel{
		Title:      title,
		Items:      items,
		Tutorials:  tutorials,
		Selected:   0,
		CurrentTab: 0,
		Width:      MaxWidth,
		Height:     24,
	}
}

// Init 初始化
func (m MenuModel) Init() tea.Cmd {
	// 启动异步版本检测
	return checkUpdateCmd
}

// checkUpdateCmd 异步检测更新
func checkUpdateCmd() tea.Msg {
	scriptUpdate := checkScriptUpdate()
	sourceUpdate := checkSourceUpdate()
	return StatusUpdateMsg{
		ScriptUpdate:  scriptUpdate,
		SourceUpdate:  sourceUpdate,
		CheckComplete: true,
	}
}

// checkScriptUpdate 检测脚本更新
func checkScriptUpdate() bool {
	// 检测汉化项目是否有新版本
	projectDir, err := getProjectDir()
	if err != nil {
		return false
	}
	return checkGitUpdate(projectDir)
}

// checkSourceUpdate 检测源码更新
func checkSourceUpdate() bool {
	// 检测 OpenCode 源码是否有新版本
	opencodeDir, err := getOpencodeDir()
	if err != nil {
		return false
	}
	return checkGitUpdate(opencodeDir)
}

// checkGitUpdate 检查 Git 仓库是否有更新
func checkGitUpdate(dir string) bool {
	if dir == "" {
		return false
	}

	// 检查目录是否存在
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		return false
	}

	// 切换到目录
	oldDir, _ := os.Getwd()
	defer os.Chdir(oldDir)

	if err := os.Chdir(dir); err != nil {
		return false
	}

	// git fetch --quiet
	fetchCmd := exec.Command("git", "fetch", "--quiet")
	fetchCmd.Dir = dir
	// 显式静默：防止任何后台输出破坏 TUI 界面
	fetchCmd.Stdout = nil
	fetchCmd.Stderr = nil
	fetchCmd.Run() // 忽略错误，如果没网等情况

	// 优先检查 origin/dev (开发分支)，其次 origin/main
	target := "origin/dev"
	// 检查 origin/dev 是否存在
	if err := exec.Command("git", "-C", dir, "rev-parse", "--verify", "origin/dev").Run(); err != nil {
		target = "origin/main"
	}

	// git rev-list --count HEAD..target
	revCmd := exec.Command("git", "rev-list", "--count", "HEAD.."+target)
	revCmd.Dir = dir
	output, err := revCmd.Output()
	if err != nil {
		return false
	}

	count := strings.TrimSpace(string(output))
	return count != "0" && count != ""
}

// getProjectDir 获取项目目录
func getProjectDir() (string, error) {
	// 直接复用 core 包的实现
	return core.GetProjectDir()
}

// getOpencodeDir 获取 OpenCode 源码目录
func getOpencodeDir() (string, error) {
	// 直接复用 core 包的实现
	return core.GetOpencodeDir()
}

// calculateMenuStartRow 计算菜单区域的起始行
func (m MenuModel) calculateMenuStartRow() int {
	// 计算视图中菜单内容开始的行数
	// 1 顶边框 + 1 标题 + 1 分隔线 + 3 状态行 + 1 分隔线 + 1 空行 = 8
	contentStartRow := 8

	// 计算总行数来确定垂直居中偏移
	rowCount := (len(m.Items) + Columns - 1) / Columns
	// 估算总高度: 8 + 菜单行*2-1 + 空行 + 分隔线 + 描述2行 + 教程区(1+1+5) + 分隔线 + 提示 + 底边框
	// 简化为直接计算
	totalLines := 8 + rowCount*2 - 1 + 1 + 1 + 2 + 7 + 1 + 1 + 1 // 约 22-28 行

	verticalPadding := (m.Height - totalLines) / 2
	if verticalPadding < 0 {
		verticalPadding = 0
	}

	return verticalPadding + contentStartRow
}

// Update 更新状态
func (m MenuModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		// 修复：忽略无效的窗口尺寸 (Windows 后台运行时可能会发送 0x0)
		if msg.Width <= 0 || msg.Height <= 0 {
			return m, nil
		}
		m.Width = msg.Width
		m.Height = msg.Height
		m.MenuStartRow = m.calculateMenuStartRow()
		return m, nil

	case StatusUpdateMsg:
		m.Status.ScriptUpdate = msg.ScriptUpdate
		m.Status.SourceUpdate = msg.SourceUpdate
		m.Status.CheckComplete = msg.CheckComplete
		return m, nil

	case tea.MouseMsg:
		// 更新菜单起始行
		m.MenuStartRow = m.calculateMenuStartRow()

		// 处理鼠标事件
		if msg.Action == tea.MouseActionPress || msg.Action == tea.MouseActionMotion {
			if msg.Button == tea.MouseButtonLeft {
				// 计算点击位置对应的菜单项
				inner := MaxWidth - 2
				cellW := inner / Columns

				// 计算居中偏移
				leftPadding := (m.Width - MaxWidth) / 2
				if leftPadding < 0 {
					leftPadding = 0
				}

				// 调整 X 坐标（减去左侧填充和边框）
				adjustedX := msg.X - leftPadding - 1

				// 计算列
				col := adjustedX / cellW
				if col < 0 {
					col = 0
				}
				if col >= Columns {
					col = Columns - 1
				}

				// 计算行（菜单区域从 MenuStartRow 开始）
				row := msg.Y - m.MenuStartRow
				if row >= 0 {
					menuRow := row / 2 // 每项占2行（含空行）
					idx := menuRow*Columns + col
					if idx >= 0 && idx < len(m.Items) {
						m.Selected = idx
					}
				}
			} else if msg.Button == tea.MouseButtonWheelUp {
				m.moveUp()
			} else if msg.Button == tea.MouseButtonWheelDown {
				m.moveDown()
			} else if msg.Button == tea.MouseButtonWheelLeft {
				m.moveLeft()
			} else if msg.Button == tea.MouseButtonWheelRight {
				m.moveRight()
			}
		}
		return m, nil

	case tea.KeyMsg:
		switch msg.String() {
		case "q", "esc":
			m.Quitting = true
			m.Result = "exit"
			return m, tea.Quit

		case "enter":
			m.Result = m.Items[m.Selected].Value
			return m, tea.Quit

		case "up", "k":
			m.moveUp()
		case "down", "j":
			m.moveDown()
		case "left", "h":
			m.moveLeft()
		case "right", "l":
			m.moveRight()

		case "tab":
			if len(m.Tutorials) > 0 {
				m.CurrentTab = (m.CurrentTab + 1) % len(m.Tutorials)
			}

		// 数字快捷键
		case "1", "2", "3", "4", "5", "6", "7", "8", "9":
			idx := int(msg.String()[0] - '1')
			if idx < len(m.Items) {
				m.Result = m.Items[idx].Value
				return m, tea.Quit
			}

		// 添加手动刷新快捷键
		case "ctrl+l":
			return m, tea.ClearScreen
		}
	}
	return m, nil
}

func (m *MenuModel) moveUp() {
	if m.Selected >= Columns {
		m.Selected -= Columns
	} else {
		lastRow := (len(m.Items) - 1) / Columns
		newPos := lastRow*Columns + m.Selected%Columns
		if newPos >= len(m.Items) {
			newPos = len(m.Items) - 1
		}
		m.Selected = newPos
	}
}

func (m *MenuModel) moveDown() {
	if m.Selected+Columns < len(m.Items) {
		m.Selected += Columns
	} else {
		m.Selected = m.Selected % Columns
	}
}

func (m *MenuModel) moveLeft() {
	if m.Selected > 0 {
		m.Selected--
	} else {
		m.Selected = len(m.Items) - 1
	}
}

func (m *MenuModel) moveRight() {
	if m.Selected < len(m.Items)-1 {
		m.Selected++
	} else {
		m.Selected = 0
	}
}

// View 渲染视图
func (m MenuModel) View() string {
	if m.Quitting {
		return ""
	}

	var lines []string
	inner := MaxWidth - 2
	cellW := inner / Columns

	// 边框样式
	borderColor := lipgloss.NewStyle().Foreground(Cyan)

	// 创建边框辅助函数
	hLine := func(left, fill, right string) string {
		return borderColor.Render(left + strings.Repeat(fill, inner) + right)
	}

	vLine := func(content string) string {
		// 计算内容宽度并填充
		contentWidth := lipgloss.Width(content)
		padding := inner - contentWidth
		if padding < 0 {
			padding = 0
		}
		return borderColor.Render(Vertical) + content + strings.Repeat(" ", padding) + borderColor.Render(Vertical)
	}

	vLineCenter := func(content string) string {
		contentWidth := lipgloss.Width(content)
		left := (inner - contentWidth) / 2
		right := inner - contentWidth - left
		if left < 0 {
			left = 0
		}
		if right < 0 {
			right = 0
		}
		return borderColor.Render(Vertical) + strings.Repeat(" ", left) + content + strings.Repeat(" ", right) + borderColor.Render(Vertical)
	}

	// ════════ 顶部边框 ════════
	lines = append(lines, hLine(TopLeft, Horizontal, TopRight))

	// ════════ 标题 ════════
	title := TitleStyle.Render(m.Title)
	lines = append(lines, vLineCenter(title))

	// ════════ 分隔线 ════════
	lines = append(lines, hLine(LeftTee, Horizontal, RightTee))

	// ════════ 状态区 ════════
	statusLines := m.renderStatus()
	for _, line := range statusLines {
		lines = append(lines, vLine(" "+line))
	}

	// ════════ 分隔线 ════════
	lines = append(lines, hLine(LeftTee, Horizontal, RightTee))

	// ════════ 空行 ════════
	lines = append(lines, vLine(""))

	// 记录菜单区域起始行
	menuStartRow := len(lines)

	// ════════ 菜单网格 ════════
	rowCount := (len(m.Items) + Columns - 1) / Columns
	for r := 0; r < rowCount; r++ {
		var rowStr strings.Builder
		for c := 0; c < Columns; c++ {
			idx := r*Columns + c
			if idx < len(m.Items) {
				item := m.Items[idx]
				text := fmt.Sprintf("%s %s", item.Key, item.Name)
				text = truncateText(text, cellW-2)
				text = padRight(text, cellW-1)

				if idx == m.Selected {
					rowStr.WriteString(SelectedStyle.Render(" " + text))
				} else {
					rowStr.WriteString(NormalStyle.Render(" " + text))
				}
			} else {
				rowStr.WriteString(strings.Repeat(" ", cellW))
			}
		}
		lines = append(lines, vLine(rowStr.String()))

		// 菜单项之间的空行
		if r < rowCount-1 {
			lines = append(lines, vLine(""))
		}
	}

	// ════════ 空行 ════════
	lines = append(lines, vLine(""))

	// ════════ 描述区分隔线 ════════
	lines = append(lines, hLine(LeftTee, Horizontal, RightTee))

	// ════════ 描述区 ════════
	desc := m.Items[m.Selected].Desc
	descLines := wrapText(desc, inner-4)
	for i := 0; i < 2; i++ {
		var line string
		if i < len(descLines) {
			line = descLines[i]
		}
		lines = append(lines, vLineCenter(DescStyle.Render(line)))
	}

	// ════════ 教程区 ════════
	if len(m.Tutorials) > 0 {
		lines = append(lines, hLine(LeftTee, Horizontal, RightTee))

		// Tabs
		var tabStr strings.Builder
		for i, t := range m.Tutorials {
			if i == m.CurrentTab {
				tabStr.WriteString(SelectedStyle.Render(" " + t.Title + " "))
				tabStr.WriteString(" ")
			} else {
				tabStr.WriteString(DimStyle.Render(" " + t.Title + " "))
				tabStr.WriteString(" ")
			}
		}
		lines = append(lines, vLine(" "+tabStr.String()))

		// 教程内容
		tutorial := m.Tutorials[m.CurrentTab]
		maxLines := 5
		for i := 0; i < maxLines; i++ {
			var line string
			if i < len(tutorial.Content) {
				line = tutorial.Content[i]
			}
			lines = append(lines, vLine(" "+line))
		}
	}

	// ════════ 底部提示分隔线 ════════
	lines = append(lines, hLine(LeftTee, Horizontal, RightTee))

	// ════════ 底部提示 ════════
	hint := "↑↓←→ 移动 │ Enter 确认 │ 1-9 快捷 │ Q 退出 │ Tab 切换教程"
	lines = append(lines, vLineCenter(DimStyle.Render(hint)))

	// ════════ 底部边框 ════════
	lines = append(lines, hLine(BottomLeft, Horizontal, BottomRight))

	// 组合所有行
	content := strings.Join(lines, "\n")

	// 使用 lipgloss 居中放置
	// 关键修复: 高度减 1，防止 Windows 终端触底自动滚动导致界面错位
	renderHeight := m.Height
	if renderHeight > 0 {
		renderHeight = renderHeight - 1
	}

	style := lipgloss.NewStyle().
		Width(m.Width).
		Height(renderHeight).
		Align(lipgloss.Center, lipgloss.Center)

	// 更新菜单起始行（考虑居中后的偏移）
	// 注意：这里使用 renderHeight 进行计算
	verticalPadding := (renderHeight - len(lines)) / 2
	if verticalPadding < 0 {
		verticalPadding = 0
	}
	m.MenuStartRow = verticalPadding + menuStartRow

	return style.Render(content)
}

// renderStatus 渲染状态栏
func (m MenuModel) renderStatus() []string {
	var lines []string

	// 第一行：版本和路径
	version := m.Status.Version
	if version == "" {
		version = "v" + core.VERSION
	}
	path := m.Status.Path
	if path == "" {
		path = "..."
	}
	if len(path) > 35 {
		path = "..." + path[len(path)-32:]
	}
	line1 := StatusStyle.Render("版本") + " " + version + "  " + StatusStyle.Render("路径") + " " + path
	lines = append(lines, line1)

	// 第二行：状态
	var srcStatus, i18nStatus, binStatus, bunStatus string

	if m.Status.SourceExists {
		srcStatus = SuccessStyle.Render("✓源码")
	} else {
		srcStatus = ErrorStyle.Render("✗源码")
	}

	if m.Status.I18nExists {
		i18nStatus = SuccessStyle.Render("✓汉化")
	} else {
		i18nStatus = ErrorStyle.Render("✗汉化")
	}

	if m.Status.BinaryExists {
		binStatus = SuccessStyle.Render("✓已编译")
	} else {
		binStatus = WarnStyle.Render("○未编译")
	}

	if m.Status.BunVersion != "" {
		if m.Status.BunVersion == m.Status.BunRecommend {
			bunStatus = SuccessStyle.Render("✓ Bun v" + m.Status.BunVersion)
		} else {
			bunStatus = ErrorStyle.Render("! Bun v" + m.Status.BunVersion + " (推荐 " + m.Status.BunRecommend + ")")
		}
	} else {
		bunStatus = ErrorStyle.Render("✗ Bun未安装")
	}

	line2 := srcStatus + "  " + i18nStatus + "  " + binStatus + "  " + bunStatus
	lines = append(lines, line2)

	// 第三行：更新状态
	if !m.Status.CheckComplete {
		lines = append(lines, DimStyle.Render("○ 检测更新中..."))
	} else {
		var updates []string
		if m.Status.ScriptUpdate {
			updates = append(updates, WarnStyle.Render("● 汉化脚本可更新"))
		} else {
			updates = append(updates, SuccessStyle.Render("✓ 汉化脚本最新"))
		}
		if m.Status.SourceUpdate {
			updates = append(updates, WarnStyle.Render("● OpenCode可更新"))
		} else {
			updates = append(updates, SuccessStyle.Render("✓ OpenCode最新"))
		}
		lines = append(lines, strings.Join(updates, "  "))
	}

	return lines
}

// 辅助函数

func padRight(s string, width int) string {
	textWidth := lipgloss.Width(s)
	if textWidth >= width {
		return s
	}
	return s + strings.Repeat(" ", width-textWidth)
}

func truncateText(s string, maxWidth int) string {
	if lipgloss.Width(s) <= maxWidth {
		return s
	}
	runes := []rune(s)
	for i := len(runes) - 1; i >= 0; i-- {
		test := string(runes[:i]) + ".."
		if lipgloss.Width(test) <= maxWidth {
			return test
		}
	}
	return ".."
}

func wrapText(s string, width int) []string {
	if lipgloss.Width(s) <= width {
		return []string{s}
	}

	var lines []string
	runes := []rune(s)
	var current []rune

	for _, r := range runes {
		current = append(current, r)
		if lipgloss.Width(string(current)) > width {
			lines = append(lines, string(current[:len(current)-1]))
			current = []rune{r}
		}
	}
	if len(current) > 0 {
		lines = append(lines, string(current))
	}

	return lines
}

// Run 运行菜单并返回选择结果
func Run(title string, items []MenuItem, tutorials []Tutorial, status StatusInfo) (string, error) {
	model := NewMenuModel(title, items, tutorials)
	model.Status = status

	p := tea.NewProgram(model,
		tea.WithAltScreen(),
		tea.WithMouseCellMotion(),
	)
	finalModel, err := p.Run()
	if err != nil {
		return "", err
	}

	m := finalModel.(MenuModel)
	return m.Result, nil
}
