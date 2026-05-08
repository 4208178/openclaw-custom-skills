# OpenClaw 监控与告警集成方案

## 1. 概述

OpenClaw 提供多层监控能力，从服务健康到业务指标，支持集成主流监控工具。

## 2. 内置监控能力

### 2.1 状态检查命令

```bash
# 快速状态摘要
openclaw status

# 完整诊断 (安全，可粘贴)
openclaw status --all

# 深度诊断 (包含实时探针)
openclaw status --deep

# 健康快照 (JSON 格式)
openclaw health --json

# 强制实时探针
openclaw health --verbose
```

### 2.2 健康指标详解

**openclaw health --json** 输出示例:
```json
{
  "ok": true,
  "ts": "2026-05-08T00:15:00.000Z",
  "durationMs": 245,
  "gateway": {
    "reachable": true,
    "mode": "local",
    "port": 18790
  },
  "channels": {
    "telegram": {
      "status": "connected",
      "lastEventAt": "2026-05-08T00:10:00.000Z",
      "authAgeHours": 12
    },
    "whatsapp": {
      "status": "disconnected",
      "lastError": "loggedOut"
    }
  },
  "agents": {
    "main": {
      "available": true,
      "activeSessions": 2
    }
  },
  "sessions": {
    "total": 45,
    "active": 3,
    "idle": 42
  }
}
```

### 2.3 通道状态监控

```bash
# 通道状态探针
openclaw channels status --probe

# 列出所有配对设备
openclaw pairing list --channel <channel>

# 查看凭证文件
ls -l ~/.openclaw/credentials/<channel>/<accountId>/creds.json
```

## 3. 日志监控

### 3.1 日志路径

| 日志类型 | 路径 | 说明 |
|---------|------|------|
| 运行日志 | `/tmp/openclaw/openclaw-*.log` | 实时运行日志 |
| 稳定性日志 | `~/.openclaw/logs/stability/` | 性能快照 |
| 任务日志 | `~/.openclaw/cron/runs/` | 定时任务执行日志 |
| 会话日志 | `~/.openclaw/memory/YYYY-MM-DD.md` | 会话记录 |

### 3.2 日志分析命令

```bash
# 实时日志跟踪
openclaw logs --follow

# 过滤特定日志
openclaw logs --follow | grep "error"

# 查看稳定性报告
openclaw gateway stability --bundle latest

# 导出诊断包
openclaw gateway diagnostics export
```

### 3.3 关键日志模式

**正常信号**:
- `web-heartbeat`: 心跳正常
- `web-reconnect`: 重连成功
- `web-auto-reply`: 自动回复正常

**异常信号**:
- `logged out`: 通道登出
- `EADDRINUSE`: 端口冲突
- `Invalid config`: 配置错误
- `HTTP 429`: API 限流

## 4. Prometheus 集成方案

### 4.1 自定义 Exporter (推荐)

创建 `openclaw-exporter.py`:

```python
#!/usr/bin/env python3
import json
import subprocess
import time
from prometheus_client import start_http_server, Gauge, Counter

# 定义指标
gateway_status = Gauge('openclaw_gateway_status', 'Gateway status (1=up, 0=down)')
channel_status = Gauge('openclaw_channel_status', 'Channel status', ['channel'])
active_sessions = Gauge('openclaw_active_sessions', 'Active session count')
total_sessions = Gauge('openclaw_total_sessions', 'Total session count')
health_probe_duration = Gauge('openclaw_health_probe_duration_seconds', 'Health probe duration')
error_count = Counter('openclaw_errors_total', 'Error count', ['error_type'])

def collect_metrics():
    try:
        # 获取健康状态
        result = subprocess.run(
            ['openclaw', 'health', '--json'],
            capture_output=True, text=True, timeout=10
        )
        health = json.loads(result.stdout)
        
        gateway_status.set(1 if health.get('ok') else 0)
        health_probe_duration.set(health.get('durationMs', 0) / 1000)
        
        # 通道状态
        for channel, data in health.get('channels', {}).items():
            status = 1 if data.get('status') == 'connected' else 0
            channel_status.labels(channel=channel).set(status)
        
        # 会话统计
        sessions = health.get('sessions', {})
        active_sessions.set(sessions.get('active', 0))
        total_sessions.set(sessions.get('total', 0))
        
    except Exception as e:
        gateway_status.set(0)
        error_count.labels(error_type='health_check').inc()

if __name__ == '__main__':
    start_http_server(9100)
    print("OpenClaw Exporter running on port 9100")
    
    while True:
        collect_metrics()
        time.sleep(60)  # 每分钟采集一次
```

### 4.2 Prometheus 配置

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'openclaw'
    static_configs:
      - targets: ['localhost:9100']
    scrape_interval: 60s

  - job_name: 'openclaw-logs'
    static_configs:
      - targets: ['localhost:9200']  # 如果使用 Loki
```

### 4.3 Grafana 仪表板

**推荐面板**:
1. **Gateway 可用性**: `gateway_status` (Gauge)
2. **通道连接状态**: `channel_status` (Gauge by channel)
3. **会话活跃度**: `active_sessions` vs `total_sessions` (Time series)
4. **健康检查延迟**: `health_probe_duration_seconds` (Histogram)
5. **错误率**: `error_count` (Counter)

## 5. ELK 日志分析集成

### 5.1 Filebeat 配置

```yaml
# filebeat.yml
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /tmp/openclaw/openclaw-*.log
    fields:
      app: openclaw
    fields_under_root: true

