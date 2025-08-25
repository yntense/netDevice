#!/bin/bash

echo "Mesh Network Driver 性能测试脚本"
echo "=============================="

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    echo "请以root权限运行此脚本"
    echo "使用方法: sudo ./performance_test.sh"
    exit 1
fi

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=== 网络性能测试 ==="

# 检查驱动是否加载
if ! lsmod | grep -q mesh; then
    echo -e "${RED}错误：驱动未加载，请先加载驱动${NC}"
    exit 1
fi

# 检查接口是否存在
if ! ip link show | grep -q mesh; then
    echo -e "${RED}错误：mesh接口不存在${NC}"
    exit 1
fi

# 配置测试IP地址
echo -e "\n${YELLOW}配置测试IP地址...${NC}"
ip addr add 192.168.1.100/24 dev mesh0 2>/dev/null
ip addr add 192.168.1.101/24 dev mesh0 2>/dev/null

echo -e "\n${BLUE}1. 基本网络统计测试${NC}"
echo "接口统计信息："
cat /proc/net/dev | grep mesh

echo -e "\n${BLUE}2. 数据包大小测试${NC}"
echo "测试不同大小的数据包..."

# 测试不同大小的ping包
for size in 64 128 256 512 1024 1472; do
    echo -n "测试 $size 字节数据包: "
    if ping -c 1 -s $size -W 1 192.168.1.100 >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
    fi
done

echo -e "\n${BLUE}3. 网络延迟测试${NC}"
echo "测试网络延迟（ping 100次）："
ping -c 100 -i 0.1 192.168.1.100 | tail -5

echo -e "\n${BLUE}4. 数据包丢失测试${NC}"
echo "测试数据包丢失率："
ping -c 1000 -i 0.01 192.168.1.100 | tail -3

echo -e "\n${BLUE}5. 网络吞吐量测试${NC}"
echo "使用iperf3测试网络吞吐量..."

# 检查iperf3是否可用
if command -v iperf3 >/dev/null 2>&1; then
    echo "启动iperf3服务器..."
    iperf3 -s -D -p 5201
    
    sleep 2
    
    echo "测试TCP吞吐量："
    iperf3 -c 192.168.1.100 -p 5201 -t 10 -i 1
    
    echo "测试UDP吞吐量："
    iperf3 -c 192.168.1.100 -p 5201 -t 10 -i 1 -u -b 100M
    
    # 停止iperf3服务器
    pkill iperf3
else
    echo -e "${YELLOW}iperf3未安装，跳过吞吐量测试${NC}"
    echo "安装命令: sudo apt install iperf3"
fi

echo -e "\n${BLUE}6. 网络工具测试${NC}"

# 测试netstat
echo "测试netstat："
if command -v netstat >/dev/null 2>&1; then
    netstat -i | grep mesh
else
    echo "netstat未安装"
fi

# 测试ss
echo "测试ss："
if command -v ss >/dev/null 2>&1; then
    ss -i | head -5
else
    echo "ss未安装"
fi

# 测试ethtool
echo "测试ethtool："
if command -v ethtool >/dev/null 2>&1; then
    ethtool mesh0 2>/dev/null || echo "ethtool不支持此接口类型"
else
    echo "ethtool未安装"
fi

echo -e "\n${BLUE}7. 数据包捕获测试${NC}"
echo "测试tcpdump（5秒）："
if command -v tcpdump >/dev/null 2>&1; then
    # 生成一些测试流量
    ping -c 10 192.168.1.100 >/dev/null &
    
    # 捕获数据包
    timeout 5 tcpdump -i mesh0 -c 10 2>/dev/null || echo "tcpdump超时或无数据包"
    
    # 等待ping完成
    wait
else
    echo "tcpdump未安装"
fi

echo -e "\n${BLUE}8. 压力测试${NC}"
echo "进行网络压力测试..."

# 创建大量并发连接
echo "创建100个并发ping进程..."
for i in {1..100}; do
    ping -c 1 -W 1 192.168.1.100 >/dev/null 2>&1 &
done

echo "等待所有ping进程完成..."
wait

echo -e "\n${BLUE}9. 内存和资源使用测试${NC}"
echo "检查驱动内存使用："
cat /proc/modules | grep mesh

echo "检查网络设备统计："
cat /proc/net/dev | grep mesh

echo -e "\n${BLUE}10. 清理测试环境${NC}"
echo "清理测试IP地址..."
ip addr del 192.168.1.100/24 dev mesh0 2>/dev/null
ip addr del 192.168.1.101/24 dev mesh0 2>/dev/null

echo -e "\n${GREEN}性能测试完成！${NC}"
echo "建议："
echo "1. 分析ping结果中的延迟和丢包率"
echo "2. 检查网络统计信息的变化"
echo "3. 监控系统资源使用情况"
echo "4. 对比不同数据包大小的性能表现"
