// Bean conversion engine.
// Supports JSON -> Java Bean and Java Bean -> JSON sample generation.

import 'dart:convert';

enum ConvertDirection {
  jsonToBean,
  beanToJson,
}

class LombokConfig {
  final bool useData;
  final bool useGetter;
  final bool useSetter;
  final bool useToString;
  final bool useEqualsHash;
  final bool useBuilder;
  final bool useAllArgs;
  final bool useNoArgs;
  final bool useAccessors;
  final bool useJsonIgnore;
  final bool useJsonProperty;

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

  List<String> get imports {
    final result = <String>[];
    if (useData) result.add('import lombok.Data;');
    if (useGetter && !useData) result.add('import lombok.Getter;');
    if (useSetter && !useData) result.add('import lombok.Setter;');
    if (useToString && !useData) result.add('import lombok.ToString;');
    if (useEqualsHash && !useData) {
      result.add('import lombok.EqualsAndHashCode;');
    }
    if (useBuilder) result.add('import lombok.Builder;');
    if (useAllArgs) result.add('import lombok.AllArgsConstructor;');
    if (useNoArgs) result.add('import lombok.NoArgsConstructor;');
    if (useAccessors) result.add('import lombok.experimental.Accessors;');
    if (useJsonProperty || useJsonIgnore) {
      result.add('import com.fasterxml.jackson.annotation.*;');
    }
    result.sort();
    return result;
  }

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

  String fieldAnnotations({
    bool isJsonIgnore = false,
    String? jsonPropertyName,
  }) {
    final result = <String>[];
    if (isJsonIgnore && useJsonIgnore) result.add('    @JsonIgnore');
    if (jsonPropertyName != null && useJsonProperty) {
      result.add('    @JsonProperty("$jsonPropertyName")');
    }
    return result.join('\n');
  }
}

class JavaField {
  final String type;
  final String name;
  final String? jsonName;
  final bool isObject;
  final bool isArray;
  final String? elementType;
  final dynamic sampleValue;

  JavaField({
    required this.type,
    required this.name,
    this.jsonName,
    this.isObject = false,
    this.isArray = false,
    this.elementType,
    this.sampleValue,
  });

  String get capitalizedName =>
      name.isNotEmpty ? '${name[0].toUpperCase()}${name.substring(1)}' : name;
}

class BeanConvertConfig {
  final LombokConfig lombok;
  final String className;
  final bool useInnerClass;
  final String packageName;
  final bool useJsonAnnotations;
  final bool useCamelCase;
  final bool generateComments;

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

class BeanGenerator {
  static String jsonToJava(String jsonStr, BeanConvertConfig config) {
    final trimmed = jsonStr.trim();
    if (trimmed.isEmpty) return '';

    try {
      final parsed = json.decode(trimmed);
      final fields = _extractFields(parsed, config.useCamelCase);
      return _buildJavaClass(config, fields);
    } catch (e) {
      return '// JSON parse error: $e\n$jsonStr';
    }
  }

  static String javaToJson(String javaCode) {
    try {
      final fields = _parseJavaFields(javaCode);
      final map = <String, dynamic>{};
      for (final field in fields) {
        map[field.name] = _exampleValue(field.type);
      }
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(map);
    } catch (e) {
      return '// Java parse error: $e\n$javaCode';
    }
  }

