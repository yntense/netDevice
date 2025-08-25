#!/bin/bash

echo "查找内核错误代码行的脚本"
echo "========================"

echo "1. 获取错误地址和函数信息..."
echo "错误地址: 0x0000000000000078"
echo "错误函数: ethtool_check_ops+0x8/0x30"

echo ""
echo "2. 使用addr2line工具查找代码行（需要内核调试符号）..."
if command -v addr2line >/dev/null 2>&1; then
    echo "addr2line 可用"
    echo "使用方法: addr2line -e /usr/lib/debug/boot/vmlinux-$(uname -r) 0x[函数地址]"
else
    echo "addr2line 不可用，请安装: sudo apt install binutils"
fi

echo ""
echo "3. 使用gdb查找代码行..."
if command -v gdb >/dev/null 2>&1; then
    echo "gdb 可用"
    echo "使用方法: sudo gdb /usr/lib/debug/boot/vmlinux-$(uname -r)"
    echo "在gdb中运行: info line *ethtool_check_ops+0x8"
else
    echo "gdb 不可用，请安装: sudo apt install gdb"
fi

echo ""
echo "4. 检查内核调试符号..."
if [ -f "/usr/lib/debug/boot/vmlinux-$(uname -r)" ]; then
    echo "✓ 内核调试符号文件存在"
else
    echo "✗ 内核调试符号文件不存在"
    echo "安装方法: sudo apt install linux-image-$(uname -r)-dbg"
fi

echo ""
echo "5. 使用crash工具（如果可用）..."
if command -v crash >/dev/null 2>&1; then
    echo "crash 可用"
    echo "使用方法: sudo crash /usr/lib/debug/boot/vmlinux-$(uname -r) /var/crash/..."
else
    echo "crash 不可用"
fi

echo ""
echo "6. 手动分析调用堆栈..."
echo "从错误信息可以看出："
echo "- 错误发生在 mesh_net_init_module+0x1a9 处"
echo "- 调用路径: mesh_net_init_module → register_netdev → register_netdevice → ethtool_check_ops"
echo "- 问题在于 ethtool_ops 字段的设置"

echo ""
echo "建议：检查 mesh_net_driver.c 中 register_netdev 调用附近的代码"

