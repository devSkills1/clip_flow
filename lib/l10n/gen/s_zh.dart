// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 's.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class SZh extends S {
  SZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Clip Flow Pro';

  @override
  String get homeTitle => '首页';

  @override
  String get appSwitcherTitle => '紧凑模式';

  @override
  String get settingsTitle => '设置';

  @override
  String get sectionGeneral => '常规';

  @override
  String get sectionSecurity => '安全';

  @override
  String get sectionAppearance => '外观';

  @override
  String get sectionAbout => '关于';

  @override
  String get generalAutoStartTitle => '开机自启动';

  @override
  String get generalAutoStartSubtitle => '应用启动时自动运行';

  @override
  String generalAutoStartErrorMessage(String error) {
    return '更新开机自启动失败：$error';
  }

  @override
  String get generalMinimizeToTrayTitle => '最小化到系统托盘';

  @override
  String get generalMinimizeToTraySubtitle => '关闭窗口时最小化到系统托盘';

  @override
  String get generalAutoHideTitle => '自动隐藏窗口';

  @override
  String get generalAutoHideSubtitle => '静置后自动隐藏，冷启动与 Cmd + Option + ` 唤起均生效';

  @override
  String get generalGlobalHotkeyTitle => '全局快捷键';

  @override
  String generalGlobalHotkeySubtitle(String hotkey) {
    return '当前快捷键：$hotkey';
  }

  @override
  String get generalAutoHideHotkeyTitle => '自动隐藏快捷键';

  @override
  String generalAutoHideHotkeySubtitle(String hotkey) {
    return '当前快捷键：$hotkey';
  }

  @override
  String get generalAutoHideTimeoutTitle => '自动隐藏延迟';

  @override
  String generalAutoHideTimeoutSubtitle(int seconds) {
    return '无操作后 $seconds 秒自动隐藏';
  }

  @override
  String get generalMaxHistoryTitle => '最大历史记录数';

  @override
  String generalMaxHistorySubtitle(int count) {
    return '$count 条';
  }

  @override
  String get securityEnableEncryptionTitle => '启用加密';

  @override
  String get securityEnableEncryptionSubtitle => '使用AES-256加密存储敏感数据';

  @override
  String get securityEnableOcrTitle => '启用OCR';

  @override
  String get securityEnableOcrSubtitle => '自动识别图片中的文字';

  @override
  String get clipCardOcrDisabledHint => '检测到OCR文本，但OCR功能已禁用。请在设置中启用。';

  @override
  String get clipCardOcrFailedHint => 'OCR识别失败，或置信度低于阈值。';

  @override
  String get appearanceThemeModeTitle => '主题模式';

  @override
  String get appearanceDefaultDisplayModeTitle => '默认显示模式';

  @override
  String get appearanceLanguageTitle => '语言';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get displayCompact => '紧凑';

  @override
  String get displayNormal => '默认';

  @override
  String get displayPreview => '预览';

  @override
  String get displayCompactDesc => '紧凑模式：更高信息密度，单行预览';

  @override
  String get displayNormalDesc => '默认模式：信息密度适中，常规预览';

  @override
  String get displayPreviewDesc => '预览模式：更大缩略图与更详细的预览';

  @override
  String get languageZhCN => '简体中文';

  @override
  String get languageEnUS => 'English';

  @override
  String get dialogHotkeyTitle => '设置全局快捷键';

  @override
  String get dialogHotkeyContent => '请按下您想要设置的快捷键组合';

  @override
  String get dialogMaxHistoryTitle => '设置最大历史记录数';

  @override
  String get dialogMaxHistoryContent => '选择最大保存的剪贴板历史记录数量';

  @override
  String get dialogMaxHistoryFieldLabel => '历史记录数量';

  @override
  String get dialogMaxHistoryHelperText => '建议值：100-2000';

  @override
  String get dialogThemeTitle => '选择主题模式';

  @override
  String get dialogDisplayModeTitle => '选择默认显示模式';

  @override
  String get dialogLanguageTitle => '选择语言';

  @override
  String get actionCancel => '取消';

  @override
  String get actionOk => '确定';

  @override
  String get actionCheckUpdateTitle => '检查更新';

  @override
  String get actionCheckUpdateSubtitle => '检查最新版本';

  @override
  String get actionFeedbackTitle => '反馈问题';

  @override
  String get actionFeedbackSubtitle => '报告Bug或建议';

  @override
  String get headerActionOpenAppSwitcher => '紧凑模式';

  @override
  String get headerActionBackTraditional => '经典模式';

  @override
  String get windowMinimizeTooltip => '最小化窗口';

  @override
  String get windowCloseTooltip => '关闭窗口';

  @override
  String get aboutVersionTitle => '版本';

  @override
  String get aboutVersionValue => '1.0.0';

  @override
  String get homeEmptyTitle => '暂无剪贴板历史';

  @override
  String get homeEmptySubtitle => '复制一些内容开始使用吧';

  @override
  String get searchEmptyTitle => '未找到匹配内容';

  @override
  String get searchEmptySubtitle => '尝试调整关键词或筛选条件';

  @override
  String snackCopiedPrefix(String text) {
    return '已复制: $text';
  }

  @override
  String get dialogDeleteTitle => '确认删除';

  @override
  String dialogDeleteContent(String text) {
    return '确定要删除这个剪贴板项目吗？\\n$text';
  }

  @override
  String get actionDelete => '删除';

  @override
  String previewImage(int width, int height, String format) {
    return '图片 ($width x $height, $format)';
  }

  @override
  String previewFile(String fileName) {
    return '文件: $fileName';
  }

  @override
  String previewColor(String hex) {
    return '颜色: $hex';
  }

  @override
  String compactStatCharacters(String count) {
    return '$count字符';
  }

  @override
  String compactStatWords(String count) {
    return '$count词';
  }

  @override
  String compactStatLines(String count) {
    return '$count行';
  }

  @override
  String get unknownFormat => '未知格式';

  @override
  String get unknownFile => '未知文件';

  @override
  String get filterTitle => '筛选';

  @override
  String get filterTypeSection => '类型';

  @override
  String get filterDisplayModeSection => '显示模式';

  @override
  String get filterTypeAll => '全部';

  @override
  String get filterTypeText => '文本';

  @override
  String get filterTypeRichText => '富文本';

  @override
  String get filterTypeImage => '图片';

  @override
  String get filterTypeColor => '颜色';

  @override
  String get filterTypeFile => '文件';

  @override
  String get filterTypeAudio => '音频';

  @override
  String get filterTypeVideo => '视频';

  @override
  String get filterSettingsButton => '设置';

  @override
  String get filterClearHistoryButton => '清空历史';

  @override
  String get filterClearSearchButton => '清空搜索';

  @override
  String get filterClearAllUnfavoritedButton => '清空未收藏的';

  @override
  String get filterClearAllButton => '全部清空';

  @override
  String get filterConfirmClearTitle => '确认清空';

  @override
  String get filterConfirmClearContent =>
      '确定要清空历史记录吗？\n\n此操作将删除所有【未收藏】的历史，保留收藏项。\n此操作不可撤销。';

  @override
  String get searchHint => '搜索剪贴板历史...';

  @override
  String get timeJustNow => '刚刚';

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes分钟前';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours小时前';
  }

  @override
  String timeDaysAgo(int days) {
    return '$days天前';
  }

  @override
  String get clipTypeText => '文本';

  @override
  String get clipTypeRichText => '富文本';

  @override
  String get clipTypeHtml => 'HTML';

  @override
  String get clipTypeImage => '图片';

  @override
  String get formatCountThousand => '千';

  @override
  String get formatCountTenThousand => '万';

  @override
  String get formatCountHundredMillion => '亿';

  @override
  String get formatCountMillion => '百万';

  @override
  String get formatCountBillion => '十亿';

  @override
  String get clipTypeColor => '颜色';

  @override
  String get clipTypeFile => '文件';

  @override
  String get clipTypeAudio => '音频';

  @override
  String get clipTypeVideo => '视频';

  @override
  String get clipTypeUrl => '网址';

  @override
  String get clipTypeEmail => '邮箱';

  @override
  String get clipTypeJson => 'JSON';

  @override
  String get clipTypeXml => 'XML';

  @override
  String get clipTypeCode => '代码';

  @override
  String get performanceMonitor => '性能监控';

  @override
  String get performanceMetricsReset => '性能指标已重置';

  @override
  String get performanceResetFailed => '重置性能指标失败';

  @override
  String get performanceFps => '帧率 (FPS)';

  @override
  String get performanceMemory => '内存使用';

  @override
  String get performanceCpu => 'CPU 使用率';

  @override
  String get performanceJank => '卡顿次数';

  @override
  String get performanceDbQuery => '数据库查询';

  @override
  String get performanceClipboard => '剪贴板捕获';

  @override
  String get performanceScore => '性能评分';

  @override
  String get performanceGood => '性能良好';

  @override
  String get performanceWarning => '性能警告';

  @override
  String get performanceMemoryLeak => '检测到内存泄漏';

  @override
  String get performanceOptimizationTitle => '性能优化建议';

  @override
  String get performanceOptimizationClose => '关闭';

  @override
  String performanceOptimizationCount(int count) {
    return '优化建议 ($count)';
  }

  @override
  String get performanceRecommendationReduceAnimations => '建议: 减少复杂动画和重绘操作';

  @override
  String get performanceRecommendationRepaintBoundary =>
      '建议: 使用RepaintBoundary优化渲染';

  @override
  String get performanceRecommendationMemoryLeak => '建议: 检查是否存在内存泄漏';

  @override
  String get performanceRecommendationReleaseResources => '建议: 及时释放不再使用的资源';

  @override
  String get performanceRecommendationOptimizeCpu => '建议: 优化计算密集型操作';

  @override
  String get performanceRecommendationUseIsolate => '建议: 使用Isolate处理耗时任务';

  @override
  String get performanceRecommendationCheckMainThread => '建议: 检查主线程阻塞操作';

  @override
  String get performanceRecommendationAsyncIO => '建议: 使用异步操作处理IO任务';

  @override
  String performanceAlertCriticalFps(String fps) {
    return '严重: FPS过低 ($fps)';
  }

  @override
  String performanceAlertWarningFps(String fps) {
    return '警告: FPS偏低 ($fps)';
  }

  @override
  String performanceAlertCriticalMemory(String memory) {
    return '严重: 内存使用过高 (${memory}MB)';
  }

  @override
  String performanceAlertWarningMemory(String memory) {
    return '警告: 内存使用偏高 (${memory}MB)';
  }

  @override
  String performanceAlertCriticalCpu(String cpu) {
    return '严重: CPU使用率过高 ($cpu%)';
  }

  @override
  String performanceAlertWarningCpu(String cpu) {
    return '警告: CPU使用率偏高 ($cpu%)';
  }

  @override
  String get performanceStreamError => '性能监控流错误';

  @override
  String get performanceStartFailed => '启动性能监控失败';

  @override
  String get performanceAlert => '性能告警';

  @override
  String get performanceAvgFrameTime => '平均帧时间';

  @override
  String get performanceJankPercentage => '卡顿百分比';

  @override
  String get performanceFrameTimeVariance => '帧时间方差';

  @override
  String get performanceHealthExcellent => '优秀';

  @override
  String get performanceHealthGood => '良好';

  @override
  String get performanceHealthFair => '一般';

  @override
  String get performanceHealthPoor => '较差';

  @override
  String get performanceHealthWarmingUp => '预热';

  @override
  String get performanceHealthUnknown => '未知';

  @override
  String get ocrLanguageTitle => 'OCR 识别语言';

  @override
  String get ocrLanguageSubtitle => '选择用于识别的语言（可选自动）';

  @override
  String get ocrMinConfidenceTitle => '最小置信度阈值';

  @override
  String get ocrMinConfidenceSubtitle => '低于该阈值的识别结果将被忽略';

  @override
  String get updateAvailableTitle => '发现新版本';

  @override
  String get updateLatestVersionPrefix => '最新版本: ';

  @override
  String get updateReleaseNotesTitle => '更新内容:';

  @override
  String get updateLaterAction => '稍后更新';

  @override
  String get downloadNowAction => '立即下载';

  @override
  String get sectionStorage => '存储管理';

  @override
  String get storageAppDataTitle => '应用数据';

  @override
  String get storageAppDataSubtitle => '在Finder中显示应用数据目录';

  @override
  String get developerOptionsTitle => '开发者选项';

  @override
  String get storageCleanEmptyTitle => '清理空数据';

  @override
  String get storageCleanEmptySubtitle => '删除内容为空的剪贴板记录';

  @override
  String get storageValidateTitle => '验证数据完整性';

  @override
  String get storageValidateSubtitle => '检查并修复数据库中的问题';

  @override
  String get performanceOverlayTitle => '性能监控浮层';

  @override
  String get performanceOverlaySubtitle => '显示实时性能指标';

  @override
  String get developerModeActive => '开发者模式已激活';

  @override
  String get developerModeInactive => '开发者模式已关闭';

  @override
  String maxHistoryUnit(int count) {
    return '$count 条';
  }

  @override
  String get cleanEmptyDialogTitle => '确认清理空数据';

  @override
  String get cleanEmptyDialogContent => '此操作将永久删除所有内容为空的记录，且无法撤销。是否继续？';

  @override
  String cleanSuccessMessage(int count) {
    return '成功清理 $count 条空数据记录';
  }

  @override
  String cleanErrorMessage(String error) {
    return '清理失败: $error';
  }

  @override
  String get validateProgressText => '正在验证数据...';

  @override
  String get validateCompleteDialogTitle => '验证完成';

  @override
  String validateEmptyTextDeleted(int count) {
    return '已删除空文本记录: $count条';
  }

  @override
  String validateOrphanFilesDeleted(int count) {
    return '已删除孤立文件: $count个';
  }

  @override
  String validateTotalRemaining(int count) {
    return '剩余有效记录: $count条';
  }

  @override
  String validateErrorMessage(String error) {
    return '验证失败: $error';
  }

  @override
  String checkUpdateErrorMessage(String error) {
    return '检查更新失败: $error';
  }

  @override
  String get feedbackDialogTitle => '反馈与帮助';

  @override
  String get feedbackEmailTitle => '发送邮件';

  @override
  String get feedbackEmailAddress => 'jr.lu.jobs@gmail.com';

  @override
  String get feedbackIssueTitle => '提交问题';

  @override
  String get feedbackIssueSubtitle => '在 GitHub 上报告错误或提出建议';

  @override
  String feedbackErrorMessage(String error) {
    return '无法打开反馈渠道: $error';
  }

  @override
  String get feedbackEmailInDevelopment => '邮件功能正在开发中，请稍后重试。';

  @override
  String feedbackEmailErrorMessage(String error) {
    return '无法打开邮件客户端: $error';
  }

  @override
  String get feedbackIssueInDevelopment => '问题报告功能正在开发中，请稍后重试。';

  @override
  String feedbackIssueErrorMessage(String error) {
    return '无法打开链接: $error';
  }

  @override
  String get checkUpdateProgressText => '正在检查更新...';

  @override
  String get checkUpdateDialogTitle => '检查更新';

  @override
  String get checkUpdateDialogContent => '您已经是最新版本';
}
