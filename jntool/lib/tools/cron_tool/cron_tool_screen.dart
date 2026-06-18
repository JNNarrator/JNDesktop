// Cron 表达式生成器主界面。
// 提供 Quartz 七字段输入体验，生成和计算时使用前六字段（秒 分 时 日 月 周）。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/constants.dart';
import '../../widgets/glass_container.dart';
import 'cron_expression.dart';

class CronToolScreen extends StatefulWidget {
  const CronToolScreen({super.key});

  @override
  State<CronToolScreen> createState() => _CronToolScreenState();
}

class _CronToolScreenState extends State<CronToolScreen> {
  final List<_CronFieldMeta> _fields = _CronFieldMeta.values;
  late final Map<_CronFieldKey, TextEditingController> _controllers;
  late final Map<_CronFieldKey, FocusNode> _focusNodes;

  _CronFieldKey _activeField = _CronFieldKey.second;
  CronValidationResult _validation = const CronValidationResult.valid();
  List<DateTime> _nextTimes = const [];
  String? _copyMessage;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in _fields)
        field.key: TextEditingController(text: field.defaultValue),
    };
    _focusNodes = {
      for (final field in _fields) field.key: FocusNode(),
    };

    for (final field in _fields) {
      _controllers[field.key]!.addListener(_refreshPreview);
      _focusNodes[field.key]!.addListener(() => _handleFocusChanged(field.key));
    }
    _refreshPreview();
  }

  String get _spacedExpression {
    return _expressionFields.map(_fieldText).join(' ');
  }

  String get _compactExpression {
    return _expressionFields.map(_fieldText).join();
  }

  List<_CronFieldMeta> get _expressionFields {
    // 年字段仅用于 UI 展示，不参与最终 cron 字符串与执行时间计算。
    return _fields.where((field) => field.key != _CronFieldKey.year).toList();
  }

  _CronFieldMeta get _activeMeta {
    return _fields.firstWhere((field) => field.key == _activeField);
  }

  String _fieldText(_CronFieldMeta field) {
    final value = _controllers[field.key]!.text.trim();
    return value.isEmpty ? field.defaultValue : value;
  }

  void _handleFocusChanged(_CronFieldKey key) {
    final node = _focusNodes[key]!;
    if (!node.hasFocus || !mounted) return;
    setState(() => _activeField = key);
  }

  void _refreshPreview() {
    final validation = CronExpression.validate(_spacedExpression);
    var nextTimes = <DateTime>[];

    // 输入合法后再计算未来时间，避免高级 Quartz 语法或非法范围触发无效扫描。
    if (validation.isValid) {
      nextTimes = CronExpression.parse(_spacedExpression)
          .nextTimes(DateTime.now(), count: 10);
    }

    if (!mounted) return;
    setState(() {
      _validation = validation;
      _nextTimes = nextTimes;
      _copyMessage = null;
    });
  }

  void _parseBackToUi() {
    if (!_validation.isValid) {
      return;
    }

    // 预览串按需求不带空格，多字符字段无法仅凭字符串可靠切分；这里使用当前 UI
    // 的字段边界进行回填，保证 */15、MON-FRI 等合法值不会被错误拆散。
    for (final field in _expressionFields) {
      _controllers[field.key]!.text = _fieldText(field);
    }
    _refreshPreview();
  }

  Future<void> _copyExpression() async {
    await Clipboard.setData(ClipboardData(text: _compactExpression));
    if (!mounted) return;
    setState(() => _copyMessage = '已复制到剪贴板');
  }

  @override
  void dispose() {
    for (final field in _fields) {
      _controllers[field.key]!.removeListener(_refreshPreview);
      _controllers[field.key]!.dispose();
      _focusNodes[field.key]!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(validation: _validation),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 7,
                  child: _buildInputPanel(),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 5,
                  child: _NextTimesPanel(
                    times: _nextTimes,
                    validation: _validation,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    return _Panel(
      title: 'Cron 表达式生成器',
      subtitle: '七字段输入，生成时忽略年字段',
      badge: 'QUARTZ',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FieldGrid(
              fields: _fields,
              controllers: _controllers,
              focusNodes: _focusNodes,
              activeField: _activeField,
            ),
            const SizedBox(height: AppSpacing.md),
            _FieldHelp(meta: _activeMeta),
            const SizedBox(height: AppSpacing.md),
            _SummaryRow(fields: _fields, valueOf: _fieldText),
            const SizedBox(height: AppSpacing.md),
            _ExpressionPreview(
              expression: _compactExpression,
              validation: _validation,
              copyMessage: _copyMessage,
              onParseBack: _parseBackToUi,
              onCopy: _copyExpression,
            ),
          ],
        ),
      ),
    );
  }
}

