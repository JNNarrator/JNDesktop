<proposed_plan>
# JNTool macOS 开发工具应用搭建计划

## Summary
- 目标：基于 Flutter 构建面向 macOS 的开发者工具聚合应用。
- 优先完成可运行骨架与开发工具扩展点，后续功能在 `plan.md` 中约定最小可用集。
- UI 采用现代可爱风格：柔和渐变、圆角卡片、毛玻璃效果、微动效、Emoji 点缀。
- 代码要求：中文注释、结构清晰、具备基础日志/错误边界与可测试分层。

## Key Changes / Implementation Changes

1. 项目初始化与 macOS 专项配置
- 确认 `jntool/` 为 Flutter 项目根目录，保持默认模板文件不变。
- 配置 `macos/Runner/DebugProfile.entitlements` 与 `Release.entitlements`，启用基础开发工具权限预留。
- 在 `macos/Runner/Info.plist` 中补充应用基础元数据与类别标识。

2. 目录与模块结构
- 新增应用分层目录：
  - `lib/src/core/`：日志、异常、常量、工具类。
  - `lib/src/ui/`：页面、组件、主题、动效。
  - `lib/src/features/`：各功能模块，预留“工具插件”目录。
  - `lib/src/routing/`：路由与导航逻辑。
- 新增 macOS 原生桥接目录：`macos/Classes/`。

3. 核心运行时与主题
- 新建 `AppTheme`：柔彩渐变 + 圆角 + 毛玻璃材质 + 微动效开关。
- 新建 `AppRouter`：支持侧边栏/多视图导航。
- 引入基础异常包装与 `Logger`，所有关键逻辑带中文注释。

4. 开发工具基础功能（最小可用集）
- “JSON 格式化”：输入校验、压缩/美化、错误提示。
- “Base64 编解码”：文本/文件支持（v1 先做文本）。
- “时间戳转换”：秒/毫秒、UTC/本地、一键复制。
- “正则测试”：实时匹配、高亮分组。

5. 交互与可测试性
- 所有工具页面遵循统一 `ToolScaffold`，减少重复样式与逻辑。
- 输入校验、边界条件（空值、超长文本、非法格式）全部单独处理。
- 建立基础 widget 单测与至少一个工具逻辑单测。

## Test Plan

1. 单元测试
- `test/logger_test.dart`：验证日志级别过滤。
- `test/features/timestamp/timestamp_converter_test.dart`：覆盖秒/毫秒、越界、非法输入。

2. 集成/运行验证
- `flutter analyze` 通过。
- macOS 构建：`flutter build macos --release` 可成功生成应用。
- 启动应用后侧边栏导航正常，最小功能集可交互。

## Assumptions
- 用户后续功能扩展会在 `lib/src/features/` 下按约定目录新增，避免散落。
- 开发优先保证可运行与可扩展，初期不做通用插件化架构，仅做清晰的模块化预留。
- UI 默认采用中文界面；文案可后续按需调整。
- 若用户未提供图标资源，先使用系统字体 Emoji 作为功能图标。

## 变更记录
- v1：初始化计划，定义目录结构、最小功能集、测试目标与 UI 规范。
</proposed_plan>
