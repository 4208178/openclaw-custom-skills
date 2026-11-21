# 📚 自定义技能清单 (SKILLS_INDEX.md)

> 本文件记录所有 `skills/` 目录下的自定义技能。
> 路径：`~/.openclaw/workspace/skills/`

## 技能列表 (17 个)

| # | 技能名称 | 描述 | 状态 |
|---|---------|------|------|
| 1 | `agent-browser` | 浏览器自动化控制技能 | ✅ 已就绪 |
| 2 | `agent-browser-clawdbot` | ClawDBot 专用浏览器代理 | ✅ 已就绪 |
| 3 | `elite-longterm-memory` | 高级长期记忆管理 | ✅ 已就绪 |
| 4 | `email-manager` | 邮件管理工具 (SMTP/IMAP) | ✅ 已就绪 |
| 5 | `email-notification` | 邮件通知功能 | ⚠️ 需配置 SMTP |
| 6 | `evolution-engine` | 自我进化引擎 | ✅ 已就绪 |
| 7 | `find-skill` | 技能查找工具 (GitHub/ClawHub) | ✅ 已就绪 |
| 8 | `github` | GitHub 集成工具 | ✅ 已就绪 |
| 9 | `handsfree-windows-control` | 免提 Windows 控制 | ⚠️ 需 Windows/WSL |
| 10 | `local-backup` | 本地备份功能 | ✅ 已就绪 |
| 11 | `nano-pdf` | PDF 处理工具 | ✅ 已就绪 |
| 12 | `openclaw-skill-vetter` | 官方技能安全审查工具 | ✅ 已就绪 |
| 13 | `session-logs-enhanced` | 增强版会话日志搜索 | ✅ 已就绪 |
| 14 | `skill-vetter` | 技能质量检查器 (安全审查) | ✅ 已就绪 |
| 15 | `telegram` | Telegram 集成 | ⚠️ 需配置 Bot Token |
| 16 | `vlm` | 视觉语言模型接口 | ⚠️ 需配置 PyTorch |
| 17 | `windows-bridge` | Windows 桥接服务 | ⚠️ 需 Windows/WSL |

## 更新日志

- **2026-11-21**: 仓库结构清理 (v2.1.0)
  - 移除根目录重复的 13 个技能目录
  - 清理 9 个空目录
  - 修复 `session-logs-enhanced` (新增 SKILL.md)
  - 合并文档更新 (README, CHANGELOG)
  - 技能总数：18 → 17 (去重)

- **2026-05-07**: 新增 5 个技能 (openclaw-skill-vetter, session-logs-enhanced, find-skill, auto-vetter.sh 等)，总数 18
- **2026-04-24**: 初始恢复 13 个技能

## 使用说明

所有自定义技能统一位于 `skills/` 目录。
安装方法：
```bash
cp -r skills/* ~/.openclaw/workspace-main/skills/
openclaw gateway restart
```

如需添加新技能，在 `skills/` 下创建文件夹并包含 `SKILL.md`，然后更新此文件。