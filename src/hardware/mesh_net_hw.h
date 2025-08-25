#ifndef MESH_NET_HW_H
#define MESH_NET_HW_H

#include "../include/mesh_net_common.h"

// 硬件初始化
int mesh_hw_init(struct platform_device *pdev);

// 硬件清理
void mesh_hw_cleanup(void);

// 设置频率 (Hz)
int mesh_hw_set_frequency(u32 freq);

// 设置数据速率 (bps)
int mesh_hw_set_data_rate(u32 rate);

// 设置发射功率 (dBm)
int mesh_hw_set_tx_power(u8 power_dbm);

// 设置接收增益 (dB)
int mesh_hw_set_rx_gain(u8 gain_db);

// 启用硬件
int mesh_hw_enable(void);

// 禁用硬件
int mesh_hw_disable(void);

// 发送数据
int mesh_hw_tx_data(const u8 *data, u32 len);

// 接收数据
int mesh_hw_rx_data(u8 *data, u32 *len);

// 获取硬件状态
u8 mesh_hw_get_status(void);

// 检查硬件是否就绪
bool mesh_hw_is_ready(void);

#endif // MESH_NET_HW_H
