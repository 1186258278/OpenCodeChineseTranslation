/**
 * CLI 入口模块
 * 使用 Commander.js 处理命令行参数
 */

const { Command } = require('commander');
const { checkEnvironment } = require('./env.js');
const { step, success, error, log } = require('./colors.js');
const { run: runMenu } = require('./menu.js');
const { VERSION } = require('./version.js');

// 导入命令
const updateCmd = require('../commands/update.js');
const applyCmd = require('../commands/apply.js');
const buildCmd = require('../commands/build.js');
const verifyCmd = require('../commands/verify.js');
const fullCmd = require('../commands/full.js');
const launchCmd = require('../commands/launch.js');
const helperCmd = require('../commands/helper.js');
const packageCmd = require('../commands/package.js');
const deployCmd = require('../commands/deploy.js');
const rollbackCmd = require('../commands/rollback.js');

/**
 * 创建 CLI 应用
 */
function createCLI() {
  const program = new Command();

  program
    .name('opencodenpm')
    .description('OpenCode 中文汉化管理工具')
    .version(VERSION);

  // update 命令
  program
    .command('update')
    .description('更新 OpenCode 源码到最新版本')
    .option('-f, --force', '强制重新克隆（删除现有目录）')
    .action(async (options) => {
      try {
        const result = await updateCmd.run(options);
        process.exit(result ? 0 : 1);
      } catch (e) {
        error(e.message);
        process.exit(1);
      }
    });

  // apply 命令
  program
    .command('apply')
    .description('应用汉化配置到源码')
    .option('-s, --silent', '静默模式')
    .option('-b, --backup', '应用前自动备份')
    .option('-r, --report', '生成翻译报告')
    .option('--strict', '严格模式（变量问题时失败）')
    .option('--dry-run', '模拟运行（不实际修改文件）')
    .option('--no-check-variables', '跳过变量保护检查')
    .action(async (options) => {
      try {
        const result = await applyCmd.run(options);
        // 检查返回结果
        if (typeof result === 'object') {
          const hasErrors = result.errors && result.errors.length > 0;
          process.exit(hasErrors ? 1 : 0);
        }
        process.exit(result ? 0 : 1);
      } catch (e) {
        error(e.message);
        process.exit(1);
      }
    });

  // build 命令
  program
    .command('build')
    .description('编译构建 OpenCode')
    .option('-p, --platform <platform>', '目标平台 (windows-x64, darwin-arm64, linux-x64)')
    .option('--no-deploy', '不部署到本地 bin 目录')
    .option('-s, --silent', '静默模式')
    .action(async (options) => {
      try {
        const result = await buildCmd.run(options);
        process.exit(result ? 0 : 1);
      } catch (e) {
        error(e.message);
        process.exit(1);
      }
    });

  // verify 命令
  program
    .command('verify')
    .description('验证汉化配置和覆盖率')
    .option('-d, --detailed', '显示详细信息')
    .option('--dry-run', '模拟运行检查（检测翻译匹配情况）')
    .option('--no-check-variables', '跳过变量保护检查')
    .action(async (options) => {
      try {
        const result = await verifyCmd.run(options);
        process.exit(result ? 0 : 1);
      } catch (e) {
        error(e.message);
        process.exit(1);
      }
    });

  // full 命令
  program
    .command('full')
    .description('完整工作流：更新 → 恢复 → 汉化 → 编译')
    .option('--skip-update', '跳过更新源码')
    .option('--skip-build', '跳过编译')
    .option('-y, --auto', '自动模式（跳过所有确认）')
    .action(async (options) => {
      try {
        const result = await fullCmd.run(options);
        process.exit(result ? 0 : 1);
      } catch (e) {
        error(e.message);
        process.exit(1);
      }
    });

  // env 命令
  program
    .command('env')
    .description('检查编译环境')
    .action(async () => {
      try {
        await checkEnvironment();
        process.exit(0);
      } catch (e) {
        error(e.message);
        process.exit(1);
      }
    });

  // config 命令
  program
    .command('config')
    .description('显示当前配置')
    .action(() => {
      const { getProjectDir, getOpencodeDir, getI18nDir, getBinDir } = require('./utils');
      log('项目配置:', 'cyan');
      log(`  项目目录: ${getProjectDir()}`);
      log(`  源码目录: ${getOpencodeDir()}`);
      log(`  汉化目录: ${getI18nDir()}`);
      log(`  输出目录: ${getBinDir()}`);
    });

  // launch 命令
  program
    .command('launch')
    .alias('start')
    .description('启动已编译的 OpenCode')
    .option('-b, --background', '后台启动')
    .action(async (options) => {
      try {
        const result = await launchCmd.run(options);
        process.exit(result ? 0 : 1);
      } catch (e) {
        error(e.message);
        process.exit(1);
      }
    });

  // helper 命令
  program
    .command('helper')
    .description('智谱助手 - 安装/启动')
    .option('-i, --install', '安装智谱助手')
    .option('-f, --force', '强制重装')
    .allowUnknownOption(true)
    .action(async (options) => {
      try {
        if (options.install) {
          const result = await helperCmd.install(options);
          process.exit(result ? 0 : 1);
        } else {
          // 转发其他参数给 coding-helper
          const args = process.argv.slice(3);
          await helperCmd.launch(args);
        }
      } catch (e) {
        error(e.message);
        process.exit(1);
      }
    });

  // package 命令
  program
    .command('package')
    .alias('pack')
    .description('打包 Releases (生成分发包)')
    .option('-p, --platform <platform>', '指定平台 (windows-x64, darwin-arm64, linux-x64)')
    .option('-a, --all', '打包所有平台')
    .option('--skip-binaries', '跳过编译二进制文件（只打包汉化工具源码）')
    .action(async (options) => {
      try {
        const result = await packageCmd.run(options);
        process.exit(result ? 0 : 1);
      } catch (e) {
        error(e.message);
        process.exit(1);
      }
    });

  // deploy 命令
  program
    .command('deploy')
    .description('部署 opencode 全局命令到三端')
    .action(async () => {
      try {
        const result = await deployCmd.run();
        process.exit(result ? 0 : 1);
      } catch (e) {
        error(e.message);
        process.exit(1);
      }
    });

  // rollback 命令
  program
    .command('rollback')
    .description('回滚到之前的备份')
    .option('-l, --list', '列出所有备份')
    .option('-i, --id <backupId>', '指定要回滚的备份ID')
    .action(async (options) => {
      try {
        const result = await rollbackCmd.run({
          backupId: options.id,
          list: options.list,
        });
        process.exit(result ? 0 : 1);
      } catch (e) {
        error(e.message);
        process.exit(1);
      }
    });

  // interactive 命令（默认命令）
  program
    .command('interactive', { isDefault: true })
    .alias('ui')
    .description('打开交互式菜单界面')
    .action(() => {
      runMenu();
    });

  return program;
}

/**
 * 运行 CLI
 */
function run() {
  const program = createCLI();
  program.parseAsync(process.argv).catch((err) => {
    error(err.message);
    process.exit(1);
  });
}

module.exports = { createCLI, run };
