import 'dart:async';
import 'dart:io';

import 'package:clip_flow_pro/core/services/observability/index.dart';
import 'package:clip_flow_pro/core/services/storage/index.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 版本信息模型
class VersionInfo {
  /// 创建版本信息实例
  const VersionInfo({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isForced,
    required this.publishedAt,
    this.minSupportedVersion,
  });

  /// 从JSON创建版本信息实例
  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      version: json['version'] as String,
      buildNumber: json['build_number'] as String,
      downloadUrl: json['download_url'] as String,
      releaseNotes: json['release_notes'] as String,
      isForced: json['is_forced'] as bool? ?? false,
      publishedAt: DateTime.parse(json['published_at'] as String),
      minSupportedVersion: json['min_supported_version'] as String?,
    );
  }

  /// 版本号
  final String version;

  /// 构建号
  final String buildNumber;

  /// 下载链接
  final String downloadUrl;

  /// 发布说明
  final String releaseNotes;

  /// 是否强制更新
  final bool isForced;

  /// 发布时间
  final DateTime publishedAt;

  /// 最低支持版本
  final String? minSupportedVersion;

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'build_number': buildNumber,
      'download_url': downloadUrl,
      'release_notes': releaseNotes,
      'is_forced': isForced,
      'published_at': publishedAt.toIso8601String(),
      'min_supported_version': minSupportedVersion,
    };
  }
}

/// 更新状态枚举
enum UpdateStatus {
  /// 检查中
  checking,

  /// 有可用更新
  available,

  /// 无可用更新
  upToDate,

  /// 下载中
  downloading,

  /// 下载完成
  downloaded,

  /// 安装中
  installing,

  /// 更新失败
  failed,

  /// 强制更新
  forced,
}

/// 自动更新服务
///
/// 负责检查、下载和安装应用更新
class UpdateService {
  /// 工厂构造：返回更新服务单例
  factory UpdateService() => _instance;

  /// 私有构造：单例内部初始化
  UpdateService._internal();

  /// 单例实例
  static final UpdateService _instance = UpdateService._internal();

  /// HTTP客户端
  final Dio _dio = Dio();

  /// 当前应用信息
  PackageInfo? _packageInfo;

  /// 更新状态流控制器
  final _statusController = StreamController<UpdateStatus>.broadcast();

  /// 下载进度流控制器
  final _progressController = StreamController<double>.broadcast();

  /// 更新状态流
  Stream<UpdateStatus> get statusStream => _statusController.stream;

  /// 下载进度流
  Stream<double> get progressStream => _progressController.stream;

  /// 当前状态
  UpdateStatus _currentStatus = UpdateStatus.upToDate;

  /// 获取当前状态
  UpdateStatus get currentStatus => _currentStatus;

  /// 最新版本信息
  VersionInfo? _latestVersion;

  /// 获取最新版本信息
  VersionInfo? get latestVersion => _latestVersion;

  /// 更新检查URL
  static const String _updateCheckUrl = String.fromEnvironment(
    'UPDATE_CHECK_URL',
  );

