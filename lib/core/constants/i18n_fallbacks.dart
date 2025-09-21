//// 文案回退常量
/// 集中管理 UI 文案的本地回退值，避免 i18n 缺失造成的崩溃或空白。
/// 使用示例：
///   final t = I18nFallbacks;
///   Text(S.of(context)?.settingsTitle ?? t.settings.title);
class I18nFallbacks {
  /// 私有构造：禁止实例化
  const I18nFallbacks._();

  /// 设置页文案回退
  static const settings = _SettingsFallback();

  /// 通用文案回退
  static const common = _CommonFallback();

  /// 首页文案回退
  static const home = _HomeFallback();

  /// 筛选侧边栏文案回退
  static const filter = _FilterFallback();

  /// 性能监控文案回退
  static const performance = _PerformanceFallback();
}

class _CommonFallback {
  /// 通用文案
  const _CommonFallback();

  /// 操作类：确定
  final String actionOk = '确定';

  /// 操作类：取消
  final String actionCancel = '取消';

  /// 操作类：删除
  final String actionDelete = '删除';

  /// 标签：未知
  final String unknown = '未知';

  /// 气泡提示：复制成功前缀
  String snackCopiedPrefix(String label) => '已复制: $label';

  /// 弹窗标题：确认删除
  final String deleteTitle = '确认删除';

  /// 弹窗内容前缀：确认删除提示
  final String deleteContentPrefix = '确定要删除这个剪贴板项目吗？\n';

  /// 实体标签：图片
  final String labelImage = '图片';

  /// 实体标签：文件
  final String labelFile = '文件';

  /// 实体标签：颜色
  final String labelColor = '颜色';

  /// 时间显示：刚刚
  final String timeJustNow = '刚刚';

  /// 时间显示：分钟前
  String timeMinutesAgo(int minutes) => '$minutes分钟前';

  /// 时间显示：小时前
  String timeHoursAgo(int hours) => '$hours小时前';

  /// 时间显示：天前
  String timeDaysAgo(int days) => '$days天前';

  /// 时间显示：月前
  String timeMonthsAgo(int months) => '$months个月前';

  /// 时间显示：年前
  String timeYearsAgo(int years) => '$years年前';

  /// 剪贴板类型：文本
  final String clipTypeText = '文本';

  /// 剪贴板类型：图片
  final String clipTypeImage = '图片';

  /// 剪贴板类型：文件
  final String clipTypeFile = '文件';

  /// 剪贴板类型：链接
  final String clipTypeUrl = '链接';

  /// 剪贴板类型：颜色
  final String clipTypeColor = '颜色';

  /// 剪贴板类型：富文本
  final String clipTypeRichText = '富文本';

  /// 剪贴板类型：音频
  final String clipTypeAudio = '音频';

  /// 剪贴板类型：视频
  final String clipTypeVideo = '视频';

  /// 剪贴板类型：HTML
  final String clipTypeHtml = 'HTML';
}

class _HomeFallback {
  /// 首页文案
  const _HomeFallback();

  /// 空状态标题
  final String emptyTitle = '暂无内容';

  /// 空状态副标题
  final String emptySubtitle = '复制一些内容开始使用吧';

  /// 搜索提示
  final String searchHint = '搜索剪贴板历史...';
}

class _SettingsFallback {
  /// 设置页文案
  const _SettingsFallback();

  /// AppBar 标题
  final String title = '设置';

  /// 分组：常规
  final String sectionGeneral = '常规';

  /// 分组：安全
  final String sectionSecurity = '安全';

  /// 分组：外观
  final String sectionAppearance = '外观';

  /// 分组：关于
  final String sectionAbout = '关于';

  /// 常规：开机自启动 标题
  final String generalAutoStartTitle = '开机自启动';

  /// 常规：开机自启动 副标题
  final String generalAutoStartSubtitle = '应用启动时自动运行';

  /// 常规：最小化到系统托盘 标题
  final String generalMinimizeToTrayTitle = '最小化到系统托盘';

  /// 常规：最小化到系统托盘 副标题
  final String generalMinimizeToTraySubtitle = '关闭窗口时最小化到系统托盘';

