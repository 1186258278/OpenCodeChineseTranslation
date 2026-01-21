/**
 * 交互式菜单模块
 * v7.1 - 异步版本检测，动态更新状态栏
 */

const { existsSync } = require('node:fs');
const { exec } = require('node:child_process');
const { execSync } = require('node:child_process');
const path = require('node:path');
const { getProjectDir, getOpencodeDir, getI18nDir, getBinDir } = require('./utils.js');
const { step, success, warn, error, log } = require('./colors.js');
const { createGridMenu, confirm: gridConfirm, showMessage, waitForKey } = require('./grid-menu.js');
const { getTitle, VERSION_SHORT } = require('./version.js');

// 导入功能模块
const updateCmd = require('../commands/update.js');
const applyCmd = require('../commands/apply.js');
const buildCmd = require('../commands/build.js');
const verifyCmd = require('../commands/verify.js');
const launchCmd = require('../commands/launch.js');
const helperCmd = require('../commands/helper.js');
const packageCmd = require('../commands/package.js');
const deployCmd = require('../commands/deploy.js');
const rollbackCmd = require('../commands/rollback.js');
const antigravityCmd = require('../commands/antigravity.js');
const ohmyopencodeCmd = require('../commands/ohmyopencode.js');
const githubCmd = require('../commands/github.js');
const { cleanRepo } = require('../core/git.js');

/**
 * 异步执行命令
 */
function execAsync(cmd, options) {
  return new Promise((resolve) => {
    exec(cmd, { ...options, encoding: 'utf-8' }, (err, stdout) => {
      if (err) {
        resolve({ success: false, output: '' });
      } else {
        resolve({ success: true, output: stdout.trim() });
      }
    });
  });
}

/**
 * 异步检查脚本更新 (通过 git fetch)
 */
async function checkScriptUpdateAsync() {
  try {
    // 先 fetch 获取远程最新信息
    await execAsync('git fetch --quiet', { cwd: getProjectDir(), timeout: 10000 });

    const result = await execAsync('git rev-list --count --left-right main...@{u}', {
      cwd: getProjectDir(),
      timeout: 5000,
    });

    if (result.success && result.output) {
      const [ahead, behind] = result.output.split('\t').map(Number);
      return { ahead: ahead || 0, behind: behind || 0, hasUpdate: (behind || 0) > 0, checked: true };
    }
  } catch (e) {}
  return { ahead: 0, behind: 0, hasUpdate: false, checked: true };
}

/**
 * 异步检查 OpenCode 源码更新 (通过 git fetch)
 */
async function checkSourceUpdateAsync() {
  const opencodeDir = getOpencodeDir();

  if (!existsSync(opencodeDir)) {
    return { hasUpdate: false, checked: true };
  }

  try {
    // 先 fetch 获取远程最新
    await execAsync('git fetch --quiet', { cwd: opencodeDir, timeout: 10000 });

    const localResult = await execAsync('git rev-parse HEAD', { cwd: opencodeDir, timeout: 5000 });
    const remoteResult = await execAsync('git rev-parse @{u}', { cwd: opencodeDir, timeout: 5000 });

    if (localResult.success && remoteResult.success) {
      const hasUpdate = localResult.output !== remoteResult.output;
      return { hasUpdate, checked: true };
    }
  } catch (e) {}
  return { hasUpdate: false, checked: true };
}

/**
 * 获取基础状态（同步，快速）
 */
function getBasicStatus() {
  const opencodeDir = getOpencodeDir();
  const i18nDir = getI18nDir();
  const binDir = getBinDir();
  const platform = process.platform;
  const exeName = platform === 'win32' ? 'opencode.exe' : 'opencode';

  // 获取 Bun 版本状态
  const { getCurrentBunVersion, getRecommendedBunVersion } = require('./env.js');
  const currentBun = getCurrentBunVersion();
  const recommendedBun = getRecommendedBunVersion();

  return {
    opencodeExists: existsSync(opencodeDir),
    i18nExists: existsSync(i18nDir),
    binExists: existsSync(path.join(binDir, exeName)),
    opencodeDir,
    currentBun,
    recommendedBun
  };
}

/**
 * 构建状态行
 */
