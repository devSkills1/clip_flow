import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// 剪贴板轮询管理器
///
/// 负责管理剪贴板的轮询检测，包括：
/// - 自适应轮询间隔调整
/// - 平台特定的剪贴板序列检查
/// - 轮询状态管理
/// - 性能优化的轮询策略
/// - 智能调度和资源管理
class ClipboardPoller {
  static const MethodChannel _platformChannel = MethodChannel(
    'clipboard_service',
  );

  // 轮询间隔配置
  static const Duration _minInterval = Duration(milliseconds: 100);
  static const Duration _maxInterval = Duration(milliseconds: 2000);
  static const Duration _defaultInterval = Duration(milliseconds: 500);
  static const Duration _idleInterval = Duration(milliseconds: 5000); // 空闲时的长间隔

  // 自适应调整参数
  static const double _speedUpFactor = 0.8;
  static const double _slowDownFactor = 1.2;
  static const int _consecutiveNoChangeThreshold = 5;
  static const int _recentChangeWindow = 10;
  static const int _idleThreshold = 50; // 进入空闲模式的阈值

  Timer? _pollingTimer;
  Duration _currentInterval = _defaultInterval;
  bool _isPolling = false;
  bool _isPaused = false;
  bool _isIdleMode = false;

  // 变化检测状态
  int _lastClipboardSequence = -1;
  int _consecutiveNoChangeCount = 0;
  final List<DateTime> _recentChanges = [];

  // 性能监控
  int _totalChecks = 0;
  int _successfulChecks = 0;
  int _failedChecks = 0;
  DateTime? _lastChangeTime;
  Duration _totalPollingTime = Duration.zero;
  DateTime? _pollingStartTime;

  // 回调函数
  VoidCallback? _onClipboardChanged;
  void Function(String error)? _onError;

  /// 开始轮询
  void startPolling({
    VoidCallback? onClipboardChanged,
    void Function(String error)? onError,
  }) {
    if (_isPolling && !_isPaused) return;

    _onClipboardChanged = onClipboardChanged;
    _onError = onError;
    _isPolling = true;
    _isPaused = false;
    _pollingStartTime = DateTime.now();

    _scheduleNextPoll();
  }

  /// 停止轮询
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    _isPaused = false;

    // 更新总轮询时间
    if (_pollingStartTime != null) {
      _totalPollingTime += DateTime.now().difference(_pollingStartTime!);
      _pollingStartTime = null;
    }

