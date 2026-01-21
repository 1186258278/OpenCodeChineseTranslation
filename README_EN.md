# OpenCode Chinese Translation Project

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-v7.0-green.svg)](scripts/package.json)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-blue.svg)](#)

[Chinese Documentation](README.md)

---

## Project Overview

**OpenCode Chinese Translation** is a localized and enhanced distribution of the open-source AI coding agent [OpenCode](https://github.com/anomalyco/opencode). This project aims to lower the barrier for developers by providing full Chinese localization, automated build workflows, and optimizations for the domestic network environment.

With the built-in `opencodenpm` management tool, you can easily update source code, apply translation patches, build binaries, and package releases for multiple platforms.

### Key Features

*   **Complete Localization**: Covers TUI, dialogs, messages, and core workflows.
*   **Automated Workflow**: One-click script for updating, localizing, verifying, and building.
*   **Multi-Platform Support**: Fully supports Windows, macOS, and Linux.
*   **Plugin Integration**: Built-in setup wizards for Oh-My-OpenCode and Antigravity, unlocking multi-agent collaboration and local model support.
*   **Professional CLI**: Provides an intuitive TUI interactive menu.

## Screenshots

<p align="center">
  <img src="docs/0-1.png" alt="Management Tool Main Interface" width="800">
</p>

<p align="center">
  <img src="docs/1-1.png" alt="MCP Server Localization" width="45%">
  <img src="docs/2-2.png" alt="Status Dialog Localization" width="45%">
</p>

---

## Quick Start

### 1. Prerequisites

Before starting, ensure your environment meets the following requirements:

*   **Node.js**: >= 18.0.0
*   **Bun**: >= 1.3.0 (for fast building)
*   **Git**: Latest version

### 2. Install Management Tool

It is recommended to install `opencodenpm` globally.

```bash
# Go to scripts directory
cd scripts

# Install dependencies and link command
npm install
npm link
```

### 3. Run Interactive Menu

After installation, run the following command in your terminal:

```bash
opencodenpm
```

You will see a grid-based interactive menu. Use arrow keys or number keys to select functions.

---

## Command Reference

Besides the interactive menu, `opencodenpm` supports rich CLI arguments for CI/CD integration.

| Command | Args | Description |
|---------|------|-------------|
| **full** | `-y, --auto` | Run full workflow (update->apply->build). `--auto` skips confirmation |
| **update** | `-f, --force` | Update source code. `--force` to re-clone |
| **apply** | `-b, --backup`<br>`-r, --report` | Apply translation. `-b` backup source, `-r` generate report |
| **build** | `-p <platform>` | Build binary. Platforms: `windows-x64`, `linux-x64`, `darwin-arm64` |
| **verify** | `-d, --detailed` | Verify coverage and config integrity |
| **deploy** | - | Deploy `opencode` and `opencodenpm` to system PATH |
| **rollback** | `-l, --list`<br>`-i <id>` | Rollback backup. `-l` list backups, `-i` rollback to specific ID |
| **package** | `-a, --all`<br>`-p <platform>` | Package release ZIP. `-a` for all platforms |
| **launch** | `-b, --background` | Launch OpenCode. `-b` run in background |
| **antigravity** | - | Configure Antigravity local AI gateway |
| **ohmyopencode** | - | Install Oh-My-OpenCode plugin |
| **helper** | `-i, --install` | Install/Launch Coding Helper |
| **env** | - | Check development environment |

**Examples:**

```bash
# Force update source and apply translation
opencodenpm update --force
opencodenpm apply

# Build for Linux
opencodenpm build -p linux-x64

# Deploy global commands
opencodenpm deploy
```

---

## Documentation

*   [📅 Changelog](CHANGELOG.md)
*   [🚀 Antigravity Integration Guide](docs/ANTIGRAVITY_INTEGRATION.md)
*   [🛠️ AI Maintenance Guide](docs/AI_MAINTENANCE.md)
*   [📦 Oh My OpenCode Guide](docs/OH_MY_OPENCODE_GUIDE.md)

---

## FAQ

**Q: Build failed with "bun command not found"?**
A: This project depends on Bun for fast builds. Please install it from [bun.sh](https://bun.sh) or run `npm install -g bun`.

**Q: Some interface text is still in English after localization?**
A: OpenCode updates frequently, and some new features may not yet be covered by our translation config. Please submit an Issue to report missing translations.

**Q: How to use custom models?**
A: We recommend using the `opencodenpm antigravity` command for one-click configuration, or manually editing the `provider` section in `~/.config/opencode/opencode.json`.

---

## License

This project is open-sourced under the [MIT License](LICENSE).
The original OpenCode project is copyright [Anomaly Company](https://anomaly.company/).
