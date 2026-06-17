// JSON 工具 —— 主界面
// 左侧：输入 + 格式化内联展示
// 右侧：纯树形展示（可折叠展开）

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_container.dart';
import 'json_models.dart';
import 'json_tree_widget.dart';

class JsonToolScreen extends StatefulWidget {
  const JsonToolScreen({super.key});

  @override
  State<JsonToolScreen> createState() => _JsonToolScreenState();
}

class _JsonToolScreenState extends State<JsonToolScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  JsonTreeNode? _rootNode;
  String? _errorMessage;
  bool _hasProcessed = false;

  /// 格式化左侧输入框内容，并同步构建右侧树形
  void _processJson() {
    final raw = _inputController.text;
    if (raw.trim().isEmpty) {
      setState(() {
        _rootNode = null;
        _errorMessage = null;
        _hasProcessed = false;
      });
      return;
    }

    // 1. 校验 JSON
    final error = JsonFormatter.validate(raw);
    if (error != null) {
      setState(() {
        _rootNode = null;
        _errorMessage = error;
        _hasProcessed = true;
      });
      return;
    }

    // 2. 格式化输入框内容（内联展示）
    final formatted = JsonFormatter.format(raw);
    _inputController.text = formatted;
    _inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: formatted.length),
    );

    // 3. 构建树形节点
    final root = JsonTreeBuilder.fromString(raw);

    setState(() {
      _rootNode = root;
      _errorMessage = null;
      _hasProcessed = true;
    });
  }

  void _loadSample() {
    const sample = '''
{
  "name": "JNTool",
  "version": "1.0.0",
  "description": "开发者工具箱",
  "features": [
    "JSON 格式化",
    "Base64 编码",
    "时间戳转换"
  ],
  "config": {
    "theme": "light",
    "fontSize": 14,
    "debug": false,
    "limits": null
  }
}''';
    _inputController.text = sample.trim();
    _processJson();
  }

  void _clearAll() {
    _inputController.clear();
    setState(() {
      _rootNode = null;
      _errorMessage = null;
      _hasProcessed = false;
    });
    _inputFocus.requestFocus();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.md),
      height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----- 顶部工具栏 -----
          _buildToolbar(),
          const SizedBox(height: AppSpacing.md),
          // ----- 左右分栏 -----
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildEditorPanel()),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _buildTreePanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 顶部工具栏
  Widget _buildToolbar() {
    return Row(
      children: [
        const Text(
          '🔍 JSON 格式化',
          style: TextStyle(
            fontSize: AppTypography.h2Size,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        _ToolbarBtn(icon: Icons.auto_fix_high, label: '示例', onTap: _loadSample),
        const SizedBox(width: AppSpacing.sm),
        _ToolbarBtn(icon: Icons.delete_outline, label: '清空', onTap: _clearAll),
        const SizedBox(width: AppSpacing.sm),
        // 格式化主按钮
        Container(
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _processJson,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 4),
                    Text(
                      '格式化',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 左侧编辑器面板
  Widget _buildEditorPanel() {
    return Material(
      color: AppColors.glassWhite,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.glassBorder, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '📝 输入 & 格式化',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_inputController.text.length} chars',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocus,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: '在此粘贴 JSON，然后点击「格式化」...',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: Color(0xFFFAFAFA),
                ),
                onChanged: (_) {
                  if (_hasProcessed) {
                    setState(() {
                      if (_errorMessage != null) _errorMessage = null;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 右侧树形面板
  Widget _buildTreePanel() {
    return GlassContainer(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.sm),
      height: double.infinity,
      gradient: const LinearGradient(
        colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '🌳 树形视图',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (_rootNode != null)
                Text(
                  '${_countNodes(_rootNode!)} nodes',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _buildTreeContent()),
        ],
      ),
    );
  }

  int _countNodes(JsonTreeNode node) {
    int count = 1;
    for (final child in node.children) {
      count += _countNodes(child);
    }
    return count;
  }

  Widget _buildTreeContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('❌', style: TextStyle(fontSize: 32)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'JSON 解析错误',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.accentRose,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    if (_rootNode == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌳', style: TextStyle(fontSize: 40)),
            const SizedBox(height: AppSpacing.md),
            const Text(
              '在左侧输入并格式化后\n树形将在此展示',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '点击「示例」试试吧 ✨',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return JsonTreeWidget(root: _rootNode!);
  }
}

// ========== 工具栏按钮 ==========
class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
