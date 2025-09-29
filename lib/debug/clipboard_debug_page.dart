import 'dart:async';

import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/debug/clipboard_debug.dart';
import 'package:flutter/material.dart';

/// 剪贴板调试页面
class ClipboardDebugPage extends StatefulWidget {
  /// 剪贴板调试页面构造函数
  const ClipboardDebugPage({super.key});

  @override
  State<ClipboardDebugPage> createState() => _ClipboardDebugPageState();
}

class _ClipboardDebugPageState extends State<ClipboardDebugPage> {
  /// 诊断结果
  Map<String, dynamic>? _diagnosticsResults;

  /// 剪贴板事件流订阅
  StreamSubscription<ClipItem>? _subscription;

  /// 是否正在监听剪贴板事件
  bool _isListening = false;

  /// 最近的剪贴板事件列表
  final List<String> _events = [];

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _diagnosticsResults = null;
    });

    final results = await ClipboardDebug.runDiagnostics();

    setState(() {
      _diagnosticsResults = results;
    });
  }

  void _toggleListening() {
    if (_isListening) {
      _subscription?.cancel();
      _subscription = null;
      setState(() {
        _isListening = false;
      });
    } else {
      _subscription = ClipboardDebug.startListening();
      _subscription?.onData((clipItem) {
        setState(() {
          _events.insert(
            0,
            '${DateTime.now()}: ${clipItem.type} - '
            '${clipItem.content?.substring(0, 30) ?? ""}...',
          );
          if (_events.length > 20) {
            _events.removeLast();
          }
        });
      });
      setState(() {
        _isListening = true;
      });
    }
  }

  Future<void> _reinitializeService() async {
    final success = await ClipboardDebug.reinitializeService();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '服务重新初始化成功' : '服务重新初始化失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('剪贴板调试工具'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 控制按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _runDiagnostics,
                    child: const Text('运行诊断'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _toggleListening,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isListening ? Colors.red : Colors.green,
                    ),
                    child: Text(_isListening ? '停止监听' : '开始监听'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _reinitializeService,
                    child: const Text('重新初始化'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 诊断结果
            if (_diagnosticsResults != null) ...[
              const Text(
                '诊断结果:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _formatDiagnostics(_diagnosticsResults!),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // 监听事件
            const Text(
              '监听事件:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _events.isEmpty
                    ? const Center(child: Text('暂无事件'))
                    : ListView.builder(
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              _events[index],
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDiagnostics(Map<String, dynamic> results) {
    final buffer = StringBuffer();

    for (final entry in results.entries) {
      buffer.writeln('${entry.key}:');
      if (entry.value is Map) {
        for (final subEntry in (entry.value as Map).entries) {
          buffer.writeln('  ${subEntry.key}: ${subEntry.value}');
        }
      } else {
        buffer.writeln('  ${entry.value}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
