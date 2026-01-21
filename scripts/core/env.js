/**
 * 环境检查模块
 * 检查 Node.js、Bun、Git 等必要工具
 */

const path = require('path');
const fs = require('fs');
const { hasCommand, getCommandVersion, getPlatform, getOpencodeDir, readJSON, execLive } = require('./utils.js');
const { step, success, error, warn, indent, log } = require('./colors.js');

/**
 * 安装/校准 Bun 版本
 */
async function installBun(version) {
  step(`正在校准 Bun 版本到 v${version}...`);
  
  try {
    // 优先使用 npm 安装，因为这是跨平台最一致的方式（且我们已经在 node 环境中）
    const cmd = 'npm';
    const args = ['install', '-g', `bun@${version}`];
    
    await execLive(cmd, args);
    
    // 验证安装结果
    const current = getCurrentBunVersion();
    if (current === version) {
      success(`Bun 已成功校准到 v${version}`);
      return true;
    } else {
      warn(`安装完成，但版本似乎未更新 (当前: ${current})。可能需要重启终端。`);
      return true;
    }
  } catch (e) {
    error(`安装失败: ${e.message}`);
    return false;
  }
}

/**
 * 获取 OpenCode 推荐的 Bun 版本
 */
function getRecommendedBunVersion() {
  try {
    const opencodeDir = getOpencodeDir();
    const pkgPath = path.join(opencodeDir, 'package.json');
    if (fs.existsSync(pkgPath)) {
      const pkg = readJSON(pkgPath);
      if (pkg.packageManager && typeof pkg.packageManager === 'string' && pkg.packageManager.startsWith('bun@')) {
        return pkg.packageManager.split('@')[1];
      }
    }
  } catch (e) {
    // 忽略错误
  }
  return '1.3.5'; // 默认推荐版本
}

/**
 * 获取本地 Bun 版本
 */
function getCurrentBunVersion() {
  const version = getCommandVersion('bun', '--version');
  return version ? version.trim() : null;
}

/**
 * 检查 Node.js 版本
 */
function checkNode() {
  try {
    const version = getCommandVersion('node', '--version');
    if (!version) return { ok: false, version: null };

    const match = version.match(/v(\d+)\.(\d+)/);
    if (!match) return { ok: false, version };

    const major = parseInt(match[1], 10);
    const minor = parseInt(match[2], 10);

    // Node.js >= 18.0.0
    const ok = major > 18 || (major === 18 && minor >= 0);
    return { ok, version, required: '>=18.0.0' };
  } catch (e) {
    return { ok: false, version: null };
  }
}

/**
 * 检查 Bun
 */
function checkBun() {
  try {
    const version = getCommandVersion('bun', '--version');
    if (!version) return { ok: false, version: null };

    // bun 版本格式如 "1.3.6"
    const match = version.match(/(\d+)\.(\d+)\.(\d+)/);
    if (match) {
      return { ok: true, version };
    }
    return { ok: true, version };
  } catch (e) {
    return { ok: false, version: null };
  }
}

/**
 * 检查 Git
 */
function checkGit() {
  try {
    const version = getCommandVersion('git', '--version');
    return { ok: !!version, version };
  } catch (e) {
    return { ok: false, version: null };
  }
}

/**
 * 检查 npm
 */
function checkNpm() {
  try {
    const version = getCommandVersion('npm', '--version');
    return { ok: !!version, version };
  } catch (e) {
    return { ok: false, version: null };
  }
}

/**
 * 完整的环境检查
 */
