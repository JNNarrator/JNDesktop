# WebDAV Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 JNTool 中新增一个可保存本地连接、测试连接、浏览和编辑 WebDAV 文件的桌面工具。

**Architecture:** 将 WebDAV 功能拆成模型、本地存储、网络客户端和 Flutter 三栏页面。模型与客户端保持可测试，页面沿用现有毛玻璃工具页风格和 `IndexedStack` 注册方式。

**Tech Stack:** Flutter/Dart、`http`、`file_selector`、`flutter_test`。

---

### Task 1: 模型、存储和目录解析

**Files:**
- Create: `jntool/lib/tools/webdav_tool/webdav_models.dart`
- Create: `jntool/lib/tools/webdav_tool/webdav_storage.dart`
- Create: `jntool/lib/tools/webdav_tool/webdav_client.dart`
- Test: `jntool/test/webdav_models_test.dart`
- Test: `jntool/test/webdav_client_test.dart`
- Test: `jntool/test/webdav_storage_test.dart`

- [ ] 先写连接模型序列化、本地存储、XML 目录解析的失败测试。
- [ ] 运行 `flutter test test/webdav_models_test.dart test/webdav_client_test.dart test/webdav_storage_test.dart` 确认因缺少实现而失败。
- [ ] 实现最小模型、存储和客户端解析逻辑。
- [ ] 重跑上述测试确认通过。

### Task 2: WebDAV 三栏 UI

**Files:**
- Create: `jntool/lib/tools/webdav_tool/webdav_tool_screen.dart`
- Modify: `jntool/lib/app.dart`
- Modify: `jntool/lib/screens/home_screen.dart`
- Modify: `jntool/test/widget_test.dart`

- [ ] 先写 Widget 测试确认侧栏出现 `WebDAV 管理` 且可打开页面标题。
- [ ] 运行 `flutter test test/widget_test.dart` 确认失败。
- [ ] 接入工具注册、页面索引和三栏 UI。
- [ ] 重跑 Widget 测试确认通过。

### Task 3: 文件操作与收尾验证

**Files:**
- Modify: `jntool/lib/tools/webdav_tool/webdav_client.dart`
- Modify: `jntool/lib/tools/webdav_tool/webdav_tool_screen.dart`

- [ ] 补充客户端方法：测试连接、读取文本、保存文本、上传、下载、删除、新建文件夹。
- [ ] 在页面中接入按钮、状态提示和确认弹窗。
- [ ] 运行 `flutter test`、`flutter analyze`、必要时 `flutter build macos --release`。
