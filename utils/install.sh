#!/bin/bash

echo "915MHz Mesh Network Driver 安装脚本"
echo "=================================="

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    echo "请以root权限运行此脚本"
    echo "使用方法: sudo ./install.sh"
    exit 1
fi

# 编译驱动
echo "正在编译驱动..."
make clean
make

if [ $? -ne 0 ]; then
    echo "编译失败！"
    exit 1
fi

echo "驱动编译成功！"

# 安装驱动
echo "正在安装驱动..."
make install

if [ $? -ne 0 ]; then
    echo "安装失败！"
    exit 1
fi

# 加载驱动
echo "正在加载驱动..."
modprobe mesh_net_driver

if [ $? -ne 0 ]; then
    echo "驱动加载失败！"
    echo "请检查内核日志: dmesg | tail -20"
    exit 1
fi

echo "驱动加载成功！"

# 检查网络接口
echo "检查网络接口..."
ip link show | grep mesh

if [ $? -eq 0 ]; then
    echo "网络接口创建成功！"
    
    # 启用接口
    echo "正在启用网络接口..."
    ip link set mesh0 up
    
    # 配置IP地址
    echo "正在配置IP地址..."
    ip addr add 192.168.1.100/24 dev mesh0 2>/dev/null || echo "IP地址配置失败或已存在"
    
    echo "安装完成！"
    echo ""
    echo "使用方法："
    echo "1. 查看接口状态: ip link show mesh0"
    echo "2. 查看IP地址: ip addr show mesh0"
    echo "3. 测试连接: ping 192.168.1.100"
    echo "4. 运行测试程序: ./test_mesh_net"
    echo "5. 查看驱动日志: dmesg | grep mesh"
else
    echo "网络接口创建失败！"
    echo "请检查驱动状态: dmesg | grep mesh"
fi