function buildStatusLines(basicStatus, updateStatus = null) {
  const statusLines = [];
  const opencodeDir = basicStatus.opencodeDir;
  const shortPath = opencodeDir.length > 35 ? '...' + opencodeDir.slice(-32) : opencodeDir;

  // 第一行：版本和路径
  statusLines.push(`{cyan-fg}版本{/cyan-fg} ${VERSION_SHORT}  {cyan-fg}路径{/cyan-fg} ${shortPath}`);

  // 第二行：基础状态 + Bun 版本
  const srcStatus = basicStatus.opencodeExists ? '{green-fg}✓源码{/green-fg}' : '{red-fg}✗源码{/red-fg}';
  const i18nStatus = basicStatus.i18nExists ? '{green-fg}✓汉化{/green-fg}' : '{red-fg}✗汉化{/red-fg}';
  const binStatus = basicStatus.binExists ? '{green-fg}✓已编译{/green-fg}' : '{yellow-fg}○未编译{/yellow-fg}';
  
  let bunStatus = '{gray-fg}○ Bun未知{/gray-fg}';
  if (basicStatus.currentBun) {
    if (basicStatus.currentBun === basicStatus.recommendedBun) {
      bunStatus = `{green-fg}✓ Bun v${basicStatus.currentBun}{/green-fg}`;
    } else {
      bunStatus = `{red-fg}! Bun v${basicStatus.currentBun} (推荐 ${basicStatus.recommendedBun}){/red-fg}`;
    }
  } else {
    bunStatus = `{red-fg}✗ Bun未安装{/red-fg}`;
  }

  statusLines.push(`${srcStatus}  ${i18nStatus}  ${binStatus}  ${bunStatus}`);

  // 第三行：更新状态（异步加载）- 明确标注脚本和源码
  if (!updateStatus) {
    statusLines.push('{gray-fg}○ 检测更新中...{/gray-fg}');
  } else {
    const updates = [];

    // 汉化脚本状态
    if (updateStatus.script?.hasUpdate) {
      updates.push(`{yellow-fg}● 汉化脚本可更新(${updateStatus.script.behind}){/yellow-fg}`);
    } else if (updateStatus.script?.checked) {
      updates.push('{green-fg}✓ 汉化脚本最新{/green-fg}');
    }

    // OpenCode源码状态
    if (updateStatus.source?.hasUpdate) {
      updates.push('{yellow-fg}● OpenCode可更新{/yellow-fg}');
    } else if (updateStatus.source?.checked) {
      updates.push('{green-fg}✓ OpenCode最新{/green-fg}');
    }

    // 本地未推送提交
    if (updateStatus.script?.ahead > 0) {
      updates.push(`{cyan-fg}○ ${updateStatus.script.ahead}个本地提交{/cyan-fg}`);
    }

    statusLines.push(updates.join('  '));
  }

  return statusLines;
}

/**
 * 显示主菜单 (网格布局 + 异步更新检测)
 */
