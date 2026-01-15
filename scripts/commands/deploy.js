/**
 * deploy 命令
 * 部署全局 opencode 命令到三端
 */

const path = require('path');
const fs = require('fs');
const { exec } = require('../core/utils.js');
const { getBinDir, getOpencodeDir, getPlatform } = require('../core/utils.js');
const { step, success, error, indent, warn } = require('../core/colors.js');

/**
 * 获取编译产物的路径
 */
function getCompiledBinary() {
  const { platform } = getPlatform();
  const platformMap = {
    win32: 'windows-x64',
    darwin: 'darwin-arm64',
    linux: 'linux-x64',
  };
  const targetPlatform = platformMap[platform] || 'linux-x64';
  const binExt = platform === 'win32' ? '.exe' : '';

  // 优先从 bin 目录
  const binDir = getBinDir();
  const localBinary = path.join(binDir, `opencode${binExt}`);

  if (fs.existsSync(localBinary)) {
    return localBinary;
  }

  // 从源码目录
  const opencodeDir = getOpencodeDir();
  const distBinary = path.join(
    opencodeDir,
    'packages',
    'opencode',
    'dist',
    `opencode-${targetPlatform}`,
    'bin',
    `opencode${binExt}`
  );

  if (fs.existsSync(distBinary)) {
    return distBinary;
  }

  return null;
}

/**
 * 安全复制文件（处理目标文件被占用的情况）
 */
function safeCopy(source, target) {
  // 如果目标文件存在，先尝试删除
  if (fs.existsSync(target)) {
    try {
      fs.unlinkSync(target);
    } catch (e) {
      if (e.code === 'EBUSY' || e.code === 'EPERM') {
        throw new Error('目标文件正在使用中，请先关闭所有 opencode 进程');
      }
      throw e;
    }
  }

  // 复制文件
  fs.copyFileSync(source, target);
}

/**
 * 部署到 Windows 全局
 */
function deployToWindows(binaryPath) {
  const npmGlobal = process.env.APPDATA
    ? path.join(process.env.APPDATA, 'npm')
    : path.join(require('os').homedir(), 'AppData', 'Roaming', 'npm');

  // 确保 npm 全局目录存在
  if (!fs.existsSync(npmGlobal)) {
    fs.mkdirSync(npmGlobal, { recursive: true });
  }

  const targetPath = path.join(npmGlobal, 'opencode.exe');

  // 安全复制文件
  try {
    safeCopy(binaryPath, targetPath);
  } catch (e) {
    warn(`部署警告: ${e.message}`);
    indent(`请手动复制:`, 2);
    indent(`  从: ${binaryPath}`, 4);
    indent(`  到: ${targetPath}`, 4);
    return null;
  }

  // 创建 opencode.cmd 包装器
  const cmdPath = path.join(npmGlobal, 'opencode.cmd');
  fs.writeFileSync(cmdPath, '@echo off\r\n"%~dp0opencode.exe" %*\r\n');

  success(`已部署到: ${targetPath}`);
  indent(`CMD 包装器: ${cmdPath}`, 2);

  // 检查 PATH
  const pathVar = process.env.Path || process.env.PATH || '';
  if (!pathVar.toLowerCase().includes(npmGlobal.toLowerCase())) {
    indent('', 0);
    indent('提示: 请确保以下目录在 PATH 环境变量中:', 2);
    indent(npmGlobal, 4);
  }

  return targetPath;
}

/**
 * 部署到 Unix 全局 (Linux/macOS)
 */
function deployToUnix(binaryPath) {
  const usrLocalBin = '/usr/local/bin';
  const homeBin = path.join(require('os').homedir(), '.local', 'bin');

  // 优先使用 ~/.local/bin (无需 sudo)
  let targetDir = homeBin;
  let needsSudo = false;

  // 检查 ~/.local/bin 是否在 PATH 中
  const pathVar = process.env.PATH || '';
  if (!pathVar.includes(homeBin)) {
    // 尝试 /usr/local/bin
    if (fs.existsSync(usrLocalBin)) {
      targetDir = usrLocalBin;
      needsSudo = true;
    }
  }

  // 确保目录存在
  if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir, { recursive: true });
  }

  const targetPath = path.join(targetDir, 'opencode');

  // 复制文件
  fs.copyFileSync(binaryPath, targetPath);

  // 设置可执行权限
  fs.chmodSync(targetPath, 0o755);

  success(`已部署到: ${targetPath}`);

  if (!pathVar.includes(targetDir)) {
    indent('', 0);
    indent('提示: 请确保以下目录在 PATH 中:', 2);
    indent(targetDir, 4);
    indent('', 0);
    indent(`  export PATH="$PATH:${targetDir}"`, 4);
  }

  return targetPath;
}

/**
 * 主运行函数
 */
async function run(options = {}) {
  step('部署 opencode 全局命令');

  const binaryPath = getCompiledBinary();

  if (!binaryPath) {
    error('未找到编译产物，请先运行: opencodenpm build');
    return false;
  }

  indent(`源文件: ${binaryPath}`, 2);

  const { platform } = getPlatform();

  try {
    if (platform === 'win32') {
      deployToWindows(binaryPath);
    } else {
      deployToUnix(binaryPath);
    }

    indent('', 0);
    indent('现在可以使用以下命令启动 OpenCode:', 2);
    indent('  opencode', 4);

    return true;
  } catch (e) {
    error(`部署失败: ${e.message}`);
    return false;
  }
}

module.exports = {
  run,
  getCompiledBinary,
};
