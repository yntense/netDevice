#!/bin/bash

echo "Mesh Network Driver 详细调试脚本"
echo "=============================="

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    echo "请以root权限运行此脚本"
    echo "使用方法: sudo ./debug_driver.sh"
    exit 1
fi

# 检查驱动文件是否存在
if [ ! -f "mesh_net_driver.ko" ]; then
    echo "错误：找不到驱动文件 mesh_net_driver.ko"
    echo "请先编译驱动：make"
    exit 1
fi

echo "1. 清理之前的错误日志..."
dmesg -c > /dev/null 2>&1

echo ""
echo "2. 检查当前加载的模块..."
lsmod | grep mesh

echo ""
echo "3. 加载驱动（这可能会触发错误）..."
insmod mesh_net_driver.ko

echo ""
echo "4. 检查加载结果..."
if lsmod | grep -q mesh; then
    echo "✓ 驱动加载成功"
    
    echo ""
    echo "5. 检查网络接口..."
    ip link show | grep mesh || echo "未找到mesh接口"
    
    echo ""
    echo "6. 卸载驱动..."
    rmmod mesh_net_driver
    echo "✓ 驱动卸载成功"
else
    echo "✗ 驱动加载失败"
fi

echo ""
echo "7. 分析内核日志..."
echo "=== 最近的错误信息 ==="
dmesg | grep -E "(mesh|BUG|Oops|Call Trace)" | tail -30

echo ""
echo "8. 如果有错误，请运行以下命令获取详细信息："
echo "   dmesg | grep -A 50 'Call Trace:'"
echo "   dmesg | grep -A 20 'BUG:'"

echo ""
echo "调试完成！"

