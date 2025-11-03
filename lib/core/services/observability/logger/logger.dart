import 'dart:async';

import 'package:clip_flow_pro/core/services/observability/logger/adapters/console_adapter.dart';
import 'package:clip_flow_pro/core/services/observability/logger/adapters/file_adapter.dart';

// ignore_for_file: public_member_api_docs
// 日志系统内部使用，不需要为每个方法添加文档注释
// This logger service uses internal methods that don't require public API
// documentation.

/// 日志级别
enum LogLevel {
  trace,
  debug,
  info,
  warn,
  error,
  fatal,
}

extension LogLevelX on LogLevel {
  int get v => index;
  String get label => toString().split('.').last.toUpperCase();
}

/// 日志记录
class LogRecord {
  LogRecord({
    required this.level,
    required this.message,
    this.tag,
    this.id,
    this.error,
    this.stackTrace,
    DateTime? time,
    this.fields,
  }) : time = time ?? DateTime.now();

  final LogLevel level;
  final String message;
  final String? tag; // 模块/功能标签
  final String? id; // 业务ID / 过滤用
  final Object? error;
  final StackTrace? stackTrace;
  final DateTime time;
  final Map<String, Object?>? fields;
}

/// 日志配置
class LoggerConfig {
  LoggerConfig({
    this.enabled = true,
    this.minLevel = LogLevel.debug,
    Set<String>? includeTags,
    Set<String>? includeIds,
    this.enableConsole = true,
    this.enableFile = false,
    this.fileDirectory, // 自定义日志目录；为空则使用应用文档目录/logs
    this.maxRetentionDays = 7, // 日志文件最多保留数量（最新N个文件）
  }) : includeTags = includeTags ?? <String>{},
       includeIds = includeIds ?? <String>{};

  bool enabled;
  LogLevel minLevel;
  final Set<String> includeTags; // 非空时仅输出命中的 tag
  final Set<String> includeIds; // 非空时仅输出命中的 id
  bool enableConsole;
  bool enableFile;
  String? fileDirectory;
  int maxRetentionDays; // 日志文件保留数量（最新N个文件）
}

/// 适配器接口
abstract class LogAdapter {
  FutureOr<void> log(LogRecord record);
  FutureOr<void> dispose() {}
}

/// 日志统一入口
class Log {
  Log._();

  static final LoggerConfig _config = LoggerConfig();
  static final List<LogAdapter> _adapters = <LogAdapter>[];

  static bool _initialized = false;

  /// 初始化（可重复调用以更新配置）
  static Future<void> init(LoggerConfig config) async {
    // 更新配置
    _config.enabled = config.enabled;
    _config.minLevel = config.minLevel;
    _config.includeTags
      ..clear()
      ..addAll(config.includeTags);
    _config.includeIds
      ..clear()
      ..addAll(config.includeIds);
    _config.enableConsole = config.enableConsole;
    _config.enableFile = config.enableFile;
    _config.fileDirectory = config.fileDirectory;
    _config.maxRetentionDays = config.maxRetentionDays;

    // 重建适配器
    for (final a in _adapters) {
      await a.dispose();
    }
    _adapters.clear();

    if (_config.enableConsole) {
      _adapters.add(ConsoleLogAdapter());
    }
    if (_config.enableFile) {
      // Web 环境下会自动降级为 no-op
      final fileAdapter = await FileLogAdapter.create(
        customDir: _config.fileDirectory,
        maxRetentionDays: _config.maxRetentionDays,
      );
      if (fileAdapter != null) {
        _adapters.add(fileAdapter);
      }
    }

    _initialized = true;
  }

  // 过滤器与开关
  static bool get enabled => _config.enabled;
  static set enabled(bool value) => _config.enabled = value;

  static LogLevel get minLevel => _config.minLevel;
  static set minLevel(LogLevel value) => _config.minLevel = value;

  static void setTagFilter(Set<String>? tags) {
    _config.includeTags
      ..clear()
      ..addAll(tags ?? const {});
  }

  static void setIdFilter(Set<String>? ids) {
    _config.includeIds
      ..clear()
      ..addAll(ids ?? const {});
  }

  static Future<void> enableConsole({required bool enabled}) async {
    _config.enableConsole = enabled;
    await init(_config);
  }

  static Future<void> enableFile({
    required bool enabled,
    String? directory,
  }) async {
    _config.enableFile = enabled;
    _config.fileDirectory = directory ?? _config.fileDirectory;
    await init(_config);
  }

  // 核心派发
  static Future<void> _emit(LogRecord r) async {
    if (!_config.enabled) return;
    if (r.level.v < _config.minLevel.v) return;

    // tag 过滤
    if (_config.includeTags.isNotEmpty) {
      final tag = r.tag ?? '';
      if (!_config.includeTags.contains(tag)) return;
    }

    // id 过滤
    if (_config.includeIds.isNotEmpty) {
      final id = r.id ?? '';
      if (!_config.includeIds.contains(id)) return;
    }

    // 确保至少有控制台适配器（未 init 的兜底）
    if (!_initialized && _adapters.isEmpty) {
      _adapters.add(ConsoleLogAdapter());
    }

    // 并行投递
    final futures = _adapters.map((a) => a.log(r));
    await Future.wait(
      futures.map((f) async {
        try {
          await f;
        } on Exception catch (_) {
          // 单个适配器失败不影响其他
        }
      }),
    );
  }

  // 便捷方法
  static Future<void> t(
    Object message, {
    String? tag,
    String? id,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? fields,
  }) => _emit(
    LogRecord(
      level: LogLevel.trace,
      message: '$message',
      tag: tag,
      id: id,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    ),
  );

  static Future<void> d(
    Object message, {
    String? tag,
    String? id,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? fields,
  }) => _emit(
    LogRecord(
      level: LogLevel.debug,
      message: '$message',
      tag: tag,
      id: id,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    ),
  );

  static Future<void> i(
    Object message, {
    String? tag,
    String? id,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? fields,
  }) => _emit(
    LogRecord(
      level: LogLevel.info,
      message: '$message',
      tag: tag,
      id: id,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    ),
  );

  static Future<void> w(
    Object message, {
    String? tag,
    String? id,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? fields,
  }) => _emit(
    LogRecord(
      level: LogLevel.warn,
      message: '$message',
      tag: tag,
      id: id,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    ),
  );

  static Future<void> e(
    Object message, {
    String? tag,
    String? id,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? fields,
  }) => _emit(
    LogRecord(
      level: LogLevel.error,
      message: '$message',
      tag: tag,
      id: id,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    ),
  );

  static Future<void> f(
    Object message, {
    String? tag,
    String? id,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? fields,
  }) => _emit(
    LogRecord(
      level: LogLevel.fatal,
      message: '$message',
      tag: tag,
      id: id,
      error: error,
      stackTrace: stackTrace,
      fields: fields,
    ),
  );
}

/// 便捷用法示例：
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Log.init(LoggerConfig(
///     enabled: true,
///     minLevel: LogLevel.debug,
///     enableConsole: true,
///     enableFile: true, // 桌面/移动生效，Web 自动无操作
///     includeTags: {'home'}, // 仅输出 tag=home 的日志；留空输出全部
///     maxRetentionDays: 7, // 保留最新的7个日志文件
///   ));
///
///   Log.d('App started', tag: 'home', id: 'boot');
/// }
