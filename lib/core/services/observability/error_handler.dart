import 'dart:async';

import 'package:clip_flow/core/services/observability/index.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 全局错误处理器
///
/// 负责捕获和处理应用中的未处理异常
class ErrorHandler {
  /// 初始化全局错误处理
  static void initialize() {
    // 捕获Flutter框架错误
    FlutterError.onError = (FlutterErrorDetails details) {
      // 记录到日志
      unawaited(
        Log.e(
          'Flutter Error: ${details.exception}',
          error: details.exception,
          stackTrace: details.stack,
        ),
      );

      // 上报到崩溃监控
      CrashService.reportError(
        details.exception,
        details.stack,
        context: 'Flutter Framework Error',
        extra: {
          'library': details.library,
          'context': details.context?.toString(),
          'informationCollector': details.informationCollector?.toString(),
        },
      );

      // 在debug模式下显示红屏
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    // 捕获异步错误
    PlatformDispatcher.instance.onError = (error, stack) {
      // 记录到日志
      unawaited(
        Log.e(
          'Platform Error: $error',
          error: error,
          stackTrace: stack,
        ),
      );

      // 上报到崩溃监控
      CrashService.reportError(
        error,
        stack,
        context: 'Platform Error',
      );

      return true; // 表示错误已处理
    };

    // 捕获Zone错误
    runZonedGuarded(
      () {
        // 应用代码在这个Zone中运行
      },
      (error, stack) {
        // 记录到日志
        unawaited(
          Log.e(
            'Zone Error: $error',
            error: error,
            stackTrace: stack,
          ),
        );

        // 上报到崩溃监控
        CrashService.reportError(
          error,
          stack,
          context: 'Zone Error',
        );
      },
    );
  }

  /// 处理业务逻辑错误
  static Future<void> handleBusinessError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? extra,
  }) async {
    // 记录到日志
    await Log.e(
      'Business Error: $error',
      error: error,
      stackTrace: stackTrace,
      fields: extra,
    );

    // 上报到崩溃监控（非致命错误）
    await CrashService.reportError(
      error,
      stackTrace,
      context: context ?? 'Business Logic Error',
      extra: extra,
    );
  }

  /// 处理网络错误
  static Future<void> handleNetworkError(
    dynamic error,
    StackTrace? stackTrace, {
    String? url,
    String? method,
    int? statusCode,
  }) async {
    // 记录到日志
    await Log.e(
      'Network Error: $error',
      error: error,
      stackTrace: stackTrace,
      fields: {
        'url': url,
        'method': method,
        'status_code': statusCode,
      },
    );

    // 上报到崩溃监控
    await CrashService.reportError(
      error,
      stackTrace,
      context: 'Network Error',
      extra: {
        'url': url,
        'method': method,
        'status_code': statusCode,
      },
    );
  }

  /// 处理数据库错误
  static Future<void> handleDatabaseError(
    dynamic error,
    StackTrace? stackTrace, {
    String? operation,
    String? table,
    Map<String, dynamic>? query,
  }) async {
    // 记录到日志
    await Log.e(
      'Database Error: $error',
      error: error,
      stackTrace: stackTrace,
      fields: {
        'operation': operation,
        'table': table,
        'query': query?.toString(),
      },
    );

    // 上报到崩溃监控
    await CrashService.reportError(
      error,
      stackTrace,
      context: 'Database Error',
      extra: {
        'operation': operation,
        'table': table,
        'query': query?.toString(),
      },
    );
  }

  /// 处理文件系统错误
  static Future<void> handleFileSystemError(
    dynamic error,
    StackTrace? stackTrace, {
    String? operation,
    String? filePath,
  }) async {
    // 记录到日志
    await Log.e(
      'FileSystem Error: $error',
      error: error,
      stackTrace: stackTrace,
      fields: {
        'operation': operation,
        'file_path': filePath,
      },
    );

    // 上报到崩溃监控
    await CrashService.reportError(
      error,
      stackTrace,
      context: 'FileSystem Error',
      extra: {
        'operation': operation,
        'file_path': filePath,
      },
    );
  }

  /// 显示用户友好的错误消息
  static void showUserError(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? onRetry,
  }) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title ?? '错误'),
          content: Text(message),
          actions: [
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: const Text('重试'),
              ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }
}
