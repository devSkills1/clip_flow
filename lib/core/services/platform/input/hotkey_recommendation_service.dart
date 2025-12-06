import 'dart:async';
import 'dart:math';

import 'package:clip_flow/core/models/hotkey_config.dart';
import 'package:clip_flow/core/services/observability/index.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

/// Marks a future as intentionally not awaited.
///
/// This helper function is used for fire-and-forget operations where
/// we don't want to wait for the completion and don't care about the result.
void unawaited(Future<void> future) {
  // Intentionally unawaited
}

/// 快捷键使用统计
@immutable
class HotkeyUsageStats {
  /// 构造函数
  const HotkeyUsageStats({
    required this.action,
    required this.count,
    required this.lastUsed,
    required this.averageInterval,
  });

  /// 从JSON创建
  factory HotkeyUsageStats.fromJson(Map<String, dynamic> json) {
    return HotkeyUsageStats(
      action: HotkeyAction.values.firstWhere(
        (a) => a.name == json['action'],
      ),
      count: json['count'] as int,
      lastUsed: DateTime.fromMillisecondsSinceEpoch(json['lastUsed'] as int),
      averageInterval: (json['averageInterval'] as num).toDouble(),
    );
  }

  /// 动作
  final HotkeyAction action;

  /// 使用次数
  final int count;

  /// 最后使用时间
  final DateTime lastUsed;

  /// 平均使用间隔（分钟）
  final double averageInterval;

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'action': action.name,
      'count': count,
      'lastUsed': lastUsed.millisecondsSinceEpoch,
      'averageInterval': averageInterval,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HotkeyUsageStats &&
        other.action == action &&
        other.count == count &&
        other.lastUsed == lastUsed &&
        other.averageInterval == averageInterval;
  }

  @override
  int get hashCode {
    return Object.hash(action, count, lastUsed, averageInterval);
  }
}

/// 快捷键推荐
@immutable
class HotkeyRecommendation {
  /// 构造函数
  const HotkeyRecommendation({
    required this.action,
    required this.recommendedKeys,
    required this.conflictProbability,
    required this.usageFrequency,
    required this.reason,
  });

  /// 计算推荐优先级
  double get priority {
    return (usageFrequency * 0.6) + ((1.0 - conflictProbability) * 0.4);
  }

  /// 动作
  final HotkeyAction action;

  /// 推荐的快捷键列表
  final List<HotkeyConfig> recommendedKeys;

  /// 冲突概率 (0.0 - 1.0)
  final double conflictProbability;

  /// 使用频率评分 (0.0 - 1.0)
  final double usageFrequency;

  /// 推荐原因
  final String reason;
}

/// 智能快捷键推荐服务
class HotkeyRecommendationService {
  /// 构造函数
  HotkeyRecommendationService(this._channel);
  static const String _tag = 'HotkeyRecommendationService';

  /// 平台通道
  final MethodChannel _channel;

  /// 使用统计缓存
  final Map<HotkeyAction, HotkeyUsageStats> _usageStats = {};

  /// 快捷键冲突数据库
  final Set<String> _knownConflicts = {};

  /// 应用特定快捷键偏好
  final Map<String, Map<HotkeyAction, String>> _appSpecificPreferences = {};

  /// 是否已初始化
  bool _isInitialized = false;

  /// 初始化推荐服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Log.i('初始化快捷键推荐服务', tag: _tag);

      // 加载使用统计
      await _loadUsageStats();

      // 加载冲突数据库
      await _loadConflictDatabase();

      // 加载应用特定偏好
      await _loadAppSpecificPreferences();

