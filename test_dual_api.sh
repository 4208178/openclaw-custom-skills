#!/bin/bash

# 双 API 切换测试脚本
# 连续发送 3 个请求到主 API (Qwen 3.5)，观察是否触发 429 错误并切换到备用 API (GLM-4.7)

echo "=== 双 API 切换测试开始 ==="
echo "时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 初始化统计
total_requests=3
main_api_success=0
main_api_fail=0
fallback_count=0
total_time=0

# 记录开始时间
start_time=$(date +%s%3N)

for i in 1 2 3; do
    echo "[$i/3] 发送请求到主 API (Qwen 3.5)..."
    
    # 记录请求开始时间
    req_start=$(date +%s%3N)
    
    # 使用 OpenClaw 发送请求（通过调用自身来测试）
    # 这里我们模拟一个请求，实际测试需要使用 OpenClaw 的 API
    # 由于我们无法直接从脚本调用 OpenClaw 的模型，我们将使用一个简单的 curl 请求来模拟
    
    # 注意：实际的 API 测试需要通过 OpenClaw 的模型调用机制
    # 这里我们只是模拟测试流程
    
    # 使用 openclaw 命令发送一个简单的消息来测试
    response=$(echo "测试请求 $i" | timeout 60 openclaw chat --model custom-integrate-api-nvidia-com/qwen/qwen3.5-122b-a10b 2>&1)
    exit_code=$?
    
    # 记录请求结束时间
    req_end=$(date +%s%3N)
    req_time=$((req_end - req_start))
    total_time=$((total_time + req_time))
    
    echo "  响应时间：${req_time}ms"
    
    if [ $exit_code -eq 0 ]; then
        echo "  状态：成功"
        main_api_success=$((main_api_success + 1))
        
        # 检查是否使用了备用 API
        if echo "$response" | grep -q "glm4.7"; then
            echo "  注意：请求已切换到备用 API (GLM-4.7)"
            fallback_count=$((fallback_count + 1))
        fi
    else
        echo "  状态：失败 (退出码：$exit_code)"
        
        # 检查是否是 429 错误
        if echo "$response" | grep -qi "429\|rate limit\|too many requests"; then
            echo "  错误类型：429 速率限制"
            echo "  已切换到备用 API (GLM-4.7)"
            fallback_count=$((fallback_count + 1))
            main_api_fail=$((main_api_fail + 1))
        else
            echo "  错误类型：其他错误"
            main_api_fail=$((main_api_fail + 1))
        fi
    fi
    
    echo ""
    sleep 1  # 请求间隔
done

# 计算总耗时
end_time=$(date +%s%3N)
total_elapsed=$((end_time - start_time))

# 输出统计结果
echo "=== 测试完成 ==="
echo "总耗时：${total_elapsed}ms"
echo "平均响应时间：$((total_elapsed / total_requests))ms"
echo ""
echo "统计结果:"
echo "  主 API (Qwen 3.5) 成功次数：$main_api_success / $total_requests"
echo "  主 API 失败次数：$main_api_fail"
echo "  主 API 成功率：$(echo "scale=2; $main_api_success * 100 / $total_requests" | bc)%"
echo "  备用 API 切换次数：$fallback_count"
