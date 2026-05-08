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
from pathlib import Path

# 加载 .env 文件
env_path = Path(__file__).parent.parent / '.env'
if env_path.exists():
    import dotenv
    dotenv.load_dotenv(env_path)

# 配置 (从 .env 读取，若无则使用默认值)
EMAIL = os.getenv('SMTP_EMAIL', '4208178@qq.com')
AUTH_CODE = os.getenv('SMTP_AUTH_CODE', '')
SMTP_SERVER = os.getenv('SMTP_SERVER', 'smtp.qq.com')
SMTP_PORT = int(os.getenv('SMTP_PORT', 465))
DEFAULT_RECIPIENT = os.getenv('DEFAULT_RECIPIENT', EMAIL)

def send_email(to_email, subject, body, is_html=False):
    """发送邮件"""
    print("📧 正在准备发送邮件...")
    print(f"   发件人：{EMAIL}")
    print(f"   收件人：{to_email}")
    print(f"   主题：{subject}")
    
    if not AUTH_CODE:
        print("❌ 错误：SMTP_AUTH_CODE 未配置，请检查 .env 文件")
        return False
    
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
        print(" [INFO] Connecting to SMTP server...")
        server = smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT)
        print(" [INFO] Logging in...")
        server.login(EMAIL, AUTH_CODE)
        print(" [INFO] Sending email...")
        server.send_message(msg)
        server.quit()
        print(" [OK] Email sent successfully!")
        print(f" [INFO] Sent to: {to_email}")
        return True
    except Exception as e:
        print(f" [ERROR] Send failed: {e}")
        # 记录失败日志
        with open('/home/myuser/.openclaw/workspace-main/email-send-fail.log', 'a') as f:
            f.write(f"Failed at {datetime.now()}: {e}\n")
        return False

def send_report_file(report_path, to_email=None):
    """发送报告文件作为邮件正文"""
    if to_email is None:
        to_email = DEFAULT_RECIPIENT
    
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
    subject = f"Tianluo Report: {filename} - {datetime.now().strftime('%Y-%m-%d %H:%M')}"
    
    # 邮件正文 (HTML 格式)
    body = f"""
<html>
<body>
<h2>📊 田螺自动报告</h2>
<p>发送时间：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
<hr>
<pre style="white-space: pre-wrap; font-family: monospace;">{report_content}</pre>
<hr>
<p><small>-- Tianluo (CEO) AI Assistant</small></p>
</body>
</html>
"""
    
    return send_email(to_email, subject, body, is_html=True)

def main():
    print("Tianluo - Email Sender")
    print("=" * 40)
    
    # 检查命令行参数
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python3 send_email.py <report_file> [recipient_email]")
        print("  python3 send_email.py --test # 发送测试邮件")
        return
    
    if sys.argv[1] == "--test":
        # 发送测试邮件
        success = send_email(
            DEFAULT_RECIPIENT,
            "Tianluo Test Email",
            f"<html><body><h2>测试邮件</h2><p>这是来自田螺的测试邮件。</p><p>发送时间：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p></body></html>",
            is_html=True
        )
    else:
        # 发送指定的报告文件
        report_path = sys.argv[1]
        to_email = sys.argv[2] if len(sys.argv) > 2 else None
        success = send_report_file(report_path, to_email)
    
    print("\n" + "=" * 40)
    if success:
        print("✅ Email sent successfully!")
    else:
        print("❌ Email send failed")

if __name__ == "__main__":
    main()
