// Spring Boot 配置转换工具主界面。
// 支持 application.yml / application.properties 在常见配置结构下双向转换。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/constants.dart';
import '../../widgets/glass_container.dart';
import 'config_converter.dart';

class ConfigToolScreen extends StatefulWidget {
  const ConfigToolScreen({super.key});

  @override
  State<ConfigToolScreen> createState() => _ConfigToolScreenState();
}

class _ConfigToolScreenState extends State<ConfigToolScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _outputScrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  ConfigConvertDirection _direction = ConfigConvertDirection.yamlToProperties;
  String _output = '';
  String? _error;
  String? _copyMessage;

  bool get _isYamlToProperties =>
      _direction == ConfigConvertDirection.yamlToProperties;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_handleInputChanged);
  }

  void _handleInputChanged() {
    if (!mounted) return;
    setState(() => _copyMessage = null);
  }

  void _convert() {
    final raw = _inputController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _output = '';
        _error = null;
        _copyMessage = null;
      });
      return;
    }

    try {
      final converted = ConfigConverter.convert(raw, _direction);
      setState(() {
        _output = converted;
        _error = null;
        _copyMessage = null;
      });
    } catch (e) {
      setState(() {
        _output = '';
        _error = '转换失败：$e';
        _copyMessage = null;
      });
    }
  }

  void _toggleDirection() {
    setState(() {
      _direction = _isYamlToProperties
          ? ConfigConvertDirection.propertiesToYaml
          : ConfigConvertDirection.yamlToProperties;
      _output = '';
      _error = null;
      _copyMessage = null;
    });
    if (_inputController.text.trim().isNotEmpty) _convert();
  }

  void _loadSample() {
    _inputController.text =
        _isYamlToProperties ? _yamlSample : _propertiesSample;
    _convert();
  }

  void _swapInputOutput() {
    if (_output.trim().isEmpty) return;
    _inputController.text = _output;
    _toggleDirection();
  }

  void _clearAll() {
    _inputController.clear();
    setState(() {
      _output = '';
      _error = null;
      _copyMessage = null;
    });
    _inputFocus.requestFocus();
  }

  Future<void> _copyOutput() async {
    if (_output.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _output));
    if (!mounted) return;
    setState(() => _copyMessage = '已复制输出内容');
  }

  @override
  void dispose() {
    _inputController.removeListener(_handleInputChanged);
    _inputController.dispose();
    _outputScrollController.dispose();
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
                Expanded(flex: 6, child: _buildInputPanel()),
                const SizedBox(width: AppSpacing.md),
                Expanded(flex: 5, child: _buildOutputPanel()),
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
            const Icon(Icons.tune_rounded,
                size: 20, color: AppColors.primaryStart),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'Spring Boot 配置转换',
              style: TextStyle(
                fontSize: AppTypography.h3Size,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _DirectionChip(
              from: _isYamlToProperties ? 'YAML' : 'Properties',
              to: _isYamlToProperties ? 'Properties' : 'YAML',
              onTap: _toggleDirection,
            ),
            const SizedBox(width: AppSpacing.md),
            _ToolBtn(
              icon: Icons.auto_fix_high,
              label: '示例',
              onTap: _loadSample,
            ),
            _ToolBtn(
              icon: Icons.swap_horiz_rounded,
              label: '反向',
              onTap: _swapInputOutput,
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

  Widget _buildInputPanel() {
    return _CodePanel(
      title: _isYamlToProperties ? '输入 YAML' : '输入 Properties',
      subtitle: '${_inputController.text.length} chars',
      badge: _isYamlToProperties ? 'SOURCE: YAML' : 'SOURCE: PROPERTIES',
      child: TextField(
        controller: _inputController,
        focusNode: _inputFocus,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: CodeStyle.inputText,
        cursorColor: AppColors.primaryStart,
        inputFormatters: [
          _YamlIndentFormatter(enabled: _isYamlToProperties),
        ],
        decoration: CodeStyle.inputDecoration(
          fillColor: const Color(0xFF0F172A).withValues(alpha: 0.035),
        ).copyWith(
          hintText: _isYamlToProperties
              ? '在此粘贴 application.yml 内容...'
              : '在此粘贴 application.properties 内容...',
          hintStyle: CodeStyle.inputText.copyWith(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildOutputPanel() {
    return _CodePanel(
      title: _isYamlToProperties ? 'Properties 输出' : 'YAML 输出',
      subtitle: _error != null
          ? '转换异常'
          : _output.isEmpty
              ? '等待转换'
              : '${_output.length} chars',
      badge: _isYamlToProperties ? 'TARGET: PROPERTIES' : 'TARGET: YAML',
      trailing: _output.isEmpty
          ? null
          : _IconAction(
              icon: Icons.copy_rounded,
              tooltip: '复制输出',
              onTap: _copyOutput,
            ),
      child: _buildOutputContent(),
    );
  }

  Widget _buildOutputContent() {
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
        icon: Icons.settings_suggest_rounded,
        title: '等待输入',
        message: _isYamlToProperties
            ? '在左侧输入 YAML，然后点击转换生成 properties。'
            : '在左侧输入 properties，然后点击转换生成 YAML。',
      );
    }

    return Stack(
      children: [
        Scrollbar(
          controller: _outputScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _outputScrollController,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SelectableText(_output, style: CodeStyle.outputText),
          ),
        ),
        if (_copyMessage != null)
          Positioned(
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: _CopyToast(message: _copyMessage!),
          ),
      ],
    );
  }
}

const _yamlSample = '''
spring:
  application:
    name: demo-service
  datasource:
    url: 'jdbc:mysql://localhost:3306/demo'
    username: root
    password: 123456
server:
  port: 8080
management:
  endpoints:
    web:
      exposure:
        include: health,info
app:
  servers:
    - host: localhost
      port: 8081
    - host: example.com
      port: 8082
''';

const _propertiesSample = '''
spring.application.name=demo-service
spring.datasource.url=jdbc:mysql://localhost:3306/demo
spring.datasource.username=root
spring.datasource.password=123456
server.port=8080
management.endpoints.web.exposure.include=health,info
app.servers[0].host=localhost
app.servers[0].port=8081
app.servers[1].host=example.com
app.servers[1].port=8082
''';

class _YamlIndentFormatter extends TextInputFormatter {
  final bool enabled;

  const _YamlIndentFormatter({required this.enabled});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!enabled) return newValue;
    if (!newValue.selection.isCollapsed) return newValue;
    if (newValue.text.length != oldValue.text.length + 1) return newValue;

    final cursor = newValue.selection.baseOffset;
    if (cursor <= 0 || newValue.text[cursor - 1] != '\n') return newValue;

    final previousLineStart = newValue.text.lastIndexOf('\n', cursor - 2) + 1;
    final previousLine = newValue.text.substring(previousLineStart, cursor - 1);
    final inheritedIndent =
        RegExp(r'^ *').firstMatch(previousLine)?.group(0) ?? '';
    final extraIndent = previousLine.trimRight().endsWith(':') ? '  ' : '';
    final indent = inheritedIndent + extraIndent;
    if (indent.isEmpty) return newValue;

    // 只处理用户手动输入的单次换行：继承上一行缩进，父级 key 后多缩进两格。
    final updatedText = newValue.text.replaceRange(cursor, cursor, indent);
    return TextEditingValue(
      text: updatedText,
      selection: TextSelection.collapsed(offset: cursor + indent.length),
      composing: TextRange.empty,
    );
  }
}

class _CodePanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final Widget child;
  final Widget? trailing;

  const _CodePanel({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.child,
    this.trailing,
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
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing!,
                ],
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
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(from, style: CodeStyle.badgeText),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 14, color: AppColors.primaryStart),
              ),
              Text(to, style: CodeStyle.badgeText),
            ],
          ),
        ),
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
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryStart.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  '转换',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Icon(icon, size: 15, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _CopyToast extends StatelessWidget {
  final String message;

  const _CopyToast({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: const Color(0xFFA7F3D0)),
        boxShadow: AppShadows.soft,
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF047857),
        ),
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
    this.color = AppColors.textMuted,
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
