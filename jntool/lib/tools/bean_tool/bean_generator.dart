// Bean 工具 —— Java Bean ↔ JSON 转换引擎
// JSON 转 Java（支持 Lombok、自定义类名、内部类）、Java 转 JSON

import 'dart:convert';

/// 转换方向
enum ConvertDirection {
  jsonToBean, // JSON → Java Bean
  beanToJson, // Java Bean → JSON
}

/// Lombok 注解配置
class LombokConfig {
  final bool useData;       // @Data
  final bool useGetter;     // @Getter
  final bool useSetter;     // @Setter
  final bool useToString;   // @ToString
  final bool useEqualsHash; // @EqualsAndHashCode
  final bool useBuilder;    // @Builder
  final bool useAllArgs;    // @AllArgsConstructor
  final bool useNoArgs;     // @NoArgsConstructor
  final bool useAccessors;  // @Accessors(chain = true)
  final bool useJsonIgnore; // @JsonIgnore（用于忽略字段）
  final bool useJsonProperty; // @JsonProperty（用于指定 JSON 键名）

  const LombokConfig({
    this.useData = true,
    this.useGetter = false,
    this.useSetter = false,
    this.useToString = false,
    this.useEqualsHash = false,
    this.useBuilder = false,
    this.useAllArgs = false,
    this.useNoArgs = false,
    this.useAccessors = false,
    this.useJsonIgnore = false,
    this.useJsonProperty = false,
  });

  /// 获取需要的 Lombok import
  List<String> get imports {
    final result = <String>['import lombok.Data;'];
    if (useGetter) result.add('import lombok.Getter;');
    if (useSetter) result.add('import lombok.Setter;');
    if (useToString) result.add('import lombok.ToString;');
    if (useEqualsHash) result.add('import lombok.EqualsAndHashCode;');
    if (useBuilder) result.add('import lombok.Builder;');
    if (useAllArgs) result.add('import lombok.AllArgsConstructor;');
    if (useNoArgs) result.add('import lombok.NoArgsConstructor;');
    if (useAccessors) result.add('import lombok.experimental.Accessors;');
    if (useJsonProperty || useJsonIgnore) {
      result.add('import com.fasterxml.jackson.annotation.*;');
    }
    return result;
  }

  /// 获取类注解
  List<String> get classAnnotations {
    final result = <String>[];
    if (useData) result.add('@Data');
    if (useGetter && !useData) result.add('@Getter');
    if (useSetter && !useData) result.add('@Setter');
    if (useToString && !useData) result.add('@ToString');
    if (useEqualsHash && !useData) result.add('@EqualsAndHashCode');
    if (useBuilder) result.add('@Builder');
    if (useAllArgs) result.add('@AllArgsConstructor');
    if (useNoArgs) result.add('@NoArgsConstructor');
    if (useAccessors) result.add('@Accessors(chain = true)');
    return result;
  }

  /// 获取字段注解（根据字段是否需要特殊处理）
  String fieldAnnotations(String fieldName, {bool isJsonIgnore = false, String? jsonPropertyName}) {
    final result = <String>[];
    if (isJsonIgnore && useJsonIgnore) result.add('    @JsonIgnore');
    if (jsonPropertyName != null && useJsonProperty) {
      result.add('    @JsonProperty("$jsonPropertyName")');
    }
    return result.join('\n');
  }
}

/// Java 字段信息
class JavaField {
  final String type;
  final String name;
  final String? jsonName;      // JSON 中的键名（驼峰/下划线转换时有用）
  final bool isObject;         // 是否为复杂对象
  final bool isArray;          // 是否为数组/List
  final String? elementType;   // 数组元素类型
  final dynamic sampleValue;   // 示例值（用于推断类型）

  JavaField({
    required this.type,
    required this.name,
    this.jsonName,
    this.isObject = false,
    this.isArray = false,
    this.elementType,
    this.sampleValue,
  });

  /// 首字母大写
  String get capitalizedName => name.isNotEmpty
      ? '${name[0].toUpperCase()}${name.substring(1)}'
      : name;
}

