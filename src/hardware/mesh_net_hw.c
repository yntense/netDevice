#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/delay.h>
#include <linux/spi/spi.h>
#include <linux/i2c.h>
#include <linux/gpio.h>
#include <linux/interrupt.h>
#include <linux/irq.h>
#include <linux/of.h>
#include <linux/of_gpio.h>
#include <linux/of_irq.h>
#include <linux/platform_device.h>
#include <linux/regulator/consumer.h>
#include <linux/clk.h>
#include "mesh_net_hw.h"

// 硬件寄存器定义
#define MESH_REG_CONTROL      0x00
#define MESH_REG_STATUS       0x01
#define MESH_REG_FREQ_LOW     0x02
#define MESH_REG_FREQ_HIGH    0x03
#define MESH_REG_DATA_RATE    0x04
#define MESH_REG_TX_POWER     0x05
#define MESH_REG_RX_GAIN      0x06
#define MESH_REG_FIFO_DATA    0x07
#define MESH_REG_FIFO_STATUS  0x08
#define MESH_REG_IRQ_STATUS   0x09
#define MESH_REG_IRQ_MASK     0x0A

// 控制寄存器位定义
#define MESH_CTRL_ENABLE      0x01
#define MESH_CTRL_TX_EN       0x02
#define MESH_CTRL_RX_EN       0x04
#define MESH_CTRL_RESET       0x08
#define MESH_CTRL_SLEEP       0x10

// 状态寄存器位定义
#define MESH_STATUS_READY     0x01
#define MESH_STATUS_TX_BUSY   0x02
#define MESH_STATUS_RX_BUSY   0x04
#define MESH_STATUS_FIFO_FULL 0x08
#define MESH_STATUS_FIFO_EMPTY 0x10

// 硬件抽象结构
struct mesh_hw {
    struct platform_device *pdev;
    void __iomem *reg_base;
    struct clk *clk;
    struct regulator *vdd;
    int reset_gpio;
    int irq_gpio;
    int irq;
    struct mutex lock;
    bool initialized;
};

// 全局硬件实例
static struct mesh_hw *g_mesh_hw = NULL;

// 硬件初始化
int mesh_hw_init(struct platform_device *pdev)
{
    struct mesh_hw *hw;
    struct resource *res;
    int err;
    
    hw = devm_kzalloc(&pdev->dev, sizeof(*hw), GFP_KERNEL);
    if (!hw)
        return -ENOMEM;
    
    hw->pdev = pdev;
    mutex_init(&hw->lock);
    
    // 获取寄存器基地址
    res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    if (!res) {
        dev_err(&pdev->dev, "No memory resource\n");
        return -ENODEV;
    }
    
    hw->reg_base = devm_ioremap_resource(&pdev->dev, res);
    if (IS_ERR(hw->reg_base)) {
        dev_err(&pdev->dev, "Failed to map registers\n");
        return PTR_ERR(hw->reg_base);
    }
    
    // 获取时钟
    hw->clk = devm_clk_get(&pdev->dev, NULL);
    if (IS_ERR(hw->clk)) {
        dev_err(&pdev->dev, "Failed to get clock\n");
        return PTR_ERR(hw->clk);
    }
    
    // 获取电源
    hw->vdd = devm_regulator_get(&pdev->dev, "vdd");
    if (IS_ERR(hw->vdd)) {
        dev_err(&pdev->dev, "Failed to get regulator\n");
        return PTR_ERR(hw->vdd);
    }
    
    // 获取GPIO
    hw->reset_gpio = of_get_named_gpio(pdev->dev.of_node, "reset-gpios", 0);
    if (hw->reset_gpio < 0) {
        dev_err(&pdev->dev, "No reset GPIO\n");
        return -ENODEV;
    }
    
    hw->irq_gpio = of_get_named_gpio(pdev->dev.of_node, "irq-gpios", 0);
    if (hw->irq_gpio < 0) {
        dev_err(&pdev->dev, "No IRQ GPIO\n");
        return -ENODEV;
    }
    
    // 配置GPIO
    err = devm_gpio_request_one(&pdev->dev, hw->reset_gpio, GPIOF_OUT_INIT_LOW, "mesh_reset");
    if (err) {
        dev_err(&pdev->dev, "Failed to request reset GPIO\n");
        return err;
    }
    
    err = devm_gpio_request_one(&pdev->dev, hw->irq_gpio, GPIOF_IN, "mesh_irq");
    if (err) {
        dev_err(&pdev->dev, "Failed to request IRQ GPIO\n");
        return err;
    }
    
    // 获取IRQ
    hw->irq = gpio_to_irq(hw->irq_gpio);
    if (hw->irq < 0) {
        dev_err(&pdev->dev, "Failed to get IRQ\n");
        return hw->irq;
    }
    
    // 启用电源和时钟
    err = regulator_enable(hw->vdd);
    if (err) {
        dev_err(&pdev->dev, "Failed to enable regulator\n");
        return err;
    }
    
    err = clk_prepare_enable(hw->clk);
    if (err) {
        dev_err(&pdev->dev, "Failed to enable clock\n");
        return err;
    }
    
    // 硬件复位
    gpio_set_value(hw->reset_gpio, 0);
    udelay(1000);
    gpio_set_value(hw->reset_gpio, 1);
    udelay(1000);
    
    // 配置915MHz频率
    err = mesh_hw_set_frequency(915000000);
    if (err) {
        dev_err(&pdev->dev, "Failed to set frequency\n");
        return err;
    }
    
    // 配置700kbps数据速率
    err = mesh_hw_set_data_rate(700000);
    if (err) {
        dev_err(&pdev->dev, "Failed to set data rate\n");
        return err;
    }
    
    // 配置发射功率
    err = mesh_hw_set_tx_power(20); // 20 dBm
    if (err) {
        dev_err(&pdev->dev, "Failed to set TX power\n");
        return err;
    }
    
    // 配置接收增益
    err = mesh_hw_set_rx_gain(30); // 30 dB
    if (err) {
        dev_err(&pdev->dev, "Failed to set RX gain\n");
        return err;
    }
    
    g_mesh_hw = hw;
    hw->initialized = true;
    
    dev_info(&pdev->dev, "Mesh hardware initialized successfully\n");
    
    return 0;
}