  /// 常规：全局快捷键 标题
  final String generalGlobalHotkeyTitle = '全局快捷键';

  /// 常规：全局快捷键 副标题（直接显示组合键）
  String generalGlobalHotkeySubtitle(String hotkey) => hotkey;

  /// 常规：最大历史记录数 标题
  final String generalMaxHistoryTitle = '最大历史记录数';

  /// 常规：最大历史记录数 副标题（显示条数）
  String generalMaxHistorySubtitle(int count) => '$count 条';

  /// 安全：启用加密 标题
  final String securityEnableEncryptionTitle = '启用加密';

  /// 安全：启用加密 副标题
  final String securityEnableEncryptionSubtitle = '使用AES-256加密存储敏感数据';

  /// 安全：启用OCR 标题
  final String securityEnableOcrTitle = '启用OCR';

  /// 安全：启用OCR 副标题
  final String securityEnableOcrSubtitle = '自动识别图片中的文字';

  /// 外观：主题模式 标题
  final String appearanceThemeModeTitle = '主题模式';

  /// 外观：默认显示模式 标题
  final String appearanceDefaultDisplayModeTitle = '默认显示模式';

  /// 外观：语言 标题
  final String appearanceLanguageTitle = '语言';

  /// 主题选项：浅色
  final String themeLight = '浅色';

  /// 主题选项：深色
  final String themeDark = '深色';

  /// 主题选项：跟随系统
  final String themeSystem = '跟随系统';

  /// 显示方式：紧凑
  final String displayCompact = '紧凑';

  /// 显示方式：默认
  final String displayNormal = '默认';

  /// 显示方式：预览
  final String displayPreview = '预览';

  /// 语言：中文（简体）
  final String languageZhCN = '简体中文';

  /// 语言：英语（美国）
  final String languageEnUS = 'English';

  /// 弹窗：设置全局快捷键 标题
  final String dialogHotkeyTitle = '设置全局快捷键';

  /// 弹窗：设置全局快捷键 内容
  final String dialogHotkeyContent = '请按下您想要设置的快捷键组合';

  /// 弹窗：设置最大历史记录数 标题
  final String dialogMaxHistoryTitle = '设置最大历史记录数';

  /// 弹窗：设置最大历史记录数 内容
  final String dialogMaxHistoryContent = '选择最大保存的剪贴板历史记录数量';

  /// 弹窗：设置最大历史记录数 输入框标签
  final String dialogMaxHistoryFieldLabel = '历史记录数量';

  /// 弹窗：选择主题模式 标题
  final String dialogThemeTitle = '选择主题模式';

  /// 弹窗：选择默认显示模式 标题
  final String dialogDisplayModeTitle = '选择默认显示模式';

  /// 弹窗：选择语言 标题
  final String dialogLanguageTitle = '选择语言';

  /// 关于：版本 标题
  final String aboutVersionTitle = '版本';

  /// 关于：版本 值
  final String aboutVersionValue = '1.0.0';

  /// 设置页操作：检查更新 标题
  final String actionCheckUpdateTitle = '检查更新';

  /// 设置页操作：检查更新 副标题
  final String actionCheckUpdateSubtitle = '检查最新版本';

  /// 设置页操作：反馈问题 标题
  final String actionFeedbackTitle = '反馈问题';

  /// 设置页操作：反馈问题 副标题
  final String actionFeedbackSubtitle = '报告Bug或建议';

  /// 显示模式说明：紧凑
  final String displayCompactDesc = '列表形式，显示更多项目';

  /// 显示模式说明：默认
  final String displayNormalDesc = '网格形式，平衡显示效果';

  /// 显示模式说明：预览
  final String displayPreviewDesc = '大卡片形式，突出内容预览';
}

class _FilterFallback {
  /// 筛选侧边栏文案
  const _FilterFallback();

  /// 筛选标题
  final String title = '筛选';

  /// 类型分组标题
  final String typeSection = '类型';

  /// 显示模式分组标题
  final String displayModeSection = '显示模式';

  /// 类型选项：全部
  final String typeAll = '全部';

