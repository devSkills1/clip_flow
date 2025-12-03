import 'dart:async';
import 'dart:io';

import 'package:clip_flow_pro/core/services/observability/index.dart';
import 'package:flutter/services.dart';

/// 权限状态枚举
enum PermissionStatus {
  /// 未知状态
  unknown,

  /// 已授权
  granted,

  /// 被拒绝
  denied,

  /// 永久拒绝
  permanentlyDenied,

  /// 受限制
  restricted,
}

/// 权限类型枚举
enum PermissionType {
  /// 剪贴板权限
  clipboard,

  /// 文件访问权限
  fileAccess,

  /// 网络权限
  network,

  /// 通知权限
  notification,
}

/// 权限状态缓存项
class _PermissionCacheEntry {
  /// 创建权限缓存项
  _PermissionCacheEntry({
    required this.status,
    required this.timestamp,
    required this.validDuration,
  });

  /// 权限状态
  final PermissionStatus status;

  /// 缓存时间戳
  final DateTime timestamp;

  /// 缓存有效期
  final Duration validDuration;

  /// 检查缓存是否有效
  bool get isValid {
    return DateTime.now().difference(timestamp) < validDuration;
  }
}

/// 权限管理服务
///
/// 提供统一的权限状态管理和缓存机制，避免重复的权限检查和弹框
class PermissionService {
  /// 权限服务工厂构造函数
  factory PermissionService() {
    return _instance ??= PermissionService._internal();
  }

  /// 私有构造函数
  PermissionService._internal();

  static PermissionService? _instance;

  static const MethodChannel _platformChannel = MethodChannel(
    'clipboard_service',
  );

  // 权限状态缓存
  final Map<PermissionType, _PermissionCacheEntry> _permissionCache = {};

  // 缓存有效期配置
  static const Map<PermissionType, Duration> _cacheValidDurations = {
    PermissionType.clipboard: Duration(minutes: 5), // 剪贴板权限缓存5分钟
    PermissionType.fileAccess: Duration(minutes: 10), // 文件访问权限缓存10分钟
    PermissionType.network: Duration(hours: 1), // 网络权限缓存1小时
    PermissionType.notification: Duration(minutes: 30), // 通知权限缓存30分钟
  };

  // 权限检查防抖
  final Map<PermissionType, Timer?> _checkTimers = {};
  static const Duration _debounceDelay = Duration(milliseconds: 500);

  /// 检查权限状态（带缓存）
  Future<PermissionStatus> checkPermission(PermissionType type) async {
    // 检查缓存
    final cached = _permissionCache[type];
    if (cached != null && cached.isValid) {
      await Log.d(
        'Permission status from cache: $type -> ${cached.status}',
        tag: 'permission_service',
      );
      return cached.status;
    }

    // 防抖处理
    final existingTimer = _checkTimers[type];
    if (existingTimer != null && existingTimer.isActive) {
      await Log.d(
        'Permission check debounced: $type',
        tag: 'permission_service',
      );
      // 如果有缓存，返回缓存值，否则返回未知状态
      return cached?.status ?? PermissionStatus.unknown;
    }

    // 设置防抖定时器
    _checkTimers[type] = Timer(_debounceDelay, () {
      _checkTimers[type] = null;
    });

    // 实际检查权限
    final status = await _checkPermissionInternal(type);

    // 更新缓存
    _updateCache(type, status);

    await Log.d(
      'Permission status checked: $type -> $status',
      tag: 'permission_service',
    );

    return status;
  }

  /// 内部权限检查实现
  Future<PermissionStatus> _checkPermissionInternal(
    PermissionType type,
  ) async {
    try {
      switch (type) {
        case PermissionType.clipboard:
          return await _checkClipboardPermission();
        case PermissionType.fileAccess:
          return await _checkFileAccessPermission();
        case PermissionType.network:
          return await _checkNetworkPermission();
        case PermissionType.notification:
          return await _checkNotificationPermission();
      }
    } on Exception catch (e) {
      await Log.e(
        'Permission check failed: $type',
        tag: 'permission_service',
        error: e,
      );
      return PermissionStatus.unknown;
    }
  }