// 硬件清理
void mesh_hw_cleanup(void)
{
    struct mesh_hw *hw = g_mesh_hw;
    
    if (!hw || !hw->initialized)
        return;
    
    // 禁用硬件
    mesh_hw_disable();
    
    // 关闭时钟和电源
    if (hw->clk)
        clk_disable_unprepare(hw->clk);
    
    if (hw->vdd)
        regulator_disable(hw->vdd);
    
    hw->initialized = false;
    g_mesh_hw = NULL;
}

// 设置频率
int mesh_hw_set_frequency(u32 freq)
{
    struct mesh_hw *hw = g_mesh_hw;
    u32 freq_reg;
    
    if (!hw || !hw->initialized)
        return -ENODEV;
    
    mutex_lock(&hw->lock);
    
    // 将频率转换为寄存器值 (假设时钟为100MHz)
    freq_reg = (freq * 1000) / 100000000;
    
    // 写入频率寄存器
    iowrite8(freq_reg & 0xFF, hw->reg_base + MESH_REG_FREQ_LOW);
    iowrite8((freq_reg >> 8) & 0xFF, hw->reg_base + MESH_REG_FREQ_HIGH);
    
    mutex_unlock(&hw->lock);
    
    dev_dbg(&hw->pdev->dev, "Set frequency to %u Hz (reg: 0x%04x)\n", freq, freq_reg);
    
    return 0;
}

// 设置数据速率
int mesh_hw_set_data_rate(u32 rate)
{
    struct mesh_hw *hw = g_mesh_hw;
    u32 rate_reg;
    
    if (!hw || !hw->initialized)
        return -ENODEV;
    
    mutex_lock(&hw->lock);
    
    // 将数据速率转换为寄存器值
    rate_reg = rate / 1000; // 转换为kbps
    
    iowrite8(rate_reg & 0xFF, hw->reg_base + MESH_REG_DATA_RATE);
    
    mutex_unlock(&hw->lock);
    
    dev_dbg(&hw->pdev->dev, "Set data rate to %u bps (reg: 0x%02x)\n", rate, rate_reg);
    
    return 0;
}

// 设置发射功率
int mesh_hw_set_tx_power(u8 power_dbm)
{
    struct mesh_hw *hw = g_mesh_hw;
    
    if (!hw || !hw->initialized)
        return -ENODEV;
    
    mutex_lock(&hw->lock);
    
    iowrite8(power_dbm, hw->reg_base + MESH_REG_TX_POWER);
    
    mutex_unlock(&hw->lock);
    
    dev_dbg(&hw->pdev->dev, "Set TX power to %u dBm\n", power_dbm);
    
    return 0;
}

// 设置接收增益
int mesh_hw_set_rx_gain(u8 gain_db)
{
    struct mesh_hw *hw = g_mesh_hw;
    
    if (!hw || !hw->initialized)
        return -ENODEV;
    
    mutex_lock(&hw->lock);
    
    iowrite8(gain_db, hw->reg_base + MESH_REG_RX_GAIN);
    
    mutex_unlock(&hw->lock);
    
    dev_dbg(&hw->pdev->dev, "Set RX gain to %u dB\n", gain_db);
    
    return 0;
}

// 启用硬件
int mesh_hw_enable(void)
{
    struct mesh_hw *hw = g_mesh_hw;
    
    if (!hw || !hw->initialized)
        return -ENODEV;
    
    mutex_lock(&hw->lock);
    
    // 启用硬件
    iowrite8(MESH_CTRL_ENABLE, hw->reg_base + MESH_REG_CONTROL);
    
    mutex_unlock(&hw->lock);
    
    dev_dbg(&hw->pdev->dev, "Hardware enabled\n");
    
    return 0;
}

