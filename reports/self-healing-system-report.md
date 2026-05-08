# OpenClaw 自愈系统调研报告

**生成时间**: 2026-05-08 00:14 GMT+8
**调研人**: CEO 田螺 (主代理) + 子代理 (Research-Self-Healing)
**目标**: 解决任务中断需人工干预问题，实现全自动自愈

---

## 📋 执行摘要

本报告基于现有文档 (`optimization-plan.md`, `HEARTBEAT.md`) 和技术调研，针对 OpenClaw 系统**任务中断需人工干预**的核心问题，提供了完整的自愈系统设计方案。

**核心结论**:
- ✅ 现有方案 (`HEARTBEAT.md` + `sessions_send`) 仅实现**半自动**，依赖人工触发
- ✅ 最优方案：**独立看门狗 (Watchdog) + 状态持久化 (Checkpoint)**
- ✅ 推荐技能: 暂无现成技能，需自定义开发 `self-healing-agent` 或 `gateway-watchdog`

---

## 1️⃣ 现状分析

### 当前问题
| 问题类型 | 表现 | 影响 |
| :--- | :--- | :--- |
| **Gateway 崩溃** | 服务意外退出，所有会话挂起 | 任务中断，需手动 `openclaw gateway restart` |
| **Session 超时** | 长时间无响应，状态变为 `failed`/`done` | 任务挂起，需手动发送唤醒消息 |
| **模型卡死** | API 响应超时，无错误返回 | 任务阻塞，需人工干预 |

### 现有方案缺陷
```markdown
当前方案 (HEARTBEAT.md):
- 每 2 小时检查一次 CTO/CIO 状态
- 发现异常后，仅**汇报**，不自动重启
- 手动重启流程繁琐：检查状态 → 发送消息 → 超时则重启 Gateway

缺陷:
❌ 依赖人工触发，非全自动
❌ 检查频率低 (2 小时)，故障恢复延迟高
❌ 无状态持久化，重启后任务无法断点续传
```

---

## 2️⃣ 推荐技能列表

经本地扫描和通用知识检索，**ClawHub/GitHub 暂无现成的 `self-healing` 或 `watchdog` 技能**。

| 技能名称 | 来源 | 状态 | 用途 |
| :--- | :--- | :--- | :--- |
| `session-logs-enhanced` | 本地 | ✅ 可用 | 会话日志搜索与分析，辅助故障诊断 |
| `elite-longterm-memory` | ClawHub | ✅ 可用 | 状态持久化 (WAL + Git-Notes)，支持断点续传 |
| `self-healing-agent` | 待开发 | ⏳ 需自建 | 核心自愈逻辑 (检测 + 恢复) |
| `gateway-watchdog` | 待开发 | ⏳ 需自建 | 轻量级看门狗脚本 (Shell/Python) |

**建议**:
1. **短期**: 使用 `gateway-watchdog` (Shell 脚本) + `cron` 快速部署
2. **长期**: 开发 `self-healing-agent` 技能，集成状态持久化与自动重试

---

## 3️⃣ 自愈系统架构设计

### 3.1 整体架构
```
┌─────────────────────────────────────────────────────────────────┐
│                    SELF-HEALING SYSTEM                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │  DETECTION   │───▶│  RECOVERY    │───▶│  VERIFICATION│      │
│  │   (检测层)    │    │   (恢复层)    │    │   (验证层)    │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│         │                   │                   │               │
│         ▼                   ▼                   ▼               │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │ - Gateway    │    │ - 唤醒 Session│    │ - 检查状态   │      │
│  │   状态检测    │    │ - 重启 Gateway│    │ - 验证任务   │      │
│  │ - Session    │    │ - 重试任务   │    │ - 记录日志   │      │
│  │   状态检测    │    │ - 断点恢复   │    │ - 告警通知   │      │
│  │ - 模型超时   │    │              │    │              │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              STATE PERSISTENCE (状态持久化)              │   │
│  │  - SESSION-STATE.md (Hot RAM)                           │   │
│  │  - memory/YYYY-MM-DD.md (Daily Logs)                    │   │
│  │  - Git-Notes (决策与断点)                                │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 自动检测逻辑

| 检测目标 | 检测方法 | 触发条件 | 检测频率 |
| :--- | :--- | :--- | :--- |
| **Gateway 状态** | `openclaw gateway status` | 返回 `stopped` 或超时 | 每 1 分钟 |
| **Session 状态** | `sessions_list` + 过滤 `agent:*:main` | 状态为 `failed` 或 `done` (非正常) | 每 1 分钟 |
| **模型响应超时** | 监控 API 响应时间 | 单次请求 > 120 秒 | 实时 (Gateway 层) |
| **任务挂起** | 检查 `SESSION-STATE.md` 更新时间 | 超过 30 分钟无更新 | 每 5 分钟 |

### 3.3 自动恢复逻辑

| 故障类型 | 恢复动作 | 优先级 | 重试策略 |
| :--- | :--- | :--- | :--- |
| **Gateway 停止** | `openclaw gateway restart` | P0 | 最多 3 次，间隔 30 秒 |
| **Session 异常** | `sessions_send --sessionKey <key> --message "自愈指令：重启"` | P0 | 最多 2 次，间隔 10 秒 |
| **任务超时** | 发送 `Ctrl+C` 终止 + 重新 spawn 任务 | P1 | 最多 3 次，使用备用模型 |
| **状态丢失** | 从 `SESSION-STATE.md` / Git-Notes 恢复断点 | P2 | 仅一次，人工确认 |

### 3.4 验证与告警

| 步骤 | 动作 | 成功标准 | 失败处理 |
| :--- | :--- | :--- | :--- |
| **恢复后验证** | `sessions_list` 检查状态 | 状态为 `running` 或 `idle` | 记录失败，发送告警 |
| **任务验证** | 检查 `SESSION-STATE.md` 更新 | 有最新时间戳 | 人工介入 |
| **告警通知** | 写入 `memory/watchdog-alerts.log` + 微信/邮件 | 日志成功写入 | 静默失败，下次检测重试 |

---

## 4️⃣ Cron 任务配置示例

### 4.1 看门狗脚本 (`scripts/watchdog.sh`)

```bash
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
FAILED_SESSIONS=$(openclaw sessions list --json 2>/dev/null | \
    jq -r '.[] | select(.key | test("agent:.+:main")) | select(.state == "failed" or .state == "done") | .key')