  /// 检查剪贴板权限
  Future<PermissionStatus> _checkClipboardPermission() async {
    try {
      // 尝试获取剪贴板序列号（轻量级操作）
      final result = await _platformChannel.invokeMethod<int>(
        'getClipboardSequence',
      );

      if (result != null && result >= 0) {
        return PermissionStatus.granted;
      } else {
        return PermissionStatus.denied;
      }
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        return PermissionStatus.denied;
      } else if (e.code == 'PERMISSION_PERMANENTLY_DENIED') {
        return PermissionStatus.permanentlyDenied;
      } else {
        return PermissionStatus.unknown;
      }
    }
  }

  /// 检查文件访问权限
  Future<PermissionStatus> _checkFileAccessPermission() async {
    try {
      // 在macOS上，检查是否能访问Documents目录
      if (Platform.isMacOS) {
        // 这里可以通过尝试创建临时文件来检查权限
        // 但为了避免不必要的文件操作，我们假设已授权
        return PermissionStatus.granted;
      }
      return PermissionStatus.granted;
    } on Exception catch (_) {
      return PermissionStatus.denied;
    }
  }

  /// 检查网络权限
  Future<PermissionStatus> _checkNetworkPermission() async {
    // 桌面平台通常不需要特殊的网络权限
    return PermissionStatus.granted;
  }

  /// 检查通知权限
  Future<PermissionStatus> _checkNotificationPermission() async {
    // 这里可以集成通知权限检查
    // 目前返回已授权
    return PermissionStatus.granted;
  }

  /// 更新权限缓存
  void _updateCache(PermissionType type, PermissionStatus status) {
    final validDuration =
        _cacheValidDurations[type] ?? const Duration(minutes: 5);
    _permissionCache[type] = _PermissionCacheEntry(
      status: status,
      timestamp: DateTime.now(),
      validDuration: validDuration,
    );
  }

  /// 清除特定权限的缓存
  void clearCache(PermissionType type) {
    _permissionCache.remove(type);
    unawaited(
      Log.d(
        'Permission cache cleared: $type',
        tag: 'permission_service',
      ),
    );
  }

  /// 清除所有权限缓存
  void clearAllCache() {
    _permissionCache.clear();
    unawaited(
      Log.d(
        'All permission cache cleared',
        tag: 'permission_service',
      ),
    );
  }

  /// 获取权限状态描述
  String getPermissionStatusDescription(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.unknown:
        return '未知';
      case PermissionStatus.granted:
        return '已授权';
      case PermissionStatus.denied:
        return '被拒绝';
      case PermissionStatus.permanentlyDenied:
        return '永久拒绝';
      case PermissionStatus.restricted:
        return '受限制';
    }
  }

  /// 获取权限类型描述
  String getPermissionTypeDescription(PermissionType type) {
    switch (type) {
      case PermissionType.clipboard:
        return '剪贴板权限';
      case PermissionType.fileAccess:
        return '文件访问权限';
      case PermissionType.network:
        return '网络权限';
      case PermissionType.notification:
        return '通知权限';
    }
  }

  /// 获取所有权限状态
  Future<Map<PermissionType, PermissionStatus>> getAllPermissionStatus() async {
    final result = <PermissionType, PermissionStatus>{};

    for (final type in PermissionType.values) {
      result[type] = await checkPermission(type);
    }

    return result;
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    final stats = <String, dynamic>{
      'total_cached': _permissionCache.length,
      'valid_cached': 0,
      'expired_cached': 0,
      'cache_details': <String, dynamic>{},
    };

    for (final entry in _permissionCache.entries) {
      final type = entry.key;
      final cache = entry.value;
      final isValid = cache.isValid;

      if (isValid) {
        stats['valid_cached'] = (stats['valid_cached'] as int) + 1;
      } else {
        stats['expired_cached'] = (stats['expired_cached'] as int) + 1;
      }

      (stats['cache_details'] as Map<String, dynamic>)[type.toString()] = {
        'status': cache.status.toString(),
        'timestamp': cache.timestamp.toIso8601String(),
        'valid_duration': cache.validDuration.inSeconds,
        'is_valid': isValid,
        'age_seconds': DateTime.now().difference(cache.timestamp).inSeconds,
      };
    }

    return stats;
  }

  /// 清理过期缓存
  void cleanupExpiredCache() {
    final expiredKeys = <PermissionType>[];

    for (final entry in _permissionCache.entries) {
      if (!entry.value.isValid) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _permissionCache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      unawaited(
        Log.d(
          'Cleaned up ${expiredKeys.length} expired permission cache entries',
          tag: 'permission_service',
        ),
      );
    }
  }

  /// 销毁服务
  void dispose() {
    // 取消所有定时器
    for (final timer in _checkTimers.values) {
      timer?.cancel();
    }
    _checkTimers.clear();

    // 清除缓存
    _permissionCache.clear();

    Log.d(
      'PermissionService disposed',
      tag: 'permission_service',
    );
  }
}
