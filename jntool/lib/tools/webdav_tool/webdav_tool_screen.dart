// WebDAV 管理工具主界面。
// 三栏布局：左侧连接管理，中间文件浏览，右侧详情与文本编辑。

import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../../widgets/glass_container.dart';
import 'webdav_client.dart';
import 'webdav_models.dart';
import 'webdav_storage.dart';

class WebDavToolScreen extends StatefulWidget {
  const WebDavToolScreen({super.key});

  @override
  State<WebDavToolScreen> createState() => _WebDavToolScreenState();
}

class _WebDavToolScreenState extends State<WebDavToolScreen> {
  final WebDavConnectionStorage _storage = WebDavConnectionStorage();
  final WebDavClient _client = WebDavClient();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newFolderController = TextEditingController();
  final TextEditingController _editorController = TextEditingController();

  List<WebDavConnection> _connections = [];
  List<WebDavFileEntry> _entries = [];
  WebDavConnection? _selectedConnection;
  WebDavFileEntry? _selectedEntry;
  String _currentPath = '/';
  String? _editingPath;
  String? _statusMessage;
  String? _errorMessage;
  bool _loadingConnections = true;
  bool _busy = false;
  bool _editorDirty = false;

  @override
  void initState() {
    super.initState();
    _editorController.addListener(_handleEditorChanged);
    _loadConnections();
  }

  void _handleEditorChanged() {
    // 核心：只有打开文件后才记录脏状态，避免初始填充内容触发误提示。
    if (_editingPath != null && !_editorDirty) {
      setState(() => _editorDirty = true);
    }
  }

