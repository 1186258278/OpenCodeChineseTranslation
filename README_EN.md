# OpenCode Chinese Localization

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://microsoft.com/PowerShell)
[![OpenCode](https://img.shields.io/badge/OpenCode-dev-green.svg)](https://github.com/anomalyco/opencode)

English | [中文版](README.md)

---

## Overview

OpenCode Chinese Localization is a modification of the official Anthropic OpenCode project that provides complete Chinese translation. This project uses modular configuration and automated scripts to localize OpenCode, making it more accessible to Chinese-speaking users.

**Problems Solved:**

| Problem | Solution |
|---------|----------|
| English-only interface reduces efficiency | Complete translation of all user-visible text |
| Manual re-modification required after each update | Automated scripts support one-click update and translation |
| Unfamiliarity with command-line operations | Interactive menu system simplifies workflow |
| Concern about breaking original functionality | Preserves source structure, only replaces display text |

---

## System Requirements

| Component | Minimum | Recommended | Notes |
|-----------|---------|-------------|-------|
| Operating System | Windows 10 1809+ | Windows 11 22H2+ | Requires PowerShell 5.1+ |
| PowerShell | 5.1 | 7.2+ | Included with Windows 10 |
| Git | 2.25+ | 2.40+ | For code management and submodule operations |
| Bun | 1.3+ | Latest | OpenCode build dependency |

**Supported Systems:**
- Windows 10 version 1809 (October 2018 update) and later
- All versions of Windows 11
- Windows Server 2019 and later

---

## Installation

### Method 1: Quick Install

```powershell
# 1. Clone repository
git clone https://github.com/1186258278/OpenCodeChineseTranslation.git
cd OpenCodeChineseTranslation

# 2. Initialize submodule
git submodule update --init --recursive

# 3. Run script
.\scripts\opencode.ps1
```

### Method 2: Manual Deployment

```powershell
# 1. Clone main repository (without submodule)
git clone --no-recurse-submodules https://github.com/1186258278/OpenCodeChineseTranslation.git
cd OpenCodeChineseTranslation

# 2. Add submodule manually
git submodule add https://github.com/anomalyco/opencode.git opencode-zh-CN

# 3. Install dependencies in submodule
cd opencode-zh-CN
bun install
cd ..

# 4. Apply localization
.\scripts\opencode.ps1
# Select menu [2] Apply Translation
```

### Method 3: Deploy from GitHub Releases

1. Visit [Releases page](https://github.com/1186258278/OpenCodeChineseTranslation/releases)
2. Download the latest precompiled package
3. Extract to local directory
4. Run `opencode.bat` or `.\scripts\opencode.ps1`

---

## Usage

### One-Click Localization & Deployment

Recommended for first-time users. Automatically completes the following process:

```
Pull latest code → Apply patches → Build → Deploy locally
```

```powershell
.\scripts\opencode.ps1
# Select [1] One-Click Localization+Deploy
```

### Step-by-Step Operations

For users who want to understand the process or need customization:

| Step | Menu Option | Description |
|------|-------------|-------------|
| Pull code | Advanced Menu → [1] | Fetch latest source from official repository |
| Apply translation | Advanced Menu → [2] | Apply Chinese translation to source |
| Build | Advanced Menu → [3] | Compile project using Bun |
| Deploy | Advanced Menu → [9] | Replace global OpenCode installation |

### Version Update

```powershell
.\scripts\opencode.ps1
# Select [5] Check Version
# If update available, type y to confirm
```

---

## Menu Guide

### Main Menu

| Option | Function | Use Case |
|--------|----------|----------|
| [1] | One-Click Localization+Deploy | First-time use or complete update |
| [2] | Apply Translation | Apply translation only, no build |
| [3] | Verify Translation | Check translation coverage |
| [4] | Debug Tools | Troubleshoot translation issues |
| [5] | Check Version | Check and update official version |
| [6] | Backup Version | Backup current localized version |
| [7] | Advanced Menu | More advanced options |

### Advanced Menu

| Option | Function |
|--------|----------|
| [1] | Pull latest code (with automatic proxy detection) |
| [2] | Apply translation patches |
| [3] | Build program |
| [4] | Check version |
| [5] | Backup source and build output |
| [6] | Restore from backup |
| [7] | Restore original files |
| [8] | Open output directory |
| [9] | Replace global version |
| [C] | Cleanup tools (cache, temp files) |
| [L] | Launch OpenCode |
| [R] | Source recovery (force reset) |
| [S] | Restore script |

---

## Translation Scope

| Module | Coverage |
|--------|----------|
| Command Panel | Session management, model selection, agent switching |
| Dialogs | Agent selector, session list, message handling |
| Sidebar | Context management, MCP status display |
| Top Bar | Sub-agent navigation |
| Permission System | File operation permission requests |
| Notifications | 70+ action prompt messages |

---

## Project Structure

```
OpenCodeChineseTranslation/
├── scripts/                 # Management scripts
│   └── opencode.ps1         # Main script (2300+ lines)
├── opencode-i18n/           # Translation configuration
│   ├── config.json          # Main configuration (version control)
│   ├── dialogs/             # Dialog translations (21 modules)
│   ├── routes/              # Route translations (3 modules)
│   ├── components/          # Component translations (6 modules)
│   └── common/              # Common translations (6 modules)
├── opencode-zh-CN/          # OpenCode source (Git submodule)
├── dist/                    # Build output (Git ignored)
└── docs/                    # Project documentation
```

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Execution Policy Error | PowerShell default blocks scripts | `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` |
| Build Failed | Bun not installed or outdated | Run `bun upgrade` or reinstall Bun |
| Translation Not Applied | Source overwritten by Git update | Run `[2] Apply Translation` to reapply |
| Network Timeout | Slow GitHub access | Script auto-detects and uses local proxy |
| Empty Submodule | Submodule not initialized | Run `git submodule update --init --recursive` |
| Port in Use | OpenCode already running | Close existing process or use `[L] Launch OpenCode` |

---

## Proxy Configuration

The script automatically detects common proxy ports:

| Proxy Software | Default Ports | Detection |
|----------------|---------------|-----------|
| Clash | 7890, 7891 | Automatic |
| V2RayN | 10809, 10808 | Automatic |
| Surge | 1087, 1080 | Automatic |
| Others | 8080 | Automatic |

To manually configure proxy:

```powershell
git config --global http.proxy http://127.0.0.1:PORT
git config --global https.proxy http://127.0.0.1:PORT
```

---

## Version Compatibility

The language pack ensures compatibility with OpenCode source code via Git Commit matching.

**Version Detection Mechanism:**

| Check Item | Description |
|------------|-------------|
| Supported Version | Commit Hash of tested OpenCode version in config |
| Current Version | Actual Commit of OpenCode submodule at runtime |
| Mismatch Handling | Show warning and prompt to contact maintainer |

**Issues when versions don't match:**
- Some new text may not be translated
- Translated text may display incorrectly
- UI elements may appear broken

**How to update language pack:**

If you encounter a version mismatch warning, please contact the maintainer:

| Contact Method | Description |
|----------------|-------------|
| WeChat | CodeCreator |
| GitHub | [Submit Issue](https://github.com/1186258278/OpenCodeChineseTranslation/issues) |

**Maintainer Info:**

```json
{
  "name": "CodeCreator",
  "wechat": "CodeCreator",
  "github": "https://github.com/1186258278/OpenCodeChineseTranslation"
}
```

---

## Contributing

Contributions are welcome!

1. **Fix translation errors**: Submit PR to modify JSON files in `opencode-i18n/`
2. **Add new modules**: Add new JSON files and update `config.json`
3. **Optimize scripts**: Submit PR to modify `scripts/opencode.ps1`
4. **Report issues**: Submit Issue with error logs

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## License

This project is licensed under MIT License. See [LICENSE](LICENSE) for details.

OpenCode original project is copyrighted by Anthropic.

---

## Related Links

- [OpenCode Official Repository](https://github.com/anomalyco/opencode)
- [OpenCode Documentation](https://opencode.ai/docs)
- [Issue Tracker](https://github.com/1186258278/OpenCodeChineseTranslation/issues)
- [中文文档](README.md)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 4.5 | 2026-01-09 | Added error message translations, fixed validation script |
| 4.3 | 2026-01-08 | Improved menu structure, added auto proxy detection |
| 4.0 | 2026-01-07 | Modular refactoring, independent module management |
| 3.1 | 2026-01-06 | Menu optimization, fixed version detection |
| 3.0 | 2026-01-05 | Added one-click localization |
| 1.0 | 2025-12-01 | Initial release |
