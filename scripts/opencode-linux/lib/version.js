/**
 * 版本检测模块
 *
 * 检测脚本版本和 OpenCode 版本
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const REPO_URL = 'https://gitee.com/QtCodeCreators/OpenCodeChineseTranslation';

/**
 * 获取脚本版本（基于 git 提交数）
 */
function getScriptVersion() {
  try {
    // 使用 git 提交数作为版本号
    const count = execSync('git rev-list --count HEAD', {
      cwd: __dirname,
      encoding: 'utf-8'
    }).trim();

    return `1.0.${count}`;
  } catch {
    return '1.0.0';
  }
}

/**
 * 获取本地 OpenCode 版本（基于 commit hash）
 */
function getLocalOpenCodeVersion() {
  try {
    const projectDir = getProjectDir();
    const opencodeDir = path.join(projectDir, 'opencode-zh-CN');

    if (!fs.existsSync(opencodeDir)) {
      return null;
    }

    const hash = execSync('git rev-parse HEAD', {
      cwd: opencodeDir,
      encoding: 'utf-8'
    }).trim();

    return hash.substring(0, 8);
  } catch {
    return null;
  }
}

/**
 * 获取远程 OpenCode 版本
 */
async function getRemoteOpenCodeVersion() {
  try {
    // 获取远程最新 commit
    const ref = execSync(
      `git ls-remote ${REPO_URL}.git HEAD`,
      { encoding: 'utf-8' }
    ).trim();

    if (!ref) {
      return null;
    }

    return ref.split('\t')[0].substring(0, 8);
  } catch {
    return null;
  }
}

/**
 * 检查是否有更新可用
 */
async function checkUpdateAvailable() {
  const local = getLocalOpenCodeVersion();
  const remote = await getRemoteOpenCodeVersion();

  if (!local || !remote) {
    return { available: false, local, remote };
  }

  return {
    available: local !== remote,
    local,
    remote
  };
}

/**
 * 获取项目根目录
 * 如果找不到包含 opencode-i18n 的目录，返回当前目录
 */
function getProjectDir() {
  let dir = process.cwd();
  while (dir !== '/') {
    if (fs.existsSync(path.join(dir, 'opencode-i18n'))) {
      return dir;
    }
    dir = path.dirname(dir);
  }
  // 未找到项目目录，返回当前目录
  return process.cwd();
}

/**
 * 综合版本检查
 */
async function check() {
  return {
    script: getScriptVersion(),
    opencode: getLocalOpenCodeVersion() || '未安装',
    remote: await getRemoteOpenCodeVersion() || '未知',
    updateAvailable: (await checkUpdateAvailable()).available
  };
}

module.exports = {
  getScriptVersion,
  getLocalOpenCodeVersion,
  getRemoteOpenCodeVersion,
  checkUpdateAvailable,
  getProjectDir,
  check
};
