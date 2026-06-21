#!/data/adb/magisk/busybox sh
# OpenP2P 守护脚本 - 启动并守护 openp2p 进程
# 全部参数从 config.json 读取
# 兼容 busybox ash / POSIX sh

MODDIR=${0%/*}
OPENP2P_DIR="/sdcard/Documents/openp2p"
CONFIG_FILE="${OPENP2P_DIR}/config/config.json"
LOG_DIR="${OPENP2P_DIR}/log"
LOG_FILE="${LOG_DIR}/openp2p_core.log"
MODULE_PROP="${MODDIR}/module.prop"
OPENP2P="${MODDIR}/openp2p"

# 兜底默认值(配置缺失时使用)
DEFAULT_MONITOR_INTERVAL="10s"
DEFAULT_LOG_LEVEL=1
DEFAULT_SHARE_BANDWIDTH=50
DEFAULT_SERVER_HOST="api.openp2p.cn"
DEFAULT_INSECURE=true
DEFAULT_TZ="Asia/Shanghai"

mkdir -p "${LOG_DIR}"
mkdir -p "${OPENP2P_DIR}/config"
touch "${LOG_FILE}"

log() {
    local message="$(date "+%Y-%m-%d %H:%M:%S") $1"
    echo "$message"
    echo "$message" >> "${LOG_FILE}"
}

# 通用 JSON 字段读取 - 接受字符串/数字/布尔
# 用法: json_get "字段名" "默认值" [type:str|num|bool]
# 优先匹配 "字段": "值", 其次 "字段": 值
json_get() {
    local key="$1"
    local default="$2"
    local type="${3:-str}"
    [ ! -f "$CONFIG_FILE" ] && { echo "$default"; return; }
    local val
    case "$type" in
        str)
            val=$(grep -m1 -oE "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$CONFIG_FILE" \
                | sed -E "s/\"${key}\"[[:space:]]*:[[:space:]]*\"([^\"]*)\"/\1/")
            ;;
        num)
            val=$(grep -m1 -oE "\"${key}\"[[:space:]]*:[[:space:]]*-?[0-9]+(\\.[0-9]+)?" "$CONFIG_FILE" \
                | grep -oE -- "-?[0-9]+(\.[0-9]+)?$")
            ;;
        bool)
            val=$(grep -m1 -oE "\"${key}\"[[:space:]]*:[[:space:]]*(true|false)" "$CONFIG_FILE" \
                | grep -oE "(true|false)$")
            ;;
    esac
    if [ -z "$val" ]; then
        echo "$default"
    else
        echo "$val"
    fi
}

get_token() {
    if [ -f "$CONFIG_FILE" ]; then
        # 优先字符串格式
        local t=$(grep -m1 -oE '"Token"[[:space:]]*:[[:space:]]*"[^"]+"' "$CONFIG_FILE" \
            | sed -E 's/.*"Token"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
        if [ -z "$t" ] || [ "$t" = "YOUR_TOKEN_HERE" ]; then
            t=$(grep -m1 -oE '"Token"[[:space:]]*:[[:space:]]*[0-9]+' "$CONFIG_FILE" \
                | grep -oE '[0-9]+$')
        fi
        echo "$t"
    fi
}

get_monitor_interval() {
    local v=$(json_get "MonitorInterval" "$DEFAULT_MONITOR_INTERVAL" "str")
    echo "$v"
}

parse_interval() {
    # 支持 10s / 5m / 1h / 纯数字(秒)
    local interval="$1"
    case "$interval" in
        *s) echo "${interval%s}" ;;
        *m) local n="${interval%m}"; echo $((n * 60)) ;;
        *h) local n="${interval%h}"; echo $((n * 3600)) ;;
        *)  echo "${interval:-10}" ;;
    esac
}

update_module_description() {
    sed -i "/^description=/c\description=[状态]${1}" "${MODULE_PROP}" 2>/dev/null
}

# 检查并创建 TUN 设备
create_tun() {
    if [ ! -e /dev/net/tun ]; then
        mkdir -p /dev/net
        if [ -e /dev/tun ]; then
            ln -sf /dev/tun /dev/net/tun 2>/dev/null
        else
            log "WARN: /dev/tun 不存在,VPN 模式可能无法工作"
        fi
    fi
}

# 清理已存在的 openp2p 进程
kill_openp2p() {
    # 用 -x 精确匹配进程名,避免误杀
    if pgrep -x openp2p >/dev/null 2>&1; then
        log "Stopping existing openp2p processes..."
        pkill -9 -x openp2p 2>/dev/null
        sleep 1
    fi
}

create_tun
kill_openp2p

while true; do
    MONITOR_INTERVAL=$(get_monitor_interval)
    SLEEP_SECONDS=$(parse_interval "$MONITOR_INTERVAL")
    
    # 兼容 set -u
    [ -z "$SLEEP_SECONDS" ] && SLEEP_SECONDS=10
    
    if ls "${MODDIR}" 2>/dev/null | grep -q "^disable$"; then
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
            
            # 全部参数从 config.json 读取
            LOG_LEVEL=$(json_get "LogLevel" "$DEFAULT_LOG_LEVEL" "num")
            SHARE_BANDWIDTH=$(json_get "ShareBandwidth" "$DEFAULT_SHARE_BANDWIDTH" "num")
            SERVER_HOST=$(json_get "ServerHost" "$DEFAULT_SERVER_HOST" "str")
            INSECURE_VAL=$(json_get "TLSInsecureSkipVerify" "$DEFAULT_INSECURE" "bool")
            TZ_VAL=$(json_get "Timezone" "$DEFAULT_TZ" "str")
            NODE_NAME=$(json_get "Node" "" "str")
            [ -n "$NODE_NAME" ] && DEVICE_NAME="$NODE_NAME"
            
            # 构造额外参数
            EXTRA_ARGS=""
            [ "$INSECURE_VAL" = "true" ] && EXTRA_ARGS="$EXTRA_ARGS -insecure"
            
            if ! pgrep -x openp2p >/dev/null 2>&1; then
                log "Starting OpenP2P with token: ${TOKEN:0:8}..."
                log "  server=${SERVER_HOST} loglevel=${LOG_LEVEL} sharebandwidth=${SHARE_BANDWIDTH} tz=${TZ_VAL}"
                
                cd "${MODDIR}"
                TZ="${TZ_VAL}" nohup "${OPENP2P}" -d \
                    -token "${TOKEN}" \
                    -node "${DEVICE_NAME}" \
                    -serverhost "${SERVER_HOST}" \
                    -loglevel "${LOG_LEVEL}" \
                    -sharebandwidth "${SHARE_BANDWIDTH}" \
                    ${EXTRA_ARGS} > "${LOG_DIR}/openp2p.log" 2>&1 &
                
                sleep 3
                
                if pgrep -x openp2p >/dev/null 2>&1; then
                    log "OpenP2P started successfully"
                    update_module_description "运行中 | ${DEVICE_NAME}"
                else
                    log "OpenP2P failed to start"
                    update_module_description "启动失败"
                fi
            fi
        fi
    fi
    
    # 用 for 循环 sleep,避免 sleep 被信号打断后等待时间不足
    i=0
    while [ $i -lt "$SLEEP_SECONDS" ]; do
        sleep 1
        i=$((i + 1))
    done
done
