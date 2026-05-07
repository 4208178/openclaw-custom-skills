#!/bin/bash
# 本地备份脚本

set -e

SOURCE_DIR="${1:-/home/myuser/.openclaw/workspace}"
BACKUP_DIR="${2:-/home/myuser/backups}"
COMPRESS="${3:-true}"
ENCRYPT="${4:-false}"

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 生成时间戳
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_${TIMESTAMP}"

# 备份文件路径
if [ "$COMPRESS" = "true" ]; then
    BACKUP_FILE="$BACKUP_DIR/${BACKUP_NAME}.tar.gz"
    tar -czf "$BACKUP_FILE" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"
else
    BACKUP_FILE="$BACKUP_DIR/${BACKUP_NAME}.tar"
    tar -cf "$BACKUP_FILE" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"
fi

# 加密（如启用）
if [ "$ENCRYPT" = "true" ]; then
    GPG_PASSPHRASE="${GPG_PASSPHRASE:-}"
    if [ -z "$GPG_PASSPHRASE" ]; then
        echo "错误: 未设置 GPG_PASSPHRASE 环境变量"
        exit 1
    fi
    echo "$GPG_PASSPHRASE" | gpg --batch --yes --passphrase-fd 0 -c "$BACKUP_FILE"
    rm "$BACKUP_FILE"
    BACKUP_FILE="${BACKUP_FILE}.gpg"
fi

# 记录备份元数据
echo "备份完成: $BACKUP_FILE"
echo "源目录: $SOURCE_DIR"
echo "时间: $(date)"
echo "大小: $(du -h "$BACKUP_FILE" | cut -f1)"

# 写入日志
LOG_FILE="$BACKUP_DIR/backup.log"
echo "[$(date)] 备份完成: $BACKUP_FILE (源: $SOURCE_DIR)" >> "$LOG_FILE"
