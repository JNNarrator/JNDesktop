import 'package:flutter_test/flutter_test.dart';
import 'package:jntool/tools/cron_tool/cron_expression.dart';

void main() {
  group('CronExpression', () {
    test('校验 Spring Boot 6 段表达式', () {
      final result = CronExpression.validate('0 0/5 * * * ?');

      expect(result.isValid, isTrue);
      expect(result.error, isNull);
    });

    test('拒绝非 Spring Boot 6 段表达式', () {
      final result = CronExpression.validate('*/5 * * * *');

      expect(result.isValid, isFalse);
      expect(result.error, contains('6 段'));
    });

    test('支持英文月份和星期', () {
      final cron = CronExpression.parse('0 30 9 ? JAN MON');
      final next = cron.nextTimes(DateTime(2026, 1, 1), count: 1);

      expect(next.single, DateTime(2026, 1, 5, 9, 30));
    });

    test('计算最近五次执行时间', () {
      final cron = CronExpression.parse('0 */15 9-10 * * ?');
      final next = cron.nextTimes(DateTime(2026, 6, 18, 9, 7, 10));

      expect(next, [
        DateTime(2026, 6, 18, 9, 15),
        DateTime(2026, 6, 18, 9, 30),
        DateTime(2026, 6, 18, 9, 45),
        DateTime(2026, 6, 18, 10, 0),
        DateTime(2026, 6, 18, 10, 15),
      ]);
    });

    test('日期和星期都指定时满足任一条件', () {
      final cron = CronExpression.parse('0 0 8 15 * MON');
      final next = cron.nextTimes(DateTime(2026, 6, 14, 8), count: 2);

      expect(next, [
        DateTime(2026, 6, 15, 8),
        DateTime(2026, 6, 22, 8),
      ]);
    });

    test('拒绝暂不支持的 Quartz 高级语法', () {
      final result = CronExpression.validate('0 0 9 ? * MON#1');

      expect(result.isValid, isFalse);
      expect(result.error, contains('暂不支持'));
    });
  });
}
