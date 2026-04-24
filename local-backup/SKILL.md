# 本地备份技能 (local-backup)

## 用途
提供本地文件/目录的自动化备份功能，支持：
- 定时备份关键项目
- 增量备份与全量备份
- 压缩与加密
- 备份历史管理

## 使用方法

### 基础备份
```bash
# 备份指定目录到备份目录
local-backup backup <source> <dest> [--compress] [--encrypt]
```

### 定时备份
```bash
# 每天凌晨2点备份项目目录
local-backup schedule --daily 02:00 --source /path/to/project --dest /path/to/backups
```

### 查看备份历史
```bash
local-backup list --dest /path/to/backups
```

### 恢复备份
```bash
local-backup restore <backup-file> <dest>
```

## 配置示例

在 `TOOLS.md` 中添加备份配置：
```markdown
### 备份设置
- 默认备份目录: /home/myuser/backups
- 保留策略: 最近7天 + 每周1个 + 每月1个
- 压缩: gzip (默认)
- 加密: AES-256 (可选)
```

## 实现要点
1. 使用 `tar` + `gzip` 进行压缩
2. 使用 `gpg` 进行加密（如启用）
3. 备份元数据记录（时间、大小、文件列表）
4. 自动清理过期备份
5. 备份完整性校验

## 注意事项
- 备份前确认源路径存在
- 大文件备份建议使用增量模式
- 加密备份需妥善保管密钥
- 定期验证备份可恢复性
