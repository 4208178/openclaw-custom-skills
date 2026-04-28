#!/usr/bin/env python3
"""
田芯管家 - 邮件发送工具
用法：
  1. 纯文本：python send_email.py "收件人" "主题" "内容"
  2. 带附件：python send_email.py "收件人" "主题" "内容" "附件路径1" ["附件路径2" ...]
"""
import smtplib
import json
import sys
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders
from email.header import Header
import mimetypes

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

def send_email(to_address, subject, body, attachments=None):
    try:
        print(f"🚀 正在发送邮件到 {to_address}...")
        
        # 创建邮件容器
        if attachments:
            msg = MIMEMultipart()
            msg.attach(MIMEText(body, 'plain', 'utf-8'))
            print(f"📎 准备添加 {len(attachments)} 个附件...")
            for file_path in attachments:
                if not os.path.exists(file_path):
                    print(f"⚠️  警告：文件不存在，跳过：{file_path}")
                    continue
                
                # 获取文件名
                file_name = os.path.basename(file_path)
                
                # 尝试检测 MIME 类型
                mime_type, _ = mimetypes.guess_type(file_path)
                if mime_type is None:
                    mime_type = 'application/octet-stream'
                main_type, sub_type = mime_type.split('/', 1)
                
                # 读取并附加文件
                with open(file_path, 'rb') as f:
                    part = MIMEBase(main_type, sub_type)
                    part.set_payload(f.read())
                    encoders.encode_base64(part)
                    part.add_header('Content-Disposition', f'attachment; filename="{file_name}"')
                    msg.attach(part)
                    print(f"   ✅ 已附加：{file_name}")
        else:
            msg = MIMEText(body, 'plain', 'utf-8')
        
        # 设置邮件头
        msg['From'] = sender
        msg['To'] = to_address
        msg['Subject'] = Header(subject, 'utf-8')
        
        # 发送邮件
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
        print("用法：")
        print("  1. 纯文本：python send_email.py '收件人' '主题' '内容'")
        print("  2. 带附件：python send_email.py '收件人' '主题' '内容' '附件路径1' ['附件路径2' ...]")
        sys.exit(1)
    
    to_addr = sys.argv[1]
    subj = sys.argv[2]
    content = sys.argv[3]
    
    # 提取附件参数（第 4 个参数及之后）
    attachments = sys.argv[4:] if len(sys.argv) > 4 else None
    
    send_email(to_addr, subj, content, attachments)
# 更新：添加附件支持 (2026-04-28)
