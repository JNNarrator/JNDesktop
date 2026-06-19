import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jntool/tools/webdav_tool/webdav_client.dart';
import 'package:jntool/tools/webdav_tool/webdav_models.dart';

void main() {
  group('WebDavClient', () {
    final connection = WebDavConnection(
      id: 'conn-1',
      name: '测试盘',
      baseUrl: 'https://dav.example.com/root',
      username: 'user',
      password: 'pass',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

    test('PROPFIND 目录解析会跳过当前目录并按文件夹优先排序', () async {
      final client = WebDavClient(
        httpClient: MockClient((request) async {
          expect(request.method, 'PROPFIND');
          expect(request.url.toString(), 'https://dav.example.com/root/docs/');
          expect(request.headers['depth'], '1');
          expect(
            request.headers['authorization'],
            'Basic ${base64Encode(utf8.encode('user:pass'))}',
          );

          return http.Response(_multiStatusXml, 207, headers: {
            'content-type': 'application/xml; charset=utf-8',
          });
        }),
      );

      final entries = await client.listDirectory(connection, '/docs');

      expect(entries, hasLength(2));
      expect(entries.first.name, 'assets');
      expect(entries.first.isDirectory, isTrue);
      expect(entries.first.path, '/docs/assets');
      expect(entries.last.name, 'readme.md');
      expect(entries.last.isDirectory, isFalse);
      expect(entries.last.size, 42);
    });

    test('读取和保存文本文件使用 GET 与 PUT', () async {
      final requests = <String>[];
      final client = WebDavClient(
        httpClient: MockClient((request) async {
          requests.add('${request.method} ${request.url}');
          if (request.method == 'GET') {
            return http.Response('你好 WebDAV', 200, headers: {
              'content-type': 'text/plain; charset=utf-8',
            });
          }
          if (request.method == 'PUT') {
            expect(utf8.decode(request.bodyBytes), '更新内容');
            return http.Response('', 204);
          }
          return http.Response('Method Not Allowed', 405);
        }),
      );

      final text = await client.readTextFile(connection, '/docs/readme.md');
      await client.saveTextFile(connection, '/docs/readme.md', '更新内容');

      expect(text, '你好 WebDAV');
      expect(requests, [
        'GET https://dav.example.com/root/docs/readme.md',
        'PUT https://dav.example.com/root/docs/readme.md',
      ]);
    });
  });
}

const _multiStatusXml = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/root/docs/</d:href>
    <d:propstat><d:prop><d:resourcetype><d:collection/></d:resourcetype></d:prop></d:propstat>
  </d:response>
  <d:response>
    <d:href>/root/docs/readme.md</d:href>
    <d:propstat><d:prop><d:getcontentlength>42</d:getcontentlength><d:getlastmodified>Fri, 19 Jun 2026 10:00:00 GMT</d:getlastmodified></d:prop></d:propstat>
  </d:response>
  <d:response>
    <d:href>/root/docs/assets/</d:href>
    <d:propstat><d:prop><d:resourcetype><d:collection/></d:resourcetype></d:prop></d:propstat>
  </d:response>
</d:multistatus>
''';
