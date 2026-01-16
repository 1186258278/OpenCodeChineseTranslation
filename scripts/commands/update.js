/**
 * update 命令
 * 更新 OpenCode 源码到最新版本
 */

const { getOpencodeDir } = require('../core/utils.js');
const { cloneRepo, pullRepo } = require('../core/git.js');
const { step, success, error, skip } = require('../core/colors.js');

async function run(options = {}) {
  const { force = false } = options;
  const opencodeDir = getOpencodeDir();

  step('更新 OpenCode 源码');

  // 检查是否已存在仓库
  const { isGitRepo } = require('../core/git.js');

  if (isGitRepo(opencodeDir)) {
    if (force) {
      skip('强制重新克隆');
      // 删除旧目录
      const { remove } = require('../core/utils.js');
      remove(opencodeDir);
    } else {
      const result = await pullRepo(opencodeDir);
      return result;
    }
  }

  // 克隆新仓库
  success('克隆 OpenCode 源码...');
  const result = await cloneRepo(
    'https://github.com/anomalyco/opencode.git',
    opencodeDir,
    { depth: 1 }
  );

  return result;
}

module.exports = { run };