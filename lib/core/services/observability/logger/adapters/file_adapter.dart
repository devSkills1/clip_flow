import 'dart:async';
import 'dart:io' as io;

import 'package:clip_flow/core/services/observability/index.dart';
import 'package:clip_flow/core/services/storage/index.dart';
import 'package:flutter/foundation.dart';

/// 文件日志适配器：
/// - Web 环境自动返回 null（通过工厂）
/// - 非 Web：按日期滚动，每天一个文件：`logsDir`/`yyyy-mm-dd`.log
/// - 自动清理：保留最新的N个日志文件，避免按绝对日期删除导致的问题
class FileLogAdapter implements LogAdapter {
  FileLogAdapter._(this._dirPath, [this.maxRetentionDays = 7]);

  /// 日志目录路径
  final String _dirPath;

  /// 日志文件最大保留数量（保留最新的N个文件）
  final int maxRetentionDays;

  io.File? _currentFile;
  String? _currentDateKey;
  bool _creating = false;

  /// 创建文件日志适配器，Web 环境自动返回 null
  ///
  /// [customDir] 自定义日志目录路径，为空时使用默认目录
  /// [maxRetentionDays] 日志文件最大保留数量，默认保留最新的7个文件
  static Future<FileLogAdapter?> create({String? customDir, int maxRetentionDays = 7}) async {
    if (kIsWeb) return null;
    try {
      final baseDir = customDir ?? await _defaultLogsDir();
      final d = io.Directory(baseDir);
      if (!d.existsSync()) {
        d.createSync(recursive: true);
      }
      final adapter = FileLogAdapter._(d.path, maxRetentionDays);
      // 初始化时清理旧日志文件
      await adapter._cleanupOldLogs();
      return adapter;
    } on Exception catch (_) {
      return null;
    }
  }

  static Future<String> _defaultLogsDir() async {
    // 移动/桌面：应用文档目录/logs
    return PathService.instance.getLogsDirectoryPath();
  }

  @override
  Future<void> log(LogRecord record) async {
    try {
      final file = await _resolveFile(record);
      final line = _format(record);
      await file.writeAsString(
        '$line\n',
        mode: io.FileMode.append,
        flush: true,
      );
    } on Exception catch (_) {
      // 忽略文件写入错误（例如权限问题）
    }
  }

  Future<io.File> _resolveFile(LogRecord record) async {
    // 若存在 id，则按 id 拆分日志文件：<dir>/<id>.log
    final id = (record.id ?? '').trim();
    if (id.isNotEmpty) {
      final safe = _sanitizeFileName(id);
      final path = '$_dirPath/$safe.log';
      final f = io.File(path);
      if (!f.existsSync()) {
        f.createSync(recursive: true);
      }
      // 使用 id 文件时不参与日期滚动缓存键
      _currentFile = f;
      _currentDateKey = null;
      return f;
    }

    // 否则按日期滚动（保持原逻辑）
    final dateKey = _dateKey(record.time);
    if (_currentFile != null && _currentDateKey == dateKey) {
      return _currentFile!;
    }

    // 防止并发创建
    while (_creating) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    if (_currentFile != null && _currentDateKey == dateKey) {
      return _currentFile!;
    }

    _creating = true;
    try {
      final path = '$_dirPath/$dateKey.log';
      final f = io.File(path);
      if (!f.existsSync()) {
        f.createSync(recursive: true);
        // 创建新日志文件时清理旧文件
        await _cleanupOldLogs();
      }
      _currentFile = f;
      _currentDateKey = dateKey;
      return f;
    } finally {
      _creating = false;
    }
  }

  String _format(LogRecord r) {
    final ts = _fmtTime(r.time);
    final level = r.level.label;
    final tag = r.tag != null ? ' [${r.tag}]' : '';
    final id = r.id != null ? ' (#${r.id})' : '';
    final fields = (r.fields != null && r.fields!.isNotEmpty)
        ? ' ${_fmtFields(r.fields!)}'
        : '';
    final base = '$ts $level$tag$id - ${r.message}$fields';

    if (r.error != null || r.stackTrace != null) {
      final err = r.error != null ? ' error=${r.error}' : '';
      final st = r.stackTrace != null ? '\nstack=${r.stackTrace}' : '';
      return '$base$err$st';
    }
    return base;
  }

  String _dateKey(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)}';
  }

  String _fmtTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    final msec = t.millisecond.toString().padLeft(3, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.$msec';
  }

  String _fmtFields(Map<String, Object?> fields) {
    return fields.entries.map((e) => '${e.key}=${e.value}').join(' ');
  }

  String _sanitizeFileName(String name) {
    // 仅保留字母、数字、下划线、连字符与点，其余替换为下划线
    final sanitized = name.replaceAll(RegExp('[^A-Za-z0-9._-]'), '_');
    // 避免空或全被替换
    return sanitized.isEmpty ? 'default' : sanitized;
  }

  /// 清理日志文件，保留最新的maxRetentionDays个文件
  Future<void> _cleanupOldLogs() async {
    try {
      final dir = io.Directory(_dirPath);
      if (!dir.existsSync()) return;

      final logFiles = <io.File>[];

      // 收集所有日期格式的日志文件
      await for (final entity in dir.list()) {
        if (entity is io.File && entity.path.endsWith('.log')) {
          final fileName = entity.path.split('/').last;

          // 跳过ID文件（格式：<id>.log），只清理日期文件（格式：yyyy-mm-dd.log）
          if (!_isDateLogFile(fileName)) continue;

          logFiles.add(entity);
        }
      }

      // 如果文件数量少于等于保留天数，不需要清理
      if (logFiles.length <= maxRetentionDays) return;

      // 按文件修改时间排序（最新的在前）
      logFiles.sort((a, b) {
        final aModified = a.statSync().modified;
        final bModified = b.statSync().modified;
        return bModified.compareTo(aModified); // 降序排列
      });

      // 删除超出保留数量的旧文件
      final filesToDelete = logFiles.skip(maxRetentionDays);
      for (final file in filesToDelete) {
        try {
          await file.delete();
        } on Exception catch (_) {
          // 忽略删除失败
        }
      }
    } on Exception catch (_) {
      // 忽略清理过程中的错误
    }
  }

  /// 检查是否为日期格式的日志文件（yyyy-mm-dd.log）
  bool _isDateLogFile(String fileName) {
    final nameWithoutExt = fileName.replaceAll('.log', '');
    final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    return datePattern.hasMatch(nameWithoutExt);
  }

  @override
  FutureOr<void> dispose() {
    _currentFile = null;
    _currentDateKey = null;
  }
}