  static List<JavaField> _extractFields(dynamic value, bool useCamelCase) {
    final fields = <JavaField>[];

    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString();
        final fieldName = useCamelCase ? _toCamelCase(key) : key;
        final fieldValue = entry.value;

        if (fieldValue is Map) {
          fields.add(JavaField(
            type: _toClassName(key),
            name: fieldName,
            jsonName: key,
            isObject: true,
            sampleValue: fieldValue,
          ));
        } else if (fieldValue is List) {
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

  static String _inferListElementType(List list, String fieldName) {
    if (list.isEmpty) return 'Object';
    final first = list.first;
    if (first is Map) return _toClassName(fieldName);
    if (first is List) return 'List<Object>';
    return _dartToJavaType(first);
  }

  static String _buildJavaClass(
    BeanConvertConfig config,
    List<JavaField> fields, {
    String className = '',
  }) {
    final actualClassName = className.isNotEmpty ? className : config.className;
    final buf = StringBuffer();
    final lombok = _lombokWithJackson(config);
    final imports = <String>{...lombok.imports};

    if (fields.any((field) => field.isArray)) {
      imports.add('import java.util.List;');
    }

    if (config.packageName.isNotEmpty) {
      buf.writeln('package ${config.packageName};');
      buf.writeln();
    }

    for (final imp in imports.toList()..sort()) {
      buf.writeln(imp);
    }
    if (imports.isNotEmpty) buf.writeln();

    if (config.generateComments) {
      buf.writeln('/**');
      buf.writeln(' * $actualClassName model.');
      buf.writeln(' *');
      buf.writeln(' * Generated by JNTool.');
      buf.writeln(' */');
    }

    for (final annotation in lombok.classAnnotations) {
      buf.writeln(annotation);
    }

    buf.writeln('public class $actualClassName {');
    if (fields.isNotEmpty) buf.writeln();

    for (var index = 0; index < fields.length; index++) {
      final field = fields[index];
      final jsonPropertyName =
          field.jsonName != field.name ? field.jsonName : null;

      if (config.generateComments && jsonPropertyName != null) {
        buf.writeln('    /** JSON field: "$jsonPropertyName". */');
      }

      final fieldAnnotations = lombok.fieldAnnotations(
        jsonPropertyName: jsonPropertyName,
      );
      if (fieldAnnotations.isNotEmpty) {
        buf.writeln(fieldAnnotations);
      }

      buf.writeln('    private ${field.type} ${field.name};');
      if (index != fields.length - 1) buf.writeln();
    }

    if (_shouldGenerateAccessors(config, fields)) buf.writeln();

    if (!config.lombok.useData && !config.lombok.useGetter) {
      _writeGetters(buf, fields);
    }
    if (!config.lombok.useData && !config.lombok.useSetter) {
      if (!config.lombok.useGetter && fields.isNotEmpty) buf.writeln();
      _writeSetters(buf, fields);
    }

    buf.writeln('}');
    return buf.toString();
  }

  static LombokConfig _lombokWithJackson(BeanConvertConfig config) {
    final lb = config.lombok;
    return LombokConfig(
      useData: lb.useData,
      useGetter: lb.useGetter,
      useSetter: lb.useSetter,
      useToString: lb.useToString,
      useEqualsHash: lb.useEqualsHash,
      useBuilder: lb.useBuilder,
      useAllArgs: lb.useAllArgs,
      useNoArgs: lb.useNoArgs,
      useAccessors: lb.useAccessors,
      useJsonIgnore: lb.useJsonIgnore,
      useJsonProperty: config.useJsonAnnotations || lb.useJsonProperty,
    );
  }

  static bool _shouldGenerateAccessors(
    BeanConvertConfig config,
    List<JavaField> fields,
  ) {
    if (fields.isEmpty) return false;
    return !config.lombok.useData &&
        (!config.lombok.useGetter || !config.lombok.useSetter);
  }

  static void _writeGetters(StringBuffer buf, List<JavaField> fields) {
    for (var index = 0; index < fields.length; index++) {
      final field = fields[index];
      buf.writeln('    public ${field.type} get${field.capitalizedName}() {');
      buf.writeln('        return ${field.name};');
      buf.writeln('    }');
      if (index != fields.length - 1) buf.writeln();
    }
  }

  static void _writeSetters(StringBuffer buf, List<JavaField> fields) {
    for (var index = 0; index < fields.length; index++) {
      final field = fields[index];
      buf.writeln(
        '    public void set${field.capitalizedName}(${field.type} ${field.name}) {',
      );
      buf.writeln('        this.${field.name} = ${field.name};');
      buf.writeln('    }');
      if (index != fields.length - 1) buf.writeln();
    }
  }

  static String _toCamelCase(String name) {
    final parts = name.split('_');
    if (parts.length == 1) return name;
    return parts[0] +
        parts.skip(1).map((part) {
          return part.isNotEmpty
              ? '${part[0].toUpperCase()}${part.substring(1)}'
              : '';
        }).join();
  }

  static String _toClassName(String name) {
    var base = _toCamelCase(name);
    if (base.endsWith('s') && base.length > 2) {
      base = base.substring(0, base.length - 1);
    }
    if (base.endsWith('ss')) base = '${base}s';
    return base.isNotEmpty
        ? '${base[0].toUpperCase()}${base.substring(1)}'
        : 'Item';
  }

  static String _dartToJavaType(dynamic value) {
    if (value == null) return 'Object';
    if (value is int) return 'Integer';
    if (value is double) return 'Double';
    if (value is bool) return 'Boolean';
    if (value is String) return 'String';
    return 'Object';
  }

  static List<JavaField> _parseJavaFields(String javaCode) {
    final fields = <JavaField>[];
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
