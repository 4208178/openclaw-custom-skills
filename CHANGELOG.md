# 更新日志 (CHANGELOG)

## [2.1.0] - 2026-11-21

### 清理
- **移除根目录重复技能目录** (13 个)：agent-browser, agent-browser-clawdbot, elite-longterm-memory, email-notification, evolution-engine, find-skill, handsfree-windows-control, local-backup, nano-pdf, openclaw-skill-vetter, skill-vetter, vlm, windows-bridge, xiucheng-self-improving-agent, email-manager, github, telegram
- **清理空目录** (9 个)：.clawhub, .openclaw, .template, agent-configs, knowledge-base, memory, reports, scripts, session-logs-enhanced (根目录)
- **修复 session-logs-enhanced**：在 `skills/session-logs-enhanced/` 新增标准 `SKILL.md`，使其可作为正规技能加载
- **合并文档**：更新 README.md, SKILLS_INDEX.md 同步当前技能列表 (17 个)
- **技能总数**：18 → 17 (去重后)

### 修复
- 修复 `skills/session-logs-enhanced` 为空目录无 SKILL.md 问题
- 统一技能存放路径至 `skills/` 单一位置

## [2.0.0] - 2026-05-07

### 新增 (Added)
- 新增 5 个技能：
  - `openclaw-skill-vetter`: 官方安全审查工具 (最新版)
  - `session-logs-enhanced`: 增强版会话日志搜索
  - `find-skill`: 技能查找工具 (配置版)
  - `auto-vetter.sh`: 自动化安全审查脚本
  - `skill-vetting-report.md`: 审查报告模板
- 全量技能安全审查 (auto-vetter.sh)
- 固化报告格式

### 修复 (Fixed)
- 修复技能路径分散问题，统一至 `~/.openclaw/workspace/skills/`
- 修复 `local-backup` 脚本权限问题

### 文档 (Documentation)
- 生成 `SKILLS_INDEX.md` 技能清单
- 生成 `SKILL_TEST_REPORT.md` 测试报告
- 生成本 `CHANGELOG.md` 更新日志

### 依赖 (Dependencies)
- 确认系统依赖：tar, gzip, gpg, bash, node (v22.22.2), python3

### 已知问题 (Known Issues)
- `windows-bridge` 和 `handsfree-windows-control` 需 Windows 环境或 WSL
- `email-notification` 需配置 SMTP 服务器
- `vlm` 需确认 PyTorch 依赖
- `agent-browser*` 需安装浏览器框架 (Playwright/Puppeteer)

## [1.0.0] - 2026-04-24

### 新增 (Added)
- 恢复并统一配置 13 个自定义技能：
  - `local-backup`: 本地文件/目录自动化备份功能
  - `vlm`: 视觉语言模型接口
  - `email-notification`: 邮件通知功能
  - `windows-bridge`: Windows 桥接服务
  - `handsfree-windows-control`: 免提 Windows 控制
  - `elite-longterm-memory`: 高级长期记忆管理
  - `agent-browser`: 浏览器自动化控制
  - `agent-browser-clawdbot`: ClawDBot 专用浏览器代理
  - `find-skill`: 技能查找工具
  - `skill-vetter`: 技能质量检查器
  - `evolution-engine`: 自我进化引擎
  - `nano-pdf`: PDF 处理工具
  - `xiucheng-self-improving-agent`: 自改进代理

### 修复 (Fixed)
- 修复技能路径分散问题，统一至 `~/.openclaw/workspace/skills/`
- 修复 `local-backup` 脚本权限问题

### 文档 (Documentation)
- 生成 `SKILLS_INDEX.md` 技能清单
- 生成 `SKILL_TEST_REPORT.md` 测试报告
- 生成本 `CHANGELOG.md` 更新日志

### 依赖 (Dependencies)
- 确认系统依赖：tar, gzip, gpg, bash, node (v22.22.2), python3

### 已知问题 (Known Issues)
- `windows-bridge` 和 `handsfree-windows-control` 需 Windows 环境或 WSL
- `email-notification` 需配置 SMTP 服务器
- `vlm` 需确认 PyTorch 依赖
- `agent-browser*` 需安装浏览器框架 (Playwright/Puppeteer)