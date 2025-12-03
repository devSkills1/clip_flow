import 'dart:io';

import 'package:clip_flow_pro/core/constants/clip_constants.dart';

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

  /// 存储管理文案回退
  static const storage = _StorageFallback();
}

class _CommonFallback {
  /// 通用文案
  const _CommonFallback();

  /// 操作类：确定
  String get actionOk => '确定';

  /// 操作类：取消
  String get actionCancel => '取消';

  /// 操作类：删除
  String get actionDelete => '删除';

  /// 标签：未知
  String get unknown => '未知';

  /// 气泡提示：复制成功前缀
  String snackCopiedPrefix(String label) => '已复制: $label';

  /// 弹窗标题：确认删除
  String get deleteTitle => '确认删除';

  /// 弹窗内容前缀：确认删除提示
  String get deleteContentPrefix => '确定要删除这个剪贴板项目吗？\n';

  /// 实体标签：图片
  String get labelImage => '图片';

  /// 实体标签：文件
  String get labelFile => '文件';

  /// 实体标签：颜色
  String get labelColor => '颜色';

  /// 时间显示：刚刚
  String get timeJustNow => '刚刚';

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
  String get clipTypeText => '文本';

  /// 剪贴板类型：图片
  String get clipTypeImage => '图片';

  /// 剪贴板类型：文件
  String get clipTypeFile => '文件';

  /// 剪贴板类型：链接
  String get clipTypeUrl => '链接';

  /// 剪贴板类型：颜色
  String get clipTypeColor => '颜色';

  /// 剪贴板类型：富文本
  String get clipTypeRichText => '富文本';

  /// 剪贴板类型：音频
  String get clipTypeAudio => '音频';

  /// 剪贴板类型：视频
  String get clipTypeVideo => '视频';

  /// 剪贴板类型：HTML
  String get clipTypeHtml => 'HTML';

  /// 剪贴板类型：邮箱
  String get clipTypeEmail => '邮箱';

  /// 剪贴板类型：JSON
  String get clipTypeJson => 'JSON';

  /// 剪贴板类型：XML
  String get clipTypeXml => 'XML';

  /// 剪贴板类型：代码
  String get clipTypeCode => '代码';
}

class _HomeFallback {
  /// 首页文案
  const _HomeFallback();

  /// 空状态标题
  String get emptyTitle => '暂无内容';

  /// 空状态副标题
  String get emptySubtitle => '复制一些内容开始使用吧';

  /// 搜索提示
  String get searchHint => '搜索剪贴板历史...';
}

class _SettingsFallback {
  /// 设置页文案
  const _SettingsFallback();

  /// AppBar 标题
  String get title => '设置';

  /// 分组：常规
  String get sectionGeneral => '常规';

  /// 分组：安全
  String get sectionSecurity => '安全';

  /// 分组：外观
  String get sectionAppearance => '外观';

  /// 分组：关于
  String get sectionAbout => '关于';

  /// 常规：开机自启动 标题
  String get generalAutoStartTitle => '开机自启动';

  /// 常规：开机自启动 副标题
  String get generalAutoStartSubtitle => '应用启动时自动运行';

  /// 常规：最小化到系统托盘 标题
  String get generalMinimizeToTrayTitle => '最小化到系统托盘';

  /// 常规：最小化到系统托盘 副标题
  String get generalMinimizeToTraySubtitle => '关闭窗口时最小化到系统托盘';

  /// 常规：自动隐藏 标题
  String get generalAutoHideTitle => '自动隐藏窗口';

  /// 常规：自动隐藏 副标题
  String get generalAutoHideSubtitle => '静置后自动隐藏，冷启动与 Cmd + Option + ` 唤起均生效';

  /// 常规：全局快捷键 标题
  String get generalGlobalHotkeyTitle => '全局快捷键';

  /// 常规：全局快捷键 副标题（直接显示组合键）
  String generalGlobalHotkeySubtitle(String hotkey) => hotkey;

  /// 常规：自动隐藏快捷键 标题
  String get generalAutoHideHotkeyTitle => '自动隐藏快捷键';

  /// 常规：自动隐藏快捷键 副标题
  String generalAutoHideHotkeySubtitle(String hotkey) => '当前快捷键：$hotkey';

