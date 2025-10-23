import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 性能监控工具 - 用于检测和解决性能问题
class PerformanceMonitor {
  /// 单例实例
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();

  /// 获取单例实例
  factory PerformanceMonitor() => _instance;

  /// 私有构造函数
  PerformanceMonitor._internal();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<Duration>> _durations = {};
  final Map<String, int> _counters = {};
  Timer? _reportingTimer;
  bool _isMonitoring = false;

  /// 开始监控
  void startMonitoring() {
    if (_isMonitoring || !kDebugMode) return;

    _isMonitoring = true;
    _reportingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _reportMetrics();
    });

    // 监控帧渲染性能
    WidgetsBinding.instance.addTimingsCallback(_onFrameTimings);
  }

  /// 停止监控
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _reportingTimer?.cancel();
    _reportingTimer = null;
    _clearMetrics();
  }

  /// 开始计时
  void startTimer(String operation) {
    if (!_isMonitoring) return;
    _startTimes[operation] = DateTime.now();
  }

  /// 结束计时
  void endTimer(String operation) {
    if (!_isMonitoring) return;

    final startTime = _startTimes[operation];
    if (startTime == null) return;

    final duration = DateTime.now().difference(startTime);
    _durations[operation] ??= [];
    _durations[operation]!.add(duration);

    // 只保留最近100次记录
    if (_durations[operation]!.length > 100) {
      _durations[operation]!.removeAt(0);
    }

    _startTimes.remove(operation);

    // 如果操作耗时超过阈值，记录警告
    if (duration.inMilliseconds > 100) {
      developer.log(
        'Performance Warning: $operation took ${duration.inMilliseconds}ms',
        name: 'PerformanceMonitor',
      );
    }
  }

  /// 计数器增加
  void incrementCounter(String counter) {
    if (!_isMonitoring) return;
    _counters[counter] = (_counters[counter] ?? 0) + 1;
  }

  /// 监控内存使用
  void reportMemoryUsage() {
    if (!_isMonitoring) return;

    if (!kDebugMode) return; // 只在调试模式下报告

    // 模拟内存使用情况
    final memoryInfo = {
      'timestamp': DateTime.now().toIso8601String(),
      'heap_used': 'N/A', // Flutter没有直接的API
      'counters': _counters,
      'operations': _durations.keys.toList(),
    };

    developer.log(
      'Memory Usage: $memoryInfo',
      name: 'PerformanceMonitor',
    );
  }

  void _onFrameTimings(List<ui.FrameTiming> timings) {
    if (!_isMonitoring) return;

    for (final timing in timings) {
      final totalDuration = timing.totalSpan.inMicroseconds;
      final buildDuration = timing.buildSpan.inMicroseconds;
      final rasterDuration = timing.rasterSpan.inMicroseconds;

      // 如果帧时间超过16ms（60fps），记录警告
      if (totalDuration > 16000) {
        developer.log(
          'Frame Performance Warning: ${totalDuration / 1000}ms '
          '(Build: ${buildDuration / 1000}ms, '
          'Raster: ${rasterDuration / 1000}ms)',
          name: 'PerformanceMonitor',
        );
      }
    }
  }

  void _reportMetrics() {
    if (!_isMonitoring) return;

    for (final entry in _durations.entries) {
      final operation = entry.key;
      final durations = entry.value;

      if (durations.isEmpty) continue;

      final avgDuration =
          durations.fold<int>(
            0,
            (sum, duration) => sum + duration.inMilliseconds,
          ) /
          durations.length;

      final maxDuration = durations.fold<int>(
        0,
        (max, duration) =>
            duration.inMilliseconds > max ? duration.inMilliseconds : max,
      );

      developer.log(
        'Performance Report - $operation: '
        'Avg: ${avgDuration.toStringAsFixed(1)}ms, '
        'Max: ${maxDuration}ms, '
        'Count: ${durations.length}',
        name: 'PerformanceMonitor',
      );
    }

    for (final entry in _counters.entries) {
      developer.log(
        'Counter Report - ${entry.key}: ${entry.value}',
        name: 'PerformanceMonitor',
      );
    }

    reportMemoryUsage();
  }

  void _clearMetrics() {
    _startTimes.clear();
    _durations.clear();
    _counters.clear();
  }

  /// 清除所有性能指标数据
  void clearMetrics() {
    _clearMetrics();
  }
}

