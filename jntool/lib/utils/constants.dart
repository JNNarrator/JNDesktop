// 应用常量配置 —— 设计系统 Token
// 统一管理颜色、尺寸、动画时长等设计 Token

import 'package:flutter/material.dart';

// ========== 设计系统：颜色 ==========
class AppColors {
  // 主色调 —— 紫靛蓝渐变，适合开发者工具的专业感 + 活力
  static const Color primaryStart = Color(0xFF6366F1);  // Indigo-500
  static const Color primaryMid   = Color(0xFF8B5CF6);  // Violet-500
  static const Color primaryEnd   = Color(0xFFA78BFA);  // Violet-400

  // 强调色
  static const Color accentPink   = Color(0xFFF472B6);  // Pink-400
  static const Color accentTeal   = Color(0xFF14B8A6);  // Teal-500
  static const Color accentAmber  = Color(0xFFFBBF24);  // Amber-400
  static const Color accentRose   = Color(0xFFFB7185);  // Rose-400

  // 毛玻璃色
  static const Color glassWhite   = Color(0xE6FFFFFF);  // 90% 白
  static const Color glassBorder  = Color(0x66FFFFFF);  // 40% 白边框
  static const Color glassShadow  = Color(0x1A000000);  // 10% 黑阴影
  static const Color glassDark    = Color(0xCC1E1B4B);  // 深色玻璃（80%）

  // 背景
  static const Color bgLight      = Color(0xFFF5F3FF);  // Indigo-50
  static const Color bgCard       = Color(0xFFFFF0F5);  // Pink-50
  static const Color bgSurface    = Color(0xFFFAFAFA);  // 浅灰表面

  // 文字
  static const Color textPrimary  = Color(0xFF1E1B4B);  // Indigo-950
  static const Color textSecondary= Color(0xFF6B7280);  // Gray-500
  static const Color textMuted    = Color(0xFF9CA3AF);  // Gray-400
  static const Color textInverse  = Color(0xFFFFF7ED);  // 浅暖白

  // 边框
  static const Color borderLight  = Color(0xFFE5E7EB);  // Gray-200
  static const Color borderFocus  = Color(0xFF6366F1);  // Indigo-500
}

// ========== 设计系统：字阶 ==========
class AppTypography {
  static const String fontFamily   = '';
  static const double displaySize  = 32.0;
  static const double h1Size       = 24.0;
  static const double h2Size       = 20.0;
  static const double h3Size       = 16.0;
  static const double bodySize     = 14.0;
  static const double captionSize  = 12.0;
  static const double smallSize    = 11.0;
}

// ========== 设计系统：间距 (4px 基准) ==========
class AppSpacing {
  static const double xxs  = 2.0;
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xxl  = 24.0;
  static const double xxxl = 32.0;
}

// ========== 设计系统：圆角 ==========
class AppRadius {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 20.0;
  static const double xxl = 24.0;
}

// ========== 设计系统：动画 ==========
class AppAnimations {
  static const Duration fast   = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow   = Duration(milliseconds: 350);
  static const Curve  defaultCurve = Curves.easeInOutCubic;

  // 弹性动效曲线
  static const Curve springCurve = Curves.fastEaseInToSlowEaseOut;
}

// ========== 设计系统：阴影 ==========
class AppShadows {
  // 浅层阴影
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  // 中层阴影
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  // 弹窗阴影
  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
}

// ========== 设计系统：渐变 ==========
class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primaryStart, AppColors.primaryEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sidebarBg = LinearGradient(
    colors: [
      Color(0xFFEEF2FF), // Indigo-50
      Color(0xFFFAF5FF), // Violet-50
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient welcomeBg = LinearGradient(
    colors: [
      Color(0xFFF5F3FF), // Indigo-50
      Color(0xFFFFF0F5), // Pink-50
      Color(0xFFECFDF5), // Emerald-50
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassHighlight = LinearGradient(
    colors: [
      Color(0x99FFFFFF),
      Color(0x33FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}


// ========== 设计系统：代码展示样式 ==========
class CodeStyle {
  /// 代码编辑器/展示器的输入框装饰
  static InputDecoration inputDecoration({Color? fillColor}) {
    return InputDecoration(
      border: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      filled: true,
      fillColor: fillColor ?? const Color(0xFFFAFAFA),
    );
  }

  /// 代码输入字体样式
  static const TextStyle inputText = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    height: 1.6,
    color: AppColors.textPrimary,
  );

  /// 代码结果展示字体样式
  static const TextStyle outputText = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    height: 1.7,
    color: AppColors.textPrimary,
  );

  /// 小型代码标签样式
  static const TextStyle badgeText = TextStyle(
    fontFamily: 'monospace',
    fontSize: 10,
    height: 1.3,
    fontWeight: FontWeight.w500,
  );
}