async function checkEnvironment(options = {}) {
  const { silent = false, autoInstall = false } = options;

  if (!silent) {
    step('检查编译环境');
  }

  // 检查 Bun 版本匹配
  const currentBun = getCurrentBunVersion();
  const recommendedBun = getRecommendedBunVersion();
  let bunVersionWarning = null;

  if (currentBun && currentBun !== recommendedBun) {
    bunVersionWarning = `Bun 版本不匹配: 当前 ${currentBun}, 推荐 ${recommendedBun}`;
  }

  const results = {
    node: checkNode(),
    bun: checkBun(),
    git: checkGit(),
    npm: checkNpm(),
  };

  const missing = [];
  const warnings = [];
  
  if (bunVersionWarning) {
    warnings.push(bunVersionWarning);
  }

  // 检查结果
  if (!results.node.ok) {
    missing.push('Node.js (需要 >=18.0.0)');
  } else if (!silent) {
    success(`Node.js ${results.node.version}`);
    indent(`版本: ${results.node.version}`, 2);
  }

  if (!results.bun.ok) {
    missing.push('Bun');
  } else if (!silent) {
    success(`Bun ${results.bun.version}`);
    indent(`版本: ${results.bun.version}`, 2);
  }

  if (!results.git.ok) {
    missing.push('Git');
  } else if (!silent) {
    success(`Git ${results.git.version}`);
  }

  if (!results.npm.ok) {
    warnings.push('npm (用于全局安装)');
  } else if (!silent) {
    success(`npm ${results.npm.version}`);
  }

  // 平台信息
  const { isWindows, isLinux, isMacOS, platform } = getPlatform();
  if (!silent) {
    indent(`平台: ${platform}`, 2);
  }

  if (missing.length > 0) {
    if (!silent) {
      error(`缺少必要工具: ${missing.join(', ')}`);
      
      // 显示具体错误信息（如版本不兼容）
      if (results.bun?.error) {
        warn(results.bun.error);
      }

      warn('请安装后重试:');
      if (results.node?.ok === false) {
        indent('Node.js: https://nodejs.org/', 2);
      }
      if (results.bun?.ok === false) {
        const installCmd = isWindows ? 'npm install -g bun@1.3.5' : 'npm install -g bun';
        indent(`Bun: ${installCmd}`, 2);
      }
      if (results.git?.ok === false) {
        indent('Git: https://git-scm.com/', 2);
      }
    }
    return { ok: false, missing, warnings, results };
  }

  if (warnings.length > 0 && !silent) {
    warn(`建议安装/注意: ${warnings.join(', ')}`);
    
    // 如果有 Bun 版本不匹配，且不在静默模式下，尝试交互式修复
    // 注意：这里我们不引入 grid-menu 以避免可能的循环依赖，
    // 而是只打印更显眼的提示和命令。
    if (bunVersionWarning) {
      const { isWindows } = getPlatform();
      const installCmd = isWindows ? `npm install -g bun@${recommendedBun}` : `npm install -g bun@${recommendedBun}`;
      console.log('');
      warn(`! 检测到 Bun 版本不一致 (${currentBun} vs ${recommendedBun})`);
      warn(`! Windows 上 Bun 1.3.6 存在已知问题，强烈建议使用推荐版本。`);
      indent(`修复命令: ${installCmd}`, 2);
      console.log('');
    }
  }

  return { ok: true, missing: [], warnings, results, bunStatus: { current: currentBun, recommended: recommendedBun, match: currentBun === recommendedBun } };
}

/**
 * 获取 Bun 的完整路径
 */
function getBunPath() {
  const { isWindows } = getPlatform();
  const path = require('path');
  const fs = require('fs');
  const os = require('os');

  const possiblePaths = [];

  if (isWindows) {
    // Windows 路径
    possiblePaths.push(
      path.join(process.env.APPDATA || '', 'npm', 'node_modules', 'bun', 'bin', 'bun.exe'),
      path.join(process.env.USERPROFILE || '', '.bun', 'bin', 'bun.exe'),
      path.join(process.env.ProgramFiles || '', 'bun', 'bin', 'bun.exe'),
      path.join(process.env['ProgramFiles(x86)'] || '', 'bun', 'bin', 'bun.exe')
    );
  } else {
    // Unix 路径
    possiblePaths.push(
      path.join(os.homedir(), '.bun', 'bin', 'bun'),
      '/usr/local/bin/bun',
      path.join(os.homedir(), '.local', 'bin', 'bun')
    );
  }

  for (const bunPath of possiblePaths) {
    if (fs.existsSync(bunPath)) {
      return bunPath;
    }
  }

  // 尝试从 PATH 获取
  try {
    const whereCmd = isWindows ? 'where bun' : 'which bun';
    const result = require('child_process').execSync(whereCmd, { encoding: 'utf-8' }).trim();
    if (result) {
      return result.split('\n')[0].trim();
    }
  } catch (e) {
    // 忽略
  }

  return null;
}

module.exports = {
  checkNode,
  checkBun,
  checkGit,
  checkNpm,
  checkEnvironment,
  getBunPath,
  getRecommendedBunVersion,
  getCurrentBunVersion,
  installBun
};
