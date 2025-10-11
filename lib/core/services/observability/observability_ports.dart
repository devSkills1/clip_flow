import 'dart:async';

/// 错误处理服务端口接口
///
/// 负责错误处理和报告，包括：
/// - 错误捕获
/// - 错误分析
/// - 错误报告
/// - 错误恢复
abstract class ErrorHandlerPort {
  /// 处理错误
  Future<void> handleError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
  });

  /// 记录错误
  Future<void> logError(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  });

  /// 获取错误统计
  Future<Map<String, dynamic>> getErrorStats();

  /// 清理错误日志
  Future<void> clearErrorLogs();

  /// 设置错误报告配置
  Future<void> setErrorReportingConfig(Map<String, dynamic> config);
}

/// 崩溃服务端口接口
///
/// 负责崩溃监控和报告，包括：
/// - 崩溃检测
/// - 崩溃数据收集
/// - 崩溃报告
/// - 崩溃恢复
abstract class CrashServicePort {
  /// 初始化崩溃监控
  Future<void> initialize();

  /// 报告崩溃
  Future<void> reportCrash(
    dynamic error,
    StackTrace stackTrace, {
    Map<String, dynamic>? context,
  });

  /// 获取崩溃统计
  Future<Map<String, dynamic>> getCrashStats();

  /// 获取崩溃报告
  Future<List<Map<String, dynamic>>> getCrashReports();

  /// 清理崩溃数据
  Future<void> clearCrashData();

  /// 设置崩溃报告配置
  Future<void> setCrashReportingConfig(Map<String, dynamic> config);
}

/// 日志服务端口接口
///
/// 负责日志记录和管理，包括：
/// - 日志记录
/// - 日志级别控制
/// - 日志输出
/// - 日志分析
abstract class LoggerPort {
  /// 记录调试日志
  Future<void> d(String message, {String? tag, Map<String, dynamic>? fields});

  /// 记录信息日志
  Future<void> i(String message, {String? tag, Map<String, dynamic>? fields});

  /// 记录警告日志
  Future<void> w(
    String message, {
    String? tag,
    Map<String, dynamic>? fields,
    dynamic error,
  });

  /// 记录错误日志
  Future<void> e(
    String message, {
    String? tag,
    Map<String, dynamic>? fields,
    dynamic error,
  });

  /// 设置日志级别
  Future<void> setLogLevel(LogLevel level);

  /// 获取日志统计
  Future<Map<String, dynamic>> getLogStats();

  /// 清理日志
  Future<void> clearLogs();

  /// 导出日志
  Future<String> exportLogs();
}

/// 日志级别枚举
enum LogLevel {
  /// 调试级别
  debug,
  
  /// 信息级别
  info,
  
  /// 警告级别
  warning,
  
  /// 错误级别
  error,
}
