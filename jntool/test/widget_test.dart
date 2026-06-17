import 'package:flutter_test/flutter_test.dart';
import 'package:jntool/app.dart';

void main() {
  testWidgets('JNTool 应用启动测试', (WidgetTester tester) async {
    await tester.pumpWidget(const JNToolApp());
    await tester.pumpAndSettle();

    // 验证应用标题显示
    expect(find.text('JNTool'), findsWidgets);
    // 验证侧边栏版本号
    expect(find.text('v1.0.0'), findsOneWidget);
  });
}
