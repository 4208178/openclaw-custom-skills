# OpenClaw 容错机制详解

## 1. 概述

OpenClaw 的容错机制覆盖从底层服务到上层应用的全链路，确保在部分组件故障时系统仍能正常运行。

## 2. 服务层容错

### 2.1 Gateway 服务保护

#### 启动保护
- **配置验证**: 启动前严格验证配置，无效配置拒绝启动
- **版本检查**: 防止旧版本二进制操作新版本配置
- **端口冲突检测**: 自动检测并处理端口占用

#### 运行时保护
- **事件循环监控**: 检测事件循环阻塞，记录警告
- **内存压力监控**: 监控 RSS/堆内存，触发压缩或警告
- **会话队列管理**: 限制并发会话数，防止资源耗尽

### 2.2 服务重启策略

```json5
{
  "gateway": {
    "handshakeTimeoutMs": 30000  // WebSocket 握手超时 (默认 15000ms)
  }
}
```

**重启触发条件**:
- 配置无效导致启动失败
- 端口冲突
- 进程异常退出 (由 systemd 管理)
- 健康检查失败 (通道级)

**重启保护**:
- 每小时最大重启次数限制 (`channelMaxRestartsPerHour: 10`)
- 重启间隔退避
- 重启日志记录

## 3. 通道层容错

### 3.1 通道健康监控

#### 监控指标
- **连接状态**: WebSocket/长连接存活
- **事件活跃度**: 最近事件时间戳
- **认证状态**: 凭证有效期
- **响应延迟**: 消息往返时间

#### 自动恢复流程
```
检测到异常
    ↓
尝试重连 (最多 3 次)
    ↓
重连失败 → 标记为异常
    ↓
健康检查确认异常
    ↓
触发通道重启 (检查速率限制)
    ↓
重启成功 → 恢复正常
重启失败 → 发送告警
```

### 3.2 通道故障分类与处理

| 故障类型 | 错误码/信号 | 处理方式 |
|---------|-----------|---------|
| 认证失效 | 409-515, loggedOut | 自动触发重配对流程 |
| 网络断开 | 连接超时 | 指数退避重连 |
| 服务不可用 | 503, 504 | 等待服务恢复，定期探测 |
| 消息限流 | 429 | 退避等待，降级处理 |
| 配置错误 | 验证失败 | 拒绝加载，回滚到上次良好配置 |

### 3.3 配对与访问控制容错

```json5
{
  "channels": {
    "telegram": {
      "dmPolicy": "pairing",  // pairing | allowlist | open | disabled
      "allowFrom": ["tg:123"],
      "groups": {
        "*": {
          "requireMention": true,
          "mentionPatterns": ["@openclaw", "openclaw"]
        }
      }
    }
  }
}
```

**容错策略**:
- **配对模式**: 未知发送者获得一次性配对码
- **允许列表**: 仅允许列表中的发送者
- **开放模式**: 允许所有 DM (需 `allowFrom: ["*"]`)
- **禁用模式**: 忽略所有 DM

## 4. 模型层容错

### 4.1 故障转移机制

```json5
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "custom-integrate-api-nvidia-com/qwen/qwen3.5-122b-a10b",
        "fallbacks": ["custom-nvidia-glm4/z-ai/glm4.7"]
      }
    }
  }
}
```

**故障转移流程**:
```
主模型请求
    ↓
失败 (429/5xx/超时)
    ↓
尝试第一个备用模型
    ↓
失败 → 尝试下一个备用
    ↓
所有备用失败 → 返回错误
```

**重试限制**:
- 初始尝试 + 2 次切换重试 = 最多 3 次
- 防止无限循环

### 4.2 特定错误处理

#### 429 限流错误
```
HTTP 429: rate_limit_error: Extra usage is required for long context requests
```

**处理方案**:
1. 禁用 `context1m` 参数，降级到正常上下文窗口
2. 切换到可用的凭证
3. 配置备用模型链

#### 本地模型兼容性问题
```
messages[].content: invalid type: sequence, expected a string
```

**处理方案**:
```json5
{
  "models": {
    "providers": {
      "<provider>": {
        "models": [{
          "id": "<model-id>",
          "compat": {
            "requiresStringContent": true,
            "supportsTools": false
          }
        }]
      }
    }
  }
}
```

### 4.3 超时与并发控制

```json5
{
  "agents": {
    "defaults": {
      "timeoutSeconds": 120,    // 单次请求超时
      "maxConcurrent": 2        // 最大并发会话数
    }
  }
}
```

## 5. 会话层容错

### 5.1 会话持久化

- **存储位置**: `~/.openclaw/agents/<agentId>/sessions/sessions.json`
- **自动保存**: 每次消息交互后自动持久化
- **崩溃恢复**: 重启后从持久化状态恢复

### 5.2 会话重置策略

```json5
{
  "session": {
    "reset": {
      "mode": "daily",       // 每日重置
      "atHour": 4,           // UTC 4 点
      "idleMinutes": 120     // 或空闲 120 分钟后重置
    }
  }
}
```

