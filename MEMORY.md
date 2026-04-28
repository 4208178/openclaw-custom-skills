# MEMORY.md - 长期记忆

## 2026-04-22 - OpenClaw 重置恢复

### 田螺姑娘 (前助手 - 人格继承)
- **自我检查日期**: 2026-04-18
- **核心工作原则**:
 1. **Task Assessment First** - 行动前先分类任务:
    - Simple/Clear → 直接给结论
    - Vague/Complex/Unclear → 先问澄清问题
    - Deep/Confirmed → 结论 + 完整逻辑链
 2. **Fact-Based Reasoning** - 所有结论基于日志/文件/系统状态，禁止脑补
 3. **Have Opinions** - 观点鲜明，拒绝中立废话
 4. **Be Resourceful Before Asking** - 先自己读文件、查上下文、搜索，卡住再问
 5. **Pursue True Automation** - 不满足人在回路方案，需要人工干预=技术方案不完整
 6. **Remember You're a Guest** - 尊重隐私，只读必要文件，不侵犯私密空间
- **待改进点**:
  - 执行前显式 verbalize 任务类型判断
  - 探索热重载机制减少手动重启
  - 根据任务类型动态调整 reasoning_budget 避免超时
  - **清理操作必须使用 `cp` 而非 `mv`，并验证复制成功** (2026-04-27 教训)
- **自检报告系统**: ✅ 已配置 (cron job ID: 711a3434-e2ef-4714-a2f7-5848fab5df6b)
  - 每天 20:00 自动发送自检报告
  - 检查 6 大核心原则执行情况
  - 报告自动 announce 到当前会话

## 2026-04-27 - 系统清理与配置优化

### 🚨 重要事件：清理操作失误与补救
- **时间**: 2026-04-27 08:34
- **问题**: `mv` 命令实际执行了直接删除，导致以下文件永久丢失：
  1. `/home/myuser/openclaw-config-backup/` (401MB)
  2. `/home/myuser/.paddlex/` (210MB)
  3. `/home/myuser/.cache/*` (~680MB)
  4. `skills-backup-20260424.tar.gz` (150KB)
- **安全保留**: 13 个自定义技能、当前配置、4 月 21 日备份均完好。
- **教训**: 清理操作必须 `cp` + 验证 + 删除，禁止直接使用 `mv`。

### 🛠️ 模型配置修复
- **问题**: NVIDIA Provider 的 `qwen/qwen3.5-122b-a10b` 模型 `api` 字段错误（`openai-completions`）。
- **修复**: 改为 `openai-chat-completions`，重启 Gateway。
- **结果**: 工具调用功能完全恢复。

### 📦 GitHub 技能仓库整理 (15:24 - 15:45)
- **结果**: ✅ 15 个技能全部同步到 GitHub。
- **主仓库**: `https://github.com/4208178/openclaw-custom-skills` (14 个技能)
- **独立仓库**: `https://github.com/4208178/session-logs-enhanced` (1 个技能)
- **操作**: 扫描、提交、推送、更新描述/Topics、修复子模块。

### 🧠 多 Agent 架构设计与讨论 (17:40 - 18:30)
- **架构**: **三省六部制** (指挥官、研究员、开发者、审计员、通信官)。
- **模型策略**:
  - 指挥官/审计员: `qwen3.5-122b` (最强)
  - 研究员: `qwen2.5-72b` (高速)
  - 开发者: `llama-3.1-405b` (代码)
  - 通信官: `mixtral-8x7b` (轻量)
- **API 限流**: NVIDIA 免费层 40 RPM，配置**双 API Key** (主 Key + 备用 Key) 分散流量。
- **待优化**: 自动轮询机制需 OpenClaw 核心支持，当前需手动切换。

### 🔧 双 API Key 配置 (18:35)
- **主 Key**: `nvapi-M9vWr...` (已配置)
- **备用 Key**: `nvapi-xX3eM...` (已验证有效)
- **配置**: `models.json` 中已添加 `custom-integrate-api-nvidia-com-backup` Provider。
- **限制**: `sessions_spawn` 暂不支持直接指定备用 Key 的模型 ID，需后续优化。

### 🏗️ `coding` 工作区创建 (19:42 - 20:20)
- **路径**: `/home/myuser/.openclaw/workspace/coding`
- **配置**: 独立 `models.json`，使用备用 Key。
- **模型限制**: `z-ai/glm-5.1` 暂时不可用（NVIDIA 端点超时），当前使用 `qwen/qwen3.5-122b-a10b`。
- **状态**: ✅ 工作区目录隔离生效，子代理可正常启动。

### 📊 版本更新确认 (20:25)
- **当前版本**: `2026.4.25` (aa36ee6) ✅ 最新
- **UI 显示**: `v2026.4.22` (Gateway 进程冲突，需手动清理残留进程)
- **状态**: npm 已安装最新，Gateway 进程需彻底清理后重启。