/// 内存优化工具
class MemoryOptimizer {
  static final MemoryOptimizer _instance = MemoryOptimizer._internal();
  factory MemoryOptimizer() => _instance;
  MemoryOptimizer._internal();

  final List<VoidCallback> _cleanupCallbacks = [];
  Timer? _cleanupTimer;

  /// 注册清理回调
  void registerCleanupCallback(VoidCallback callback) {
    _cleanupCallbacks.add(callback);
  }

  /// 开始定期清理
  void startPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      performCleanup();
    });
  }

  /// 停止定期清理
  void stopPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  /// 执行清理
  void performCleanup() {
    try {
      // 调用所有注册的清理回调
      for (final callback in _cleanupCallbacks) {
        try {
          callback();
        } catch (e) {
          developer.log(
            'Error in cleanup callback: $e',
            name: 'MemoryOptimizer',
            level: 1000, // ERROR level
          );
        }
      }

      // 强制垃圾回收（仅调试模式）
      if (kDebugMode) {
        SystemChannels.platform.invokeMethod('System.gc');
      }

      developer.log(
        'Memory cleanup completed',
        name: 'MemoryOptimizer',
      );
    } catch (e) {
      developer.log(
        'Error during memory cleanup: $e',
        name: 'MemoryOptimizer',
        level: 1000, // ERROR level
      );
    }
  }
}

/// 性能优化的列表视图
class PerformanceOptimizedListView<T> extends StatefulWidget {
  const PerformanceOptimizedListView({
    required this.items,
    required this.itemBuilder,
    required this.itemCount,
    this.controller,
    this.padding,
    this.physics,
    this.cacheExtent = 250.0,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    super.key,
  });

  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final int itemCount;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final double cacheExtent;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;

  @override
  State<PerformanceOptimizedListView<T>> createState() =>
      _PerformanceOptimizedListViewState<T>();
}

class _PerformanceOptimizedListViewState<T>
    extends State<PerformanceOptimizedListView<T>> {
  final PerformanceMonitor _monitor = PerformanceMonitor();

  @override
  Widget build(BuildContext context) {
    _monitor.startTimer('list_view_build');

    final listView = ListView.builder(
      controller: widget.controller,
      padding: widget.padding,
      physics: widget.physics,
      cacheExtent: widget.cacheExtent,
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      addRepaintBoundaries: widget.addRepaintBoundaries,
      addSemanticIndexes: widget.addSemanticIndexes,
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        if (index >= widget.items.length) {
          return const SizedBox.shrink();
        }

        _monitor.startTimer('item_build_$index');
        final item = widget.itemBuilder(context, widget.items[index], index);
        _monitor.endTimer('item_build_$index');

        return item;
      },
    );

    _monitor.endTimer('list_view_build');
    return listView;
  }
}

/// 性能优化的网格视图
class PerformanceOptimizedGridView<T> extends StatefulWidget {
  const PerformanceOptimizedGridView({
    required this.items,
    required this.itemBuilder,
    required this.gridDelegate,
    this.controller,
    this.padding,
    this.physics,
    this.cacheExtent = 250.0,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    super.key,
  });

  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final SliverGridDelegateWithFixedCrossAxisCount gridDelegate;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final double cacheExtent;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;

  @override
  State<PerformanceOptimizedGridView<T>> createState() =>
      _PerformanceOptimizedGridViewState<T>();
}

class _PerformanceOptimizedGridViewState<T>
    extends State<PerformanceOptimizedGridView<T>> {
  final PerformanceMonitor _monitor = PerformanceMonitor();

  @override
  Widget build(BuildContext context) {
    _monitor.startTimer('grid_view_build');

    final gridView = GridView.builder(
      controller: widget.controller,
      padding: widget.padding,
      physics: widget.physics,
      cacheExtent: widget.cacheExtent,
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      addRepaintBoundaries: widget.addRepaintBoundaries,
      addSemanticIndexes: widget.addSemanticIndexes,
      gridDelegate: widget.gridDelegate,
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        if (index >= widget.items.length) {
          return const SizedBox.shrink();
        }

        _monitor.startTimer('grid_item_build_$index');
        final item = widget.itemBuilder(context, widget.items[index], index);
        _monitor.endTimer('grid_item_build_$index');

        return item;
      },
    );

    _monitor.endTimer('grid_view_build');
    return gridView;
  }
}

