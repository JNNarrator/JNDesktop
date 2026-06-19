// WebDAV 连接本地持久化。
// 当前按用户要求保存到本地 JSON 文件，不做云同步或加密。

import 'dart:convert';
import 'dart:io';

import 'webdav_models.dart';

class WebDavConnectionStorage {
  final File file;

  WebDavConnectionStorage({File? file}) : file = file ?? _defaultFile();

  static File _defaultFile() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.current.path;
    return File('$home/.jntool/webdav_connections.json');
  }

  Future<List<WebDavConnection>> loadConnections() async {
    if (!await file.exists()) return [];

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('WebDAV 连接配置不是列表');
    }

    return decoded
        .whereType<Map>()
        .map((item) =>
            WebDavConnection.fromJson(Map<String, dynamic>.from(item)))
        .where((connection) => connection.id.trim().isNotEmpty)
        .toList();
  }

  Future<void> saveConnections(List<WebDavConnection> connections) async {
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(
      encoder.convert(connections.map((item) => item.toJson()).toList()),
    );
  }
}
