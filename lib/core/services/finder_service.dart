import 'dart:io';
import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/services/logger/logger.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process/process.dart';

/// Finder服务类
///
/// 提供在Finder中显示文件和文件夹的功能
class FinderService {
  /// 工厂构造：返回Finder服务单例
  factory FinderService() => _instance;

  /// 私有构造：单例内部初始化
  FinderService._internal();

  /// 单例实例
  static final FinderService _instance = FinderService._internal();

  /// 获取Finder服务单例
  static FinderService get instance => _instance;

  /// 进程管理器
  final ProcessManager _processManager = const LocalProcessManager();

  /// 在Finder中显示指定路径的文件或文件夹
  ///
  /// [path] 要显示的文件或文件夹路径
  /// 返回操作是否成功
  Future<bool> showInFinder(String path) async {
    try {
      if (!Platform.isMacOS) {
        return false;
      }

      final file = File(path);
      final directory = Directory(path);

      // 检查路径是否存在
      if (!file.existsSync() && !directory.existsSync()) {
        throw FileSystemException('Path does not exist: $path');
      }

      // 使用 open -R 命令在Finder中显示文件/文件夹
      final result = await _processManager.run([
        'open',
        '-R',
        path,
      ]);

      return result.exitCode == 0;
    } on FileSystemException catch (e) {
      Log.e('Failed to show in Finder: $e');
      return false;
    } on Exception catch (e) {
      Log.e('Failed to show in Finder: $e');
      return false;
    }
  }

  /// 在Finder中显示数据库文件
  ///
  /// 返回操作是否成功
  Future<bool> showDatabaseInFinder() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final databasePath = join(
        documentsDirectory.path,
        ClipConstants.databaseName,
      );

      // 检查数据库文件是否存在
      final databaseFile = File(databasePath);
      if (databaseFile.existsSync()) {
        return await showInFinder(databasePath);
      } else {
        // 如果数据库文件不存在，显示文档目录
        return await showInFinder(documentsDirectory.path);
      }
    } on Exception catch (e) {
      Log.e('Failed to show database in Finder: $e');
      return false;
    }
  }

  /// 在Finder中显示应用文档目录
  ///
  /// 返回操作是否成功
  Future<bool> showAppDocumentsInFinder() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      return await showInFinder(documentsDirectory.path);
    } on Exception catch (e) {
      Log.e('Failed to show app documents in Finder: $e');
      return false;
    }
  }

  /// 在Finder中显示媒体文件目录
  ///
  /// 返回操作是否成功
  Future<bool> showMediaDirectoryInFinder() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final mediaPath = join(documentsDirectory.path, 'media');

      // 如果媒体目录不存在，显示应用文档目录
      final mediaDirectory = Directory(mediaPath);
      if (!await mediaDirectory.exists()) {
        return await showAppDocumentsInFinder();
      }

      return await showInFinder(mediaPath);
    } on Exception catch (e) {
      Log.e('Failed to show media directory in Finder: $e');
      return false;
    }
  }

  /// 在Finder中显示图片文件目录
  ///
  /// 返回操作是否成功
  Future<bool> showImageDirectoryInFinder() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final imagePath = join(documentsDirectory.path, 'media', 'images');

      // 如果图片目录不存在，显示媒体目录
      final imageDirectory = Directory(imagePath);
      if (!await imageDirectory.exists()) {
        return await showMediaDirectoryInFinder();
      }

      return await showInFinder(imagePath);
    } on Exception catch (e) {
      Log.e('Failed to show image directory in Finder: $e');
      return false;
    }
  }

  /// 在Finder中显示文件目录
  ///
  /// 返回操作是否成功
  Future<bool> showFileDirectoryInFinder() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final filePath = join(documentsDirectory.path, 'media', 'files');

      // 如果文件目录不存在，显示媒体目录
      final fileDirectory = Directory(filePath);
      if (!await fileDirectory.exists()) {
        return await showMediaDirectoryInFinder();
      }

      return await showInFinder(filePath);
    } on Exception catch (e) {
      Log.e('Failed to show file directory in Finder: $e');
      return false;
    }
  }

  /// 在Finder中显示日志文件目录
  ///
  /// 返回操作是否成功
  Future<bool> showLogDirectoryInFinder() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final logPath = join(documentsDirectory.path, 'logs');

      // 如果日志目录不存在，显示应用文档目录
      final logDirectory = Directory(logPath);
      if (!await logDirectory.exists()) {
        return await showAppDocumentsInFinder();
      }

      return await showInFinder(logPath);
    } on Exception catch (e) {
      Log.e('Failed to show log directory in Finder: $e');
      return false;
    }
  }

  /// 获取数据库文件路径
  ///
  /// 返回数据库文件的完整路径
  Future<String> getDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, ClipConstants.databaseName);
  }

  /// 获取应用文档目录路径
  ///
  /// 返回应用文档目录的完整路径
  Future<String> getAppDocumentsPath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return documentsDirectory.path;
  }

  /// 获取媒体文件目录路径
  ///
  /// 返回媒体文件目录的完整路径
  Future<String> getMediaDirectoryPath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, 'media');
  }

  /// 获取图片文件目录路径
  ///
  /// 返回图片文件目录的完整路径
  Future<String> getImageDirectoryPath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, 'media', 'images');
  }

  /// 获取文件目录路径
  ///
  /// 返回文件目录的完整路径
  Future<String> getFileDirectoryPath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, 'media', 'files');
  }

  /// 获取日志文件目录路径
  ///
  /// 返回日志文件目录的完整路径
  Future<String> getLogDirectoryPath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, 'logs');
  }
}
