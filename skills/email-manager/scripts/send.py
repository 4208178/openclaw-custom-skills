#!/usr/bin/env python3
"""
田芯管家 - 邮件发送工具
用法：python send_email.py "收件人" "主题" "内容"
"""
import smtplib
import json
import sys
import os
from email.mime.text import MIMEText
from email.header import Header

# 加载配置 (支持 BOM)
CONFIG_PATH = os.path.expanduser("~/.openclaw/config/email_config.json")
try:
    with open(CONFIG_PATH, 'r', encoding='utf-8-sig') as f:
        config = json.load(f)['email']
    smtp_server = config['smtp_server']
    smtp_port = config['smtp_port']
    sender = config['sender']
    auth_code = config['authorization_code']
except FileNotFoundError:
    print("❌ 错误：配置文件不存在。请先配置邮箱。")
    sys.exit(1)
except KeyError:
    print("❌ 错误：配置文件格式错误。")
    sys.exit(1)

def send_email(to_address, subject, body):
    try:
        print(f"🚀 正在发送邮件到 {to_address}...")
        msg = MIMEText(body, 'plain', 'utf-8')
        msg['From'] = sender
        msg['To'] = to_address
        msg['Subject'] = Header(subject, 'utf-8')
        
        server = smtplib.SMTP(smtp_server, smtp_port)
        server.starttls()
        server.login(sender, auth_code)
        server.sendmail(sender, [to_address], msg.as_string())
        server.quit()
        print("✅ 邮件发送成功！")
        return True
    except Exception as e:
        print(f"❌ 发送失败：{e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("用法：python send_email.py '收件人' '主题' '内容'")
        sys.exit(1)
    
    to_addr = sys.argv[1]
    subj = sys.argv[2]
    content = sys.argv[3]
    send_email(to_addr, subj, content)
