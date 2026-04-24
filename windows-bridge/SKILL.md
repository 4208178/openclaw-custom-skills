---
name: windows-bridge
description: 打通 WSL 与 Windows 节点的桥接技能。使用 powershell.exe 作为“翻译官”，让运行在 WSL 中的 OpenClaw 能够直接控制 Windows 程序（如浏览器、记事本等）。适用于 WSL2 镜像模式网络环境。
---

# Windows 桥接技能 (Windows Bridge Skill)

**核心原理**：利用 WSL2 的 `powershell.exe` 作为“翻译官”，将 Linux 命令转换为 Windows 可执行的命令。

## 当且仅当以下情况使用此技能

- 需要打开 Windows 程序（如浏览器、记事本、Excel 等）
- 需要控制 Windows 桌面应用（UI 自动化）
- 需要访问 Windows 文件系统（通过 `powershell.exe` 调用）
- 需要在 WSL 中测试 Windows 网络服务

## 核心命令

### 1. 打开程序
```bash
powershell.exe Start-Process "notepad.exe"
powershell.exe Start-Process "chrome.exe"
powershell.exe Start-Process "C:\\Program Files\\Microsoft Office\\root\\Office16\\WINWORD.EXE"
```

### 2. 打开网页
```bash
powershell.exe Start-Process "https://www.bing.com"
powershell.exe Start-Process "http://localhost:3000"  # 访问 WSL 或 Windows 本地服务
```

### 3. 执行 Windows 命令
```bash
powershell.exe -Command "Get-Process"
powershell.exe -Command "Get-ChildItem C:\\Users"
```

### 4. 文件操作（通过 PowerShell）
```bash
powershell.exe -Command "Copy-Item 'C:\\path\\to\\file.txt' 'D:\\backup\\'"
```

## 前置条件

1. **WSL2 镜像模式**：确保 `~/.wslconfig` 中包含：
   ```ini
   [wsl2]
   networkingMode=mirrored
   localhostForwarding=true
   ```
   修改后需运行 `wsl --shutdown` 并重启 WSL。

2. **环境变量**：确保 `powershell.exe` 在 PATH 中（启动脚本会自动处理）：
   ```bash
   export PATH="/mnt/c/Windows/System32/WindowsPowerShell/v1.0:$PATH"
   ```

## 使用示例

### 场景 1：打开浏览器
```bash
# 打开默认浏览器访问百度
powershell.exe Start-Process "https://www.baidu.com"
```

### 场景 2：打开记事本
```bash
powershell.exe Start-Process "notepad.exe"
```

### 场景 3：运行脚本
```bash
# 运行 Windows 上的 Python 脚本
powershell.exe -Command "python C:\\path\\to\\script.py"
```

## 反馈机制增强

为了让 OpenClaw 能够知道命令是否真的成功执行（而不仅仅是命令本身返回了 0），技能中包含了一个 PowerShell 包装脚本：`scripts/powershell_wrapper.py`。

### 使用方式
OpenClaw 内部会调用此包装脚本，它会返回 JSON 结果，包含：
- `success`: 布尔值，表示命令是否成功启动
- `output`: 标准输出
- `error`: 错误信息（如果有）
- `note`: 额外说明（如后台执行提示）

### 示例返回值
```json
{
  "success": true,
  "output": "",
  "error": "",
  "returncode": 0,
  "command": "Start-Process notepad.exe",
  "note": "Command initiated, process may still be running"
}
```

这使得 OpenClaw 能够在后续对话中准确报告：“记事本已成功打开” 或 “启动失败，错误：xxx”。

### 开发者注意
如果您直接在终端中测试，可以使用：
```bash
python3 /home/myuser/.openclaw/workspace/skills/windows-bridge/scripts/powershell_wrapper.py "Start-Process notepad.exe"
```

## 故障排查

### 问题 1：`powershell.exe: command not found`
**解决**：手动添加 PATH 或运行启动脚本：
```bash
/home/myuser/.openclaw/workspace/scripts/setup_windows_bridge.sh
```

### 问题 2：无法打开程序
**解决**：检查程序路径是否正确，尝试使用完整路径：
```bash
powershell.exe Start-Process "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
```

### 问题 3：网络服务无法访问
**解决**：确认 WSL 处于镜像模式，并检查防火墙设置。

## 与 handsfree-windows 的关系

- **windows-bridge**：基础桥接，用于启动程序、执行简单命令。
- **handsfree-windows**：高级 UI 自动化，用于模拟鼠标、键盘操作（需要额外安装 CLI）。

建议先使用 `windows-bridge` 启动程序，再使用 `handsfree-windows` 进行 UI 控制。