  /// 初始化更新服务
  Future<void> initialize() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      await Log.i(
        'UpdateService initialized with version ${_packageInfo?.version}',
      );
    } on Exception catch (e, stackTrace) {
      await Log.e(
        'Failed to initialize UpdateService: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 检查更新
  Future<bool> checkForUpdates({bool silent = false}) async {
    if (_packageInfo == null) {
      await initialize();
    }

    _updateStatus(UpdateStatus.checking);

    try {
      if (!silent) {
        await Log.i('Checking for updates...');
      }

      // 检查更新URL是否配置
      if (_updateCheckUrl.isEmpty) {
        await Log.i('Update check URL not configured, skipping update check');
        _updateStatus(UpdateStatus.upToDate);
        return false;
      }

      final response = await _dio.get<Map<String, dynamic>>(_updateCheckUrl);
      final releaseData = response.data!;

      // 解析GitHub Release API响应
      final latestVersion = _parseGitHubRelease(releaseData);
      _latestVersion = latestVersion;

      // 比较版本
      final hasUpdate = _hasNewerVersion(
        _packageInfo!.version,
        latestVersion.version,
      );

      if (hasUpdate) {
        _updateStatus(
          latestVersion.isForced ? UpdateStatus.forced : UpdateStatus.available,
        );

        if (!silent) {
          await Log.i(
            'Update available: ${latestVersion.version} '
            '(current: ${_packageInfo!.version})',
          );
        }
        return true;
      } else {
        _updateStatus(UpdateStatus.upToDate);
        if (!silent) {
          await Log.i('App is up to date');
        }
        return false;
      }
    } on Exception catch (e, stackTrace) {
      _updateStatus(UpdateStatus.failed);
      await Log.e(
        'Failed to check for updates: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 下载更新
  Future<bool> downloadUpdate() async {
    if (_latestVersion == null) {
      await Log.w('No update available to download');
      return false;
    }

    _updateStatus(UpdateStatus.downloading);

    try {
      final fileName = _getDownloadFileName(_latestVersion!.downloadUrl);
      final filePath = await PathService.instance.getDownloadPath(fileName);

      await Log.i('Downloading update to: $filePath');

      await _dio.download(
        _latestVersion!.downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _progressController.add(progress);
          }
        },
      );

      _updateStatus(UpdateStatus.downloaded);
      await Log.i('Update downloaded successfully');
      return true;
    } on Exception catch (e, stackTrace) {
      _updateStatus(UpdateStatus.failed);
      await Log.e(
        'Failed to download update: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 安装更新
  Future<bool> installUpdate() async {
    if (_latestVersion == null) {
      await Log.w('No update available to install');
      return false;
    }

    _updateStatus(UpdateStatus.installing);

    try {
      if (Platform.isMacOS) {
        return await _installMacOSUpdate();
      } else if (Platform.isWindows) {
        return await _installWindowsUpdate();
      } else if (Platform.isLinux) {
        return await _installLinuxUpdate();
      } else {
        await Log.w('Platform not supported for automatic installation');
        return false;
      }
    } on Exception catch (e, stackTrace) {
      _updateStatus(UpdateStatus.failed);
      await Log.e(
        'Failed to install update: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 打开下载页面
  Future<void> openDownloadPage() async {
    if (_latestVersion?.downloadUrl != null) {
      final uri = Uri.parse(_latestVersion!.downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  /// 安排后台检查
  void scheduleBackgroundCheck() {
    // 每24小时检查一次更新
    Timer.periodic(const Duration(hours: 24), (timer) {
      checkForUpdates(silent: true);
    });
  }

  /// 解析GitHub Release API响应
  VersionInfo _parseGitHubRelease(Map<String, dynamic> data) {
    final tagName = data['tag_name'] as String;
    final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;

    // 查找对应平台的下载链接
    final assets = data['assets'] as List<dynamic>;
    var downloadUrl = '';

    for (final asset in assets) {
      final assetMap = asset as Map<String, dynamic>;
      final name = assetMap['name'] as String;
      if (_isPlatformAsset(name)) {
        downloadUrl = assetMap['browser_download_url'] as String;
        break;
      }
    }

    return VersionInfo(
      version: version,
      buildNumber: version, // GitHub Release通常只有版本号
      downloadUrl: downloadUrl,
      releaseNotes: data['body'] as String? ?? '',
      isForced: false, // 可以通过release描述或标签判断
      publishedAt: DateTime.parse(data['published_at'] as String),
    );
  }

  /// 判断是否为当前平台的资源
  bool _isPlatformAsset(String assetName) {
    final name = assetName.toLowerCase();
    if (Platform.isMacOS) {
      return name.contains('macos') ||
          name.contains('darwin') ||
          name.endsWith('.dmg');
    } else if (Platform.isWindows) {
      return name.contains('windows') ||
          name.contains('win') ||
          name.endsWith('.exe') ||
          name.endsWith('.msi');
    } else if (Platform.isLinux) {
      return name.contains('linux') ||
          name.endsWith('.deb') ||
          name.endsWith('.rpm') ||
          name.endsWith('.appimage');
    }
    return false;
  }

  /// 比较版本号
  bool _hasNewerVersion(String currentVersion, String latestVersion) {
    final current = _parseVersion(currentVersion);
    final latest = _parseVersion(latestVersion);

    for (var i = 0; i < 3; i++) {
      if (latest[i] > current[i]) return true;
      if (latest[i] < current[i]) return false;
    }
    return false;
  }

  /// 解析版本号
  List<int> _parseVersion(String version) {
    final parts = version.split('.');
    return [
      int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0,
      int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0,
    ];
  }

  /// 获取下载文件名
  String _getDownloadFileName(String url) {
    final uri = Uri.parse(url);
    return uri.pathSegments.last;
  }

  /// 安装macOS更新
  Future<bool> _installMacOSUpdate() async {
    // macOS通常需要用户手动安装DMG文件
    await Log.i('Opening download location for manual installation');
    await openDownloadPage();
    return true;
  }

  /// 安装Windows更新
  Future<bool> _installWindowsUpdate() async {
    // Windows可以尝试自动运行安装程序
    await Log.i('Starting Windows installer');
    await openDownloadPage();
    return true;
  }

  /// 安装Linux更新
  Future<bool> _installLinuxUpdate() async {
    // Linux通常需要用户手动安装包文件
    await Log.i('Opening download location for manual installation');
    await openDownloadPage();
    return true;
  }

  /// 更新状态
  void _updateStatus(UpdateStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// 销毁服务
  Future<void> dispose() async {
    await _statusController.close();
    await _progressController.close();
    _dio.close();
    await Log.i('UpdateService disposed');
  }
}
