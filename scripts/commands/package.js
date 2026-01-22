/**
 * package 命令
 * 将编译产物打包到 releases 目录，生成专业的发布包
 *
 * 目录结构:
 *   releases/
 *     └── v7.0.0/
 *         ├── opencode-zh-CN-v7.0.0-windows-x64.zip
 *         ├── opencode-zh-CN-v7.0.0-darwin-arm64.zip
 *         ├── opencode-zh-CN-v7.0.0-linux-x64.zip
 *         ├── RELEASE_NOTES.md
 *         └── checksums.txt
 */

const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const { exec } = require('../core/utils.js');
const { getOpencodeDir, getProjectDir, getPlatform } = require('../core/utils.js');
const { step, success, error, indent, log, warn } = require('../core/colors.js');
const Builder = require('../core/build.js');

/**
 * 获取 releases 目录
 */
function getReleasesDir() {
  return path.join(getProjectDir(), 'releases');
}

/**
 * 获取汉化脚本版本号
 */
function getI18nVersion() {
  try {
    const projectDir = getProjectDir();
    const packageJson = path.join(projectDir, 'scripts', 'package.json');
    if (fs.existsSync(packageJson)) {
      const pkg = JSON.parse(fs.readFileSync(packageJson, 'utf-8'));
      return pkg.version || '0.0.0';
    }
  } catch {
    // 忽略
  }
  return '0.0.0';
}

/**
 * 获取 OpenCode 源码版本信息
 */
function getOpencodeVersion() {
  try {
    const opencodeDir = getOpencodeDir();

    // 读取 package.json
    const packageJson = path.join(opencodeDir, 'package.json');
    let version = 'unknown';
    let bunVersion = 'unknown';

    if (fs.existsSync(packageJson)) {
      const pkg = JSON.parse(fs.readFileSync(packageJson, 'utf-8'));
      bunVersion = pkg.packageManager?.split('@')[1] || 'unknown';
    }

    // 读取 opencode 包的版本
    const opencodePkg = path.join(opencodeDir, 'packages', 'opencode', 'package.json');
    if (fs.existsSync(opencodePkg)) {
      const pkg = JSON.parse(fs.readFileSync(opencodePkg, 'utf-8'));
      version = pkg.version || 'unknown';
    }

    // 获取 git commit
    let commit = 'unknown';
    let commitDate = 'unknown';
    try {
      commit = exec('git rev-parse --short HEAD', { cwd: opencodeDir, stdio: 'pipe' }).trim();
      commitDate = exec('git log -1 --format=%ci', { cwd: opencodeDir, stdio: 'pipe' }).trim().split(' ')[0];
    } catch {}

    return { version, bunVersion, commit, commitDate };
  } catch {
    return { version: 'unknown', bunVersion: 'unknown', commit: 'unknown', commitDate: 'unknown' };
  }
}

/**
 * 计算文件的 MD5 和 SHA256
 */
function calculateChecksums(filePath) {
  const fileBuffer = fs.readFileSync(filePath);
  const md5 = crypto.createHash('md5').update(fileBuffer).digest('hex');
  const sha256 = crypto.createHash('sha256').update(fileBuffer).digest('hex');
  return { md5, sha256 };
}

/**
 * 生成 Release Notes 模板
 */