  /// 常规：自动隐藏延迟 标题
  String get generalAutoHideTimeoutTitle => '自动隐藏延迟';

  /// 常规：自动隐藏延迟 副标题（显示秒数）
  String generalAutoHideTimeoutSubtitle(int seconds) => '无操作后 $seconds 秒自动隐藏';

  /// 常规：最大历史记录数 标题
  String get generalMaxHistoryTitle => '最大历史记录数';

  /// 常规：最大历史记录数 副标题（显示条数）
  String generalMaxHistorySubtitle(int count) => '$count 条';

  /// 常规：开机自启动切换错误
  String generalAutoStartErrorMessage(String error) => '更新开机自启动失败: $error';

  /// 安全：启用加密 标题
  String get securityEnableEncryptionTitle => '启用加密';

  /// 安全：启用加密 副标题
  String get securityEnableEncryptionSubtitle => '使用AES-256加密存储敏感数据';

  /// 安全：启用OCR 标题
  String get securityEnableOcrTitle => '启用OCR';

  /// 安全：启用OCR 副标题
  String get securityEnableOcrSubtitle => '自动识别图片中的文字';

  /// OCR：识别语言 标题
  String get ocrLanguageTitle => 'OCR 识别语言';

  /// OCR：识别语言 副标题
  String get ocrLanguageSubtitle => '选择用于识别的语言（可选自动）';

  /// OCR：最小置信度 标题
  String get ocrMinConfidenceTitle => '最小置信度阈值';

  /// OCR：最小置信度 副标题
  String get ocrMinConfidenceSubtitle => '低于该阈值的识别结果将被忽略';

  /// 外观：主题模式 标题
  String get appearanceThemeModeTitle => '主题模式';

  /// 外观：语言 标题
  String get appearanceLanguageTitle => '语言';

  /// 主题选项：浅色
  String get themeLight => '浅色';

  /// 主题选项：深色
  String get themeDark => '深色';

  /// 主题选项：跟随系统
  String get themeSystem => '跟随系统';

  /// 显示方式：紧凑
  String get displayCompact => '紧凑';

  /// 显示方式：默认
  String get displayNormal => '默认';

  /// 显示方式：预览
  String get displayPreview => '预览';

  /// 语言：中文（简体）
  String get languageZhCN => '简体中文';

  /// 语言：英语（美国）
  String get languageEnUS => 'English';

  /// 弹窗：设置全局快捷键 标题
  String get dialogHotkeyTitle => '设置全局快捷键';

  /// 弹窗：设置全局快捷键 内容
  String get dialogHotkeyContent => '请按下您想要设置的快捷键组合';

  /// 弹窗：设置最大历史记录数 标题
  String get dialogMaxHistoryTitle => '设置最大历史记录数';

  /// 弹窗：设置最大历史记录数 内容
  String get dialogMaxHistoryContent => '选择最大保存的剪贴板历史记录数量';

  /// 弹窗：设置最大历史记录数 输入框标签
  String get dialogMaxHistoryFieldLabel => '历史记录数量';

  /// 弹窗：设置最大历史记录数 Helper
  String get dialogMaxHistoryHelperText => '建议值：100-2000';

  /// 弹窗：选择主题模式 标题
  String get dialogThemeTitle => '选择主题模式';

  /// 弹窗：选择语言 标题
  String get dialogLanguageTitle => '选择语言';

  /// 关于：版本 标题
  String get aboutVersionTitle => '版本';

  /// 关于：版本 值
  String get aboutVersionValue => '1.0.0';

  /// 设置页操作：检查更新 标题
  String get actionCheckUpdateTitle => '检查更新';

  /// 数字格式化：千单位
  String get formatCountThousand => '千';

  /// 数字格式化：万单位
  String get formatCountTenThousand => '万';

  /// 数字格式化：亿单位
  String get formatCountHundredMillion => '亿';

  /// 数字格式化：百万单位
  String get formatCountMillion => '百万';

  /// 数字格式化：十亿单位
  String get formatCountBillion => '十亿';

  /// 设置页操作：检查更新 副标题
  String get actionCheckUpdateSubtitle => '检查最新版本';

  /// 设置页操作：反馈问题 标题
  String get actionFeedbackTitle => '反馈问题';

  /// 设置页操作：反馈问题 副标题
  String get actionFeedbackSubtitle => '报告Bug或建议';

