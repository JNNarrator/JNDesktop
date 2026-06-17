// 工具数据模型
// 定义每个开发工具的基本信息结构

class ToolModel {
  final String id;        // 工具唯一标识
  final String name;      // 工具名称
  final String icon;      // 使用的 Emoji 图标
  final String color;     // 主题色（十六进制）
  final String description; // 工具描述
  final String route;     // 路由路径

  const ToolModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.route,
  });
}
