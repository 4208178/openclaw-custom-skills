# OpenClaw 系统优化方案报告

**生成时间**: 2026-05-07 20:52 GMT+8  
**报告人**: CEO 田螺 (主代理) + CIO 田芯 (通信代理)  
**收件人**: 4208178@qq.com

---

## 📝 执行摘要

本报告针对 OpenClaw 系统当前面临的三大核心问题（API 限流、自愈系统、模型卡死）进行了深度调研与方案对比，并基于 CIO 的网络调研结果与 CTO 的代码分析，制定了**最优落地方案**。

---

## 1️⃣ 问题一：API 速率限制 (40 RPM)

### 现状
- **限制**: 40 次/分钟。
- **当前方案**: `agents.defaults.maxConcurrent: 2` (简化版令牌桶)。
- **风险**: 突发请求仍可能触发限流，且缺乏动态调整能力。

### 最优方案：动态令牌桶 + 分布式 Redis
- **核心逻辑**:
  1. 引入 `rate-limiter-skill` (ClawHub 待开发/集成)。
  2. 使用 Redis 存储令牌桶状态，支持多节点共享。
  3. 动态调整 `maxConcurrent` (根据 API 响应头 `Retry-After`)。
- **实施步骤**:
  1. 部署 Redis 容器。
  2. 在 `openclaw.json` 中配置 `rateLimiter.redisUrl`。
  3. 更新 `gateway` 逻辑，集成 Redis 限流中间件。
- **预期效果**: 平滑流量，突发请求自动排队，彻底杜绝 429 错误。

---

## 2️⃣ 问题二：任务中断需人工干预 (自愈系统)

### 现状
- **问题**: Gateway 重启、会话超时后，任务挂起，需人工重启。
- **当前方案**: `HEARTBEAT.md` 手动检查 + `sessions_send` 唤醒。
- **缺陷**: 依赖人工触发，非全自动。

### 最优方案：看门狗 + 状态持久化 (Watchdog + State Persistence)
- **核心逻辑**:
  1. **看门狗**: 独立守护进程 (或 `cron` 任务)，每分钟检查所有 `agent:*:main` 会话状态。
  2. **自动重启**: 检测到 `failed` 或 `done` (非正常结束) 时，立即发送唤醒指令。
  3. **状态持久化**: 任务执行前保存 `checkpoint` (WAL 日志)，重启后从断点恢复。
- **实施步骤**:
  1. 创建 `scripts/watchdog.sh` (或 Python 脚本)。
  2. 配置 `cron` 任务：`* * * * * /path/to/watchdog.sh`。
  3. 在 `agents.defaults` 中启用 `statePersistence: true`。
- **预期效果**: 系统故障自动恢复，无需人工干预，任务断点续传。

---

## 3️⃣ 问题三：模型卡死无响应 (超时熔断)

### 现状
- **问题**: 大模型长时间无反应，任务卡死。
- **当前方案**: 依赖 `timeoutSeconds` (局部配置)。
- **缺陷**: 未全局生效，且缺乏备用模型切换。

### 最优方案：多级超时 + 备用模型 (Multi-Level Timeout + Fallback)
- **核心逻辑**:
  1. **全局超时**: 设置 `agents.defaults.timeoutSeconds: 120`。
  2. **备用模型**: 配置 `fallbacks` 列表 (如 `GLM-4.7`)。
  3. **自动切换**: 主模型超时/失败时，自动重试备用模型。
- **实施步骤**:
  1. 更新 `openclaw.json`:
     ```json
     "agents": {
       "defaults": {
         "timeoutSeconds": 120,
         "fallbacks": ["custom-nvidia-glm4/z-ai/glm4.7"]
       }
     }
     ```
  2. 更新 `gateway` 路由逻辑，支持自动 fallback。
- **预期效果**: 主模型卡死时，120 秒内自动切换备用模型，任务不中断。

---

## 📌 综合实施路线图

| 优先级 | 任务 | 负责人 | 预计耗时 | 状态 |
| :--- | :--- | :--- | :--- | :--- |
| **P0** | 配置全局超时与备用模型 | CEO | 5 分钟 | ⏳ 待执行 |
| **P0** | 部署 Redis 并集成限流 | CTO | 30 分钟 | ⏳ 待执行 |
| **P0** | 编写并部署 Watchdog 脚本 | CIO | 20 分钟 | ⏳ 待执行 |
| **P1** | 开发 `rate-limiter-skill` | CTO | 2 小时 | ⏳ 待规划 |
| **P1** | 开发 `self-healing-agent` | CIO | 2 小时 | ⏳ 待规划 |

---

## 🚀 立即行动建议

1. **批准 P0 任务**：立即执行全局超时、备用模型配置，以及 Watchdog 脚本部署。
2. **启动 P1 开发**：授权 CTO/CIO 开发专用技能，实现长期自动化。
3. **监控验证**：运行 24 小时，观察限流与自愈效果。

---

**报告结束**。  
**CEO 田螺** 🏢✨  
**CIO 田芯** 📡