enum _CronFieldKey { second, minute, hour, day, month, week, year }

class _CronFieldMeta {
  final _CronFieldKey key;
  final String label;
  final String defaultValue;
  final String range;
  final String periodExample;
  final String intervalExample;
  final Color accent;

  const _CronFieldMeta({
    required this.key,
    required this.label,
    required this.defaultValue,
    required this.range,
    required this.periodExample,
    required this.intervalExample,
    required this.accent,
  });

  static const values = [
    _CronFieldMeta(
      key: _CronFieldKey.second,
      label: '秒',
      defaultValue: '*',
      range: '0 到 59 秒',
      periodExample: '周期从 1 到 2 秒',
      intervalExample: '间隔从 0 到 1 秒开始，每 1 秒执行一次',
      accent: AppColors.primaryStart,
    ),
    _CronFieldMeta(
      key: _CronFieldKey.minute,
      label: '分钟',
      defaultValue: '*',
      range: '0 到 59 分钟',
      periodExample: '周期从 1 到 2 分钟',
      intervalExample: '间隔从 0 到 5 分钟开始，每 5 分钟执行一次',
      accent: AppColors.accentTeal,
    ),
    _CronFieldMeta(
      key: _CronFieldKey.hour,
      label: '小时',
      defaultValue: '*',
      range: '0 到 23 小时',
      periodExample: '周期从 1 到 2 小时',
      intervalExample: '间隔从 0 到 6 小时开始，每 6 小时执行一次',
      accent: AppColors.accentAmber,
    ),
    _CronFieldMeta(
      key: _CronFieldKey.day,
      label: '日',
      defaultValue: '*',
      range: '1 到 31 日',
      periodExample: '周期从 1 到 2 日',
      intervalExample: '间隔从 1 到 3 日开始，每 3 日执行一次',
      accent: AppColors.accentRose,
    ),
    _CronFieldMeta(
      key: _CronFieldKey.month,
      label: '月',
      defaultValue: '*',
      range: '1 到 12 月，或 JAN 到 DEC',
      periodExample: '周期从 1 到 2 月',
      intervalExample: '间隔从 1 到 2 月开始，每 2 月执行一次',
      accent: AppColors.primaryMid,
    ),
    _CronFieldMeta(
      key: _CronFieldKey.week,
      label: '周',
      defaultValue: '?',
      range: '1 到 7 周，或 MON 到 SUN',
      periodExample: '周期从 MON 到 FRI',
      intervalExample: '间隔从 MON 到 WED 开始，每 1 周执行一次',
      accent: Color(0xFF0EA5E9),
    ),
    _CronFieldMeta(
      key: _CronFieldKey.year,
      label: '年',
      defaultValue: '',
      range: '可留空，常见为 2024 到 2099',
      periodExample: '周期从 2026 到 2028 年',
      intervalExample: '年字段仅保留在 UI 中，不参与表达式生成',
      accent: Color(0xFF64748B),
    ),
  ];
}

class _Header extends StatelessWidget {
  final CronValidationResult validation;

  const _Header({required this.validation});

  @override
  Widget build(BuildContext context) {
    final valid = validation.isValid;
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
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded,
              size: 20, color: AppColors.primaryStart),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Cron 表达式生成器',
              style: TextStyle(
                fontSize: AppTypography.h3Size,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _StatusPill(
            label: valid ? '实时有效' : '需要修正',
            icon: valid ? Icons.check_circle : Icons.error_outline,
            color: valid ? AppColors.accentTeal : AppColors.accentRose,
          ),
        ],
      ),
    );
  }
}

class _FieldGrid extends StatelessWidget {
  final List<_CronFieldMeta> fields;
  final Map<_CronFieldKey, TextEditingController> controllers;
  final Map<_CronFieldKey, FocusNode> focusNodes;
  final _CronFieldKey activeField;

