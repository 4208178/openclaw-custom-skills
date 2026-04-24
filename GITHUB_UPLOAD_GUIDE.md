# 📤 GitHub 上传指南

> 由于网络限制，自动推送失败。请按照以下步骤手动上传到 GitHub。

## 方法一：使用 GitHub 网页界面（推荐）

### 步骤 1: 创建仓库
1. 访问 https://github.com/new
2. 仓库名：`openclaw-custom-skills`
3. 描述：`OpenClaw 自定义技能集合 - 包含本地备份、长期记忆、Windows 桥接等 13 个自定义技能`
4. 选择：✅ Public
5. 不要勾选 "Add README, .gitignore, or license"
6. 点击 "Create repository"

### 步骤 2: 上传文件
1. 进入刚创建的仓库页面
2. 点击 "uploading an existing file" 链接
3. 拖拽以下文件/文件夹到上传区域：
   - `README.md`
   - `CHANGELOG.md`
   - `SKILLS_INDEX.md`
   - `SKILL_TEST_REPORT.md`
   - 所有技能文件夹（`local-backup/`, `vlm/`, 等）
4. 等待上传完成
5. 提交信息：`feat: 初始提交 - 恢复 13 个自定义技能 (2026-04-24)`
6. 点击 "Commit changes"

### 步骤 3: 创建版本标签
1. 在仓库页面点击 "Releases"
2. 点击 "Draft a new release"
3. 标签：`v1.0.0`
4. 目标：`main`
5. 标题：`v1.0.0 - 初始版本`
6. 描述：复制 `CHANGELOG.md` 的内容
7. 点击 "Publish release"

## 方法二：使用 Git 命令行（如网络允许）

### 前提条件
确保已配置 SSH 密钥或 HTTPS 凭证：
```bash
# 检查 SSH 密钥
ls ~/.ssh/id_ed25519.pub

# 如果没有，生成新密钥
ssh-keygen -t ed25519 -C "your_email@example.com"

# 将公钥添加到 GitHub
cat ~/.ssh/id_ed25519.pub
# 复制输出，访问 https://github.com/settings/keys 添加
```

### 推送步骤
```bash
cd /home/myuser/.openclaw/workspace/skills

# 初始化仓库（如果尚未初始化）
git init
git branch -m main
git add -A
git commit -m "feat: 初始提交 - 恢复 13 个自定义技能 (2026-04-24)"

# 添加远程仓库
git remote add origin git@github.com:4208178/openclaw-custom-skills.git

# 推送
git push -u origin main

# 创建标签
git tag -a v1.0.0 -m "初始版本 - 2026-04-24"
git push origin v1.0.0
```

## 方法三：使用 GitHub CLI（如网络允许）

```bash
cd /home/myuser/.openclaw/workspace/skills

# 创建仓库
gh repo create 4208178/openclaw-custom-skills --public --description "OpenClaw 自定义技能集合" --source=. --push

# 创建标签
git tag -a v1.0.0 -m "初始版本"
gh release create v1.0.0 --title "v1.0.0 - 初始版本" --notes-file CHANGELOG.md
```

## 验证上传

上传完成后，访问以下链接验证：
- 仓库主页：https://github.com/4208178/openclaw-custom-skills
- 版本标签：https://github.com/4208178/openclaw-custom-skills/releases/tag/v1.0.0

## 后续操作

上传成功后，可以：
1. 在 `README.md` 中添加仓库链接
2. 在 `SKILLS_INDEX.md` 中添加版本信息
3. 配置 GitHub Actions 自动化测试（可选）

## 故障排除

### 问题：HTTPS 连接超时
- 解决方案：使用 SSH 方式或网页上传

### 问题：SSH 权限拒绝
- 解决方案：生成新 SSH 密钥并添加到 GitHub

### 问题：文件过大
- 解决方案：分批次上传，或使用 `git lfs`

---
生成时间：2026-04-24 15:40
维护者：田芯管家
