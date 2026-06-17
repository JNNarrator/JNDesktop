// Bean 工具 —— 主界面
// JSON ↔ Java Bean 互相转换，支持 Lombok、自定义类名等配置

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_container.dart';
import 'bean_generator.dart';
import 'bean_config_panel.dart';

class BeanToolScreen extends StatefulWidget {
  const BeanToolScreen({super.key});

  @override
  State<BeanToolScreen> createState() => _BeanToolScreenState();
}

class _BeanToolScreenState extends State<BeanToolScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  ConvertDirection _direction = ConvertDirection.jsonToBean;
  String _output = '';
  String? _error;
  BeanConvertConfig _config = const BeanConvertConfig();

  void _loadSample() {
    _inputController.text = '''
{
  "user_id": 1,
  "user_name": "John Doe",
  "email": "john@example.com",
  "age": 28,
  "is_active": true,
  "address": {
    "street": "123 Main St",
    "city": "Beijing",
    "zip_code": "100000"
  },
  "tags": ["developer", "designer"],
  "scores": [95, 88, 92]
}'''.trim();
    _convert();
  }

  void _loadSampleJava() {
    _inputController.text = '''
public class User {
    private Integer id;
    private String name;
    private String email;
    private Integer age;
    private Boolean isActive;
}'''.trim();
    _convert();
  }

  void _clearAll() {
    _inputController.clear();
    setState(() { _output = ''; _error = null; });
  }

  void _convert() {
    final raw = _inputController.text.trim();
    if (raw.isEmpty) {
      setState(() { _output = ''; _error = null; });
      return;
    }
    try {
      setState(() {
        _output = _direction == ConvertDirection.jsonToBean
            ? BeanGenerator.jsonToJava(raw, _config)
            : BeanGenerator.javaToJson(raw);
        _error = null;
      });
    } catch (e) {
      setState(() { _output = ''; _error = '转换失败: $e'; });
    }
  }

  void _toggleDirection() {
    setState(() {
      _direction = _direction == ConvertDirection.jsonToBean
          ? ConvertDirection.beanToJson : ConvertDirection.jsonToBean;
    });
    _convert();
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
          _buildToolbar(),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 5, child: _buildLeftPanel()),
                const SizedBox(width: AppSpacing.sm),
                Expanded(flex: 5, child: _buildResultPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Text('🫘 JSON ↔ Java Bean',
            style: TextStyle(fontSize: AppTypography.h2Size, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(width: AppSpacing.md),
          // 方向切换
          GestureDetector(
            onTap: _toggleDirection,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primaryStart.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primaryStart.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_direction == ConvertDirection.jsonToBean ? 'JSON' : 'Java',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryStart, fontFamily: 'monospace')),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.swap_horiz, size: 18, color: AppColors.primaryStart)),
                  Text(_direction == ConvertDirection.jsonToBean ? 'Java' : 'JSON',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryStart, fontFamily: 'monospace')),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _ToolBtn(icon: Icons.auto_fix_high, label: _direction == ConvertDirection.jsonToBean ? 'JSON 示例' : 'Java 示例',
            onTap: _direction == ConvertDirection.jsonToBean ? _loadSample : _loadSampleJava),
          const SizedBox(width: 4),
          _ToolBtn(icon: Icons.delete_outline, label: '清空', onTap: _clearAll),
          const SizedBox(width: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              gradient: AppGradients.primary, borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: [BoxShadow(color: AppColors.primaryStart.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _convert,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.transform, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('转换', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Column(
      children: [
        // 输入区域（占用 60% 高度）
        Expanded(
          flex: 3,
          child: Material(
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
                  Row(children: [
                    Text(_direction == ConvertDirection.jsonToBean ? '📝 输入 JSON' : '📝 输入 Java Bean',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const Spacer(),
                    Text('${_inputController.text.length} chars',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ]),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      focusNode: _inputFocus,
                      maxLines: null, expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.5, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: _direction == ConvertDirection.jsonToBean ? '在此粘贴 JSON...' : '在此粘贴 Java Bean 代码...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'monospace'),
                        border: InputBorder.none, contentPadding: EdgeInsets.zero, filled: true, fillColor: Color(0xFFFAFAFA),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // 配置区域（占用 40% 高度）
        Expanded(
          flex: 2,
          child: _direction == ConvertDirection.jsonToBean
              ? BeanConfigPanel(config: _config, onChanged: (c) => setState(() => _config = c))
              : Material(
                  color: AppColors.glassWhite,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.glassBorder, width: 0.8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📤', style: TextStyle(fontSize: 32)),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Java → JSON 方向无需额外配置',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildResultPanel() {
    return GlassContainer(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.sm),
      height: double.infinity,
      gradient: const LinearGradient(
        colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(_direction == ConvertDirection.jsonToBean ? '📄 Java Bean' : '📋 JSON 输出',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const Spacer(),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('❌', style: TextStyle(fontSize: 32)),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(_error!, style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.accentRose),
              textAlign: TextAlign.center),
          ),
        ]),
      );
    }
    if (_output.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_direction == ConvertDirection.jsonToBean ? '🫘' : '📄', style: const TextStyle(fontSize: 40)),
          const SizedBox(height: AppSpacing.md),
          Text(_direction == ConvertDirection.jsonToBean ? '在左侧输入 JSON\n然后点击「转换」' : '在左侧输入 Java 代码\n然后点击「转换」',
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.5), textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          const Text('试试示例吧 ✨', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ]),
      );
    }
    return SingleChildScrollView(
      child: SelectableText(_output,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.6, color: AppColors.textPrimary)),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ToolBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}
