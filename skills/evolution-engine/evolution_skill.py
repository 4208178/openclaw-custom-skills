#!/usr/bin/env python3
"""
进化引擎技能 (Evolution Engine Skill)
OpenClaw 技能包装器，用于触发进化周期。
"""

import sys
import os
from pathlib import Path

# 添加父目录到路径，以便导入 evolution_engine
sys.path.insert(0, str(Path(__file__).parent.parent))

from evolution_engine import EvolutionEngine

def main():
    """主函数：被 OpenClaw 调用"""
    print("🚀 启动进化引擎技能...")
    
    engine = EvolutionEngine()
    
    # 运行进化周期
    result = engine.run_cycle()
    print(result)
    
    # 返回结果（供 OpenClaw 处理）
    return result

if __name__ == "__main__":
    main()
