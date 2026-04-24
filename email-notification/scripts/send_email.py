#!/usr/bin/env python3
"""
田螺姑娘 - 通用邮件发送脚本
通过SMTP发送邮件，支持自定义内容和收件人
"""

import smtplib
import email
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime
import os
import sys

# 配置 (与现有工作脚本保持一致)
EMAIL = "4208178@qq.com"
AUTH_CODE = "otxfdvdefgexcagh"  # 已授权的授权码
SMTP_SERVER = "smtp.qq.com"
SMTP_PORT = 465

def send_email(to_email, subject, body, is_html=False):
    """发送邮件"""
    print("📧 正在准备发送邮件...")
    
    # 创建邮件
    msg = MIMEMultipart()
    msg['From'] = EMAIL
    msg['To'] = to_email
    msg['Subject'] = subject
    
    # 添加邮件正文
    if is_html:
        msg.attach(MIMEText(body, 'html', 'utf-8'))
    else:
        msg.attach(MIMEText(body, 'plain', 'utf-8'))
    
    # 发送邮件
    try:
        print("  [INFO] Connecting to SMTP server...")
        server = smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT)
        print("  [INFO] Logging in...")
        server.login(EMAIL, AUTH_CODE)
        print("  [INFO] Sending email...")
        server.send_message(msg)
        server.quit()
        
        print("  [OK] Email sent successfully!")
        print(f"  [INFO] Sent to: {to_email}")
        return True
        
    except Exception as e:
        print(f"  [ERROR] Send failed: {e}")
        return False

def send_report_file(report_path, to_email=None):
    """发送报告文件作为邮件正文"""
    if to_email is None:
        to_email = EMAIL  # 默认发送给自己
    
    print("📧 正在准备发送报告邮件...")
    
    # 检查报告文件是否存在
    if not os.path.exists(report_path):
        print(f"❌ 报告文件不存在：{report_path}")
        return False
    
    # 读取报告内容
    try:
        with open(report_path, 'r', encoding='utf-8') as f:
            report_content = f.read()
    except Exception as e:
        print(f"❌ 读取报告文件失败：{e}")
        return False
    
    # 创建邮件主题
    filename = os.path.basename(report_path)
    subject = f"Tianluo Guniang Report: {filename} - {datetime.now().strftime('%Y-%m-%d %H:%M')}"
    
    # 邮件正文
    body = f"""
Hello!

This is an automated report from Tianluo Guniang.

{report_content}

--
Tianluo Guniang
AI Assistant
Sent at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""
    
    return send_email(to_email, subject, body)

def main():
    print("Tianluo Guniang - Email Sender")
    print("=" * 40)
    
    # 检查命令行参数
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python3 send_email.py <report_file> [recipient_email]")
        print("  python3 send_email.py --send-report  # 发送默认自检报告")
        print("  python3 send_email.py --test         # 发送测试邮件")
        return
    
    if sys.argv[1] == "--send-report":
        # 发送默认自检报告
        report_path = "/mnt/c/Users/4208178/OneDrive/Desktop/田螺姑娘输出/self_check_report_2026-04-18.md"
        success = send_report_file(report_path)
    elif sys.argv[1] == "--test":
        # 发送测试邮件
        success = send_email(
            EMAIL,
            "Tianluo Guniang Test Email",
            f"This is a test email from Tianluo Guniang.\n\nSent at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        )
    elif sys.argv[1] == "--help":
        print("Usage:")
        print("  python3 send_email.py <report_file> [recipient_email]")
        print("  python3 send_email.py --send-report  # 发送默认自检报告")
        print("  python3 send_email.py --test         # 发送测试邮件")
        return
    else:
        # 发送指定的报告文件
        report_path = sys.argv[1]
        to_email = sys.argv[2] if len(sys.argv) > 2 else None
        success = send_report_file(report_path, to_email)
    
    print("\n" + "=" * 40)
    if success:
        print("Email sent successfully!")
    else:
        print("Email send failed")

if __name__ == "__main__":
    main()