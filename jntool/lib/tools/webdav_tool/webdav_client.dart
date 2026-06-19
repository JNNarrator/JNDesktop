// WebDAV 请求客户端。
// 封装 PROPFIND/GET/PUT/MKCOL/DELETE 等操作，UI 层只消费明确的方法结果。

import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'webdav_models.dart';

class WebDavClient {
  final http.Client _httpClient;

  WebDavClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Future<WebDavOperationResult> testConnection(
    WebDavConnection connection,
  ) async {
    try {
      await listDirectory(connection, '/');
      return const WebDavOperationResult(success: true, message: '连接成功');
    } catch (e) {
      return WebDavOperationResult(success: false, message: '连接失败：$e');
    }
  }

  Future<List<WebDavFileEntry>> listDirectory(
    WebDavConnection connection,
    String path,
  ) async {
    final normalizedPath = _normalizeDirectoryPath(path);
    final response = await _send(
      connection: connection,
      method: 'PROPFIND',
      path: normalizedPath,
      headers: const {'depth': '1'},
      body: _propfindBody,
    );
    _ensureSuccess(response, expected: const [207, 200]);

    final basePath = _baseUri(connection).path;
    return _parseMultiStatus(
      utf8.decode(response.bodyBytes),
      basePath: basePath,
      currentPath: normalizedPath,
    );
  }

  Future<String> readTextFile(WebDavConnection connection, String path) async {
    final response = await _send(
      connection: connection,
      method: 'GET',
      path: path,
    );
    _ensureSuccess(response, expected: const [200]);
    return utf8.decode(response.bodyBytes);
  }

  Future<void> saveTextFile(
    WebDavConnection connection,
    String path,
    String content,
  ) async {
    final response = await _send(
      connection: connection,
      method: 'PUT',
      path: path,
      headers: const {'content-type': 'text/plain; charset=utf-8'},
      bodyBytes: Uint8List.fromList(utf8.encode(content)),
    );
    _ensureSuccess(response, expected: const [200, 201, 204]);
  }

  Future<void> uploadFile(
    WebDavConnection connection,
    String remotePath,
    Uint8List bytes,
  ) async {
    final response = await _send(
      connection: connection,
      method: 'PUT',
      path: remotePath,
      bodyBytes: bytes,
    );
    _ensureSuccess(response, expected: const [200, 201, 204]);
  }

  Future<Uint8List> downloadFile(
    WebDavConnection connection,
    String remotePath,
  ) async {
    final response = await _send(
      connection: connection,
      method: 'GET',
      path: remotePath,
    );
    _ensureSuccess(response, expected: const [200]);
    return response.bodyBytes;
  }

  Future<void> createDirectory(
    WebDavConnection connection,
    String remotePath,
  ) async {
    final response = await _send(
      connection: connection,
      method: 'MKCOL',
      path: _normalizeDirectoryPath(remotePath),
    );
    _ensureSuccess(response, expected: const [200, 201, 204, 405]);
  }

  Future<void> deleteResource(
    WebDavConnection connection,
    String remotePath,
  ) async {
    final response = await _send(
      connection: connection,
      method: 'DELETE',
      path: remotePath,
    );
    _ensureSuccess(response, expected: const [200, 202, 204, 404]);
  }

  Future<http.Response> _send({
    required WebDavConnection connection,
    required String method,
    required String path,
    Map<String, String> headers = const {},
    String? body,
    Uint8List? bodyBytes,
  }) async {
    final request = http.Request(method, _buildUri(connection, path));
    request.headers.addAll({
      ...headers,
      if (connection.username.isNotEmpty || connection.password.isNotEmpty)
        'authorization': _basicAuth(connection),
    });
    if (bodyBytes != null) {
      request.bodyBytes = bodyBytes;
    } else if (body != null) {
      request.body = body;
    }

    final streamed = await _httpClient.send(request);
    return http.Response.fromStream(streamed);
  }

  Uri _buildUri(WebDavConnection connection, String path) {
    final base = _baseUri(connection);
    final baseSegments = base.pathSegments.where((item) => item.isNotEmpty);
    final pathSegments = path.split('/').where((item) => item.isNotEmpty);
    final allSegments = [...baseSegments, ...pathSegments];
    // WebDAV 目录请求依赖尾部斜杠，额外空 segment 可让 Uri 保留这个语义。
    if (path.endsWith('/') && allSegments.isNotEmpty) {
      allSegments.add('');
    }
    return base.replace(pathSegments: allSegments);
  }