function generateReleaseNotes(version, opencodeInfo, packages) {
  const now = new Date();
  const dateStr = now.toISOString().split('T')[0];
  const timeStr = now.toISOString().split('T')[1].split('.')[0];

  let notes = `# OpenCode 中文汉化版 v${version}

> 🎉 **发布日期**: ${dateStr} ${timeStr} UTC
>
> 📦 **基于 OpenCode**: v${opencodeInfo.version} (commit: \`${opencodeInfo.commit}\`)
>
> 🔧 **构建环境**: Bun ${opencodeInfo.bunVersion}

---

## 📋 版本信息

| 项目 | 版本 |
|------|------|
| 汉化版本 | v${version} |
| OpenCode 版本 | v${opencodeInfo.version} |
| OpenCode Commit | \`${opencodeInfo.commit}\` (${opencodeInfo.commitDate}) |
| Bun 版本 | ${opencodeInfo.bunVersion} |
| 构建时间 | ${dateStr} ${timeStr} |

---

## ✨ 更新内容

<!-- 请在此处填写本次更新的主要内容 -->

### 🆕 新增功能
-

### 🔧 改进优化
-

### 🐛 问题修复
-

### 📝 其他变更
-

---

## 📦 下载文件

| 平台 | 文件名 | 大小 | MD5 |
|------|--------|------|-----|
`;

  // 添加文件信息
  for (const pkg of packages) {
    notes += `| ${pkg.platform} | \`${pkg.filename}\` | ${pkg.size} | \`${pkg.md5.substring(0, 8)}...\` |\n`;
  }

  notes += `
---

## 🔐 校验码

完整校验码请查看 \`checksums.txt\` 文件。

\`\`\`
`;

  for (const pkg of packages) {
    notes += `# ${pkg.filename}\n`;
    notes += `MD5:    ${pkg.md5}\n`;
    notes += `SHA256: ${pkg.sha256}\n\n`;
  }

  notes += `\`\`\`

---

## 📖 安装说明

### Windows
1. 下载 \`opencode-zh-CN-v${version}-windows-x64.zip\`
2. 解压到任意目录
3. 双击 \`opencode.exe\` 运行
4. (可选) 将目录添加到 PATH 环境变量

### macOS (Apple Silicon)
\`\`\`bash
# 下载并解压
unzip opencode-zh-CN-v${version}-darwin-arm64.zip -d ~/Applications/

# 添加执行权限
chmod +x ~/Applications/opencode

# 运行
~/Applications/opencode
\`\`\`

### Linux
\`\`\`bash
# 下载并解压
unzip opencode-zh-CN-v${version}-linux-x64.zip -d ~/.local/bin/

# 添加执行权限
chmod +x ~/.local/bin/opencode

# 运行
opencode
\`\`\`

---

## 🔗 相关链接

- [汉化项目 GitHub](https://github.com/1186258278/OpenCodeChineseTranslation)
- [汉化项目 Gitee](https://gitee.com/QtCodeCreators/OpenCodeChineseTranslation)
- [OpenCode 官方](https://github.com/anomalyco/opencode)
- [问题反馈](https://github.com/1186258278/OpenCodeChineseTranslation/issues)

---

## ⚠️ 注意事项

1. 首次运行需要配置 API Key
2. 建议使用终端/命令行运行以获得最佳体验
3. 如遇问题请查看 [FAQ](https://github.com/1186258278/OpenCodeChineseTranslation#-常见问题) 或提交 Issue

---

> 🤖 由 OpenCode 中文汉化项目自动生成
`;

  return notes;
}

/**
 * 生成 checksums.txt
 */
function generateChecksums(packages) {
  const now = new Date().toISOString();
  let content = `# OpenCode 中文汉化版 - 文件校验码
# 生成时间: ${now}
#
# 验证方法:
#   Windows PowerShell: Get-FileHash -Algorithm SHA256 <文件名>
#   Linux/macOS: sha256sum <文件名> 或 md5sum <文件名>
#
# ============================================================

`;

  for (const pkg of packages) {
    content += `文件: ${pkg.filename}
大小: ${pkg.size}
MD5:    ${pkg.md5}
SHA256: ${pkg.sha256}

`;
  }

  return content;
}

/**
 * 打包汉化工具源码（便携版）
 */
