import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jntool/tools/webdav_tool/webdav_models.dart';
import 'package:jntool/tools/webdav_tool/webdav_storage.dart';

void main() {
  group('WebDavConnectionStorage', () {
    test('连接信息保存到本地 JSON 并可读取', () async {
      final tempDir = await Directory.systemTemp.createTemp('jntool_webdav_');
      addTearDown(() async {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      });
      final storage = WebDavConnectionStorage(
        file: File('${tempDir.path}/webdav_connections.json'),
      );

      final connection = WebDavConnection(
        id: 'conn-1',
        name: '坚果云',
        baseUrl: 'https://dav.jianguoyun.com/dav',
        username: 'mail@example.com',
        password: 'token',
        createdAt: DateTime.utc(2026, 6, 19),
        updatedAt: DateTime.utc(2026, 6, 19),
      );

      await storage.saveConnections([connection]);
      final loaded = await storage.loadConnections();

      expect(loaded, hasLength(1));
      expect(loaded.single.name, '坚果云');
      expect(loaded.single.password, 'token');
    });

    test('存储文件不存在时返回空列表', () async {
      final tempDir = await Directory.systemTemp.createTemp('jntool_webdav_');
      addTearDown(() async {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      });
      final storage = WebDavConnectionStorage(
        file: File('${tempDir.path}/missing.json'),
      );

      expect(await storage.loadConnections(), isEmpty);
    });
  });
}
