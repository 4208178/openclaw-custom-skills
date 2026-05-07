# 2026-04-28 - Windows 11 + WSL + OpenClaw 完整卸载与重建报告

## 🎯 目标
在 Windows 11 环境下彻底卸载 WSL 和 OpenClaw，清理所有残留，然后在 `D:\4208178\WSL` 目录重新搭建一个独立、干净的 Ubuntu 22.04 环境，并成功运行 OpenClaw 网关服务。

## 一、卸载阶段

### 1.1 准备工作
- 备份重要数据。
- 创建系统还原点。
- 全程在 **管理员 PowerShell** 中执行命令。

### 1.2 卸载 OpenClaw
| 命令 | 说明与结果 |
| :--- | :--- |
| `schtasks /Delete /F /TN "OpenClaw Gateway"` | 任务不存在（正常） |
| `schtasks /Delete /F /TN "OpenClaw Gateway (default)"` | 任务不存在（正常） |
| `npm uninstall -g openclaw` | 成功移除 434 个包 |
| `Remove-Item -Recurse -Force "$env:USERPROFILE\.openclaw"` 等 | 清理 `.openclaw`, `.clawdbot`, `.moltbot`, `.molthub` 目录及 `.openclawrc`, `.clawdbotrc` 文件 |
| `npm cache clean --force` | 清理成功 |
| 检查 `%LOCALAPPDATA%\OpenClaw`, `%APPDATA%\OpenClaw` | 无残留 |
| 手动删除 Path 中相关条目 | 完成 |
| 注册表清理 (`HKCU\Software\Microsoft\Windows\CurrentVersion\Lxss`) | 跳过或谨慎执行 |

### 1.3 卸载 WSL
| 命令 | 结果 |
| :--- | :--- |
| `wsl --list --verbose` | 显示 Ubuntu-22.04 (Stopped, v2) |
| `wsl --unregister Ubuntu-22.04` | 操作成功 |
| `wsl --shutdown` | 完成 |
| `dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart` | 成功 |
| 卸载内核更新包 | 未找到，跳过 |
| 重启后清理 `%LOCALAPPDATA%\Packages\CanonicalGroupLimited*` | 无残留 |
| **最终验证** | `wsl --list` → “没有已安装的分发版”；`openclaw --version` → 无法识别 |

## 二、重新搭建 WSL 到 D 盘

### 2.1 启用 WSL 功能
```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```
- 重启电脑生效。

### 2.2 安装 Ubuntu-22.04 到指定位置
- **初始尝试**：`wsl --install -d Ubuntu-22.04 --location D:\4208178\WSL`（下载成功，但需迁移）。
- **实际流程**：
  1. 默认安装：`wsl --install -d Ubuntu-22.04`
  2. 创建用户：`myuser`
  3. 导出：`wsl --export Ubuntu-22.04 D:\4208178\WSL\ubuntu_backup.tar`
  4. 注销原版：`wsl --unregister Ubuntu-22.04`
  5. 导入到 D 盘：`wsl --import Ubuntu-22.04 D:\4208178\WSL D:\4208178\WSL\ubuntu_backup.tar --version 2`
  6. 设置默认用户：
     ```bash
     sudo tee /etc/wsl.conf << EOF
     [user]
     default=myuser
     EOF
     ```
  7. 关闭 WSL：`wsl --shutdown`，重新进入后确认用户为 `myuser`。
  8. 删除备份文件：`Remove-Item D:\4208178\WSL\ubuntu_backup.tar`

## 三、环境配置与问题解决

### 3.1 DNS 解析问题（首次出现）
- **现象**：执行 `curl`, `apt update` 等命令时出现 `Temporary failure resolving` 或 `Connection refused`。
- **诊断**：WSL2 默认 DNS 配置不稳定。
- **解决方案**：
  1. 禁止自动生成 `resolv.conf`：
     ```bash
     sudo tee /etc/wsl.conf << EOF
     [network]
     generateResolvConf = false
     EOF
     ```
  2. 手动配置阿里 DNS 和 114 DNS：
     ```bash
     sudo rm /etc/resolv.conf
     sudo tee /etc/resolv.conf << EOF
     nameserver 223.5.5.5
     nameserver 114.114.114.114
     EOF
     ```
  3. 验证：`ping -c 2 mirrors.aliyun.com` 成功。
  4. **注意**：安装 `wslu` 时 DNS 再次丢失，需重复上述修复步骤。

