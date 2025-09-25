/// 字符串常量
/// 定义应用中使用的所有字符串，避免硬编码
// ignore_for_file: public_member_api_docs
class AppStrings {
  /// 私有构造：禁止实例化
  AppStrings._();

  /// 确认对话框
  static const String confirmClearHistory = '确定要清空所有剪贴板历史吗？此操作不可恢复。';

  /// 取消按钮文本
  static const String cancel = '取消';

  /// 确定按钮文本
  static const String confirm = '确定';

  /// 清空按钮文本
  static const String clear = '清空';

  /// 删除项目确认提示
  static const String confirmDeleteItem = '确定要删除这个剪贴板项目吗？\n';

  /// 文件相关

  /// 未知文件标签
  static const String unknownFile = '未知文件';

  /// 未知标签
  static const String unknown = '未知';

  /// 时间格式

  /// 分钟前时间格式
  static const String timeFormatMinutes = '分钟前';

  /// 小时前时间格式
  static const String timeFormatHours = '小时前';

  /// 天前时间格式
  static const String timeFormatDays = '天前';

  /// 默认时间格式
  static const String timeFormatDefault = 'MM-dd HH:mm';

  /// 单位
  static const String unitWords = '字';
  static const String unitLines = '行';
  static const String unitKB = 'KB';
  static const String unitMB = 'MB';
  static const String unitGB = 'GB';

  /// 数据库相关
  static const String dbNotInitialized = 'Database not initialized';
  static const String encryptionNotInitialized = 'Encryption not initialized';

  /// 设置键名
  static const String prefKeyEncryptionKey = 'encryption_key';
  static const String prefKeyEncryptionIv = 'encryption_iv';

  /// 平台通道
  static const String channelClipboardService = 'clipboard_service';
  static const String methodGetClipboardSequence = 'getClipboardSequence';
  static const String methodGetClipboardImage = 'getClipboardImage';
  static const String methodGetSourceApp = 'getSourceApp';
  static const String methodSetClipboardImage = 'setClipboardImage';

  /// 文件路径相关
  static const String mediaPathTemplate = 'media/{type}/{yyyy}/{mm}/{dd}';
  static const String tempFileExtension = '.tmp';
  static const String defaultFileExtension = 'bin';

  /// 正则表达式相关
  static const String regexChineseChars = r'[\u4e00-\u9fa5]';
  static const String regexAlphanumericChinese = r'[a-zA-Z0-9\u4e00-\u9fa5]';
  static const String regexRtfContent = r'\\rtf';
  static const String regexFontTable = r'\\fonttbl';

  /// 加密算法
  static const String encryptionAlgorithm = 'AES-256-GCM';

  /// 默认值
  static const String defaultGlobalHotkey = 'Cmd+Shift+V';
  static const String defaultLanguage = 'zh_CN';
  static const int defaultMaxHistoryItems = 500;
  static const int defaultWordCountLimit = 50;

  /// 文件分隔符
  static const String pathSeparator = '/';
  static const String dotSeparator = '.';
  static const String commaSeparator = ',';

  /// 图片相关
  static const String imageFormatUnknown = 'unknown';
  static const String imageAltTemplate = '![{alt}]({imagePath})';
  static const String imageHtmlTemplate =
      '<img src="{imagePath}" alt="{alt}"{widthAttr}{heightAttr}>';

  /// 数据库字段
  static const String dbFieldIsFavorite = 'is_favorite';
  static const String dbFieldCreatedAt = 'created_at';
  static const String dbFieldUpdatedAt = 'updated_at';
  static const String dbFieldSchemaVersion = 'schema_version';
  static const String dbFieldFilePath = 'file_path';
  static const String dbFieldMetadata = 'metadata';
  static const String dbOrderByCreatedAtDesc = 'created_at DESC';

  /// 元数据字段
  static const String metaFileName = 'fileName';
  static const String metaFileExtension = 'fileExtension';
  static const String metaContentLength = 'contentLength';
  static const String metaLineCount = 'lineCount';
  static const String metaImageFormat = 'imageFormat';
  static const String metaWidth = 'width';
  static const String metaHeight = 'height';
  static const String metaAspectRatio = 'aspectRatio';
  static const String metaColorHex = 'colorHex';
}
