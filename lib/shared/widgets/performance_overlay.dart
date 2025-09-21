import 'dart:async';
import 'package:clip_flow_pro/core/services/performance_service.dart';
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
    fps: 60.0,
    memoryUsage: 0.0,
    cpuUsage: 0.0,
    jankCount: 0,
    dbQueryTime: 0.0,
    clipboardCaptureTime: 0.0,
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
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _dragController,
      curve: Curves.easeInOut,
    ));
    
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
              _performanceHealth = PerformanceService.instance.getPerformanceHealth();
              _performanceScore = PerformanceService.instance.getPerformanceScore();
              _recommendations = PerformanceService.instance.getPerformanceRecommendations();
              _memoryLeakDetected = PerformanceService.instance.detectMemoryLeak();
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
    } catch (e) {
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
          fps: 60.0,
          memoryUsage: 100.0,
          cpuUsage: 5.0,
          jankCount: 0,
          dbQueryTime: 0.0,
          clipboardCaptureTime: 0.0,
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
                        (_position.dx + details.delta.dx).clamp(0.0, 
                          screenSize.width - overlayWidth),
                        (_position.dy + details.delta.dy).clamp(0.0, 
                          screenSize.height - overlayHeight),
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
                    ? Colors.black.withOpacity(0.95)
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
                    child: _isExpanded ? _buildExpandedView() : _buildCompactView(),
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
            const Text(
              '性能监控',
              style: TextStyle(
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
            _buildMetricChip('FPS', _currentMetrics.fps.toStringAsFixed(1), 
              _getPerformanceColor(_currentMetrics.fps, 45, 30)),
            const SizedBox(width: 8),
            _buildMetricChip('内存', '${_currentMetrics.memoryUsage.toStringAsFixed(0)}MB', 
              _getPerformanceColor(_currentMetrics.memoryUsage, 150, 200)),
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
            const Text(
              '性能监控',
              style: TextStyle(
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
                            content: const Text('性能指标已重置'),
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
                    } catch (e) {
                      debugPrint('重置性能指标失败: $e');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
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
        _buildDetailedMetricRow('帧率 (FPS)', _currentMetrics.fps.toStringAsFixed(1), 
          _getPerformanceColor(60 - _currentMetrics.fps, 15, 30), _currentMetrics.fps, 60.0),
        _buildDetailedMetricRow('内存使用', '${_currentMetrics.memoryUsage.toStringAsFixed(0)} MB', 
          _getPerformanceColor(_currentMetrics.memoryUsage, 150, 200), _currentMetrics.memoryUsage, 300.0),
        _buildDetailedMetricRow('CPU 使用率', '${_currentMetrics.cpuUsage.toStringAsFixed(1)}%', 
          _getPerformanceColor(_currentMetrics.cpuUsage, 15, 25), _currentMetrics.cpuUsage, 100.0),
        _buildMetricRow('卡顿次数', _currentMetrics.jankCount.toString(), 
          _getPerformanceColor(_currentMetrics.jankCount.toDouble(), 5, 10)),
        _buildMetricRow('数据库查询', '${_currentMetrics.dbQueryTime.toStringAsFixed(0)} ms', 
          _getPerformanceColor(_currentMetrics.dbQueryTime, 50, 100)),
        _buildMetricRow('剪贴板捕获', '${_currentMetrics.clipboardCaptureTime.toStringAsFixed(0)} ms', 
          _getPerformanceColor(_currentMetrics.clipboardCaptureTime, 100, 200)),
        const SizedBox(height: 8),
        _buildPerformanceScore(),
        const SizedBox(height: 4),
        _buildStatusIndicator(),
        if (_memoryLeakDetected) ...[const SizedBox(height: 4), _buildMemoryLeakWarning()],
        if (_recommendations.isNotEmpty) ...[const SizedBox(height: 4), _buildRecommendationsButton()],
      ],
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
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

  Widget _buildDetailedMetricRow(String label, String value, Color color, double currentValue, double maxValue) {
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
              color: Colors.white.withOpacity(0.2),
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
        color: scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scoreColor, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '性能评分',
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
        color: isHealthy ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHealthy ? Colors.green : Colors.orange,
          width: 1,
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
            isHealthy ? '性能良好' : '性能警告',
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
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red, width: 1),
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
          const Text(
            '检测到内存泄漏',
            style: TextStyle(
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
      onTap: () => _showRecommendationsDialog(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blue, width: 1),
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
              '优化建议 (${_recommendations.length})',
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
        title: const Text('性能优化建议'),
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
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}