/// 图片内存管理工具
class ImageMemoryManager {
  static final ImageMemoryManager _instance = ImageMemoryManager._internal();
  factory ImageMemoryManager() => _instance;
  ImageMemoryManager._internal();

  final Map<String, ui.Image> _imageCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const int _maxCacheSize = 50;
  static const Duration _maxCacheAge = Duration(minutes: 10);

  /// 缓存图片
  Future<void> cacheImage(String key, ui.Image image) async {
    // 如果缓存已满，清理最旧的图片
    if (_imageCache.length >= _maxCacheSize) {
      _cleanupOldCache();
    }

    _imageCache[key] = image;
    _cacheTimestamps[key] = DateTime.now();

    // 监听图片释放
    image.addListener(() {
      _imageCache.remove(key);
      _cacheTimestamps.remove(key);
    });
  }

  /// 获取缓存的图片
  ui.Image? getCachedImage(String key) {
    // 检查缓存是否存在且未过期
    if (_imageCache.containsKey(key)) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _maxCacheAge) {
        return _imageCache[key];
      } else {
        // 缓存已过期，移除
        _removeFromCache(key);
      }
    }
    return null;
  }

  void _removeFromCache(String key) {
    final image = _imageCache[key];
    if (image != null) {
      image.dispose();
    }
    _imageCache.remove(key);
    _cacheTimestamps.remove(key);
  }

  void _cleanupOldCache() {
    if (_imageCache.isEmpty) return;

    // 找到最旧的缓存项
    var oldestKey = _cacheTimestamps.keys.first;
    var oldestTime = _cacheTimestamps[oldestKey]!;

    for (final entry in _cacheTimestamps.entries) {
      if (entry.value!.isBefore(oldestTime)) {
        oldestKey = entry.key;
        oldestTime = entry.value!;
      }
    }

    _removeFromCache(oldestKey);
  }

  /// 清理所有缓存
  void clearCache() {
    for (final image in _imageCache.values) {
      image.dispose();
    }
    _imageCache.clear();
    _cacheTimestamps.clear();
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _imageCache.length,
      'maxCacheSize': _maxCacheSize,
      'cacheKeys': _imageCache.keys.toList(),
    };
  }
}

/// 滚动性能监控器
class ScrollPerformanceMonitor extends StatefulWidget {
  const ScrollPerformanceMonitor({
    required this.child,
    this.onScrollEnd,
    this.onPerformanceIssue,
    super.key,
  });

  final Widget child;
  final VoidCallback? onScrollEnd;
  final VoidCallback? onPerformanceIssue;

  @override
  State<ScrollPerformanceMonitor> createState() =>
      _ScrollPerformanceMonitorState();
}

class _ScrollPerformanceMonitorState extends State<ScrollPerformanceMonitor> {
  final PerformanceMonitor _monitor = PerformanceMonitor();
  DateTime? _scrollStartTime;
  Timer? _scrollEndTimer;
  bool _isScrolling = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _handleScrollNotification(notification);
        return false;
      },
      child: widget.child,
    );
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _onScrollStart();
    } else if (notification is ScrollUpdateNotification) {
      _onScrollUpdate();
    } else if (notification is ScrollEndNotification) {
      _onScrollEnd();
    }
  }

  void _onScrollStart() {
    if (_isScrolling) return;

    _isScrolling = true;
    _scrollStartTime = DateTime.now();
    _monitor.startTimer('scroll_session');
    _scrollEndTimer?.cancel();
  }

  void _onScrollUpdate() {
    // 可以在这里添加滚动过程中的性能监控
  }

  void _onScrollEnd() {
    if (!_isScrolling) return;

    _isScrolling = false;
    _monitor.endTimer('scroll_session');

    if (_scrollStartTime != null) {
      final scrollDuration = DateTime.now().difference(_scrollStartTime!);

      // 如果滚动时间过长，可能存在性能问题
      if (scrollDuration.inMilliseconds > 5000) {
        widget.onPerformanceIssue?.call();
        developer.log(
          'Long scroll detected: ${scrollDuration.inMilliseconds}ms',
          name: 'ScrollPerformanceMonitor',
        );
      }
    }

    // 延迟调用滚动结束回调
    _scrollEndTimer = Timer(const Duration(milliseconds: 100), () {
      widget.onScrollEnd?.call();
    });

    _scrollStartTime = null;
  }
}