  Future<void> _loadConnections() async {
    try {
      final connections = await _storage.loadConnections();
      if (!mounted) return;
      setState(() {
        _connections = connections;
        _loadingConnections = false;
        if (connections.isNotEmpty) {
          _selectConnection(connections.first, loadRemote: false);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingConnections = false;
        _errorMessage = '读取本地连接失败：$e';
      });
    }
  }

  void _selectConnection(
    WebDavConnection connection, {
    bool loadRemote = true,
  }) {
    _selectedConnection = connection;
    _nameController.text = connection.name;
    _urlController.text = connection.baseUrl;
    _usernameController.text = connection.username;
    _passwordController.text = connection.password;
    _currentPath = '/';
    _entries = [];
    _selectedEntry = null;
    _clearEditor();
    _statusMessage = '已选择 ${connection.name}';
    _errorMessage = null;
    if (loadRemote) {
      _listDirectory('/');
    }
  }

  Future<void> _saveConnection() async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    if (name.isEmpty || url.isEmpty) {
      setState(() => _errorMessage = '请填写连接名称和 WebDAV 地址');
      return;
    }

    final now = DateTime.now().toUtc();
    final existing = _selectedConnection;
    final connection = WebDavConnection(
      id: existing?.id ?? now.microsecondsSinceEpoch.toString(),
      name: name,
      baseUrl: url,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final index = _connections.indexWhere((item) => item.id == connection.id);
    final next = [..._connections];
    if (index >= 0) {
      next[index] = connection;
    } else {
      next.add(connection);
    }

    await _storage.saveConnections(next);
    if (!mounted) return;
    setState(() {
      _connections = next;
      _selectConnection(connection, loadRemote: false);
      _statusMessage = '连接信息保存到本地';
      _errorMessage = null;
    });
  }

  Future<void> _deleteConnection() async {
    final connection = _selectedConnection;
    if (connection == null) return;
    final confirmed =
        await _confirm('删除连接', '确定删除 ${connection.name} 吗？远端文件不会被删除。');
    if (!confirmed) return;

    final next =
        _connections.where((item) => item.id != connection.id).toList();
    await _storage.saveConnections(next);
    if (!mounted) return;
    setState(() {
      _connections = next;
      _selectedConnection = null;
      _entries = [];
      _selectedEntry = null;
      _currentPath = '/';
      _clearForm();
      _clearEditor();
      _statusMessage = '已删除本地连接';
      _errorMessage = null;
    });
  }

  Future<void> _testConnection() async {
    final connection = _connectionFromForm();
    if (connection == null) return;
    await _runBusy(() async {
      final result = await _client.testConnection(connection);
      setState(() {
        _statusMessage = result.success ? result.message : null;
        _errorMessage = result.success ? null : result.message;
      });
    });
  }

  Future<void> _listDirectory(String path) async {
    await _runBusy(() => _loadDirectory(path));
  }

  Future<void> _loadDirectory(String path) async {
    final connection = _selectedConnection;
    if (connection == null) {
      setState(() => _errorMessage = '请先保存并选择一个连接');
      return;
    }

    final entries = await _client.listDirectory(connection, path);
    setState(() {
      _currentPath = _normalizePath(path);
      _entries = entries;
      _selectedEntry = null;
      _clearEditor();
      _statusMessage = '已加载 $_currentPath';
      _errorMessage = null;
    });
  }

  Future<void> _openEntry(WebDavFileEntry entry) async {
    if (entry.isDirectory) {
      await _listDirectory(entry.path);
      return;
    }

    setState(() {
      _selectedEntry = entry;
      _editingPath = null;
      _editorController.clear();
      _editorDirty = false;
    });
  }

  Future<void> _openTextFile() async {
    final connection = _selectedConnection;
    final entry = _selectedEntry;
    if (connection == null || entry == null || entry.isDirectory) return;

    await _runBusy(() async {
      final text = await _client.readTextFile(connection, entry.path);
      // 核心：先填充控制器，再标记正在编辑，避免初始内容触发脏状态。
      _editorController.text = text;
      setState(() {
        _editingPath = entry.path;
        _editorDirty = false;
        _statusMessage = '已打开 ${entry.name}';
        _errorMessage = null;
      });
    });
  }

  Future<void> _saveTextFile() async {
    final connection = _selectedConnection;
    final path = _editingPath;
    if (connection == null || path == null) return;

    await _runBusy(() async {
      await _client.saveTextFile(connection, path, _editorController.text);
      setState(() {
        _editorDirty = false;
        _statusMessage = '已保存 $path';
        _errorMessage = null;
      });
      await _loadDirectory(_currentPath);
    });
  }

  Future<void> _createFolder() async {
    final connection = _selectedConnection;
    final folderName = _newFolderController.text.trim();
    if (connection == null || folderName.isEmpty) return;

    final remotePath = _childPath(_currentPath, folderName);
    await _runBusy(() async {
      await _client.createDirectory(connection, remotePath);
      _newFolderController.clear();
      await _loadDirectory(_currentPath);
      setState(() => _statusMessage = '已新建文件夹 $folderName');
    });
  }

  Future<void> _deleteSelectedEntry() async {
    final connection = _selectedConnection;
    final entry = _selectedEntry;
    if (connection == null || entry == null) return;

    final confirmed =
        await _confirm('删除远端资源', '确定删除 ${entry.name} 吗？此操作会影响远端文件。');
    if (!confirmed) return;

    await _runBusy(() async {
      await _client.deleteResource(connection, entry.path);
      await _loadDirectory(_currentPath);
      setState(() => _statusMessage = '已删除 ${entry.name}');
    });
  }

  Future<void> _uploadFile() async {
    final connection = _selectedConnection;
    if (connection == null) return;

    try {
      final file = await openFile();
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final remotePath = _childPath(_currentPath, file.name);
      await _runBusy(() async {
        await _client.uploadFile(
            connection, remotePath, Uint8List.fromList(bytes));
        await _loadDirectory(_currentPath);
        setState(() => _statusMessage = '已上传 ${file.name}');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = '上传失败：$e');
    }
  }

  Future<void> _downloadSelectedFile() async {
    final connection = _selectedConnection;
    final entry = _selectedEntry;
    if (connection == null || entry == null || entry.isDirectory) return;

    try {
      final location = await getSaveLocation(suggestedName: entry.name);
      if (location == null) return;
      await _runBusy(() async {
        final bytes = await _client.downloadFile(connection, entry.path);
        final file = XFile.fromData(bytes, name: entry.name);
        await file.saveTo(location.path);
        setState(() => _statusMessage = '已下载到 ${location.path}');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = '下载失败：$e');
    }
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  WebDavConnection? _connectionFromForm() {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    if (name.isEmpty || url.isEmpty) {
      setState(() => _errorMessage = '请填写连接名称和 WebDAV 地址');
      return null;
    }
    final now = DateTime.now().toUtc();
    return WebDavConnection(
      id: _selectedConnection?.id ?? now.microsecondsSinceEpoch.toString(),
      name: name,
      baseUrl: url,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      createdAt: _selectedConnection?.createdAt ?? now,
      updatedAt: now,
    );
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _clearForm() {
    _nameController.clear();
    _urlController.clear();
    _usernameController.clear();
    _passwordController.clear();
  }

  void _clearEditor() {
    _editingPath = null;
    _editorController.clear();
    _editorDirty = false;
  }

  String _normalizePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty || trimmed == '/') return '/';
    final value = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    return value.startsWith('/') ? value : '/$value';
  }

  String _parentPath(String path) {
    final normalized = _normalizePath(path);
    if (normalized == '/') return '/';
    final index = normalized.lastIndexOf('/');
    if (index <= 0) return '/';
    return normalized.substring(0, index);
  }

  String _childPath(String parent, String child) {
    final cleanChild = child.replaceAll('/', '').trim();
    return parent == '/' ? '/$cleanChild' : '$parent/$cleanChild';
  }

  @override
  void dispose() {
    _editorController.removeListener(_handleEditorChanged);
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _newFolderController.dispose();
    _editorController.dispose();
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                const minContentWidth = 1120.0;
                final contentWidth = constraints.maxWidth < minContentWidth
                    ? minContentWidth
                    : constraints.maxWidth;
                // 核心：三栏是桌面管理台形态，小宽度下横向滚动而不是强行压缩溢出。
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: contentWidth,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 270, child: _buildConnectionPanel()),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(flex: 5, child: _buildFilePanel()),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(flex: 4, child: _buildDetailPanel()),
                      ],
                    ),
                  ),
                );
              },
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
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_queue_rounded,
              size: 20, color: AppColors.primaryStart),
          const SizedBox(width: AppSpacing.sm),
          const Text(
            'WebDAV 文件管理',
            style: TextStyle(
              fontSize: AppTypography.h3Size,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _StatusPill(
            text: _busy ? '处理中...' : (_statusMessage ?? '连接信息保存到本地'),
            color: _busy ? AppColors.accentAmber : AppColors.accentTeal,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _errorMessage!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.accentRose,
                  fontSize: AppTypography.captionSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else
            const Spacer(),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(left: AppSpacing.sm),
              child: Icon(
                Icons.sync_rounded,
                size: 18,
                color: AppColors.accentAmber,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionPanel() {
    return _Panel(
      title: '连接',
      badge: '${_connections.length} SAVED',
      child: Column(
        children: [
          _buildInput('名称', _nameController, Icons.label_outline_rounded),
          const SizedBox(height: AppSpacing.sm),
          _buildInput('WebDAV 地址', _urlController, Icons.link_rounded),
          const SizedBox(height: AppSpacing.sm),
          _buildInput('用户名', _usernameController, Icons.person_outline_rounded),
          const SizedBox(height: AppSpacing.sm),
          _buildInput(
            '密码 / Token',
            _passwordController,
            Icons.key_rounded,
            obscureText: true,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ActionButton(
                icon: Icons.save_rounded,
                label: '保存',
                onTap: _saveConnection,
                primary: true,
              ),
              _ActionButton(
                icon: Icons.wifi_tethering_rounded,
                label: '测试',
                onTap: _testConnection,
              ),
              _ActionButton(
                icon: Icons.add_rounded,
                label: '新建',
                onTap: () => setState(() {
                  _selectedConnection = null;
                  _clearForm();
                }),
              ),
              _ActionButton(
                icon: Icons.delete_outline_rounded,
                label: '删除',
                onTap: _deleteConnection,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _loadingConnections
                ? const _EmptyState(
                    icon: Icons.hourglass_empty_rounded,
                    title: '读取本地连接',
                    message: '正在加载 .jntool 中的 WebDAV 连接。',
                  )
                : _connections.isEmpty
                    ? const _EmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: '暂无连接',
                        message: '填写上方信息后保存到本地。',
                      )
                    : ListView.separated(
                        itemCount: _connections.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final connection = _connections[index];
                          final selected =
                              _selectedConnection?.id == connection.id;
                          return _ConnectionTile(
                            connection: connection,
                            selected: selected,
                            onTap: () {
                              setState(() {
                                _selectConnection(connection,
                                    loadRemote: false);
                              });
                              _listDirectory('/');
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePanel() {
    return _Panel(
      title: _currentPath,
      badge: '${_entries.length} ITEMS',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconButton(
            icon: Icons.arrow_upward_rounded,
            tooltip: '返回上级',
            onTap: () => _listDirectory(_parentPath(_currentPath)),
          ),
          _IconButton(
            icon: Icons.refresh_rounded,
            tooltip: '刷新',
            onTap: () => _listDirectory(_currentPath),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newFolderController,
                  decoration: _inputDecoration('新文件夹名称'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ActionButton(
                icon: Icons.create_new_folder_rounded,
                label: '新建',
                onTap: _createFolder,
              ),
              const SizedBox(width: AppSpacing.sm),
              _ActionButton(
                icon: Icons.upload_file_rounded,
                label: '上传',
                onTap: _uploadFile,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _selectedConnection == null
                ? const _EmptyState(
                    icon: Icons.cloud_sync_rounded,
                    title: '选择连接',
                    message: '保存或选择连接后加载远端目录。',
                  )
                : _entries.isEmpty
                    ? const _EmptyState(
                        icon: Icons.folder_open_rounded,
                        title: '目录为空',
                        message: '点击刷新加载，或上传文件 / 新建文件夹。',
                      )
                    : ListView.separated(
                        itemCount: _entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          final selected = _selectedEntry?.path == entry.path;
                          return _FileTile(
                            entry: entry,
                            selected: selected,
                            onTap: () => _openEntry(entry),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel() {
    final entry = _selectedEntry;
    return _Panel(
      title: entry?.displayName ?? '详情 / 编辑',
      badge: _editorDirty ? 'UNSAVED' : 'PREVIEW',
      trailing: entry == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!entry.isDirectory)
                  _IconButton(
                    icon: Icons.download_rounded,
                    tooltip: '下载文件',
                    onTap: _downloadSelectedFile,
                  ),
                _IconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: '删除远端资源',
                  onTap: _deleteSelectedEntry,
                ),
              ],
            ),
      child: entry == null
          ? const _EmptyState(
              icon: Icons.description_outlined,
              title: '选择文件',
              message: '单击文件查看详情，文本文件可打开编辑。',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetaRow(label: '路径', value: entry.path),
                _MetaRow(label: '类型', value: entry.isDirectory ? '文件夹' : '文件'),
                _MetaRow(label: '大小', value: entry.sizeLabel),
                _MetaRow(
                  label: '修改时间',
                  value: entry.modifiedAt?.toLocal().toString() ?? '--',
                ),
                const SizedBox(height: AppSpacing.md),
                if (!entry.isDirectory)
                  Row(
                    children: [
                      _ActionButton(
                        icon: Icons.edit_note_rounded,
                        label: '打开文本',
                        onTap: _openTextFile,
                        primary: true,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _ActionButton(
                        icon: Icons.save_as_rounded,
                        label: '保存编辑',
                        onTap: _editingPath == null ? null : _saveTextFile,
                      ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: _editingPath == null
                      ? _EmptyState(
                          icon: entry.isDirectory
                              ? Icons.folder_rounded
                              : Icons.text_snippet_outlined,
                          title: entry.isDirectory ? '这是文件夹' : '尚未打开文本',
                          message: entry.isDirectory
                              ? '双击或单击中间列表中的文件夹可进入。'
                              : '点击打开文本后，可编辑 UTF-8 文本并保存。',
                        )
                      : TextField(
                          controller: _editorController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: CodeStyle.inputText,
                          decoration: CodeStyle.inputDecoration(
                            fillColor: const Color(0xFF0F172A)
                                .withValues(alpha: 0.035),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: _inputDecoration(label).copyWith(
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: AppTypography.captionSize),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
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
        borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.2),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final String badge;
  final Widget child;
  final Widget? trailing;

  const _Panel({
    required this.title,
    required this.badge,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppTypography.h3Size,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StatusPill(text: badge, color: AppColors.primaryStart),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  final WebDavConnection connection;
  final bool selected;
  final VoidCallback onTap;

  const _ConnectionTile({
    required this.connection,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.bgLight : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              const Icon(Icons.cloud_done_rounded,
                  size: 18, color: AppColors.accentTeal),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connection.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      connection.normalizedBaseUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppTypography.smallSize,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  final WebDavFileEntry entry;
  final bool selected;
  final VoidCallback onTap;

  const _FileTile({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.bgLight : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                entry.isDirectory
                    ? Icons.folder_rounded
                    : Icons.insert_drive_file_rounded,
                color: entry.isDirectory
                    ? AppColors.accentAmber
                    : AppColors.primaryStart,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                entry.sizeLabel,
                style: const TextStyle(
                  fontSize: AppTypography.smallSize,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: primary ? AppColors.primaryStart : Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: primary ? null : Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: primary ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.captionSize,
                  fontWeight: FontWeight.w700,
                  color: primary ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: AppTypography.smallSize,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: AppTypography.captionSize,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppTypography.captionSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 34, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppTypography.captionSize,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
