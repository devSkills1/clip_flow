import 'dart:async';
import 'dart:io' as io;

import 'package:clip_flow_pro/core/services/observability/index.dart';
import 'package:clip_flow_pro/core/services/storage/index.dart';
import 'package:flutter/foundation.dart';

/// 文件日志适配器：
/// - Web 环境自动返回 null（通过工厂）
/// - 非 Web：按日期滚动，每天一个文件：`logsDir`/`yyyy-mm-dd`.log
class FileLogAdapter implements LogAdapter {
  FileLogAdapter._(this._dirPath);

  final String _dirPath;

  io.File? _currentFile;
  String? _currentDateKey;
  bool _creating = false;

  /// 创建文件日志适配器，Web 环境自动返回 null
  static Future<FileLogAdapter?> create({String? customDir}) async {
    if (kIsWeb) return null;
    try {
      final baseDir = customDir ?? await _defaultLogsDir();
      final d = io.Directory(baseDir);
      if (!d.existsSync()) {
        d.createSync(recursive: true);
      }
      return FileLogAdapter._(d.path);
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

  @override
  FutureOr<void> dispose() {
    _currentFile = null;
    _currentDateKey = null;
  }
}
