# Mesh Network Driver Makefile
# 支持新的目录结构

# 配置
DRIVER_NAME := mesh_net_driver
KERNEL_DIR ?= /lib/modules/$(shell uname -r)/build
PWD := $(shell pwd)
BUILD_DIR := build
SRC_DIR := src

# 默认目标
all: compile move_files

# 编译目标
compile:
	$(MAKE) -C $(KERNEL_DIR) M=$(PWD) modules

# 移动编译文件到build目录
move_files: compile
	@echo "移动编译文件到 $(BUILD_DIR) 目录..."
	@mkdir -p $(BUILD_DIR)
	@if [ -f "$(DRIVER_NAME).ko" ]; then \
		mv -f $(DRIVER_NAME).ko $(BUILD_DIR)/ 2>/dev/null || true; \
	fi
	@if [ -f "$(DRIVER_NAME).o" ]; then \
		mv -f $(DRIVER_NAME).o $(BUILD_DIR)/ 2>/dev/null || true; \
	fi
	@if [ -f "$(DRIVER_NAME).mod" ]; then \
		mv -f $(DRIVER_NAME).mod $(BUILD_DIR)/ 2>/dev/null || true; \
	fi
	@if [ -f "$(DRIVER_NAME).mod.c" ]; then \
		mv -f $(DRIVER_NAME).mod.c $(BUILD_DIR)/ 2>/dev/null || true; \
	fi
	@if [ -f "$(DRIVER_NAME).mod.o" ]; then \
		mv -f $(DRIVER_NAME).mod.o $(BUILD_DIR)/ 2>/dev/null || true; \
	fi
	@if [ -f "modules.order" ]; then \
		mv -f modules.order $(BUILD_DIR)/ 2>/dev/null || true; \
	fi
	@if [ -f "Module.symvers" ]; then \
		mv -f Module.symvers $(BUILD_DIR)/ 2>/dev/null || true; \
	fi
	@if [ -f ".$(DRIVER_NAME).ko.cmd" ]; then \
		mv -f .$(DRIVER_NAME).ko.cmd $(BUILD_DIR)/ 2>/dev/null || true; \
	fi
	@if [ -f ".$(DRIVER_NAME).o.cmd" ]; then \
		mv -f .$(DRIVER_NAME).o.cmd $(BUILD_DIR)/ 2>/dev/null || true; \
	fi
	@if [ -f ".$(DRIVER_NAME).mod.cmd" ]; then \
		mv -f .$(DRIVER_NAME).mod.cmd $(BUILD_DIR)/ 2>/dev/null || true; \
	fi
	@if [ -f ".$(DRIVER_NAME).mod.o.cmd" ]; then \
		mv -f .$(DRIVER_NAME).mod.o.cmd $(BUILD_DIR)/ 2>/dev/null || true; \
	fi
	@if [ -f ".modules.order.cmd" ]; then \
		mv -f .modules.order.cmd $(BUILD_DIR)/ 2>/dev/null || true; \
	fi
	@if [ -f ".Module.symvers.cmd" ]; then \
		mv -f .Module.symvers.cmd $(BUILD_DIR)/ 2>/dev/null || true; \
	fi
	@echo "文件移动完成！"

# 创建构建目录
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# 清理
clean:
	$(MAKE) -C $(KERNEL_DIR) M=$(PWD) clean
	rm -rf $(BUILD_DIR)

# 安装
install: all
	$(MAKE) -C $(KERNEL_DIR) M=$(PWD) modules_install
	depmod -a

# 卸载
uninstall:
	rmmod $(DRIVER_NAME) || true
	rm -f /lib/modules/$(shell uname -r)/extra/$(DRIVER_NAME).ko

# 测试
test: all
	@echo "检查驱动状态..."
	@if lsmod | grep -q $(DRIVER_NAME); then \
		echo "驱动已加载，先卸载..." ; \
		rmmod $(DRIVER_NAME) 2>/dev/null || true ; \
		sleep 1 ; \
	fi
	@echo "加载驱动进行测试..."
	@if insmod $(BUILD_DIR)/$(DRIVER_NAME).ko; then \
		echo "✓ 驱动加载成功" ; \
	else \
		echo "✗ 驱动加载失败" ; \
		exit 1 ; \
	fi
	@echo "等待接口创建..."
	@sleep 2
	@echo "检查网络接口..."
	@if ip link show | grep -q mesh; then \
		echo "✓ mesh接口创建成功" ; \
		ip link show | grep mesh ; \
	else \
		echo "✗ mesh接口创建失败" ; \
		exit 1 ; \
	fi
	@echo "测试完成，卸载驱动..."
	@rmmod $(DRIVER_NAME) 2>/dev/null || true
	@echo "✓ 测试完成！"

# 开发模式（快速编译）
dev: clean all

# 帮助
help:
	@echo "可用的目标："
	@echo "  all         - 编译驱动并移动文件到build目录"
	@echo "  compile     - 仅编译驱动（不移动文件）"
	@echo "  move_files  - 移动编译文件到build目录"
	@echo "  clean       - 清理编译文件"
	@echo "  install     - 安装驱动"
	@echo "  uninstall   - 卸载驱动"
	@echo "  test        - 快速测试"
	@echo "  dev         - 开发模式（清理+编译）"
	@echo "  help        - 显示此帮助"

.PHONY: all compile move_files clean install uninstall test dev help
