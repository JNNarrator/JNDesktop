# JNTool

JNTool 是一款基于 Flutter 的桌面开发工具集，面向日常接口调试、数据整理和代码生成场景。项目目前支持 Windows 与 macOS 桌面端，核心体验是把常用的小工具集中在一个轻量应用里，减少开发过程中在网页、脚本和编辑器之间来回切换。

## 功能特性

- **JSON 工具**：提供 JSON 格式化、压缩、校验和树形结构查看能力。
- **Curl 请求**：解析 curl 命令，提取 URL、请求方法、请求头和请求体，并支持发起 HTTP 请求辅助接口调试。
- **Bean 转换**：支持 JSON 生成 Java Bean、Java Bean 生成示例 JSON，可配置类名、包名、Lombok 注解、Jackson 注解、驼峰命名和字段注释。
- **Cron 生成**：面向 Spring Boot cron 表达式，支持快捷生成和执行时间预览。
- **配置转换**：支持 Spring Boot YAML 与 properties 配置互相转换，并保留空字符串等边界值语义。
- **Base64 转换**：支持文本 / 图片与 Base64 互相转换，方便调试编码内容。
- **WebDAV 管理**：支持本地保存 WebDAV 连接、测试连接、浏览远端目录、上传下载、新建文件夹、删除资源，以及打开 UTF-8 文本文件后编辑保存。
- **桌面端体验**：使用 Flutter 构建，当前仓库已包含 Windows 与 macOS 平台工程。

## 技术栈

- Flutter 3.x
- Dart
- Provider
- Windows Desktop / macOS Desktop

## 快速开始

### 环境要求

- Flutter SDK 3.0 或更高版本
- Windows：Visual Studio 2022 Build Tools，并安装 **Desktop development with C++** 工作负载
- macOS：Xcode 与 macOS 桌面开发环境

### 安装依赖

```bash
cd jntool
flutter pub get
```

### 运行应用

Windows：

```bash
flutter run -d windows
```

macOS：

```bash
flutter run -d macos
```

### 构建应用

Windows：

```bash
flutter build windows
```

生成 Windows 安装包需在 Windows 主机执行，并安装 Inno Setup 6：

```powershell
cd jntool
.\installer\windows\build_windows_installer.ps1
```

安装包输出到：`jntool\dist\windows\JNToolSetup-1.0.0.exe`

也可以使用 GitHub Actions 云端 Windows 环境打包：打开 `Build Windows Installer` 工作流，点击 `Run workflow`，完成后在 Artifacts 中下载 `JNToolSetup-1.0.0`。

macOS：

```bash
flutter build macos
```

## 项目结构

```text
jndesktop/
├── jntool/
│   ├── lib/
│   │   ├── app.dart
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   ├── tools/
│   │   │   ├── base64_tool/
│   │   │   ├── bean_tool/
│   │   │   ├── config_tool/
│   │   │   ├── cron_tool/
│   │   │   ├── curl_tool/
│   │   │   ├── json_tool/
│   │   │   └── webdav_tool/
│   │   ├── utils/
│   │   └── widgets/
│   ├── macos/
│   ├── windows/
│   ├── test/
│   └── pubspec.yaml
├── README.md
└── README.en.md
```

## 开发检查

提交前建议执行：

```bash
cd jntool
flutter analyze
flutter test
```

如需验证 Windows 桌面构建：

```bash
flutter build windows
```

## 许可

本项目使用 MIT License 开源。
