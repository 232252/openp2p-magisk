#!/system/bin/sh

# OpenP2P Magisk Module 管理脚本

MODDIR=${0%/*}
MODULE_DIR="/data/adb/modules/openp2p"
OPENP2P_DIR="/sdcard/Documents/openp2p"
CONFIG_FILE="${OPENP2P_DIR}/config/config.json"
LOG_DIR="${OPENP2P_DIR}/log"
LOG_FILE="${LOG_DIR}/action.log"
PID_FILE="${MODULE_DIR}/openp2p.pid"

chmod 755 "${MODDIR}"/*.sh "${MODDIR}/openp2p" 2>/dev/null

log() {
    mkdir -p "${LOG_DIR}"
    touch "${LOG_FILE}"
    echo "$(date "+%Y-%m-%d %H:%M:%S") $1" | tee -a "${LOG_FILE}"
}

# 统一的 Token 解析逻辑：先尝试字符串格式，再尝试数字格式
get_token() {
    if [ -f "$CONFIG_FILE" ]; then
        # 先尝试字符串格式 "Token": "xxx"
        TOKEN=$(grep -o '"Token":[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed 's/.*"\([^"]*\)".*/\1/')
        # 如果为空或为占位符，尝试数字格式 "Token": 12345
        if [ -z "$TOKEN" ] || [ "$TOKEN" = "YOUR_TOKEN_HERE" ] || [ "$TOKEN" = "Token" ]; then
            TOKEN=$(grep -o '"Token":[[:space:]]*[0-9]*' "$CONFIG_FILE" | grep -o '[0-9]*')
        fi
        echo "$TOKEN"
    fi
}

# 统一的启动参数
start_openp2p() {
    TOKEN=$(get_token)
    if [ -z "$TOKEN" ] || [ "$TOKEN" = "0" ]; then
        echo "错误: 请先在 ${CONFIG_FILE} 中配置 Token"
        log "错误: Token 未配置"
        exit 1
    fi

    DEVICE_NAME="$(getprop ro.product.brand)-$(getprop ro.product.model)"

    cd "$MODULE_DIR"
    TZ=Asia/Shanghai nohup "${MODULE_DIR}/openp2p" -d \
        -token "$TOKEN" \
        -node "${DEVICE_NAME}" \
        -serverhost api.openp2p.cn \
        -loglevel 1 \
        -sharebandwidth 50 \
        -insecure > "${LOG_DIR}/openp2p.log" 2>&1 &
    echo $! > "${PID_FILE}"
    log "OpenP2P 已启动 (PID: $!)"
}

# 检查进程是否存活
is_running() {
    [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

case "$1" in
    start)
        log "执行 start 命令"
        mkdir -p "${OPENP2P_DIR}/config" "${LOG_DIR}"

        if [ ! -f "$CONFIG_FILE" ]; then
            if [ -f "${MODDIR}/config/config.json" ]; then
                cp "${MODDIR}/config/config.json" "${CONFIG_FILE}"
                echo "已复制默认配置文件到 ${CONFIG_FILE}，请配置 Token"
                log "已复制默认配置文件到 ${CONFIG_FILE}"
                exit 1
            else
                echo "错误: 找不到默认配置文件"
                log "错误: 模块目录中没有 config/config.json"
                exit 1
            fi
        fi

        if is_running; then
            echo "OpenP2P 已在运行 (PID: $(cat "$PID_FILE"))"
            exit 0
        fi

        start_openp2p
        echo "启动完成，PID: $(cat "$PID_FILE")"
        ;;

    stop)
        log "执行 stop 命令"
        if is_running; then
            PID=$(cat "$PID_FILE")
            kill "$PID" 2>/dev/null
            rm -f "$PID_FILE"
            # 同时确保所有 openp2p 进程退出
            pkill -f 'openp2p -d' 2>/dev/null
            echo "OpenP2P 已停止 (PID: $PID)"
            log "OpenP2P 已停止 (PID: $PID)"
        else
            pkill -f 'openp2p -d' 2>/dev/null
            rm -f "$PID_FILE"
            echo "OpenP2P 未运行"
            log "OpenP2P 未运行，清理完成"
        fi
        ;;

    restart)
        log "执行 restart 命令"
        $0 stop
        sleep 2
        $0 start
        ;;

    status)
        if is_running; then
            echo "✅ OpenP2P 运行中 (PID: $(cat "$PID_FILE"))"
        else
            echo "❌ OpenP2P 未运行"
        fi
        ;;

    log)
        if [ -f "${LOG_DIR}/openp2p.log" ]; then
            echo "=== OpenP2P 日志 ==="
            tail -50 "${LOG_DIR}/openp2p.log"
        else
            echo "日志文件不存在"
        fi
        ;;

    *)
        echo "用法: $0 {start|stop|restart|status|log}"
        exit 1
        ;;
esac
