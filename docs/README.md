# Mesh Network Driver 项目结构

## 目录结构

```
net_device/
├── src/                    # 源代码目录
│   ├── include/           # 公共头文件
│   │   └── mesh_net_common.h
│   ├── core/              # 核心驱动代码
│   │   ├── mesh_net_driver.c
│   │   └── mesh_net_driver.h
│   └── hardware/          # 硬件抽象层
│       ├── mesh_net_hw.c
│       └── mesh_net_hw.h
├── build/                  # 编译输出目录
│   ├── *.ko               # 内核模块文件
│   ├── *.o                # 目标文件
│   └── *.mod*             # 模块相关文件
├── examples/               # 示例代码
│   ├── test_mesh_net.c    # 测试程序
│   └── mesh_net.dts       # 设备树文件
├── utils/                  # 工具脚本
│   ├── install.sh         # 安装脚本
│   ├── test_driver.sh     # 测试脚本
│   └── ...
├── tests/                  # 测试目录
├── docs/                   # 文档目录
├── Makefile               # 主构建文件
├── Kbuild                 # 内核构建配置
├── config.mk              # 编译配置
└── README.md              # 项目说明
```

## 模块说明

### 核心模块 (src/core/)
- **mesh_net_driver.c**: 主要的网络驱动实现
- **mesh_net_driver.h**: 核心驱动的数据结构定义

### 硬件抽象层 (src/hardware/)
- **mesh_net_hw.c**: 硬件相关的操作实现
- **mesh_net_hw.h**: 硬件接口定义

### 公共头文件 (src/include/)
- **mesh_net_common.h**: 共享的常量、宏和类型定义

## 编译说明

### 基本编译
```bash
make                    # 编译驱动
make clean             # 清理编译文件
make install           # 安装驱动
make uninstall         # 卸载驱动
```

### 开发模式
```bash
make dev               # 清理+编译
make test              # 快速测试
make help              # 显示帮助
```

### 调试编译
```bash
make DEBUG=1           # 启用调试信息
make PERFORMANCE=1     # 启用性能优化
```

## 文件组织原则

1. **源码与编译分离**: 所有编译生成的文件都放在 `build/` 目录
2. **功能模块分离**: 按功能将源码分为核心、硬件等模块
3. **公共代码集中**: 共享的定义和常量放在 `include/` 目录
4. **工具脚本集中**: 所有脚本文件放在 `utils/` 目录
5. **示例代码集中**: 测试和示例代码放在 `examples/` 目录

## 开发工作流

1. 修改源码文件 (src/)
2. 运行 `make dev` 重新编译
3. 使用 `make test` 快速测试
4. 使用 `utils/` 中的脚本进行详细测试
5. 使用 `make install` 安装到系统

## 注意事项

- 编译前确保 `build/` 目录存在
- 修改头文件后需要重新编译所有依赖模块
- 使用 `make clean` 清理旧的编译文件
- 调试时使用 `DEBUG=1` 选项获取更多信息