      _isInitialized = true;
      await Log.i('快捷键推荐服务初始化完成', tag: _tag);
    } on Exception catch (e) {
      unawaited(Future(() => Log.e('快捷键推荐服务初始化失败', tag: _tag, error: e)));
      rethrow;
    }
  }

  /// 记录快捷键使用
  Future<void> recordUsage(HotkeyAction action) async {
    if (!_isInitialized) await initialize();

    try {
      final now = DateTime.now();
      final existing = _usageStats[action];

      if (existing == null) {
        _usageStats[action] = HotkeyUsageStats(
          action: action,
          count: 1,
          lastUsed: now,
          averageInterval: 0,
        );
      } else {
        final interval = now.difference(existing.lastUsed).inMinutes;
        final newAverageInterval = existing.count == 1
            ? interval.toDouble()
            : (existing.averageInterval * (existing.count - 1) + interval) /
                  existing.count;

        _usageStats[action] = HotkeyUsageStats(
          action: action,
          count: existing.count + 1,
          lastUsed: now,
          averageInterval: newAverageInterval,
        );
      }

      await _saveUsageStats();
      await Log.d('记录快捷键使用: ${action.name}', tag: _tag);
    } on Exception catch (e) {
      unawaited(Future(() => Log.e('记录快捷键使用失败', tag: _tag, error: e)));
    }
  }

  /// 获取推荐快捷键
  Future<List<HotkeyRecommendation>> getRecommendations({
    String? currentApp,
    bool developerMode = false,
    Set<HotkeyAction>? excludeActions,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final recommendations = <HotkeyRecommendation>[];
      final exclude = excludeActions ?? <HotkeyAction>{};

      for (final action in HotkeyAction.values) {
        if (exclude.contains(action)) continue;

        final usage = _usageStats[action];
        final usageFrequency = _calculateUsageFrequency(usage);

        // 为高频使用的动作生成推荐
        if (usageFrequency > 0.1) {
          final recommendedKeys = await _generateRecommendedKeys(
            action,
            currentApp: currentApp,
            developerMode: developerMode,
          );

          if (recommendedKeys.isNotEmpty) {
            final conflictProbability = await _calculateConflictProbability(
              recommendedKeys,
              currentApp: currentApp,
            );

            recommendations.add(
              HotkeyRecommendation(
                action: action,
                recommendedKeys: recommendedKeys,
                conflictProbability: conflictProbability,
                usageFrequency: usageFrequency,
                reason: _generateRecommendationReason(
                  action,
                  usage,
                  conflictProbability,
                ),
              ),
            );
          }
        }
      }

      // 按优先级排序
      recommendations.sort((a, b) => b.priority.compareTo(a.priority));
      return recommendations;
    } on Exception catch (e) {
      await Log.e('获取推荐快捷键失败', tag: _tag, error: e);
      return [];
    }
  }

  /// 获取个性化快捷键配置
  Future<HotkeyConfig?> getPersonalizedConfig(
    HotkeyAction action, {
    String? currentApp,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      // 检查应用特定偏好
      if (currentApp != null &&
          _appSpecificPreferences.containsKey(currentApp)) {
        final appPrefs = _appSpecificPreferences[currentApp]!;
        if (appPrefs.containsKey(action)) {
          final keyString = appPrefs[action]!;
          return _parseHotkeyString(keyString, action);
        }
      }

      // 根据使用频率推荐配置
      final usage = _usageStats[action];
      if (usage != null && usage.count > 10) {
        // 为高频使用动作推荐更容易触发的快捷键
        return _recommendEasierKeyForAction(action, currentApp);
      }

      return null;
    } on Exception catch (e) {
      await Log.e('获取个性化配置失败', tag: _tag, error: e);
      return null;
    }
  }

  /// 分析当前快捷键配置
  Future<Map<String, dynamic>> analyzeConfiguration(
    Map<HotkeyAction, HotkeyConfig> currentConfig,
  ) async {
    if (!_isInitialized) await initialize();

    try {
      final analysis = <String, dynamic>{
        'totalActions': currentConfig.length,
        'highConflicts': <String>[],
        'unusedActions': <HotkeyAction>[],
        'optimizationSuggestions': <String>[],
        'efficiencyScore': 0.0,
      };

      var conflictCount = 0;
      var efficientActions = 0;

      for (final entry in currentConfig.entries) {
        final action = entry.key;
        final config = entry.value;

        // 检查冲突
        final conflictLevel = await _checkConflictLevel(config);
        if (conflictLevel > 0.7) {
          (analysis['highConflicts'] as List<Map<String, dynamic>>).add({
            'action': action.name,
            'key': config.displayString,
            'conflictLevel': conflictLevel,
          });
          conflictCount++;
        }

        // 检查使用情况
        final usage = _usageStats[action];
        if (usage == null || usage.count < 5) {
          (analysis['unusedActions'] as List<HotkeyAction>).add(action);
        } else if (conflictLevel < 0.3) {
          efficientActions++;
        }
      }

      // 计算效率评分
      analysis['efficiencyScore'] = currentConfig.isEmpty
          ? 0.0
          : (efficientActions / currentConfig.length);

      // 生成优化建议
      analysis['optimizationSuggestions'] = _generateOptimizationSuggestions(
        currentConfig,
        conflictCount,
        analysis['unusedActions'] as List<HotkeyAction>,
      );

      return analysis;
    } on Exception catch (e) {
      await Log.e('分析快捷键配置失败', tag: _tag, error: e);
      return {};
    }
  }

  /// 学习用户偏好
  Future<void> learnUserPreference(
    HotkeyAction action,
    HotkeyConfig config,
    String? currentApp,
  ) async {
    if (!_isInitialized) await initialize();

    try {
      // 记录应用特定偏好
      if (currentApp != null) {
        _appSpecificPreferences.putIfAbsent(currentApp, () => {});
        _appSpecificPreferences[currentApp]![action] = config.systemKeyString;
        await _saveAppSpecificPreferences();
      }

      await Log.d(
        '学习用户偏好: ${action.name} -> ${config.displayString}',
        tag: _tag,
      );
    } on Exception catch (e) {
      await Log.e('学习用户偏好失败', tag: _tag, error: e);
    }
  }

  /// 重置学习数据
  Future<void> resetLearningData() async {
    try {
      _usageStats.clear();
      _appSpecificPreferences.clear();

      await _saveUsageStats();
      await _saveAppSpecificPreferences();

      await Log.i('重置学习数据完成', tag: _tag);
    } on Exception catch (e) {
      await Log.e('重置学习数据失败', tag: _tag, error: e);
    }
  }

  // 私有方法

  /// 计算使用频率评分
  double _calculateUsageFrequency(HotkeyUsageStats? usage) {
    if (usage == null) return 0;

    final now = DateTime.now();
    final daysSinceLastUsed = now.difference(usage.lastUsed).inDays;
    final recencyFactor = max(0, 1.0 - (daysSinceLastUsed / 30.0)); // 30天衰减

    final frequencyFactor = min(1, usage.count / 50.0); // 50次使用为满分
    final intervalFactor = min(
      1,
      60.0 / max(1.0, usage.averageInterval),
    ); // 1小时间隔为满分

    return (frequencyFactor * 0.4) +
        (recencyFactor * 0.3) +
        (intervalFactor * 0.3);
  }

  /// 生成推荐快捷键
  Future<List<HotkeyConfig>> _generateRecommendedKeys(
    HotkeyAction action, {
    String? currentApp,
    bool developerMode = false,
  }) async {
    final candidates = <HotkeyConfig>[];

    // 基于动作类型生成候选快捷键
    switch (action) {
      case HotkeyAction.toggleWindow:
        candidates.addAll([
          const HotkeyConfig(
            action: HotkeyAction.toggleWindow,
            key: '`',
            modifiers: {HotkeyModifier.command, HotkeyModifier.alt},
            description: '显示/隐藏剪贴板窗口',
          ),
          const HotkeyConfig(
            action: HotkeyAction.toggleWindow,
            key: 'space',
            modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
            description: '显示/隐藏剪贴板窗口',
          ),
        ]);
      case HotkeyAction.quickPaste:
        candidates.addAll([
          const HotkeyConfig(
            action: HotkeyAction.quickPaste,
            key: 'v',
            modifiers: {HotkeyModifier.command, HotkeyModifier.control},
            description: '快速粘贴最近一项',
          ),
          const HotkeyConfig(
            action: HotkeyAction.quickPaste,
            key: 'return',
            modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
            description: '快速粘贴最近一项',
          ),
        ]);
      case HotkeyAction.showHistory:
        candidates.addAll([
          const HotkeyConfig(
            action: HotkeyAction.showHistory,
            key: 'h',
            modifiers: {HotkeyModifier.command, HotkeyModifier.alt},
            description: '显示剪贴板历史',
          ),
          const HotkeyConfig(
            action: HotkeyAction.showHistory,
            key: 'f9',
            modifiers: {HotkeyModifier.command},
            description: '显示剪贴板历史',
          ),
        ]);
      case HotkeyAction.search:
        candidates.addAll([
          const HotkeyConfig(
            action: HotkeyAction.search,
            key: 'f',
            modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
            description: '搜索剪贴板内容',
          ),
          const HotkeyConfig(
            action: HotkeyAction.search,
            key: 'space',
            modifiers: {HotkeyModifier.command, HotkeyModifier.alt},
            description: '搜索剪贴板内容',
          ),
        ]);
      case HotkeyAction.performOCR:
        candidates.addAll([
          const HotkeyConfig(
            action: HotkeyAction.performOCR,
            key: 'f8',
            modifiers: {HotkeyModifier.command},
            description: 'OCR文字识别',
          ),
          const HotkeyConfig(
            action: HotkeyAction.performOCR,
            key: 'o',
            modifiers: {HotkeyModifier.command, HotkeyModifier.alt},
            description: 'OCR文字识别',
          ),
        ]);
      case HotkeyAction.clearHistory:
        candidates.addAll([
          const HotkeyConfig(
            action: HotkeyAction.clearHistory,
            key: 'delete',
            modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
            description: '清空剪贴板历史',
          ),
          const HotkeyConfig(
            action: HotkeyAction.clearHistory,
            key: 'backspace',
            modifiers: {HotkeyModifier.command, HotkeyModifier.alt},
            description: '清空剪贴板历史',
          ),
        ]);
      case HotkeyAction.toggleMonitoring:
        candidates.addAll([
          const HotkeyConfig(
            action: HotkeyAction.toggleMonitoring,
            key: 'p',
            modifiers: {HotkeyModifier.command, HotkeyModifier.alt},
            description: '暂停/恢复剪贴板监听',
          ),
          const HotkeyConfig(
            action: HotkeyAction.toggleMonitoring,
            key: 'pause',
            modifiers: {HotkeyModifier.command},
            description: '暂停/恢复剪贴板监听',
          ),
        ]);
    }

    // 过滤掉已知冲突的快捷键
    final filtered = candidates.where((config) {
      return !_knownConflicts.contains(config.systemKeyString);
    }).toList();

    return filtered;
  }

  /// 计算冲突概率
  Future<double> _calculateConflictProbability(
    List<HotkeyConfig> configs, {
    String? currentApp,
  }) async {
    if (configs.isEmpty) return 0.0;

    double totalConflict = 0;

    for (final config in configs) {
      try {
        final isSystem =
            await _channel.invokeMethod<bool>('isSystemHotkey', {
              'key': config.systemKeyString,
            }) ??
            false;

        if (isSystem) {
          totalConflict += 1.0;
        } else if (_knownConflicts.contains(config.systemKeyString)) {
          totalConflict += 0.8;
        } else {
          // 基于修饰符组合判断冲突概率
          final conflictScore = _calculateModifierConflictScore(config);
          totalConflict += conflictScore;
        }
      } on Exception catch (e) {
        await Log.e('检查快捷键冲突失败', tag: _tag, error: e);
        totalConflict += 0.5; // 默认中等冲突风险
      }
    }

    return totalConflict / configs.length;
  }

  /// 计算修饰符冲突评分
  double _calculateModifierConflictScore(HotkeyConfig config) {
    final modifiers = config.modifiers;

    // 常见的高冲突修饰符组合
    const highConflictCombos = {
      {HotkeyModifier.command},
      {HotkeyModifier.command, HotkeyModifier.shift},
      {HotkeyModifier.command, HotkeyModifier.alt},
      {HotkeyModifier.command, HotkeyModifier.control},
    };

    if (highConflictCombos.contains(modifiers)) {
      return 0.6;
    } else if (modifiers.contains(HotkeyModifier.command) &&
        modifiers.length == 2) {
      return 0.4;
    } else {
      return 0.2;
    }
  }

  /// 生成推荐原因
  String _generateRecommendationReason(
    HotkeyAction action,
    HotkeyUsageStats? usage,
    double conflictProbability,
  ) {
    final parts = <String>[];

    if (usage != null && usage.count > 20) {
      parts.add('这是您的高频使用动作');
    }

    if (conflictProbability < 0.3) {
      parts.add('与系统快捷键冲突风险低');
    } else if (conflictProbability > 0.7) {
      parts.add('可能存在冲突风险');
    }

    switch (action) {
      case HotkeyAction.toggleWindow:
        parts.add('建议使用易于记忆的组合');
      case HotkeyAction.quickPaste:
        parts.add('推荐使用快速访问的组合');
      case HotkeyAction.showHistory:
        parts.add('适合使用易于访问的组合');
      case HotkeyAction.clearHistory:
        parts.add('建议使用不易误触的组合');
      case HotkeyAction.search:
        parts.add('推荐使用搜索相关的组合');
      case HotkeyAction.performOCR:
        parts.add('适合使用功能键组合');
      case HotkeyAction.toggleMonitoring:
        parts.add('建议使用简单的开关组合');
    }

    return parts.join('，');
  }

  /// 推荐更容易触发的快捷键
  HotkeyConfig _recommendEasierKeyForAction(
    HotkeyAction action,
    String? currentApp,
  ) {
    // 根据使用频率推荐更容易触发的组合
    switch (action) {
      case HotkeyAction.toggleWindow:
        return const HotkeyConfig(
          action: HotkeyAction.toggleWindow,
          key: '`',
          modifiers: {HotkeyModifier.command, HotkeyModifier.alt},
          description: '显示/隐藏剪贴板窗口',
        );
      case HotkeyAction.quickPaste:
        return const HotkeyConfig(
          action: HotkeyAction.quickPaste,
          key: 'v',
          modifiers: {HotkeyModifier.command, HotkeyModifier.control},
          description: '快速粘贴最近一项',
        );
      case HotkeyAction.showHistory:
        return const HotkeyConfig(
          action: HotkeyAction.showHistory,
          key: 'f9',
          modifiers: {HotkeyModifier.command},
          description: '显示剪贴板历史',
        );
      case HotkeyAction.clearHistory:
        return const HotkeyConfig(
          action: HotkeyAction.clearHistory,
          key: 'Delete',
          modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
          description: '清空剪贴板历史',
        );
      case HotkeyAction.search:
        return const HotkeyConfig(
          action: HotkeyAction.search,
          key: 'f',
          modifiers: {HotkeyModifier.command, HotkeyModifier.shift},
          description: '搜索剪贴板内容',
        );
      case HotkeyAction.performOCR:
        return const HotkeyConfig(
          action: HotkeyAction.performOCR,
          key: 'f8',
          modifiers: {HotkeyModifier.command},
          description: 'OCR文字识别',
        );
      case HotkeyAction.toggleMonitoring:
        return const HotkeyConfig(
          action: HotkeyAction.toggleMonitoring,
          key: 'm',
          modifiers: {HotkeyModifier.command, HotkeyModifier.alt},
          description: '暂停/恢复剪贴板监听',
        );
    }
  }

  /// 解析快捷键字符串
  HotkeyConfig _parseHotkeyString(String keyString, HotkeyAction action) {
    final parts = keyString.split('+');
    final keyPart = parts.last;

    final modifiers = <HotkeyModifier>{};
    for (final part in parts.take(parts.length - 1)) {
      switch (part.toLowerCase()) {
        case 'cmd':
        case 'command':
          modifiers.add(HotkeyModifier.command);
        case 'shift':
          modifiers.add(HotkeyModifier.shift);
        case 'alt':
        case 'option':
          modifiers.add(HotkeyModifier.alt);
        case 'ctrl':
        case 'control':
          modifiers.add(HotkeyModifier.control);
      }
    }

    return HotkeyConfig(
      action: action,
      key: keyPart,
      modifiers: modifiers,
      description: '智能推荐的快捷键',
    );
  }

  /// 检查冲突级别
  Future<double> _checkConflictLevel(HotkeyConfig config) async {
    try {
      final isSystem =
          await _channel.invokeMethod<bool>('isSystemHotkey', {
            'key': config.systemKeyString,
          }) ??
          false;

      if (isSystem) return 1.0;
      if (_knownConflicts.contains(config.systemKeyString)) return 0.8;
      return _calculateModifierConflictScore(config);
    } on Exception {
      return 0.5;
    }
  }

  /// 生成优化建议
  List<String> _generateOptimizationSuggestions(
    Map<HotkeyAction, HotkeyConfig> currentConfig,
    int conflictCount,
    List<HotkeyAction> unusedActions,
  ) {
    final suggestions = <String>[];

    if (conflictCount > 0) {
      suggestions.add('您有 $conflictCount 个快捷键可能存在冲突，建议更换');
    }

    if (unusedActions.isNotEmpty) {
      suggestions.add('有 ${unusedActions.length} 个快捷键很少使用，可以考虑重新配置');
    }

    if (currentConfig.length < 5) {
      suggestions.add('建议为常用功能配置更多快捷键以提高效率');
    }

    return suggestions;
  }

  /// 加载使用统计
  Future<void> _loadUsageStats() async {
    try {
      // 这里应该从持久化存储加载，暂时使用内存
      await Log.d('加载使用统计', tag: _tag);
    } on Exception catch (e) {
      await Log.e('加载使用统计失败', tag: _tag, error: e);
    }
  }

  /// 保存使用统计
  Future<void> _saveUsageStats() async {
    try {
      // 这里应该保存到持久化存储，暂时跳过
      await Log.d('保存使用统计', tag: _tag);
    } on Exception catch (e) {
      await Log.e('保存使用统计失败', tag: _tag, error: e);
    }
  }

  /// 加载冲突数据库
  Future<void> _loadConflictDatabase() async {
    try {
      // 初始化常见冲突快捷键
      _knownConflicts.addAll([
        'cmd+shift+o', // Xcode Open Quickly
        'cmd+j', // Xcode Show Navigator
        'cmd+b', // Build
        'cmd+r', // Run
        'cmd+t', // New Tab
        'cmd+w', // Close Window
        'cmd+q', // Quit
      ]);

      await Log.d('加载冲突数据库: ${_knownConflicts.length} 个冲突项', tag: _tag);
    } on Exception catch (e) {
      await Log.e('加载冲突数据库失败', tag: _tag, error: e);
    }
  }

  /// 加载应用特定偏好
  Future<void> _loadAppSpecificPreferences() async {
    try {
      // 这里应该从持久化存储加载，暂时使用内存
      await Log.d('加载应用特定偏好', tag: _tag);
    } on Exception catch (e) {
      await Log.e('加载应用特定偏好失败', tag: _tag, error: e);
    }
  }

  /// 保存应用特定偏好
  Future<void> _saveAppSpecificPreferences() async {
    try {
      // 这里应该保存到持久化存储，暂时跳过
      await Log.d('保存应用特定偏好', tag: _tag);
    } on Exception catch (e) {
      await Log.e('保存应用特定偏好失败', tag: _tag, error: e);
    }
  }

  /// 清理资源
  Future<void> dispose() async {
    try {
      _usageStats.clear();
      _appSpecificPreferences.clear();
      _isInitialized = false;
      await Log.d('推荐服务已清理', tag: _tag);
    } on Exception catch (e) {
      await Log.e('推荐服务清理失败', tag: _tag, error: e);
    }
  }
}
