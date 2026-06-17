// 工具卡片组件（升级版）
// 每个开发工具以毛玻璃卡片展示，包含图标、名称和描述

import 'package:flutter/material.dart';
import '../models/tool_model.dart';
import '../utils/constants.dart';
import 'glass_container.dart';

class ToolCard extends StatelessWidget {
  final ToolModel tool;
  final VoidCallback onTap;

  const ToolCard({
    super.key,
    required this.tool,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.lg),
        borderRadius: AppRadius.xl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 工具 Emoji 图标
            Text(
              tool.icon,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: AppSpacing.sm),
            // 工具名称
            Text(
              tool.name,
              style: const TextStyle(
                fontSize: AppTypography.h3Size,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            // 工具描述
            Text(
              tool.description,
              style: TextStyle(
                fontSize: AppTypography.captionSize,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
