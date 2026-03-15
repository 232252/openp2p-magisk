#!/data/adb/magisk/busybox sh

MODDIR=${0%/*}
CONFIG_FILE="${MODDIR}/config/config.json"
LOG_DIR="${MODDIR}/log"
LOG_FILE="${LOG_DIR}/openp2p_core.log"
MODULE_PROP="${MODDIR}/module.prop"
OPENP2P="${MODDIR}/openp2p"

# 创建日志目录
mkdir -p "${LOG_DIR}"
touch "${LOG_FILE}"

# 日志输出函数
log() {
    local message="$(date "+%Y-%m-%d %H:%M:%S") $1"
    echo "$message"
    echo "$message" >> "${LOG_FILE}"
}

# 从配置文件读取 Token
get_token() {
    if [ -f "$CONFIG_FILE" ]; then
        # 尝试匹配字符串格式
        TOKEN=$(grep -o '"Token": *"[^"]*"' "$CONFIG_FILE" | sed 's/"Token": *"\([^"]*\)"/\1/')
        if [ -z "$TOKEN" ] || [ "$TOKEN" = "YOUR_TOKEN_HERE" ]; then
            # 尝试匹配数字格式
            TOKEN=$(grep -o '"Token": *[0-9]*' "$CONFIG_FILE" | grep -o '[0-9]*')
        fi
        echo "$TOKEN"
    fi
}

# 从配置文件读取监控间隔时间
get_monitor_interval() {
    if [ -f "$CONFIG_FILE" ]; then
        # 尝试匹配字符串格式
        INTERVAL=$(grep -o '"MonitorInterval": *"[^"]*"' "$CONFIG_FILE" | sed 's/"MonitorInterval": *"\([^"]*\)"/\1/')
        if [ -n "$INTERVAL" ]; then
            echo "$INTERVAL"
            return
        fi
    fi
    # 默认值
    echo "10s"
}

# 解析监控间隔时间为秒数
parse_interval() {
    local interval=$1
    local num=${interval%[smh]}
    local unit=${interval: -1}
    
    case $unit in
        s)
            echo $num
            ;;
        m)
            echo $((num * 60))
            ;;
        h)
            echo $((num * 3600))
            ;;
        *)
            # 默认秒
            echo $num
            ;;
    esac
}

# 更新 module.prop 文件中的 description
update_module_description() {
    local status_message=$1
    sed -i "/^description=/c\description=[状态]${status_message}" ${MODULE_PROP}
}

# 检查 TUN 设备
echo "检查 TUN 设备"
log "检查 TUN 设备"
mkdir -p "${LOG_DIR}"
touch "${LOG_FILE}"
if [ ! -e /dev/net/tun ]; then
    if [ ! -d /dev/net ]; then
        echo "创建 /dev/net 目录"
        log "创建 /dev/net 目录"
        mkdir -p /dev/net
    fi
    echo "创建 TUN 设备链接"
    log "创建 TUN 设备链接"
    ln -s /dev/tun /dev/net/tun 2>/dev/null
fi

# 主循环
while true; do
    # 读取监控间隔时间
    MONITOR_INTERVAL=$(get_monitor_interval)
    SLEEP_SECONDS=$(parse_interval "$MONITOR_INTERVAL")
    
    # 检查是否禁用
    if ls ${MODDIR} | grep -q "disable"; then
        echo "模块已禁用"
        log "模块已禁用"
        update_module_description "已禁用"
        if pgrep -f 'openp2p -d' >/dev/null; then
            echo "模块已禁用，正在关闭..."
            log "模块已禁用，正在关闭..."
            pkill openp2p 2>/dev/null
        fi
    else
        # 检查配置文件
        if [ ! -f "$CONFIG_FILE" ]; then
            echo "config.json 不存在"
            log "config.json 不存在"
            update_module_description "config.json 不存在"
            sleep 3s
            continue
        fi
        
        # 获取 Token
        TOKEN=$(get_token)
        if [ -z "$TOKEN" ] || [ "$TOKEN" = "YOUR_TOKEN_HERE" ]; then
            echo "请先在 config/config.json 中配置 Token"
            log "请先在 config/config.json 中配置 Token"
            update_module_description "请先配置 Token"
            sleep 10s
            continue
        fi
        
        # 获取设备名称
        DEVICE_NAME="$(getprop ro.product.brand)-$(getprop ro.product.model)"
        
        # 检查进程是否存在
        if ! pgrep -f 'openp2p -d' >/dev/null; then
            echo "正在启动 OpenP2P..."
            log "正在启动 OpenP2P..."
            echo "设备名称: ${DEVICE_NAME}"
            log "设备名称: ${DEVICE_NAME}"
            
            # 从配置文件读取参数启动
            cd ${MODDIR}
            TZ=Asia/Shanghai ${OPENP2P} -d \
                -token ${TOKEN} \
                -node "${DEVICE_NAME}" \
                -serverhost api.openp2p.cn \
                -loglevel 1 \
                -sharebandwidth 50 \
                -insecure > "${LOG_DIR}/openp2p.log" 2>&1 &
            
            sleep 5s
            
            # 检查是否启动成功
            if pgrep -f 'openp2p -d' >/dev/null; then
                echo "OpenP2P 启动成功"
                log "OpenP2P 启动成功"
                update_module_description "主程序已开启 | 节点: ${DEVICE_NAME}"
            else
                echo "OpenP2P 启动失败"
                log "OpenP2P 启动失败"
                update_module_description "主程序启动失败，请检查日志"
            fi
        else
            # 检查进程是否真正正常运行
            OPENP2P_PID=$(pgrep -f 'openp2p -d')
            if [ -n "$OPENP2P_PID" ]; then
                # 检查进程是否有网络连接
                if netstat -an 2>/dev/null | grep -E "27183|26188" | grep -q ESTABLISHED; then
                    echo "OpenP2P 运行中..."
                    log "OpenP2P 运行中..."
                else
                    # 进程存在但可能没有网络连接，尝试重启
                    echo "OpenP2P 进程存在但网络连接异常，尝试重启..."
                    log "OpenP2P 进程存在但网络连接异常，尝试重启..."
                    
                    # 使用 action.sh restart 命令重启服务
                    echo "使用 action.sh restart 命令重启服务..."
                    log "使用 action.sh restart 命令重启服务..."
                    
                    # 执行重启命令
                    "${MODDIR}/action.sh" restart
                    
                    # 等待重启完成
                    echo "等待服务重启完成..."
                    log "等待服务重启完成..."
                    sleep 10
                    
                    # 检查重启是否成功
                    if pgrep -f 'openp2p -d' >/dev/null; then
                        echo "OpenP2P 重启成功，检查网络连接..."
                        log "OpenP2P 重启成功，检查网络连接..."
                        
                        # 检查网络连接
                        sleep 2
                        if netstat -an 2>/dev/null | grep -E "27183|26188" | grep -q ESTABLISHED; then
                            echo "OpenP2P 重启成功且网络连接正常"
                            log "OpenP2P 重启成功且网络连接正常"
                            update_module_description "主程序已开启 | 节点: ${DEVICE_NAME}"
                        else
                            echo "OpenP2P 重启成功但网络连接异常"
                            log "OpenP2P 重启成功但网络连接异常"
                            update_module_description "主程序已开启 | 网络连接异常"
                            # 显示日志末尾，便于排查
                            echo "=== openp2p.log 末尾内容 ==="
                            tail -10 "${LOG_DIR}/openp2p.log"
                            echo "========================="
                        fi
                    else
                        echo "OpenP2P 重启失败"
                        log "OpenP2P 重启失败"
                        update_module_description "主程序重启失败，请检查日志"
                        # 显示日志末尾，便于排查
                        echo "=== openp2p.log 末尾内容 ==="
                        tail -10 "${LOG_DIR}/openp2p.log"
                        echo "========================="
                    fi
                fi
            else
                echo "OpenP2P 未运行..."
                log "OpenP2P 未运行..."
            fi
        fi
    fi
    
    echo "监控间隔: ${MONITOR_INTERVAL} (${SLEEP_SECONDS}秒)"
    log "监控间隔: ${MONITOR_INTERVAL} (${SLEEP_SECONDS}秒)"
    sleep ${SLEEP_SECONDS}
done
