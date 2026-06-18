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

  testWidgets('Base64 工具入口可见并能打开页面', (WidgetTester tester) async {
    await tester.pumpWidget(const JNToolApp());
    await tester.pumpAndSettle();

    // 核心：新增工具必须出现在侧边栏，避免被布局挤出可视区域。
    expect(find.text('Base64 转换'), findsOneWidget);

    await tester.tap(find.text('Base64 转换'));
    await tester.pumpAndSettle();

    // 打开后应显示 Base64 工具页标题和默认文本模式输入区。
    expect(find.text('文本 / 图片 Base64'), findsOneWidget);
    expect(find.text('输入文本'), findsOneWidget);
  });

  testWidgets('Base64 图片编码使用文件选择入口', (WidgetTester tester) async {
    await tester.pumpWidget(const JNToolApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Base64 转换'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('图片'));
    await tester.pumpAndSettle();

    // 核心：图片编码模式不再让用户手输路径，而是展示系统文件选择入口。
    expect(find.text('选择图片'), findsWidgets);
    expect(find.text('支持 PNG、JPG、GIF、WebP、BMP、SVG'), findsOneWidget);
    expect(find.text('输入图片路径'), findsNothing);
  });
}