async function showMainMenu() {
  const basicStatus = getBasicStatus();
  const initialStatusLines = buildStatusLines(basicStatus, null);

  // 网格菜单项 (3列布局)
  const items = [
    { name: '[*] 一键全流程', value: 'full', desc: '一键全流程：源码更新 + 恢复 + 汉化应用 + 验证 + 编译构建。推荐首次使用。' },
    { name: '[>] 更新源码', value: 'update', desc: '从 GitHub 获取最新 OpenCode 源码。如遇冲突可选择强制覆盖。' },
    { name: '[~] 恢复源码', value: 'restore', desc: '清除源码目录中的所有本地修改，恢复到 Git 纯净状态。用于解决汉化冲突。' },
    { name: '[W] 应用汉化', value: 'apply', desc: '将 opencode-i18n 中的汉化配置注入到源码中。包含变量保护和备份功能。' },
    { name: '[V] 验证汉化', value: 'verify', desc: '检查汉化配置格式、变量完整性以及翻译覆盖率。推荐在编译前运行。' },
    { name: '[#] 编译构建', value: 'build', desc: '使用 Bun 编译生成 OpenCode 可执行文件。自动处理多平台构建。' },
    { name: '[<] 回滚备份', value: 'rollback', desc: '回滚到上一次应用汉化前的状态。支持查看备份列表和指定版本回滚。' },
    { name: '[^] 部署命令', value: 'deploy', desc: '将编译好的 opencode 命令部署到系统 PATH，使其在任意终端可用。' },
    { name: '[=] 打包三端', value: 'package-all', desc: '为 Win/Mac/Linux 平台打包发布版 ZIP 文件，生成 Release Notes 和校验码。' },
    { name: '[P] 启动OpenCode', value: 'launch', desc: '直接启动当前已编译好的 OpenCode 程序。支持后台运行模式。' },
    { name: '[A] Antigravity', value: 'antigravity', desc: '配置 Antigravity 本地 AI 代理服务 (Claude/GPT/Gemini)，用于智能体功能。' },
    { name: '[O] Oh-My-OC', value: 'ohmyopencode', desc: '安装 Oh-My-OpenCode 插件，启用智能体、Git 增强、LSP 等高级功能。' },
    { name: '[@] 智谱助手', value: 'helper', desc: '安装并启动智谱编码助手 (Coding Helper)，提供代码补全和解释功能。' },
    { name: '[G] GitHub仓库', value: 'github', desc: '在浏览器中打开项目仓库 (GitHub/Gitee)，查看源码或提交 Issue。' },
    { name: '[?] 检查环境', value: 'env', desc: '检查 Node.js, Bun, Git 等开发环境是否满足编译要求。' },
    { name: '[B] 校准 Bun', value: 'fix-bun', desc: '强制将 Bun 版本校准为项目推荐版本 (v1.3.5)，解决兼容性问题。' },
    { name: '[U] 更新脚本', value: 'update-script', desc: '从 Git 更新本汉化管理脚本到最新版本。不影响 OpenCode 源码。' },
    { name: '[S] 显示配置', value: 'config', desc: '显示当前项目、源码、汉化、输出目录的路径配置信息。' },
    { name: '[X] 退出', value: 'exit', desc: '退出管理工具。' },
  ];

  // 异步更新回调
  const onAsyncUpdate = (updateFn) => {
    // 并行检测脚本和源码更新
    Promise.all([
      checkScriptUpdateAsync(),
      checkSourceUpdateAsync(),
    ]).then(([scriptUpdate, sourceUpdate]) => {
      const newStatusLines = buildStatusLines(basicStatus, {
        script: scriptUpdate,
        source: sourceUpdate,
      });
      updateFn(newStatusLines);
    }).catch(() => {
      // 检测失败时显示错误状态
      const errorLines = buildStatusLines(basicStatus, { script: {}, source: {} });
      updateFn(errorLines);
    });
  };

  // 教程数据
  const tutorials = [
    {
      title: 'OpenCode 基础',
      content: [
        '{bold}核心功能{/}: 开源 AI 编程助手，TUI 界面，支持鼠标',
        '1. {yellow}连接模型{/}: 运行后输入 {dim}/connect{/} 配置 API Key',
        '2. {yellow}汉化流程{/}: 更新源码 -> 应用汉化 -> 编译构建',
        '3. {yellow}常用命令{/}: {dim}/theme{/} 换肤, {dim}/share{/} 分享对话',
        '{cyan}推荐使用 [一键全流程] 完成汉化和编译{/}'
      ]
    },
    {
      title: 'Oh-My-OpenCode',
      content: [
        'OpenCode 的{green}增强扩展插件{/} (类似 Oh My Zsh)',
        '• {bold}智能体{/}: Sisyphus(编排), Oracle(分析), Librarian(研究)',
        '• {bold}功能{/}: 多模型协作, 提示词优化, 后台任务管理',
        '• {bold}安装{/}: 运行 {yellow}[O] Oh-My-OC{/} 菜单一键安装',
        '{dim}配置文件: ~/.config/opencode/oh-my-opencode.json{/}'
      ]
    },
    {
      title: '自定义模型',
      content: [
        '配置文件: {dim}~/.config/opencode/opencode.json{/}',
        '1. {bold}一键配置{/}: 使用 {yellow}[A] Antigravity{/} 配置本地模型',
        '2. {bold}手动配置{/}: 在 {dim}provider{/} 字段添加 OpenAI 兼容接口',
        '   (如 DeepSeek, Claude, Gemini, GLM 等)',
        '{cyan}支持配置 baseURL, apiKey 和自定义 models 列表{/}'
      ]
    },
    {
      title: '汉化工具指南',
      content: [
        '• {bold}导航{/}: ↑↓←→ 移动, Enter 确认, 1-9 数字键快捷选择',
        '• {bold}Tab键{/}: 切换下方教程板块',
        '• {bold}故障恢复{/}: {yellow}[~] 恢复源码{/} 清除所有修改',
        '• {bold}回滚{/}: {yellow}[<] 回滚备份{/} 还原到汉化前状态',
        '{dim}项目地址: github.com/1186258278/OpenCodeChineseTranslation{/}'
      ]
    }
  ];

  const action = await createGridMenu({
    title: getTitle(),
    statusLines: initialStatusLines,
    items,
    columns: 3,
    onAsyncUpdate,
    tutorials,
  });

  return action;
}

/**
 * 执行完整工作流
 */
async function runFullWorkflow() {
  step('开始完整工作流...');

  step('[1/4] 更新 OpenCode 源码');
  await updateCmd.run({});

  step('[2/4] 应用汉化配置');
  await applyCmd.run({});

  step('[3/4] 验证汉化配置');
  await verifyCmd.run({});

  step('[4/4] 编译构建');
  await buildCmd.run({});

  success('完整工作流执行完成!');
}

