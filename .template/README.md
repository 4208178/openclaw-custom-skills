# {{SKILL_NAME}} 封装模板

这是一个用于快速创建 OpenClaw 技能的模板。

## 使用方法
1. 复制整个 `.template` 目录到新技能目录：
   ```bash
   cp -r .template /path/to/new-skill
   cd /path/to/new-skill
   ```
2. 替换所有 `{{PLACEHOLDER}}` 为实际内容。
3. 修改 `{{SKILL_NAME}}.sh` 主脚本逻辑。
4. 运行 `git add .` 并提交。

## 必须修改的字段
- `SKILL_NAME`: 技能名称 (小写，连字符分隔)
- `SKILL_DESCRIPTION`: 简短描述
- `VERSION`: 语义化版本号 (如 1.0.0)
- `DEPENDENCIES`: 依赖列表
- `CONFIG_FILE`: 配置文件名
- `CONFIG_KEY`: 配置 JSON 中的键名
- `STEP1`, `STEP2`: 配置步骤
- `ACTION1`, `ACTION2`: 具体操作
- `PORT`: 默认端口
- `FEATURES`: 支持的功能
- `CHECK1`, `CHECK2`: 故障排查步骤
