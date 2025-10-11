import 'dart:io';

import 'package:clip_flow_pro/core/services/observability/logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// 崩溃监控服务
///
/// 负责应用崩溃和错误的监控、上报和分析
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
      await SentryFlutter.init(
        (options) {
          // 使用开发环境的DSN，生产环境需要替换
          // 如果没有配置SENTRY_DSN环境变量，在开发模式下禁用远程上报
          const sentryDsn = String.fromEnvironment('SENTRY_DSN');
          if (sentryDsn.isEmpty && kDebugMode) {
            // 开发模式下，如果没有配置DSN，则禁用Sentry上报
            options.dsn = null;
            // 注意：这里不能使用await，因为在options配置回调中
            if (kDebugMode) {
              print(
                'Sentry DSN not configured, '
                'crash reporting disabled in debug mode',
              );
            }
          } else {
            options.dsn = sentryDsn.isEmpty
                ? 'https://your-dsn@sentry.io/project-id'
                : sentryDsn;
          }

          // 设置环境
          options
            ..environment = kDebugMode ? 'development' : 'production'
            // 设置发布版本
            ..release = 'clip_flow_pro@1.0.0+1'
            // 采样率设置
            ..tracesSampleRate = kDebugMode ? 1.0 : 0.1
            // 启用自动会话跟踪
            ..enableAutoSessionTracking = true
            // 设置用户上下文
            ..beforeSend = (event, hint) {
              // 在发送前可以修改事件或过滤敏感信息
              return _filterSensitiveData(event);
            };
        },
      );

      // 设置用户上下文
      await _setUserContext();

      // 设置标签
      await _setTags();

      _isInitialized = true;
      await Log.i('CrashService initialized successfully');
    } on Exception catch (e, stackTrace) {
      await Log.e(
        'Failed to initialize CrashService: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 上报错误
  static Future<void> reportError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? extra,
    SentryLevel level = SentryLevel.error,
  }) async {
    try {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          if (context != null) {
            scope.setContexts('error_context', {'message': context});
          }

          if (extra != null) {
            for (final entry in extra.entries) {
              scope.setContexts(entry.key, {'value': entry.value});
            }
          }

          scope.level = level;
        },
      );

      // 同时记录到本地日志
      await Log.e(
        'Error reported to Sentry: $error',
        error: error,
        stackTrace: stackTrace,
        fields: extra,
      );
    } on Exception catch (e) {
      // 如果Sentry上报失败，至少记录到本地日志
      await Log.e(
        'Failed to report error to Sentry: $e, Original error: $error',
        error: e,
      );
    }
  }

  /// 上报消息
  static Future<void> reportMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extra,
  }) async {
    try {
      await Sentry.captureMessage(
        message,
        level: level,
        withScope: (scope) {
          if (extra != null) {
            for (final entry in extra.entries) {
              scope.setContexts(entry.key, {'value': entry.value});
            }
          }
        },
      );
    } on Exception catch (e) {
      await Log.e('Failed to report message to Sentry: $e');
    }
  }

  /// 添加面包屑
  static Future<void> addBreadcrumb(
    String message, {
    String? category,
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? data,
  }) async {
    try {
      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: message,
          category: category,
          level: level,
          data: data,
        ),
      );
    } on Exception catch (e) {
      await Log.e('Failed to add breadcrumb: $e');
    }
  }

  /// 设置用户上下文
  static Future<void> setUserContext({
    String? userId,
    String? email,
    String? username,
    Map<String, dynamic>? extra,
  }) async {
    try {
      await Sentry.configureScope((scope) {
        scope.setUser(
          SentryUser(
            id: userId,
            email: email,
            username: username,
            data: extra,
          ),
        );
      });
    } on Exception catch (e) {
      await Log.e('Failed to set user context: $e');
    }
  }

  /// 设置自定义上下文信息
  static Future<void> setContext(
    String key,
    Map<String, dynamic> context,
  ) async {
    await Sentry.configureScope((scope) {
      scope.setContexts(key, context);
    });
  }

  /// 设置额外信息
  static Future<void> setExtra(String key, dynamic value) async {
    await Sentry.configureScope((scope) {
      scope.setContexts('extra', {key: value});
    });
  }

  /// 设置标签
  static Future<void> setTag(String key, String value) async {
    try {
      await Sentry.configureScope((scope) {
        scope.setTag(key, value);
      });
    } on Exception catch (e) {
      await Log.e('Failed to set tag: $e');
    }
  }

  /// 开始性能事务
  static ISentrySpan startTransaction(
    String name,
    String operation, {
    String? description,
  }) {
    return Sentry.startTransaction(
      name,
      operation,
      description: description,
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
  }

  /// 过滤敏感数据
  SentryEvent? _filterSensitiveData(SentryEvent event) {
    // 过滤可能包含敏感信息的字段
    final filteredEvent = event.copyWith();

    // 可以在这里过滤特定的上下文信息
    // 例如：filteredEvent.contexts.removeWhere(
    //   (key, value) => key.contains('sensitive')
    // );

    return filteredEvent;
  }

  /// 销毁服务
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await Sentry.close();
      _isInitialized = false;
      await Log.i('CrashService disposed');
    } on Exception catch (e) {
      await Log.e('Failed to dispose CrashService: $e');
    }
  }
}
