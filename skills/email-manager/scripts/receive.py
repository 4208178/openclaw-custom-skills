#!/usr/bin/env python3
"""
田芯管家 - QQ 邮箱收件箱检查工具
使用 IMAP 协议读取收件箱
"""
import imaplib
import email
from email.header import decode_header
import json
import os

# 配置
EMAIL = "4208178@qq.com"
AUTH_CODE = "pvbsaudtwasobhei"  # 授权码
IMAP_SERVER = "imap.qq.com"
IMAP_PORT = 993

def decode_mime_header(header):
    """解码 MIME 编码的邮件主题"""
    if not header:
        return ""
    decoded_parts = decode_header(header)
    result = ""
    for part, encoding in decoded_parts:
        if isinstance(part, bytes):
            try:
                result += part.decode(encoding or 'utf-8', errors='ignore')
            except:
                result += part.decode('utf-8', errors='ignore')
        else:
            result += str(part)
    return result

def check_inbox():
    print("🔌 正在连接 QQ 邮箱 IMAP 服务器...")
    try:
        # 连接 IMAP
        mail = imaplib.IMAP4_SSL(IMAP_SERVER, IMAP_PORT)
        mail.login(EMAIL, AUTH_CODE)
        print("✅ 登录成功！")
        
        # 选择收件箱
        mail.select("inbox")
        
        # 搜索所有未读和已读邮件 (最近 10 封)
        status, messages = mail.search(None, "ALL")
        if status != "OK":
            print("❌ 搜索失败")
            return
        
        email_ids = messages[0].split()
        total_emails = len(email_ids)
        print(f"📬 收件箱中共有 {total_emails} 封邮件。")
        
        # 获取最近 10 封
        recent_count = min(10, total_emails)
        print(f"\n📋 最近 {recent_count} 封邮件：")
        print("-" * 80)
        
        for i in range(total_emails, total_emails - recent_count, -1):
            email_id = email_ids[i-1]
            status, msg_data = mail.fetch(email_id, "(RFC822.HEADER)")
            
            if status == "OK":
                raw_email = msg_data[0][1]
                msg = email.message_from_bytes(raw_email)
                
                # 提取信息
                subject = decode_mime_header(msg.get("Subject", "无主题"))
                from_ = decode_mime_header(msg.get("From", "未知发件人"))
                date = msg.get("Date", "未知日期")
                
                # 截断长文本
                if len(subject) > 50:
                    subject = subject[:47] + "..."
                if len(from_) > 40:
                    from_ = from_[:37] + "..."
                
                print(f"[{i}] 主题: {subject}")
                print(f"    发件人: {from_}")
                print(f"    日期: {date}")
                print("-" * 80)
        
        # 登出
        mail.logout()
        print("\n✅ 检查完成！")
        
    except imaplib.IMAP4.error as e:
        print(f"❌ IMAP 错误: {e}")
        print("  可能是授权码无效，或 IMAP 服务未开启。")
        print("  请检查 QQ 邮箱设置 -> 账户 -> IMAP/SMTP服务 是否开启。")
    except Exception as e:
        print(f"❌ 未知错误: {e}")

if __name__ == "__main__":
    check_inbox()
