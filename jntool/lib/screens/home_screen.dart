// 主界面（升级版）
// 左侧导航 + 右侧内容区，使用 IndexedStack 保留各工具状态

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tool_provider.dart';
import '../tools/json_tool/json_tool_screen.dart';
import '../tools/curl_tool/curl_tool_screen.dart';
import '../tools/bean_tool/bean_tool_screen.dart';
import '../tools/cron_tool/cron_tool_screen.dart';
import '../tools/config_tool/config_tool_screen.dart';
import '../tools/base64_tool/base64_tool_screen.dart';
import '../tools/webdav_tool/webdav_tool_screen.dart';
import '../utils/constants.dart';
import '../widgets/sidebar.dart';
import '../widgets/glass_container.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 所有可用工具的 ID 列表（按顺序）
  static const List<String> _toolIds = [
    'json_tool',
    'curl_tool',
    'bean_tool',
    'cron_tool',
    'config_tool',
    'base64_tool',
    'webdav_tool',
  ];

  // 预创建所有工具页面实例（保持状态）
  late final List<Widget> _toolPages;

  @override
  void initState() {
    super.initState();
    _toolPages = const [
      JsonToolScreen(),
      CurlToolScreen(),
      BeanToolScreen(),
      CronToolScreen(),
      ConfigToolScreen(),
      Base64ToolScreen(),
      WebDavToolScreen(),
    ];
  }

  /// 根据 toolId 获取在 _toolPages 中的索引
  int _getToolIndex(String? toolId) {
    if (toolId == null) return -1;
    final idx = _toolIds.indexOf(toolId);
    return idx >= 0 ? idx : -1;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ToolProvider>(
      builder: (context, provider, _) {
        final tool = provider.currentTool;
        final toolIndex = _getToolIndex(tool?.id);

        return Row(
          children: [
            // 左侧侧边栏导航
            const Sidebar(),
            const SizedBox(width: 4),
            // 右侧主内容区
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: toolIndex >= 0
                    ? IndexedStack(
                        index: toolIndex,
                        children: _toolPages,
                      )
                    : const _WelcomeScreen(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ========== 欢迎页面 ==========
class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen();

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: AppRadius.xl,
      padding: EdgeInsets.zero,
      gradient: AppGradients.welcomeBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryStart.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🧰', style: TextStyle(fontSize: 44)),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Text(
              'JNTool',
              style: TextStyle(
                fontSize: AppTypography.displaySize,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '你的开发工具百宝箱',
              style: TextStyle(
                fontSize: AppTypography.h2Size,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FeatureHint(icon: '🚀', text: '快速启动', sub: '即开即用'),
                const SizedBox(width: AppSpacing.md),
                _FeatureHint(icon: '🎨', text: '精心设计', sub: '舒适体验'),
                const SizedBox(width: AppSpacing.md),
                _FeatureHint(icon: '🔌', text: '持续扩展', sub: '工具不断'),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl + AppSpacing.sm),
            Text(
              '从左侧选择一个工具开始使用吧 ✨',
              style: TextStyle(
                fontSize: AppTypography.bodySize,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== 功能提示小卡片 ==========
class _FeatureHint extends StatelessWidget {
  final String icon;
  final String text;
  final String sub;

  const _FeatureHint({
    required this.icon,
    required this.text,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      borderRadius: AppRadius.lg,
      width: 120,
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            text,
            style: const TextStyle(
              fontSize: AppTypography.bodySize,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              fontSize: AppTypography.captionSize,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
