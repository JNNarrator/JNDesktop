// 应用主组件
// 配置全局主题、渐变背景，初始化并注册所有工具

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/tool_model.dart';
import 'providers/tool_provider.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';

class JNToolApp extends StatelessWidget {
  const JNToolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = ToolProvider();
        // ========== 注册内置工具 ==========
        provider.registerTool(const ToolModel(
          id: 'json_tool',
          name: 'JSON 工具',
          icon: '🔍',
          color: '#8B5CF6',
          description: 'JSON 格式化、校验与树形展示',
          route: '/tools/json',
        ));
        provider.registerTool(const ToolModel(
          id: 'curl_tool',
          name: 'Curl 请求',
          icon: '🌐',
          color: '#14B8A6',
          description: '解析 curl 命令并发起 HTTP 请求',
          route: '/tools/curl',
        ));
        provider.registerTool(const ToolModel(
          id: 'bean_tool',
          name: 'Bean 转换',
          icon: '🫘',
          color: '#F59E0B',
          description: 'JSON ↔ Java Bean 互相转换',
          route: '/tools/bean',
        ));
        provider.registerTool(const ToolModel(
          id: 'cron_tool',
          name: 'Cron 生成',
          icon: '⏰',
          color: '#6366F1',
          description: 'Spring Boot cron 生成与执行时间预览',
          route: '/tools/cron',
        ));
        provider.registerTool(const ToolModel(
          id: 'config_tool',
          name: '配置转换',
          icon: '⚙️',
          color: '#0EA5E9',
          description: 'Spring Boot YAML 与 properties 互相转换',
          route: '/tools/config',
        ));
        return provider;
      },
      child: MaterialApp(
        title: 'JNTool',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryStart,
            brightness: Brightness.light,
          ),
          fontFamily: AppTypography.fontFamily,
          scaffoldBackgroundColor: Colors.transparent,
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            color: AppColors.glassWhite,
          ),
          dividerTheme: DividerThemeData(
            color: AppColors.glassBorder,
            thickness: 1,
            space: AppSpacing.md,
          ),
        ),
        home: const _AppBackground(child: HomeScreen()),
      ),
    );
  }
}

// ========== 应用渐变背景 ==========
class _AppBackground extends StatelessWidget {
  final Widget child;

  const _AppBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.3, -0.3),
          end: Alignment(0.8, 0.8),
          colors: [
            Color(0xFFEEF2FF),
            Color(0xFFFAF5FF),
            Color(0xFFFFF0F5),
            Color(0xFFF0FDF4),
          ],
          stops: [0.0, 0.3, 0.6, 1.0],
        ),
      ),
      child: Material(
        // 为各工具页中的 TextField、InkWell 等 Material 组件提供透明承载层。
        type: MaterialType.transparency,
        child: SafeArea(
          child: child,
        ),
      ),
    );
  }
}
