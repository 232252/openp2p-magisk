#!/data/adb/magisk/busybox sh
MODDIR=${0%/*}
LOG_DIR="${MODDIR}/log"
LOG_FILE="${LOG_DIR}/service.log"
mkdir -p "${LOG_DIR}"
touch "${LOG_FILE}"
chmod 755 ${MODDIR}/*

# 日志输出函数
log() {
    local message="$(date "+%Y-%m-%d %H:%M:%S") $1"
    echo "$message"
    echo "$message" >> "${LOG_FILE}"
}

# 等待系统启动成功
echo "开始启动服务，等待系统启动完成..."
log "开始启动服务，等待系统启动完成..."
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 5s
done
echo "系统启动完成"
log "系统启动完成"

# 防止系统挂起
echo "获取唤醒锁"
log "获取唤醒锁"
echo "PowerManagerService.noSuspend" > /sys/power/wake_lock

# 修改模块描述
sed -i 's/^description=.*/description=[状态]启动中.../' "$MODDIR/module.prop"
echo "修改模块描述为启动中"
log "修改模块描述为启动中"

# 等待网络就绪
echo "等待网络就绪..."
log "等待网络就绪..."
sleep 10s
echo "网络就绪"
log "网络就绪"

# 启动核心服务
echo "启动核心服务"
log "启动核心服务"
"${MODDIR}/openp2p_core.sh" &

# 释放唤醒锁，允许系统正常休眠
sleep 2
echo "释放唤醒锁"
log "释放唤醒锁"
echo "PowerManagerService.noSuspend" > /sys/power/wake_unlock
echo "服务启动完成"
log "服务启动完成"
