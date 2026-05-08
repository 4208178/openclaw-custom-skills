#!/bin/bash
# OpenClaw Watchdog - 自愈系统看门狗脚本
# 安装: chmod +x scripts/watchdog.sh
# 调度: * * * * * /path/to/watchdog.sh

LOG_FILE="$HOME/.openclaw/workspace-main/memory/watchdog.log"
ALERT_FILE="$HOME/.openclaw/workspace-main/memory/watchdog-alerts.log"
WORKSPACE="$HOME/.openclaw/workspace-main"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

alert() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ $1" >> "$ALERT_FILE"
    # 可选: 发送微信/邮件告警
    # curl -X POST "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY" \
    #   -H "Content-Type: application/json" \
    #   -d "{\"msgtype\":\"text\",\"text\":{\"content\":\"OpenClaw 告警: $1\"}}"
}

# 1. 检查 Gateway 状态
log "Checking Gateway status..."
if ! openclaw gateway status > /dev/null 2>&1; then
    alert "Gateway 停止运行，尝试重启..."
    openclaw gateway restart
    sleep 5
    if ! openclaw gateway status > /dev/null 2>&1; then
        alert "Gateway 重启失败，需人工干预！"
        exit 1
    fi
    log "Gateway 重启成功"
fi

# 2. 检查 Session 状态 (仅检查 main 会话)
log "Checking Sessions..."
# 使用 sessions_list 获取会话列表，过滤 failed/done 的 main 会话
SESSIONS_JSON=$(openclaw sessions list --json 2>/dev/null)
if [ -n "$SESSIONS_JSON" ]; then
    # 解析 JSON 并检查状态 (需要 jq)
    if command -v jq &> /dev/null; then
        FAILED_SESSIONS=$(echo "$SESSIONS_JSON" | \
            jq -r '.[] | select(.key | test("agent:.+:main")) | select(.state == "failed" or .state == "done") | .key')
        
        for session_key in $FAILED_SESSIONS; do
            state=$(echo "$SESSIONS_JSON" | jq -r --arg k "$session_key" '.[] | select(.key == $k) | .state')
            alert "Session $session_key 异常 (状态: $state)，尝试唤醒..."
            
            # 尝试发送唤醒消息
            if openclaw sessions send --sessionKey "$session_key" --message "自愈指令：立即重启并汇报状态" 2>/dev/null; then
                log "已发送唤醒消息到 $session_key"
            else
                alert "唤醒 $session_key 失败，尝试重启 Gateway..."
                openclaw gateway restart
            fi
        done
    else
        log "jq 未安装，跳过 JSON 解析，使用简单检查"
        # 备用方案：直接检查 sessions_list 输出
        SESSIONS_LIST=$(openclaw sessions list 2>/dev/null)
        if echo "$SESSIONS_LIST" | grep -q "failed\|done"; then
            alert "检测到异常会话，请手动检查: openclaw sessions list"
        fi
    fi
else
    log "无法获取会话列表，Gateway 可能未响应"
fi

# 3. 检查任务挂起 (SESSION-STATE.md 更新时间)
STATE_FILE="$WORKSPACE/SESSION-STATE.md"
if [ -f "$STATE_FILE" ]; then
    LAST_UPDATE=$(stat -c %Y "$STATE_FILE" 2>/dev/null || stat -f %m "$STATE_FILE" 2>/dev/null)
    CURRENT_TIME=$(date +%s)
    DIFF=$((CURRENT_TIME - LAST_UPDATE))
    
    if [ $DIFF -gt 1800 ]; then  # 30 分钟无更新
        alert "SESSION-STATE.md 超过 30 分钟未更新 (距今 $((DIFF/60)) 分钟)，可能存在任务挂起"
    fi
fi

log "Watchdog 检查完成"
exit 0
