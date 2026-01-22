/**
 * clean-cache 命令
 * 清理 Bun 的全局缓存
 */

const { execSync } = require('node:child_process');
const { step, success, error, warn } = require('../core/colors.js');

async function run(options) {
  step('正在清理 Bun 全局缓存...');

  try {
    // 尝试使用 bun pm cache rm
    execSync('bun pm cache rm', { stdio: 'inherit' });
    success('缓存清理完成!');
  } catch (e) {
    error('清理失败: ' + e.message);
    warn('建议尝试以管理员权限运行，或手动删除 .bun/install/cache 目录');
  }
}

module.exports = { run };
