import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clip_flow_pro/core/models/hotkey_config.dart';
import 'package:clip_flow_pro/core/services/observability/logger/logger.dart';
import 'package:clip_flow_pro/core/services/storage/preferences_service.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

/// 快捷键冲突类型
enum HotkeyConflictType {
  /// 与系统快捷键冲突
  system,

  /// 与应用内其他快捷键冲突
  internal,

  /// 与其他应用快捷键冲突
  external,
}

/// 快捷键冲突信息
@immutable
class HotkeyConflict {
  /// 构造函数
  const HotkeyConflict({
    required this.config,
    required this.type,
    required this.description,
  });

  /// 冲突的快捷键配置
  final HotkeyConfig config;

  /// 冲突类型
  final HotkeyConflictType type;

  /// 冲突描述
  final String description;
}

/// 快捷键注册结果
@immutable
class HotkeyRegistrationResult {
  /// 构造函数
  const HotkeyRegistrationResult({
    required this.success,
    this.error,
    this.conflicts = const [],
  });

  /// Creates a successful registration result with no errors or conflicts.
  factory HotkeyRegistrationResult.success() {
    return const HotkeyRegistrationResult(success: true);
  }

  /// Creates a failed registration result with an optional list of conflicts.
  factory HotkeyRegistrationResult.failure(
    String error, [
    List<HotkeyConflict>? conflicts,
  ]) {
    return HotkeyRegistrationResult(
      success: false,
      error: error,
      conflicts: conflicts ?? [],
    );
  }

  /// 是否成功注册
  final bool success;

  /// 注册失败时的错误信息
  final String? error;

  /// 注册冲突的快捷键配置
  final List<HotkeyConflict> conflicts;
}

/// 全局快捷键服务
class HotkeyService {
  /// 构造函数
  HotkeyService(this._preferencesService);
  static const String _tag = 'HotkeyService';
  static const String _prefsKey = 'hotkey_configs';

  /// 平台通道
  static const MethodChannel _channel = MethodChannel('clipboard_service');

  /// 偏好设置服务
  final PreferencesService _preferencesService;

  /// 当前注册的快捷键配置
  final Map<HotkeyAction, HotkeyConfig> _registeredHotkeys = {};

  /// 快捷键动作回调
  final Map<HotkeyAction, VoidCallback> _actionCallbacks = {};

  /// 是否已初始化
  bool _isInitialized = false;

  /// 是否支持全局快捷键
  bool _isSupported = false;

  /// 快捷键注册重试计数器
  final Map<HotkeyAction, int> _registrationRetryCount = {};

  /// 最大重试次数
  static const int _maxRetryCount = 3;

  /// 初始化快捷键服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Log.i('初始化快捷键服务', tag: _tag);

      // 检查平台支持
      _isSupported = await _checkPlatformSupport();

      if (!_isSupported) {
        await Log.w('当前平台不支持全局快捷键', tag: _tag);
        _isInitialized = true;
        return;
      }

      // 设置平台通道方法调用处理器
      _channel.setMethodCallHandler(_handleMethodCall);

      // 加载保存的快捷键配置
      await _loadHotkeyConfigs();

      // 注册默认快捷键（如果没有保存的配置）
      if (_registeredHotkeys.isEmpty) {
        await _registerDefaultHotkeys();
      }

