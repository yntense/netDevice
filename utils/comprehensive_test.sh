#!/bin/bash

echo "Mesh Network Driver 完整功能测试脚本"
echo "=================================="

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    echo "请以root权限运行此脚本"
    echo "使用方法: sudo ./comprehensive_test.sh"
    exit 1
fi

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试结果统计
PASSED=0
FAILED=0
SKIPPED=0

# 测试函数
test_step() {
    local test_name="$1"
    local test_cmd="$2"
    local expected_result="$3"
    
    echo -e "\n${BLUE}测试: $test_name${NC}"
    echo "命令: $test_cmd"
    
    if eval "$test_cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ 通过${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ 失败${NC}"
        ((FAILED++))
    fi
}

echo "=== 第一阶段：驱动加载和基础功能测试 ==="

# 1. 检查驱动文件
echo -e "\n${YELLOW}1. 检查驱动文件${NC}"
if [ -f "mesh_net_driver.ko" ]; then
    echo -e "${GREEN}✓ 驱动文件存在${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ 驱动文件不存在${NC}"
    ((FAILED++))
    exit 1
fi

# 2. 检查当前模块状态
echo -e "\n${YELLOW}2. 检查当前模块状态${NC}"
if lsmod | grep -q mesh; then
    echo -e "${YELLOW}⚠ 驱动已加载，先卸载${NC}"
    rmmod mesh_net_driver 2>/dev/null
    sleep 1
fi

# 3. 加载驱动
echo -e "\n${YELLOW}3. 加载驱动${NC}"
if insmod mesh_net_driver.ko; then
    echo -e "${GREEN}✓ 驱动加载成功${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ 驱动加载失败${NC}"
    ((FAILED++))
    exit 1
fi

# 4. 检查模块是否在系统中
echo -e "\n${YELLOW}4. 验证模块加载${NC}"
if lsmod | grep -q mesh; then
    echo -e "${GREEN}✓ 模块在系统中可见${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ 模块未在系统中${NC}"
    ((FAILED++))
fi

# 5. 检查网络接口
echo -e "\n${YELLOW}5. 检查网络接口${NC}"
sleep 2
if ip link show | grep -q mesh; then
    echo -e "${GREEN}✓ mesh接口已创建${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ mesh接口未创建${NC}"
    ((FAILED++))
fi

echo -e "\n=== 第二阶段：接口配置和状态测试 ==="

# 6. 检查接口状态
echo -e "\n${YELLOW}6. 检查接口状态${NC}"
if ip link show mesh0 | grep -q "UP"; then
    echo -e "${GREEN}✓ 接口已启用${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ 接口未启用${NC}"
    ((FAILED++))
fi

# 7. 检查接口标志
echo -e "\n${YELLOW}7. 检查接口标志${NC}"
if ip link show mesh0 | grep -q "NOARP"; then
    echo -e "${GREEN}✓ NOARP标志设置正确${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ NOARP标志未设置${NC}"
    ((FAILED++))
fi

# 8. 检查MTU设置
echo -e "\n${YELLOW}8. 检查MTU设置${NC}"
MTU=$(ip link show mesh0 | grep -o "mtu [0-9]*" | awk '{print $2}')
if [ "$MTU" = "1500" ]; then
    echo -e "${GREEN}✓ MTU设置正确: $MTU${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ MTU设置错误: $MTU (期望1500)${NC}"
    ((FAILED++))
fi

# 9. 检查MAC地址
echo -e "\n${YELLOW}9. 检查MAC地址${NC}"
MAC=$(ip link show mesh0 | grep -o "link/ether [0-9a-f:]*" | awk '{print $2}')
if [ -n "$MAC" ] && [ "$MAC" != "00:00:00:00:00:00" ]; then
    echo -e "${GREEN}✓ MAC地址有效: $MAC${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ MAC地址无效: $MAC${NC}"
    ((FAILED++))
fi

echo -e "\n=== 第三阶段：网络功能测试 ==="

# 10. 配置IP地址
echo -e "\n${YELLOW}10. 配置IP地址${NC}"
if ip addr add 192.168.1.100/24 dev mesh0 2>/dev/null; then
    echo -e "${GREEN}✓ IP地址配置成功${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ IP地址可能已存在${NC}"
    ((SKIPPED++))
fi

