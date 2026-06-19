import 'package:flutter_test/flutter_test.dart';
import 'package:jntool/app.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const JNToolApp());
    // 核心：部分页面会做异步本地初始化，定量推进比等待所有动画静止更稳定。
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('JNTool 应用启动测试', (WidgetTester tester) async {
    await pumpApp(tester);

    // 验证应用标题显示
    expect(find.text('JNTool'), findsWidgets);
    // 验证侧边栏版本号
    expect(find.text('v1.0.0'), findsOneWidget);
  });

  testWidgets('Base64 工具入口可见并能打开页面', (WidgetTester tester) async {
    await pumpApp(tester);

    // 核心：新增工具必须出现在侧边栏，避免被布局挤出可视区域。
    expect(find.text('Base64 转换'), findsOneWidget);

    await tester.tap(find.text('Base64 转换'));
    await tester.pump(const Duration(milliseconds: 300));

    // 打开后应显示 Base64 工具页标题和默认文本模式输入区。
    expect(find.text('文本 / 图片 Base64'), findsOneWidget);
    expect(find.text('输入文本'), findsOneWidget);
  });

  testWidgets('Base64 图片编码使用文件选择入口', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Base64 转换'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('图片'));
    await tester.pump(const Duration(milliseconds: 300));

    // 核心：图片编码模式不再让用户手输路径，而是展示系统文件选择入口。
    expect(find.text('选择图片'), findsWidgets);
    expect(find.text('支持 PNG、JPG、GIF、WebP、BMP、SVG'), findsOneWidget);
    expect(find.text('输入图片路径'), findsNothing);
  });

  testWidgets('WebDAV 管理工具入口可见并能打开页面', (WidgetTester tester) async {
    await pumpApp(tester);

    // 核心：WebDAV 管理必须注册到侧边栏，方便从工具箱直接进入。
    expect(find.text('WebDAV 管理'), findsOneWidget);

    await tester.tap(find.text('WebDAV 管理'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('WebDAV 文件管理'), findsOneWidget);
    expect(find.text('连接信息保存到本地'), findsOneWidget);
  });
}