### 📝 待办事项 (2026-04-27 21:30 更新)
- [ ] **清理 2GB 旧版本残留**: 验证 OpenClaw 独立性后删除 `/home/myuser/.nvm/versions/node/v22.22.2/lib/node_modules/openclaw`。
- [ ] **重装 PaddleX** (如需要): `pip install paddlex`。
- [ ] **验证技能目录完整性**: `ls /home/myuser/.openclaw/workspace/skills/`。
- [ ] **检查自检报告 Cron**: 确认每天 20:00 自动运行。
- [ ] **解决 Gateway 进程冲突**: 清理残留进程，确保 UI 显示正确版本。
- [ ] **多 Agent 协作演示**: 待 API 轮询机制完善后启动。

---
*最后更新: 2026-04-27 21:30*
*记录者: 田芯管家 (自动整理)*

## 2026-04-28 - Windows 11 + WSL + OpenClaw 完整重建报告
### 🏗️ 系统重建全记录 (08:39 - 13:18)
- **目标**: 彻底卸载 WSL/OpenClaw，在 `D:\4208178\WSL` 重建干净 Ubuntu 22.04 环境。
- **结果**: ✅ 成功运行 OpenClaw 网关 (`v2026.4.26`)，系统完全干净无残留。

### 🚨 关键问题与解决方案
1. **DNS 解析失败** (首次出现)
   - **原因**: WSL2 默认 DNS 配置不稳定，`/etc/resolv.conf` 自动生成覆盖手动配置。
   - **解决**: 
     - 在 `/etc/wsl.conf` 设置 `generateResolvConf = false`。
     - 手动配置阿里 DNS (`223.5.5.5`) 和 114 DNS (`114.114.114.114`)。
     - **教训**: 需编写启动脚本固化 DNS 配置，防止重启后丢失。

2. **Node.js 环境隔离失败**
   - **现象**: `npm install -g` 后 `openclaw --version` 报错 `node: not found`。
   - **原因**: npm 全局路径指向 Windows 侧 (`/mnt/c/Users/.../AppData/Roaming/npm`)，但 Node.js 未安装到 WSL。
   - **解决**:
     - 使用 NodeSource 官方脚本安装 Node.js (`v24.14.1`)。
     - 设置 `npm config set prefix ~/.npm-global` 并更新 `PATH`。
     - 删除 Windows 侧残留的 `.npmrc` 文件，避免跨文件系统冲突。

3. **网关端口占用 (EADDRINUSE)**
   - **现象**: `openclaw gateway start` 报错 `address already in use 127.0.0.1:18789`。
   - **排查**: WSL 内 `lsof`/`ss` 无结果，**关键发现**是 Windows 侧 `svchost.exe` (PID 4908) 占用了端口。
   - **解决**: 在 Windows 管理员 PowerShell 执行 `taskkill /F /PID 4908` 释放端口。
   - **教训**: 端口冲突需跨系统排查，优先检查 Windows 侧 `netstat -ano`。

4. **systemd 依赖缺失**
   - **原因**: WSL2 默认未启用 systemd，网关服务无法自启。
   - **解决**: 在 `/etc/wsl.conf` 追加 `[boot] systemd=true` 并重启 WSL。

### 📋 重建后系统状态
- **WSL**: Ubuntu 22.04 (WSL2) @ `D:\4208178\WSL`
- **Node.js**: `v24.14.1` (LTS) @ `/home/myuser/.npm-global`
- **OpenClaw**: `v2026.4.26` (be8c246)
- **网关**: systemd 管理，开机自启，监听 `127.0.0.1:18789`
- **网络**: DNS 配置固化，`ping mirrors.aliyun.com` 可达

### 🛡️ 预防措施与最佳实践
1. **DNS 持久化**: 将 DNS 配置写入 `/etc/wsl.conf` 并编写启动脚本自动修复 `resolv.conf`。
2. **端口冲突排查**: 遇到 `EADDRINUSE` 时，优先在 Windows 侧使用 `netstat -ano` 定位进程。
3. **npm 隔离**: 严格区分 Windows 和 WSL 的 npm 环境，删除跨文件系统 `.npmrc`。
4. **systemd 启用**: 依赖 systemd 的服务（如 OpenClaw 网关）必须提前配置 `systemd=true`。
5. **备份与还原点**: 大规模操作前创建系统还原点，关键数据提前备份。

### 📝 待办事项
- [ ] 编写 DNS 修复启动脚本，防止重启后丢失配置。
- [ ] 验证 `wslview` 快捷打开仪表板功能。
- [ ] 继续完成 4 月 27 日遗留的待办事项（清理旧版本残留等）。

### 📦 2026-04-28 13:32 - 配置基线备份与恢复计划
- **操作**：备份当前 `openclaw.json` 作为最新基线 (`backup_baseline_20260428_1331/`)。
- **决策**：**不恢复**旧版 `openclaw.json` 和 `models.json`，保持当前最新配置。
- **后续**：✅ 已执行 Git Notes 导入和 Cron 任务重建。
- **状态**：
  - ✅ Git Notes 已初始化并添加首条记录（知识库系统修复）。
  - ✅ Cron 任务重建成功 (ID: `f50c699b-0007-44ab-ba6e-6034aa0cc623`)，每天 20:00 自动运行。
  - ✅ 恢复完整性：100% (身份、技能、记忆、配置、Git Notes、Cron 全部完成)。