/**
 * 更新脚本
 */
async function updateScript() {
  step('更新脚本到最新版本...');
  try {
    execSync('git pull --ff-only', {
      cwd: getProjectDir(),
      stdio: 'inherit',
    });
    success('脚本已更新!');

    log('\n正在重新加载...', 'cyan');

    Object.keys(require.cache).forEach(key => {
      if (key.includes('scripts')) {
        delete require.cache[key];
      }
    });

    const { spawn } = require('node:child_process');
    const child = spawn(process.argv[0], process.argv.slice(1), {
      cwd: process.cwd(),
      stdio: 'inherit',
      detached: false,
    });

    child.on('exit', (code) => process.exit(code));
    return;
  } catch (e) {
    error('更新失败，可能存在本地修改');
    const confirmForce = await gridConfirm('是否强制覆盖本地修改?', false);

    if (confirmForce) {
      execSync('git reset --hard @{u}', {
        cwd: getProjectDir(),
        stdio: 'inherit',
      });
      success('脚本已强制更新!');

      const { spawn } = require('node:child_process');
      const child = spawn(process.argv[0], process.argv.slice(1), {
        cwd: process.cwd(),
        stdio: 'inherit',
        detached: false,
      });
      child.on('exit', (code) => process.exit(code));
    }
  }
}

/**
 * 运行菜单循环
 */
async function run() {
  while (true) {
    try {
      const action = await showMainMenu();

      switch (action) {
        case 'full':
          await runFullWorkflow();
          break;
        case 'update':
          await updateCmd.run({});
          break;
        case 'restore':
          await cleanRepo(getOpencodeDir());
          break;
        case 'apply':
          await applyCmd.run({});
          break;
        case 'build':
          await buildCmd.run({});
          break;
        case 'verify':
          await verifyCmd.run({ detailed: true });
          break;
        case 'rollback':
          await rollbackCmd.run({ list: true });
          const doRollback = await gridConfirm('是否执行回滚到最新备份?', false);
          if (doRollback) {
            await rollbackCmd.run({});
          }
          break;
        case 'launch':
          await launchCmd.run({});
          break;
        case 'deploy':
          await deployCmd.run({});
          break;
        case 'package-all':
          await packageCmd.run({ all: true });
          break;
        case 'antigravity':
          await antigravityCmd.run({});
          break;
        case 'ohmyopencode':
          await ohmyopencodeCmd.run({});
          break;
        case 'github':
          await githubCmd.run({});
          break;
        case 'helper':
          const helperItems = [
            { name: '[I] 安装/更新', value: 'install' },
            { name: '[L] 启动', value: 'launch' },
            { name: '[B] 返回', value: 'back' },
          ];
          const helperAction = await createGridMenu({
            title: '智谱助手',
            statusLines: ['选择操作:'],
            items: helperItems,
            columns: 3,
          });
          if (helperAction === 'install') {
            await helperCmd.install({});
          } else if (helperAction === 'launch') {
            await helperCmd.launch([]);
          }
          break;
        case 'update-script':
          await updateScript();
          return;
        case 'env':
          const envResult = await require('./env.js').checkEnvironment();
          if (envResult.bunStatus && !envResult.bunStatus.match) {
            console.log('');
            const doFix = await gridConfirm(`检测到 Bun 版本不匹配，是否立即校准为 v${envResult.bunStatus.recommended}?`, true);
            if (doFix) {
              await require('./env.js').installBun(envResult.bunStatus.recommended);
            }
          }
          break;
        case 'fix-bun':
          const { getRecommendedBunVersion, installBun } = require('./env.js');
          const recVersion = getRecommendedBunVersion();
          const confirmFix = await gridConfirm(`确认将 Bun 版本校准为 v${recVersion}?`, true);
          if (confirmFix) {
            await installBun(recVersion);
          }
          break;
        case 'config':
          log('\n项目配置:', 'cyan');
          log(`  项目目录: ${getProjectDir()}`);
          log(`  源码目录: ${getOpencodeDir()}`);
          log(`  汉化目录: ${getI18nDir()}`);
          log(`  输出目录: ${getBinDir()}`);
          break;
        case 'exit':
          log('\n再见!\n');
          process.exit(0);  // 直接退出进程
      }

      // 操作完成后，在主屏幕等待用户按键
      success('\n✓ 操作完成');
      await waitForKey();
    } catch (e) {
      error(e.message);
      await waitForKey('按任意键返回菜单...');
    }
  }
}

module.exports = { run };
