// ignore_for_file: public_member_api_docs
import 'dart:async';
import 'package:clip_flow_pro/core/constants/i18n_fallbacks.dart';
import 'package:clip_flow_pro/core/services/performance_service.dart';
import 'package:clip_flow_pro/l10n/gen/s.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 性能监控覆盖层
/// 显示实时性能指标，包括FPS、内存使用、CPU使用率等
class PerformanceOverlay extends ConsumerStatefulWidget {
  const PerformanceOverlay({super.key});

  @override
  ConsumerState<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends ConsumerState<PerformanceOverlay>
    with TickerProviderStateMixin {
  StreamSubscription<PerformanceMetrics>? _metricsSubscription;
  bool _isExpanded = false;
  bool _isDragging = false;
  bool _isHovering = false;
  Offset _position = const Offset(20, 100);

  late AnimationController _expandController;
  late AnimationController _dragController;
  late Animation<double> _expandAnimation;
  late Animation<double> _scaleAnimation;

  // 性能指标
  PerformanceMetrics _currentMetrics = PerformanceMetrics(
    fps: 60,
    memoryUsage: 0,
    cpuUsage: 0,
    jankCount: 0,
    dbQueryTime: 0,
    clipboardCaptureTime: 0,
    timestamp: DateTime.now(),
  );

  // 增强监控数据
  Map<String, dynamic> _detailedStats = {};
  String _performanceHealth = 'warming_up';
  int _performanceScore = 100;
  List<String> _recommendations = [];
  bool _memoryLeakDetected = false;

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _dragController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // 初始化动画
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation =
        Tween<double>(
          begin: 1,
          end: 1.05,
        ).animate(
          CurvedAnimation(
            parent: _dragController,
            curve: Curves.easeInOut,
          ),
        );

    _startPerformanceMonitoring();
  }

  @override
  void dispose() {
    // 安全地释放资源
    _metricsSubscription?.cancel();
    _metricsSubscription = null;

    _expandController.dispose();
    _dragController.dispose();

    // 只有在没有其他监听器时才停止监控
    if (PerformanceService.instance.isMonitoring) {
      PerformanceService.instance.stopMonitoring();
    }

    super.dispose();
  }

  void _startPerformanceMonitoring() {
    try {
      PerformanceService.instance.startMonitoring();
      _metricsSubscription = PerformanceService.instance.metricsStream.listen(
        (metrics) {
          if (mounted) {
            setState(() {
              _currentMetrics = metrics;
              // 获取增强的监控数据
              _detailedStats = PerformanceService.instance.getDetailedStats();
              _performanceHealth = PerformanceService.instance
                  .getPerformanceHealth();
              _performanceScore = PerformanceService.instance
                  .getPerformanceScore();
              _recommendations = PerformanceService.instance
                  .getPerformanceRecommendations();
              _memoryLeakDetected = PerformanceService.instance
                  .detectMemoryLeak();
            });
          }
        },
        onError: (error) {
          if (mounted) {
            debugPrint('性能监控流错误: $error');
            // 降级到基础监控模式
            _fallbackToBasicMonitoring();
          }
        },
      );
    } on Exception catch (e) {
      debugPrint('启动性能监控失败: $e');
      _fallbackToBasicMonitoring();
    }
  }