  /// 类型选项：文本
  final String typeText = '文本';

  /// 类型选项：富文本
  final String typeRichText = '富文本';

  /// 类型选项：图片
  final String typeImage = '图片';

  /// 类型选项：颜色
  final String typeColor = '颜色';

  /// 类型选项：文件
  final String typeFile = '文件';

  /// 类型选项：音频
  final String typeAudio = '音频';

  /// 类型选项：视频
  final String typeVideo = '视频';

  /// 显示模式：紧凑
  final String displayCompact = '紧凑';

  /// 显示模式：默认
  final String displayNormal = '默认';

  /// 显示模式：预览
  final String displayPreview = '预览';

  /// 设置按钮
  final String settingsButton = '设置';

  /// 确认清空对话框标题
  final String confirmClearTitle = '确认清空';

  /// 清空历史按钮
  final String clearHistoryButton = '清空历史';
}

class _PerformanceFallback {
  /// 性能监控文案回退
  const _PerformanceFallback();

  /// 性能监控标题
  final String monitor = '性能监控';

  /// 性能指标重置消息
  final String metricsReset = '性能指标已重置';

  /// 性能重置失败消息
  final String resetFailed = '重置性能指标失败';

  /// FPS标签
  final String fps = '帧率 (FPS)';

  /// 内存使用标签
  final String memory = '内存使用';

  /// CPU使用率标签
  final String cpu = 'CPU 使用率';

  /// 卡顿次数标签
  final String jank = '卡顿次数';

  /// 数据库查询标签
  final String dbQuery = '数据库查询';

  /// 剪贴板捕获标签
  final String clipboard = '剪贴板捕获';

  /// 性能评分标签
  final String score = '性能评分';

  /// 性能良好状态
  final String good = '性能良好';

  /// 性能警告状态
  final String warning = '性能警告';

  /// 内存泄漏警告
  final String memoryLeak = '检测到内存泄漏';

  /// 优化建议对话框标题
  final String optimizationTitle = '性能优化建议';

  /// 关闭按钮
  final String close = '关闭';

  /// 优化建议数量
  String optimizationCount(int count) => '优化建议 ($count)';

  /// 性能建议：减少动画
  final String recommendationReduceAnimations = '建议: 减少复杂动画和重绘操作';

  /// 性能建议：重绘边界
  final String recommendationRepaintBoundary = '建议: 使用RepaintBoundary优化渲染';

  /// 性能建议：内存泄漏
  final String recommendationMemoryLeak = '建议: 检查是否存在内存泄漏';

  /// 性能建议：释放资源
  final String recommendationReleaseResources = '建议: 及时释放不再使用的资源';

  /// 性能建议：优化CPU
  final String recommendationOptimizeCpu = '建议: 优化计算密集型操作';

  /// 性能建议：使用Isolate
  final String recommendationUseIsolate = '建议: 使用Isolate处理耗时任务';

  /// 性能建议：检查主线程
  final String recommendationCheckMainThread = '建议: 检查主线程阻塞操作';

  /// 性能建议：异步IO
  final String recommendationAsyncIO = '建议: 使用异步操作处理IO任务';

  /// 严重FPS警报
  String alertCriticalFps(String fps) => '严重: FPS过低 ($fps)';

  /// 警告FPS警报
  String alertWarningFps(String fps) => '警告: FPS偏低 ($fps)';

  /// 严重内存警报
  String alertCriticalMemory(String memory) => '严重: 内存使用过高 (${memory}MB)';

  /// 警告内存警报
  String alertWarningMemory(String memory) => '警告: 内存使用偏高 (${memory}MB)';

  /// 严重CPU警报
  String alertCriticalCpu(String cpu) => '严重: CPU使用率过高 ($cpu%)';

  /// 警告CPU警报
  String alertWarningCpu(String cpu) => '警告: CPU使用率偏高 ($cpu%)';

  /// 性能监控流错误
  final String streamError = '性能监控流错误';

  /// 启动性能监控失败
  final String startFailed = '启动性能监控失败';

  /// 性能告警前缀
  final String alert = '性能告警';
}
