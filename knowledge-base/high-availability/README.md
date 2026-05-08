# OpenClaw 高可用架构最佳实践

## 概述

OpenClaw 本身设计为单点服务，但通过以下机制实现高可用性和可靠性：

## 1. 服务守护机制

### Systemd 服务管理
```bash
# 安装为系统服务
openclaw onboard --install-daemon

# 服务状态检查
openclaw gateway status
openclaw gateway status --deep  # 深度诊断

# 服务重启
openclaw gateway restart
```

### 自动重启策略
- **系统级**: 通过 systemd 配置自动重启
- **进程级**: Gateway 内置健康检查和自动恢复
- **通道级**: 通道健康监控自动重启异常通道

## 2. 健康监控 (Health Monitoring)

### 配置参数
```json5
{
  "gateway": {
    "channelHealthCheckMinutes": 5,        // 健康检查间隔 (默认 5 分钟)
    "channelStaleEventThresholdMinutes": 30, // 空闲超时阈值 (默认 30 分钟)
    "channelMaxRestartsPerHour": 10        // 每小时最大重启次数 (默认 10 次)
  },
  "channels": {
    "telegram": {
      "healthMonitor": {
        "enabled": true  // 可单独禁用某通道监控
      }
    }
  }
}
```

### 健康检查命令
```bash
# 快速状态检查
openclaw status
openclaw status --all      # 完整诊断
openclaw status --deep     # 深度探针

# 健康快照
openclaw health
openclaw health --verbose  # 强制实时探针
openclaw health --json     # JSON 格式输出

# 通道状态
openclaw channels status --probe
```

### 健康指标
- **Gateway 可达性**: 端口监听、响应时间
- **通道连接**: 每个通道的连接状态
- **会话活跃度**: 最近活动、会话数量
- **认证时效**: 凭证过期时间
- **资源使用**: CPU、内存、事件循环延迟

## 3. 配置保护机制

### 配置版本控制
- **lastTouchedVersion**: 配置写入时记录 OpenClaw 版本
- **防止版本不匹配**: 旧版本二进制拒绝操作新版本配置
- **最后已知良好副本**: `openclaw.json.last-good`

### 配置修复
```bash
# 诊断配置问题
openclaw doctor
openclaw doctor --fix      # 自动修复

# 验证配置
openclaw config validate

# 查看配置历史
ls -lt ~/.openclaw/openclaw.json.clobbered.*
```

### 配置热重载
- 配置文件修改自动检测
- 无效配置跳过重载，保持当前运行配置
- 损坏配置自动备份为 `.clobbered.*`

## 4. 会话持久化

### 会话存储
- **位置**: `~/.openclaw/agents/<agentId>/sessions/sessions.json`
- **作用域**: 支持多种会话隔离策略
- **线程绑定**: 支持 Discord `/focus`、`/unfocus` 等高级功能

### 会话重置策略
```json5
{
  "session": {
    "reset": {
      "mode": "daily",       // daily | idle | off
      "atHour": 4,           // 每日重置时间 (UTC)
      "idleMinutes": 120     // 空闲超时 (分钟)
    },
    "threadBindings": {
      "enabled": true,
      "idleHours": 24,
      "maxAgeHours": 0       // 0 = 无限制
    }
  }
}
```

## 5. 容错机制

### 模型故障转移
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

### 重试策略
- **模型切换重试**: 最多 2 次切换重试
- **超时处理**: `timeoutSeconds: 120` (默认)
- **并发限制**: `maxConcurrent: 2` (防止资源耗尽)

### 错误处理
- **429 限流**: 自动降级到备用模型
- **连接超时**: WebSocket 握手超时可配置 (`handshakeTimeoutMs`)
- **通道断线**: 自动重连 + 健康监控重启

## 6. 监控告警集成

### 日志管理
```bash
# 实时日志
openclaw logs --follow

# 诊断导出
openclaw gateway diagnostics export

# 稳定性报告
openclaw gateway stability --bundle latest
```

### 集成 Prometheus/Grafana (推荐方案)
```yaml
# Prometheus 配置示例
scrape_configs:
  - job_name: 'openclaw'
    static_configs:
      - targets: ['localhost:18789']
    metrics_path: '/metrics'  # 需通过反向代理暴露
```

### 集成 ELK 日志分析
```bash
# 日志路径
/var/log/openclaw/openclaw-*.log
# 或使用 journalctl
journalctl -u openclaw -f
```

## 7. 备份与恢复

### 配置备份
```bash
# 手动备份
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup.$(date +%Y%m%d)

# 工作区备份
tar -czf backup-$(date +%Y%m%d).tar.gz ~/.openclaw/workspace-main/
```

### 恢复流程
1. 停止 Gateway: `openclaw gateway stop`
2. 恢复配置: `cp backup.json ~/.openclaw/openclaw.json`
3. 恢复工作区: `tar -xzf backup.tar.gz -C ~/.openclaw/`
4. 启动 Gateway: `openclaw gateway start`

## 8. 高可用部署建议

### 单节点优化
- ✅ 启用 systemd 自动重启
- ✅ 配置健康监控
- ✅ 设置模型故障转移
- ✅ 定期备份配置和工作区
- ✅ 配置日志轮转

### 多节点部署 (手动方案)
- ⚠️ 使用负载均衡器 (如 Nginx) 分发请求
- ⚠️ 共享存储 (NFS/S3) 存储配置和会话
- ⚠️ 数据库后端存储会话状态 (需自定义开发)
- ⚠️ 使用 Tailscale 等工具实现内网互通

### 容器化部署
```dockerfile
FROM node:24-alpine
WORKDIR /app
RUN npm install -g openclaw@latest
COPY openclaw.json /root/.openclaw/
EXPOSE 18789
CMD ["openclaw", "gateway", "--port", "18789"]
```

## 参考文档
- [健康检查](https://docs.openclaw.ai/gateway/health)
- [故障排查](https://docs.openclaw.ai/gateway/troubleshooting)
- [配置参考](https://docs.openclaw.ai/gateway/configuration)
