import 'dart:io';

import 'package:clip_flow_pro/core/services/observability/index.dart';
import 'package:flutter/foundation.dart';

/// 崩溃监控服务 (Local Only Version)
///
/// 负责应用崩溃和错误的监控和本地记录
/// 注意：此版本已移除 Sentry 上报功能，仅保留本地日志记录
class CrashService {
  /// 工厂构造：返回崩溃监控服务单例
  factory CrashService() => _instance;

  /// 私有构造：单例内部初始化
  CrashService._internal();

  /// 单例实例
  static final CrashService _instance = CrashService._internal();

  /// 是否已初始化
  bool _isInitialized = false;

  /// 初始化崩溃监控服务
  Future<void> initialize() async {
    if (_isInitialized) {
      await Log.i('CrashService already initialized');
      return;
    }

    try {
      // 设置初始上下文信息（仅本地记录）
      await _setUserContext();
      await _setTags();

      _isInitialized = true;
      await Log.i('CrashService initialized successfully (local only mode)');
    } on Exception catch (e, stackTrace) {
      await Log.e(
        'Failed to initialize CrashService: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 上报错误（本地记录）
  static Future<void> reportError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? extra,
    // 保持 SentryLevel 参数兼容性，但不再使用
    @Deprecated('No longer used - kept for API compatibility') dynamic level,
  }) async {
    // 直接记录到本地日志
    await Log.e(
      'Error recorded locally: $error${context != null ? ' (Context: $context)' : ''}',
      error: error,
      stackTrace: stackTrace,
      fields: extra,
    );
  }

  /// 上报消息（本地记录）
  static Future<void> reportMessage(
    String message, {
    @Deprecated('No longer used - kept for API compatibility') dynamic level,
    Map<String, dynamic>? extra,
  }) async {
    await Log.i(
      'Message recorded locally: $message',
      fields: extra,
    );
  }

  /// 添加面包屑（本地记录）
  static Future<void> addBreadcrumb(
    String message, {
    String? category,
    @Deprecated('No longer used - kept for API compatibility') dynamic level,
    Map<String, dynamic>? data,
  }) async {
    await Log.d(
      'Breadcrumb: $message${category != null ? ' (Category: $category)' : ''}',
      fields: data,
    );
  }

  /// 设置用户上下文（本地记录）
  static Future<void> setUserContext({
    String? userId,
    String? email,
    String? username,
    Map<String, dynamic>? extra,
  }) async {
    await Log.i(
      'User context set: ${userId ?? 'anonymous'}',
      fields: {
        'user_id': userId,
        'email': email,
        'username': username,
        ...?extra,
      },
    );
  }

  /// 设置自定义上下文信息（本地记录）
  static Future<void> setContext(
    String key,
    Map<String, dynamic> context,
  ) async {
    await Log.d(
      'Context set: $key',
      fields: {key: context},
    );
  }

  /// 设置额外信息（本地记录）
  static Future<void> setExtra(String key, dynamic value) async {
    await Log.d(
      'Extra info set: $key',
      fields: {'extra_$key': value},
    );
  }

  /// 设置标签（本地记录）
  static Future<void> setTag(String key, String value) async {
    await Log.d(
      'Tag set: $key = $value',
    );
  }

  
  /// 设置初始用户上下文
  Future<void> _setUserContext() async {
    await setUserContext(
      userId: 'anonymous',
      extra: {
        'platform': Platform.operatingSystem,
        'platform_version': Platform.operatingSystemVersion,
        'app_version': '1.0.0+1',
      },
    );
  }

  /// 设置初始标签
  Future<void> _setTags() async {
    await setTag('platform', Platform.operatingSystem);
    await setTag('environment', kDebugMode ? 'debug' : 'release');
    await setTag('app_name', 'clip_flow_pro');
    await setTag('mode', 'local_only');
  }

  /// 销毁服务
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      _isInitialized = false;
      await Log.i('CrashService disposed (local only mode)');
    } on Exception catch (e) {
      await Log.e('Failed to dispose CrashService: $e');
    }
  }
}
