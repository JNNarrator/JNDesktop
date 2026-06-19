# WebDAV 管理功能设计

## 目标

在 JNTool 中新增 WebDAV 管理工具，采用三栏管理台：左侧管理本地连接，中间浏览远端目录，右侧查看详情并编辑文本文件。

## 范围

- 保存 WebDAV 连接信息到本机用户目录 `.jntool/webdav_connections.json`。
- 支持新增、更新、删除、选择连接，并可测试连接有效性。
- 支持目录浏览、返回上级、刷新、上传、下载、删除文件/目录、新建文件夹。
- 支持打开 UTF-8 文本文件，编辑后通过 WebDAV `PUT` 保存。
- 不做云同步、密码加密、批量复制/移动、冲突合并和二进制在线预览。

## 架构

- `webdav_models.dart` 定义连接、文件条目、操作结果等纯模型。
- `webdav_storage.dart` 负责本地 JSON 持久化，UI 不直接读写文件。
- `webdav_client.dart` 封装 WebDAV 请求和 `PROPFIND` XML 解析，支持测试注入 `http.Client`。
- `webdav_tool_screen.dart` 负责三栏 UI、用户操作状态和错误提示。

## 错误处理

URL、名称、路径为空时在本地拦截。网络失败、鉴权失败、XML 解析失败和保存失败统一转成用户可读消息。删除远端资源前弹确认框，避免误操作。

## 验证

优先用单元测试覆盖连接模型、本地存储和 WebDAV XML 目录解析，再用 Widget 测试确认侧栏入口可打开工具页。收尾运行 `flutter test` 与 `flutter analyze`。