  const _FieldGrid({
    required this.fields,
    required this.controllers,
    required this.focusNodes,
    required this.activeField,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (final field in fields)
              Expanded(
                child: _FieldLabel(
                  meta: field,
                  active: field.key == activeField,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final field in fields) ...[
              Expanded(
                child: _CronInput(
                  meta: field,
                  controller: controllers[field.key]!,
                  focusNode: focusNodes[field.key]!,
                  active: field.key == activeField,
                ),
              ),
              if (field != fields.last) const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final _CronFieldMeta meta;
  final bool active;

  const _FieldLabel({required this.meta, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimations.fast,
      margin: const EdgeInsets.only(right: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(vertical: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? meta.accent.withValues(alpha: 0.13)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(
          color: active
              ? meta.accent.withValues(alpha: 0.45)
              : AppColors.borderLight,
        ),
      ),
      child: Text(
        meta.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: active ? FontWeight.w800 : FontWeight.w700,
          color: active ? meta.accent : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _CronInput extends StatelessWidget {
  final _CronFieldMeta meta;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool active;

  const _CronInput({
    required this.meta,
    required this.controller,
    required this.focusNode,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        style: CodeStyle.inputText.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        cursorColor: meta.accent,
        decoration: InputDecoration(
          hintText: meta.defaultValue.isEmpty ? '空' : meta.defaultValue,
          hintStyle: CodeStyle.inputText.copyWith(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
          filled: true,
          fillColor: active ? Colors.white : const Color(0xFFF8FAFC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: meta.accent, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _FieldHelp extends StatelessWidget {
  final _CronFieldMeta meta;

  const _FieldHelp({required this.meta});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimations.normal,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: meta.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: meta.accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${meta.label} 允许的通配符 [ , - * / L W # ? ]，范围 ${meta.range}',
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meta.periodExample,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meta.intervalExample,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final List<_CronFieldMeta> fields;
  final String Function(_CronFieldMeta field) valueOf;

  const _SummaryRow({required this.fields, required this.valueOf});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Text(
            '各字段：',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SelectableText(
              fields.map(valueOf).join(' '),
              style: CodeStyle.outputText.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpressionPreview extends StatelessWidget {
  final String expression;
  final CronValidationResult validation;
  final String? copyMessage;
  final VoidCallback onParseBack;
  final VoidCallback onCopy;

  const _ExpressionPreview({
    required this.expression,
    required this.validation,
    required this.copyMessage,
    required this.onParseBack,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final valid = validation.isValid;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: valid ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: valid ? const Color(0xFFA7F3D0) : const Color(0xFFFFCDD5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                valid ? Icons.verified_rounded : Icons.warning_amber_rounded,
                size: 18,
                color: valid ? AppColors.accentTeal : AppColors.accentRose,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SelectableText(
                  expression,
                  style: CodeStyle.outputText.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (!valid) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              validation.error ?? '表达式无效',
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AppColors.accentRose,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (copyMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              copyMessage!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF047857),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _FlatActionButton(
                icon: Icons.keyboard_return_rounded,
                label: '反解析到UI',
                onTap: onParseBack,
              ),
              _FlatActionButton(
                icon: Icons.copy_rounded,
                label: '复制',
                onTap: onCopy,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextTimesPanel extends StatelessWidget {
  final List<DateTime> times;
  final CronValidationResult validation;

  const _NextTimesPanel({required this.times, required this.validation});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: '近10次执行时间：',
      subtitle: validation.isValid ? '从当前时间向后计算' : '修正字段后自动刷新',
      badge: 'NEXT 10',
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (!validation.isValid) {
      return _MessageState(
        icon: Icons.error_outline,
        title: '暂无法计算',
        message: validation.error ?? '请检查 cron 字段。',
        color: AppColors.accentRose,
      );
    }
    if (times.isEmpty) {
      return const _MessageState(
        icon: Icons.hourglass_empty_rounded,
        title: '没有找到未来时间',
        message: '请放宽日期、月份或星期条件。',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: times.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final time = times[index];
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryStart.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryStart,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SelectableText(
                  _formatDateTime(time),
                  style: CodeStyle.outputText.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatDateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final Widget child;

  const _Panel({
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
                _Badge(label: badge),
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

class _StatusPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

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

class _FlatActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FlatActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
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
