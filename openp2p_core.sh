#!/data/adb/magisk/busybox sh
MODDIR=${0%/*}
OPENP2P_DIR="/sdcard/Documents/openp2p"
CONFIG_FILE="${OPENP2P_DIR}/config/config.json"
LOG_DIR="${OPENP2P_DIR}/log"
LOG_FILE="${LOG_DIR}/openp2p_core.log"
MODULE_PROP="${MODDIR}/module.prop"
PID_FILE="${MODDIR}/openp2p.pid"

mkdir -p "${LOG_DIR}"
mkdir -p "${OPENP2P_DIR}/config"
touch "${LOG_FILE}"

log() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") $1" | tee -a "${LOG_FILE}"
}

# 与 action.sh 一致的 Token 解析逻辑
get_token() {
    if [ -f "$CONFIG_FILE" ]; then
        TOKEN=$(grep -o '"Token":[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed 's/.*"\([^"]*\)".*/\1/')
        if [ -z "$TOKEN" ] || [ "$TOKEN" = "YOUR_TOKEN_HERE" ] || [ "$TOKEN" = "Token" ]; then
            TOKEN=$(grep -o '"Token":[[:space:]]*[0-9]*' "$CONFIG_FILE" | grep -o '[0-9]*')
        fi
        echo "$TOKEN"
    fi
}

# 从配置文件读取 MonitorInterval
get_monitor_interval() {
    if [ -f "$CONFIG_FILE" ]; then
        INTERVAL=$(grep -o '"MonitorInterval":[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed 's/.*"\([^"]*\)".*/\1/')
        [ -n "$INTERVAL" ] && echo "$INTERVAL" || echo "10s"
    else
        echo "10s"
    fi
}

parse_interval() {
    local interval=$1
    local num=${interval%[smh]}
    local unit=${interval: -1}
    case "$unit" in
        m) echo $((num * 60)) ;;
        h) echo $((num * 3600)) ;;
        *) echo "$num" ;;
    esac
}

update_module_description() {
    sed -i "/^description=/c\\description=OpenP2P内网穿透服务 | $1" "$MODULE_PROP" 2>/dev/null
}

# 检查进程是否存活（与 action.sh 一致）
is_running() {
    [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

kill_openp2p() {
    if pgrep -f 'openp2p -d' >/dev/null 2>&1; then
        log "停止 openp2p 进程..."
        pkill -9 -f 'openp2p -d' 2>/dev/null
        rm -f "$PID_FILE"
        sleep 2
    fi
}

log "openp2p_core.sh 启动"

# 等待系统启动完成
while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ]; do
    sleep 5
done
log "系统启动完成"

# 守护循环
while true; do
    MONITOR_INTERVAL=$(get_monitor_interval)
    SLEEP_SECONDS=$(parse_interval "$MONITOR_INTERVAL")

    # 检查模块是否被禁用
    if ls ${MODDIR} | grep -q "disable"; then
        update_module_description "已禁用"
        kill_openp2p
        sleep "$SLEEP_SECONDS"
        continue
    fi

    # 检查配置文件
    if [ ! -f "$CONFIG_FILE" ]; then
        if [ -f "${MODDIR}/config/config.json" ]; then
            cp "${MODDIR}/config/config.json" "${CONFIG_FILE}"
            log "已复制默认配置到 ${CONFIG_FILE}"
        fi
        update_module_description "请配置 Token"
        sleep "$SLEEP_SECONDS"
        continue
    fi

    # 检查 Token
    TOKEN=$(get_token)
    if [ -z "$TOKEN" ] || [ "$TOKEN" = "0" ]; then
        update_module_description "请配置 Token"
        sleep "$SLEEP_SECONDS"
        continue
    fi

    # 启动进程（参数与 action.sh 保持一致）
    if ! is_running; then
        DEVICE_NAME="$(getprop ro.product.brand 2>/dev/null)-$(getprop ro.product.model 2>/dev/null)"
        log "启动 OpenP2P... Token: ${TOKEN:0:8}..."

        cd "$MODDIR"
        TZ=Asia/Shanghai nohup "${MODDIR}/openp2p" -d \
            -token "$TOKEN" \
            -node "${DEVICE_NAME}" \
            -serverhost api.openp2p.cn \
            -loglevel 1 \
            -sharebandwidth 50 \
            -insecure > "${LOG_DIR}/openp2p.log" 2>&1 &
        echo $! > "$PID_FILE"

        sleep 5

        if is_running; then
            log "OpenP2P 启动成功 (PID: $(cat "$PID_FILE"))"
            update_module_description "运行中 | ${DEVICE_NAME}"
        else
            log "OpenP2P 启动失败，请查看 ${LOG_DIR}/openp2p.log"
            update_module_description "启动失败"
            rm -f "$PID_FILE"
        fi
    fi

    sleep "$SLEEP_SECONDS"
done
