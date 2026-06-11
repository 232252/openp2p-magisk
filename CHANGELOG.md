# Changelog

## v3.25.11 (2026-06-11)

- 🔄 同步上游 OpenP2P v3.25.11
- ✅ 版本策略调整为直接使用上游版本号，避免版本跳跃导致自动更新失效
- ✅ 版本码格式统一为 `MAJOR * 1000000 + MINOR * 1000 + PATCH`
- ✅ 统一 action.sh 和 openp2p_core.sh 的 Token 解析和启动参数
- ✅ 启动参数增加 `-serverhost -loglevel -sharebandwidth -insecure`
- ✅ PID 文件统一为 `${MODDIR}/openp2p.pid`
- ✅ module.prop / update.json / README.md 版本信息保持一致
- ✅ config.json Token 改为占位符 `0`
- ✅ 更新 CHANGELOG、模块描述与卸载脚本

## v3.26.0-beta1 (历史版本，仅供参考)

- 同步上游 OpenP2P v3.25.8

## v3.25.7 (2026-03-19)

- 🚀 正式版发布
- ✅ 适配 console.openp2p.cn
- ✅ 使用官方安装脚本参数

## v3.24.23-beta (2026-03-16)

- 🧪 Beta 测试版
