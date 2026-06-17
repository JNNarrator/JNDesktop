// Curl 工具 —— HTTP 请求引擎
// 基于 http 包（NSURLSession），兼容 macOS Sandbox 出站网络连接

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'curl_parser.dart';

/// HTTP 响应内容类型
enum ResponseContentType {
  json,
  html,
  text,
  xml,
  binary,
}

/// 响应结果
class HttpResponse {
  final int statusCode;
  final String statusMessage;
  final Map<String, String> headers;
  final Uint8List rawBody;
  final String textBody;
  final ResponseContentType contentType;
  final Duration elapsed;
  final String? error;

  HttpResponse({
    required this.statusCode,
    required this.statusMessage,
    required this.headers,
    required this.rawBody,
    required this.textBody,
    required this.contentType,
    required this.elapsed,
    this.error,
  });

  bool get isJson => contentType == ResponseContentType.json;

  String get sizeLabel {
    final bytes = rawBody.length;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// HTTP 请求引擎（基于 http 包）
class HttpEngine {
  /// 发送 HTTP 请求
  static Future<HttpResponse> send(CurlRequest request) async {
    final stopwatch = Stopwatch()..start();

    try {
      final uri = Uri.parse(request.url);
      final headers = Map<String, String>.from(request.headers);
      final method = request.method.toUpperCase();

      http.Response response;

      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: request.body);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: request.body);
          break;
        case 'PATCH':
          response = await http.patch(uri, headers: headers, body: request.body);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers, body: request.body);
          break;
        case 'HEAD':
          response = await http.head(uri, headers: headers);
          break;
        default:
          // OPTIONS 等：使用 GET 兜底
          response = await http.get(uri, headers: headers);
      }

      stopwatch.stop();

      final rawBody = Uint8List.fromList(response.bodyBytes);
      final textBody = response.body;
      final statusCode = response.statusCode;

      // 判断内容类型
      final contentTypeHeader = response.headers['content-type'] ?? '';
      final responseContentType = _detectContentType(contentTypeHeader, rawBody);

      return HttpResponse(
        statusCode: statusCode,
        statusMessage: _statusMessage(statusCode),
        headers: response.headers,
        rawBody: rawBody,
        textBody: textBody,
        contentType: responseContentType,
        elapsed: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return HttpResponse(
        statusCode: 0,
        statusMessage: 'Error',
        headers: {},
        rawBody: Uint8List(0),
        textBody: '',
        contentType: ResponseContentType.text,
        elapsed: stopwatch.elapsed,
        error: e.toString(),
      );
    }
  }

  static String _statusMessage(int code) {
    // 常见状态码消息
    const messages = {
      200: 'OK', 201: 'Created', 204: 'No Content',
      301: 'Moved Permanently', 302: 'Found', 304: 'Not Modified',
      400: 'Bad Request', 401: 'Unauthorized', 403: 'Forbidden',
      404: 'Not Found', 405: 'Method Not Allowed', 408: 'Request Timeout',
      429: 'Too Many Requests',
      500: 'Internal Server Error', 502: 'Bad Gateway',
      503: 'Service Unavailable', 504: 'Gateway Timeout',
    };
    return messages[code] ?? '';
  }

  static ResponseContentType _detectContentType(
    String contentTypeHeader, Uint8List rawBody) {
    final lower = contentTypeHeader.toLowerCase();

    if (lower.contains('application/json') ||
        lower.contains('application/vnd.api+json')) {
      return ResponseContentType.json;
    }
    if (lower.contains('text/html')) {
      return ResponseContentType.html;
    }
    if (lower.contains('application/xml') || lower.contains('text/xml')) {
      return ResponseContentType.xml;
    }
    if (lower.contains('text/')) {
      return ResponseContentType.text;
    }

    if (rawBody.isEmpty) return ResponseContentType.text;

    try {
      final text = utf8.decode(rawBody);
      final trimmed = text.trim();
      if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
        json.decode(trimmed);
        return ResponseContentType.json;
      }
      if (trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html') ||
          trimmed.startsWith('<!doctype')) {
        return ResponseContentType.html;
      }
      if (trimmed.startsWith('<?xml')) {
        return ResponseContentType.xml;
      }
      return ResponseContentType.text;
    } catch (_) {
      return ResponseContentType.binary;
    }
  }
}
