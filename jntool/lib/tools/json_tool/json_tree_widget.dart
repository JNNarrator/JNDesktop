// JSON 工具 —— 树形展示组件
// 可折叠/展开的 JSON 树形视图，每个节点显示类型标签 + 键 + 值

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'json_models.dart';

/// JSON 树形展示组件
class JsonTreeWidget extends StatelessWidget {
  final JsonTreeNode root;

  const JsonTreeWidget({super.key, required this.root});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _TreeNodeTile(
          node: root,
          depth: 0,
          isLastChild: true,
        ),
      ],
    );
  }
}

/// 树形节点单项（可折叠展开）
class _TreeNodeTile extends StatefulWidget {
  final JsonTreeNode node;
  final int depth;
  final bool isLastChild;

  const _TreeNodeTile({
    required this.node,
    required this.depth,
    required this.isLastChild,
  });

  @override
  State<_TreeNodeTile> createState() => _TreeNodeTileState();
}

class _TreeNodeTileState extends State<_TreeNodeTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.node.isExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    if (_isExpanded) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_TreeNodeTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.isExpanded != widget.node.isExpanded) {
      _toggleExpanded();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      widget.node.isExpanded = _isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  bool get _isExpandable =>
      widget.node.type == JsonNodeType.object ||
      widget.node.type == JsonNodeType.array;

  @override
  Widget build(BuildContext context) {
    final isLeaf = !_isExpandable;
    final children = widget.node.children;
    final hasChildren = children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ----- 当前节点行 -----
        Padding(
          padding: EdgeInsets.only(left: widget.depth * 20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 展开/折叠箭头（对 object/array 有效）
              if (isLeaf)
                const SizedBox(width: 20)
              else
                GestureDetector(
                  onTap: hasChildren ? _toggleExpanded : null,
                  child: AnimatedRotation(
                    turns: _isExpanded ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: hasChildren
                            ? AppColors.textSecondary
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              // 类型标签
              _TypeBadge(type: widget.node.type),
              const SizedBox(width: 6),
              // 键名（非 root 且非数组索引时显示）
              if (widget.node.key != null && widget.node.key != 'root' && !_isArrayKey(widget.node.key!))
                Text(
                  '${widget.node.key}: ',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryStart,
                    fontFamily: 'monospace',
                  ),
                ),
              // 值（叶子节点显示值，容器节点显示概要）
              if (isLeaf)
                Flexible(
                  child: Text(
                    widget.node.valuePreview,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: _valueColor(widget.node.type),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                Text(
                  widget.node.displayValue,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
        ),
        // ----- 子节点（可折叠动画） -----
        if (_isExpandable && hasChildren)
          SizeTransition(
            sizeFactor: _expandAnimation,
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: children.map((child) {
                return _TreeNodeTile(
                  node: child,
                  depth: widget.depth + 1,
                  isLastChild: child == children.last,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  /// 判断是否为数组索引键 [0]、[1] 等
  bool _isArrayKey(String key) {
    return key.startsWith('[') && key.endsWith(']');
  }

  /// 根据类型返回值的文字颜色
  Color _valueColor(JsonNodeType type) {
    switch (type) {
      case JsonNodeType.string:
        return const Color(0xFF059669); // Emerald-600
      case JsonNodeType.number:
        return const Color(0xFF2563EB); // Blue-600
      case JsonNodeType.boolean:
        return const Color(0xFFD97706); // Amber-600
      case JsonNodeType.nullValue:
        return AppColors.textMuted;
      default:
        return AppColors.textPrimary;
    }
  }
}

/// 类型标签小徽章
class _TypeBadge extends StatelessWidget {
  final JsonNodeType type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _badgeInfo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          fontFamily: 'monospace',
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  (String, Color) get _badgeInfo {
    switch (type) {
      case JsonNodeType.object:
        return ('{}', const Color(0xFF8B5CF6)); // Violet-500
      case JsonNodeType.array:
        return ('[]', const Color(0xFF3B82F6)); // Blue-500
      case JsonNodeType.string:
        return ('s', const Color(0xFF059669)); // Emerald-600
      case JsonNodeType.number:
        return ('n', const Color(0xFF2563EB)); // Blue-600
      case JsonNodeType.boolean:
        return ('b', const Color(0xFFD97706)); // Amber-600
      case JsonNodeType.nullValue:
        return ('∅', AppColors.textMuted);
    }
  }
}