// 禁用硬件
int mesh_hw_disable(void)
{
    struct mesh_hw *hw = g_mesh_hw;
    
    if (!hw || !hw->initialized)
        return -ENODEV;
    
    mutex_lock(&hw->lock);
    
    // 禁用硬件
    iowrite8(0, hw->reg_base + MESH_REG_CONTROL);
    
    mutex_unlock(&hw->lock);
    
    dev_dbg(&hw->pdev->dev, "Hardware disabled\n");
    
    return 0;
}

// 发送数据
int mesh_hw_tx_data(const u8 *data, u32 len)
{
    struct mesh_hw *hw = g_mesh_hw;
    u32 i;
    u8 status;
    
    if (!hw || !hw->initialized)
        return -ENODEV;
    
    if (len == 0 || len > 255)
        return -EINVAL;
    
    mutex_lock(&hw->lock);
    
    // 等待发送器空闲
    for (i = 0; i < 1000; i++) {
        status = ioread8(hw->reg_base + MESH_REG_STATUS);
        if (!(status & MESH_STATUS_TX_BUSY))
            break;
        udelay(100);
    }
    
    if (i >= 1000) {
        mutex_unlock(&hw->lock);
        return -EBUSY;
    }
    
    // 启用发送
    iowrite8(MESH_CTRL_TX_EN, hw->reg_base + MESH_REG_CONTROL);
    
    // 写入数据长度
    iowrite8(len, hw->reg_base + MESH_REG_FIFO_DATA);
    
    // 写入数据
    for (i = 0; i < len; i++) {
        iowrite8(data[i], hw->reg_base + MESH_REG_FIFO_DATA);
    }
    
    // 等待发送完成
    for (i = 0; i < 10000; i++) {
        status = ioread8(hw->reg_base + MESH_REG_STATUS);
        if (!(status & MESH_STATUS_TX_BUSY))
            break;
        udelay(100);
    }
    
    // 禁用发送
    iowrite8(0, hw->reg_base + MESH_REG_CONTROL);
    
    mutex_unlock(&hw->lock);
    
    if (i >= 10000) {
        dev_err(&hw->pdev->dev, "TX timeout\n");
        return -ETIMEDOUT;
    }
    
    dev_dbg(&hw->pdev->dev, "TX completed: %u bytes\n", len);
    
    return 0;
}

// 接收数据
int mesh_hw_rx_data(u8 *data, u32 *len)
{
    struct mesh_hw *hw = g_mesh_hw;
    u8 status;
    u32 i;
    
    if (!hw || !hw->initialized)
        return -ENODEV;
    
    mutex_lock(&hw->lock);
    
    // 检查接收状态
    status = ioread8(hw->reg_base + MESH_REG_STATUS);
    if (status & MESH_STATUS_FIFO_EMPTY) {
        mutex_unlock(&hw->lock);
        return -ENODATA;
    }
    
    // 启用接收
    iowrite8(MESH_CTRL_RX_EN, hw->reg_base + MESH_REG_CONTROL);
    
    // 读取数据长度
    *len = ioread8(hw->reg_base + MESH_REG_FIFO_DATA);
    
    if (*len > 255) {
        mutex_unlock(&hw->lock);
        return -EINVAL;
    }
    
    // 读取数据
    for (i = 0; i < *len; i++) {
        data[i] = ioread8(hw->reg_base + MESH_REG_FIFO_DATA);
    }
    
    // 禁用接收
    iowrite8(0, hw->reg_base + MESH_REG_CONTROL);
    
    mutex_unlock(&hw->lock);
    
    dev_dbg(&hw->pdev->dev, "RX completed: %u bytes\n", *len);
    
    return 0;
}

// 获取硬件状态
u8 mesh_hw_get_status(void)
{
    struct mesh_hw *hw = g_mesh_hw;
    
    if (!hw || !hw->initialized)
        return 0;
    
    return ioread8(hw->reg_base + MESH_REG_STATUS);
}

// 检查硬件是否就绪
bool mesh_hw_is_ready(void)
{
    struct mesh_hw *hw = g_mesh_hw;
    
    if (!hw || !hw->initialized)
        return false;
    
    return (mesh_hw_get_status() & MESH_STATUS_READY) != 0;
}

EXPORT_SYMBOL(mesh_hw_init);
EXPORT_SYMBOL(mesh_hw_cleanup);
EXPORT_SYMBOL(mesh_hw_set_frequency);
EXPORT_SYMBOL(mesh_hw_set_data_rate);
EXPORT_SYMBOL(mesh_hw_set_tx_power);
EXPORT_SYMBOL(mesh_hw_set_rx_gain);
EXPORT_SYMBOL(mesh_hw_enable);
EXPORT_SYMBOL(mesh_hw_disable);
EXPORT_SYMBOL(mesh_hw_tx_data);
EXPORT_SYMBOL(mesh_hw_rx_data);
EXPORT_SYMBOL(mesh_hw_get_status);
EXPORT_SYMBOL(mesh_hw_is_ready);
