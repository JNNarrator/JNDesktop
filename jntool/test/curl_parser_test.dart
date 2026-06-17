import 'package:flutter_test/flutter_test.dart';
import 'package:jntool/tools/curl_tool/curl_parser.dart';

void main() {
  test('解析简单 curl 命令', () {
    final result = CurlParser.parse("curl 'https://httpbin.org/get' -H 'User-Agent: JNTool/1.0'");
    expect(result, isNotNull);
    expect(result!.url, 'https://httpbin.org/get');
    expect(result.headers['User-Agent'], 'JNTool/1.0');
    expect(result.method, 'GET');
  });

  test('解析带换行的 curl 命令', () {
    final result = CurlParser.parse("curl 'https://httpbin.org/get' \\\n  -H 'User-Agent: JNTool/1.0'");
    expect(result, isNotNull);
    expect(result!.url, 'https://httpbin.org/get');
    expect(result.headers['User-Agent'], 'JNTool/1.0');
  });

  test('解析 POST 请求', () {
    final result = CurlParser.parse("curl -X POST 'https://httpbin.org/post' -H 'Content-Type: application/json' -d '{\"key\":\"value\"}'");
    expect(result, isNotNull);
    expect(result!.url, 'https://httpbin.org/post');
    expect(result.method, 'POST');
    expect(result.body, '{"key":"value"}');
    expect(result.headers['Content-Type'], 'application/json');
  });
}
