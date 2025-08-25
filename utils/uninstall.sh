#!/bin/bash

echo "915MHz Mesh Network Driver 卸载脚本"
echo "=================================="

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    echo "请以root权限运行此脚本"
    echo "使用方法: sudo ./uninstall.sh"
    exit 1
fi

# 卸载驱动
echo "正在卸载驱动..."
modprobe -r mesh_net_driver

if [ $? -eq 0 ]; then
    echo "驱动卸载成功！"
else
    echo "驱动卸载失败！"
    echo "请检查是否有进程正在使用该接口"
fi

# 清理安装的文件
echo "正在清理安装文件..."
make uninstall

echo "卸载完成！"


