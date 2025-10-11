import 'dart:async';

import 'package:clip_flow_pro/core/services/observability/index.dart';
import 'package:flutter/foundation.dart';

/// 控制台日志适配器
class ConsoleLogAdapter implements LogAdapter {
  @override
  void log(LogRecord record) {
    final ts = _fmtTime(record.time);
    final level = record.level.label.padRight(5);
    final tag = record.tag != null ? ' [${record.tag}]' : '';
    final id = record.id != null ? ' (#${record.id})' : '';
    final fields = (record.fields != null && record.fields!.isNotEmpty)
        ? ' ${_fmtFields(record.fields!)}'
        : '';
    final base = '$ts $level$tag$id - ${record.message}$fields';

    if (record.error != null || record.stackTrace != null) {
      debugPrint(
        '$base\n  error: ${record.error}\n  stack: ${record.stackTrace ?? ''}',
      );
    } else {
      debugPrint(base);
    }
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

  @override
  FutureOr<void> dispose() {
    // no-op for console
  }
}
