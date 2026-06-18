// 文本 / 图片 Base64 互转工具主界面。
// 文本模式使用 UTF-8 编解码，图片模式使用本地文件路径读写图片字节。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';

import '../../utils/constants.dart';
import '../../widgets/glass_container.dart';
import 'base64_converter.dart';

enum _Base64Mode { text, image }

enum _Base64Direction { encode, decode }

class Base64ToolScreen extends StatefulWidget {
  const Base64ToolScreen({super.key});

  @override
  State<Base64ToolScreen> createState() => _Base64ToolScreenState();
}

class _Base64ToolScreenState extends State<Base64ToolScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _outputScrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  _Base64Mode _mode = _Base64Mode.text;
  _Base64Direction _direction = _Base64Direction.encode;
  String _output = '';
  String? _error;
  String? _copyMessage;
  String? _selectedImagePath;
  Uint8List? _previewBytes;

  bool get _isTextMode => _mode == _Base64Mode.text;
  bool get _isEncode => _direction == _Base64Direction.encode;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_handleInputChanged);
  }

  void _handleInputChanged() {
    if (!mounted) return;
    setState(() {
      _copyMessage = null;
      if (!_isTextMode && !_isEncode) {
        _previewBytes = _tryDecodePreview(_inputController.text);
      }
    });
  }

  void _changeMode(_Base64Mode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _direction = _Base64Direction.encode;
      _output = '';
      _error = null;
      _copyMessage = null;
      _previewBytes = null;
      _selectedImagePath = null;
      _inputController.clear();
    });
    _inputFocus.requestFocus();
  }

  void _toggleDirection() {
    setState(() {
      _direction =
          _isEncode ? _Base64Direction.decode : _Base64Direction.encode;
      _output = '';
      _error = null;
      _copyMessage = null;
      _previewBytes =
          _isTextMode ? null : _tryDecodePreview(_inputController.text);
    });
  }

  Future<void> _convert() async {
    final raw = _isTextMode || !_isEncode
        ? _inputController.text.trim()
        : (_selectedImagePath ?? '').trim();
    if (raw.isEmpty) {
      setState(() {
        _output = '';
        // 图片编码依赖系统文件选择器，未选择时给出明确提示。
        _error = !_isTextMode && _isEncode ? '请先选择一张图片' : null;
        _copyMessage = null;
        _previewBytes = null;
      });
      return;
    }

    try {
      if (_isTextMode) {
        final converted = _isEncode
            ? Base64Converter.textToBase64(raw)
            : Base64Converter.base64ToText(raw);
        setState(() {
          _output = converted;
          _error = null;
          _copyMessage = null;
          _previewBytes = null;
        });
        return;
      }

      if (_isEncode) {
        final converted = await Base64Converter.imageFileToBase64(raw);
        setState(() {
          _output = converted;
          _error = null;
          _copyMessage = null;
          _previewBytes = Base64Converter.base64ToBytes(converted);
        });
        return;
      }

      // 图片解码保存不再手输路径，转换时由系统保存对话框返回目标路径。
      final savePath = await _pickImageSavePath();
      if (savePath == null) {
        setState(() {
          _output = '';
          _error = null;
          _copyMessage = null;
        });
        return;
      }

      final written = await Base64Converter.base64ToImageFile(
        raw,
        savePath,
      );
      setState(() {
        _output = '已保存图片：$savePath\n写入字节：$written';
        _error = null;
        _copyMessage = null;
        _previewBytes = Base64Converter.base64ToBytes(raw);
      });
    } catch (e) {
      setState(() {
        _output = '';
        _error = '转换失败：$e';
        _copyMessage = null;
        _previewBytes = null;
      });
    }
  }

  void _loadSample() {
    if (_isTextMode) {
      _inputController.text =
          _isEncode ? '你好，JNTool Base64' : '5L2g5aW977yMSk5Ub29sIEJhc2U2NA==';
    } else {
      _inputController.text =
          _isEncode ? '' : 'data:image/png;base64,iVBORw0KGgo=';
      _previewBytes =
          _isEncode ? null : _tryDecodePreview(_inputController.text);
    }
    _convert();
  }

  void _clearAll() {
    _inputController.clear();
    setState(() {
      _output = '';
      _error = null;
      _copyMessage = null;
      _selectedImagePath = null;
      _previewBytes = null;
    });
    _inputFocus.requestFocus();
  }

  Future<void> _pickImageFile() async {
    const imageTypeGroup = XTypeGroup(
      label: '图片文件',
      extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'svg'],
    );

    try {
      final file = await openFile(acceptedTypeGroups: [imageTypeGroup]);
      if (file == null || !mounted) return;

      setState(() {
        _selectedImagePath = file.path;
        _output = '';
        _error = null;
        _copyMessage = null;
        _previewBytes = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _output = '';
        _error = '打开文件选择器失败：$e';
        _copyMessage = null;
        _previewBytes = null;
      });
    }
  }

  Future<String?> _pickImageSavePath() async {
    const imageTypeGroup = XTypeGroup(
      label: 'PNG 图片',
      extensions: ['png'],
    );
    try {
      final location = await getSaveLocation(
        suggestedName: 'jntool_base64_image.png',
        acceptedTypeGroups: [imageTypeGroup],
      );
      return location?.path;
    } catch (e) {
      if (!mounted) return null;
      setState(() {
        _output = '';
        _error = '打开保存位置选择器失败：$e';
        _copyMessage = null;
      });
      return null;
    }
  }

  Future<void> _copyOutput() async {
    if (_output.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _output));
    if (!mounted) return;
    setState(() => _copyMessage = '已复制输出内容');
  }

  Uint8List? _tryDecodePreview(String input) {
    try {
      return Base64Converter.base64ToBytes(input);
    } catch (_) {
      return null;
    }
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
            const Icon(Icons.lock_reset_rounded,
                size: 20, color: AppColors.primaryStart),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              '文本 / 图片 Base64',
              style: TextStyle(
                fontSize: AppTypography.h3Size,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _ModeSegment(
              mode: _mode,
              onChanged: _changeMode,
            ),
            const SizedBox(width: AppSpacing.md),
            _DirectionChip(
              from: _directionLabel(true),
              to: _directionLabel(false),
              onTap: _toggleDirection,
            ),
            const SizedBox(width: AppSpacing.md),
            _ToolBtn(
                icon: Icons.auto_fix_high, label: '示例', onTap: _loadSample),
            _ToolBtn(icon: Icons.delete_outline, label: '清空', onTap: _clearAll),
            const SizedBox(width: AppSpacing.sm),
            _PrimaryActionButton(onTap: _convert),
          ],
        ),
      ),
    );
  }

  String _directionLabel(bool source) {
    if (_isTextMode) {
      if (_isEncode) return source ? '文本' : 'Base64';
      return source ? 'Base64' : '文本';
    }
    if (_isEncode) return source ? '图片文件' : 'Base64';
    return source ? 'Base64' : '图片文件';
  }

  Widget _buildInputPanel() {
    return _CodePanel(
      title: _inputTitle,
      subtitle: _inputSubtitle,
      badge: 'SOURCE',
      child: _isTextMode || !_isEncode
          ? _buildTextInput()
          : _ImagePickerPanel(
              path: _selectedImagePath,
              onPick: _pickImageFile,
              onConvert: _convert,
            ),
    );
  }

  String get _inputTitle {
    if (_isTextMode) return _isEncode ? '输入文本' : '输入 Base64';
    return _isEncode ? '选择图片' : '输入图片 Base64';
  }

  String get _inputSubtitle {
    if (_isTextMode || !_isEncode) {
      return '${_inputController.text.length} chars';
    }
    if (_selectedImagePath == null) return '等待选择图片';
    return _selectedImagePath!.split('/').last;
  }

  String get _inputHint {
    if (_isTextMode) {
      return _isEncode ? '在此输入需要编码的文本...' : '在此粘贴 Base64 文本...';
    }
    return _isEncode
        ? '点击选择图片按钮，从本地选取图片文件'
        : '粘贴图片 Base64 或 data:image/png;base64,...';
  }

  Widget _buildTextInput() {
    return TextField(
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
        hintText: _inputHint,
        hintStyle: CodeStyle.inputText.copyWith(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildOutputPanel() {
    return _CodePanel(
      title: _isEncode ? 'Base64 输出' : (_isTextMode ? '文本输出' : '图片输出'),
      subtitle: _error != null
          ? '转换异常'
          : _output.isEmpty
              ? '等待转换'
              : '${_output.length} chars',
      badge: 'TARGET',
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
        icon: Icons.code_rounded,
        title: '等待输入',
        message:
            _isTextMode ? '输入文本或 Base64 后点击转换。' : '选择图片或输入图片 Base64 后点击转换。',
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            if (_previewBytes != null) _ImagePreview(bytes: _previewBytes!),
            Expanded(
              child: Scrollbar(
                controller: _outputScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _outputScrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SelectableText(_output, style: CodeStyle.outputText),
                ),
              ),
            ),
          ],
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

class _ModeSegment extends StatelessWidget {
  final _Base64Mode mode;
  final ValueChanged<_Base64Mode> onChanged;

  const _ModeSegment({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            label: '文本',
            selected: mode == _Base64Mode.text,
            onTap: () => onChanged(_Base64Mode.text),
          ),
          _ModeButton(
            label: '图片',
            selected: mode == _Base64Mode.image,
            onTap: () => onChanged(_Base64Mode.image),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: 5),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color:
                  selected ? AppColors.primaryStart : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final Uint8List bytes;

  const _ImagePreview({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Image.memory(bytes, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
          return const Center(
            child: Text(
              '图片预览不可用，但字节内容已解析。',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          );
        }),
      ),
    );
  }
}

class _ImagePickerPanel extends StatelessWidget {
  final String? path;
  final VoidCallback onPick;
  final VoidCallback onConvert;

  const _ImagePickerPanel({
    required this.path,
    required this.onPick,
    required this.onConvert,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = path?.split('/').last;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryStart.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_photo_alternate_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                fileName ?? '选择一张图片',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                path ?? '支持 PNG、JPG、GIF、WebP、BMP、SVG',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _PickerActionButton(
                    icon: Icons.folder_open_rounded,
                    label: path == null ? '选择图片' : '重新选择',
                    onTap: onPick,
                  ),
                  if (path != null)
                    _PickerActionButton(
                      icon: Icons.play_arrow_rounded,
                      label: '转 Base64',
                      onTap: onConvert,
                      primary: true,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _PickerActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: primary ? null : Colors.white,
        gradient: primary ? AppGradients.primary : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: primary ? null : Border.all(color: AppColors.borderLight),
        boxShadow: primary ? AppShadows.soft : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: primary ? Colors.white : AppColors.primaryStart,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: primary ? Colors.white : AppColors.textPrimary,
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
                            fontSize: 11, color: AppColors.textMuted),
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

  const _DirectionChip(
      {required this.from, required this.to, required this.onTap});

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
              horizontal: AppSpacing.sm, vertical: 6),
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

  const _ToolBtn(
      {required this.icon, required this.label, required this.onTap});

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
            padding:
                EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
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

  const _IconAction(
      {required this.icon, required this.tooltip, required this.onTap});

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
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
