import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jntool/tools/base64_tool/base64_converter.dart';

void main() {
  group('Base64Converter', () {
    test('文本 UTF-8 Base64 往返', () {
      const source = '你好 JNTool Base64';

      final encoded = Base64Converter.textToBase64(source);
      final decoded = Base64Converter.base64ToText(encoded);

      expect(encoded, isNotEmpty);
      expect(decoded, source);
    });

    test('Base64 解码支持 Data URI 前缀', () {
      const dataUri = 'data:text/plain;base64,5L2g5aW9';

      expect(Base64Converter.base64ToText(dataUri), '你好');
      expect(Base64Converter.mimeTypeFromDataUri(dataUri), 'text/plain');
    });

    test('图片文件可转 Base64 并保存回文件', () async {
      final tempDir = await Directory.systemTemp.createTemp('jntool_base64_');
      addTearDown(() async {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      });

      final sourceFile = File('${tempDir.path}/pixel.png');
      final outputFile = File('${tempDir.path}/out.png');
      final bytes = <int>[137, 80, 78, 71, 13, 10, 26, 10];
      await sourceFile.writeAsBytes(bytes);

      final encoded = await Base64Converter.imageFileToBase64(sourceFile.path);
      final written = await Base64Converter.base64ToImageFile(
        encoded,
        outputFile.path,
      );

      expect(encoded, startsWith('data:image/png;base64,'));
      expect(written, bytes.length);
      expect(await outputFile.readAsBytes(), bytes);
    });
  });
}
