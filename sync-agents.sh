#!/bin/bash
# sync-agents.sh - 同步代理配置文件到 OpenClaw 运行时目录
# 用法：./sync-agents.sh

set -e

WORKSPACE="/home/myuser/.openclaw/workspace-main"
AGENT_ROOT="/home/myuser/.openclaw/agents"

echo "🔄 开始同步代理配置文件..."

# 同步 CTO (coding)
echo "📦 同步 CTO (coding) 配置..."
cp "$WORKSPACE/agent-configs/coding/agent/IDENTITY.md" "$AGENT_ROOT/coding/agent/IDENTITY.md"
cp "$WORKSPACE/agent-configs/coding/agent/AGENTS.md" "$AGENT_ROOT/coding/agent/AGENTS.md"
echo "✅ CTO 配置同步完成"

# 同步 CIO (comms)
echo "📦 同步 CIO (comms) 配置..."
cp "$WORKSPACE/agent-configs/comms/agent/IDENTITY.md" "$AGENT_ROOT/comms/agent/IDENTITY.md"
cp "$WORKSPACE/agent-configs/comms/agent/AGENTS.md" "$AGENT_ROOT/comms/agent/AGENTS.md"
echo "✅ CIO 配置同步完成"

echo "🎉 所有代理配置文件同步完成！"
echo "💡 提示：如需重启 Gateway 以加载新配置，请运行：openclaw gateway restart"