### 3.2 Node.js 安装与 npm 路径隔离
- **问题**：WSL 内 `npm install -g openclaw` 后运行 `openclaw --version` 报错 `node: not found`。因为 npm 存在但 node 不存在，且 npm 全局路径指向 Windows 侧。
- **解决**：
  1. 安装 Node.js（NodeSource 官方脚本）：
     ```bash
     curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
     sudo apt install nodejs -y
     ```
     - 版本：`v24.14.1`, `npm 11.11.0`。
  2. 修正 npm 全局前缀到 Linux 家目录：
     ```bash
     npm config set prefix ~/.npm-global
     echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
     source ~/.bashrc
     ```
  3. 删除 Windows 侧残留的 `.npmrc` 文件。
  4. 验证：`npm config get prefix` 输出 `/home/myuser/.npm-global`。

### 3.3 安装 OpenClaw
```bash
npm install -g openclaw
openclaw --version
```
- 成功输出 `OpenClaw 2026.4.26 (be8c246)`。

## 四、网关服务配置与端口占用问题

### 4.1 启用 systemd
- 编辑 `/etc/wsl.conf` 追加：
  ```bash
  sudo tee -a /etc/wsl.conf << EOF
  [boot]
  systemd=true
  EOF
  ```
- `wsl --shutdown` 重启后生效。

### 4.2 安装并启动服务
```bash
openclaw gateway install
openclaw gateway start
```
- 日志报错 `EADDRINUSE: address already in use 127.0.0.1:18789`。

### 4.3 排查端口占用
- **WSL 内**：`lsof -i :18789` 和 `ss -tlnp | grep 18789` 均无结果。
- **Windows 侧**（管理员 PowerShell）：
  ```powershell
  netstat -ano | findstr :18789
  # 输出: TCP 0.0.0.0:18789 0.0.0.0:0 LISTENING 4908
  tasklist /FI "PID eq 4908"
  # 进程: svchost.exe
  taskkill /F /PID 4908
  ```
- **结果**：端口立即释放。

### 4.4 重启服务并验证
```bash
systemctl --user daemon-reload
systemctl --user enable openclaw-gateway.service
systemctl --user start openclaw-gateway.service
openclaw gateway status
```
- **状态**：`Runtime: running`, `Connectivity probe: ok`, `Service: systemd (enabled)`。

## 五、访问仪表板
- **Windows 浏览器**：直接访问 `http://127.0.0.1:18789/`。
- **快捷打开**：`sudo apt install wslu -y`，然后 `wslview http://127.0.0.1:18789/`。

## 六、最终状态总结
| 项目 | 状态 |
| :--- | :--- |
| WSL 发行版 | Ubuntu 22.04 (WSL2) |
| 存储位置 | `D:\4208178\WSL` |
| 默认用户 | `myuser` |
| Node.js | `v24.14.1` (LTS) |
| npm 全局路径 | `/home/myuser/.npm-global` |
| OpenClaw 版本 | `2026.4.26` |
| 网关服务 | systemd 管理，开机自启，监听 `127.0.0.1:18789` |
| 仪表板 | 可通过 `http://127.0.0.1:18789/` 访问 |
| DNS 配置 | `generateResolvConf = false` + 阿里 DNS (`223.5.5.5`, `114.114.114.114`) |
| 网络连通性 | 正常，`ping mirrors.aliyun.com` 可达 |

## 七、关键经验与预防措施
1. **DNS 持久化**：WSL 重启后 `/etc/resolv.conf` 可能消失，需固化配置或编写启动脚本自动修复。
2. **端口冲突**：若 Windows 服务占用端口，WSL 内无法监听。需使用 `netstat -ano` 在 Windows 侧排查并终止进程。
3. **npm 环境隔离**：避免 Windows 和 WSL 的 npm 路径混用，设置 `prefix` 到 Linux 家目录，删除跨文件系统的 `.npmrc` 冲突项。
4. **systemd 依赖**：WSL2 需在 `/etc/wsl.conf` 中启用 `systemd=true`，否则网关服务无法自启。
5. **备份与还原点**：大规模操作前创建系统还原点，关键数据提前备份。

---
*记录时间: 2026-04-28 13:18*
*记录者: 田芯管家 (自动整理)*
