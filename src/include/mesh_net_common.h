#ifndef MESH_NET_COMMON_H
#define MESH_NET_COMMON_H

#include <linux/types.h>
#include <linux/netdevice.h>

// 驱动版本和名称
#define DRIVER_NAME "mesh_net_driver"
#define DRIVER_VERSION "1.0.0"

// 网络参数
#define MAX_NODES 12
#define FREQ_915MHZ 915000000
#define DATA_RATE 700000  // 700 kbps

// 默认配置
#define DEFAULT_MTU 1500
#define DEFAULT_TX_POWER 20  // dBm
#define DEFAULT_RX_GAIN 30   // dB

// 错误代码
#define MESH_NET_SUCCESS 0
#define MESH_NET_ERROR -1
#define MESH_NET_INVALID_PARAM -2
#define MESH_NET_NO_MEMORY -3

// 调试宏
#ifdef DEBUG
#define MESH_DEBUG(fmt, ...) pr_debug("mesh: " fmt, ##__VA_ARGS__)
#else
#define MESH_DEBUG(fmt, ...) do {} while (0)
#endif

#define MESH_INFO(fmt, ...) pr_info("mesh: " fmt, ##__VA_ARGS__)
#define MESH_ERR(fmt, ...) pr_err("mesh: " fmt, ##__VA_ARGS__)
#define MESH_WARN(fmt, ...) pr_warn("mesh: " fmt, ##__VA_ARGS__)

#endif // MESH_NET_COMMON_H
