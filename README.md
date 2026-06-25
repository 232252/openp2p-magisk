<div align="center">

# 🌐 OpenP2P Magisk Module

**让 Android 设备开机即拥有内网穿透能力,无需 root 折腾,刷完就用。**

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/232252/openp2p-magisk?style=flat-square)](https://github.com/232252/openp2p-magisk/releases/latest)
[![GitHub all releases](https://img.shields.io/github/downloads/232252/openp2p-magisk/total?style=flat-square)](https://github.com/232252/openp2p-magisk/releases)
[![GitHub stars](https://img.shields.io/github/stars/232252/openp2p-magisk?style=flat-square)](https://github.com/232252/openp2p-magisk/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/232252/openp2p-magisk?style=flat-square)](https://github.com/232252/openp2p-magisk/network/members)
[![GitHub issues](https://img.shields.io/github/issues/232252/openp2p-magisk?style=flat-square)](https://github.com/232252/openp2p-magisk/issues)
[![License](https://img.shields.io/github/license/232252/openp2p-magisk?style=flat-square)](LICENSE)
[![Magisk](https://img.shields.io/badge/Magisk-≥24.0-00B388?style=flat-square)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-兼容-1976D2?style=flat-square)](https://github.com/tiann/KernelSU)

<p align="center">
  <a href="#-快速开始">快速开始</a> ·
  <a href="#-功能特性">功能特性</a> ·
  <a href="#-配置说明">配置说明</a> ·
  <a href="#-管理命令">管理命令</a> ·
  <a href="#-故障排查">故障排查</a> ·
  <a href="#-常见问题">FAQ</a>
</p>

</div>

---

> 📦 本仓库基于 [OpenP2P](https://github.com/openp2p-cn/openp2p) 官方项目,封装为 **Magisk / KernelSU 模块**,实现 Android 设备的内网穿透服务**开机自启动 + 进程守护**。

## ✨ 这个模块能做什么

把你的 Android 手机 / 平板 / 电视变成一个**随时可达的内网节点**:

- 🏠 **远程回家**:在外面访问家里的 NAS / 智能家居 / 路由器
- 💼 **远程办公**:在公司连回家里或办公室的内网服务
- 🐛 **远程调试**:SSH / Web 后台 / 数据库 / 游戏服务器 都能穿透
- 🔌 **P2P 直连**:走的是 OpenP2P 的 P2P 通道,延迟低、不经过第三方中转

## 🚀 快速开始

### 一、获取 Token

前往 [OpenP2P 控制台](https://console.openp2p.cn) 注册并登录,创建一个节点,**复制节点 Token**(一串数字)。

### 二、下载并安装模块

1. 前往 [Releases](https://github.com/232252/openp2p-magisk/releases/latest) 下载最新的 `openp2p-magisk-*.zip`
2. 打开 **Magisk / KernelSU** → **模块** → **从存储安装**
3. 选中 zip,等待刷入完成
4. **重启设备**

### 三、配置 Token

模块默认会把模板配置文件复制到:

```
/sdcard/Documents/openp2p/config/config.json
```

用文件管理器编辑它,把 `Token` 改成你刚才复制的数字:

```json
{
  "network": {
    "Token": 1234567890123456789,
    "Node": "我的小米14",
    "ServerHost": "api.openp2p.cn"
  }
}
```

保存即可,守护进程会在下一个监测周期(默认 10 秒)自动重启服务。

### 四、验证

打开 Magisk → 模块,模块描述会显示 `运行中 | 我的小米14` ——恭喜,搞定 ✅

---

## 🎯 功能特性

| 特性 | 说明 |
| --- | --- |
| 🚀 开机自启 | 通过 `service.sh` 注册,系统启动完成后自动拉起 |
| 🛡 进程守护 | `openp2p_core.sh` 轮询检测,挂了自动重启 |
| ⚙️ 全部参数可配 | `config.json` 一处配置,Token / 节点名 / 服务器 / 日志级别 / 带宽共享 / 心跳间隔 / TLS 等 |
| 🔁 在线热更新 | 改完配置无需重启,下一个轮询周期生效 |
| 🧩 冲突规避 | 已修复与 easytier 等其他 VPN 模块的网关冲突 |
| 🪪 自动设备命名 | 默认使用 `品牌-型号` 作为节点名 |
| 📝 日志易读 | `/sdcard/Documents/openp2p/log/` 下分类保存 |
| 🤖 自动同步上游 | GitHub Actions 每天检查上游新版本,有更新自动打包 Beta |
| 🔐 权限自愈 | `post-fs-data.sh` 自动修复脚本和二进制的可执行权限 |

## 📂 文件结构

```
openp2p-magisk/
├── action.sh           # 手动管理入口(start / stop / restart / status / log)
├── openp2p             # OpenP2P 官方 arm64 二进制
├── openp2p_core.sh     # 守护进程主循环
├── service.sh          # Magisk 服务启动脚本
├── post-fs-data.sh     # 挂载后修复权限
├── uninstall.sh        # 卸载清理
├── module.prop         # Magisk 模块元数据
├── update.json         # Magisk 在线更新检查
├── config/
│   └── config.json     # 默认配置模板(首次启动复制到 /sdcard)
├── scripts/
│   └── release.sh      # 一键同步上游并打包
└── .github/
    └── workflows/
        └── update.yml  # 每日自动检测上游版本
```

## ⚙️ 配置说明

| 字段 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `network.Token` | string/number | `YOUR_TOKEN_HERE` | 控制台获取的节点 Token |
| `network.Node` | string | `""` | 节点显示名,留空则用 `品牌-型号` |
| `network.ShareBandwidth` | number | `50` | 共享带宽(Mbps),贡献给 P2P 通道 |
| `network.ServerHost` | string | `api.openp2p.cn` | OpenP2P 信令服务器 |
| `LogLevel` | number | `1` | 日志级别:0=error, 1=warn, 2=info, 3=debug |
| `MonitorInterval` | string | `10s` | 守护进程轮询间隔,支持 `s/m/h` |
| `TLSInsecureSkipVerify` | bool | `true` | 是否跳过 TLS 证书校验 |
| `Forcev6` | bool | `false` | 强制 IPv6 |
| `Timezone` | string | `Asia/Shanghai` | 时区(影响日志时间戳) |
| `MaxLogSize` | number | `1048576` | 日志最大字节数(1MB) |

> 💡 **安全提示**:Token 等同于你的节点控制权,**不要把含真实 Token 的 `config.json` 提交到公开仓库**。仓库中的默认模板只包含占位符。

## 🔧 管理命令

模块刷入后,所有脚本都位于:

```
/data/adb/modules/openp2p/
```

```bash
# 启动(无参数时默认就是 start,方便 Magisk 模块页面的"执行"按钮)
sh /data/adb/modules/openp2p/action.sh

# 停止
sh /data/adb/modules/openp2p/action.sh stop

# 重启
sh /data/adb/modules/openp2p/action.sh restart

# 查看运行状态(进程 + 网络连接)
sh /data/adb/modules/openp2p/action.sh status

# 查看最近 50 行运行日志
sh /data/adb/modules/openp2p/action.sh log

# 帮助
sh /data/adb/modules/openp2p/action.sh --help
```

## 🩺 故障排查

### 1. 模块描述一直显示 `请配置 Token`

**原因**:`config.json` 中的 Token 还是占位符 `YOUR_TOKEN_HERE` 或缺失。

**解决**:
```bash
# 用 ADB 推送一份正确的配置
adb push config.json /sdcard/Documents/openp2p/config/config.json
adb shell chmod 644 /sdcard/Documents/openp2p/config/config.json
```
或在手机文件管理器中编辑 `/sdcard/Documents/openp2p/config/config.json`。

### 2. 模块描述显示 `启动失败`

**原因**:openp2p 二进制没跑起来。

**排查步骤**:
```bash
# 看二进制和 openp2p 进程是否退出
sh /data/adb/modules/openp2p/action.sh status

# 看 openp2p 自己输出的日志
cat /sdcard/Documents/openp2p/log/openp2p.log

# 看守护进程的日志
cat /sdcard/Documents/openp2p/log/openp2p_core.log

# 看 Magisk 服务日志
cat /sdcard/Documents/openp2p/log/service.log
```

常见原因:
- **架构不匹配**:本模块只编译了 `arm64`,x86 模拟器请改用上游的 `linux-amd64` 二进制
- **网络受限**:部分国行 ROM 限制了开机自启,需要把 Magisk 加入自启动白名单
- **Token 无效**:复制时漏了字符

### 3. 内网穿透连不上 / 节点显示离线

- 确认控制台的 `节点状态` 是「在线」(OpenP2P 控制台 → 节点管理)
- 在手机上 `ping api.openp2p.cn` 看 DNS 是否正常
- 升级到最新版本:本模块跟随上游修复,旧版可能有已知的连接问题

### 4. 与 easytier / 其他 VPN 模块冲突

本模块已规避常见的网关冲突(见 commit `2d7aadd`),如果还是冲突:

1. 关闭其他 VPN 模块
2. 重启后只保留本模块,验证可用
3. 再依次打开其他模块,定位冲突源

### 5. 日志在哪

| 日志文件 | 内容 |
| --- | --- |
| `/sdcard/Documents/openp2p/log/action.log` | `action.sh` 手动管理记录 |
| `/sdcard/Documents/openp2p/log/service.log` | `service.sh` 开机启动记录 |
| `/sdcard/Documents/openp2p/log/openp2p_core.log` | 守护进程主循环日志 |
| `/sdcard/Documents/openp2p/log/openp2p.log` | OpenP2P 二进制自身输出 |

## ❓ 常见问题

**Q:这个模块 root 吗?需要解锁 Bootloader 吗?**
A:需要。Magisk / KernelSU 都需要解锁 BL + root。**没有 root 的设备用不了本模块**,可以装 OpenP2P 官方 APK。

**Q:会消耗多少流量?**
A:控制台有 `ShareBandwidth` 字段,默认 50Mbps 上行共享给 P2P 通道。如果不想贡献带宽可以改成 `0`,但会显著影响别人的穿透速度,建议保留。

**Q:跟 frp / 内网穿透工具比有什么优势?**
A:OpenP2P 走的是 P2P 直连,延迟低、不依赖固定公网 IP / 服务器中转。frp 需要你有公网服务器,ZeroTier 需要双方都能直连(国内网络环境不一定行)。

**Q:可以商用吗?**
A:可以,本仓库遵循上游 OpenP2P 的开源协议(MIT),使用时请遵守 [OpenP2P 服务条款](https://openp2p.cn)。

**Q:为什么不上 Magisk 仓库(Repo)?**
A:依赖用户自行配置 Token,目前只在本仓库分发,后续看社区反馈决定是否上架。

## 🛠 开发者

### 本地构建

```bash
# 同步上游 v3.25.11 并打包
./scripts/release.sh v3.25.11

# 仅打包当前仓库内容(假设二进制已就位)
zip -r openp2p-magisk-$(git describe --tags).zip \
    action.sh openp2p openp2p_core.sh \
    post-fs-data.sh service.sh uninstall.sh \
    module.prop update.json config/ \
    CHANGELOG.md LICENSE README.md \
    -x "*.git*" "openp2p-magisk-v*.zip" "scripts/*" ".github/*"
```

### 自动更新机制

`.github/workflows/update.yml` 每天 UTC 0:00(北京时间 8:00)运行:

1. 查询 [openp2p-cn/openp2p](https://github.com/openp2p-cn/openp2p/releases/latest) 最新版本
2. 对比当前模块版本,有更新就:
   - 下载新的 `android-arm64` 二进制
   - `module.prop` 版本号 +1(beta 标签)
   - 自动创建 Release

### 提 PR / Issue 之前

- 🐛 **Bug 报告**:附上 `openp2p_core.log` + 设备型号 / 系统版本 / 模块版本
- 💡 **功能建议**:先开 Issue 讨论,达成共识再发 PR
- 🔀 **PR**:保持单一改动,commit message 写清意图

## 📜 开源协议

本项目基于 **MIT License** 开源,详见 [LICENSE](LICENSE)。

模块内嵌的 `openp2p` 二进制版权归 [OpenP2P](https://github.com/openp2p-cn/openp2p) 所有。

## 🔗 相关链接

- [OpenP2P 官网](https://openp2p.cn)
- [OpenP2P 控制台](https://console.openp2p.cn)
- [OpenP2P GitHub](https://github.com/openp2p-cn/openp2p)
- [上游 Release Notes](https://github.com/openp2p-cn/openp2p/releases)
- [Magisk](https://github.com/topjohnwu/Magisk)
- [KernelSU](https://github.com/tiann/KernelSU)

---

<div align="center">

如果这个项目对你有帮助,欢迎点 ⭐ / 提 Issue / 提 PR 🙌

Made with ❤️ by [232252](https://github.com/232252) and contributors

</div>