// Curl 工具 —— 主界面
// 输入 curl 命令 → 发送请求 → 展示响应（JSON 树形 / HTML 预览 / 纯文本 / Headers）


import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_container.dart';
import '../json_tool/json_models.dart';
import '../json_tool/json_tree_widget.dart';
import 'curl_parser.dart';
import 'http_engine.dart';

/// 响应展示选项卡
enum ResponseTab { body, headers, raw }

class CurlToolScreen extends StatefulWidget {
  const CurlToolScreen({super.key});

  @override
  State<CurlToolScreen> createState() => _CurlToolScreenState();
}

class _CurlToolScreenState extends State<CurlToolScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  // 发送状态
  bool _isLoading = false;

  // 响应结果
  HttpResponse? _response;

  // 当前选中的展示选项卡
  ResponseTab _currentTab = ResponseTab.body;

  // 解析后的请求信息（供调试查看）
  CurlRequest? _parsedRequest;

  // 解析错误
  String? _parseError;
  String? _sendError;

  // JSON 树形节点（当响应为 JSON 时）
  JsonTreeNode? _jsonRoot;

  void _loadSample() {
    const sample =
        "curl 'https://jsonplaceholder.typicode.com/todos/1' \\\n  -H 'User-Agent: JNTool/1.0'";
    _inputController.text = sample;
    _clearResults();
  }

  void _loadSamplePost() {
    const sample =
        "curl 'https://jsonplaceholder.typicode.com/posts' \\\n  -H 'Content-Type: application/json' \\\n  -d '{\"name\":\"JNTool\",\"version\":\"1.0.0\"}'";
    _inputController.text = sample;
    _clearResults();
  }

  void _clearAll() {
    _inputController.clear();
    _clearResults();
    _inputFocus.requestFocus();
  }

  void _clearResults() {
    setState(() {
      _response = null;
      _parsedRequest = null;
      _parseError = null;
      _sendError = null;
      _jsonRoot = null;
      _isLoading = false;
    });
  }

  /// 发送请求
  Future<void> _sendRequest() async {
    final raw = _inputController.text.trim();
    if (raw.isEmpty) return;

    setState(() {
      _isLoading = true;
      _response = null;
      _parseError = null;
      _sendError = null;
      _jsonRoot = null;
    });

    // 1. 解析 curl 命令
    final parsed = CurlParser.parse(raw);
    if (parsed == null) {
      setState(() {
        _parseError = '无法解析 curl 命令，请检查格式';
        _isLoading = false;
      });
      return;
    }

    _parsedRequest = parsed;

    // 2. 发送 HTTP 请求
    try {
      final response = await HttpEngine.send(parsed);
      setState(() {
        if (response.error != null) {
          _sendError = response.error;
        } else {
          _response = response;
        }
        _isLoading = false;
        _jsonRoot = _buildJsonTree(response);
      });
    } catch (e) {
      setState(() {
        _sendError = '请求失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 响应为 JSON 时构建树形节点
  JsonTreeNode? _buildJsonTree(HttpResponse response) {
    if (!response.isJson) return null;
    try {
      return JsonTreeBuilder.fromString(response.textBody);
    } catch (_) {
      return null;
    }
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
          // ----- 主体：输入区 + 结果区 -----
          Expanded(
            child: Row(
              children: [
                // 左侧：curl 输入
                Expanded(flex: 2, child: _buildInputPanel()),
                const SizedBox(width: AppSpacing.sm),
                // 右侧：响应展示
                Expanded(flex: 3, child: _buildResponsePanel()),
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
          '🌐 Curl 请求工具',
          style: TextStyle(
            fontSize: AppTypography.h2Size,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (_response != null)
          _buildStatusCodeBadge(_response!.statusCode),
        const Spacer(),
        _ToolbarBtn(icon: Icons.auto_fix_high, label: 'GET 示例', onTap: _loadSample),
        const SizedBox(width: AppSpacing.xs),
        _ToolbarBtn(icon: Icons.auto_fix_high, label: 'POST 示例', onTap: _loadSamplePost),
        const SizedBox(width: AppSpacing.xs),
        _ToolbarBtn(icon: Icons.delete_outline, label: '清空', onTap: _clearAll),
        const SizedBox(width: AppSpacing.sm),
        // 发送按钮
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
              onTap: _isLoading ? null : _sendRequest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isLoading ? Icons.hourglass_top : Icons.send_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isLoading ? '发送中...' : '发送',
                      style: const TextStyle(
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

  /// 状态码徽章
  Widget _buildStatusCodeBadge(int code) {
    final isSuccess = code >= 200 && code < 300;
    final isRedirect = code >= 300 && code < 400;
    final isError = code >= 400;

    Color bgColor;
    if (isSuccess) {
      bgColor = const Color(0xFF059669); // Emerald-600
    } else if (isRedirect) {
      bgColor = const Color(0xFFD97706); // Amber-600
    } else if (isError) {
      bgColor = const Color(0xFFE11D48); // Rose-600
    } else {
      bgColor = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: bgColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$code ${_response?.statusMessage ?? ''}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: bgColor,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  /// 左侧输入面板
  Widget _buildInputPanel() {
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
                  '📝 curl 命令',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_parsedRequest != null)
                  Text(
                    '${_parsedRequest!.method} ${_parsedRequest!.url.length > 30 ? _parsedRequest!.url.substring(0, 30) + "..." : _parsedRequest!.url}',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'monospace'),
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
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: '粘贴 curl 命令...\ne.g. curl \'https://api.example.com\' -H \'Header: value\'',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 右侧响应面板
  Widget _buildResponsePanel() {
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
          // 标题 + 选项卡
          Row(
            children: [
              const Text(
                '📥 响应结果',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_response != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${_response!.elapsed.inMilliseconds}ms · ${_response!.sizeLabel}',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
              const Spacer(),
              if (_response != null)
                _buildTabBar(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // 内容区
          Expanded(child: _buildResponseContent()),
        ],
      ),
    );
  }

  /// 选项卡切换栏
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassBorder,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TabButton(
            label: '响应体',
            icon: Icons.description_outlined,
            isActive: _currentTab == ResponseTab.body,
            onTap: () => setState(() => _currentTab = ResponseTab.body),
          ),
          _TabButton(
            label: 'Headers',
            icon: Icons.list_alt,
            isActive: _currentTab == ResponseTab.headers,
            onTap: () => setState(() => _currentTab = ResponseTab.headers),
          ),
          _TabButton(
            label: 'Raw',
            icon: Icons.code,
            isActive: _currentTab == ResponseTab.raw,
            onTap: () => setState(() => _currentTab = ResponseTab.raw),
          ),
        ],
      ),
    );
  }

  /// 响应内容
  Widget _buildResponseContent() {
    // 加载中
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              '正在发送请求...',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // 解析错误
    if (_parseError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 32)),
            const SizedBox(height: AppSpacing.sm),
            Text(_parseError!, style: const TextStyle(fontSize: 13, color: AppColors.accentRose)),
          ],
        ),
      );
    }

    // 发送错误
    if (_sendError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('❌', style: TextStyle(fontSize: 32)),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                _sendError!,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.accentRose),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    // 空状态
    if (_response == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌐', style: TextStyle(fontSize: 40)),
            const SizedBox(height: AppSpacing.md),
            const Text(
              '在左侧粘贴 curl 命令\n然后点击「发送」',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text('试试示例请求吧 ✨', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      );
    }

    // 根据选项卡展示不同内容
    switch (_currentTab) {
      case ResponseTab.body:
        return _buildBodyContent();
      case ResponseTab.headers:
        return _buildHeadersContent();
      case ResponseTab.raw:
        return _buildRawContent();
    }
  }

  /// 响应体展示（JSON 树形 / HTML / 纯文本）
  Widget _buildBodyContent() {
    // 空响应体
    if (_response!.textBody.isEmpty) {
      return const Center(
        child: Text('响应体为空', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
      );
    }

    // JSON 响应 → 树形展示
    if (_response!.isJson && _jsonRoot != null) {
      return JsonTreeWidget(root: _jsonRoot!);
    }

    // HTML 响应 → 展示清理后的文本
    if (_response!.contentType == ResponseContentType.html) {
      return _buildHtmlContent();
    }

    // 纯文本响应
    return SingleChildScrollView(
      child: SelectableText(
        _response!.textBody,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.6,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  /// HTML 内容展示（清理掉标签，展示文本）
  Widget _buildHtmlContent() {
    // 简单清理 HTML 标签
    final cleanText = _response!.textBody
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HTML 标识
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'HTML',
              style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600,
                color: Color(0xFFD97706), fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            cleanText.length > 1000
                ? '${cleanText.substring(0, 1000)}...\n\n(内容过长，点击 Raw 查看完整响应)'
                : cleanText,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Headers 展示
  Widget _buildHeadersContent() {
    final headers = _response!.headers;
    if (headers.isEmpty) {
      return const Center(
        child: Text('无响应头', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return ListView(
      children: headers.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.key}: ',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryStart,
                ),
              ),
              Expanded(
                child: SelectableText(
                  entry.value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Raw 响应展示
  Widget _buildRawContent() {
    return SingleChildScrollView(
      child: SelectableText(
        _response!.textBody,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          height: 1.5,
          color: AppColors.textPrimary,
        ),
      ),
    );
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
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== 选项卡按钮 ==========
class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.glassWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isActive ? AppColors.primaryStart : AppColors.textMuted),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primaryStart : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
