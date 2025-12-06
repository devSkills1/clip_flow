////
/// 剪贴板应用常量定义
/// Global constants shared across the app (names, sizes, patterns, messages).
///
/// 包含：
/// - 应用信息与描述
/// - 窗口与布局尺寸（单位：px、dp/逻辑像素）
/// - 数据库与路径常量
/// - UI 配置与字体大小
/// - 颜色数值（ARGB 整数）
/// - 支持的文件类型列表
/// - 正则表达式模式（原始字符串 r''）
/// - 文案与提示消息
/// - 设置键名
////
class ClipConstants {
  /// 应用信息（元数据）
  /// 应用名称
  static const String appName = 'ClipFlow Pro';

  /// 应用版本
  static const String appVersion = '1.0.0';

  /// 应用描述
  static const String appDescription = '强大的剪贴板管理工具';

  /// 窗口尺寸（单位：逻辑像素）
  /// 最小窗口宽度
  static const double minWindowWidth = 800;

  /// 最小窗口高度
  static const double minWindowHeight = 600;

  /// 最大窗口宽度
  static const double maxWindowWidth = 1920;

  /// 最大窗口高度
  static const double maxWindowHeight = 1080;

  /// 默认窗口宽度
  static const double defaultWindowWidth = 1200;

  /// 默认窗口高度
  static const double defaultWindowHeight = 800;

  /// 紧凑模式窗口尺寸
  /// 紧凑模式窗口高度
  static const double compactModeWindowHeight = 360;

  /// 紧凑模式窗口宽度比例
  static const double compactModeWidthRatio = 0.8;

  /// 数据库相关常量
  /// 数据库文件名
  static const String databaseName = 'clipflow_pro.db';

  /// 数据库版本号
  static const int databaseVersion = 2;

  /// 剪贴项表名
  static const String clipItemsTable = 'clip_items';

  /// 应用内相对文件路径
  /// 媒体文件根目录
  static const String mediaDir = 'media';

  /// 图片文件目录
  static const String mediaImagesDir = 'media/images';

  /// 其他文件目录（音频、视频、文件等）
  static const String mediaFilesDir = 'media/files';

  /// 缩略图目录
  static const String thumbnailsDir = 'thumbnails';

  /// 缓存目录
  static const String cacheDir = 'cache';

  /// 日志目录
  static const String logsDir = 'logs';

  /// 限制值（容量/数量/长度）
  /// 历史记录最大条数（默认值）
  static const int maxHistoryItems = 500;

  /// 缩略图最大边长（px）
  static const int maxThumbnailSize = 200;

  /// 内容最大长度（字节）
  static const int maxContentLength = 1024 * 1024; // 1MB
  /// 搜索结果最大数量
  static const int maxSearchResults = 100;

  /// 时间间隔（单位：毫秒）
  /// 剪贴板检查间隔
  static const int clipboardCheckInterval = 500; // 毫秒
  /// 自动保存间隔
  static const int autoSaveInterval = 30000; // 30秒
  /// 缓存清理间隔
  static const int cacheCleanupInterval = 3600000; // 1小时

  /// UI 常量（尺寸：逻辑像素）
  /// 卡片圆角
  static const double cardBorderRadius = 8;

  /// 默认内边距
  static const double defaultPadding = 16;

  /// 小号内边距
  static const double smallPadding = 8;

  /// 大号内边距
  static const double largePadding = 24;

  /// 字体大小（逻辑像素）
  /// 标题文字大小
  static const double titleFontSize = 18;

  /// 正文字体大小
  static const double bodyFontSize = 14;

  /// 说明文字大小
  static const double captionFontSize = 12;

  /// 极小文字大小
  static const double smallFontSize = 10;

  /// 颜色值（ARGB，0xAARRGGBB）
  /// 主色数值
  static const int primaryColorValue = 0xFF2196F3;

  /// 强调色数值
  static const int accentColorValue = 0xFF03DAC6;

  /// 错误色数值
  static const int errorColorValue = 0xFFB00020;

  /// 反馈邮箱
  static const String feedbackEmail = 'jr.lu.jobs@gmail.com';

  /// GitHub 仓库地址
  static const String githubRepositoryUrl =
      'https://github.com/devSkills1/clip_flow';

  /// 全局快捷键默认值（平台：macOS）
  static const String defaultGlobalHotkey = 'cmd+shift+v';

  /// 支持的文件类型
  /// 支持的图片格式列表
  static const List<String> supportedImageFormats = [
    'png',
    'jpg',
    'jpeg',
    'gif',
    'bmp',
    'webp',
  ];

  /// 支持的文本格式
  /// 文本/代码常见格式列表
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

  /// 正则表达式模式（用于校验颜色/URL/邮箱）
  /// 十六进制颜色（支持 3/4/6/8 位）
  static const String hexColorPattern =
      r'^#?(?:[A-Fa-f0-9]{3}|[A-Fa-f0-9]{4}|[A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$';

  /// rgb(...) 颜色（0-255）
  static const String rgbColorPattern =
      r'^rgb\(\s*(0|255|25[0-4]|2[0-4]\d|[01]?\d\d?)\s*,\s*(0|255|25[0-4]|2[0-4]\d|[01]?\d\d?)\s*,\s*(0|255|25[0-4]|2[0-4]\d|[01]?\d\d?)\s*\)$';

