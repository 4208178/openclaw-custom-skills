# OpenClaw 自动化与定时任务

## 1. 概述

OpenClaw 提供强大的定时任务 (Cron) 和 Webhook 机制，支持无人值守模式的自动化工作流。

## 2. Cron 定时任务

### 2.1 核心概念

- **执行位置**: 在 Gateway 进程内运行 (非模型内部)
- **持久化**: 任务定义保存在 `~/.openclaw/cron/jobs.json`
- **状态持久化**: 运行时状态保存在 `~/.openclaw/cron/jobs-state.json`
- **任务记录**: 每次执行记录在 `~/.openclaw/cron/runs/<jobId>.jsonl`

### 2.2 任务类型

| 类型 | CLI 标志 | 描述 |
|------|---------|------|
| 一次性任务 | `--at` | 指定时间点执行 (ISO 8601 或相对时间) |
| 固定间隔 | `--every` | 固定间隔重复执行 |
| Cron 表达式 | `--cron` | 5 字段或 6 字段 Cron 表达式 |

### 2.3 执行模式

| 模式 | `--session` 值 | 运行环境 | 适用场景 |
|------|---------------|---------|---------|
| 主会话 | `main` | 主会话下一次心跳 | 提醒、系统事件 |
| 隔离会话 | `isolated` | 独立 `cron:<jobId>` 会话 | 报告、后台任务 |
| 当前会话 | `current` | 创建时绑定的会话 | 需要上下文的任务 |
| 自定义会话 | `session:xxx` | 持久化命名会话 | 需要累积上下文的流程 |

### 2.4 CLI 命令参考

```bash
# 添加一次性提醒
openclaw cron add \
  --name "Calendar check" \
  --at "20m" \
  --session main \
  --system-event "Next heartbeat: check calendar." \
  --wake now

# 添加重复任务
openclaw cron add \
  --name "Morning brief" \
  --cron "0 7 * * *" \
  --tz "America/Los_Angeles" \
  --session isolated \
  --message "Summarize overnight updates." \
  --announce \
  --channel slack \
  --to "channel:C1234567890"

# 模型和推理级别覆盖
openclaw cron add \
  --name "Deep analysis" \
  --cron "0 6 * * 1" \
  --session isolated \
  --message "Weekly deep analysis." \
  --model "opus" \
  --thinking high \
  --announce

# 查看任务列表
openclaw cron list

# 查看任务详情
openclaw cron show <job-id>

# 查看执行历史
openclaw cron runs --id <job-id>

# 删除任务
openclaw cron delete <job-id>
```

### 2.5 配置参考

```json5
{
  "cron": {
    "enabled": true,
    "maxConcurrentRuns": 2,      // 最大并发运行数
    "sessionRetention": "24h",   // 会话保留时间 (completed 任务)
    "runLog": {
      "maxBytes": "2mb",         // 日志最大大小
      "keepLines": 2000          // 保留日志行数
    },
    "failureDestination": "main", // 失败通知目标
    "failureAlert": {
      "includeSkipped": false    // 是否包含跳过的任务告警
    }
  }
}
```

### 2.6 调度表达式

**Cron 表达式格式**:
```
* * * * *
│ │ │ │ │
│ │ │ │ └─ 星期几 (0-7, 0 和 7 都是周日)
│ │ │ └─── 月份 (1-12)
│ │ └───── 日期 (1-31)
│ └─────── 小时 (0-23)
└───────── 分钟 (0-59)
```

**示例**:
```
# 每天早上 7 点
0 7 * * *

# 每 30 分钟
*/30 * * * *

# 每周一上午 9 点
0 9 * * 1

# 每月 1 号凌晨 2 点
0 2 1 * *
```

**注意事项**:
- 时区: 默认 UTC，使用 `--tz` 指定时区
- OR 逻辑: 当日期和星期都非通配符时，满足任一条件即触发
- 错峰: 整点任务自动错开最多 5 分钟，使用 `--exact` 强制精确时间

## 3. Webhook 集成

### 3.1 启用 Webhook

```json5
{
  "hooks": {
    "enabled": true,
    "token": "shared-secret",
    "path": "/hooks",
    "defaultSessionKey": "hook:ingress",
    "allowRequestSessionKey": false,
    "allowedSessionKeyPrefixes": ["hook:"],
    "mappings": [
      {
        "match": { "path": "gmail" },
        "action": "agent",
        "agentId": "main",
        "deliver": true
      }
    ]
  }
}
```

### 3.2 Webhook 端点

