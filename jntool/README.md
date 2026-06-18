# JNTool Flutter 应用

这里是 JNTool 的 Flutter 桌面应用源码。应用把 JSON、Curl、Java Bean 等开发辅助工具集中在一个桌面窗口中，当前支持 Windows 与 macOS。

## 模块说明

- `lib/app.dart`：应用入口与工具注册。
- `lib/screens/`：主界面与工具页面容器。
- `lib/tools/bean_tool/`：JSON 与 Java Bean 双向转换工具。
- `lib/tools/curl_tool/`：curl 命令解析工具。
- `lib/tools/json_tool/`：JSON 格式化与查看工具。
- `lib/widgets/`：侧边栏、工具卡片、玻璃容器等通用组件。
- `lib/utils/constants.dart`：颜色、间距、字体和阴影等设计常量。

## 开发环境

- Flutter SDK 3.0 或更高版本
- Dart SDK 随 Flutter 提供
- Windows 桌面构建需要 Visual Studio 2022 Build Tools 与 C++ 桌面开发工作负载
- macOS 桌面构建需要 Xcode

## 常用命令

安装依赖：

```bash
flutter pub get
```

运行 Windows 桌面端：

```bash
flutter run -d windows
```

运行 macOS 桌面端：

```bash
flutter run -d macos
```

运行测试：

```bash
flutter test
```

静态检查：

```bash
flutter analyze
```

构建 Windows 应用：

```bash
flutter build windows
```

构建 Windows 安装包需在 Windows 主机执行，并安装 Inno Setup 6：

```powershell
.\installer\windows\build_windows_installer.ps1
```

安装包输出到：`dist\windows\JNToolSetup-1.0.0.exe`

构建 macOS 应用：

```bash
flutter build macos
```

## JavaBean 工具

JavaBean 工具支持两种方向：

- JSON 转 Java Bean：根据 JSON 字段推断 Java 类型，支持包名、类名、Lombok、Jackson、驼峰命名和字段注释配置。
- Java Bean 转 JSON：从 `private Type name;` 字段声明中提取字段，并生成示例 JSON。

该工具偏向轻量代码生成，不替代完整的 Java AST 解析器。复杂泛型、继承层级和注解语义目前不作为解析目标。

## 提交前检查

建议在提交前至少运行：

```bash
flutter analyze
flutter test
```
