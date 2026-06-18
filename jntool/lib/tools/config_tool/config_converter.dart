// Spring Boot 配置文件 YAML / properties 双向转换。
// 该转换器聚焦常见配置结构：嵌套对象、点号 key、简单列表与标量值。

enum ConfigConvertDirection { yamlToProperties, propertiesToYaml }

class ConfigConverter {
  const ConfigConverter._();

  static String convert(String input, ConfigConvertDirection direction) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';

    return switch (direction) {
      ConfigConvertDirection.yamlToProperties => yamlToProperties(trimmed),
      ConfigConvertDirection.propertiesToYaml => propertiesToYaml(trimmed),
    };
  }

  static String yamlToProperties(String input) {
    final result = <String, String>{};
    final stack = <_YamlFrame>[];
    final listIndexes = <String, int>{};

    for (final rawLine in input.split('\n')) {
      if (rawLine.trim().isEmpty) continue;
      final indent = _countIndent(rawLine);
      final line = _stripInlineComment(rawLine.trimRight()).trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      if (rawLine.substring(0, indent).contains('\t')) {
        throw const FormatException('YAML 缩进不能使用 Tab，请改为空格');
      }

      while (stack.isNotEmpty && stack.last.indent >= indent) {
        stack.removeLast();
      }

      final parentPath = _stackPath(stack);
      if (line.startsWith('- ')) {
        _parseYamlListItem(
          line.substring(2).trim(),
          indent,
          parentPath,
          stack,
          listIndexes,
          result,
        );
        continue;
      }

      final entry = _splitYamlEntry(line);
      if (entry == null) {
        throw FormatException('无法解析 YAML 行：$line');
      }
      final keyPath = [...parentPath, entry.key];
      if (entry.value == null) {
        stack.add(_YamlFrame(indent, entry.key));
      } else {
        result[keyPath.join('.')] = _normalizeYamlScalar(entry.value!);
      }
    }

    return _renderProperties(result);
  }

  static String propertiesToYaml(String input) {
    dynamic root = <String, dynamic>{};
    for (final entry in _parseProperties(input).entries) {
      final path = _parsePropertyPath(entry.key);
      if (path.isEmpty) continue;
      root = _insertPath(root, path, entry.value);
    }
    return _renderYaml(root).trimRight();
  }

  static void _parseYamlListItem(
    String item,
    int indent,
    List<String> parentPath,
    List<_YamlFrame> stack,
    Map<String, int> listIndexes,
    Map<String, String> result,
  ) {
    if (parentPath.isEmpty) {
      throw const FormatException('暂不支持根节点直接为数组的 YAML');
    }

    final listPath = parentPath.join('.');
    final index =
        listIndexes.update(listPath, (value) => value + 1, ifAbsent: () => 0);
    final indexedKey = '${parentPath.removeLast()}[$index]';
    final indexedPath = [...parentPath, indexedKey];

    // 列表项可能是纯标量，也可能是 `- name: value` 这样的对象快捷写法。
    final entry = _splitYamlEntry(item);
    if (entry == null) {
      if (item.isEmpty) {
        stack.add(_YamlFrame(indent, indexedKey));
        return;
      }
      result[indexedPath.join('.')] = _normalizeYamlScalar(item);
      return;
    }

    if (entry.value == null) {
      stack.add(_YamlFrame(indent, indexedKey));
      stack.add(_YamlFrame(indent + 1, entry.key));
    } else {
      // `- host: localhost` 后续缩进字段仍属于同一个列表元素。
      stack.add(_YamlFrame(indent, indexedKey));
      result[[...indexedPath, entry.key].join('.')] =
          _normalizeYamlScalar(entry.value!);
    }
  }

  static Map<String, String> _parseProperties(String input) {
    final result = <String, String>{};
    final lines = _joinContinuationLines(input.split('\n'));

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#') || line.startsWith('!')) {
        continue;
      }
      final separator = _findPropertySeparator(line);
      if (separator < 0) {
        result[_unescapeProperty(line)] = '';
        continue;
      }

      final key = _unescapeProperty(line.substring(0, separator).trim());
      final value = _unescapeProperty(line.substring(separator + 1).trim());
      if (key.isNotEmpty) result[key] = value;
    }

    return result;
  }

  static List<String> _stackPath(List<_YamlFrame> stack) {
    final path = <String>[];
    for (final frame in stack) {
      if (path.isNotEmpty && frame.key.startsWith('${path.last}[')) {
        path[path.length - 1] = frame.key;
      } else {
        path.add(frame.key);
      }
    }
    return path;
  }

  static List<String> _joinContinuationLines(List<String> lines) {
    final joined = <String>[];
    var buffer = '';

    // properties 允许行尾反斜杠续行，先合并再解析键值。
    for (final line in lines) {
      final trimmedRight = line.replaceFirst(RegExp(r'\s+$'), '');
      if (trimmedRight.endsWith('\\') && !trimmedRight.endsWith('\\\\')) {
        buffer += trimmedRight.substring(0, trimmedRight.length - 1);
      } else {
        joined.add(buffer + trimmedRight);
        buffer = '';
      }
    }
    if (buffer.isNotEmpty) joined.add(buffer);
    return joined;
  }

  static int _findPropertySeparator(String line) {
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if ((char == '=' || char == ':') && !_isEscaped(line, i)) return i;
    }
    for (var i = 0; i < line.length; i++) {
      if (line[i].trim().isEmpty && !_isEscaped(line, i)) return i;
    }
    return -1;
  }

  static List<Object> _parsePropertyPath(String key) {
    final segments = <Object>[];
    for (final part in key.split('.')) {
      if (part.isEmpty) continue;
      final matches = RegExp(r'([^\[]+)|(\[(\d+)\])').allMatches(part);
      for (final match in matches) {
        final name = match.group(1);
        final index = match.group(3);
        if (name != null && name.isNotEmpty) segments.add(name);
        if (index != null) segments.add(int.parse(index));
      }
    }
    return segments;
  }

  static dynamic _insertPath(dynamic node, List<Object> path, String value) {
    if (path.isEmpty) return value;
    final head = path.first;
    final tail = path.sublist(1);

    if (head is int) {
      final list = node is List ? node : <dynamic>[];
      while (list.length <= head) {
        list.add(tail.isNotEmpty && tail.first is int
            ? <dynamic>[]
            : <String, dynamic>{});
      }
      list[head] = _insertPath(list[head], tail, value);
      return list;
    }

    final key = head as String;
    final map = node is Map<String, dynamic> ? node : <String, dynamic>{};
    final current = map[key];
    final fallback = tail.isNotEmpty && tail.first is int
        ? <dynamic>[]
        : <String, dynamic>{};
    map[key] = _insertPath(current ?? fallback, tail, value);
    return map;
  }

  static String _renderYaml(dynamic value, {int indent = 0}) {
    final spaces = ' ' * indent;
    if (value is Map<String, dynamic>) {
      final buffer = StringBuffer();
      for (final entry in value.entries) {
        if (entry.value is Map || entry.value is List) {
          buffer.writeln('$spaces${entry.key}:');
          buffer.write(_renderYaml(entry.value, indent: indent + 2));
        } else {
          buffer.writeln(
              '$spaces${entry.key}: ${_formatYamlScalar(entry.value)}');
        }
      }
      return buffer.toString();
    }
    if (value is List) {
      final buffer = StringBuffer();
      for (final item in value) {
        if (item is Map || item is List) {
          buffer.writeln('$spaces-');
          buffer.write(_renderYaml(item, indent: indent + 2));
        } else {
          buffer.writeln('$spaces- ${_formatYamlScalar(item)}');
        }
      }
      return buffer.toString();
    }
    return '$spaces${_formatYamlScalar(value)}\n';
  }

  static String _renderProperties(Map<String, String> values) {
    final keys = values.keys.toList()..sort();
    return keys.map((key) => '$key=${values[key]}').join('\n');
  }

  static _YamlEntry? _splitYamlEntry(String line) {
    var inSingle = false;
    var inDouble = false;
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == "'" && !inDouble) inSingle = !inSingle;
      if (char == '"' && !inSingle && !_isEscaped(line, i)) {
        inDouble = !inDouble;
      }
      if (char == ':' && !inSingle && !inDouble) {
        final key = line.substring(0, i).trim();
        final rest = line.substring(i + 1).trim();
        if (key.isEmpty) return null;
        return _YamlEntry(key, rest.isEmpty ? null : rest);
      }
    }
    return null;
  }

  static String _stripInlineComment(String line) {
    var inSingle = false;
    var inDouble = false;
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == "'" && !inDouble) inSingle = !inSingle;
      if (char == '"' && !inSingle && !_isEscaped(line, i)) {
        inDouble = !inDouble;
      }
      if (char == '#' && !inSingle && !inDouble) {
        if (i == 0 || line[i - 1].trim().isEmpty) return line.substring(0, i);
      }
    }
    return line;
  }

  static String _normalizeYamlScalar(String value) {
    final text = value.trim();
    if ((text.startsWith('"') && text.endsWith('"')) ||
        (text.startsWith("'") && text.endsWith("'"))) {
      return text.substring(1, text.length - 1);
    }
    return text;
  }

  static String _formatYamlScalar(dynamic value) {
    final text = value.toString();
    if (text.isEmpty) return "''";
    final lower = text.toLowerCase();
    final needsQuote = text != text.trim() ||
        text.contains(':') ||
        text.contains('#') ||
        text.startsWith('{') ||
        text.startsWith('[') ||
        ['null', 'true', 'false', 'yes', 'no', 'on', 'off'].contains(lower);
    if (!needsQuote) return text;
    return "'${text.replaceAll("'", "''")}'";
  }

  static String _unescapeProperty(String value) {
    return value
        .replaceAll(r'\:', ':')
        .replaceAll(r'\=', '=')
        .replaceAll(r'\ ', ' ')
        .replaceAll(r'\t', '\t')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\r', '\r')
        .replaceAll(r'\\', r'\');
  }

  static int _countIndent(String line) {
    var count = 0;
    while (count < line.length && line[count] == ' ') {
      count++;
    }
    return count;
  }

  static bool _isEscaped(String text, int index) {
    var slashCount = 0;
    for (var i = index - 1; i >= 0 && text[i] == r'\'; i--) {
      slashCount++;
    }
    return slashCount.isOdd;
  }
}

class _YamlFrame {
  final int indent;
  final String key;

  const _YamlFrame(this.indent, this.key);
}

class _YamlEntry {
  final String key;
  final String? value;

  const _YamlEntry(this.key, this.value);
}
