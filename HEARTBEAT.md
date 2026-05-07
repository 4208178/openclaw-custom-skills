# Heartbeat Tasks - 团队健康检查

## 核心任务
1. **检查 CTO (蜜蜂/coding) 状态**
   - 检查 `agent:coding:main` 会话状态
   - 如果 `failed` 或 `done`，汇报 "CTO 需要重启"
   - 不自动重启，仅汇报

2. **检查 CIO (田芯/comms) 状态**
   - 检查 `agent:comms:main` 会话状态
   - 如果 `failed` 或 `done`，汇报 "CIO 需要重启"
   - 不自动重启，仅汇报

3. **通信链路测试**
   - 向 CTO/CIO 发送测试消息
   - 确认回复能正确路由回主会话

## 执行频率
- 每 2 小时检查一次（通过 cron 任务 `Team-Health-Check`）
- 超时时间：30 秒
- 失败告警：连续 2 次失败后发送告警

## 异常处理
- 如果连续 2 次检查失败，发送警报到微信
- 记录失败日志到 `memory/heartbeat-failures.log`
- 不自动重启，需手动干预

## 手动重启流程
如果 CTO 或 CIO 需要重启，请执行以下步骤：
1. 检查会话状态：`sessions_list`
2. 如果会话状态为 `failed` 或 `done`，发送唤醒消息：
   - CTO: `sessions_send --sessionKey agent:coding:main --message "CEO 指令：立即重启并汇报状态"`
   - CIO: `sessions_send --sessionKey agent:comms:main --message "CEO 指令：立即重启并汇报状态"`
3. 如果 `sessions_send` 超时，重启 Gateway：`openclaw gateway restart`
4. 验证会话状态：`sessions_list`