**重置保护**:
- 重置前保存会话摘要
- 支持手动保留重要会话
- 重置后自动创建新会话

### 5.3 会话隔离

- **Agent 级隔离**: 不同 Agent 独立会话空间
- **通道级隔离**: 不同通道的会话独立
- **用户级隔离**: 同一通道不同用户独立会话

## 6. 沙箱层容错

### 6.1 沙箱故障处理

```json5
{
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "non-main",
        "backend": "docker",
        "scope": "agent"
      }
    }
  }
}
```

**故障场景**:
- **Docker 守护进程不可用**: 自动降级到非沙箱模式 (如果配置允许)
- **容器启动失败**: 重试 3 次，失败后记录错误并跳过该工具调用
- **容器资源不足**: 清理旧容器，重试创建

### 6.2 浏览器沙箱容错

```json5
{
  "agents": {
    "defaults": {
      "sandbox": {
        "browser": {
          "autoStart": true,
          "autoStartTimeoutMs": 30000,
          "network": "openclaw-sandbox-browser"
        }
      }
    }
  }
}
```

**容错机制**:
- 自动启动失败后重试
- 超时后降级到非沙箱浏览器 (如果可用)
- 容器泄漏自动清理

## 7. 定时任务容错 (Cron)

### 7.1 任务持久化

- **任务定义**: `~/.openclaw/cron/jobs.json`
- **任务状态**: `~/.openclaw/cron/jobs-state.json`
- **运行日志**: `~/.openclaw/cron/runs/<jobId>.jsonl`

### 7.2 任务执行容错

```json5
{
  "cron": {
    "enabled": true,
    "maxConcurrentRuns": 2,
    "sessionRetention": "24h",
    "runLog": {
      "maxBytes": "2mb",
      "keepLines": 2000
    }
  }
}
```

**容错策略**:
- **任务过期**: Gateway 启动时自动重新调度过期任务
- **执行超时**: 超时后自动终止并记录错误
- **会话泄漏**: 自动清理超时任务的会话
- **日志轮转**: 自动清理旧日志，保留最新日志

### 7.3 模型依赖容错

- **本地模型检查**: 执行前检查本地模型端点可用性
- **跳过机制**: 端点不可用时标记为 `skipped`，不视为执行错误
- **缓存探测**: 5 分钟内共享同一端点探测结果

## 8. 监控与告警

### 8.1 内置监控

```bash
# 状态检查
openclaw status --deep

# 健康快照
openclaw health --json

# 稳定性报告
openclaw gateway stability --bundle latest

# 诊断导出
openclaw gateway diagnostics export
```

### 8.2 日志分类

| 日志类型 | 路径 | 用途 |
|---------|------|------|
| 运行日志 | `/tmp/openclaw/openclaw-*.log` | 实时调试 |
| 稳定性日志 | `~/.openclaw/logs/stability/` | 性能分析 |
| 任务日志 | `~/.openclaw/cron/runs/` | 定时任务审计 |
| 会话日志 | `~/.openclaw/memory/YYYY-MM-DD.md` | 会话记录 |

### 8.3 告警集成建议

**Prometheus 集成**:
- 通过 `openclaw health --json` 定期抓取健康状态
- 解析 JSON 输出，暴露为 Prometheus metrics
- 配置告警规则 (如连续失败、高延迟)

**日志告警 (ELK)**:
- 收集 `openclaw-*.log` 到 Elasticsearch
- 配置告警规则 (如错误率、异常模式)
- 集成 Slack/邮件通知

## 9. 故障恢复清单

### 9.1 快速恢复步骤

```bash
# 1. 检查服务状态
openclaw gateway status

# 2. 查看日志
openclaw logs --follow

# 3. 诊断问题
openclaw doctor

# 4. 自动修复
openclaw doctor --fix

# 5. 重启服务
openclaw gateway restart

# 6. 验证恢复
openclaw health --verbose
```

### 9.2 配置恢复

```bash
# 1. 检查配置
openclaw config validate

# 2. 查看备份
ls -lt ~/.openclaw/openclaw.json.clobbered.*

# 3. 恢复备份
cp ~/.openclaw/openclaw.json.last-good ~/.openclaw/openclaw.json

# 4. 重启服务
openclaw gateway restart
```

### 9.3 通道恢复

```bash
# 1. 检查通道状态
openclaw channels status --probe

# 2. 登出异常通道
openclaw channels logout --channel <channel>

# 3. 重新配对
openclaw channels login --channel <channel>

# 4. 验证连接
openclaw channels status --probe
```

## 参考文档
- [故障排查](https://docs.openclaw.ai/gateway/troubleshooting)
- [健康检查](https://docs.openclaw.ai/gateway/health)
- [沙箱机制](https://docs.openclaw.ai/gateway/sandboxing)
- [定时任务](https://docs.openclaw.ai/automation/cron-jobs)
