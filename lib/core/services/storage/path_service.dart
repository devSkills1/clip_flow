import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as path_provider;

/// 路径管理服务
///
/// 统一管理应用的文件路径访问，避免重复的权限请求
/// 通过缓存机制确保 getApplicationDocumentsDirectory() 只被调用一次
class PathService {
  /// 单例工厂构造函数
  factory PathService() => _instance;
  PathService._internal();
  static final PathService _instance = PathService._internal();

  /// 获取单例实例
  ///
  /// 确保在整个应用生命周期内只有一个实例
  static PathService get instance => _instance;

  Directory? _documentsDirectory;
  Directory? _temporaryDirectory;
  Directory? _applicationSupportDirectory;

  /// 获取应用文档目录
  ///
  /// 首次调用时会触发权限请求，后续调用使用缓存
  Future<Directory> getDocumentsDirectory() async {
    _documentsDirectory ??= await path_provider.getApplicationDocumentsDirectory();
    return _documentsDirectory!;
  }

  /// 获取临时目录
  Future<Directory> getTemporaryDirectory() async {
    _temporaryDirectory ??= await path_provider.getTemporaryDirectory();
    return _temporaryDirectory!;
  }

  /// 获取应用支持目录
  Future<Directory> getApplicationSupportDirectory() async {
    _applicationSupportDirectory ??= await path_provider.getApplicationSupportDirectory();
    return _applicationSupportDirectory!;
  }

  /// 获取数据库路径
  Future<String> getDatabasePath(String databaseName) async {
    final supportDir = await getApplicationSupportDirectory();
    return '${supportDir.path}/$databaseName';
  }

  /// 获取日志目录路径
  Future<String> getLogsDirectoryPath() async {
    final supportDir = await getApplicationSupportDirectory();
    return '${supportDir.path}/logs';
  }

  /// 获取文件保存路径
  Future<String> getFileSavePath(String fileName) async {
    final supportDir = await getApplicationSupportDirectory();
    return '${supportDir.path}/$fileName';
  }

  /// 获取下载目录路径（使用临时目录）
  Future<String> getDownloadPath(String fileName) async {
    final tempDir = await getTemporaryDirectory();
    return '${tempDir.path}/$fileName';
  }

  /// 清除缓存（用于测试或重置）
  void clearCache() {
    _documentsDirectory = null;
    _temporaryDirectory = null;
    _applicationSupportDirectory = null;
  }

  /// 检查目录是否存在，不存在则创建
  Future<Directory> ensureDirectoryExists(String path) async {
    final directory = Directory(path);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return directory;
  }

  /// 将相对路径转换为绝对路径
  ///
  /// 支持多种路径格式：
  /// - 绝对路径（Unix: /path/to/file, Windows: C:\path\to\file）
  /// - file:// URI
  /// - 相对路径（media/images/file.png）
  Future<String> resolveAbsolutePath(String path) async {
    try {
      // 处理 file:// URI
      if (path.startsWith('file://')) {
        return Uri.parse(path).toFilePath();
      }

      // 检查是否已经是绝对路径
      final isAbsoluteUnix = path.startsWith('/');
      final isAbsoluteWin = RegExp(r'^[A-Za-z]:\\').hasMatch(path);

      if (isAbsoluteUnix || isAbsoluteWin) {
        return path; // 已经是绝对路径，直接返回
      }

      // 相对路径：拼接应用支持目录
      final supportDir = await getApplicationSupportDirectory();
      return p.join(supportDir.path, path);
    } on Exception catch (_) {
      // 如果转换失败，返回原始路径
      return path;
    }
  }

  /// 检查文件是否存在（支持相对和绝对路径）
  Future<bool> fileExists(String path) async {
    try {
      final absolutePath = await resolveAbsolutePath(path);
      final file = File(absolutePath);
      return file.existsSync();
    } on Exception catch (_) {
      return false;
    }
  }
}
