# OpenClaw 架构知识图谱

## 核心组件

### Gateway (网关)
- **角色**: 单点事实源 (Single Source of Truth)
- **功能**: 连接聊天应用与 AI Agent 的桥梁
- **运行模式**: 
  - `local`: 本地服务模式 (默认)
  - `daemon`: 后台守护进程
- **默认端口**: 18789
- **配置路径**: `~/.openclaw/openclaw.json`

### 架构层次
```
┌─────────────────────────────────────────────────────┐
│                  Chat Apps Layer                     │
│  Discord | Telegram | WhatsApp | Slack | WeChat...  │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│                   Gateway Layer                      │
│  - Channel Plugins (内置 + 外部)                      │
│  - Multi-agent Routing                              │
│  - Session Management                               │
│  - Health Monitoring                                │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│                   Agent Layer                        │
│  - Main Session (主会话)                             │
│  - Isolated Sessions (隔离会话)                      │
│  - Sandbox Runtimes (Docker/SSH/OpenShell)          │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│                  Model Providers                     │
│  - NVIDIA (Qwen, GLM, DeepSeek, Llama)              │
│  - Anthropic, OpenAI, Google (可选)                 │
└─────────────────────────────────────────────────────┘
```

## 关键特性

### 1. 多通道支持
- **内置通道**: Discord, Telegram, WhatsApp, Slack, Signal, iMessage 等
- **插件通道**: Matrix, Nostr, Twitch, Zalo, 微信 (openclaw-weixin)
- **配对机制**: 每个通道支持 `pairing` | `allowlist` | `open` | `disabled` 策略

### 2. 多 Agent 路由
- **会话隔离**: 每个 Agent/工作区/发送者独立会话
- **会话作用域**: 
  - `main`: 共享主会话
  - `per-peer`: 每对对话者独立
  - `per-channel-peer`: 每通道每对话者独立
  - `per-account-channel-peer`: 每账户每通道每对话者独立

### 3. 沙箱机制
- **模式**: `off` | `non-main` (默认) | `all`
- **范围**: `agent` (默认) | `session` | `shared`
- **后端**: `docker` (默认) | `ssh` | `openshell`
- **浏览器沙箱**: 支持独立 Docker 网络隔离

### 4. 配置管理
- **格式**: JSON5 (支持注释和尾随逗号)
- **热重载**: 配置文件修改自动应用
- **验证**: 严格模式，未知键会导致启动失败
- **版本控制**: `meta.lastTouchedVersion` 防止版本不匹配

## 文件结构
```
~/.openclaw/
├── openclaw.json              # 主配置文件
├── openclaw.json.last-good    # 上次成功的配置备份
├── openclaw.json.clobbered.*  # 被修复的损坏配置
├── agents/                    # Agent 工作区
│   ├── main/
│   ├── coding/
│   └── comms/
├── sessions/                  # 会话存储
├── cron/                      # 定时任务
│   ├── jobs.json
│   └── jobs-state.json
├── memory/                    # 记忆文件
│   ├── YYYY-MM-DD.md
│   └── MEMORY.md
├── logs/                      # 日志文件
├── media/                     # 媒体文件
├── plugins/                   # 插件
└── workspace-main/            # 主工作区
```

## 启动流程
1. **安装**: `npm install -g openclaw@latest`
2. **向导**: `openclaw onboard --install-daemon`
3. **验证**: `openclaw gateway status`
4. **控制 UI**: `openclaw dashboard` (http://127.0.0.1:18789)

## 参考文档
- [官方文档索引](https://docs.openclaw.ai/llms.txt)
- [配置参考](https://docs.openclaw.ai/gateway/configuration)
- [故障排查](https://docs.openclaw.ai/gateway/troubleshooting)