output.elasticsearch:
  hosts: ["localhost:9200"]
  index: "openclaw-logs-%{+yyyy.MM.dd}"
```

### 5.2 Logstash 配置 (可选)

```ruby
# logstash.conf
input {
  file {
    path => "/tmp/openclaw/openclaw-*.log"
    start_position => "beginning"
  }
}

filter {
  grok {
    match => { "message" => "%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{GREEDYDATA:message_body}" }
  }
  
  if [level] == "ERROR" {
    mutate {
      add_tag => ["error"]
    }
  }
}

output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => "openclaw-logs-%{+YYYY.MM.dd}"
  }
}
```

### 5.3 Kibana 仪表板

**推荐查询**:
- 错误统计: `level:ERROR`
- 通道异常: `message:"logged out" OR message:"409" OR message:"515"`
- 性能问题: `message:"event-loop delay" OR message:"memory pressure"`
- 配置问题: `message:"Invalid config" OR message:"validation failed"`

## 6. 告警规则配置

### 6.1 Prometheus Alertmanager

```yaml
# alertmanager.yml
groups:
  - name: openclaw
    rules:
      - alert: OpenClawGatewayDown
        expr: openclaw_gateway_status == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "OpenClaw Gateway 不可用"
          
      - alert: OpenClawChannelDisconnected
        expr: openclaw_channel_status == 0
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "通道 {{ $labels.channel }} 断开连接"
          
      - alert: OpenClawHighErrorRate
        expr: rate(openclaw_errors_total[5m]) > 0.1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "OpenClaw 错误率过高"
          
      - alert: OpenClawHealthProbeSlow
        expr: openclaw_health_probe_duration_seconds > 5
        for: 10m
        labels:
          severity: info
        annotations:
          summary: "健康检查延迟过高"
```

### 6.2 告警通知渠道

**Slack 集成**:
```yaml
receivers:
  - name: 'slack-notifications'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/xxx'
        channel: '#openclaw-alerts'
        title: 'OpenClaw 告警'
        text: '{{ .AlertAnnotations.summary }}'
```

**邮件集成**:
```yaml
receivers:
  - name: 'email-notifications'
    email_configs:
      - to: 'admin@example.com'
        from: 'openclaw-alerts@example.com'
        smarthost: 'smtp.example.com:587'
```

## 7. 自定义监控脚本

### 7.1 健康检查脚本

```bash
#!/bin/bash
# openclaw-health-check.sh

THRESHOLD=5  # 秒
STATUS=$(openclaw health --json 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "CRITICAL: OpenClaw 健康检查失败"
    exit 2
fi

OK=$(echo $STATUS | jq -r '.ok')
DURATION=$(echo $STATUS | jq -r '.durationMs')

if [ "$OK" != "true" ]; then
    echo "CRITICAL: OpenClaw 健康状态异常"
    exit 2
fi

if [ $DURATION -gt $((THRESHOLD * 1000)) ]; then
    echo "WARNING: 健康检查延迟 ${DURATION}ms > ${THRESHOLD}s"
    exit 1
fi

echo "OK: OpenClaw 健康检查正常 (${DURATION}ms)"
exit 0
```

### 7.2 通道状态监控脚本

```bash
#!/bin/bash
# openclaw-channel-monitor.sh

CHANNELS=("telegram" "whatsapp" "discord")

for channel in "${CHANNELS[@]}"; do
    STATUS=$(openclaw channels status --probe 2>/dev/null | jq -r ".channels.\"$channel\".status")
    
    if [ "$STATUS" != "connected" ]; then
        echo "WARNING: 通道 $channel 状态: $STATUS"
        # 可在此处发送告警通知
    fi
done
```

## 8. 监控最佳实践

### 8.1 监控覆盖范围

| 监控层级 | 指标 | 工具 | 频率 |
|---------|------|------|------|
| 服务层 | Gateway 状态、端口监听 | openclaw status | 1 分钟 |
| 通道层 | 连接状态、认证时效 | openclaw health | 5 分钟 |
| 会话层 | 活跃会话数、空闲会话数 | openclaw health | 5 分钟 |
| 性能层 | 健康检查延迟、事件循环延迟 | 自定义脚本 | 1 分钟 |
| 日志层 | 错误率、异常模式 | ELK | 实时 |

### 8.2 告警分级

| 级别 | 场景 | 响应时间 | 通知渠道 |
|------|------|---------|---------|
| Critical | Gateway 宕机、所有通道断开 | 立即 | 电话 + Slack + 邮件 |
| Warning | 单个通道断开、错误率升高 | 15 分钟 | Slack + 邮件 |
| Info | 健康检查延迟、会话积压 | 1 小时 | Slack |

### 8.3 日志保留策略

```bash
# 日志轮转配置 (logrotate)
/tmp/openclaw/openclaw-*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 myuser myuser
}
```

## 9. 诊断工具清单

```bash
# 日常检查
openclaw status
openclaw health --json
openclaw channels status --probe

# 深度诊断
openclaw status --deep
openclaw doctor
openclaw logs --follow

# 性能分析
openclaw gateway stability --bundle latest
openclaw gateway diagnostics export

# 配置验证
openclaw config validate
openclaw doctor --fix
```

## 参考文档
- [健康检查](https://docs.openclaw.ai/gateway/health)
- [故障排查](https://docs.openclaw.ai/gateway/troubleshooting)
- [诊断导出](https://docs.openclaw.ai/gateway/diagnostics)