/// 转换配置
class BeanConvertConfig {
  final LombokConfig lombok;
  final String className;
  final bool useInnerClass;
  final String packageName;
  final bool useJsonAnnotations; // Jackson 注解
  final bool useCamelCase;       // 驼峰命名
  final bool generateComments;   // 生成注释

  const BeanConvertConfig({
    this.lombok = const LombokConfig(),
    this.className = 'Root',
    this.useInnerClass = false,
    this.packageName = 'com.example.model',
    this.useJsonAnnotations = false,
    this.useCamelCase = true,
    this.generateComments = true,
  });
}

/// Bean 转换引擎
class BeanGenerator {
  /// JSON → Java Bean
  static String jsonToJava(String jsonStr, BeanConvertConfig config) {
    final trimmed = jsonStr.trim();
    if (trimmed.isEmpty) return '';

    try {
      final parsed = json.decode(trimmed);
      final fields = _extractFields(parsed, '', config.useCamelCase);
      final innerClasses = <String>[];

      return _buildJavaClass(config, fields, parsed, innerClasses);
    } catch (e) {
      return '// JSON 解析错误: $e\n${jsonStr}';
    }
  }

  /// Java Bean → JSON
  static String javaToJson(String javaCode) {
    // 从 Java 类定义解析出字段，生成示例 JSON
    try {
      final fields = _parseJavaFields(javaCode);
      final map = <String, dynamic>{};
      for (final field in fields) {
        map[field.name] = _exampleValue(field.type);
      }
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(map);
    } catch (e) {
      return '// 解析失败: $e\n$javaCode';
    }
  }

