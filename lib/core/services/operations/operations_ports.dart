import 'dart:async';

/// 更新服务端口接口
///
/// 负责应用更新管理，包括：
/// - 检查更新
/// - 下载更新
/// - 安装更新
/// - 更新通知
abstract class UpdateServicePort {
  /// 检查是否有可用更新
  Future<bool> checkForUpdates();

  /// 获取更新信息
  Future<UpdateInfo?> getUpdateInfo();

  /// 下载更新
  Future<bool> downloadUpdate();

  /// 安装更新
  Future<bool> installUpdate();

  /// 获取下载进度
  Stream<double> get downloadProgress;

  /// 获取更新状态
  UpdateStatus get updateStatus;

  /// 设置自动检查更新
  Future<void> setAutoCheckEnabled(bool enabled);

  /// 获取更新设置
  Future<Map<String, dynamic>> getUpdateSettings();
}

/// 更新信息
class UpdateInfo {
  /// 构造函数
  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.fileSize,
    required this.releaseDate,
    required this.isForced,
  });
  
  /// 版本号
  final String version;
  
  /// 下载地址
  final String downloadUrl;
  
  /// 发布说明
  final String releaseNotes;
  
  /// 文件大小
  final int fileSize;
  
  /// 发布日期
  final DateTime releaseDate;
  
  /// 是否强制更新
  final bool isForced;
}

/// 更新状态枚举
enum UpdateStatus {
  /// 空闲状态
  idle,
  
  /// 正在检查
  checking,
  
  /// 有可用更新
  available,
  
  /// 正在下载
  downloading,
  
  /// 准备安装
  ready,
  
  /// 正在安装
  installing,
  
  /// 错误
  error,
}
