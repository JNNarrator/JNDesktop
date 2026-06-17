# JNTool

JNTool 是一款基于 Flutter 构建的 macOS 桌面开发工具应用，旨在为开发者提供便捷的代码生成和数据处理功能。

## 功能特点

- **Bean 生成器**：快速生成 Java/Flutter Bean 类及配置面板
- **Curl 工具**：解析 curl 命令，支持 HTTP 请求模拟与调试
- **JSON 工具**：JSON 数据解析、格式化和树形可视化展示

## 技术栈

- **框架**：Flutter 3.x
- **平台**：macOS
- **状态管理**：Provider
- **编程语言**：Dart

## 项目结构

```
jntool/
├── lib/
│   ├── app.dart              # 应用入口
│   ├── main.dart             # 主函数
│   ├── models/               # 数据模型
│   ├── providers/           # 状态管理
│   ├── screens/              # 页面屏幕
│   ├── tools/                # 工具模块
│   │   ├── bean_tool/        # Bean 生成工具
│   │   ├── curl_tool/        # Curl 解析工具
│   │   └── json_tool/        # JSON 处理工具
│   ├── utils/                # 工具类
│   └── widgets/              # 公共组件
├── macos/                    # macOS 原生配置
├── test/                     # 单元测试
└── pubspec.yaml              # 依赖配置
```

## 快速开始

### 环境要求

- Flutter SDK (>=3.0.0)
- macOS 10.14+

### 安装依赖

```bash
cd jntool
flutter pub get
```

### 运行项目

```bash
flutter run -d macos
```

### 构建应用

```bash
flutter build macos
```

## 功能说明

### Bean 生成工具

提供可视化的 Bean 类配置面板，支持自定义字段类型、注解等，生成标准化的代码模板。

### Curl 工具

- 解析 curl 命令字符串
- 转换为 HTTP 请求配置
- 支持多种 HTTP 方法和请求头设置

### JSON 工具

- JSON 格式化与压缩
- 树形结构可视化
- JSON 与 Dart Model 互转

## 贡献指南

欢迎提交 Issue 和 Pull Request。请确保提交前运行测试：

```bash
flutter test
```

## 许可证

本项目基于 MIT 许可证开源。