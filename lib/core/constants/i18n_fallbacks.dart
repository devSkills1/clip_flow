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
}

class _HomeFallback {
  /// 首页文案
  const _HomeFallback();

  /// 空状态标题
  final String emptyTitle = '暂无内容';

  /// 空状态副标题
  final String emptySubtitle = '复制一些内容开始使用吧';
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
