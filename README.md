# 915MHz 自组网 Linux 网卡驱动

这是一个为915MHz自组网系统开发的Linux网卡驱动，支持12个节点，数据速率700kbps。

## 功能特性

- 915MHz频点支持
- 支持最多12个节点
- 700kbps数据速率
- 自组网功能
- 节点发现和管理
- 实时网络统计

## 文件结构

```
.
├── Makefile              # 编译脚本
├── mesh_net_driver.c     # 主要驱动代码
├── mesh_net_driver.h     # 驱动头文件
├── mesh_net_hw.c         # 硬件抽象层
├── mesh_net_hw.h         # 硬件抽象层头文件
├── mesh_net.dts          # 设备树文件
├── test_mesh_net.c       # 测试程序
└── README.md             # 说明文档
```

## 编译和安装

### 1. 编译驱动

```bash
make
```

### 2. 安装驱动

```bash
sudo make install
```

### 3. 加载驱动

```bash
sudo modprobe mesh_net_driver
```

### 4. 编译测试程序

```bash
gcc -o test_mesh_net test_mesh_net.c
```

## 使用方法

### 1. 检查驱动状态

```bash
dmesg | grep mesh
```

### 2. 查看网络接口

```bash
ip link show
```

### 3. 启用网络接口

```bash
sudo ip link set mesh0 up
```

### 4. 配置IP地址

```bash
sudo ip addr add 192.168.1.100/24 dev mesh0
```

### 5. 运行测试程序

```bash
sudo ./test_mesh_net
```

## 硬件要求

- 支持915MHz的RF收发器
- GPIO接口用于复位和中断
- 内存映射寄存器接口
- 时钟和电源管理

## 设备树配置

在设备树中添加以下节点：

```dts
mesh_net: mesh-network@40000000 {
    compatible = "mesh,network";
    reg = <0x40000000 0x1000>;
    interrupts = <0 32 4>;
    reset-gpios = <&gpio0 12 0>;
    irq-gpios = <&gpio0 13 0>;
    frequency = <915000000>;
    data-rate = <700000>;
    tx-power = <20>;
    rx-gain = <30>;
    status = "okay";
};
```

## 故障排除

### 1. 驱动加载失败

检查内核日志：
```bash
dmesg | tail -20
```

### 2. 硬件未检测到

检查设备树是否正确加载：
```bash
ls /proc/device-tree/
```

### 3. 网络接口未创建

检查驱动是否正确注册：
```bash
lsmod | grep mesh
```

## 开发说明

### 1. 添加新功能

- 在 `mesh_net_driver.c` 中添加新的网络功能
- 在 `mesh_net_hw.c` 中添加硬件相关代码
- 更新头文件中的接口定义

### 2. 调试

启用调试输出：
```bash
echo 8 > /proc/sys/kernel/printk
```

### 3. 性能优化

- 调整工作队列参数
- 优化中断处理
- 使用DMA传输

## 许可证

GPL v2

## 作者

[您的姓名]

## 版本历史

- v1.0.0 - 初始版本，支持基本的915MHz自组网功能


