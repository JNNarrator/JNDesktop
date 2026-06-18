// Base64 编解码核心逻辑。
// 支持文本 UTF-8 编解码、图片文件字节编解码和 Data URI 处理。

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class Base64Converter {
  const Base64Converter._();

  static String textToBase64(String input) {
    return base64Encode(utf8.encode(input));
  }

  static String base64ToText(String input) {
    final bytes = base64Decode(_stripDataUri(input));
    return utf8.decode(bytes);
  }

  static Future<String> imageFileToBase64(String path,
      {bool asDataUri = true}) async {
    final file = File(path.trim());
    if (!await file.exists()) {
      throw FormatException('图片文件不存在：${file.path}');
    }
    final bytes = await file.readAsBytes();
    final encoded = base64Encode(bytes);
    if (!asDataUri) return encoded;
    return 'data:${mimeTypeFromPath(file.path)};base64,$encoded';
  }

  static Future<int> base64ToImageFile(String input, String outputPath) async {
    final bytes = base64ToBytes(input);
    final file = File(outputPath.trim());
    if (file.path.isEmpty) {
      throw const FormatException('请填写输出图片路径');
    }

    // 保存前确保父目录存在，避免 File.writeAsBytes 抛出难读的系统异常。
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    await file.writeAsBytes(bytes);
    return bytes.length;
  }

  static Uint8List base64ToBytes(String input) {
    final cleaned = _stripDataUri(input);
    if (cleaned.isEmpty) throw const FormatException('Base64 内容不能为空');
    return base64Decode(cleaned);
  }

  static String? mimeTypeFromDataUri(String input) {
    final match = RegExp(r'^data:([^;,]+);base64,', caseSensitive: false)
        .firstMatch(input.trim());
    return match?.group(1);
  }

  static String mimeTypeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    return 'image/png';
  }

  static String _stripDataUri(String input) {
    final text = input.trim();
    final commaIndex = text.indexOf(',');
    if (text.toLowerCase().startsWith('data:') && commaIndex >= 0) {
      return text.substring(commaIndex + 1).replaceAll(RegExp(r'\s+'), '');
    }
    return text.replaceAll(RegExp(r'\s+'), '');
  }
}