  /// 显示模式说明：紧凑
  String get displayCompactDesc => '列表形式，显示更多项目';

  /// 显示模式说明：默认
  String get displayNormalDesc => '网格形式，平衡显示效果';

  /// 显示模式说明：预览
  String get displayPreviewDesc => '大卡片形式，突出内容预览';

  /// 分组：存储管理
  String get sectionStorage => '存储管理';

  /// 存储：数据库文件 标题
  String get storageDataBaseTitle => '数据库文件';

  /// 存储：数据库文件 副标题
  String get storageDataBaseSubtitle => '在Finder中显示剪贴板数据库文件';

  /// 存储：图片文件 标题
  String get storageImageTitle => '图片文件';

  /// 存储：图片文件 副标题
  String get storageImageSubtitle => '在Finder中显示保存的图片文件夹';

  /// 存储：文件存储 标题
  String get storageFileTitle => '文件存储';

  /// 存储：文件存储 副标题
  String get storageFileSubtitle => '在Finder中显示保存的文件夹';

  /// 存储：应用数据 标题
  String get storageAppDataTitle => '应用数据';

  /// 存储：应用数据 副标题
  String get storageAppDataSubtitle => '在Finder中显示应用数据目录';

  /// 存储：日志文件 标题
  String get storageLogTitle => '日志文件';

  /// 存储：日志文件 副标题
  String get storageLogSubtitle => '在Finder中显示应用日志文件夹';

  /// 存储管理错误消息
  String get storageErrorCannotShow => '无法在Finder中显示';

  /// 存储管理错误消息：打开Finder时出错
  String storageErrorOpenFinder(String error) => '打开Finder时出错: $error';

  /// 存储管理错误消息：数据库文件
  String get storageErrorDatabase => '无法在Finder中显示数据库文件';

  /// 存储管理错误消息：图片文件夹
  String get storageErrorImage => '无法在Finder中显示图片文件夹';

  /// 存储管理错误消息：文件夹
  String get storageErrorFile => '无法在Finder中显示文件夹';

  /// 存储管理错误消息：应用数据目录
  String get storageErrorAppData => '无法在Finder中显示应用数据目录';

  /// 存储管理错误消息：日志文件夹
  String get storageErrorLog => '无法在Finder中显示日志文件夹';

  /// 存储：清理空数据 标题
  String get storageCleanEmptyTitle => '清理空数据';

  /// 存储：清理空数据 副标题
  String get storageCleanEmptySubtitle => '删除内容为空的剪贴板记录';

  /// 存储：验证数据完整性 标题
  String get storageValidateTitle => '验证数据完整性';

  /// 存储：验证数据完整性 副标题
  String get storageValidateSubtitle => '检查并修复数据库中的问题';

  /// 开发者选项 标题
  String get developerOptionsTitle => '开发者选项';

  /// 性能监控覆盖层 标题
  String get performanceOverlayTitle => '性能监控覆盖层';

  /// 性能监控覆盖层 副标题
  String get performanceOverlaySubtitle => '显示实时性能指标覆盖层';

  /// 开发者模式状态：已激活
  String get developerModeActive => '开发者模式已激活';

  /// 开发者模式状态：已关闭
  String get developerModeInactive => '开发者模式已关闭';

  /// 最大历史记录数单位
  String maxHistoryUnit(int count) => '$count 条';

  /// 清理空数据对话框标题
  String get cleanEmptyDialogTitle => '清理空数据';

  /// 清理空数据对话框内容
  String get cleanEmptyDialogContent => '确定要清理数据库中的空内容记录吗？此操作不可撤销。';

  /// 清理成功消息
  String cleanSuccessMessage(int count) => '已清理 $count 条空数据记录';

  /// 清理失败消息
  String cleanErrorMessage(String error) => '清理失败: $error';

  /// 数据验证进度文本
  String get validateProgressText => '正在验证数据完整性...';

  /// 数据验证完成对话框标题
  String get validateCompleteDialogTitle => '数据验证完成';

  /// 清理空文本记录统计
  String validateEmptyTextDeleted(int count) => '清理空文本记录: $count 条';

  /// 清理孤儿文件统计
  String validateOrphanFilesDeleted(int count) => '清理孤儿文件: $count 个';