async function packageSource(versionDir) {
  step('打包汉化工具源码...');

  const projectDir = getProjectDir();
  const version = getI18nVersion();
  const baseName = `opencode-i18n-tool-v${version}`;
  const outputPath = path.join(versionDir, `${baseName}.zip`);
  const { platform: osPlatform } = getPlatform();

  // 需要打包的文件和目录
  const includeList = [
    'scripts',
    'opencode-i18n',
    'docs',
    'package.json',
    'package-lock.json',
    'README.md',
    'README_EN.md',
    'LICENSE',
    'CONTRIBUTING.md',
    '.gitignore'
  ];

  // 创建临时目录
  const tempDir = path.join(versionDir, 'temp', baseName);
  if (fs.existsSync(tempDir)) {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
  fs.mkdirSync(tempDir, { recursive: true });

  // 复制文件
  for (const item of includeList) {
    const srcPath = path.join(projectDir, item);
    const destPath = path.join(tempDir, item);

    if (fs.existsSync(srcPath)) {
      if (fs.statSync(srcPath).isDirectory()) {
        // 递归复制目录，排除 node_modules
        fs.cpSync(srcPath, destPath, { 
          recursive: true, 
          filter: (src) => !src.includes('node_modules') 
        });
      } else {
        fs.copyFileSync(srcPath, destPath);
      }
    }
  }

  // 压缩
  if (fs.existsSync(outputPath)) {
    fs.unlinkSync(outputPath);
  }

  if (osPlatform === 'win32') {
    try {
      exec(
        `powershell -Command "Compress-Archive -Path '${tempDir}\\*' -DestinationPath '${outputPath}' -Force"`,
        { stdio: 'pipe' }
      );
    } catch (e) {
      error(`压缩源码失败: ${e.message}`);
      return null;
    }
  } else {
    try {
      exec(`cd "${tempDir}" && zip -r "${outputPath}" .`, { stdio: 'pipe' });
    } catch (e) {
      error(`压缩源码失败: ${e.message}`);
      return null;
    }
  }

  // 清理临时目录
  fs.rmSync(tempDir, { recursive: true, force: true });
  
  // 清理 temp 目录（如果为空）
  const tempBaseDir = path.join(versionDir, 'temp');
  if (fs.existsSync(tempBaseDir) && fs.readdirSync(tempBaseDir).length === 0) {
    fs.rmdirSync(tempBaseDir);
  }

  // 获取文件信息
  const stats = fs.statSync(outputPath);
  const sizeMB = (stats.size / 1024 / 1024).toFixed(2);
  const checksums = calculateChecksums(outputPath);

  success(`打包源码完成: ${path.basename(outputPath)} (${sizeMB} MB)`);

  return {
    platform: 'source-tool',
    filename: `${baseName}.zip`,
    path: outputPath,
    size: `${sizeMB} MB`,
    bytes: stats.size,
    md5: checksums.md5,
    sha256: checksums.sha256,
  };
}

/**
 * 打包单个平台
 */
async function packagePlatform(platform, versionDir) {
  const { platform: osPlatform } = getPlatform();

  step(`打包 ${platform}`);

  // 获取编译产物
  const opencodeDir = getOpencodeDir();
  const distDir = path.join(
    opencodeDir,
    'packages',
    'opencode',
    'dist',
    `opencode-${platform}`
  );

  // 如果编译产物不存在，自动触发编译
  if (!fs.existsSync(distDir)) {
    log(`  编译产物不存在，正在编译 ${platform}...`, 'yellow');

    const builder = new Builder();

    // 清理该平台的旧编译产物（如果存在）
    const platformDistDir = path.join(opencodeDir, 'packages', 'opencode', 'dist', `opencode-${platform}`);
    if (fs.existsSync(platformDistDir)) {
      log(`  清理旧编译产物: ${platformDistDir}`, 'dim');
      fs.rmSync(platformDistDir, { recursive: true, force: true });
    }

    try {
      const buildResult = await builder.build({ platform, silent: false });
      if (!buildResult) {
        error(`编译 ${platform} 失败`);
        return null;
      }
      success(`编译 ${platform} 完成`);
    } catch (e) {
      error(`编译失败: ${e.message}`);
      return null;
    }
  }

  // 再次检查编译产物
  if (!fs.existsSync(distDir)) {
    error(`编译产物仍不存在: ${distDir}`);
    return null;
  }

  // 读取版本号
  const version = getI18nVersion();
  const baseName = `opencode-zh-CN-v${version}-${platform}`;

  // 创建临时打包目录
  const tempDir = path.join(versionDir, 'temp', baseName);
  if (fs.existsSync(tempDir)) {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
  fs.mkdirSync(tempDir, { recursive: true });

  // 复制文件
  const binExt = platform === 'windows-x64' ? '.exe' : '';
  const binSource = path.join(distDir, 'bin', `opencode${binExt}`);
  const binDest = path.join(tempDir, `opencode${binExt}`);

  if (!fs.existsSync(binSource)) {
    error(`二进制文件不存在: ${binSource}`);
    return null;
  }

  fs.copyFileSync(binSource, binDest);

  // 设置可执行权限 (Unix)
  if (osPlatform !== 'win32') {
    fs.chmodSync(binDest, 0o755);
  }

  // 压缩
  const outputPath = path.join(versionDir, `${baseName}.zip`);

  if (fs.existsSync(outputPath)) {
    fs.unlinkSync(outputPath);
  }

  if (osPlatform === 'win32') {
    // Windows: 使用 PowerShell Compress-Archive
    try {
      exec(
        `powershell -Command "Compress-Archive -Path '${tempDir}\\*' -DestinationPath '${outputPath}' -Force"`,
        { stdio: 'pipe' }
      );
    } catch (e) {
      error(`压缩失败: ${e.message}`);
      return null;
    }
  } else {
    // Unix: 使用 zip 命令
    try {
      exec(`cd "${tempDir}" && zip -r "${outputPath}" .`, { stdio: 'pipe' });
    } catch (e) {
      error(`压缩失败: ${e.message}`);
      return null;
    }
  }

  // 清理临时目录
  fs.rmSync(tempDir, { recursive: true, force: true });

  // 清理 temp 目录
  const tempBaseDir = path.join(versionDir, 'temp');
  if (fs.existsSync(tempBaseDir)) {
    const remaining = fs.readdirSync(tempBaseDir);
    if (remaining.length === 0) {
      fs.rmdirSync(tempBaseDir);
    }
  }

  // 获取文件信息
  const stats = fs.statSync(outputPath);
  const sizeMB = (stats.size / 1024 / 1024).toFixed(2);
  const checksums = calculateChecksums(outputPath);

  success(`打包完成: ${path.basename(outputPath)} (${sizeMB} MB)`);

  return {
    platform,
    filename: `${baseName}.zip`,
    path: outputPath,
    size: `${sizeMB} MB`,
    bytes: stats.size,
    md5: checksums.md5,
    sha256: checksums.sha256,
  };
}

/**
 * 打包所有平台
 */
async function packageAll(options = {}) {
  const { skipBinaries = false } = options;
  const platforms = ['windows-x64', 'darwin-arm64', 'linux-x64'];
  const version = getI18nVersion();
  const opencodeInfo = getOpencodeVersion();

  step(`打包 v${version} (基于 OpenCode ${opencodeInfo.version})`);

  // 创建版本目录
  const releasesDir = getReleasesDir();
  const versionDir = path.join(releasesDir, `v${version}`);

  if (!fs.existsSync(versionDir)) {
    fs.mkdirSync(versionDir, { recursive: true });
  }

  const packages = [];
  const results = [];

  // 1. 打包汉化工具源码
  const sourceResult = await packageSource(versionDir);
  if (sourceResult) {
    packages.push(sourceResult);
    results.push({ platform: 'source-tool', success: true });
  } else {
    results.push({ platform: 'source-tool', success: false });
  }

  // 2. 打包三端二进制（除非跳过）
  if (!skipBinaries) {
    for (const targetPlatform of platforms) {
      const result = await packagePlatform(targetPlatform, versionDir);
      if (result) {
        packages.push(result);
        results.push({ platform: targetPlatform, success: true });
      } else {
        results.push({ platform: targetPlatform, success: false });
      }
    }
  } else {
    log('已跳过二进制编译打包', 'yellow');
  }

  // 生成 Release Notes
  if (packages.length > 0) {
    const releaseNotes = generateReleaseNotes(version, opencodeInfo, packages);
    const releaseNotesPath = path.join(versionDir, 'RELEASE_NOTES.md');
    fs.writeFileSync(releaseNotesPath, releaseNotes, 'utf-8');
    success(`生成发布说明: RELEASE_NOTES.md`);

    // 生成 checksums.txt
    const checksums = generateChecksums(packages);
    const checksumsPath = path.join(versionDir, 'checksums.txt');
    fs.writeFileSync(checksumsPath, checksums, 'utf-8');
    success(`生成校验文件: checksums.txt`);
  }

  // 显示汇总
  const successCount = results.filter((r) => r.success).length;
  console.log('');

  log(`${'═'.repeat(50)}`, 'cyan');
  log(`  打包完成: ${successCount}/${results.length} 个平台`, 'cyan');
  log(`${'═'.repeat(50)}`, 'cyan');
  log(`  版本目录: ${versionDir}`, 'dim');
  console.log('');

  // 列出所有生成的文件
  if (fs.existsSync(versionDir)) {
    const files = fs.readdirSync(versionDir);
    log('  生成的文件:', 'white');
    files.forEach((file) => {
      const filePath = path.join(versionDir, file);
      const stats = fs.statSync(filePath);
      if (stats.isFile()) {
        const sizeMB = (stats.size / 1024 / 1024).toFixed(2);
        const icon = file.endsWith('.zip') ? '📦' : file.endsWith('.md') ? '📄' : '📋';
        log(`    ${icon} ${file} (${sizeMB} MB)`, 'dim');
      }
    });
  }
  console.log('');

  // 提示编辑 Release Notes
  if (packages.length > 0) {
    warn('请编辑 RELEASE_NOTES.md 填写更新内容!');
    log(`  路径: ${path.join(versionDir, 'RELEASE_NOTES.md')}`, 'dim');
  }

  console.log('');

  return results.every((r) => r.success);
}

/**
 * 主运行函数
 */
async function run(options = {}) {
  const { platform = null, all = false, skipBinaries = false } = options;

  if (all) {
    return await packageAll({ skipBinaries });
  }

  if (platform) {
    const version = getI18nVersion();
    const releasesDir = getReleasesDir();
    const versionDir = path.join(releasesDir, `v${version}`);

    if (!fs.existsSync(versionDir)) {
      fs.mkdirSync(versionDir, { recursive: true });
    }

    const result = await packagePlatform(platform, versionDir);
    return result !== null;
  }

  // 默认打包当前平台
  const { isWindows, isMacOS } = getPlatform();
  let currentPlatform = 'linux-x64';
  if (isWindows) currentPlatform = 'windows-x64';
  else if (isMacOS) currentPlatform = 'darwin-arm64';

  const version = getI18nVersion();
  const releasesDir = getReleasesDir();
  const versionDir = path.join(releasesDir, `v${version}`);

  if (!fs.existsSync(versionDir)) {
    fs.mkdirSync(versionDir, { recursive: true });
  }

  const result = await packagePlatform(currentPlatform, versionDir);
  return result !== null;
}

module.exports = {
  run,
  packagePlatform,
  packageAll,
  getReleasesDir,
  getI18nVersion,
  getOpencodeVersion,
};
