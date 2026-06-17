// 工具状态管理 Provider
// 管理工具栏注册、选中状态，后续扩展工具功能

import 'package:flutter/foundation.dart';
import '../models/tool_model.dart';

class ToolProvider extends ChangeNotifier {
  // 已注册的工具列表
  final List<ToolModel> _tools = [];
  // 当前选中的工具 ID
  String? _currentToolId;

  // 只读获取工具列表
  List<ToolModel> get tools => List.unmodifiable(_tools);

  // 获取当前选中的工具对象
  ToolModel? get currentTool {
    if (_currentToolId == null) return null;
    try {
      return _tools.firstWhere((t) => t.id == _currentToolId);
    } catch (_) {
      return null;
    }
  }

  // 注册一个新工具
  void registerTool(ToolModel tool) {
    // 防止重复注册
    if (_tools.any((t) => t.id == tool.id)) return;
    _tools.add(tool);
    notifyListeners();
  }

  // 选中某个工具
  void selectTool(String id) {
    _currentToolId = id;
    notifyListeners();
  }

  // 取消选中
  void clearSelection() {
    _currentToolId = null;
    notifyListeners();
  }
}
