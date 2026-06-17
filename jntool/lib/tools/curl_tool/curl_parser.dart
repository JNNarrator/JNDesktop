// Curl 工具 —— 命令行解析引擎
// 将 curl 命令字符串解析为 URL、请求头、请求方法等结构化数据

import 'dart:convert';

// 解析后的 curl 请求结构
class CurlRequest {
  final String url;
  final String method;
  final Map<String, String> headers;
  final String? body;
  final String rawCommand;

  const CurlRequest({
    required this.url,
    this.method = 'GET',
    this.headers = const {},
    this.body,
    required this.rawCommand,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'method': method,
    'headers': headers,
    'body': body,
  };
}

/// curl 命令解析器
class CurlParser {
  /// 解析 curl 命令字符串，返回 CurlRequest
  static CurlRequest? parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // 去掉开头的 "curl " 前缀
    String cmd = trimmed;
    if (cmd.toLowerCase().startsWith('curl ')) {
      cmd = cmd.substring(5).trim();
    }
    if (cmd.isEmpty) return null;

    final tokens = _tokenize(cmd);
    if (tokens.isEmpty) return null;

    String? url;
    String method = 'GET';
    String? body;
    final headers = <String, String>{};

    int i = 0;
    while (i < tokens.length) {
      final token = tokens[i];

      if (token == '-H' || token == '--header') {
        i++;
        if (i < tokens.length) {
          final headerStr = tokens[i];
          final colonIdx = headerStr.indexOf(':');
          if (colonIdx > 0) {
            final name = headerStr.substring(0, colonIdx).trim();
            var value = '';
            if (colonIdx + 1 < headerStr.length) {
              value = headerStr.substring(colonIdx + 1).trim();
            }
            if (name.isNotEmpty) {
              headers[name] = value;
            }
          }
        }
      } else if (token == '-X' || token == '--request') {
        i++;
        if (i < tokens.length) {
          method = tokens[i].toUpperCase();
        }
      } else if (token == '-d' || token == '--data' || token == '--data-raw') {
        i++;
        if (i < tokens.length) {
          body = tokens[i];
        }
      } else if (token == '--data-binary') {
        i++;
        if (i < tokens.length) {
          final dataVal = tokens[i];
          if (!dataVal.startsWith('@')) {
            body = dataVal;
          }
        }
      } else if (token == '-u' || token == '--user') {
        i++;
        if (i < tokens.length) {
          final credentials = tokens[i];
          final encoded = base64Encode(utf8.encode(credentials));
          headers['Authorization'] = 'Basic $encoded';
        }
      } else if (token == '-b' || token == '--cookie') {
        i++;
        if (i < tokens.length) {
          headers['Cookie'] = tokens[i];
        }
      } else if (token.startsWith('--compressed')) {
        // 支持压缩响应
      } else if (token.startsWith('--insecure') || token.startsWith('-k')) {
        // 跳过 SSL 验证
      } else if (token.startsWith('-')) {
        // 其他未知选项，如果下一个 token 不以 - 开头可能是值
        if (i + 1 < tokens.length && !tokens[i + 1].startsWith('-')) {
          i++;
        }
      } else {
        // 非选项 token -> URL
        url ??= token;
      }
      i++;
    }

    if (url == null) return null;

    // 自动检测 POST（有 body 但没指定 -X）
    if (body != null && method == 'GET') {
      method = 'POST';
      if (!headers.keys.any((k) => k.toLowerCase() == 'content-type')) {
        headers['Content-Type'] = 'application/x-www-form-urlencoded';
      }
    }

    return CurlRequest(
      url: url,
      method: method,
      headers: headers,
      body: body,
      rawCommand: input,
    );
  }

  /// 简易 tokenizer，支持单引号和双引号字符串
  static List<String> _tokenize(String input) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    bool inSingleQuote = false;
    bool inDoubleQuote = false;
    bool escape = false;

    for (var i = 0; i < input.length; i++) {
      final ch = input[i];

      if (escape) {
        buffer.write(ch);
        escape = false;
        continue;
      }

      if (ch == '\\' && inDoubleQuote) {
        escape = true;
        continue;
      }

      if (ch == "'" && !inDoubleQuote) {
        inSingleQuote = !inSingleQuote;
        continue;
      }

      if (ch == '"' && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
        continue;
      }

      if (ch == ' ' && !inSingleQuote && !inDoubleQuote) {
        final token = buffer.toString().trim();
        if (token.isNotEmpty) tokens.add(token);
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }

    final lastToken = buffer.toString().trim();
    if (lastToken.isNotEmpty) tokens.add(lastToken);

    return tokens;
  }
}