# 11. 检查IP地址
echo -e "\n${YELLOW}11. 检查IP地址${NC}"
if ip addr show mesh0 | grep -q "192.168.1.100"; then
    echo -e "${GREEN}✓ IP地址配置正确${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ IP地址配置失败${NC}"
    ((FAILED++))
fi

# 12. 测试本地回环
echo -e "\n${YELLOW}12. 测试本地回环${NC}"
if ping -c 1 -W 1 127.0.0.1 >/dev/null 2>&1; then
    echo -e "${GREEN}✓ 本地回环正常${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ 本地回环失败${NC}"
    ((FAILED++))
fi

# 13. 测试接口自身
echo -e "\n${YELLOW}13. 测试接口自身${NC}"
if ping -c 1 -W 1 192.168.1.100 >/dev/null 2>&1; then
    echo -e "${GREEN}✓ 接口自身可达${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ 接口自身不可达${NC}"
    ((FAILED++))
fi

echo -e "\n=== 第四阶段：驱动操作测试 ==="

# 14. 测试接口关闭
echo -e "\n${YELLOW}14. 测试接口关闭${NC}"
if ip link set mesh0 down; then
    echo -e "${GREEN}✓ 接口关闭成功${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ 接口关闭失败${NC}"
    ((FAILED++))
fi

# 15. 测试接口启用
echo -e "\n${YELLOW}15. 测试接口启用${NC}"
if ip link set mesh0 up; then
    echo -e "${GREEN}✓ 接口启用成功${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ 接口启用失败${NC}"
    ((FAILED++))
fi

# 16. 测试MAC地址修改
echo -e "\n${YELLOW}16. 测试MAC地址修改${NC}"
OLD_MAC=$(ip link show mesh0 | grep -o "link/ether [0-9a-f:]*" | awk '{print $2}')
if ip link set mesh0 address 00:11:22:33:44:55; then
    echo -e "${GREEN}✓ MAC地址修改成功${NC}"
    ((PASSED++))
    # 恢复原MAC地址
    ip link set mesh0 address "$OLD_MAC"
else
    echo -e "${RED}✗ MAC地址修改失败${NC}"
    ((FAILED++))
fi

echo -e "\n=== 第五阶段：清理和卸载测试 ==="

# 17. 清理IP地址
echo -e "\n${YELLOW}17. 清理IP地址${NC}"
if ip addr del 192.168.1.100/24 dev mesh0 2>/dev/null; then
    echo -e "${GREEN}✓ IP地址清理成功${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ IP地址清理失败或已不存在${NC}"
    ((SKIPPED++))
fi

# 18. 卸载驱动
echo -e "\n${YELLOW}18. 卸载驱动${NC}"
if rmmod mesh_net_driver; then
    echo -e "${GREEN}✓ 驱动卸载成功${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ 驱动卸载失败${NC}"
    ((FAILED++))
fi

# 19. 验证卸载
echo -e "\n${YELLOW}19. 验证卸载${NC}"
if ! lsmod | grep -q mesh; then
    echo -e "${GREEN}✓ 驱动已完全卸载${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ 驱动未完全卸载${NC}"
    ((FAILED++))
fi

# 20. 检查接口是否消失
echo -e "\n${YELLOW}20. 检查接口是否消失${NC}"
if ! ip link show | grep -q mesh; then
    echo -e "${GREEN}✓ mesh接口已消失${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ mesh接口仍然存在${NC}"
    ((FAILED++))
fi

echo -e "\n=== 测试结果汇总 ==="
echo -e "${GREEN}通过: $PASSED${NC}"
echo -e "${RED}失败: $FAILED${NC}"
echo -e "${YELLOW}跳过: $SKIPPED${NC}"
echo -e "总计: $((PASSED + FAILED + SKIPPED))"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 所有测试通过！驱动功能完整！${NC}"
else
    echo -e "\n${RED}⚠ 有 $FAILED 个测试失败，需要进一步检查${NC}"
fi

echo -e "\n=== 建议的后续测试 ==="
echo "1. 运行您的测试程序: ./test_mesh_net"
echo "2. 测试网络性能: iperf3, netperf"
echo "3. 测试数据包捕获: tcpdump"
echo "4. 测试网络工具: netstat, ss, ethtool"
echo "5. 压力测试: 大量数据包发送/接收"
