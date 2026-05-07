#!/bin/bash
# 田芯管家 - Email Manager 技能
# 用法：email-manager [send|receive|search|delete] [args...]

ACTION=${1:-help}
shift || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case $ACTION in
  send)
    # 用法：email-manager send "to" "subject" "body"
    python3 "$SCRIPT_DIR/scripts/send.py" "$@"
    ;;
  receive)
    # 用法：email-manager receive [limit]
    python3 "$SCRIPT_DIR/scripts/receive.py" "$@"
    ;;
  search)
    # 用法：email-manager search "keyword"
    echo "搜索功能待实现..."
    ;;
  delete)
    # 用法：email-manager delete "message_id"
    echo "删除功能待实现..."
    ;;
  *)
    echo "田芯管家 - Email Manager 技能"
    echo "用法:"
    echo "  email-manager send 'to' 'subject' 'body'  - 发送邮件"
    echo "  email-manager receive [limit]             - 读取收件箱"
    echo "  email-manager search 'keyword'            - 搜索邮件"
    echo "  email-manager delete 'id'                 - 删除邮件"
    ;;
esac