  /// 剩余记录总数统计
  String validateTotalRemaining(int count) => '剩余记录总数: $count 条';

  /// 验证失败消息
  String validateErrorMessage(String error) => '验证失败: $error';

  /// 检查更新进度文本
  String get checkUpdateProgressText => '正在检查更新...';

  /// 检查更新对话框标题
  String get checkUpdateDialogTitle => '检查更新';

  /// 检查更新对话框内容
  String get checkUpdateDialogContent => '您已经是最新版本';

  /// 检查更新失败消息
  String checkUpdateErrorMessage(String error) => '检查更新失败: $error';

  /// 更新可用对话框标题
  String get updateAvailableTitle => '发现新版本';

  /// 最新版本前缀（用于显示 "最新版本: 1.2.3"）
  String get updateLatestVersionPrefix => '最新版本: ';

  /// 更新内容标题
  String get updateReleaseNotesTitle => '更新内容:';

  /// 稍后更新按钮
  String get updateLaterAction => '稍后更新';

  /// 立即下载按钮
  String get downloadNowAction => '立即下载';

  /// 反馈与建议对话框标题
  String get feedbackDialogTitle => '反馈与建议';

  /// 邮件反馈标题
  String get feedbackEmailTitle => '邮件反馈';

  /// 邮件反馈主题
  String get feedbackEmailSubject => 'ClipFlow Pro 反馈与建议';

  /// 邮件反馈正文
  String get feedbackEmailBody =>
      '请在这里描述您的反馈或建议...\n\n---\n应用版本: ${ClipConstants.appVersion}\n系统平台: ${Platform.operatingSystem}';

  /// 问题报告标题
  String get feedbackIssueTitle => '问题报告';

  /// 问题报告副标题
  String get feedbackIssueSubtitle => '在GitHub上报告问题';

  /// 打开反馈失败消息
  String feedbackErrorMessage(String error) => '打开反馈失败: $error';

  /// 邮件反馈开发中消息
  String get feedbackEmailInDevelopment => '邮件反馈功能开发中...';

  /// 打开邮件失败消息
  String feedbackEmailErrorMessage(String error) => '打开邮件失败: $error';

  /// 问题报告开发中消息
  String get feedbackIssueInDevelopment => '问题报告功能开发中...';

  /// 打开问题页面失败消息
  String feedbackIssueErrorMessage(String error) => '打开问题页面失败: $error';
}

class _StorageFallback {
  /// 存储管理文案
  const _StorageFallback();

  /// 分组标题：存储管理
  String get sectionTitle => '存储管理';

  /// 数据库文件
  String get database => '数据库文件';

  /// 数据库文件描述
  String get databaseDesc => '在Finder中显示剪贴板数据库文件';

  /// 图片文件
  String get images => '图片文件';

  /// 图片文件描述
  String get imagesDesc => '在Finder中显示保存的图片文件夹';

  /// 文件存储
  String get files => '文件存储';

  /// 文件存储描述
  String get filesDesc => '在Finder中显示保存的文件夹';

  /// 应用数据
  String get appData => '应用数据';

  /// 应用数据描述
  String get appDataDesc => '在Finder中显示应用数据目录';

  /// 日志文件
  String get logs => '日志文件';

  /// 日志文件描述
  String get logsDesc => '在Finder中显示应用日志文件夹';

  /// 错误消息：无法显示
  String get errorCannotShow => '无法在Finder中显示';

  /// 错误消息：打开Finder出错
  String errorOpenFinder(String error) => '打开Finder时出错: $error';

  /// 错误消息：数据库文件
  String get errorDatabase => '无法在Finder中显示数据库文件';

  /// 错误消息：图片文件夹
  String get errorImage => '无法在Finder中显示图片文件夹';

  /// 错误消息：文件夹
  String get errorFile => '无法在Finder中显示文件夹';

  /// 错误消息：应用数据目录
  String get errorAppData => '无法在Finder中显示应用数据目录';

  /// 错误消息：日志文件夹
  String get errorLog => '无法在Finder中显示日志文件夹';
}

class _FilterFallback {
  /// 筛选侧边栏文案
  const _FilterFallback();

  /// 筛选标题
  String get title => '筛选';

  /// 类型分组标题
  String get typeSection => '类型';

