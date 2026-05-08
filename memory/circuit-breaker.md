# Circuit Breaker State - 代理健康检查熔断器

**启用时间**: 2026-05-08 08:49
**触发条件**: 连续 2 次心跳检查失败（429 或超时）
**恢复时间**: 30 分钟后自动恢复一次试探

## 当前状态
```json
{
  "circuitOpen": false,
  "failureCount": 0,
  "lastFailureAt": null,
  "lastCheckAt": null,
  "nextRetryAt": null,
  "blockedTasks": []
}
```

## 规则
1. **连续失败 ≥ 2 次** → 打开熔断器，暂停所有检查 30 分钟
2. **熔断期间** → 不执行任何 API 调用，任务写入 `memory/pending-tasks.md`
3. **30 分钟后** → 自动尝试一次轻量级检查（不等待回复）
4. **检查成功** → 关闭熔断器，恢复正常
5. **检查失败** → 保持熔断，等待用户手动干预

## 手动操作
- **立即恢复**: `echo '{"circuitOpen": false}' > memory/circuit-breaker-state.json`
- **强制重试**: `cron wake --jobId <id>` (仅当确认 API 恢复后)
- **查看状态**: `cat memory/circuit-breaker-state.json`
