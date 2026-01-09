#!/usr/bin/env python3
"""OpenCode 中文汉化应用脚本"""

import json
import os
from pathlib import Path

# 配置路径
I18N_DIR = Path("C:/DATA/PC/OpenCode/opencode-i18n")
PACKAGE_DIR = Path("C:/DATA/PC/OpenCode/opencode-zh-CN/packages/opencode")
CONFIG_FILE = I18N_DIR / "config.json"


def load_config():
    """加载汉化配置"""
    with open(CONFIG_FILE, "r", encoding="utf-8") as f:
        config = json.load(f)

    patches = {}
    for module_type, module_list in config.get("modules", {}).items():
        for module_file in module_list:
            file_path = I18N_DIR / module_file
            if not file_path.exists():
                continue

            with open(file_path, "r", encoding="utf-8") as f:
                module_data = json.load(f)

            key = module_file.replace("/", "-").replace("\\", "-").replace(".json", "")
            patches[key] = module_data

    return patches


def apply_patches():
    """应用汉化补丁"""
    patches = load_config()

    total_patches = 0
    applied_patches = 0

    print("正在应用汉化补丁...")
    print()

    for patch_key, patch in patches.items():
        if not patch.get("file"):
            continue

        target_file = PACKAGE_DIR / patch["file"]

        if not target_file.exists():
            print(f"   [{patch_key}] 文件不存在: {patch['file']}")
            continue

        # 创建备份
        backup_file = target_file.with_suffix(target_file.suffix + ".bak")
        if not backup_file.exists():
            import shutil
            shutil.copy(target_file, backup_file)

        with open(target_file, "r", encoding="utf-8") as f:
            content = f.read()

        original_content = content
        replacements = patch.get("replacements", {})

        for original, translated in replacements.items():
            total_patches += 1
            if original in content:
                content = content.replace(original, translated)
                applied_patches += 1

        if content != original_content:
            with open(target_file, "w", encoding="utf-8") as f:
                f.write(content)
            print(f"   [{patch_key}] 应用 {len(replacements)} 条替换")
        else:
            print(f"   [{patch_key}] 无需更改")

    print()
    print("=" * 50)
    print(f" 完成！共应用 {applied_patches}/{total_patches} 条替换")


if __name__ == "__main__":
    apply_patches()
