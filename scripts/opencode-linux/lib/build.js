/**
 * 编译构建模块
 *
 * 调用 bun run build 编译 OpenCode
 */

const { execSync } = require('child_process');
const { hasCommand } = require('./env.js');
const fs = require('fs');
const path = require('path');
const Version = require('./version.js');

class Build {
  constructor() {
    this.projectDir = Version.getProjectDir();
    this.opencodeDir = path.join(this.projectDir, 'opencode-zh-CN');
    // OpenCode 实际代码在 packages/opencode/ 子目录
    this.opcodePackageDir = path.join(this.opencodeDir, 'packages/opencode');
    this.bunPath = path.join(process.env.HOME || '~', '.bun/bin');
  }

  /**
   * 检查并安装 Bun
   */
  async ensureBun() {
    // 先检查是否已有 bun（包括自定义安装路径）
    if (this.hasBun()) {
      this.addToPath();
      return true;
    }

    console.log('正在安装 Bun...');

    // 方式1: 使用官方安装脚本
    try {
      execSync('curl -fsSL https://bun.sh/install | bash', {
        stdio: ['ignore', 'inherit', 'inherit'],
        shell: '/bin/bash',
        env: { ...process.env, BUN_INSTALL: this.bunPath.replace('/bin', '') }
      });

      this.addToPath();

      // 验证安装
      if (this.hasBun()) {
        console.log('✓ Bun 已安装');
        return true;
      }
    } catch (error) {
      console.log('  官方安装脚本失败，尝试备用方式...');
    }

    // 方式2: 使用 npm 全局安装（备用）
    try {
      execSync('npm install -g bun', {
        stdio: ['ignore', 'inherit', 'inherit']
      });

      // npm 全局安装路径
      const npmGlobal = execSync('npm config get prefix', {
        encoding: 'utf-8'
      }).trim();
      this.bunPath = path.join(npmGlobal, 'bin');
      this.addToPath();

      if (this.hasBun()) {
        console.log('✓ Bun 已安装 (通过 npm)');
        return true;
      }
    } catch (error) {
      console.log('  npm 安装失败');
    }

    throw new Error(`
Bun 安装失败，请手动安装后重试：

方式1: curl -fsSL https://bun.sh/install | bash
方式2: npm install -g bun

安装后重新运行: opencodecmd build
    `);
  }

  /**
   * 检查 bun 是否可用（包括自定义路径）
   */
  hasBun() {
    // 检查 PATH 中的 bun
    if (hasCommand('bun')) {
      return true;
    }

    // 检查自定义安装路径
    const bunBin = path.join(this.bunPath, 'bun');
    if (fs.existsSync(bunBin)) {
      return true;
    }

    return false;
  }

  /**
   * 添加 bun 到 PATH
   */
  addToPath() {
    if (process.env.PATH && !process.env.PATH.includes(this.bunPath)) {
      process.env.PATH = this.bunPath + ':' + process.env.PATH;
    }
  }

  /**
   * 获取 bun 命令完整路径
   */
  getBunCommand() {
    // 优先使用 PATH 中的 bun
    if (hasCommand('bun')) {
      return 'bun';
    }

    // 使用自定义安装路径
    const bunBin = path.join(this.bunPath, 'bun');
    if (fs.existsSync(bunBin)) {
      return `"${bunBin}"`;
    }

    return 'bun';
  }

  /**
   * 安装依赖
   */
  async install() {
    // 确保有 Bun
    await this.ensureBun();

    const bunCmd = this.getBunCommand();

    try {
      execSync(`${bunCmd} install`, {
        cwd: this.opcodePackageDir,
        stdio: 'inherit',
        env: { ...process.env, PATH: this.bunPath + ':' + process.env.PATH }
      });
      return true;
    } catch (error) {
      throw new Error(`依赖安装失败: ${error.message}`);
    }
  }

  /**
   * 执行编译
   */
  async run() {
    // 确保有 Bun
    await this.ensureBun();

    // 清理错误位置的 node_modules
    const wrongNodeModules = path.join(this.opencodeDir, 'node_modules');
    if (fs.existsSync(wrongNodeModules)) {
      console.log('清理错误位置的依赖...');
      fs.rmSync(wrongNodeModules, { recursive: true, force: true });
    }

    const bunCmd = this.getBunCommand();

    // 检查是否需要安装依赖
    const nodeModules = path.join(this.opcodePackageDir, 'node_modules');
    if (!fs.existsSync(nodeModules)) {
      console.log('首次构建，正在安装依赖...');
      await this.install();
    }

    try {
      execSync(`${bunCmd} run build`, {
        cwd: this.opcodePackageDir,
        stdio: 'inherit',
        env: { ...process.env, PATH: this.bunPath + ':' + process.env.PATH }
      });
      return true;
    } catch (error) {
      throw new Error(`编译失败: ${error.message}`);
    }
  }

  /**
   * 清理构建产物
   */
  async clean() {
    const distDir = path.join(this.opcodePackageDir, 'dist');

    if (fs.existsSync(distDir)) {
      fs.rmSync(distDir, { recursive: true, force: true });
    }

    const exePath = path.join(this.opcodePackageDir, 'opencode.exe');
    if (fs.existsSync(exePath)) {
      fs.unlinkSync(exePath);
    }
  }
}

module.exports = Build;
