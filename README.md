# OpenP2P Magisk Module

[![GitHub release](https://img.shields.io/github/v/release/232252/openp2p-magisk.svg)](https://github.com/232252/openp2p-magisk/releases)

Android Magisk 模块，实现 OpenP2P 内网穿透服务的开机自启动和后台运行。

## 📖 项目来源

本项目基于 [OpenP2P](https://github.com/openp2p-cn/openp2p) 官方项目打包为 Magisk 模块。

- **上游项目**: https://github.com/openp2p-cn/openp2p  
- **上游版本**: v3.25.8
- **模块版本**: 32508

## ✨ 功能特性

- ✅ 开机自启动
- ✅ 进程守护（自动重启）
- ✅ 支持 start/stop/restart/status/log 管理命令
- ✅ 从配置文件读取 Token
- ✅ 自动获取设备名称
- ✅ 兼容 easytier 等其他 VPN 模块（已修复网关冲突）

## 📦 安装

### 下载地址

**[📥 下载 openp2p-magisk-v3.25.8.zip](https://github.com/232252/openp2p-magisk/releases/download/v3.25.8/openp2p-magisk-v3.25.8.zip)**

1. 下载 zip 文件
2. Magisk Manager → 模块 → 从存储安装
3. 选择 zip 文件
4. 重启

## ⚙️ 配置

配置文件位置：
```
/sdcard/Documents/openp2p/config/config.json
```

配置 Token：
```json
{
  "network": {
    "Token": 你的TOKEN数字,
    "Node": "设备名称"
  }
}
```

Token 在 https://console.openp2p.cn 获取

## 🔧 管理命令

```bash
# 启动
/data/adb/modules/openp2p/action.sh start

# 停止
/data/adb/modules/openp2p/action.sh stop

# 重启
/data/adb/modules/openp2p/action.sh restart

# 状态
/data/adb/modules/openp2p/action.sh status

# 日志
/data/adb/modules/openp2p/action.sh log
```

## 🔗 相关链接

- [OpenP2P 官网](https://openp2p.cn)
- [OpenP2P 控制台](https://console.openp2p.cn)
- [OpenP2P GitHub](https://github.com/openp2p-cn/openp2p)

## 📜 许可证

MIT License
