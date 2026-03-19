#!/data/adb/magisk/busybox sh
MODDIR=${0%/*}
OPENP2P_DIR="/sdcard/Documents/openp2p"
CONFIG_FILE="${OPENP2P_DIR}/config/config.json"
LOG_DIR="${OPENP2P_DIR}/log"
LOG_FILE="${LOG_DIR}/openp2p_core.log"
MODULE_PROP="${MODDIR}/module.prop"
OPENP2P="${MODDIR}/openp2p"

# Create directories
mkdir -p "${LOG_DIR}"
mkdir -p "${OPENP2P_DIR}/config"
touch "${LOG_FILE}"

log() {
    local message="$(date "+%Y-%m-%d %H:%M:%S") $1"
    echo "$message"
    echo "$message" >> "${LOG_FILE}"
}

get_token() {
    if [ -f "$CONFIG_FILE" ]; then
        TOKEN=$(grep -o '"Token": *[0-9]*' "$CONFIG_FILE" | grep -o '[0-9]*')
        echo "$TOKEN"
    fi
}

get_monitor_interval() {
    if [ -f "$CONFIG_FILE" ]; then
        INTERVAL=$(grep -o '"MonitorInterval": *"[^"]*"' "$CONFIG_FILE" | sed 's/"MonitorInterval": *"\([^"]*\)"/\1/')
        [ -n "$INTERVAL" ] && echo "$INTERVAL" || echo "10s"
    else
        echo "10s"
    fi
}

parse_interval() {
    local interval=$1
    local num=${interval%[smh]}
    local unit=${interval: -1}
    case $unit in
        m) echo $((num * 60)) ;;
        h) echo $((num * 3600)) ;;
        *) echo $num ;;
    esac
}

update_module_description() {
    sed -i "/^description=/c\description=[状态]${1}" ${MODULE_PROP}
}

# Check and create TUN device
create_tun() {
    if [ ! -e /dev/net/tun ]; then
        mkdir -p /dev/net
        ln -sf /dev/tun /dev/net/tun 2>/dev/null
    fi
}

# Kill any existing openp2p processes
kill_openp2p() {
    if pgrep -f 'openp2p' >/dev/null 2>&1; then
        log "Stopping existing openp2p processes..."
        pkill -9 openp2p 2>/dev/null
        sleep 2
    fi
}

create_tun
kill_openp2p

while true; do
    MONITOR_INTERVAL=$(get_monitor_interval)
    SLEEP_SECONDS=$(parse_interval "$MONITOR_INTERVAL")
    
    if ls ${MODDIR} | grep -q "disable"; then
        update_module_description "已禁用"
        kill_openp2p
    else
        if [ ! -f "$CONFIG_FILE" ]; then
            if [ -f "${MODDIR}/config/config.json" ]; then
                cp "${MODDIR}/config/config.json" "${CONFIG_FILE}"
                log "Default config copied to ${CONFIG_FILE}"
            fi
        fi
        
        TOKEN=$(get_token)
        if [ -z "$TOKEN" ] || [ "$TOKEN" = "YOUR_TOKEN_HERE" ]; then
            update_module_description "请配置 Token"
        else
            DEVICE_NAME="$(getprop ro.product.brand)-$(getprop ro.product.model)"
            
            if ! pgrep -f 'openp2p -d' >/dev/null 2>&1; then
                log "Starting OpenP2P with token: ${TOKEN:0:8}..."
                
                cd ${MODDIR}
                TZ=Asia/Shanghai nohup ${OPENP2P} -d \
                    -token ${TOKEN} \
                    -node "${DEVICE_NAME}" \
                    -serverhost api.openp2p.cn \
                    -loglevel 1 \
                    -sharebandwidth 50 \
                    -insecure > "${LOG_DIR}/openp2p.log" 2>&1 &
                
                sleep 5
                
                if pgrep -f 'openp2p -d' >/dev/null 2>&1; then
                    log "OpenP2P started successfully"
                    update_module_description "运行中 | ${DEVICE_NAME}"
                else
                    log "OpenP2P failed to start"
                    update_module_description "启动失败"
                fi
            fi
        fi
    fi
    
    sleep ${SLEEP_SECONDS}
done
