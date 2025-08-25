#!/bin/bash

echo "Mesh Network Driver 测试脚本"
echo "=========================="

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    echo "请以root权限运行此脚本"
    echo "使用方法: sudo ./test_driver.sh"
    exit 1
fi

# 检查驱动文件是否存在
if [ ! -f "mesh_net_driver.ko" ]; then
    echo "错误：找不到驱动文件 mesh_net_driver.ko"
    echo "请先编译驱动：make"
    exit 1
fi

echo "1. 检查当前加载的模块..."
lsmod | grep mesh

echo ""
echo "2. 加载驱动..."
insmod mesh_net_driver.ko

if [ $? -eq 0 ]; then
    echo "✓ 驱动加载成功"
else
    echo "✗ 驱动加载失败"
    echo "检查内核日志：dmesg | tail -20"
    exit 1
fi

echo ""
echo "3. 检查模块状态..."
lsmod | grep mesh

echo ""
echo "4. 检查内核日志..."
dmesg | grep mesh | tail -10

echo ""
echo "5. 检查网络接口..."
ip link show | grep mesh || echo "未找到mesh接口"

echo ""
echo "6. 卸载驱动进行清理..."
rmmod mesh_net_driver

if [ $? -eq 0 ]; then
    echo "✓ 驱动卸载成功"
else
    echo "✗ 驱动卸载失败"
fi

echo ""
echo "7. 最终检查..."
lsmod | grep mesh || echo "驱动已完全卸载"

echo ""
echo "测试完成！如果没有错误信息，说明驱动工作正常。"


