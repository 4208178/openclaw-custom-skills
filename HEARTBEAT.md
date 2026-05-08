# Heartbeat Tasks - 团队健康检查 (已禁用 - 改用熔断机制)

**状态**：✅ 已关闭主动轮询，改用**熔断器 + 轻量级检查**

**核心改进**：
- ❌ 不再等待代理回复（避免 429 循环）
- ✅ 连续失败 2 次后自动熔断 30 分钟
- ✅ 轻量级检查只读会话状态，不触发 API 调用
- ✅ 失败任务写入 `memory/pending-tasks.md`，等待手动恢复

## 熔断器机制
1. **触发条件**：连续 2 次检查发现 CTO/CIO 会话失效
2. **熔断期间**：静默退出，不执行任何检查
3. **自动恢复**：30 分钟后尝试一次轻量级检查
4. **手动恢复**：`echo '{"circuitOpen": false}' > memory/circuit-breaker-state.json`

## 检查流程 (每 30 分钟)
1. 读取 `memory/circuit-breaker-state.json`
2. 如果 `circuitOpen=true` → 静默退出
3. 如果 `circuitOpen=false` → 执行 `scripts/team-health-lite.sh`
4. 脚本检查 CTO/CIO 会话状态（不等待回复）
5. 记录结果到 `memory/team-health.log`
6. 如果连续失败 ≥ 2 次 → 打开熔断器

## 手动检查流程
当需要手动检查团队状态时：
```bash
# 1. 查看熔断器状态
cat memory/circuit-breaker-state.json

# 2. 如果熔断器关闭，手动执行检查
/home/myuser/.openclaw/workspace-main/scripts/team-health-lite.sh

# 3. 查看日志
cat memory/team-health.log

# 4. 如果需要重启失效会话
sessions_send --sessionKey agent:coding:main --message "CEO 指令：重启并汇报状态"
sessions_send --sessionKey agent:comms:main --message "CEO 指令：重启并汇报状态"
```

## 原任务
- `Simple-Heal` (ID: `07505dd1-1cd7-4694-b3e7-39181d66c49c`) - **已删除**
- `Team-Health-Lite` (ID: `fd06ebe2-fe69-46ad-906b-3d5cb8be8fd3`) - **已启用** (每 30 分钟)
