// WebDAV 工具的数据模型。
// 这些模型保持纯 Dart，便于本地存储、网络层和 UI 共享并独立测试。

class WebDavConnection {
  final String id;
  final String name;
  final String baseUrl;
  final String username;
  final String password;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WebDavConnection({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.username,
    required this.password,
    required this.createdAt,
    required this.updatedAt,
  });

  String get normalizedBaseUrl {
    var value = baseUrl.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  WebDavConnection copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? username,
    String? password,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WebDavConnection(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'username': username,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WebDavConnection.fromJson(Map<String, dynamic> json) {
    return WebDavConnection(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      baseUrl: (json['baseUrl'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class WebDavFileEntry {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime? modifiedAt;

  const WebDavFileEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.modifiedAt,
  });

  String get displayName => name.isEmpty ? '/' : name;

  String get sizeLabel {
    if (isDirectory) return '--';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class WebDavOperationResult {
  final bool success;
  final String message;

  const WebDavOperationResult({
    required this.success,
    required this.message,
  });
}
