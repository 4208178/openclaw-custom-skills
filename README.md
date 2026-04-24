# 🏠 OpenClaw 自定义技能集合

> 这是一个包含 13 个自定义 OpenClaw 技能的仓库，由田芯管家 (Tian Xin Guan Jia) 维护。

## 📦 包含技能

| 技能名称 | 描述 | 状态 | 依赖 |
|---------|------|------|------|
| `local-backup` | 本地文件/目录自动化备份 | ✅ 可用 | tar, gzip |
| `vlm` | 视觉语言模型接口 | ⚠️ 需配置 | python3, torch |
| `email-notification` | 邮件通知功能 | ⚠️ 需配置 | SMTP, gpg |
| `windows-bridge` | Windows 桥接服务 | ⚠️ 需 Windows | Windows/WSL |
| `handsfree-windows-control` | 免提 Windows 控制 | ⚠️ 需 Windows | Windows/WSL, node |
| `elite-longterm-memory` | 高级长期记忆管理 | ℹ️ 文档型 | - |
| `agent-browser` | 浏览器自动化控制 | ℹ️ 文档型 | Playwright/Puppeteer |
| `agent-browser-clawdbot` | ClawDBot 专用代理 | ℹ️ 文档型 | Playwright/Puppeteer |
| `find-skill` | 技能查找工具 | ℹ️ 文档型 | - |
| `skill-vetter` | 技能质量检查器 | ℹ️ 文档型 | - |
| `evolution-engine` | 自我进化引擎 | ℹ️ 文档型 | - |
| `nano-pdf` | PDF 处理工具 | ℹ️ 文档型 | - |
| `xiucheng-self-improving-agent` | 自改进代理 | ℹ️ 文档型 | - |

## 🚀 快速开始

### 1. 克隆仓库
```bash
git clone https://github.com/4208178/openclaw-custom-skills.git
cd openclaw-custom-skills
```

### 2. 安装到 OpenClaw
```bash
# 复制所有技能到 OpenClaw 工作区
cp -r * ~/.openclaw/workspace/skills/

# 重启 OpenClaw
openclaw gateway restart
```

### 3. 验证安装
```bash
# 检查技能列表
ls ~/.openclaw/workspace/skills/

# 测试 local-backup 技能
local-backup backup /path/to/source /path/to/backup --compress
```

## 📚 文档

- `SKILLS_INDEX.md` - 完整技能索引
- `SKILL_TEST_REPORT.md` - 技能测试报告
- `CHANGELOG.md` - 更新日志
- 每个技能目录内的 `SKILL.md` - 详细使用说明

## 🔧 配置

### 本地备份 (local-backup)
在 `~/.openclaw/workspace/TOOLS.md` 中添加：
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
# 设置环境变量
export SMTP_HOST=smtp.example.com
export SMTP_PORT=587
export SMTP_USER=your_email@example.com
export SMTP_PASS=your_password
export GPG_PASSPHRASE=your_gpg_passphrase  # 如需加密
```

## 🛠️ 开发

### 添加新技能
1. 在 `skills/` 目录下创建新文件夹
2. 添加 `SKILL.md` 文件（必需）
3. 可选：添加 `scripts/` 目录和可执行脚本
4. 更新 `SKILLS_INDEX.md` 和 `README.md`

### 测试技能
```bash
# 运行测试脚本
./test-all-skills.sh

# 查看测试报告
cat SKILL_TEST_REPORT.md
```

## 📝 版本历史

- **v1.0.0** (2026-04-24) - 初始版本，恢复 13 个自定义技能

## 👤 维护者

- **田芯管家 (Tian Xin Guan Jia)** - 🏠✨
- 维护时间：2026-04-24
- 时区：Asia/Shanghai (UTC+8)

## 📄 许可证

本仓库包含的技能可能来自不同来源，请查看每个技能目录内的许可证文件。
