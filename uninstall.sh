#!/system/bin/sh
# OpenP2P 卸载脚本

MODDIR=${0%/*}

# 停止所有 openp2p 进程
pkill -f 'openp2p -d' 2>/dev/null
pkill -f 'openp2p' 2>/dev/null
rm -f "${MODDIR}/openp2p.pid" 2>/dev/null

# 清理配置和日志（保留用户配置，仅删除模块目录）
rm -f "${MODDIR}/openp2p" 2>/dev/null
rm -f "${MODDIR}"/*.sh 2>/dev/null

echo "OpenP2P 模块已卸载，用户配置保留在 /sdcard/Documents/openp2p/"