  /// rgba(...) 颜色（0-255 RGB值，0-1 透明度）
  static const String rgbaColorPattern =
      r'^rgba\(\s*(0|255|25[0-4]|2[0-4]\d|[01]?\d\d?)\s*,\s*(0|255|25[0-4]|2[0-4]\d|[01]?\d\d?)\s*,\s*(0|255|25[0-4]|2[0-4]\d|[01]?\d\d?)\s*,\s*(0|1|0\.\d+|1\.0)\s*\)$';

  /// hsl(...) 颜色（角度 0-360，百分比）
  static const String hslColorPattern =
      r'^hsl\(\s*(360|3[0-5]\d|[0-2]?\d\d?)\s*,\s*(100%|\d{1,2}%)\s*,\s*(100%|\d{1,2}%)\s*\)$';

  /// hsla(...) 颜色（角度0-360，百分比0-100%，透明度0-1）
  static const String hslaColorPattern =
      r'^hsla\(\s*(360|3[0-5]\d|[0-2]?\d\d?)\s*,\s*(100%|\d{1,2}%)\s*,\s*(100%|\d{1,2}%)\s*,\s*(0|1|0\.\d+|1\.0)\s*\)$';

  /// URL 格式（http/https，支持端口、localhost和IP地址）
  static const String urlPattern =
      r'https?:\/\/(www\.)?[-\w@:%._\+~#=]{1,256}(\.[a-zA-Z0-9()]{2,}|:\d{1,5})\b([-\w()@:%_\+.~#?&//=]*)?';

  /// 邮箱地址格式
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  /// 错误消息
  /// 数据库初始化失败
  static const String errorDatabaseInit = '数据库初始化失败';

  /// 无法访问剪贴板
  static const String errorClipboardAccess = '无法访问剪贴板';

  /// 文件不存在
  static const String errorFileNotFound = '文件不存在';

  /// 网络连接失败
  static const String errorNetworkConnection = '网络连接失败';

  /// 格式不正确
  static const String errorInvalidFormat = '格式不正确';

  /// 成功消息
  /// 复制成功
  static const String successCopied = '已复制到剪贴板';

  /// 保存成功
  static const String successSaved = '保存成功';

  /// 删除成功
  static const String successDeleted = '删除成功';

  /// 导出成功
  static const String successExported = '导出成功';

  /// 提示消息
  /// 空历史提示
  static const String tipEmptyHistory = '暂无剪贴板历史记录';

  /// 搜索无结果提示
  static const String tipSearchNoResults = '未找到匹配的结果';

  /// 选择项目提示
  static const String tipSelectItems = '请选择要操作的项目';

  /// 设置键名（持久化偏好）
  /// 是否开机自启动
  static const String settingAutoStart = 'auto_start';

  /// 关闭窗口时最小化到托盘
  static const String settingMinimizeToTray = 'minimize_to_tray';

  /// 全局快捷键
  static const String settingGlobalHotkey = 'global_hotkey';

  /// 历史记录上限
  static const String settingMaxHistoryItems = 'max_history_items';

  /// 启用加密
  static const String settingEnableEncryption = 'enable_encryption';

  /// 启用 OCR
  static const String settingEnableOCR = 'enable_ocr';

  /// 界面语言
  static const String settingLanguage = 'language';

  /// 主题模式
  static const String settingThemeMode = 'theme_mode';

  /// 网格间距（逻辑像素）
  static const double gridSpacing = 16;

  /// 十六进制基数
  static const int hexRadix = 16;

  /// 缩略图边长（像素）
  static const int thumbnailSize = 200;

  /// 文件大小单位换算（1 KB = 1024 B）
  static const int bytesInKB = 1024;
}

//// 动画常量
/// 动画相关的通用时长常量（Duration）。
class AnimationConstants {
  /// 快速动效时长（约 150ms）
  static const Duration fastDuration = Duration(milliseconds: 150);

  /// 常规动效时长（约 300ms）
  static const Duration normalDuration = Duration(milliseconds: 300);

  /// 缓慢动效时长（约 500ms）
  static const Duration slowDuration = Duration(milliseconds: 500);

  /// 渐隐/渐显时长
  static const Duration fadeInDuration = Duration(milliseconds: 200);

  /// 滑入时长
  static const Duration slideInDuration = Duration(milliseconds: 250);

  /// 缩放时长
  static const Duration scaleInDuration = Duration(milliseconds: 200);
}

//// 布局常量
/// 布局与组件尺寸相关的常量。
class LayoutConstants {
  /// 网格布局
  /// 网格的列数
  static const int gridCrossAxisCount = 2;

  /// 子项宽高比
  static const double gridChildAspectRatio = 1.5;

  /// 网格间距
  static const double gridSpacing = 16;

  /// 十六进制基数
  static const int hexRadix = 16;

  /// 缩略图边长（像素）
  static const int thumbnailSize = 200;

  /// 文件大小单位换算（1 KB = 1024 B）
  static const int bytesInKB = 1024;

  /// 列表布局
  /// 列表项高度
  static const double listItemHeight = 80;

  /// 列表项间距
  static const double listItemSpacing = 8;

  /// 卡片布局
  /// 卡片阴影高度
  static const double cardElevation = 2;

  /// 卡片外边距
  static const double cardMargin = 8;

  /// 对话框
  /// 对话框最大宽度
  static const double dialogMaxWidth = 400;

  /// 对话框最小高度
  static const double dialogMinHeight = 200;
}
