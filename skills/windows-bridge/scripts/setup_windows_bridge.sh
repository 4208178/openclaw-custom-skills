#!/bin/bash
# 田螺姑娘 - WSL 到 Windows 桥接启动脚本（健壮版）
# 功能：自动设置 PowerShell 路径到 PATH（如果尚未存在），并记录操作。
# 改进点：幂等、日志记录、错误处理。

# 配置
PS_DIR="/mnt/c/Windows/System32/WindowsPowerShell/v1.0"
LOG_DIR="/home/myuser/.openclaw/logs"
LOG_FILE="$LOG_DIR/windows_bridge_setup.log"

# 确保日志目录存在
mkdir -p "$LOG_DIR"

# 日志函数
log_message() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$message" | tee -a "$LOG_FILE" >/dev/null
}

# 检查 PowerShell 目录是否存在
if [ ! -d "$PS_DIR" ]; then
    log_message "错误：PowerShell 目录不存在：$PS_DIR"
    exit 1
fi

# 检查 PS_DIR 是否已经在 PATH 中
if echo ":$PATH:" | grep -q ":$PS_DIR:"; then
    log_message "信息：PowerShell 目录已在 PATH 中：$PS_DIR"
    exit 0
fi

# 尝试将 PS_DIR 添加到 PATH 的前面
export PATH="$PS_DIR:$PATH"
log_message "信息：已将 PowerShell 目录添加到 PATH 前方：$PS_DIR"

# 验证设置
if echo ":$PATH:" | grep -q ":$PS_DIR:"; then
    log_message "成功：PATH 已更新，包含 PowerShell 目录。"
else
    log_message "警告：PATH 更新可能未成功生效。"
fi

exit 0