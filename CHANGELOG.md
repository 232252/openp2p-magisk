# Changelog

## v3.26.0-beta1 (2026-06-22)
- 🚀 基于上游 [openp2p v3.25.11](https://github.com/openp2p-cn/openp2p/releases/tag/v3.25.11) 构建
- 🐛 修复 GitHub Actions 自动更新工作流中下载 URL 错误 (`linux-arm64` → `android-arm64`)
- 🐛 修复 `action.sh` 无参数执行时无响应的问题 ([#2](https://github.com/232252/openp2p-magisk/issues/2))，默认行为改为 `start`
- 🆕 `action.sh` 新增 `--help` 帮助输出
- 🔒 移除默认 `config.json` 中泄漏的 Token,改为占位符 `YOUR_TOKEN_HERE`
- 🎨 重写 README,增加徽章 / 目录 / 故障排查章节
- 📦 模块版本号与 update.json / module.prop 保持一致

## v3.25.11 (2026-05-15)
- 🚀 同步上游 openp2p v3.25.11
- ✅ 替换 openp2p 二进制为上游最新版本
- ✅ 修复 module.prop / update.json / README 版本号不一致
- ✅ 移除仓库内嵌套的旧版本 zip
- ✅ 重写 openp2p_core.sh,从 config.json 读取所有可配置参数
- ✅ action.sh 修复 token 数字格式误匹配 + stop 时 SIGKILL 兜底
- ✅ 新增 scripts/release.sh 自动化打包

## v3.25.7 (2026-03-19)
- 🚀 正式版发布
- ✅ 适配 console.openp2p.cn
- ✅ 使用官方安装脚本参数

## v3.24.23-beta (2026-03-16)
- 🧪 Beta 测试版