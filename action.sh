#!/system/bin/sh

# OpenP2P Magisk Module 管理脚本
# 作者: 232252
# 版本: 1.1

set -u

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

# 从配置文件读取 Token（支持字符串和数字格式，且仅取第一个匹配项）
get_token() {
    if [ ! -f "$CONFIG_FILE" ]; then
        return 1
    fi
    # 优先匹配字符串格式
    local token
    token=$(grep -oE '"Token"[[:space:]]*:[[:space:]]*"[^"]+"' "$CONFIG_FILE" | head -n 1 | sed -E 's/.*"Token"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    if [ -n "$token" ] && [ "$token" != "YOUR_TOKEN_HERE" ]; then
        echo "$token"
        return 0
    fi
    # 退回数字格式
    token=$(grep -oE '"Token"[[:space:]]*:[[:space:]]*[0-9]+' "$CONFIG_FILE" | head -n 1 | grep -oE '[0-9]+$')
    if [ -n "$token" ]; then
        echo "$token"
        return 0
    fi
    return 1
}

# 更新模块描述
update_status() {
    local status=$1
    local token=$2
    local prop_file="$MODULE_DIR/module.prop"
    
    if [ -f "$prop_file" ]; then
        # 防止特殊字符破坏 sed
        local safe_status=$(echo "$status" | tr -d '|/\\')
        local safe_token=$(echo "$token" | tr -d '|/\\')
        sed -i "s|^description=.*|description=OpenP2P内网穿透服务 | ${safe_status} | Token: ${safe_token}|" "$prop_file"
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
        # 僵尸 PID 文件,清理掉
        rm -f "$PID_FILE"
    fi
    
    # 检查配置文件目录
    mkdir -p "${OPENP2P_DIR}/config"
    mkdir -p "${LOG_DIR}"
    
    # 检查配置文件
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "config.json 不存在,正在从模块目录复制..."
        log "config.json 不存在,正在从模块目录复制..."
        
        # 检查当前目录是否有 config/config.json 文件
        if [ -f "${MODDIR}/config/config.json" ]; then
            # 复制当前目录的配置文件到 /sdcard/Documents/openp2p/config/ 目录
            echo "从模块目录复制默认配置文件..."
            log "从模块目录复制默认配置文件..."
            cp "${MODDIR}/config/config.json" "${CONFIG_FILE}"
            echo "默认配置文件已复制,请在 ${CONFIG_FILE} 中配置 Token"
            log "默认配置文件已复制,请在 ${CONFIG_FILE} 中配置 Token"
            update_status "请配置 Token" "-"
            exit 1
        else
            # 如果模块目录没有配置文件,报错并退出
            echo "错误: 模块目录中不存在 config/config.json 文件,无法复制到 ${CONFIG_FILE}"
            log "错误: 模块目录中不存在 config/config.json 文件,无法复制到 ${CONFIG_FILE}"
            update_status "缺配置文件" "-"
            exit 1
        fi
    fi
    
    if ! TOKEN=$(get_token); then
        echo "错误: 请先在 ${CONFIG_FILE} 中配置 Token"
        log "错误: 请先在 ${CONFIG_FILE} 中配置 Token"
        update_status "请配置 Token" "-"
        exit 1
    fi
    
    if [ -z "$TOKEN" ] || [ "$TOKEN" = "YOUR_TOKEN_HERE" ]; then
        echo "错误: 请先在 ${CONFIG_FILE} 中配置 Token"
        log "错误: 请先在 ${CONFIG_FILE} 中配置 Token"
        update_status "请配置 Token" "-"
        exit 1
    fi
    
    echo "正在启动 OpenP2P..."
    log "正在启动 OpenP2P..."
    
    DEVICE_NAME="$(getprop ro.product.brand)-$(getprop ro.product.model)"
    echo "设备名称: ${DEVICE_NAME}"
    log "设备名称: ${DEVICE_NAME}"
    
    cd "$MODULE_DIR"
    nohup "$OPENP2P_BIN" -d -token "$TOKEN" -node "$DEVICE_NAME" > "${LOG_DIR}/openp2p.log" 2>&1 &
    PID=$!
    echo $PID > "$PID_FILE"
    echo "启动命令已执行,PID: $PID"
    log "启动命令已执行,PID: $PID"
    
    sleep 2
    
    if kill -0 $PID 2>/dev/null; then
        echo "OpenP2P 已启动 (PID: $PID)"
        log "OpenP2P 已启动 (PID: $PID)"
        update_status "运行中" "$TOKEN"
    else
        echo "启动失败,请查看日志: ${LOG_DIR}/openp2p.log"
        log "启动失败,请查看日志: ${LOG_DIR}/openp2p.log"
        tail -10 "${LOG_DIR}/openp2p.log"
        rm -f "$PID_FILE"
        update_status "启动失败" "$TOKEN"
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
            kill $PID 2>/dev/null
            # 等待最多 5 秒优雅退出,超时强杀
            local i=0
            while kill -0 $PID 2>/dev/null && [ $i -lt 5 ]; do
                sleep 1
                i=$((i + 1))
            done
            if kill -0 $PID 2>/dev/null; then
                echo "进程未响应 SIGTERM,发送 SIGKILL"
                log "进程未响应 SIGTERM,发送 SIGKILL"
                kill -9 $PID 2>/dev/null
                sleep 1
            fi
            rm -f "$PID_FILE"
            echo "已停止 (PID: $PID)"
            log "已停止 (PID: $PID)"
            update_status "已停止" "-"
        else
            echo "OpenP2P 未运行 (PID文件已过期)"
            log "OpenP2P 未运行 (PID文件已过期)"
            rm -f "$PID_FILE"
        fi
    else
        # PID 文件不存在时,兜底通过 pkill 清理残留
        if pgrep -x openp2p >/dev/null 2>&1; then
            echo "发现残留 openp2p 进程,正在清理..."
            log "发现残留 openp2p 进程,正在清理..."
            pkill -9 -x openp2p 2>/dev/null
            sleep 1
            update_status "已停止" "-"
        else
            echo "OpenP2P 未运行"
            log "OpenP2P 未运行"
        fi
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
            ps -ef | grep -w openp2p | grep -v grep
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
# 无参数或未知参数默认执行 start,方便 Magisk 模块页面的"执行"按钮
# 也兼容手动调用时省略命令的情况(issue #2)
case "${1:-start}" in
    start|"")
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
    log|logs)
        logs
        ;;
    -h|--help|help)
        echo "用法: $0 {start|stop|restart|status|log}"
        echo "  start    启动 OpenP2P (无参数时也是 start)"
        echo "  stop     停止 OpenP2P"
        echo "  restart  重启 OpenP2P"
        echo "  status   查看运行状态"
        echo "  log      查看最近 50 行日志"
        exit 0
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|log} (试试 --help)"
        log "用法: $0 {start|stop|restart|status|log} (收到未知参数: $1)"
        exit 1
        ;;
esac
