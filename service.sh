#!/data/adb/magisk/busybox sh
MODDIR=${0%/*}

# 修复所有可执行文件的权限
chmod 755 ${MODDIR}/*.sh ${MODDIR}/openp2p 2>/dev/null

# 防止系统挂起
echo "PowerManagerService.noSuspend" > /sys/power/wake_lock 2>/dev/null
sleep 2
echo "PowerManagerService.noSuspend" > /sys/power/wake_unlock 2>/dev/null

# 启动核心服务（在后台运行）
${MODDIR}/openp2p_core.sh &
