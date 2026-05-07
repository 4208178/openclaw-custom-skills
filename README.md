# 🏠 OpenClaw 自定义技能集合
这是一个包含 **18 个** 自定义 OpenClaw 技能的仓库，由 **CEO 田螺 (Tian Luo)** 维护。

## 📦 包含技能 (18 个)

| 技能名称 | 描述 | 状态 | 依赖 |
|:---|:---|:---|:---|
| **local-backup** | 本地文件/目录自动化备份 | ✅ 可用 | tar, gzip |
| **vlm** | 视觉语言模型接口 | ⚠️ 需配置 | python3, torch |
| **email-notification** | 邮件通知功能 | ⚠️ 需配置 | SMTP, GPG |
| **windows-bridge** | Windows 桥接服务 | ⚠️ 需 Windows | Windows/WSL |
| **handsfree-windows-control** | 免提 Windows 控制 | ⚠️ 需 Windows | Windows/WSL, node |
| **elite-longterm-memory** | 高级长期记忆管理 | ✅ 可用 | Python, LanceDB |
| **agent-browser** | 浏览器自动化控制 | ✅ 可用 | Playwright |
| **agent-browser-clawdbot** | ClawDBot 专用代理 | ✅ 可用 | Playwright |
| **find-skill** | 技能查找工具 (GitHub/ClawHub) | ✅ 可用 | ClawHub CLI, curl |
| **skill-vetter** | 技能质量检查器 (安全审查) | ✅ 可用 | Python, jq |
| **openclaw-skill-vetter** | 官方安全审查工具 (最新版) | ✅ 可用 | ClawHub CLI |
| **evolution-engine** | 自我进化引擎 | ✅ 可用 | Python |
| **nano-pdf** | PDF 处理工具 | ✅ 可用 | Python, pdf2image |
| **xiucheng-self-improving-agent** | 自改进代理 | ✅ 可用 | Python |
| **session-logs-enhanced** | 增强版会话日志搜索 | ✅ 可用 | Python, sqlite3 |
| **email-manager** | 邮件管理工具 | ✅ 可用 | SMTP, IMAP |
| **github** | GitHub 集成工具 | ✅ 可用 | gh CLI, curl |
| **telegram** | Telegram 集成 | ⚠️ 需配置 | Telegram Bot Token |

## 🚀 快速开始
1. **克隆仓库**
   ```bash
   git clone https://github.com/4208178/openclaw-custom-skills.git
   cd openclaw-custom-skills
   ```

2. **安装到 OpenClaw**
   ```bash
   # 复制所有技能到 OpenClaw 工作区
   cp -r * ~/.openclaw/workspace-main/skills/
   # 重启 OpenClaw
   openclaw gateway restart
   ```

3. **验证安装**
   ```bash
   ls ~/.openclaw/workspace-main/skills/
   # 测试 find-skill
   clawhub search browser
   ```

## 📚 文档
- `SKILLS_INDEX.md` - 完整技能索引
- `SKILL_TEST_REPORT.md` - 技能测试报告 (2026-05-07)
- `CHANGELOG.md` - 更新日志
- 每个技能目录内的 `SKILL.md` - 详细使用说明

## 🔧 配置
### 本地备份 (local-backup)
在 `~/.openclaw/workspace-main/TOOLS.md` 中添加：
```markdown
### 备份设置
- 默认备份目录: /home/myuser/backups
- 保留策略: 最近 7 天 + 每周 1 个 + 每月 1 个
- 压缩: gzip (默认)
- 加密: AES-256 (可选，需配置 GPG_PASSPHRASE)
```

### 邮件通知 (email-notification)
需要配置 SMTP 服务器：
```bash
export SMTP_HOST=smtp.qq.com
export SMTP_PORT=465
export SMTP_USER=4208178@qq.com
export SMTP_PASSWORD=your_smtp_password
```

### Telegram (telegram)
需要配置 Bot Token：
```bash
export TELEGRAM_BOT_TOKEN=your_bot_token
```

## 🛠️ 开发
### 添加新技能
1. 在 `skills/` 目录下创建新文件夹
2. 添加 `SKILL.md` 文件（必需）
3. 可选：添加 `scripts/` 目录和可执行脚本
4. 更新 `SKILLS_INDEX.md` 和 `README.md`

### 测试技能
```bash
./auto-vetter.sh  # 运行安全审查
cat skill-vetting-report.md  # 查看报告
```

## 📝 版本历史
- **v2.0.0 (2026-05-07)** - 全量技能安全审查、新增 5 个技能 (total 18)、固化报告格式、更新维护者信息
- **v1.0.0 (2026-04-24)** - 初始版本，恢复 13 个自定义技能

## 👑 维护者
**CEO 田螺 (Tian Luo)** - 🏢✨ 团队领导者
- 维护时间：2026-05-07
- 时区：Asia/Shanghai (UTC+8)
- 状态：✅ 活跃

## 📄 许可证
本仓库包含的技能可能来自不同来源，请查看每个技能目录内的许可证文件。
