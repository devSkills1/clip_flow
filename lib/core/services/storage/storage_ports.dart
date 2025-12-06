import 'dart:io';

import 'package:clip_flow/core/models/clip_item.dart';

/// 数据库服务端口接口
///
/// 负责数据存储和管理，包括：
/// - 剪贴板项目 CRUD 操作
/// - 数据查询和过滤
/// - 数据迁移和备份
abstract class DatabaseServicePort {
  /// 初始化数据库
  Future<void> initialize();

  /// 关闭数据库连接
  Future<void> close();

  /// 插入剪贴板项目
  Future<void> insertClipItem(ClipItem item);

  /// 更新剪贴板项目
  Future<void> updateClipItem(ClipItem item);

  /// 删除剪贴板项目
  Future<void> deleteClipItem(String id);

  /// 更新剪贴板项目的收藏状态
  Future<void> updateFavoriteStatus({required String id, required bool isFavorite});

  /// 根据 ID 获取剪贴板项目
  Future<ClipItem?> getClipItem(String id);

  /// 获取所有剪贴板项目
  Future<List<ClipItem>> getAllClipItems();

  /// 根据类型获取剪贴板项目
  Future<List<ClipItem>> getClipItemsByType(ClipType type);

  /// 搜索剪贴板项目
  Future<List<ClipItem>> searchClipItems(String query);

  /// 清理过期数据（保留收藏的项目）
  Future<void> cleanupExpiredData();

  /// 清空所有剪贴项（保留收藏的项目）
  Future<void> clearAllClipItemsExceptFavorites();

  /// 清空所有剪贴项（包括收藏的项目）
  Future<void> clearAllClipItems();

  /// 获取数据库统计信息
  Future<Map<String, dynamic>> getDatabaseStats();
}

/// 加密服务端口接口
///
/// 负责数据加密和解密，包括：
/// - 敏感数据加密
/// - 数据解密
/// - 密钥管理
abstract class EncryptionServicePort {
  /// 加密数据
  Future<String> encrypt(String data);

  /// 解密数据
  Future<String> decrypt(String encryptedData);

  /// 生成加密密钥
  Future<String> generateKey();

  /// 验证加密数据完整性
  Future<bool> verifyIntegrity(String encryptedData);
}

/// 偏好设置服务端口接口
///
/// 负责应用偏好设置管理，包括：
/// - 设置保存和加载
/// - 默认值管理
/// - 设置验证
abstract class PreferencesServicePort {
  /// 加载偏好设置
  Future<dynamic> loadPreferences();

  /// 保存偏好设置
  Future<void> savePreferences(dynamic preferences);

  /// 获取特定设置
  Future<T?> getSetting<T>(String key, {T? defaultValue});

  /// 设置特定设置
  Future<void> setSetting<T>(String key, T value);

  /// 重置所有设置
  Future<void> resetSettings();

  /// 验证设置
  Future<bool> validateSettings(dynamic settings);
}

/// 路径服务端口接口
///
/// 负责文件路径管理，包括：
/// - 路径解析
/// - 文件操作
/// - 目录管理
abstract class PathServicePort {
  /// 获取文档目录
  Future<Directory> getDocumentsDirectory();

  /// 解析绝对路径
  Future<String> resolveAbsolutePath(String path);

  /// 检查文件是否存在
  Future<bool> fileExists(String path);

  /// 检查目录是否存在
  Future<bool> directoryExists(String path);

  /// 创建目录
  Future<void> createDirectory(String path);

  /// 获取文件大小
  Future<int> getFileSize(String path);

  /// 清理临时文件
  Future<void> cleanupTempFiles();
}
