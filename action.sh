#!/system/bin/sh

# OpenP2P Magisk Module 管理脚本
# 作者: 232252
# 版本: 1.0

MODDIR=${0%/*}

# 自动修复脚本和二进制文件执行权限
chmod 755 "${MODDIR}"/*.sh "${MODDIR}/openp2p" 2>/dev/null

MODULE_DIR="/data/adb/modules/openp2p"
OPENP2P_BIN="$MODULE_DIR/openp2p"
# 使用 /sdcard/Documents/openp2p 作为配置和日志目录
OPENP2P_DIR="/sdcard/Documents/openp2p"
CONFIG_FILE="${OPENP2P_DIR}/config/config.json"
LOG_DIR="${OPENP2P_DIR}/log"
LOG_FILE="${LOG_DIR}/action.log"
PID_FILE="$MODULE_DIR/openp2p.pid"

# 日志输出函数
log() {
    local message="$(date "+%Y-%m-%d %H:%M:%S") $1"
    echo "$message"
    echo "$message" >> "${LOG_FILE}"
}

# 从配置文件读取 Token（支持字符串和数字格式）
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

# 更新模块描述
update_status() {
    local status=$1
    local token=$2
    local prop_file="$MODULE_DIR/module.prop"
    
    if [ -f "$prop_file" ]; then
        sed -i "s/^description=.*/description=OpenP2P内网穿透服务 | $status | Token: $token/" "$prop_file"
    fi
}

# 启动服务
start() {
    mkdir -p "${LOG_DIR}"
    touch "${LOG_FILE}"
    echo "执行 start 命令"
    log "执行 start 命令"
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 $PID 2>/dev/null; then
            echo "OpenP2P 已在运行 (PID: $PID)"
            log "OpenP2P 已在运行 (PID: $PID)"
            exit 0
        fi
    fi
    
    # 检查配置文件目录
    mkdir -p "${OPENP2P_DIR}/config"
    mkdir -p "${LOG_DIR}"
    
    # 检查配置文件
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "config.json 不存在，正在从模块目录复制..."
        log "config.json 不存在，正在从模块目录复制..."
        
        # 检查当前目录是否有 config/config.json 文件
        if [ -f "${MODDIR}/config/config.json" ]; then
            # 复制当前目录的配置文件到 /sdcard/Documents/openp2p/config/ 目录
            echo "从模块目录复制默认配置文件..."
            log "从模块目录复制默认配置文件..."
            cp "${MODDIR}/config/config.json" "${CONFIG_FILE}"
            echo "默认配置文件已复制，请在 ${CONFIG_FILE} 中配置 Token"
            log "默认配置文件已复制，请在 ${CONFIG_FILE} 中配置 Token"
            exit 1
        else
            # 如果模块目录没有配置文件，报错并退出
            echo "错误: 模块目录中不存在 config/config.json 文件，无法复制到 ${CONFIG_FILE}"
            log "错误: 模块目录中不存在 config/config.json 文件，无法复制到 ${CONFIG_FILE}"
            exit 1
        fi
    fi
    
    TOKEN=$(get_token)
    if [ -z "$TOKEN" ] || [ "$TOKEN" = "YOUR_TOKEN_HERE" ]; then
        echo "错误: 请先在 ${CONFIG_FILE} 中配置 Token"
        log "错误: 请先在 ${CONFIG_FILE} 中配置 Token"
        exit 1
    fi
    
    echo "正在启动 OpenP2P..."
    log "正在启动 OpenP2P..."
    
    DEVICE_NAME="$(getprop ro.product.brand)-$(getprop ro.product.model)"
    echo "设备名称: ${DEVICE_NAME}"
    log "设备名称: ${DEVICE_NAME}"
    
    cd "$MODULE_DIR"
    nohup "$OPENP2P_BIN" -d -token "$TOKEN" -node "$DEVICE_NAME" > "${LOG_DIR}/openp2p.log" 2>&1 &
    echo $! > "$PID_FILE"
    echo "启动命令已执行，PID: $!"
    log "启动命令已执行，PID: $!"
    
    sleep 2
    
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 $PID 2>/dev/null; then
            echo "OpenP2P 已启动 (PID: $PID)"
            log "OpenP2P 已启动 (PID: $PID)"
            update_status "运行中" "$TOKEN"
        else
            echo "启动失败，请查看日志: ${LOG_DIR}/openp2p.log"
            log "启动失败，请查看日志: ${LOG_DIR}/openp2p.log"
            tail -10 "${LOG_DIR}/openp2p.log"
            exit 1
        fi
    else
        echo "启动失败"
        log "启动失败"
        exit 1
    fi
}

# 停止服务
stop() {
    mkdir -p "${LOG_DIR}"
    touch "${LOG_FILE}"
    echo "执行 stop 命令"
    log "执行 stop 命令"
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 $PID 2>/dev/null; then
            echo "正在停止 OpenP2P..."
            log "正在停止 OpenP2P..."
            kill $PID
            rm -f "$PID_FILE"
            echo "已删除 PID 文件"
            log "已删除 PID 文件"
            sleep 1
            echo "OpenP2P 已停止"
            log "OpenP2P 已停止"
            update_status "已停止" "-"
        else
            echo "OpenP2P 未运行"
            log "OpenP2P 未运行"
            rm -f "$PID_FILE"
            echo "已删除 PID 文件"
            log "已删除 PID 文件"
        fi
    else
        echo "OpenP2P 未运行"
        log "OpenP2P 未运行"
    fi
}

# 重启服务
restart() {
    mkdir -p "${LOG_DIR}"
    touch "${LOG_FILE}"
    echo "执行 restart 命令"
    log "执行 restart 命令"
    stop
    sleep 2
    start
}

# 查看状态
status() {
    mkdir -p "${LOG_DIR}"
    touch "${LOG_FILE}"
    echo "执行 status 命令"
    log "执行 status 命令"
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 $PID 2>/dev/null; then
            echo "OpenP2P 运行中"
            log "OpenP2P 运行中"
            echo ""
            ps -ef | grep openp2p | grep -v grep
            echo ""
            echo "网络连接:"
            netstat -an 2>/dev/null | grep -E "27183|26188" | head -5
        else
            echo "OpenP2P 未运行 (PID文件存在但进程已退出)"
            log "OpenP2P 未运行 (PID文件存在但进程已退出)"
        fi
    else
        echo "OpenP2P 未运行"
        log "OpenP2P 未运行"
    fi
}

# 查看日志
logs() {
    mkdir -p "${LOG_DIR}"
    touch "${LOG_FILE}"
    echo "执行 log 命令"
    log "执行 log 命令"
    if [ -f "${LOG_DIR}/openp2p.log" ]; then
        tail -50 "${LOG_DIR}/openp2p.log"
    else
        echo "日志文件不存在: ${LOG_DIR}/openp2p.log"
        log "日志文件不存在: ${LOG_DIR}/openp2p.log"
    fi
}

# 主入口
# 空参执行start
if [ $# -eq 0 ]; then
    set -- "start"  # 将第一个参数设置为start
fi
#有参命令
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    log)
        logs
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|log}"
        log "用法: $0 {start|stop|restart|status|log}"
        exit 1
        ;;
esac