    _resetState();
  }

  /// 暂停轮询
  void pausePolling() {
    if (!_isPolling) return;

    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPaused = true;

    // 更新总轮询时间
    if (_pollingStartTime != null) {
      _totalPollingTime += DateTime.now().difference(_pollingStartTime!);
      _pollingStartTime = null;
    }
  }

  /// 恢复轮询
  void resumePolling() {
    if (!_isPolling || !_isPaused) return;

    _isPaused = false;
    _pollingStartTime = DateTime.now();
    _scheduleNextPoll();
  }

  /// 手动触发一次检查
  Future<bool> checkOnce() async {
    return _checkClipboardChange();
  }

  /// 获取当前轮询间隔
  Duration get currentInterval => _currentInterval;

  /// 获取轮询状态（是否正在进行轮询活动）
  bool get isPolling => _isPolling && !_isPaused;

  /// 是否处于空闲模式
  bool get isIdleMode => _isIdleMode;

  /// 重置轮询状态
  void _resetState() {
    _currentInterval = _defaultInterval;
    _lastClipboardSequence = -1;
    _consecutiveNoChangeCount = 0;
    _recentChanges.clear();
    _isIdleMode = false;
  }

  /// 调度下一次轮询（优化版本）
  void _scheduleNextPoll() {
    if (!_isPolling || _isPaused) return;

    // 智能调度：根据系统负载和历史模式调整
    final adjustedInterval = _getSmartInterval();

    _pollingTimer = Timer(adjustedInterval, () async {
      try {
        _totalChecks++;
        final hasChanged = await _checkClipboardChange();

        if (hasChanged) {
          _successfulChecks++;
        }

        _adjustPollingInterval(hasChanged);

        if (hasChanged) {
          _onClipboardChanged?.call();
        }

        _scheduleNextPoll();
      } on Exception catch (e) {
        _failedChecks++;
        _onError?.call('轮询检查失败: $e');
        _scheduleNextPoll();
      }
    });
  }

  /// 获取智能调整后的间隔
  Duration _getSmartInterval() {
    final now = DateTime.now();

    // 检查是否应该进入空闲模式
    if (_consecutiveNoChangeCount > _idleThreshold) {
      _isIdleMode = true;
      return _idleInterval;
    }

    // 检查是否应该退出空闲模式
    if (_isIdleMode && _consecutiveNoChangeCount < _idleThreshold ~/ 2) {
      _isIdleMode = false;
    }

    // 根据时间模式调整（例如，工作时间 vs 非工作时间）
    final hour = now.hour;
    if (hour < 8 || hour > 22) {
      // 非工作时间，使用较长间隔
      return Duration(
        milliseconds: (_currentInterval.inMilliseconds * 1.5).round(),
      );
    }

    return _currentInterval;
  }

  /// 检查剪贴板是否发生变化
  Future<bool> _checkClipboardChange() async {
    try {
      final currentSequence = await _getClipboardSequence();

      if (currentSequence != _lastClipboardSequence) {
        _lastClipboardSequence = currentSequence;
        _recordChange();
        return true;
      }

      return false;
    } on Exception catch (_) {
      // 如果无法获取序列号，回退到内容比较
      return _fallbackContentCheck();
    }
  }

  /// 获取平台特定的剪贴板序列号
  Future<int> _getClipboardSequence() async {
    if (Platform.isMacOS) {
      try {
        final result = await _platformChannel.invokeMethod<int>(
          'getClipboardSequence',
        );
        return result ?? -1;
      } on Exception catch (e) {
        throw Exception('无法获取 macOS 剪贴板序列号: $e');
      }
    } else if (Platform.isWindows) {
      try {
        final result = await _platformChannel.invokeMethod<int>(
          'getClipboardSequence',
        );
        return result ?? -1;
      } on Exception catch (e) {
        throw Exception('无法获取 Windows 剪贴板序列号: $e');
      }
    } else if (Platform.isLinux) {
      try {
        final result = await _platformChannel.invokeMethod<int>(
          'getClipboardSequence',
        );
        return result ?? -1;
      } on Exception catch (e) {
        throw Exception('无法获取 Linux 剪贴板序列号: $e');
      }
    } else {
      throw Exception('不支持的平台');
    }
  }

  /// 回退到内容比较检查
  String? _lastClipboardContent;

  Future<bool> _fallbackContentCheck() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final currentContent = clipboardData?.text;

      if (currentContent != _lastClipboardContent) {
        _lastClipboardContent = currentContent;
        _recordChange();
        return true;
      }

      return false;
    } on Exception catch (e) {
      throw Exception('回退内容检查失败: $e');
    }
  }

  /// 记录剪贴板变化
  void _recordChange() {
    final now = DateTime.now();
    _recentChanges
      ..add(now)
      // 保持最近的变化记录在指定窗口内
      ..removeWhere(
        (change) => now.difference(change).inSeconds > _recentChangeWindow,
      );

    _consecutiveNoChangeCount = 0;
  }

  /// 调整轮询间隔（增强版本）
  void _adjustPollingInterval(bool hasChanged) {
    if (hasChanged) {
      // 检测到变化，加快轮询
      _currentInterval = Duration(
        milliseconds: (_currentInterval.inMilliseconds * _speedUpFactor)
            .round(),
      );
      _consecutiveNoChangeCount = 0;
      _lastChangeTime = DateTime.now();
      _isIdleMode = false; // 退出空闲模式
    } else {
      // 没有变化，增加计数
      _consecutiveNoChangeCount++;

      // 如果连续多次没有变化，减慢轮询
      if (_consecutiveNoChangeCount >= _consecutiveNoChangeThreshold) {
        _currentInterval = Duration(
          milliseconds: (_currentInterval.inMilliseconds * _slowDownFactor)
              .round(),
        );
      }
    }

    // 限制间隔范围
    if (_currentInterval < _minInterval) {
      _currentInterval = _minInterval;
    } else if (_currentInterval > _maxInterval) {
      _currentInterval = _maxInterval;
    }

    // 根据最近的活动频率进一步调整
    _adjustByRecentActivity();
  }

  /// 根据最近活动频率调整间隔（优化版本）
  void _adjustByRecentActivity() {
    final now = DateTime.now();

    // 清理过期的活动记录
    _recentChanges.removeWhere(
      (time) => now.difference(time).inMinutes > _recentChangeWindow,
    );

    if (_recentChanges.length >= 3) {
      // 最近活动频繁，使用较短间隔
      _currentInterval = Duration(
        milliseconds: (_currentInterval.inMilliseconds * 0.7).round(),
      );
    } else if (_recentChanges.isEmpty && _consecutiveNoChangeCount > 20) {
      // 长时间无活动，使用较长间隔
      _currentInterval = Duration(
        milliseconds: (_currentInterval.inMilliseconds * 1.5).round(),
      );
    }

    // 再次限制范围
    if (_currentInterval < _minInterval) {
      _currentInterval = _minInterval;
    } else if (_currentInterval > _maxInterval) {
      _currentInterval = _maxInterval;
    }
  }

  /// 获取轮询统计信息（增强版本）
  Map<String, dynamic> getPollingStats() {
    final now = DateTime.now();
    final currentSessionTime = _pollingStartTime != null
        ? now.difference(_pollingStartTime!)
        : Duration.zero;
    final totalTime = _totalPollingTime + currentSessionTime;

    final successRate = _totalChecks > 0
        ? _successfulChecks / _totalChecks
        : 0.0;

    final avgInterval = _totalChecks > 0 && totalTime.inMilliseconds > 0
        ? totalTime.inMilliseconds / _totalChecks
        : _currentInterval.inMilliseconds.toDouble();

    return {
      'isPolling': isPolling,
      'isPaused': _isPaused,
      'isIdleMode': _isIdleMode,
      'currentInterval': _currentInterval.inMilliseconds,
      'consecutiveNoChangeCount': _consecutiveNoChangeCount,
      'recentChangesCount': _recentChanges.length,
      'totalChecks': _totalChecks,
      'successfulChecks': _successfulChecks,
      'failedChecks': _failedChecks,
      'successRate': (successRate * 100).toStringAsFixed(1),
      'totalPollingTime': totalTime.inSeconds,
      'averageInterval': avgInterval.toStringAsFixed(1),
      'lastChangeTime': _lastChangeTime?.toIso8601String(),
      'performance': {
        'adaptiveScheduling': true,
        'idleModeEnabled': true,
        'smartIntervalAdjustment': true,
      },
    };
  }

  /// 获取性能指标
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'pollingEfficiency': getPollingStats(),
      'resourceOptimization': {
        'idleDetection': _isIdleMode,
        'adaptiveInterval': _currentInterval != _defaultInterval,
        'timeBasedAdjustment': true,
      },
    };
  }

  /// 重置统计信息
  void resetStats() {
    _totalChecks = 0;
    _successfulChecks = 0;
    _failedChecks = 0;
    _totalPollingTime = Duration.zero;
    _lastChangeTime = null;
  }
}
