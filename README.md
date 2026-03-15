# OpenP2P Magisk Module

[![Update Binary](https://github.com/232252/openp2p-magisk/actions/workflows/update.yml/badge.svg)](https://github.com/232252/openp2p-magisk/actions/workflows/update.yml)
[![GitHub release](https://img.shields.io/github/release/232252/openp2p-magisk.svg)](https://github.com/232252/openp2p-magisk/releases)

Android Magisk 模块，实现 OpenP2P 内网穿透服务的开机自启动和后台运行。

## 📖 项目来源

本项目基于 [OpenP2P](https://github.com/openp2p-cn/openp2p) 官方项目打包为 Magisk 模块。

- **上游项目**: https://github.com/openp2p-cn/openp2p
- **上游版本**: v3.25.7
- **模块版本**: 32507

## ✨ 功能特性

- ✅ 开机自启动
- ✅ 进程守护（自动重启）
- ✅ 支持 start/stop/restart/status/log 管理命令
- ✅ 从配置文件读取 Token
- ✅ 自动获取设备名称
- ✅ 支持 GitHub Actions 自动更新二进制文件

## 📦 安装方法

### 方法一：下载 Release 包

1. 前往 [Releases](https://github.com/232252/openp2p-magisk/releases) 页面
2. 下载最新的 `openp2p-magisk-vX.X.X.zip`
3. 在 Magisk Manager 中选择"从本地安装"
4. 选择下载的 zip 文件
5. 重启手机

### 方法二：手动安装

```bash
# 克隆仓库
git clone https://github.com/232252/openp2p-magisk.git

# 进入目录
cd openp2p-magisk

# 压缩为 zip
zip -r openp2p-magisk.zip *

# 通过 adb 推送到手机
adb push openp2p-magisk.zip /sdcard/

# 在 Magisk Manager 中安装
```

## ⚙️ 配置

### 配置文件位置

安装后，配置文件位于：

```
/sdcard/Documents/openp2p/config/config.json
```

### 配置文件参数解释

```json
{
  "network": {
    "Token": "YOUR_TOKEN_HERE",       // OpenP2P 控制台获取的令牌
    "Node": "",                       // 节点名称，留空时自动使用设备名称
    "User": "",                       // 用户名
    "ShareBandwidth": 50,              // 共享带宽，单位Mbps
    "ServerHost": "api.openp2p.cn",   // 服务器主机名
    "ServerIP": "",                   // 服务器IP地址
    "ServerPort": 27183,               // 服务器端口
    "PublicIPPort": 7037               // 公网IP端口
  },
  "apps": null,                        // 应用配置，null表示默认配置
  "LogLevel": 1,                       // 日志级别，1-5，数字越大日志越详细
  "MaxLogSize": 1048576,               // 最大日志大小，单位字节
  "TLSInsecureSkipVerify": true,      // 是否跳过TLS验证
  "Forcev6": false,                    // 是否强制使用IPv6
  "MonitorInterval": "10s",           // 监控间隔时间，支持秒(s)、分钟(m)、小时(h)格式，例如：10s, 1m, 1h
  "MonitorIntervalDesc": "监控间隔时间，支持秒(s)、分钟(m)、小时(h)格式，例如：10s, 1m, 1h",
  "ConfigDesc": "配置文件参数说明：\n1. network.Token: 字符串，OpenP2P 控制台获取的令牌\n2. network.Node: 字符串，节点名称，留空时自动使用设备名称\n3. network.User: 字符串，用户名\n4. network.ShareBandwidth: 数字，共享带宽，单位Mbps\n5. network.ServerHost: 字符串，服务器主机名\n6. network.ServerIP: 字符串，服务器IP地址\n7. network.ServerPort: 数字，服务器端口\n8. network.PublicIPPort: 数字，公网IP端口\n9. apps: 应用配置，null表示默认配置\n10. LogLevel: 数字，日志级别，1-5，数字越大日志越详细\n11. MaxLogSize: 数字，最大日志大小，单位字节\n12. TLSInsecureSkipVerify: 布尔值，是否跳过TLS验证\n13. Forcev6: 布尔值，是否强制使用IPv6\n14. MonitorInterval: 字符串，监控间隔时间，支持秒(s)、分钟(m)、小时(h)格式，例如：10s, 1m, 1h"
}
```

**重要**: 将 `YOUR_TOKEN_HERE` 替换为你的实际 Token（从 https://console.openp2p.cn 获取）

## 🔧 管理命令

```bash
# 启动
/data/adb/modules/openp2p/action.sh start

# 停止
/data/adb/modules/openp2p/action.sh stop

# 重启
/data/adb/modules/openp2p/action.sh restart

# 查看状态
/data/adb/modules/openp2p/action.sh status

# 查看日志
/data/adb/modules/openp2p/action.sh log
```

## 📁 模块结构

```
/data/adb/modules/openp2p/
├── openp2p           # 主程序
├── module.prop       # 模块信息
├── service.sh        # Magisk 开机启动入口
├── openp2p_core.sh   # 核心守护脚本
├── action.sh         # 管理脚本
├── uninstall.sh      # 卸载脚本
└── config/
    └── config.json   # 默认配置文件（安装时会复制到 /sdcard/Documents/openp2p/config/）
```

### 数据目录结构

```
/sdcard/Documents/openp2p/
├── config/
│   └── config.json   # 配置文件（实际使用的配置文件）
└── log/              # 日志目录
    ├── service.log        # service.sh 日志
    ├── openp2p_core.log   # openp2p_core.sh 日志
    ├── action.log         # action.sh 日志
    └── openp2p.log        # OpenP2P 主程序日志
```

## 🔄 自动更新

本项目通过 GitHub Actions 自动检测 OpenP2P 官方更新：

- 每天自动检查上游新版本
- 发现新版本时自动更新二进制文件
- 自动创建 Release

## 📋 系统要求

- Android 设备已 Root
- Magisk v20.4+
- ARM64 架构

## 🔗 相关链接

- OpenP2P 官网: https://openp2p.cn
- OpenP2P 控制台: https://console.openp2p.cn
- OpenP2P GitHub: https://github.com/openp2p-cn/openp2p
- Magisk 官网: https://topjohnwu.github.io/Magisk/

## 📜 许可证

本项目采用 MIT 许可证。

OpenP2P 二进制文件遵循其原始许可证。

## 🙏 致谢

- [OpenP2P](https://github.com/openp2p-cn/openp2p) - 核心内网穿透功能
- [Magisk](https://github.com/topjohnwu/Magisk) - Android Root 框架
