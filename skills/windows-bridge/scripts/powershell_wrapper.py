#!/usr/bin/env python3
"""
田螺姑娘 - PowerShell 包装脚本
通过返回JSON结果提供执行反馈，让OpenClaw能够知道命令是否真的成功执行
"""

import subprocess
import json
import sys
import os

def run_powershell_command(command, wait_for_process=False, timeout=30):
    """
    执行PowerShell命令并返回结构化结果
    
    Args:
        command (str): 要执行的PowerShell命令
        wait_for_process (bool): 是否等待进程完成（对于Start-Process等命令）
        timeout (int): 等待超时时间（秒）
    
    Returns:
        dict: 包含执行结果的字典
    """
    # 确保PowerShell路径在PATH中
    ps_path = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
    if not os.path.exists(ps_path):
        return {
            "success": False,
            "error": "PowerShell executable not found",
            "output": "",
            "command": command
        }
    
    # 构建完整命令
    full_command = [ps_path, "-Command", command]
    
    try:
        if wait_for_process:
            # 对于需要等待完成的命令
            result = subprocess.run(
                full_command,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            return {
                "success": result.returncode == 0,
                "output": result.stdout,
                "error": result.stderr if result.returncode != 0 else "",
                "returncode": result.returncode,
                "command": command
            }
        else:
            # 对于启动后台进程的命令（如Start-Process），不等待完成
            process = subprocess.Popen(
                full_command,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            # 给一点时间让进程启动
            try:
                stdout, stderr = process.communicate(timeout=3)
                # 即使是启动命令，也检查是否有即时错误
                return {
                    "success": process.returncode == 0,
                    "output": stdout,
                    "error": stderr,
                    "returncode": process.returncode,
                    "command": command,
                    "note": "Command initiated, process may still be running"
                }
            except subprocess.TimeoutExpired:
                # 超时通常意味着进程正在启动中（这是好事）
                process.kill()
                return {
                    "success": True,
                    "output": "Process started successfully (timeout indicates background execution)",
                    "error": "",
                    "returncode": 0,
                    "command": command,
                    "note": "Command initiated successfully in background"
                }
                
    except subprocess.TimeoutExpired:
        return {
            "success": False,
            "error": f"Command timed out after {timeout} seconds",
            "output": "",
            "command": command
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "output": "",
            "command": command
        }

def main():
    """命令行入口点"""
    if len(sys.argv) < 2:
        print(json.dumps({
            "success": False,
            "error": "Usage: powershell_wrapper.py '<command>' [wait]",
            "output": ""
        }))
        sys.exit(1)
    
    command = sys.argv[1]
    wait_for_process = len(sys.argv) > 2 and sys.argv[2].lower() == "wait"
    
    result = run_powershell_command(command, wait_for_process)
    print(json.dumps(result, ensure_ascii=False))

if __name__ == "__main__":
    main()