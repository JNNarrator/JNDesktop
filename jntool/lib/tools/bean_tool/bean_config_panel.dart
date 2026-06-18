// Bean tool configuration panel.

import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import 'bean_generator.dart';

typedef OnConfigChanged = void Function(BeanConvertConfig config);

class BeanConfigPanel extends StatefulWidget {
  final BeanConvertConfig config;
  final OnConfigChanged onChanged;

  const BeanConfigPanel({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  State<BeanConfigPanel> createState() => _BeanConfigPanelState();
}

class _BeanConfigPanelState extends State<BeanConfigPanel> {
  late TextEditingController _classNameCtrl;
  late TextEditingController _packageCtrl;
  final ScrollController _configScrollController = ScrollController();

  BeanConvertConfig get _base => widget.config;

  @override
  void initState() {
    super.initState();
    _classNameCtrl = TextEditingController(text: widget.config.className);
    _packageCtrl = TextEditingController(text: widget.config.packageName);
  }

  @override
  void didUpdateWidget(covariant BeanConfigPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.className != widget.config.className &&
        _classNameCtrl.text != widget.config.className) {
      _classNameCtrl.text = widget.config.className;
    }
    if (oldWidget.config.packageName != widget.config.packageName &&
        _packageCtrl.text != widget.config.packageName) {
      _packageCtrl.text = widget.config.packageName;
    }
  }

  @override
  void dispose() {
    _classNameCtrl.dispose();
    _packageCtrl.dispose();
    _configScrollController.dispose();
    super.dispose();
  }

  void _emit(BeanConvertConfig updated) {
    widget.onChanged(updated);
  }

  BeanConvertConfig _copyConfig({
    LombokConfig? lombok,
    String? className,
    bool? useInnerClass,
    String? packageName,
    bool? useJsonAnnotations,
    bool? useCamelCase,
    bool? generateComments,
  }) {
    return BeanConvertConfig(
      lombok: lombok ?? _base.lombok,
      className: className ?? _base.className,
      useInnerClass: useInnerClass ?? _base.useInnerClass,
      packageName: packageName ?? _base.packageName,
      useJsonAnnotations: useJsonAnnotations ?? _base.useJsonAnnotations,
      useCamelCase: useCamelCase ?? _base.useCamelCase,
      generateComments: generateComments ?? _base.generateComments,
    );
  }

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
          Row(
            children: [
              const Expanded(
                child: Text(
                  '转换配置',
                  style: TextStyle(
                    fontSize: AppTypography.h3Size,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _MiniBadge(label: '${_enabledLombokCount()} Lombok'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Scrollbar(
              controller: _configScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _configScrollController,
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ConfigSection(
                      title: '基础配置',
                      child: Column(
                        children: [
                          _FieldInput(
                            label: '类名',
                            controller: _classNameCtrl,
                            hintText: 'Root',
                            onChanged: (value) => _emit(
                              _copyConfig(
                                className: value.trim().isEmpty
                                    ? 'Root'
                                    : value.trim(),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _FieldInput(
                            label: '包名',
                            controller: _packageCtrl,
                            hintText: 'com.example.model',
                            onChanged: (value) => _emit(
                              _copyConfig(packageName: value.trim()),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ConfigSection(
                      title: '字段规则',
                      child: Column(
                        children: [
                          _SwitchTile(
                            label: '使用内部类',
                            value: _base.useInnerClass,
                            onChanged: (value) => _emit(
                              _copyConfig(useInnerClass: value),
                            ),
                          ),
                          _SwitchTile(
                            label: '驼峰命名',
                            value: _base.useCamelCase,
                            onChanged: (value) => _emit(
                              _copyConfig(useCamelCase: value),
                            ),
                          ),
                          _SwitchTile(
                            label: '生成注释',
                            value: _base.generateComments,
                            onChanged: (value) => _emit(
                              _copyConfig(generateComments: value),
                            ),
                          ),
                          _SwitchTile(
                            label: 'Jackson 注解',
                            value: _base.useJsonAnnotations,
                            onChanged: (value) => _emit(
                              _copyConfig(
                                useJsonAnnotations: value,
                                lombok: _copyLombok(
                                  useJsonProperty: value,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ConfigSection(
                      title: 'Lombok 注解',
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _buildLombokToggles(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _enabledLombokCount() {
    final lb = _base.lombok;
    return [
      lb.useData,
      lb.useBuilder,
      lb.useAllArgs,
      lb.useNoArgs,
      lb.useAccessors,
      lb.useToString,
      lb.useEqualsHash,
    ].where((value) => value).length;
  }

  List<Widget> _buildLombokToggles() {
    final lb = _base.lombok;
    return [
      _LombokChip(
        label: '@Data',
        value: lb.useData,
        onChanged: (value) => _updateLombok(useData: value),
      ),
      _LombokChip(
        label: '@Builder',
        value: lb.useBuilder,
        onChanged: (value) => _updateLombok(useBuilder: value),
      ),
      _LombokChip(
        label: '@AllArgsConstructor',
        value: lb.useAllArgs,
        onChanged: (value) => _updateLombok(useAllArgs: value),
      ),
      _LombokChip(
        label: '@NoArgsConstructor',
        value: lb.useNoArgs,
        onChanged: (value) => _updateLombok(useNoArgs: value),
      ),
      _LombokChip(
        label: '@Accessors(chain=true)',
        value: lb.useAccessors,
        onChanged: (value) => _updateLombok(useAccessors: value),
      ),
      _LombokChip(
        label: '@ToString',
        value: lb.useToString,
        onChanged: (value) => _updateLombok(useToString: value),
      ),
      _LombokChip(
        label: '@EqualsAndHashCode',
        value: lb.useEqualsHash,
        onChanged: (value) => _updateLombok(useEqualsHash: value),
      ),
    ];
  }

  LombokConfig _copyLombok({
    bool? useData,
    bool? useBuilder,
    bool? useAllArgs,
    bool? useNoArgs,
    bool? useAccessors,
    bool? useToString,
    bool? useEqualsHash,
    bool? useJsonProperty,
  }) {
    final lb = _base.lombok;
    return LombokConfig(
      useData: useData ?? lb.useData,
      useGetter: lb.useGetter,
      useSetter: lb.useSetter,
      useToString: useToString ?? lb.useToString,
      useEqualsHash: useEqualsHash ?? lb.useEqualsHash,
      useBuilder: useBuilder ?? lb.useBuilder,
      useAllArgs: useAllArgs ?? lb.useAllArgs,
      useNoArgs: useNoArgs ?? lb.useNoArgs,
      useAccessors: useAccessors ?? lb.useAccessors,
      useJsonIgnore: lb.useJsonIgnore,
      useJsonProperty: useJsonProperty ?? lb.useJsonProperty,
    );
  }

  void _updateLombok({
    bool? useData,
    bool? useBuilder,
    bool? useAllArgs,
    bool? useNoArgs,
    bool? useAccessors,
    bool? useToString,
    bool? useEqualsHash,
  }) {
    _emit(
      _copyConfig(
        lombok: _copyLombok(
          useData: useData,
          useBuilder: useBuilder,
          useAllArgs: useAllArgs,
          useNoArgs: useNoArgs,
          useAccessors: useAccessors,
          useToString: useToString,
          useEqualsHash: useEqualsHash,
        ),
      ),
    );
  }
}

class _ConfigSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ConfigSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _FieldInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const _FieldInput({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              borderSide: const BorderSide(color: AppColors.primaryStart),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

class _LombokChip extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LombokChip({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: value,
      label: Text(label),
      onSelected: onChanged,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 11,
        fontFamily: 'monospace',
        fontWeight: value ? FontWeight.w700 : FontWeight.w500,
        color: value ? AppColors.primaryStart : AppColors.textSecondary,
      ),
      selectedColor: const Color(0xFFEFF6FF),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: value ? const Color(0xFFBFDBFE) : AppColors.borderLight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;

  const _MiniBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        label,
        style: CodeStyle.badgeText.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
