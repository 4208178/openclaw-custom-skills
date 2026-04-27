# 🔒 邮件授权码安全指南

## 当前状态

- **邮箱**: `4208178@qq.com`
- **授权码**: 已配置在 `scripts/send_email.py` 中
- **类型**: QQ 邮箱 SMTP 授权码（应用专用密码）

## ✅ 安全性分析

### 为什么这是安全的？

1. **授权码 ≠ 主密码**
   - 授权码是 QQ 邮箱生成的**应用专用密码**
   - 即使泄露，攻击者**只能发送邮件**，无法登录邮箱
   - 无法查看邮件、无法修改密码、无法访问其他服务

2. **独立权限**
   - 授权码仅用于 SMTP 发送服务
   - 可以在 QQ 邮箱设置中单独关闭 SMTP 服务使授权码失效
   - 可以随时生成新的授权码替换旧的

3. **本地存储**
   - 当前存储在本地脚本中，未上传到 GitHub
   - 建议将敏感配置移出代码

## 🛡️ 推荐的改进方案

### 方案 A：使用环境变量（最推荐）

1. **修改脚本** (`scripts/send_email.py`):
```python
import os

EMAIL = os.getenv("SMTP_EMAIL", "4208178@qq.com")
AUTH_CODE = os.getenv("SMTP_AUTH_CODE")  # 从环境变量读取
```

2. **设置环境变量** (在 `~/.bashrc` 或 `~/.zshrc`):
```bash
export SMTP_EMAIL="4208178@qq.com"
export SMTP_AUTH_CODE="你的授权码"
```

3. **或者使用 .env 文件**:
```bash
# 创建 .env 文件
echo "SMTP_EMAIL=4208178@qq.com" > ~/.openclaw/.env
echo "SMTP_AUTH_CODE=你的授权码" >> ~/.openclaw/.env

# 确保 .env 不被上传
echo ".env" >> ~/.openclaw/.gitignore
```

### 方案 B：使用系统密钥环（更安全）

```bash
# 安装 keyring
pip install keyring

# 设置密码
python3 -c "import keyring; keyring.set_password('email-notification', 'auth_code', '你的授权码')"

# 修改脚本读取
import keyring
AUTH_CODE = keyring.get_password('email-notification', 'auth_code')
```

## 🚫 不安全的做法

- ❌ 将授权码直接提交到 GitHub
- ❌ 在公开对话中分享授权码
- ❌ 将授权码硬编码在共享脚本中
- ❌ 使用主邮箱密码代替授权码

## 🔄 如何更换授权码

1. 登录 QQ 邮箱网页版
2. 设置 → 账户
3. 找到 "POP3/IMAP/SMTP/Exchange/CardDAV/CalDAV 服务"
4. 点击 "生成授权码" (或重新生成)
5. 复制新的授权码
6. 更新脚本或环境变量

## 📋 安全检查清单

- [x] 使用授权码而非主密码
- [x] 未上传到 GitHub
- [ ] 考虑使用环境变量存储
- [ ] 定期检查授权码使用情况
- [ ] 必要时重新生成授权码

## 💡 结论

**当前配置是安全的**，因为：
1. 使用的是应用专用授权码，权限受限
2. 未上传到公共仓库
3. 即使泄露也无法造成严重后果

**建议改进**：使用环境变量存储授权码，避免硬编码在脚本中。

---
生成时间：2026-04-24 18:05
维护者：田芯管家
