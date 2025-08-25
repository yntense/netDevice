# Kbuild file for Mesh Network Driver

# 指定要编译的源文件
obj-m := mesh_net_driver.o

# 源文件列表
mesh_net_driver-objs := \
    src/core/mesh_net_driver.o \
    src/hardware/mesh_net_hw.o

# 包含路径
ccflags-y := -I$(src)/include

# 指定输出目录
# 注意：内核模块编译系统默认在当前目录生成文件
# 我们通过Makefile来控制文件移动
