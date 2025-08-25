# Mesh Network Driver 配置文件

# 编译选项
EXTRA_CFLAGS += -DDEBUG
EXTRA_CFLAGS += -DMESH_NET_DEBUG
EXTRA_CFLAGS += -Wall -Wextra

# 内核版本检查
KERNEL_VERSION := $(shell uname -r)
KERNEL_MAJOR := $(shell echo $(KERNEL_VERSION) | cut -d. -f1)
KERNEL_MINOR := $(shell echo $(KERNEL_VERSION) | cut -d. -f2)

# 根据内核版本调整编译选项
ifeq ($(shell test $(KERNEL_MAJOR) -ge 5; echo $$?),0)
    # 内核 5.x 及以上版本
    EXTRA_CFLAGS += -DKERNEL_5_PLUS
else
    # 内核 4.x 版本
    EXTRA_CFLAGS += -DKERNEL_4_X
endif

# 架构相关选项
ARCH := $(shell uname -m)
ifeq ($(ARCH),x86_64)
    EXTRA_CFLAGS += -DARCH_X86_64
else ifeq ($(ARCH),aarch64)
    EXTRA_CFLAGS += -DARCH_ARM64
else ifeq ($(ARCH),arm)
    EXTRA_CFLAGS += -DARCH_ARM
endif

# 调试选项
ifdef DEBUG
    EXTRA_CFLAGS += -g -O0
    EXTRA_CFLAGS += -DMESH_NET_VERBOSE_DEBUG
else
    EXTRA_CFLAGS += -O2
endif

# 性能选项
ifdef PERFORMANCE
    EXTRA_CFLAGS += -O3 -march=native
    EXTRA_CFLAGS += -DMESH_NET_PERFORMANCE
endif