      _isInitialized = true;
      await Log.i(
        '快捷键服务初始化完成',
        tag: _tag,
        fields: {
          'supported': _isSupported,
          'registered_count': _registeredHotkeys.length,
        },
      );
    } on Exception catch (e) {
      unawaited(Future(() => Log.e('快捷键服务初始化失败', tag: _tag, error: e)));
      rethrow;
    }
  }

  /// 检查平台支持
  Future<bool> _checkPlatformSupport() async {
    try {
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        final result = await _channel.invokeMethod<bool>('isHotkeySupported');
        return result ?? false;
      }

      return false;
    } on Exception catch (e) {
      await Log.e('检查快捷键支持失败', tag: _tag, error: e);
      return false;
    }
  }

  /// 处理平台通道方法调用
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onHotkeyPressed':
          String? actionName;
          final args = call.arguments;
          if (args is String) {
            actionName = args;
          } else if (args is Map) {
            final map = Map<Object?, Object?>.from(args);
            final value = map['action'];
            actionName = value is String ? value : null;
          }

          if (actionName != null) {
            final action = HotkeyAction.values.firstWhere(
              (a) => a.name == actionName,
              orElse: () => throw ArgumentError('Unknown action: $actionName'),
            );
            await handleHotkeyPressed(action);
          } else {
            await Log.w(
              '快捷键回调参数无效',
              tag: _tag,
              fields: {
                'arguments': call.arguments,
              },
            );
          }
        default:
          await Log.w('未知的方法调用: ${call.method}', tag: _tag);
      }
    } on Exception catch (e) {
      await Log.e(
        '处理方法调用失败',
        tag: _tag,
        error: e,
        fields: {
          'method': call.method,
          'arguments': call.arguments,
        },
      );
    }
  }

  /// 处理快捷键按下事件
  Future<void> handleHotkeyPressed(HotkeyAction action) async {
    try {
      await Log.i('快捷键被按下', tag: _tag, fields: {'action': action.name});

      final callback = _actionCallbacks[action];
      if (callback != null) {
        await Log.i('执行快捷键回调', tag: _tag, fields: {'action': action.name});
        callback();
        await Log.i('快捷键回调执行完成', tag: _tag, fields: {'action': action.name});
      } else {
        await Log.w('未找到快捷键动作回调', tag: _tag, fields: {'action': action.name});
      }
    } on Exception catch (e) {
      await Log.e(
        '处理快捷键按下事件失败',
        tag: _tag,
        error: e,
        fields: {
          'action': action.name,
        },
      );
    }
  }

  /// 注册快捷键动作回调
  void registerActionCallback(HotkeyAction action, VoidCallback callback) {
    _actionCallbacks[action] = callback;
    Log.d('注册快捷键动作回调', tag: _tag, fields: {'action': action.name});
  }

  /// 取消注册快捷键动作回调
  void unregisterActionCallback(HotkeyAction action) {
    _actionCallbacks.remove(action);
    Log.d('取消注册快捷键动作回调', tag: _tag, fields: {'action': action.name});
  }

  /// 注册快捷键
  Future<HotkeyRegistrationResult> registerHotkey(HotkeyConfig config) async {
    if (!_isSupported) {
      return HotkeyRegistrationResult.failure('平台不支持全局快捷键');
    }

    try {
      await Log.d(
        '注册快捷键',
        tag: _tag,
        fields: {
          'action': config.action.name,
          'key': config.displayString,
        },
      );

      // 检查冲突
      final conflicts = await _checkConflicts(config);
      if (conflicts.isNotEmpty) {
        return HotkeyRegistrationResult.failure('快捷键冲突', conflicts);
      }

      // 先取消注册已存在的快捷键
      if (_registeredHotkeys.containsKey(config.action)) {
        await _unregisterHotkey(config.action);
      }

      // 使用公共注册方法
      final result = await _registerHotkeyWithChannel(config);

      if (result) {
        // 清除重试计数器
        _registrationRetryCount.remove(config.action);
        return HotkeyRegistrationResult.success();
      } else {
        // 注册失败，检查是否需要重试
        final retryCount = _registrationRetryCount[config.action] ?? 0;
        if (retryCount < _maxRetryCount) {
          _registrationRetryCount[config.action] = retryCount + 1;
          await Log.w(
            '快捷键注册失败，准备重试',
            tag: _tag,
            fields: {
              'action': config.action.name,
              'key': config.displayString,
              'retryCount': retryCount + 1,
            },
          );

          // 延迟重试
          await Future<void>.delayed(
            Duration(milliseconds: 500 * (retryCount + 1)),
          );
          return registerHotkey(config);
        } else {
          await Log.e(
            '快捷键注册失败，已达到最大重试次数',
            tag: _tag,
            fields: {
              'action': config.action.name,
              'key': config.displayString,
              'retryCount': retryCount,
            },
          );
          return HotkeyRegistrationResult.failure('系统注册失败，已达到最大重试次数');
        }
      }
    } on Exception catch (e) {
      await Log.e(
        '注册快捷键失败',
        tag: _tag,
        error: e,
        fields: {
          'action': config.action.name,
          'key': config.displayString,
        },
      );
      return HotkeyRegistrationResult.failure('注册失败: $e');
    }
  }

  /// 通过通道注册快捷键的公共方法
  Future<bool> _registerHotkeyWithChannel(
    HotkeyConfig config, {
    bool saveConfig = true,
  }) async {
    try {
      // 调用平台通道注册快捷键
      final result = await _channel.invokeMethod<bool>('registerHotkey', {
        'action': config.action.name,
        'key': config.systemKeyString,
        'enabled': config.enabled,
        'ignoreRepeat': config.ignoreRepeat,
      });

      if (result ?? false) {
        _registeredHotkeys[config.action] = config;

        if (saveConfig) {
          await _saveHotkeyConfigs();
        }

        await Log.i(
          '快捷键注册成功',
          tag: _tag,
          fields: {
            'action': config.action.name,
            'key': config.displayString,
          },
        );

        return true;
      } else {
        return false;
      }
    } on Exception catch (e) {
      await Log.e(
        '通过通道注册快捷键失败',
        tag: _tag,
        error: e,
        fields: {
          'action': config.action.name,
          'key': config.displayString,
        },
      );
      return false;
    }
  }

  /// 取消注册快捷键
  Future<bool> unregisterHotkey(HotkeyAction action) async {
    return _unregisterHotkey(action);
  }

  /// 内部取消注册快捷键
  Future<bool> _unregisterHotkey(HotkeyAction action) async {
    if (!_isSupported) return false;

    try {
      final config = _registeredHotkeys[action];
      if (config == null) return true;

      await Log.d(
        '取消注册快捷键',
        tag: _tag,
        fields: {
          'action': action.name,
          'key': config.displayString,
        },
      );

      final result = await _channel.invokeMethod<bool>('unregisterHotkey', {
        'action': action.name,
      });

      if (result ?? false) {
        _registeredHotkeys.remove(action);
        await _saveHotkeyConfigs();

        await Log.i(
          '快捷键取消注册成功',
          tag: _tag,
          fields: {
            'action': action.name,
          },
        );

        return true;
      } else {
        await Log.w(
          '快捷键取消注册失败',
          tag: _tag,
          fields: {
            'action': action.name,
          },
        );
        return false;
      }
    } on Exception catch (e) {
      await Log.e(
        '取消注册快捷键失败',
        tag: _tag,
        error: e,
        fields: {
          'action': action.name,
        },
      );
      return false;
    }
  }

  /// 检查快捷键冲突
  Future<List<HotkeyConflict>> _checkConflicts(HotkeyConfig config) async {
    final conflicts = <HotkeyConflict>[];

    // 检查应用内冲突
    for (final existingConfig in _registeredHotkeys.values) {
      if (existingConfig.action != config.action &&
          existingConfig.key == config.key &&
          existingConfig.modifiers.length == config.modifiers.length &&
          existingConfig.modifiers.every(config.modifiers.contains)) {
        conflicts.add(
          HotkeyConflict(
            config: existingConfig,
            type: HotkeyConflictType.internal,
            description: '与动作 ${existingConfig.action.name} 冲突',
          ),
        );
      }
    }

    // 检查系统快捷键冲突（直接调用原生方法）
    if (await _isSystemHotkey(config)) {
      conflicts.add(
        HotkeyConflict(
          config: config,
          type: HotkeyConflictType.system,
          description: '与系统快捷键冲突',
        ),
      );
    }

    return conflicts;
  }

  /// 检查是否为系统快捷键（直接调用原生方法）
  Future<bool> _isSystemHotkey(HotkeyConfig config) async {
    try {
      final result = await _channel.invokeMethod<bool>('isSystemHotkey', {
        'key': config.systemKeyString,
      });
      return result ?? false;
    } on Exception catch (e) {
      await Log.e('检查系统快捷键失败', tag: _tag, error: e);
      return false;
    }
  }

  /// 获取已注册的快捷键
  Map<HotkeyAction, HotkeyConfig> get registeredHotkeys =>
      Map.unmodifiable(_registeredHotkeys);

  /// 获取指定动作的快捷键配置
  HotkeyConfig? getHotkeyConfig(HotkeyAction action) {
    return _registeredHotkeys[action];
  }

  /// 是否支持全局快捷键
  bool get isSupported => _isSupported;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 加载快捷键配置
  Future<void> _loadHotkeyConfigs() async {
    try {
      final configsJson = await _preferencesService.getString(_prefsKey);
      if (configsJson != null && configsJson.isNotEmpty) {
        final configsList = jsonDecode(configsJson) as List<dynamic>;

        for (final configJson in configsList) {
          final config = HotkeyConfig.fromJson(
            configJson as Map<String, dynamic>,
          );
          if (config.enabled) {
            // 使用公共注册方法，不保存配置（避免重复保存）
            final result = await _registerHotkeyWithChannel(
              config,
              saveConfig: false,
            );

            if (!result) {
              await Log.w(
                '加载快捷键配置时注册失败',
                tag: _tag,
                fields: {
                  'action': config.action.name,
                  'key': config.displayString,
                },
              );
            }
          }
        }

        await Log.i(
          '加载快捷键配置完成',
          tag: _tag,
          fields: {
            'loaded_count': _registeredHotkeys.length,
          },
        );
      }
    } on Exception catch (e) {
      await Log.e('加载快捷键配置失败', tag: _tag, error: e);
    }
  }

  /// 保存快捷键配置
  Future<void> _saveHotkeyConfigs() async {
    try {
      final configsList = _registeredHotkeys.values
          .map((config) => config.toJson())
          .toList();

      final configsJson = jsonEncode(configsList);
      await _preferencesService.setString(_prefsKey, configsJson);

      await Log.d(
        '保存快捷键配置完成',
        tag: _tag,
        fields: {
          'saved_count': configsList.length,
        },
      );
    } on Exception catch (e) {
      await Log.e('保存快捷键配置失败', tag: _tag, error: e);
    }
  }

  /// 注册默认快捷键
  Future<void> _registerDefaultHotkeys() async {
    await Log.i('注册默认快捷键', tag: _tag);

    for (final config in DefaultHotkeyConfigs.defaults) {
      final result = await registerHotkey(config);
      if (!result.success) {
        await Log.w(
          '注册默认快捷键失败',
          tag: _tag,
          fields: {
            'action': config.action.name,
            'error': result.error,
          },
        );
      }
    }
  }

  /// 重置为默认快捷键
  Future<void> resetToDefaults() async {
    await Log.i('重置为默认快捷键', tag: _tag);

    // 取消注册所有快捷键
    final actions = _registeredHotkeys.keys.toList();
    for (final action in actions) {
      await _unregisterHotkey(action);
    }

    // 注册默认快捷键
    await _registerDefaultHotkeys();
  }

  /// 清理资源
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await Log.i('清理快捷键服务', tag: _tag);

      // 取消注册所有快捷键
      final actions = _registeredHotkeys.keys.toList();
      for (final action in actions) {
        await _unregisterHotkey(action);
      }

      // 清理回调
      _actionCallbacks.clear();

      // 清理缓存
      _registrationRetryCount.clear();

      _isInitialized = false;

      await Log.i('快捷键服务清理完成', tag: _tag);
    } on Exception catch (e) {
      await Log.e('清理快捷键服务失败', tag: _tag, error: e);
    }
  }
}
