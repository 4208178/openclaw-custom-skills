#!/bin/bash
# 🛡️ Auto-Vetter: 自动化技能安全审查脚本 (基于 skill-vetter 协议)
# 扫描项：凭证窃取、代码混淆、数据外泄、危险命令

SKILLS_DIR="/home/myuser/.openclaw/workspace-main/skills"
REPORT_FILE="/home/myuser/.openclaw/workspace-main/skill-vetting-report.md"

echo "# 🛡️ 全量技能自动化安全审查报告" > "$REPORT_FILE"
echo "**生成时间**：$(date '+%Y-%m-%d %H:%M:%S (GMT+8)')" >> "$REPORT_FILE"
echo "**执行者**：CEO 田螺 (Auto-Vetter)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 获取所有技能目录
SKILLS=$(ls -d "$SKILLS_DIR"/*/ 2>/dev/null | xargs -n1 basename)

TOTAL=0
SAFE=0
WARN=0
RISK=0

echo "## ✅ 审查结果汇总" >> "$REPORT_FILE"
echo "| 技能名称 | 风险等级 | 主要发现 |" >> "$REPORT_FILE"
echo "|:---|:---|:---|" >> "$REPORT_FILE"

for skill in $SKILLS; do
    TOTAL=$((TOTAL + 1))
    SKILL_PATH="$SKILLS_DIR/$skill"
    RISK_LEVEL="✅ 安全"
    FINDINGS=""

    # 1. 检查硬编码凭证 (API Key, Token, Password)
    if grep -rE "(api_key|token|password|secret|credential)\s*[:=]\s*['\"][^'\"]{8,}['\"]" "$SKILL_PATH" 2>/dev/null | grep -v "example\|placeholder\|YOUR_" > /dev/null; then
        RISK_LEVEL="⚠️ 警告"
        FINDINGS="发现硬编码凭证"
        WARN=$((WARN + 1))
    fi

    # 2. 检查危险命令 (rm -rf, curl | bash, wget | sh)
    if grep -rE "rm\s+-rf|curl.*\|\s*bash|wget.*\|\s*sh|eval\s*\(" "$SKILL_PATH" 2>/dev/null > /dev/null; then
        RISK_LEVEL="❌ 高风险"
        FINDINGS="发现危险命令 (rm -rf, curl|bash)"
        RISK=$((RISK + 1))
    fi

    # 3. 检查数据外泄 (curl/wget 发送到外部 IP/域名)
    if grep -rE "curl.*http[s]?://[^/]+/.*POST|wget.*http[s]?://[^/]+/.*POST" "$SKILL_PATH" 2>/dev/null | grep -v "localhost\|127.0.0.1" > /dev/null; then
        if [ "$RISK_LEVEL" != "❌ 高风险" ]; then
            RISK_LEVEL="⚠️ 警告"
        fi
        FINDINGS="${FINDINGS:+$FINDINGS, }发现潜在数据外泄"
        WARN=$((WARN + 1))
    fi

    # 4. 检查代码混淆 (base64 编码的 shell/python 代码)
    if grep -rE "base64\s+-d|eval\s*\(\$.*base64" "$SKILL_PATH" 2>/dev/null > /dev/null; then
        RISK_LEVEL="❌ 高风险"
        FINDINGS="发现代码混淆 (base64)"
        RISK=$((RISK + 1))
    fi

    # 5. 检查外部依赖 (pip install, npm install 非官方源)
    if grep -rE "pip\s+install.*http|npm\s+install.*http" "$SKILL_PATH" 2>/dev/null | grep -v "pypi.org\|registry.npmjs.org" > /dev/null; then
        RISK_LEVEL="⚠️ 警告"
        FINDINGS="${FINDINGS:+$FINDINGS, }发现非官方依赖源"
        WARN=$((WARN + 1))
    fi

    # 默认安全
    if [ -z "$FINDINGS" ]; then
        FINDINGS="无高风险项"
        SAFE=$((SAFE + 1))
    fi

    echo "| $skill | $RISK_LEVEL | $FINDINGS |" >> "$REPORT_FILE"
done

echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "## 📊 统计摘要" >> "$REPORT_FILE"
echo "- **总技能数**: $TOTAL" >> "$REPORT_FILE"
echo "- **✅ 安全**: $SAFE" >> "$REPORT_FILE"
echo "- **⚠️ 警告**: $WARN" >> "$REPORT_FILE"
echo "- **❌ 高风险**: $RISK" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "🏢✨ CEO 田螺 (Auto-Vetter)" >> "$REPORT_FILE"

echo "✅ 自动化审查完成！报告已生成：$REPORT_FILE"
cat "$REPORT_FILE"
