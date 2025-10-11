import 'package:flutter/foundation.dart';

/// 权限服务端口接口
///
/// 负责系统权限管理，包括：
/// - 权限检查
/// - 权限请求
/// - 权限状态监控
abstract class PermissionServicePort {
  /// 检查权限状态
  Future<PermissionStatus> checkPermission(PermissionType type);

  /// 请求权限
  Future<PermissionStatus> requestPermission(PermissionType type);

  /// 获取所有权限状态
  Future<Map<PermissionType, PermissionStatus>> getAllPermissions();

  /// 打开系统设置
  Future<void> openSystemSettings();
}

/// 热键服务端口接口
///
/// 负责全局热键管理，包括：
/// - 热键注册
/// - 热键监听
/// - 热键冲突检测
abstract class HotkeyServicePort {
  /// 注册热键
  Future<bool> registerHotkey(String id, String key, VoidCallback callback);

  /// 注销热键
  Future<bool> unregisterHotkey(String id);

  /// 检查热键冲突
  Future<bool> checkHotkeyConflict(String key);

  /// 获取已注册的热键
  Future<Map<String, String>> getRegisteredHotkeys();

  /// 启用/禁用热键服务
  Future<void> setEnabled(bool enabled);

  /// 获取热键服务状态
  bool get isEnabled;
}

/// 托盘服务端口接口
///
/// 负责系统托盘管理，包括：
/// - 托盘图标设置
/// - 托盘菜单管理
/// - 托盘事件处理
abstract class TrayServicePort {
  /// 初始化托盘
  Future<void> initialize();

  /// 设置托盘图标
  Future<void> setTrayIcon(String iconPath);

  /// 设置托盘工具提示
  Future<void> setTooltip(String tooltip);

  /// 显示托盘菜单
  Future<void> showMenu();

  /// 隐藏托盘菜单
  Future<void> hideMenu();

  /// 销毁托盘
  Future<void> dispose();
}

/// 自启动服务端口接口
///
/// 负责应用自启动管理，包括：
/// - 自启动设置
/// - 自启动检查
/// - 自启动配置
abstract class AutostartServicePort {
  /// 启用自启动
  Future<bool> enableAutostart();

  /// 禁用自启动
  Future<bool> disableAutostart();

  /// 检查自启动状态
  Future<bool> isAutostartEnabled();

  /// 获取自启动配置
  Future<Map<String, dynamic>> getAutostartConfig();
}

/// Finder 服务端口接口
///
/// 负责 Finder 集成，包括：
/// - 在 Finder 中显示文件
/// - 文件选择
/// - 文件操作
abstract class FinderServicePort {
  /// 在 Finder 中显示文件
  Future<void> showInFinder(String filePath);

  /// 选择文件
  Future<String?> selectFile({List<String>? allowedExtensions});

  /// 选择文件夹
  Future<String?> selectFolder();

  /// 复制文件到剪贴板
  Future<bool> copyFileToClipboard(String filePath);
}

/// 窗口监听服务端口接口
///
/// 负责窗口事件监听，包括：
/// - 窗口焦点变化
/// - 窗口状态变化
/// - 应用切换
abstract class WindowListenerPort {
  /// 开始监听窗口事件
  Future<void> startListening();

  /// 停止监听窗口事件
  Future<void> stopListening();

  /// 获取当前活动窗口信息
  Future<Map<String, dynamic>?> getCurrentWindowInfo();

  /// 获取当前活动应用信息
  Future<Map<String, dynamic>?> getCurrentAppInfo();
}

/// OCR 服务端口接口
///
/// 负责文字识别，包括：
/// - 图片文字识别
/// - 语言检测
/// - 置信度评估
abstract class OcrServicePort {
  /// 识别图片中的文字
  Future<OcrResult?> recognizeText(
    Uint8List imageBytes, {
    String? language,
    double? minConfidence,
  });

  /// 获取支持的语言列表
  Future<List<String>> getSupportedLanguages();

  /// 检测图片中的语言
  Future<String?> detectLanguage(Uint8List imageBytes);

  /// 获取服务状态
  Future<Map<String, dynamic>> getServiceStatus();
}

/// OCR 结果
class OcrResult {
  /// 构造函数
  const OcrResult({
    required this.text,
    required this.confidence,
    this.language,
    this.metadata,
  });

  /// 识别的文本
  final String text;

  /// 识别置信度
  final double confidence;

  /// 识别的语言
  final String? language;

  /// 元数据
  final Map<String, dynamic>? metadata;
}

/// 权限类型枚举
enum PermissionType {
  /// 剪贴板权限
  clipboard,

  /// 辅助功能权限
  accessibility,

  /// 屏幕录制权限
  screenRecording,

  /// 文件访问权限
  files,
}

/// 权限状态枚举
enum PermissionStatus {
  /// 已授权
  granted,

  /// 已拒绝
  denied,

  /// 未确定
  notDetermined,

  /// 受限制
  restricted,
}