#### POST /hooks/wake
触发主会话系统事件:
```bash
curl -X POST http://127.0.0.1:18789/hooks/wake \
  -H 'Authorization: Bearer SECRET' \
  -H 'Content-Type: application/json' \
  -d '{
    "text": "New email received",
    "mode": "now"  // 或 "next-heartbeat"
  }'
```

#### POST /hooks/agent
运行隔离 Agent 任务:
```bash
curl -X POST http://127.0.0.1:18789/hooks/agent \
  -H 'Authorization: Bearer SECRET' \
  -H 'Content-Type: application/json' \
  -d '{
    "message": "Summarize inbox",
    "name": "Email Summary",
    "agentId": "main",
    "model": "openai/gpt-5.4",
    "deliver": true,
    "channel": "slack",
    "to": "channel:C1234567890",
    "timeoutSeconds": 120
  }'
```

#### POST /hooks/<name>
自定义映射端点 (通过 `hooks.mappings` 配置)

### 3.3 认证安全

- **Header 认证**: 
  - `Authorization: Bearer <token>` (推荐)
  - `x-openclaw-token: <token>`
- **查询字符串令牌**: 被拒绝
- **路径限制**: `hooks.path` 不能是 `/`
- **会话键限制**: 设置 `allowedSessionKeyPrefixes` 约束

## 4. Gmail PubSub 集成

### 4.1 向导设置 (推荐)

```bash
openclaw webhooks gmail setup --account openclaw@gmail.com
```

这会:
- 写入 `hooks.gmail` 配置
- 启用 Gmail 预设
- 使用 Tailscale Funnel 作为推送端点

### 4.2 自动启动

当 `hooks.enabled=true` 且 `hooks.gmail.account` 设置时:
- Gateway 启动时自动运行 `gog gmail watch serve`
- 自动续订 watch

跳过自动启动:
```bash
export OPENCLAW_SKIP_GMAIL_WATCHER=1
```

## 5. 无人值守模式最佳实践

### 5.1 服务级配置

```json5
{
  "gateway": {
    "mode": "local",
    "port": 18789,
    "channelHealthCheckMinutes": 5,
    "channelStaleEventThresholdMinutes": 30,
    "channelMaxRestartsPerHour": 10,
    "handshakeTimeoutMs": 30000
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "qwen/qwen3.5-122b-a10b",
        "fallbacks": ["glm4.7"]
      },
      "timeoutSeconds": 120,
      "maxConcurrent": 2,
      "heartbeat": {
        "every": "30m",
        "target": "last"
      }
    }
  },
  "cron": {
    "enabled": true,
    "maxConcurrentRuns": 2,
    "sessionRetention": "24h"
  },
  "session": {
    "reset": {
      "mode": "daily",
      "atHour": 4
    },
    "threadBindings": {
      "enabled": true,
      "idleHours": 24
    }
  }
}
```

### 5.2 系统服务配置 (systemd)

```ini
# /etc/systemd/system/openclaw.service
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
User=myuser
WorkingDirectory=/home/myuser
ExecStart=/usr/bin/openclaw gateway --port 18789
Restart=always
RestartSec=10
Environment=NODE_ENV=production

# 资源限制
LimitNOFILE=65535
MemoryMax=4G
CPUQuota=80%

[Install]
WantedBy=multi-user.target
```

启动服务:
```bash
sudo systemctl daemon-reload
sudo systemctl enable openclaw
sudo systemctl start openclaw
sudo systemctl status openclaw
```

### 5.3 监控与告警

**健康检查脚本**:
```bash
#!/bin/bash
# /usr/local/bin/openclaw-health.sh

STATUS=$(openclaw health --json 2>/dev/null)
OK=$(echo $STATUS | jq -r '.ok')

if [ "$OK" != "true" ]; then
    echo "CRITICAL: OpenClaw 健康检查失败" | mail -s "OpenClaw Alert" admin@example.com
    exit 2
fi

exit 0
```

**Cron 监控任务**:
```bash
# 每 5 分钟检查一次
*/5 * * * * /usr/local/bin/openclaw-health.sh
```

### 5.4 日志轮转

```bash
# /etc/logrotate.d/openclaw
/tmp/openclaw/openclaw-*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0644 myuser myuser
    postrotate
        systemctl reload openclaw 2>/dev/null || true
    endscript
}
```

### 5.5 备份策略

