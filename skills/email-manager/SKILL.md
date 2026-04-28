# email-manager

**描述**: 田芯管家邮件管理技能，支持 SMTP 发送和 IMAP 接收/搜索/删除。
**作者**: Tian Xin Guan Jia (田芯管家)
**版本**: 1.0.0 (2026-04-27)
**依赖**: Python 3.10+, `smtplib`, `imaplib` (内置)
**状态**: ✅ 稳定 (Stable)

## 📋 功能列表
| 功能 | 命令 | 说明 |
|------|------|------|
| **发送** | `email-manager send` | 通过 SMTP (587/465) 发送邮件，支持 HTML/纯文本 |
| **接收** | `email-manager receive` | 通过 IMAP (993) 读取收件箱，支持分页显示 |
| **搜索** | `email-manager search` | 按关键词/发件人搜索邮件 |
| **删除** | `email-manager delete` | 标记并删除指定邮件 (需确认) |

## ⚙️ 配置说明
### 1. 配置文件位置
`~/.openclaw/config/email_config.json`

### 2. 配置模板
```json
{
  "email": {
    "provider": "qq",           // 邮箱服务商标识
    "smtp_server": "smtp.qq.com", // SMTP 服务器地址
    "smtp_port": 587,            // 端口 (推荐 587+STARTTLS 或 465+SSL)
    "use_ssl": true,             // 是否启用 SSL/TLS
    "sender": "your_email@qq.com", // 发件人邮箱
    "sender_name": "田芯管家",    // 发件人显示名称
    "authorization_code": "your_16_digit_auth_code" // 授权码 (非登录密码)
  }
}
```

### 3. 获取授权码 (以 QQ 邮箱为例)
1. 登录 [mail.qq.com](https://mail.qq.com)
2. 点击 **设置** -> **账户**
3. 开启 **IMAP/SMTP服务**
4. 点击 **生成授权码**，短信验证后复制 16 位代码

## 📖 详细用法

### 1. 发送邮件
**语法**: `email-manager send "收件人" "主题" "内容"`
**示例**:
```bash
# 发送纯文本邮件
./email-manager.sh send "user@example.com" "测试邮件" "这是一封测试邮件。"

# 发送长内容 (使用单引号包裹)
./email-manager.sh send "user@example.com" "报告" "$(cat report.txt)"
```

### 2. 接收/查看收件箱
**语法**: `email-manager receive [数量]`
**示例**:
```bash
# 查看最近 10 封 (默认)
./email-manager.sh receive

# 查看最近 5 封
./email-manager.sh receive 5
```
**输出示例**:
```
📬 收件箱中共有 18 封邮件。
📋 最近 10 封邮件：
[18] 主题: [完整报告] NVIDIA API 可用模型列表 (135 个)
     发件人: 4208178@qq.com
     日期: 27 Apr 2026 11:23:00 +0800
...
```

### 3. 搜索邮件
**语法**: `email-manager search "关键词"`
**示例**:
```bash
./email-manager.sh search "NVIDIA"
./email-manager.sh search "from:4208178@qq.com"
```

### 4. 删除邮件 (实验性)
**语法**: `email-manager delete "邮件ID"`
**示例**:
```bash
# 删除 ID 为 123 的邮件 (需二次确认)
./email-manager.sh delete "123"
```

## 🔒 安全注意事项
1. **敏感信息保护**: 配置文件 `email_config.json` 已自动加入 `.gitignore`，**切勿**提交到 Git。
2. **端口选择**: 默认使用 **587 + STARTTLS** (更稳定)，如遇问题可切换至 **465 + SSL**。
3. **权限控制**: 删除邮件操作需显式确认，防止误删。

## 🔄 版本历史
- **1.0.0** (2026-04-27): 初始版本，支持发送、接收、搜索。

## 📞 支持
遇到问题？请检查:
1. 授权码是否正确 (非登录密码)。
2. IMAP/SMTP服务是否开启。
3. 网络连接是否正常 (端口 587/993)。
4. 查看日志: `./email-manager.sh send ... 2>&1 | tee log.txt`
