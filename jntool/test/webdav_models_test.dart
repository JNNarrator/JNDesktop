import 'package:flutter_test/flutter_test.dart';
import 'package:jntool/tools/webdav_tool/webdav_models.dart';

void main() {
  group('WebDavConnection', () {
    test('连接信息可 JSON 往返并规范化基础地址', () {
      final connection = WebDavConnection(
        id: 'conn-1',
        name: '家庭 NAS',
        baseUrl: 'https://nas.example.com/dav/',
        username: 'demo',
        password: 'secret',
        createdAt: DateTime.utc(2026, 6, 19),
        updatedAt: DateTime.utc(2026, 6, 20),
      );

      final decoded = WebDavConnection.fromJson(connection.toJson());

      expect(decoded.id, 'conn-1');
      expect(decoded.name, '家庭 NAS');
      expect(decoded.normalizedBaseUrl, 'https://nas.example.com/dav');
      expect(decoded.username, 'demo');
      expect(decoded.password, 'secret');
      expect(decoded.createdAt, DateTime.utc(2026, 6, 19));
      expect(decoded.updatedAt, DateTime.utc(2026, 6, 20));
    });

    test('文件条目能生成易读大小和路径', () {
      const file = WebDavFileEntry(
        name: 'notes.md',
        path: '/docs/notes.md',
        isDirectory: false,
        size: 1536,
        modifiedAt: null,
      );

      expect(file.sizeLabel, '1.5 KB');
      expect(file.displayName, 'notes.md');
    });
  });
}
