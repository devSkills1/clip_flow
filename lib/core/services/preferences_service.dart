import 'dart:convert';

import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户偏好设置持久化服务（单例）
///
/// 使用 SharedPreferences 进行用户偏好设置的持久化存储：
/// - 提供保存和加载用户偏好设置的方法
/// - 支持 JSON 序列化/反序列化
/// - 使用常量键名确保一致性
class PreferencesService {
  /// 工厂构造：返回单例实例
  factory PreferencesService() => _instance;

  /// 私有构造函数
  PreferencesService._internal();

  /// 单例实例
  static final PreferencesService _instance = PreferencesService._internal();

  /// SharedPreferences 实例
  SharedPreferences? _prefs;

  /// 用户偏好设置的存储键
  static const String _userPreferencesKey = 'user_preferences';

  /// 初始化服务
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 保存用户偏好设置
  ///
  /// 参数：
  /// - preferences: 要保存的用户偏好设置
  ///
  /// 返回：保存是否成功
  Future<bool> savePreferences(UserPreferences preferences) async {
    await initialize();
    if (_prefs == null) return false;

    try {
      final jsonString = jsonEncode(preferences.toJson());
      return await _prefs!.setString(_userPreferencesKey, jsonString);
    } catch (e) {
      // 记录错误但不抛出异常
      // TODO: 使用日志框架替代 print
      return false;
    }
  }

  /// 加载用户偏好设置
  ///
  /// 返回：用户偏好设置，如果不存在则返回默认设置
  Future<UserPreferences> loadPreferences() async {
    await initialize();
    if (_prefs == null) return UserPreferences();

    try {
      final jsonString = _prefs!.getString(_userPreferencesKey);
      if (jsonString == null) {
        return UserPreferences();
      }

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserPreferences.fromJson(jsonMap);
    } catch (e) {
      // 如果解析失败，返回默认设置
      // TODO: 使用日志框架替代 print
      return UserPreferences();
    }
  }

  /// 清除所有用户偏好设置
  ///
  /// 返回：清除是否成功
  Future<bool> clearPreferences() async {
    await initialize();
    if (_prefs == null) return false;

    try {
      return await _prefs!.remove(_userPreferencesKey);
    } on Exception catch (_) {
      // TODO: 使用日志框架替代 print
      return false;
    }
  }

  /// 检查是否存在保存的偏好设置
  ///
  /// 返回：是否存在保存的设置
  Future<bool> hasPreferences() async {
    await initialize();
    if (_prefs == null) return false;

    return _prefs!.containsKey(_userPreferencesKey);
  }

  /// 获取偏好设置信息
  ///
  /// 返回：包含设置信息的 Map
  Future<Map<String, dynamic>> getPreferencesInfo() async {
    await initialize();
    if (_prefs == null) {
      return {
        'hasPreferences': false,
        'dataSize': 0,
        'lastModified': null,
      };
    }

    final hasPrefs = _prefs!.containsKey(_userPreferencesKey);
    final jsonString = _prefs!.getString(_userPreferencesKey);

    return {
      'hasPreferences': hasPrefs,
      'dataSize': jsonString?.length ?? 0,
      'lastModified': hasPrefs ? DateTime.now().toIso8601String() : null,
    };
  }
}
