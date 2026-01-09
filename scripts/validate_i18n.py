#!/usr/bin/env python3
"""OpenCode 中文汉化验证脚本"""

import json
import os
from pathlib import Path

# 配置路径
I18N_DIR = Path("C:/DATA/PC/OpenCode/opencode-i18n")
PACKAGE_DIR = Path("C:/DATA/PC/OpenCode/opencode-zh-CN/packages/opencode")
CONFIG_FILE = I18N_DIR / "config.json"


def load_config():
    """加载汉化配置"""
    # 模块化结构：需要合并所有模块文件
    with open(CONFIG_FILE, "r", encoding="utf-8") as f:
        config = json.load(f)

    patches = {}

    # 加载各个模块
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


def validate_patches():
    """验证汉化补丁"""
    patches = load_config()

    total_tests = 0
    passed_tests = 0
    failed_items = []

    print("正在验证汉化结果...")
    print()

    for patch_key, patch in patches.items():
        if not patch.get("file"):
            continue

        target_file = PACKAGE_DIR / patch["file"]

        if not target_file.exists():
            print(f"   [{patch_key}] 文件不存在: {patch['file']}")
            continue

        with open(target_file, "r", encoding="utf-8") as f:
            content = f.read()

        patch_passed = True
        patch_failed = []

        replacements = patch.get("replacements", {})
        for original, expected in replacements.items():
            total_tests += 1

            # 检查文件中是否包含翻译后的文本
            if expected in content:
                passed_tests += 1
            else:
                patch_passed = False
                patch_failed.append({
                    "original": original,
                    "expected": expected
                })

        if patch_passed:
            print(f"   [{patch_key}] 通过")
        else:
            print(f"   [{patch_key}] 失败 ({len(patch_failed)} 项未生效)")
            failed_items.append({
                "module": patch_key,
                "file": patch["file"],
                "failures": patch_failed
            })

    print()
    print("=" * 50)

    if not failed_items:
        print(f" 所有汉化验证通过！({passed_tests}/{total_tests})")
    else:
        print(f" 汉化验证失败！({passed_tests}/{total_tests} 通过)")
        print()
        print("失败的模块:")
        for item in failed_items:
            print(f"  [{item['module']}] {item['file']}")
            print(f"    失败项 (前3个):")
            for i, f in enumerate(item["failures"][:3]):
                print(f"      原文: {f['original'][:80]}...")
                print(f"      期望: {f['expected'][:80]}...")

    return len(failed_items) == 0


if __name__ == "__main__":
    validate_patches()
