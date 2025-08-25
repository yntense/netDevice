#ifndef MESH_NET_DRIVER_H
#define MESH_NET_DRIVER_H

#include "../include/mesh_net_common.h"
#include <linux/platform_device.h>
#include <linux/mutex.h>
#include <linux/workqueue.h>
#include <linux/timer.h>

// 网卡私有数据结构
struct mesh_net_priv {
    struct net_device *ndev;
    struct net_device_stats stats;
    struct mutex lock;
    struct workqueue_struct *workqueue;
    struct work_struct tx_work;
    struct work_struct rx_work;
    struct timer_list beacon_timer;
    
    // 自组网相关参数
    u32 node_id;
    u32 frequency;
    u32 data_rate;
    u8 channel;
    u8 tx_power;
    
    // 节点管理
    struct {
        u32 node_id;
        u32 last_seen;
        u8 signal_strength;
        u8 link_quality;
    } nodes[MAX_NODES];
    
    // 硬件接口
    void __iomem *reg_base;
    int irq;
    struct platform_device *pdev;
    
    // 统计信息
    u32 tx_packets;
    u32 rx_packets;
    u32 tx_errors;
    u32 rx_errors;
    u32 collisions;
};

// 前向声明
int mesh_net_init(struct net_device *dev);
void mesh_net_cleanup(struct net_device *dev);

#endif // MESH_NET_DRIVER_H