  /// 显示模式分组标题
  String get displayModeSection => '显示模式';

  /// 类型选项：全部
  String get typeAll => '全部';

  /// 类型选项：文本
  String get typeText => '文本';

  /// 类型选项：富文本
  String get typeRichText => '富文本';

  /// 类型选项：RTF
  String get typeRtf => 'RTF';

  /// 类型选项：HTML
  String get typeHtml => 'HTML';

  /// 类型选项：图片
  String get typeImage => '图片';

  /// 类型选项：颜色
  String get typeColor => '颜色';

  /// 类型选项：文件
  String get typeFile => '文件';

  /// 类型选项：音频
  String get typeAudio => '音频';

  /// 类型选项：视频
  String get typeVideo => '视频';

  /// 显示模式：紧凑
  String get displayCompact => '紧凑';

  /// 显示模式：默认
  String get displayNormal => '默认';

  /// 显示模式：预览
  String get displayPreview => '预览';

  /// 设置按钮
  String get settingsButton => '设置';

  /// 确认清空对话框标题
  String get confirmClearTitle => '确认清空';

  /// 清空历史按钮
  String get clearHistoryButton => '清空历史';
}

class _PerformanceFallback {
  /// 性能监控文案回退
  const _PerformanceFallback();

  /// 性能监控标题
  String get monitor => '性能监控';

  /// 性能指标重置消息
  String get metricsReset => '性能指标已重置';

  /// 性能重置失败消息
  String get resetFailed => '重置性能指标失败';

  /// FPS标签
  String get fps => '帧率 (FPS)';

  /// 内存使用标签
  String get memory => '内存使用';

  /// CPU使用率标签
  String get cpu => 'CPU 使用率';

  /// 卡顿次数标签
  String get jank => '卡顿次数';

  /// 数据库查询标签
  String get dbQuery => '数据库查询';

  /// 剪贴板捕获标签
  String get clipboard => '剪贴板捕获';

  /// 性能评分标签
  String get score => '性能评分';

  /// 性能良好状态
  String get good => '性能良好';

  /// 性能警告状态
  String get warning => '性能警告';

  /// 内存泄漏警告
  String get memoryLeak => '检测到内存泄漏';

  /// 优化建议对话框标题
  String get optimizationTitle => '性能优化建议';

  /// 关闭按钮
  String get close => '关闭';

  /// 优化建议数量
  String optimizationCount(int count) => '优化建议 ($count)';

  /// 性能建议：减少动画
  String get recommendationReduceAnimations => '建议: 减少复杂动画和重绘操作';

  /// 性能建议：重绘边界
  String get recommendationRepaintBoundary => '建议: 使用RepaintBoundary优化渲染';

  /// 性能建议：内存泄漏
  String get recommendationMemoryLeak => '建议: 检查是否存在内存泄漏';

  /// 性能建议：释放资源
  String get recommendationReleaseResources => '建议: 及时释放不再使用的资源';

  /// 性能建议：优化CPU
  String get recommendationOptimizeCpu => '建议: 优化计算密集型操作';

  /// 性能建议：使用Isolate
  String get recommendationUseIsolate => '建议: 使用Isolate处理耗时任务';

  /// 性能建议：检查主线程
  String get recommendationCheckMainThread => '建议: 检查主线程阻塞操作';

  /// 性能建议：异步IO
  String get recommendationAsyncIO => '建议: 使用异步操作处理IO任务';

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
  String get streamError => '性能监控流错误';

  /// 启动性能监控失败
  String get startFailed => '启动性能监控失败';

  /// 性能告警前缀
  String get alert => '性能告警';

  /// 平均帧时间标签
  String get avgFrameTime => '平均帧时间';

  /// 卡顿百分比标签
  String get jankPercentage => '卡顿百分比';

  /// 帧时间方差标签
  String get frameTimeVariance => '帧时间方差';

  /// 性能健康状态：优秀
  String get healthExcellent => '优秀';

  /// 性能健康状态：良好
  String get healthGood => '良好';

  /// 性能健康状态：一般
  String get healthFair => '一般';

  /// 性能健康状态：较差
  String get healthPoor => '较差';

  /// 性能健康状态：预热
  String get healthWarmingUp => '预热';

  /// 性能健康状态：未知
  String get healthUnknown => '未知';
}
