# {{SKILL_NAME}}

**描述**: {{SKILL_DESCRIPTION}}  
**作者**: Tian Xin Guan Jia (田芯管家)  
**版本**: {{VERSION}} ({{DATE}})  
**依赖**: {{DEPENDENCIES}}  
**状态**: ✅ 稳定 (Stable) / ⚠️ 实验性 (Experimental)

## 📋 功能列表
| 功能 | 命令 | 说明 |
|------|------|------|
| **功能1** | `{{SKILL_NAME}} action1` | {{DESC1}} |
| **功能2** | `{{SKILL_NAME}} action2` | {{DESC2}} |

## ⚙️ 配置说明
### 1. 配置文件位置
`~/.openclaw/config/{{CONFIG_FILE}}`

### 2. 配置模板
```json
{
  "{{CONFIG_KEY}}": {
    "param1": "value1",
    "param2": "value2"
  }
}
```

### 3. 配置步骤
1. {{STEP1}}
2. {{STEP2}}

## 📖 详细用法
### 1. {{ACTION1}}
**语法**: `{{SKILL_NAME}} action1 "arg1" "arg2"`  
**示例**:
```bash
./{{SKILL_NAME}}.sh action1 "value1" "value2"
```

### 2. {{ACTION2}}
**语法**: `{{SKILL_NAME}} action2 [options]`  
**示例**:
```bash
./{{SKILL_NAME}}.sh action2 --option
```

## 🔒 安全注意事项
1. **敏感信息**: 配置文件已加入 `.gitignore`。
2. **权限控制**: 危险操作需确认。
3. **网络要求**: 确保端口 {{PORT}} 开放。

## 🔄 版本历史
- **{{VERSION}}** ({{DATE}}): 初始版本，支持 {{FEATURES}}。

## 📞 支持
遇到问题？请检查:
1. {{CHECK1}}
2. {{CHECK2}}
3. 查看日志: `./{{SKILL_NAME}}.sh action1 2>&1 | tee log.txt`