  /// 从 JSON 值提取字段列表（递归）
  static List<JavaField> _extractFields(dynamic value, String prefix, bool useCamelCase) {
    final fields = <JavaField>[];

    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString();
        // 转换为驼峰命名（去掉下划线）
        final fieldName = useCamelCase ? _toCamelCase(key) : key;
        final fieldValue = entry.value;

        if (fieldValue is Map) {
          // 对象类型
          fields.add(JavaField(
            type: _toClassName(key),
            name: fieldName,
            jsonName: key,
            isObject: true,
            sampleValue: fieldValue,
          ));
        } else if (fieldValue is List) {
          // 数组类型
          final elementType = _inferListElementType(fieldValue, key);
          fields.add(JavaField(
            type: 'List<$elementType>',
            name: fieldName,
            jsonName: key,
            isArray: true,
            elementType: elementType,
            sampleValue: fieldValue,
          ));
        } else {
          // 基本类型
          fields.add(JavaField(
            type: _dartToJavaType(fieldValue),
            name: fieldName,
            jsonName: key,
            sampleValue: fieldValue,
          ));
        }
      }
    }

    return fields;
  }

  /// 推断数组元素类型
  static String _inferListElementType(List list, String fieldName) {
    if (list.isEmpty) return 'Object';
    final first = list.first;
    if (first is Map) return _toClassName(fieldName); // 去掉可能的复数
    if (first is List) return 'List<Object>';
    return _dartToJavaType(first);
  }

  /// 构建 Java 类代码
  static String _buildJavaClass(
    BeanConvertConfig config,
    List<JavaField> fields,
    dynamic rawValue,
    List<String> innerClasses,
    {String className = ''}) {

    final actualClassName = className.isNotEmpty ? className : config.className;
    final buf = StringBuffer();

    // Package
    if (config.packageName.isNotEmpty) {
      buf.writeln('package ${config.packageName};');
      buf.writeln();
    }

    // Imports
    if (config.lombok.imports.isNotEmpty) {
      for (final imp in config.lombok.imports) {
        buf.writeln(imp);
      }
    }
    // 检查是否需要 List/Map 的 import
    final hasList = fields.any((f) => f.isArray);
    if (hasList) {
      buf.writeln('import java.util.List;');
    }

    if (config.lombok.imports.isNotEmpty || hasList) {
      buf.writeln();
    }

    // 类注释
    if (config.generateComments) {
      buf.writeln('/**');
      buf.writeln(' * $actualClassName');
      buf.writeln(' * Auto-generated by JNTool');
      buf.writeln(' */');
    }

    // 类注解
    for (final ann in config.lombok.classAnnotations) {
      buf.writeln(ann);
    }

    // 类定义
    buf.writeln('public class $actualClassName {');
    buf.writeln();

    // 字段
    for (final field in fields) {
      // 字段注释
      if (config.generateComments && field.jsonName != null && field.jsonName != field.name) {
        buf.writeln('    /** JSON field: "${field.jsonName}" */');
      }

      // 字段注解
      final fieldAnn = config.lombok.fieldAnnotations(
        field.name,
        jsonPropertyName: field.jsonName != field.name ? field.jsonName : null,
      );
      if (fieldAnn.isNotEmpty) {
        buf.writeln(fieldAnn);
      }

      buf.writeln('    private ${field.type} ${field.name};');
      buf.writeln();
    }

    // 无 Lombok 时生成 getter/setter
    if (!config.lombok.useData && !config.lombok.useGetter) {
      for (final field in fields) {
        buf.writeln('    public ${field.type} get${field.capitalizedName}() {');
        buf.writeln('        return ${field.name};');
        buf.writeln('    }');
        buf.writeln();
      }
    }
    if (!config.lombok.useData && !config.lombok.useSetter) {
      for (final field in fields) {
        buf.writeln('    public void set${field.capitalizedName}(${field.type} ${field.name}) {');
        buf.writeln('        this.${field.name} = ${field.name};');
        buf.writeln('    }');
        buf.writeln();
      }
    }

    buf.writeln('}');

    return buf.toString();
  }

  /// 将下划线命名转为驼峰
  static String _toCamelCase(String name) {
    final parts = name.split('_');
    if (parts.length == 1) return name;
    return parts[0] + parts.skip(1).map((p) =>
        p.isNotEmpty ? '${p[0].toUpperCase()}${p.substring(1)}' : '').join();
  }

  /// 将 JSON 键名转为类名（首字母大写驼峰）
  static String _toClassName(String name) {
    // 去掉复数 s/es
    var base = _toCamelCase(name);
    if (base.endsWith('s') && base.length > 2) {
      // 简单处理：去掉末尾 s
      base = base.substring(0, base.length - 1);
    }
    if (base.endsWith('ss')) base = '${base}s'; // class 等
    return base.isNotEmpty
        ? '${base[0].toUpperCase()}${base.substring(1)}'
        : 'Item';
  }

  /// Dart 类型 → Java 类型映射
  static String _dartToJavaType(dynamic value) {
    if (value == null) return 'Object';
    if (value is int) return 'Integer';
    if (value is double) return 'Double';
    if (value is bool) return 'Boolean';
    if (value is String) return 'String';
    return 'Object';
  }

  /// 从 Java 代码解析字段
  static List<JavaField> _parseJavaFields(String javaCode) {
    final fields = <JavaField>[];
    // 简单正则匹配字段定义：private Type name;
    final pattern = RegExp(
      r'private\s+(String|Integer|int|Long|long|Double|double|Boolean|boolean|List<[^>]+>|Map<[^>]+>|Object)\s+(\w+)\s*;',
    );
    for (final match in pattern.allMatches(javaCode)) {
      fields.add(JavaField(
        type: match.group(1)!,
        name: match.group(2)!,
      ));
    }
    return fields;
  }

  /// Java 类型 → 示例值
  static dynamic _exampleValue(String type) {
    if (type == 'String' || type == 'string') return 'example';
    if (type == 'Integer' || type == 'int') return 0;
    if (type == 'Double' || type == 'double') return 0.0;
    if (type == 'Boolean' || type == 'boolean') return false;
    if (type == 'Long' || type == 'long') return 0;
    if (type.startsWith('List<')) return [];
    if (type.startsWith('Map<')) return {};
    return null;
  }
}