for session_key in $FAILED_SESSIONS; do
    alert "Session $session_key 异常 (状态: $state)，尝试唤醒..."
    
    # 尝试发送唤醒消息
    if openclaw sessions send --sessionKey "$session_key" --message "自愈指令：立即重启并汇报状态" 2>/dev/null; then
        log "已发送唤醒消息到 $session_key"
    else
        alert "唤醒 $session_key 失败，尝试重启 Gateway..."
        openclaw gateway restart
    fi
done

# 3. 检查任务挂起 (SESSION-STATE.md 更新时间)
STATE_FILE="$WORKSPACE/SESSION-STATE.md"
if [ -f "$STATE_FILE" ]; then
    LAST_UPDATE=$(stat -c %Y "$STATE_FILE")
    CURRENT_TIME=$(date +%s)
    DIFF=$((CURRENT_TIME - LAST_UPDATE))
    
    if [ $DIFF -gt 1800 ]; then  # 30 分钟无更新
        alert "SESSION-STATE.md 超过 30 分钟未更新 (距今 $((DIFF/60)) 分钟)，可能存在任务挂起"
        # 可选: 自动发送测试消息到主会话
    fi
fi

log "Watchdog 检查完成"
exit 0
```

### 4.2 Cron 配置 (`crontab -e`)

```cron
# OpenClaw 自愈系统 - 看门狗任务
# 每 1 分钟检查一次 Gateway 和 Session 状态
* * * * * /home/myuser/.openclaw/workspace-main/scripts/watchdog.sh

# 可选: 每 5 分钟检查一次任务挂起 (如果脚本未包含)
*/5 * * * * /home/myuser/.openclaw/workspace-main/scripts/watchdog.sh --check-stale

# 可选: 每日凌晨 3 点生成健康报告
0 3 * * * /home/myuser/.openclaw/workspace-main/scripts/generate-health-report.sh
```

### 4.3 状态持久化配置 (`openclaw.json`)

```json
{
  "agents": {
    "defaults": {
      "timeoutSeconds": 120,
      "fallbacks": ["custom-nvidia-glm4/z-ai/glm4.7"],
      "statePersistence": true
    }
  },
  "memorySearch": {
    "enabled": true,
    "provider": "openai",
    "sources": ["memory", "SESSION-STATE.md"],
    "minScore": 0.3,
    "maxResults": 10
  },
  "plugins": {
    "entries": {
      "memory-lancedb": {
        "enabled": true,
        "config": {
          "autoCapture": true,
          "autoRecall": true,
          "captureCategories": ["preference", "decision", "fact"],
          "minImportance": 0.7
        }
      }
    }
  }
}
```

---

## 5️⃣ 实施路线图

| 阶段 | 任务 | 负责人 | 预计耗时 | 状态 |
| :--- | :--- | :--- | :--- | :--- |
| **P0** | 创建 `scripts/watchdog.sh` 并设置执行权限 | CEO | 10 分钟 | ⏳ 待执行 |
| **P0** | 配置 Cron 任务 (`* * * * *`) | CEO | 5 分钟 | ⏳ 待执行 |
| **P0** | 更新 `openclaw.json` 启用状态持久化 | CEO | 5 分钟 | ⏳ 待执行 |
| **P1** | 开发 `self-healing-agent` 技能 (集成断点续传) | CIO | 2 小时 | ⏳ 待规划 |
| **P1** | 集成告警通知 (微信/邮件) | CIO | 30 分钟 | ⏳ 待规划 |
| **P2** | 监控验证 (运行 24 小时，观察自愈效果) | 全员 | 24 小时 | ⏳ 待验证 |

---

## 6️⃣ 风险与注意事项

| 风险 | 描述 | 缓解措施 |
| :--- | :--- | :--- |
| **误重启** | 正常任务被误判为异常，导致重启 | 增加状态验证 (如 `SESSION-STATE.md` 更新时间) |
| **重启风暴** | 连续失败导致频繁重启，加重负载 | 设置最大重试次数 (3 次) 和冷却时间 (5 分钟) |
| **状态丢失** | 持久化文件损坏，无法恢复断点 | 定期备份 `SESSION-STATE.md` 和 Git-Notes |
| **告警疲劳** | 频繁告警导致用户忽略 | 设置告警阈值 (连续 2 次失败才告警) |

---

## 7️⃣ 结论与建议

### 核心结论
1. **无现成技能**: ClawHub/GitHub 暂无成熟的 `self-healing` 技能，需自建
2. **快速方案**: 使用 Shell 脚本 + Cron 即可实现基础自愈 (P0)
3. **长期方案**: 开发专用 `self-healing-agent` 技能，集成状态持久化与智能重试

### 立即行动
1. ✅ **批准 P0 任务**: 立即部署 `watchdog.sh` + Cron
2. ✅ **启用状态持久化**: 更新 `openclaw.json`，确保任务断点可恢复
3. ✅ **监控验证**: 运行 24 小时，观察自愈效果，调整参数

---

**报告结束**

**CEO 田螺** 🏢✨
**子代理** (Research-Self-Healing)
