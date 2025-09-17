// Centralized UI fallback strings for i18n-safe usage across the app.
// Usage example:
//   final t = I18nFallbacks;
//   Text(S.of(context)?.settingsTitle ?? t.settings.title);

class I18nFallbacks {
  const I18nFallbacks._();

  static const settings = _SettingsFallback();
  static const common = _CommonFallback();
  static const home = _HomeFallback();
}

class _CommonFallback {
  const _CommonFallback();

  // Generic actions
  final String actionOk = '确定';
  final String actionCancel = '取消';
  final String actionDelete = '删除';

  // Generic labels
  final String unknown = '未知';

  // Common composed texts
  String snackCopiedPrefix(String label) => '已复制: $label';
  final String deleteTitle = '确认删除';
  final String deleteContentPrefix = '确定要删除这个剪贴板项目吗？\n';

  // Entity labels
  final String labelImage = '图片';
  final String labelFile = '文件';
  final String labelColor = '颜色';
}

class _HomeFallback {
  const _HomeFallback();

  final String emptyTitle = '暂无内容';
  final String emptySubtitle = '复制一些内容开始使用吧';
}

class _SettingsFallback {
  const _SettingsFallback();

  // AppBar
  final String title = '设置';

  // Sections
  final String sectionGeneral = '常规';
  final String sectionSecurity = '安全';
  final String sectionAppearance = '外观';
  final String sectionAbout = '关于';

  // General
  final String generalAutoStartTitle = '开机自启动';
  final String generalAutoStartSubtitle = '应用启动时自动运行';
  final String generalMinimizeToTrayTitle = '最小化到系统托盘';
  final String generalMinimizeToTraySubtitle = '关闭窗口时最小化到系统托盘';
  final String generalGlobalHotkeyTitle = '全局快捷键';
  String generalGlobalHotkeySubtitle(String hotkey) => hotkey;
  final String generalMaxHistoryTitle = '最大历史记录数';
  String generalMaxHistorySubtitle(int count) => '$count 条';

  // Security
  final String securityEnableEncryptionTitle = '启用加密';
  final String securityEnableEncryptionSubtitle = '使用AES-256加密存储敏感数据';
  final String securityEnableOcrTitle = '启用OCR';
  final String securityEnableOcrSubtitle = '自动识别图片中的文字';

  // Appearance
  final String appearanceThemeModeTitle = '主题模式';
  final String appearanceDefaultDisplayModeTitle = '默认显示模式';
  final String appearanceLanguageTitle = '语言';

  // Theme options
  final String themeLight = '浅色';
  final String themeDark = '深色';
  final String themeSystem = '跟随系统';

  // Display options
  final String displayCompact = '紧凑';
  final String displayNormal = '默认';
  final String displayPreview = '预览';

  // Language options
  final String languageZhCN = '简体中文';
  final String languageEnUS = 'English';

  // Dialogs & Actions
  final String dialogHotkeyTitle = '设置全局快捷键';
  final String dialogHotkeyContent = '请按下您想要设置的快捷键组合';

  final String dialogMaxHistoryTitle = '设置最大历史记录数';
  final String dialogMaxHistoryContent = '选择最大保存的剪贴板历史记录数量';
  final String dialogMaxHistoryFieldLabel = '历史记录数量';

  final String dialogThemeTitle = '选择主题模式';
  final String dialogDisplayModeTitle = '选择默认显示模式';
  final String dialogLanguageTitle = '选择语言';

  // About
  final String aboutVersionTitle = '版本';
  final String aboutVersionValue = '1.0.0';

  // Actions (Settings page specific)
  final String actionCheckUpdateTitle = '检查更新';
  final String actionCheckUpdateSubtitle = '检查最新版本';
  final String actionFeedbackTitle = '反馈问题';
  final String actionFeedbackSubtitle = '报告Bug或建议';

  // Display mode descriptions
  final String displayCompactDesc = '列表形式，显示更多项目';
  final String displayNormalDesc = '网格形式，平衡显示效果';
  final String displayPreviewDesc = '大卡片形式，突出内容预览';
}
