import 'package:flutter_test/flutter_test.dart';
import 'package:jntool/tools/config_tool/config_converter.dart';

void main() {
  group('ConfigConverter', () {
    test('properties 转 YAML 支持 Spring Boot 常见嵌套配置', () {
      final yaml = ConfigConverter.propertiesToYaml('''
spring.application.name=demo-service
spring.datasource.url=jdbc:mysql://localhost:3306/demo
spring.datasource.username=root
server.port=8080
management.endpoints.web.exposure.include=health,info
''');

      expect(yaml, contains('spring:'));
      expect(yaml, contains('application:'));
      expect(yaml, contains('name: demo-service'));
      expect(yaml, contains("url: 'jdbc:mysql://localhost:3306/demo'"));
      expect(yaml, contains('server:'));
      expect(yaml, contains('port: 8080'));
    });

    test('YAML 转 properties 支持嵌套配置', () {
      final properties = ConfigConverter.yamlToProperties('''
spring:
  application:
    name: demo-service
  datasource:
    url: 'jdbc:mysql://localhost:3306/demo'
    username: root
server:
  port: 8080
''');

      expect(properties, contains('spring.application.name=demo-service'));
      expect(
        properties,
        contains('spring.datasource.url=jdbc:mysql://localhost:3306/demo'),
      );
      expect(properties, contains('spring.datasource.username=root'));
      expect(properties, contains('server.port=8080'));
    });

    test('properties 列表下标可转为 YAML 列表', () {
      final yaml = ConfigConverter.propertiesToYaml('''
app.servers[0].host=localhost
app.servers[0].port=8080
app.servers[1].host=example.com
app.servers[1].port=9090
''');

      expect(yaml, contains('servers:'));
      expect(yaml, contains('-'));
      expect(yaml, contains('host: localhost'));
      expect(yaml, contains('port: 9090'));
    });

    test('YAML 列表对象可转为 properties 下标', () {
      final properties = ConfigConverter.yamlToProperties('''
app:
  servers:
    - host: localhost
      port: 8080
    - host: example.com
      port: 9090
''');

      expect(properties, contains('app.servers[0].host=localhost'));
      expect(properties, contains('app.servers[0].port=8080'));
      expect(properties, contains('app.servers[1].host=example.com'));
      expect(properties, contains('app.servers[1].port=9090'));
    });
  });
}