  Uri _baseUri(WebDavConnection connection) {
    final uri = Uri.parse(connection.normalizedBaseUrl);
    if (!uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('WebDAV 地址必须包含 http(s):// 和主机名');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw const FormatException('WebDAV 地址仅支持 http 或 https');
    }
    return uri;
  }

  String _basicAuth(WebDavConnection connection) {
    final credential = '${connection.username}:${connection.password}';
    return 'Basic ${base64Encode(utf8.encode(credential))}';
  }

  void _ensureSuccess(http.Response response, {required List<int> expected}) {
    if (expected.contains(response.statusCode)) return;
    final body = response.body.trim();
    final suffix = body.isEmpty ? '' : '：$body';
    throw io.HttpException('HTTP ${response.statusCode}$suffix');
  }

  String _normalizeDirectoryPath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty || trimmed == '/') return '/';
    final withoutTrailing = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    return '$withoutTrailing/';
  }

  List<WebDavFileEntry> _parseMultiStatus(
    String xml, {
    required String basePath,
    required String currentPath,
  }) {
    final responses = RegExp(
      r'<(?:\w+:)?response\b[\s\S]*?</(?:\w+:)?response>',
      caseSensitive: false,
    ).allMatches(xml);
    final currentFullPath =
        _stripTrailingSlash(_joinServerPath(basePath, currentPath));
    final entries = <WebDavFileEntry>[];

    for (final match in responses) {
      final block = match.group(0) ?? '';
      final href = _firstTagText(block, 'href');
      if (href == null || href.isEmpty) continue;

      final serverPath =
          _stripTrailingSlash(Uri.decodeFull(Uri.parse(href).path));
      if (serverPath == currentFullPath) continue;

      final relativePath = _serverPathToRemotePath(serverPath, basePath);
      if (relativePath.isEmpty || relativePath == '/') continue;

      final isDirectory = RegExp(
        r'<(?:\w+:)?collection\b',
        caseSensitive: false,
      ).hasMatch(block);
      final size =
          int.tryParse(_firstTagText(block, 'getcontentlength') ?? '') ?? 0;
      final modified =
          _parseHttpDate(_firstTagText(block, 'getlastmodified') ?? '');

      entries.add(WebDavFileEntry(
        name: _lastName(relativePath),
        path: relativePath,
        isDirectory: isDirectory,
        size: size,
        modifiedAt: modified,
      ));
    }

    entries.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return entries;
  }

  String _joinServerPath(String basePath, String remotePath) {
    final left = _stripTrailingSlash(basePath);
    if (remotePath == '/') return left.isEmpty ? '/' : left;
    final right = remotePath.startsWith('/') ? remotePath : '/$remotePath';
    return '$left$right';
  }

  String _serverPathToRemotePath(String serverPath, String basePath) {
    final base = _stripTrailingSlash(basePath);
    if (base.isNotEmpty && serverPath.startsWith('$base/')) {
      return serverPath.substring(base.length);
    }
    if (base.isNotEmpty && serverPath == base) return '/';
    return serverPath.startsWith('/') ? serverPath : '/$serverPath';
  }

  String _stripTrailingSlash(String value) {
    if (value.length <= 1) return value;
    var result = value;
    while (result.length > 1 && result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  String _lastName(String path) {
    final cleaned = _stripTrailingSlash(path);
    final index = cleaned.lastIndexOf('/');
    return index >= 0 ? cleaned.substring(index + 1) : cleaned;
  }

  String? _firstTagText(String xml, String localName) {
    final pattern = RegExp(
      '<(?:\\w+:)?$localName\\b[^>]*>([\\s\\S]*?)</(?:\\w+:)?$localName>',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(xml);
    if (match == null) return null;
    return _decodeXmlEntities((match.group(1) ?? '').trim());
  }

  String _decodeXmlEntities(String value) {
    return value
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&');
  }

  DateTime? _parseHttpDate(String value) {
    if (value.trim().isEmpty) return null;
    try {
      return io.HttpDate.parse(value);
    } catch (_) {
      return DateTime.tryParse(value);
    }
  }

  static const String _propfindBody = '''
<?xml version="1.0" encoding="utf-8" ?>
<d:propfind xmlns:d="DAV:">
  <d:prop>
    <d:resourcetype />
    <d:getcontentlength />
    <d:getlastmodified />
  </d:prop>
</d:propfind>
''';
}
