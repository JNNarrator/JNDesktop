// Bean 工具 —— 配置面板
// Lombok 选项、类名、内部类等配置

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'bean_generator.dart';

/// 配置面板回调
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

  @override
  void initState() {
    super.initState();
    _classNameCtrl = TextEditingController(text: widget.config.className);
    _packageCtrl = TextEditingController(text: widget.config.packageName);
  }

  @override
  void dispose() {
    _classNameCtrl.dispose();
    _packageCtrl.dispose();
    super.dispose();
  }

  void _emit(BeanConvertConfig updated) {
    widget.onChanged(updated);
  }

  BeanConvertConfig _base() => widget.config;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.glassWhite,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.glassBorder, width: 0.8),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚙️ 转换配置',
                style: TextStyle(fontSize: AppTypography.h3Size, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.md),

              // 类名
              _section('类名', child: TextField(
                controller: _classNameCtrl,
                onChanged: (v) => _emit(BeanConvertConfig(
                  lombok: _base().lombok, className: v.isNotEmpty ? v : 'Root',
                  useInnerClass: _base().useInnerClass, packageName: _base().packageName,
                  useJsonAnnotations: _base().useJsonAnnotations,
                  useCamelCase: _base().useCamelCase, generateComments: _base().generateComments,
                )),
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: 'ClassName',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), isDense: true,
                  filled: true, fillColor: Color(0xFFF1F5F9),
                ),
              )),
              const SizedBox(height: AppSpacing.sm),

              // 包名
              _section('包名', child: TextField(
                controller: _packageCtrl,
                onChanged: (v) => _emit(BeanConvertConfig(
                  lombok: _base().lombok, className: _base().className,
                  useInnerClass: _base().useInnerClass, packageName: v,
                  useJsonAnnotations: _base().useJsonAnnotations,
                  useCamelCase: _base().useCamelCase, generateComments: _base().generateComments,
                )),
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: 'com.example.model',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), isDense: true,
                  filled: true, fillColor: Color(0xFFF1F5F9),
                ),
              )),
              const SizedBox(height: AppSpacing.sm),

              // 开关
              _switchRow('使用内部类', _base().useInnerClass, (v) => _emit(BeanConvertConfig(
                lombok: _base().lombok, className: _base().className,
                useInnerClass: v, packageName: _base().packageName,
                useJsonAnnotations: _base().useJsonAnnotations,
                useCamelCase: _base().useCamelCase, generateComments: _base().generateComments,
              ))),
              _switchRow('驼峰命名', _base().useCamelCase, (v) => _emit(BeanConvertConfig(
                lombok: _base().lombok, className: _base().className,
                useInnerClass: _base().useInnerClass, packageName: _base().packageName,
                useJsonAnnotations: _base().useJsonAnnotations,
                useCamelCase: v, generateComments: _base().generateComments,
              ))),
              _switchRow('生成注释', _base().generateComments, (v) => _emit(BeanConvertConfig(
                lombok: _base().lombok, className: _base().className,
                useInnerClass: _base().useInnerClass, packageName: _base().packageName,
                useJsonAnnotations: _base().useJsonAnnotations,
                useCamelCase: _base().useCamelCase, generateComments: v,
              ))),
              _switchRow('Jackson 注解', _base().useJsonAnnotations, (v) => _emit(BeanConvertConfig(
                lombok: _base().lombok, className: _base().className,
                useInnerClass: _base().useInnerClass, packageName: _base().packageName,
                useJsonAnnotations: v, useCamelCase: _base().useCamelCase,
                generateComments: _base().generateComments,
              ))),
              const SizedBox(height: AppSpacing.md),

              // Lombok 注解
              const Text('📦 Lombok 注解',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              ..._buildLombokToggles(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLombokToggles() {
    final lb = _base().lombok;
    return [
      _lombokRow('@Data', lb.useData, (v) => _updateLombok(lb, useData: v)),
      _lombokRow('@Builder', lb.useBuilder, (v) => _updateLombok(lb, useBuilder: v)),
      _lombokRow('@AllArgsConstructor', lb.useAllArgs, (v) => _updateLombok(lb, useAllArgs: v)),
      _lombokRow('@NoArgsConstructor', lb.useNoArgs, (v) => _updateLombok(lb, useNoArgs: v)),
      _lombokRow('@Accessors(chain=true)', lb.useAccessors, (v) => _updateLombok(lb, useAccessors: v)),
      _lombokRow('@ToString', lb.useToString, (v) => _updateLombok(lb, useToString: v)),
      _lombokRow('@EqualsAndHashCode', lb.useEqualsHash, (v) => _updateLombok(lb, useEqualsHash: v)),
    ];
  }

  void _updateLombok(LombokConfig lb, {bool? useData, bool? useBuilder, bool? useAllArgs, bool? useNoArgs, bool? useAccessors, bool? useToString, bool? useEqualsHash}) {
    _emit(BeanConvertConfig(
      lombok: LombokConfig(
        useData: useData ?? lb.useData,
        useBuilder: useBuilder ?? lb.useBuilder,
        useAllArgs: useAllArgs ?? lb.useAllArgs,
        useNoArgs: useNoArgs ?? lb.useNoArgs,
        useAccessors: useAccessors ?? lb.useAccessors,
        useToString: useToString ?? lb.useToString,
        useEqualsHash: useEqualsHash ?? lb.useEqualsHash,
      ),
      className: _base().className, useInnerClass: _base().useInnerClass,
      packageName: _base().packageName, useJsonAnnotations: _base().useJsonAnnotations,
      useCamelCase: _base().useCamelCase, generateComments: _base().generateComments,
    ));
  }

  Widget _section(String title, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Switch(value: value, onChanged: onChanged, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _lombokRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        children: [
          SizedBox(
            width: 20, height: 20,
            child: Checkbox(value: value, onChanged: (v) => onChanged(v == true), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: TextStyle(
            fontSize: 12, fontFamily: 'monospace',
            color: value ? AppColors.primaryStart : AppColors.textSecondary,
            fontWeight: value ? FontWeight.w600 : FontWeight.normal,
          )),
        ],
      ),
    );
  }
}
