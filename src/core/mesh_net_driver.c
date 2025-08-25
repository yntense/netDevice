#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/netdevice.h>
#include <linux/etherdevice.h>
#include <linux/skbuff.h>
#include <linux/version.h>
#include <linux/random.h>

#define DRIVER_NAME "mesh_net_driver"
#define DRIVER_VERSION "1.0.0"
/* virtual-only build: no RF constants needed */

// 网卡私有数据结构
struct mesh_net_priv {
    struct net_device *ndev;
    struct net_device_stats stats;
    u32 node_id;
};

// 全局变量

// 前向声明
static int mesh_net_open(struct net_device *dev);
static int mesh_net_stop(struct net_device *dev);
static netdev_tx_t mesh_net_xmit(struct sk_buff *skb, struct net_device *dev);
static int mesh_net_set_mac_address(struct net_device *dev, void *addr);
/* no ioctl */

// 网卡操作函数集
static const struct net_device_ops mesh_net_ops = {
    .ndo_open = mesh_net_open,
    .ndo_stop = mesh_net_stop,
    .ndo_start_xmit = mesh_net_xmit,
    .ndo_set_mac_address = mesh_net_set_mac_address,
    .ndo_validate_addr = eth_validate_addr,
};

// 初始化网卡
static int mesh_net_init(struct net_device *dev)
{
    struct mesh_net_priv *priv;
    
    if (!dev) {
        pr_err("mesh: invalid net_device pointer\n");
        return -EINVAL;
    }
    
    priv = netdev_priv(dev);
    if (!priv) {
        pr_err("mesh: failed to get private data\n");
        return -ENOMEM;
    }
    
    memset(priv, 0, sizeof(*priv));
    priv->ndev = dev;
    priv->node_id = get_random_u32() & 0xFFFF;
    eth_random_addr(dev->dev_addr);
    
    // 安全地打印设备名称
    if (dev->name && strlen(dev->name) > 0) {
        pr_info("mesh: init netdev %s, node_id=0x%04x\n", dev->name, priv->node_id);
    } else {
        pr_info("mesh: init netdev (unnamed), node_id=0x%04x\n", priv->node_id);
    }
    
    return 0;
}

// 打开网卡
static int mesh_net_open(struct net_device *dev)
{
    if (!dev) {
        pr_err("mesh: invalid net_device pointer in open\n");
        return -EINVAL;
    }
    
    netif_start_queue(dev);
    pr_info("mesh: %s up\n", dev->name ? dev->name : "unnamed");
    return 0;
}

// 关闭网卡
static int mesh_net_stop(struct net_device *dev)
{
    if (!dev) {
        pr_err("mesh: invalid net_device pointer in stop\n");
        return -EINVAL;
    }
    
    netif_stop_queue(dev);
    pr_info("mesh: %s down\n", dev->name ? dev->name : "unnamed");
    return 0;
}

// 发送数据包
static netdev_tx_t mesh_net_xmit(struct sk_buff *skb, struct net_device *dev)
{
    struct mesh_net_priv *priv;
    
    if (!dev) {
        pr_err("mesh: invalid net_device pointer in xmit\n");
        return NETDEV_TX_OK;
    }
    
    if (unlikely(!skb)) {
        pr_err("mesh: null skb in xmit\n");
        return NETDEV_TX_OK;
    }
    
    priv = netdev_priv(dev);
    if (!priv) {
        pr_err("mesh: failed to get private data in xmit\n");
        dev_kfree_skb(skb);
        return NETDEV_TX_OK;
    }
    
    priv->stats.tx_packets++;
    priv->stats.tx_bytes += skb->len;
    pr_debug("mesh: xmit len=%u\n", skb->len);
    dev_kfree_skb(skb);
    return NETDEV_TX_OK;
}

/* 使用标准ether_setup后的ndo_get_stats64路径，移除旧API以减少兼容性风险 */



// 设置MAC地址
static int mesh_net_set_mac_address(struct net_device *dev, void *addr)
{
    struct sockaddr *sa;
    
    if (!dev) {
        pr_err("mesh: invalid net_device pointer in set_mac\n");
        return -EINVAL;
    }
    
    if (!addr) {
        pr_err("mesh: invalid address pointer in set_mac\n");
        return -EINVAL;
    }
    
    sa = addr;
    if (!is_valid_ether_addr(sa->sa_data)) {
        pr_err("mesh: invalid ethernet address\n");
        return -EADDRNOTAVAIL;
    }
    
    memcpy(dev->dev_addr, sa->sa_data, ETH_ALEN);
    pr_info("mesh: MAC address set to %02x:%02x:%02x:%02x:%02x:%02x\n",
            sa->sa_data[0], sa->sa_data[1], sa->sa_data[2],
            sa->sa_data[3], sa->sa_data[4], sa->sa_data[5]);
    
    return 0;
}



/* 平台驱动相关逻辑已移除（纯虚拟网卡模式） */

// 平台驱动结构
/* 平台驱动相关定义在安全虚拟模式下不注册 */

// 设备树匹配表
/* of_match_table 未使用 */

// 全局网络设备
static struct net_device *mesh_global_dev = NULL;
static bool create = false; // 是否在加载时创建网卡
module_param(create, bool, 0644);
MODULE_PARM_DESC(create, "Set to 1 to create virtual netdev on module load");

// 模块初始化
static int __init mesh_net_init_module(void)
{
    int err;
    
    pr_notice("mesh: loading driver version %s (create=%d)\n", DRIVER_VERSION, create);

    // if (!create) {
    //     pr_notice("mesh: skip netdev creation on load (set create=1 to enable)\n");
    //     return 0;
    // }
    
    // 创建虚拟网络设备（用于测试）
    mesh_global_dev = alloc_etherdev(sizeof(struct mesh_net_priv));
    if (!mesh_global_dev) {
        pr_err("Failed to allocate ethernet device\n");
        return -ENOMEM;
    }
    
    // 设置设备信息
    ether_setup(mesh_global_dev);
    mesh_global_dev->netdev_ops = &mesh_net_ops;
    mesh_global_dev->flags |= IFF_NOARP;
    mesh_global_dev->features |= NETIF_F_LLTX;
    // 不设置ethtool_ops，让内核使用默认值
    // mesh_global_dev->ethtool_ops = NULL;
    
    // 设置设备名称
    strcpy(mesh_global_dev->name, "mesh%d");
    
    // 初始化网卡
    err = mesh_net_init(mesh_global_dev);
    if (err) {
        pr_err("Failed to initialize mesh network driver\n");
        free_netdev(mesh_global_dev);
        mesh_global_dev = NULL;
        return err;
    }
    
    // 注册网络设备
    err = register_netdev(mesh_global_dev);
    if (err) {
        pr_err("Failed to register network device\n");
        free_netdev(mesh_global_dev);
        mesh_global_dev = NULL;
        return err;
    }
    
    pr_notice("mesh: registered netdev %s\n", mesh_global_dev->name);
    
    return 0;
}

// 模块清理
static void __exit mesh_net_exit_module(void)
{
    pr_notice("mesh: unloading driver\n");
    
    // 注销虚拟网络设备
    if (mesh_global_dev) {
        unregister_netdev(mesh_global_dev);
        free_netdev(mesh_global_dev);
        mesh_global_dev = NULL;
    }
    
    pr_notice("mesh: unloaded\n");
}

module_init(mesh_net_init_module);
module_exit(mesh_net_exit_module);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("915MHz Mesh Network Driver");
MODULE_VERSION(DRIVER_VERSION);
