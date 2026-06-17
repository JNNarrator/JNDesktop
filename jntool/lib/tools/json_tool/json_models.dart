// JSON 工具 —— 数据模型
// 定义 JSON 解析后的树形节点结构

import 'dart:convert';

/// JSON 树形节点类型
enum JsonNodeType {
  object,   // 对象 { }
  array,    // 数组 [ ]
  string,   // 字符串
  number,   // 数字
  boolean,  // 布尔值
  nullValue, // null
}

/// JSON 树形节点 —— 递归结构
/// 每个节点包含类型、键名、值和子节点
class JsonTreeNode {
  final String? key;           // 键名（根节点无 key）
  final dynamic rawValue;      // 原始 Dart 值
  final JsonNodeType type;     // 节点类型
  final List<JsonTreeNode> children; // 子节点（仅 object/array 有）
  bool isExpanded;             // 是否展开

  JsonTreeNode({
    this.key,
    required this.rawValue,
    required this.type,
    required this.children,
    this.isExpanded = true,
  });

  /// 获取类型标签（用于树形展示中的色标）
  String get typeLabel {
    switch (type) {
      case JsonNodeType.object:  return '{}';
      case JsonNodeType.array:   return '[]';
      case JsonNodeType.string:  return 'str';
      case JsonNodeType.number:  return 'num';
      case JsonNodeType.boolean: return 'bool';
      case JsonNodeType.nullValue: return 'nil';
    }
  }

  /// 获取格式化显示的值文本
  String get displayValue {
    switch (type) {
      case JsonNodeType.object:
        return '{${children.length}}';
      case JsonNodeType.array:
        return '[${children.length}]';
      case JsonNodeType.string:
        return '"$rawValue"';
      case JsonNodeType.number:
        return '$rawValue';
      case JsonNodeType.boolean:
        return rawValue ? 'true' : 'false';
      case JsonNodeType.nullValue:
        return 'null';
    }
  }

  /// 获取值的预览摘要（用于叶子节点在行内显示）
  String get valuePreview {
    if (type == JsonNodeType.object) return '{...}';
    if (type == JsonNodeType.array) return '[...]';
    if (type == JsonNodeType.string) {
      final str = rawValue as String;
      if (str.length > 50) return '"${str.substring(0, 47)}..."';
      return '"$str"';
    }
    return displayValue;
  }
}

/// JSON 解析器 —— 将 JSON 字符串解析为树形节点
class JsonTreeBuilder {
  /// 从 JSON 字符串构建树形节点
  static JsonTreeNode? fromString(String jsonStr) {
    try {
      final parsed = json.decode(jsonStr);
      if (parsed == null) return null;
      return _buildNode('root', parsed);
    } catch (_) {
      return null;
    }
  }

  /// 递归构建树形节点
  static JsonTreeNode _buildNode(String key, dynamic value) {
    if (value is Map) {
      final children = value.entries
          .map((e) => _buildNode(e.key.toString(), e.value))
          .toList();
      return JsonTreeNode(
        key: key,
        rawValue: value,
        type: JsonNodeType.object,
        children: children,
        isExpanded: true,
      );
    } else if (value is List) {
      final children = <JsonTreeNode>[];
      for (var i = 0; i < value.length; i++) {
        children.add(_buildNode('[$i]', value[i]));
      }
      return JsonTreeNode(
        key: key,
        rawValue: value,
        type: JsonNodeType.array,
        children: children,
        isExpanded: true,
      );
    } else if (value is String) {
      return JsonTreeNode(key: key, rawValue: value, type: JsonNodeType.string, children: []);
    } else if (value is num) {
      return JsonTreeNode(key: key, rawValue: value, type: JsonNodeType.number, children: []);
    } else if (value is bool) {
      return JsonTreeNode(key: key, rawValue: value, type: JsonNodeType.boolean, children: []);
    } else {
      return JsonTreeNode(key: key, rawValue: value, type: JsonNodeType.nullValue, children: []);
    }
  }
}

/// JSON 格式化工具
class JsonFormatter {
  /// 格式化 JSON 字符串（缩进 2 空格）
  static String format(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) return '';
    try {
      final parsed = json.decode(trimmed);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(parsed);
    } catch (_) {
      return source;
    }
  }

  /// 压缩 JSON（去掉空格和换行）
  static String minify(String source) {
    try {
      final parsed = json.decode(source.trim());
      return json.encode(parsed);
    } catch (_) {
      return source;
    }
  }

  /// 校验 JSON 合法性
  static String? validate(String source) {
    try {
      json.decode(source.trim());
      return null; // 合法，无错误
    } catch (e) {
      return e.toString();
    }
  }
}
