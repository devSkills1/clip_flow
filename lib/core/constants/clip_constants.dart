/// 剪贴板应用常量定义
class ClipConstants {
  // 应用信息
  static const String appName = 'ClipFlow Pro';
  static const String appVersion = '1.0.0';
  static const String appDescription = '强大的剪贴板管理工具';

  // 窗口尺寸
  static const double minWindowWidth = 800.0;
  static const double minWindowHeight = 600.0;
  static const double maxWindowWidth = 1920.0;
  static const double maxWindowHeight = 1080.0;
  static const double defaultWindowWidth = 1200.0;
  static const double defaultWindowHeight = 800.0;

  // 数据库
  static const String databaseName = 'clipflow_pro.db';
  static const int databaseVersion = 1;
  static const String clipItemsTable = 'clip_items';

  // 文件路径
  static const String thumbnailsDir = 'thumbnails';
  static const String cacheDir = 'cache';
  static const String logsDir = 'logs';

  // 限制值
  static const int maxHistoryItems = 1000;
  static const int maxThumbnailSize = 200;
  static const int maxContentLength = 1024 * 1024; // 1MB
  static const int maxSearchResults = 100;

  // 时间间隔
  static const int clipboardCheckInterval = 500; // 毫秒
  static const int autoSaveInterval = 30000; // 30秒
  static const int cacheCleanupInterval = 3600000; // 1小时

  // UI 常量
  static const double cardBorderRadius = 8.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // 字体大小
  static const double titleFontSize = 18.0;
  static const double bodyFontSize = 14.0;
  static const double captionFontSize = 12.0;
  static const double smallFontSize = 10.0;

  // 颜色
  static const int primaryColorValue = 0xFF2196F3;
  static const int accentColorValue = 0xFF03DAC6;
  static const int errorColorValue = 0xFFB00020;

  // 快捷键
  static const String defaultGlobalHotkey = 'cmd+shift+v';

  // 文件类型
  static const List<String> supportedImageFormats = [
    'png',
    'jpg',
    'jpeg',
    'gif',
    'bmp',
    'webp',
  ];

  static const List<String> supportedTextFormats = [
    'txt',
    'md',
    'json',
    'xml',
    'html',
    'css',
    'js',
    'dart',
  ];

  // 正则表达式
  static const String hexColorPattern = r'^#?(?:[A-Fa-f0-9]{3}|[A-Fa-f0-9]{4}|[A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$';

  static const String rgbColorPattern = r'^rgb\(\s*(0|255|25[0-4]|2[0-4]\d|[01]?\d\d?)\s*,\s*(0|255|25[0-4]|2[0-4]\d|[01]?\d\d?)\s*,\s*(0|255|25[0-4]|2[0-4]\d|[01]?\d\d?)\s*\)$';
  static const String rgbaColorPattern = r'^rgb\(\s*(0|255|25[0-4]|2[0-4]\d|[01]?\d\d?)\s*,\s*(0|255|25[0-4]|2[0-4]\d|[01]?\d\d?)\s*,\s*(0|255|25[0-4]|2[0-4]\d|[01]?\d\d?)\s*\)$';
  
  static const String hslColorPattern = r'^hsl\(\s*(360|3[0-5]\d|[0-2]?\d\d?)\s*,\s*(100%|\d{1,2}%)\s*,\s*(100%|\d{1,2}%)\s*\)$';
  static const String hslaColorPattern = r'^hsla\(\s*(360|3[0-5]\d|[0-2]?\d\d?)\s*,\s*(100%|\d{1,2}%)\s*,\s*(100%|\d{1,2}%)\s*,\s*(0|1|0\.\d+|1\.0)\s*\)$';

  static const String urlPattern = r'https?:\/\/(www\.)?[-\w@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{2,}\b([-\w()@:%_\+.~#?&//=]*(:\d{1,5})?)';
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  // 错误消息
  static const String errorDatabaseInit = '数据库初始化失败';
  static const String errorClipboardAccess = '无法访问剪贴板';
  static const String errorFileNotFound = '文件不存在';
  static const String errorNetworkConnection = '网络连接失败';
  static const String errorInvalidFormat = '格式不正确';

  // 成功消息
  static const String successCopied = '已复制到剪贴板';
  static const String successSaved = '保存成功';
  static const String successDeleted = '删除成功';
  static const String successExported = '导出成功';

  // 提示消息
  static const String tipEmptyHistory = '暂无剪贴板历史记录';
  static const String tipSearchNoResults = '未找到匹配的结果';
  static const String tipSelectItems = '请选择要操作的项目';

  // 设置键名
  static const String settingAutoStart = 'auto_start';
  static const String settingMinimizeToTray = 'minimize_to_tray';
  static const String settingGlobalHotkey = 'global_hotkey';
  static const String settingMaxHistoryItems = 'max_history_items';
  static const String settingEnableEncryption = 'enable_encryption';
  static const String settingEnableOCR = 'enable_ocr';
  static const String settingLanguage = 'language';
  static const String settingThemeMode = 'theme_mode';
  static const String settingDisplayMode = 'display_mode';

  // 网格间距
  static const double gridSpacing = 16.0;

  // 十六进制基数
  static const int hexRadix = 16;

  // 缩略图尺寸
  static const int thumbnailSize = 200;

  // 文件大小单位转换
  static const int bytesInKB = 1024;
}

/// 动画常量
class AnimationConstants {
  static const Duration fastDuration = Duration(milliseconds: 150);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);

  static const Duration fadeInDuration = Duration(milliseconds: 200);
  static const Duration slideInDuration = Duration(milliseconds: 250);
  static const Duration scaleInDuration = Duration(milliseconds: 200);
}

/// 布局常量
class LayoutConstants {
  // 网格布局
  static const int gridCrossAxisCount = 2;
  static const double gridChildAspectRatio = 1.5;
  static const double gridSpacing = 16.0;

  // 十六进制基数
  static const int hexRadix = 16;

  // 缩略图尺寸
  static const int thumbnailSize = 200;

  // 文件大小单位转换
  static const int bytesInKB = 1024;

  // 列表布局
  static const double listItemHeight = 80.0;
  static const double listItemSpacing = 8.0;

  // 卡片布局
  static const double cardElevation = 2.0;
  static const double cardMargin = 8.0;

  // 对话框
  static const double dialogMaxWidth = 400.0;
  static const double dialogMinHeight = 200.0;
}