**每日备份脚本**:
```bash
#!/bin/bash
# /usr/local/bin/openclaw-backup.sh

BACKUP_DIR="/backup/openclaw"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

mkdir -p $BACKUP_DIR

# 备份配置
cp ~/.openclaw/openclaw.json $BACKUP_DIR/config_$DATE.json

# 备份工作区
tar -czf $BACKUP_DIR/workspace_$DATE.tar.gz \
    ~/.openclaw/workspace-main \
    ~/.openclaw/memory \
    ~/.openclaw/cron

# 备份会话
tar -czf $BACKUP_DIR/sessions_$DATE.tar.gz \
    ~/.openclaw/agents/*/sessions

# 清理旧备份
find $BACKUP_DIR -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "*.json" -mtime +$RETENTION_DAYS -delete
```

**Cron 定时备份**:
```bash
# 每天凌晨 3 点备份
0 3 * * * /usr/local/bin/openclaw-backup.sh
```

## 6. 自动化工作流示例

### 6.1 每日晨间简报

```bash
openclaw cron add \
  --name "Daily Morning Brief" \
  --cron "0 8 * * *" \
  --tz "Asia/Shanghai" \
  --session isolated \
  --message |
    请生成今日简报:
    1. 检查日历 (未来 24 小时事件)
    2. 检查未读邮件
    3. 检查 GitHub 通知
    4. 天气情况
    请总结关键信息，不超过 500 字。
  --model "qwen/qwen3.5-122b-a10b" \
  --announce \
  --channel telegram \
  --to "tg:123456789"
```

### 6.2 每周项目回顾

```bash
openclaw cron add \
  --name "Weekly Project Review" \
  --cron "0 9 * * 1" \
  --tz "Asia/Shanghai" \
  --session isolated \
  --message |
    请生成本周项目回顾:
    1. 分析 workspace-main 中的变更
    2. 检查 GitHub PR 和 Issue
    3. 总结本周完成的工作
    4. 列出下周计划建议
  --model "qwen/qwen3.5-122b-a10b" \
  --thinking high \
  --announce \
  --channel slack \
  --to "channel:C1234567890"
```

### 6.3 定期健康检查

```bash
openclaw cron add \
  --name "System Health Check" \
  --every "1h" \
  --session isolated \
  --message |
    执行系统健康检查:
    1. 检查 Gateway 状态
    2. 检查所有通道连接
    3. 检查磁盘空间
    4. 检查内存使用
    如有异常，发送告警。
  --tools "exec,read,web_search" \
  --announce \
  --channel telegram \
  --to "tg:123456789"
```

## 7. 故障恢复自动化

### 7.1 自动重启脚本

```bash
#!/bin/bash
# /usr/local/bin/openclaw-auto-restart.sh

LOG_FILE="/var/log/openclaw/restart.log"

# 检查服务状态
if ! openclaw gateway status | grep -q "running"; then
    echo "$(date): Gateway 未运行，尝试重启" >> $LOG_FILE
    
    # 尝试重启
    if openclaw gateway restart; then
        echo "$(date): Gateway 重启成功" >> $LOG_FILE
    else
        echo "$(date): Gateway 重启失败，发送告警" >> $LOG_FILE
        # 发送告警通知
        curl -X POST "https://hooks.slack.com/services/xxx" \
            -H 'Content-Type: application/json' \
            -d '{"text": "CRITICAL: OpenClaw Gateway 重启失败!"}'
    fi
fi
```

### 7.2 通道自动重配对

```bash
#!/bin/bash
# /usr/local/bin/openclaw-channel-repair.sh

for channel in telegram whatsapp discord; do
    STATUS=$(openclaw channels status --probe 2>/dev/null | jq -r ".channels.\"$channel\".status")
    
    if [ "$STATUS" = "loggedOut" ] || [ "$STATUS" = "disconnected" ]; then
        echo "$(date): 通道 $channel 异常，尝试重新配对" >> /var/log/openclaw/repair.log
        
        # 登出并重新配对
        openclaw channels logout --channel $channel
        # 这里可以添加自动配对逻辑，或发送通知等待手动配对
        curl -X POST "https://hooks.slack.com/services/xxx" \
            -H 'Content-Type: application/json' \
            -d "{\"text\": \"WARNING: 通道 $channel 需要重新配对\"}"
    fi
done
```

## 8. 参考文档

- [定时任务](https://docs.openclaw.ai/automation/cron-jobs)
- [Webhook 配置](https://docs.openclaw.ai/gateway/configuration#set-up-webhooks-hooks)
- [心跳机制](https://docs.openclaw.ai/gateway/heartbeat)