  /// 降级到基础监控模式
  void _fallbackToBasicMonitoring() {
    // 使用定时器模拟基础性能数据
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentMetrics = PerformanceMetrics(
          fps: 60,
          memoryUsage: 100,
          cpuUsage: 5,
          jankCount: 0,
          dbQueryTime: 0,
          clipboardCaptureTime: 0,
          timestamp: DateTime.now(),
        );
        _detailedStats = {};
        _performanceHealth = 'unknown';
      });
    });
  }

  Color _getPerformanceColor(double value, double warning, double critical) {
    if (value >= critical) return Colors.red;
    if (value >= warning) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: AnimatedBuilder(
        animation: Listenable.merge([_expandAnimation, _scaleAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: MouseRegion(
              onEnter: (_) {
                setState(() {
                  _isHovering = true;
                });
              },
              onExit: (_) {
                setState(() {
                  _isHovering = false;
                });
              },
              child: GestureDetector(
                onPanStart: (details) {
                  _isDragging = true;
                  _dragController.forward();
                },
                onPanUpdate: (details) {
                  if (_isDragging) {
                    setState(() {
                      final screenSize = MediaQuery.of(context).size;
                      final overlayWidth = _isExpanded ? 280.0 : 180.0;
                      final overlayHeight = _isExpanded ? 200.0 : 60.0;

                      _position = Offset(
                        (_position.dx + details.delta.dx).clamp(
                          0.0,
                          screenSize.width - overlayWidth,
                        ),
                        (_position.dy + details.delta.dy).clamp(
                          0.0,
                          screenSize.height - overlayHeight,
                        ),
                      );
                    });
                  }
                },
                onPanEnd: (details) {
                  _isDragging = false;
                  _dragController.reverse();
                },
                onTap: () {
                  // 防抖处理，避免快速点击
                  if (_expandController.isAnimating) return;

                  setState(() {
                    _isExpanded = !_isExpanded;
                  });

                  if (_isExpanded) {
                    _expandController.forward();
                  } else {
                    _expandController.reverse();
                  }

                  // 提供触觉反馈
                  HapticFeedback.lightImpact();
                },
                child: Material(
                  elevation: _isDragging ? 12 : (_isHovering ? 10 : 8),
                  borderRadius: BorderRadius.circular(12),
                  color: _isDragging
                      ? Colors.black.withValues(alpha: 0.95)
                      : Colors.black87,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      minWidth: 180,
                      maxWidth: _isExpanded ? 280 : 180,
                      minHeight: _isExpanded ? 200 : 60,
                    ),
                    child: _isExpanded
                        ? _buildExpandedView()
                        : _buildCompactView(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              S.of(context)?.performanceMonitor ??
                  I18nFallbacks.performance.monitor,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Flexible(
              child: _buildMetricChip(
                'FPS',
                _currentMetrics.fps.toStringAsFixed(1),
                _getPerformanceColor(_currentMetrics.fps, 45, 30),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: _buildMetricChip(
                S.of(context)?.performanceMemory ??
                    I18nFallbacks.performance.memory,
                '${_currentMetrics.memoryUsage.toStringAsFixed(0)}MB',
                _getPerformanceColor(_currentMetrics.memoryUsage, 150, 200),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              S.of(context)?.performanceMonitor ??
                  I18nFallbacks.performance.monitor,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    try {
                      PerformanceService.instance.resetJankCount();

                      // 提供触觉反馈
                      HapticFeedback.lightImpact();

                      // 显示重置反馈
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              S
                                      .of(
                                        context,
                                      )
                                      ?.performanceMetricsReset ??
                                  I18nFallbacks.performance.metricsReset,
                            ),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.only(
                              bottom: MediaQuery.of(context).size.height - 100,
                              left: 20,
                              right: 20,
                            ),
                          ),
                        );
                      }
                    } on Exception catch (e) {
                      debugPrint('重置性能指标失败: $e');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDetailedMetricRow(
          S.of(context)?.performanceFps ?? I18nFallbacks.performance.fps,
          _currentMetrics.fps.toStringAsFixed(1),
          _getPerformanceColor(60 - _currentMetrics.fps, 15, 30),
          _currentMetrics.fps,
          60,
        ),
        _buildDetailedMetricRow(
          S.of(context)?.performanceMemory ?? I18nFallbacks.performance.memory,
          '${_currentMetrics.memoryUsage.toStringAsFixed(0)} MB',
          _getPerformanceColor(_currentMetrics.memoryUsage, 150, 200),
          _currentMetrics.memoryUsage,
          300,
        ),
        _buildDetailedMetricRow(
          S.of(context)?.performanceCpu ?? I18nFallbacks.performance.cpu,
          '${_currentMetrics.cpuUsage.toStringAsFixed(1)}%',
          _getPerformanceColor(_currentMetrics.cpuUsage, 15, 25),
          _currentMetrics.cpuUsage,
          100,
        ),
        _buildMetricRow(
          S.of(context)?.performanceJank ?? I18nFallbacks.performance.jank,
          _currentMetrics.jankCount.toString(),
          _getPerformanceColor(_currentMetrics.jankCount.toDouble(), 5, 10),
        ),
        _buildMetricRow(
          S.of(context)?.performanceDbQuery ??
              I18nFallbacks.performance.dbQuery,
          '${_currentMetrics.dbQueryTime.toStringAsFixed(0)} ms',
          _getPerformanceColor(_currentMetrics.dbQueryTime, 50, 100),
        ),
        _buildMetricRow(
          S.of(context)?.performanceClipboard ??
              I18nFallbacks.performance.clipboard,
          '${_currentMetrics.clipboardCaptureTime.toStringAsFixed(0)} ms',
          _getPerformanceColor(_currentMetrics.clipboardCaptureTime, 20, 50),
        ),
        // 添加详细统计信息
        if (_detailedStats.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 8),
          _buildMetricRow(
            '平均帧时间',
            '${((_detailedStats['avgFrameTime'] as double?) ?? 0.0).toStringAsFixed(2)} ms',
            _getPerformanceColor(
              ((_detailedStats['avgFrameTime'] as double?) ?? 0.0) - 16.67,
              5,
              10,
            ),
          ),
          _buildMetricRow(
            '卡顿百分比',
            '${((_detailedStats['jankPercentage'] as double?) ?? 0.0).toStringAsFixed(1)}%',
            _getPerformanceColor(
              (_detailedStats['jankPercentage'] as double?) ?? 0.0,
              5,
              15,
            ),
          ),
          _buildMetricRow(
            '帧时间方差',
            '${((_detailedStats['frameTimeVariance'] as double?) ?? 0.0).toStringAsFixed(2)} ms²',
            _getPerformanceColor(
              (_detailedStats['frameTimeVariance'] as double?) ?? 0.0,
              10,
              25,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildPerformanceScore()),
            const SizedBox(width: 8),
            _buildHealthIndicator(),
          ],
        ),
        const SizedBox(height: 4),
        _buildStatusIndicator(),
        if (_memoryLeakDetected) ...[
          const SizedBox(height: 4),
          _buildMemoryLeakWarning(),
        ],
        if (_recommendations.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildRecommendationsButton(),
        ],
      ],
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedMetricRow(
    String label,
    String value,
    Color color,
    double currentValue,
    double maxValue,
  ) {
    final percentage = (currentValue / maxValue).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(1.5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceScore() {
    final scoreColor = _getScoreColor(_performanceScore);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scoreColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            S.of(context)?.performanceScore ?? I18nFallbacks.performance.score,
            style: TextStyle(
              color: scoreColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$_performanceScore/100',
            style: TextStyle(
              color: scoreColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStatusIndicator() {
    final isHealthy = _performanceScore >= 70;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHealthy
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHealthy ? Colors.green : Colors.orange,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHealthy ? Icons.check_circle : Icons.warning,
            color: isHealthy ? Colors.green : Colors.orange,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            isHealthy
                ? (S.of(context)?.performanceGood ??
                      I18nFallbacks.performance.good)
                : (S.of(context)?.performanceWarning ??
                      I18nFallbacks.performance.warning),
            style: TextStyle(
              color: isHealthy ? Colors.green : Colors.orange,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryLeakWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.memory,
            color: Colors.red,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            S.of(context)?.performanceMemoryLeak ??
                I18nFallbacks.performance.memoryLeak,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsButton() {
    return GestureDetector(
      onTap: _showRecommendationsDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blue),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lightbulb_outline,
              color: Colors.blue,
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              S
                      .of(
                        context,
                      )
                      ?.performanceOptimizationCount(_recommendations.length) ??
                  I18nFallbacks.performance.optimizationCount(
                    _recommendations.length,
                  ),
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecommendationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          S.of(context)?.performanceOptimizationTitle ??
              I18nFallbacks.performance.optimizationTitle,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _recommendations.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.arrow_right,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _recommendations[index],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              S.of(context)?.performanceOptimizationClose ??
                  I18nFallbacks.performance.close,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator() {
    final healthColor = _getHealthColor(_performanceHealth);
    final healthIcon = _getHealthIcon(_performanceHealth);
    final healthText = _getHealthText(_performanceHealth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: healthColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: healthColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            healthIcon,
            size: 12,
            color: healthColor,
          ),
          const SizedBox(width: 4),
          Text(
            healthText,
            style: TextStyle(
              color: healthColor,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(String health) {
    switch (health) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      case 'warming_up':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getHealthIcon(String health) {
    switch (health) {
      case 'excellent':
        return Icons.sentiment_very_satisfied;
      case 'good':
        return Icons.sentiment_satisfied;
      case 'fair':
        return Icons.sentiment_neutral;
      case 'poor':
        return Icons.sentiment_dissatisfied;
      case 'warming_up':
        return Icons.hourglass_empty;
      default:
        return Icons.help_outline;
    }
  }

  String _getHealthText(String health) {
    switch (health) {
      case 'excellent':
        return '优秀';
      case 'good':
        return '良好';
      case 'fair':
        return '一般';
      case 'poor':
        return '较差';
      case 'warming_up':
        return '预热';
      default:
        return '未知';
    }
  }
}
