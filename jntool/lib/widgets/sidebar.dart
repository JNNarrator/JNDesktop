// 侧边栏导航组件（升级版）
// 带渐变指示条、分组区域和精致感的专业侧边栏

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tool_model.dart';
import '../providers/tool_provider.dart';
import '../utils/constants.dart';
import 'glass_container.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      width: 220,
      borderRadius: AppRadius.xl,
      margin: const EdgeInsets.all(AppSpacing.sm),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Consumer<ToolProvider>(
        builder: (context, provider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- 应用标题 ----------
              _AppHeader(),
              const SizedBox(height: AppSpacing.xs),
              const _SectionDivider(label: 'TOOLS'),
              const SizedBox(height: AppSpacing.xs),
              // ---------- 工具列表 ----------
              if (provider.tools.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔧', style: TextStyle(fontSize: 32)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '等待添加工具...',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: AppTypography.captionSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: provider.tools.length,
                    itemBuilder: (context, index) {
                      final tool = provider.tools[index];
                      final isSelected = provider.currentTool?.id == tool.id;
                      return _SidebarItem(
                        tool: tool,
                        isSelected: isSelected,
                      );
                    },
                  ),
                ),
              // ---------- 底部版本 ----------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: AppTypography.smallSize,
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ========== 应用头部 ==========
class _AppHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Logo 渐变方块
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryStart.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'JT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'JNTool',
                style: TextStyle(
                  fontSize: AppTypography.h3Size,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '开发工具百宝箱',
                style: TextStyle(
                  fontSize: AppTypography.smallSize,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ========== 区域分隔线 ==========
class _SectionDivider extends StatelessWidget {
  final String label;

  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.smallSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.glassBorder,
            ),
          ),
        ],
      ),
    );
  }
}

// ========== 侧边栏单项 ==========
class _SidebarItem extends StatelessWidget {
  final ToolModel tool;
  final bool isSelected;

  const _SidebarItem({
    required this.tool,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ToolProvider>();
    return GestureDetector(
      onTap: () => provider.selectTool(tool.id),
      child: AnimatedContainer(
        duration: AppAnimations.normal,
        curve: AppAnimations.defaultCurve,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.glassWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: isSelected
              ? Border.all(
                  color: AppColors.primaryStart.withValues(alpha: 0.2),
                  width: 0.8,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryStart.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Emoji 图标
            Text(tool.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: AppSpacing.sm),
            // 名称
            Text(
              tool.name,
              style: TextStyle(
                fontSize: AppTypography.bodySize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            // 选中小圆点指示器
            AnimatedOpacity(
              duration: AppAnimations.normal,
              opacity: isSelected ? 1.0 : 0.0,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryStart.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
