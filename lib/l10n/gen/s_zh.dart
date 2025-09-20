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
  String get generalMinimizeToTrayTitle => '最小化到系统托盘';

  @override
  String get generalMinimizeToTraySubtitle => '关闭窗口时最小化到系统托盘';

  @override
  String get generalGlobalHotkeyTitle => '全局快捷键';

  @override
  String generalGlobalHotkeySubtitle(String hotkey) {
    return '当前快捷键：$hotkey';
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
  String get aboutVersionTitle => '版本';

  @override
  String get aboutVersionValue => '1.0.0';

  @override
  String get homeEmptyTitle => '暂无剪贴板历史';

  @override
  String get homeEmptySubtitle => '复制一些内容开始使用吧';

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
  String get filterConfirmClearTitle => '确认清空';

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
  String get clipTypeColor => '颜色';

  @override
  String get clipTypeFile => '文件';

  @override
  String get clipTypeAudio => '音频';

  @override
  String get clipTypeVideo => '视频';
}
