// Bean tool main screen.
// Converts JSON and Java Bean snippets with a compact developer-tool layout.

import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../../widgets/glass_container.dart';
import 'bean_config_panel.dart';
import 'bean_generator.dart';

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

  bool get _isJsonToBean => _direction == ConvertDirection.jsonToBean;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_handleInputChanged);
  }

  void _handleInputChanged() {
    if (mounted) setState(() {});
  }

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
}'''
        .trim();
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
}'''
        .trim();
    _convert();
  }

  void _clearAll() {
    _inputController.clear();
    setState(() {
      _output = '';
      _error = null;
    });
  }

  void _convert() {
    final raw = _inputController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _output = '';
        _error = null;
      });
      return;
    }

    try {
      setState(() {
        _output = _isJsonToBean
            ? BeanGenerator.jsonToJava(raw, _config)
            : BeanGenerator.javaToJson(raw);
        _error = null;
      });
    } catch (e) {
      setState(() {
        _output = '';
        _error = '转换失败: $e';
      });
    }
  }

  void _toggleDirection() {
    setState(() {
      _direction = _isJsonToBean
          ? ConvertDirection.beanToJson
          : ConvertDirection.jsonToBean;
      _output = '';
      _error = null;
    });
    if (_inputController.text.trim().isNotEmpty) _convert();
  }

  @override
  void dispose() {
    _inputController.removeListener(_handleInputChanged);
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToolbar(),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 6, child: _buildLeftPanel()),
                const SizedBox(width: AppSpacing.md),
                Expanded(flex: 5, child: _buildResultPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.soft,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.data_object,
                size: 20, color: AppColors.primaryStart),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'JSON / Java Bean',
              style: TextStyle(
                fontSize: AppTypography.h3Size,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _DirectionChip(
              from: _isJsonToBean ? 'JSON' : 'Java',
              to: _isJsonToBean ? 'Java' : 'JSON',
              onTap: _toggleDirection,
            ),
            const SizedBox(width: AppSpacing.md),
            _ToolBtn(
              icon: Icons.auto_fix_high,
              label: _isJsonToBean ? 'JSON 示例' : 'Java 示例',
              onTap: _isJsonToBean ? _loadSample : _loadSampleJava,
            ),
            _ToolBtn(
              icon: Icons.delete_outline,
              label: '清空',
              onTap: _clearAll,
            ),
            const SizedBox(width: AppSpacing.sm),
            _PrimaryActionButton(onTap: _convert),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Column(
      children: [
        Expanded(
          flex: 7,
          child: _CodePanel(
            title: _isJsonToBean ? '输入 JSON' : '输入 Java Bean',
            subtitle: '${_inputController.text.length} chars',
            badge: _isJsonToBean ? 'SOURCE: JSON' : 'SOURCE: JAVA',
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocus,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: CodeStyle.inputText,
              cursorColor: AppColors.primaryStart,
              decoration: CodeStyle.inputDecoration(
                fillColor: const Color(0xFF0F172A).withValues(alpha: 0.035),
              ).copyWith(
                hintText:
                    _isJsonToBean ? '在此粘贴 JSON...' : '在此粘贴 Java Bean 代码...',
                hintStyle: CodeStyle.inputText.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          flex: 5,
          child: _isJsonToBean
              ? BeanConfigPanel(
                  config: _config,
                  onChanged: (config) => setState(() => _config = config),
                )
              : _NoConfigPanel(onTapSample: _loadSampleJava),
        ),
      ],
    );
  }

  Widget _buildResultPanel() {
    return _CodePanel(
      title: _isJsonToBean ? 'Java Bean 输出' : 'JSON 输出',
      subtitle: _error != null
          ? '转换异常'
          : _output.isEmpty
              ? '等待转换'
              : '${_output.length} chars',
      badge: _isJsonToBean ? 'TARGET: JAVA' : 'TARGET: JSON',
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return _MessageState(
        icon: Icons.error_outline,
        title: '转换失败',
        message: _error!,
        color: AppColors.accentRose,
      );
    }

    if (_output.isEmpty) {
      return _MessageState(
        icon: Icons.terminal,
        title: '等待输入',
        message: _isJsonToBean
            ? '在左侧输入 JSON，然后点击转换生成 Java Bean。'
            : '在左侧输入 Java Bean，然后点击转换生成 JSON。',
        color: AppColors.textMuted,
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SelectableText(_output, style: CodeStyle.outputText),
      ),
    );
  }
}

class _CodePanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final Widget child;

  const _CodePanel({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(label: badge),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.borderLight),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        label,
        style: CodeStyle.badgeText.copyWith(color: const Color(0xFF1D4ED8)),
      ),
    );
  }
}

class _DirectionChip extends StatelessWidget {
  final String from;
  final String to;
  final VoidCallback onTap;

  const _DirectionChip({
    required this.from,
    required this.to,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 7,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DirectionLabel(text: from),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.swap_horiz,
                    size: 16, color: AppColors.primaryStart),
              ),
              _DirectionLabel(text: to),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectionLabel extends StatelessWidget {
  final String text;

  const _DirectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryStart,
        fontFamily: 'monospace',
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PrimaryActionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryStart,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryStart.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 9,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow_rounded, color: Colors.white, size: 17),
                SizedBox(width: 4),
                Text(
                  '转换',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoConfigPanel extends StatelessWidget {
  final VoidCallback onTapSample;

  const _NoConfigPanel({required this.onTapSample});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '转换配置',
            style: TextStyle(
              fontSize: AppTypography.h3Size,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Java 转 JSON 使用字段声明推导示例值，无需额外配置。',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomLeft,
            child: _ToolBtn(
              icon: Icons.code,
              label: '载入 Java 示例',
              onTap: onTapSample,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: color),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
