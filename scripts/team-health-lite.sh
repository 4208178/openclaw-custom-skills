#!/bin/bash
# 轻量级团队健康检查 - 不触发 API 调用
# 只检查会话状态，不等待回复

STATE_FILE="/home/myuser/.openclaw/workspace-main/memory/circuit-breaker-state.json"
LOG_FILE="/home/myuser/.openclaw/workspace-main/memory/team-health.log"
PENDING_FILE="/home/myuser/.openclaw/workspace-main/memory/pending-tasks.md"

# 读取熔断器状态
if [ -f "$STATE_FILE" ]; then
    CIRCUIT_OPEN=$(cat "$STATE_FILE" | grep -o '"circuitOpen": [a-z]*' | cut -d' ' -f2)
else
    CIRCUIT_OPEN="false"
fi

# 如果熔断器打开，静默退出
if [ "$CIRCUIT_OPEN" = "true" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 熔断器已打开，跳过检查" >> "$LOG_FILE"
    exit 0
fi

# 检查会话状态（使用 openclaw sessions_list 命令）
# 注意：这里需要调用 OpenClaw CLI，但可能不在 PATH 中
# 尝试多种方式
if command -v openclaw &> /dev/null; then
    SESSIONS_OUTPUT=$(openclaw sessions_list --agentId coding --limit 1 2>/dev/null)
    CTO_STATUS=$(echo "$SESSIONS_OUTPUT" | grep -o '"status": "[^"]*"' | head -1 | cut -d'"' -f4)
    
    SESSIONS_OUTPUT=$(openclaw sessions_list --agentId comms --limit 1 2>/dev/null)
    CIO_STATUS=$(echo "$SESSIONS_OUTPUT" | grep -o '"status": "[^"]*"' | head -1 | cut -d'"' -f4)
else
    # 如果 openclaw 命令不可用，静默退出
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 警告：openclaw 命令不可用，跳过检查" >> "$LOG_FILE"
    exit 0
fi

# 如果状态为空，设置为 unknown
CTO_STATUS=${CTO_STATUS:-unknown}
CIO_STATUS=${CIO_STATUS:-unknown}

echo "[$(date '+%Y-%m-%d %H:%M:%S')] CTO: ${CTO_STATUS}, CIO: ${CIO_STATUS}" >> "$LOG_FILE"

# 记录失败
if [ "$CTO_STATUS" = "failed" ] || [ "$CTO_STATUS" = "done" ] || [ "$CIO_STATUS" = "failed" ] || [ "$CIO_STATUS" = "done" ]; then
    FAILURE_COUNT=$(cat "$STATE_FILE" 2>/dev/null | grep -o '"failureCount": [0-9]*' | cut -d' ' -f2 || echo "0")
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 检测到失效会话，失败计数：$FAILURE_COUNT" >> "$LOG_FILE"
    
    # 更新熔断器状态
    cat > "$STATE_FILE" <<EOF
{
  "circuitOpen": false,
  "failureCount": $FAILURE_COUNT,
  "lastFailureAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "lastCheckAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "nextRetryAt": null,
  "blockedTasks": []
}
EOF
    
    # 如果连续失败 ≥ 2 次，打开熔断器
    if [ $FAILURE_COUNT -ge 2 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ 熔断器已打开！暂停检查 30 分钟" >> "$LOG_FILE"
        
        # 计算 30 分钟后的时间
        NEXT_RETRY=$(date -u -d '+30 minutes' +%Y-%m-%dT%H:%M:%SZ)
        
        cat > "$STATE_FILE" <<EOF
{
  "circuitOpen": true,
  "failureCount": $FAILURE_COUNT,
  "lastFailureAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "lastCheckAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "nextRetryAt": "$NEXT_RETRY",
  "blockedTasks": []
}
EOF
        
        # 通知用户
        cat > "$PENDING_FILE" <<EOF
## 🚨 团队健康告警

**时间**: $(date '+%Y-%m-%d %H:%M:%S GMT+8')

### 状态
- **CTO (coding)**: ${CTO_STATUS} ❌
- **CIO (comms)**: ${CIO_STATUS} ❌

### 行动
- ✅ 熔断器已打开，暂停自动检查
- ⏳ 30 分钟后自动重试一次
- 📝 如需立即恢复，请手动执行：
  \`\`\`bash
  echo '{"circuitOpen": false}' > memory/circuit-breaker-state.json
  \`\`\`

### 建议操作
1. 检查 API 配额是否耗尽
2. 等待 API 限流解除
3. 手动重启失效会话：
   \`\`\`bash
   sessions_send --sessionKey agent:coding:main --message "CEO 指令：重启"
   sessions_send --sessionKey agent:comms:main --message "CEO 指令：重启"
   \`\`\`
EOF
    fi
else
    # 成功，重置失败计数
    cat > "$STATE_FILE" <<EOF
{
  "circuitOpen": false,
  "failureCount": 0,
  "lastFailureAt": null,
  "lastCheckAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "nextRetryAt": null,
  "blockedTasks": []
}
EOF
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ 团队健康" >> "$LOG_FILE"
fi
