/**
 * 版本管理模块
 * 统一管理项目版本号，一处修改，全局生效
 */

const VERSION = '7.1.0';
const VERSION_SHORT = 'v7.1';
const APP_NAME = 'OpenCode 汉化管理工具';

module.exports = {
  VERSION,
  VERSION_SHORT,
  APP_NAME,

  // 完整标题
  getTitle() {
    return `${APP_NAME} ${VERSION_SHORT}`;
  },

  // 获取版本信息对象
  getInfo() {
    return {
      version: VERSION,
      versionShort: VERSION_SHORT,
      name: APP_NAME,
    };
  },
};
