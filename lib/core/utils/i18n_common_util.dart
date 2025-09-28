import 'package:clip_flow_pro/core/constants/i18n_fallbacks.dart';
import 'package:clip_flow_pro/l10n/gen/s.dart';
import 'package:flutter/material.dart';

/// 国际化文本工具类
/// 统一处理国际化文本获取，简化三目运算的使用
class I18nCommonUtil {
  /// 私有构造：禁止实例化
  const I18nCommonUtil._();

  /// 获取本地化文本，如果为空则使用兜底值
  static String getText(
    BuildContext context,
    String Function(S) getter,
    String fallback,
  ) {
    final l10n = S.of(context);
    return l10n != null ? getter(l10n) : fallback;
  }

  /// 获取带参数的本地化文本，如果为空则使用兜底值
  static String getTextWithArgs<T>(
    BuildContext context,
    String Function(S, T) getter,
    T args,
    String Function(T) fallbackGetter,
  ) {
    final l10n = S.of(context);
    return l10n != null ? getter(l10n, args) : fallbackGetter(args);
  }

  // ==================== 通用文本 ====================

  /// 获取操作类文本：确定
  static String getActionOk(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.actionOk,
      I18nFallbacks.common.actionOk,
    );
  }

  /// 获取操作类文本：取消
  static String getActionCancel(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.actionCancel,
      I18nFallbacks.common.actionCancel,
    );
  }

  /// 获取操作类文本：删除
  static String getActionDelete(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.actionDelete,
      I18nFallbacks.common.actionDelete,
    );
  }

  /// 获取气泡提示：复制成功前缀
  static String getSnackCopiedPrefix(BuildContext context, String text) {
    return getTextWithArgs(
      context,
      (l10n, text) => l10n.snackCopiedPrefix(text),
      text,
      (text) => I18nFallbacks.common.snackCopiedPrefix(text),
    );
  }

  /// 获取弹窗标题：确认删除
  static String getDeleteTitle(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.dialogDeleteTitle,
      I18nFallbacks.common.deleteTitle,
    );
  }

  /// 获取弹窗内容：确认删除提示
  static String getDeleteContent(BuildContext context, String text) {
    return getTextWithArgs(
      context,
      (l10n, text) => l10n.dialogDeleteContent(text),
      text,
      (text) => '${I18nFallbacks.common.deleteContentPrefix}$text',
    );
  }

  // ==================== 时间显示 ====================

  /// 获取时间显示：刚刚
  static String getTimeJustNow(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.timeJustNow,
      I18nFallbacks.common.timeJustNow,
    );
  }

  /// 获取时间显示：分钟前
  static String getTimeMinutesAgo(BuildContext context, int minutes) {
    return getTextWithArgs(
      context,
      (l10n, minutes) => l10n.timeMinutesAgo(minutes),
      minutes,
      (minutes) => I18nFallbacks.common.timeMinutesAgo(minutes),
    );
  }

  /// 获取时间显示：小时前
  static String getTimeHoursAgo(BuildContext context, int hours) {
    return getTextWithArgs(
      context,
      (l10n, hours) => l10n.timeHoursAgo(hours),
      hours,
      (hours) => I18nFallbacks.common.timeHoursAgo(hours),
    );
  }

  /// 获取时间显示：天前
  static String getTimeDaysAgo(BuildContext context, int days) {
    return getTextWithArgs(
      context,
      (l10n, days) => l10n.timeDaysAgo(days),
      days,
      (days) => I18nFallbacks.common.timeDaysAgo(days),
    );
  }

  // ==================== 剪贴板类型 ====================

  /// 获取剪贴板类型：文本
  static String getClipTypeText(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.clipTypeText,
      I18nFallbacks.common.clipTypeText,
    );
  }

  /// 获取剪贴板类型：富文本
  static String getClipTypeRichText(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.clipTypeRichText,
      I18nFallbacks.common.clipTypeRichText,
    );
  }

  /// 获取剪贴板类型：HTML
  static String getClipTypeHtml(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.clipTypeHtml,
      I18nFallbacks.common.clipTypeHtml,
    );
  }

  /// 获取剪贴板类型：图片
  static String getClipTypeImage(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.clipTypeImage,
      I18nFallbacks.common.clipTypeImage,
    );
  }

  /// 获取剪贴板类型：颜色
  static String getClipTypeColor(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.clipTypeColor,
      I18nFallbacks.common.clipTypeColor,
    );
  }

  /// 获取剪贴板类型：文件
  static String getClipTypeFile(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.clipTypeFile,
      I18nFallbacks.common.clipTypeFile,
    );
  }

  /// 获取剪贴板类型：音频
  static String getClipTypeAudio(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.clipTypeAudio,
      I18nFallbacks.common.clipTypeAudio,
    );
  }

  /// 获取剪贴板类型：视频
  static String getClipTypeVideo(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.clipTypeVideo,
      I18nFallbacks.common.clipTypeVideo,
    );
  }

  /// 获取剪贴板类型：URL
  static String getClipTypeUrl(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.clipTypeUrl,
      I18nFallbacks.common.clipTypeUrl,
    );
  }

  /// 获取剪贴板类型：邮箱
  static String getClipTypeEmail(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.clipTypeEmail,
      I18nFallbacks.common.clipTypeEmail,
    );
  }

  /// 获取剪贴板类型：JSON
  static String getClipTypeJson(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.clipTypeJson,
      I18nFallbacks.common.clipTypeJson,
    );
  }

  /// 获取剪贴板类型：XML
  static String getClipTypeXml(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.clipTypeXml,
      I18nFallbacks.common.clipTypeXml,
    );
  }

  /// 获取剪贴板类型：代码
  static String getClipTypeCode(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.clipTypeCode,
      I18nFallbacks.common.clipTypeCode,
    );
  }

  // ==================== 实体标签 ====================

  /// 获取实体标签：图片
  static String getLabelImage(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.previewImage(0, 0, ''),
      I18nFallbacks.common.labelImage,
    );
  }

  /// 获取实体标签：文件
  static String getLabelFile(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.previewFile(''),
      I18nFallbacks.common.labelFile,
    );
  }

  /// 获取实体标签：颜色
  static String getLabelColor(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.previewColor(''),
      I18nFallbacks.common.labelColor,
    );
  }

  /// 获取未知格式标签
  static String getUnknownFormat(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.unknownFormat,
      I18nFallbacks.common.unknown,
    );
  }

  // ==================== 设置页文本 ====================

  /// 获取设置页标题
  static String getSettingsTitle(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.settingsTitle,
      I18nFallbacks.settings.title,
    );
  }

  /// 获取对话框：设置全局快捷键标题
  static String getDialogHotkeyTitle(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.dialogHotkeyTitle,
      I18nFallbacks.settings.dialogHotkeyTitle,
    );
  }

  /// 获取对话框：设置全局快捷键内容
  static String getDialogHotkeyContent(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.dialogHotkeyContent,
      I18nFallbacks.settings.dialogHotkeyContent,
    );
  }

  /// 获取对话框：设置最大历史记录数标题
  static String getDialogMaxHistoryTitle(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.dialogMaxHistoryTitle,
      I18nFallbacks.settings.dialogMaxHistoryTitle,
    );
  }

  /// 获取对话框：设置最大历史记录数内容
  static String getDialogMaxHistoryContent(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.dialogMaxHistoryContent,
      I18nFallbacks.settings.dialogMaxHistoryContent,
    );
  }

  /// 获取对话框：设置最大历史记录数字段标签
  static String getDialogMaxHistoryFieldLabel(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.dialogMaxHistoryFieldLabel,
      I18nFallbacks.settings.dialogMaxHistoryFieldLabel,
    );
  }

  /// 获取对话框：选择主题模式标题
  static String getDialogThemeTitle(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.dialogThemeTitle,
      I18nFallbacks.settings.dialogThemeTitle,
    );
  }

  /// 获取主题：浅色
  static String getThemeLight(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.themeLight,
      I18nFallbacks.settings.themeLight,
    );
  }

  /// 获取主题：深色
  static String getThemeDark(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.themeDark,
      I18nFallbacks.settings.themeDark,
    );
  }

  /// 获取主题：跟随系统
  static String getThemeSystem(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.themeSystem,
      I18nFallbacks.settings.themeSystem,
    );
  }

  /// 获取对话框：选择默认显示模式标题
  static String getDialogDisplayModeTitle(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.dialogDisplayModeTitle,
      I18nFallbacks.settings.dialogDisplayModeTitle,
    );
  }

  /// 获取显示模式：紧凑
  static String getDisplayCompact(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.displayCompact,
      I18nFallbacks.settings.displayCompact,
    );
  }

  /// 获取显示模式：紧凑说明
  static String getDisplayCompactDesc(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.displayCompactDesc,
      I18nFallbacks.settings.displayCompactDesc,
    );
  }

  /// 获取显示模式：默认
  static String getDisplayNormal(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.displayNormal,
      I18nFallbacks.settings.displayNormal,
    );
  }

  /// 获取显示模式：默认说明
  static String getDisplayNormalDesc(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.displayNormalDesc,
      I18nFallbacks.settings.displayNormalDesc,
    );
  }

  /// 获取显示模式：预览
  static String getDisplayPreview(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.displayPreview,
      I18nFallbacks.settings.displayPreview,
    );
  }

  /// 获取显示模式：预览说明
  static String getDisplayPreviewDesc(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.displayPreviewDesc,
      I18nFallbacks.settings.displayPreviewDesc,
    );
  }

  /// 获取对话框：选择语言标题
  static String getDialogLanguageTitle(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.dialogLanguageTitle,
      I18nFallbacks.settings.dialogLanguageTitle,
    );
  }

  /// 获取语言：简体中文
  static String getLanguageZhCN(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.languageZhCN,
      I18nFallbacks.settings.languageZhCN,
    );
  }

  /// 获取语言：英语
  static String getLanguageEnUS(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.languageEnUS,
      I18nFallbacks.settings.languageEnUS,
    );
  }

  // ==================== 筛选侧边栏文本 ====================

  /// 获取筛选标题
  static String getFilterTitle(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.filterTitle,
      I18nFallbacks.filter.title,
    );
  }

  /// 获取筛选类型分组标题
  static String getFilterTypeSection(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.filterTypeSection,
      I18nFallbacks.filter.typeSection,
    );
  }

  /// 获取筛选类型：全部
  static String getFilterTypeAll(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.filterTypeAll,
      I18nFallbacks.filter.typeAll,
    );
  }

  /// 获取筛选类型：文本
  static String getFilterTypeText(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.filterTypeText,
      I18nFallbacks.filter.typeText,
    );
  }

  /// 获取筛选类型：富文本
  static String getFilterTypeRichText(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.filterTypeRichText,
      I18nFallbacks.filter.typeRichText,
    );
  }

  /// 获取筛选类型：RTF
  static String getFilterTypeRtf(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.filterTypeRichText, // fallback to rich text key
      I18nFallbacks.filter.typeRtf,
    );
  }

  /// 获取筛选类型：HTML
  static String getFilterTypeHtml(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.filterTypeRichText, // fallback to rich text key
      I18nFallbacks.filter.typeHtml,
    );
  }

  /// 获取筛选类型：图片
  static String getFilterTypeImage(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.filterTypeImage,
      I18nFallbacks.filter.typeImage,
    );
  }

  /// 获取筛选类型：颜色
  static String getFilterTypeColor(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.filterTypeColor,
      I18nFallbacks.filter.typeColor,
    );
  }

  /// 获取筛选类型：文件
  static String getFilterTypeFile(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.filterTypeFile,
      I18nFallbacks.filter.typeFile,
    );
  }

  /// 获取筛选类型：音频
  static String getFilterTypeAudio(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.filterTypeAudio,
      I18nFallbacks.filter.typeAudio,
    );
  }

  /// 获取筛选类型：视频
  static String getFilterTypeVideo(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.filterTypeVideo,
      I18nFallbacks.filter.typeVideo,
    );
  }

  /// 获取筛选显示模式分组标题
  static String getFilterDisplayModeSection(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.filterDisplayModeSection,
      I18nFallbacks.filter.displayModeSection,
    );
  }

  /// 获取筛选设置按钮
  static String getFilterSettingsButton(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.filterSettingsButton,
      I18nFallbacks.filter.settingsButton,
    );
  }

  /// 获取筛选确认清空标题
  static String getFilterConfirmClearTitle(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.filterConfirmClearTitle,
      I18nFallbacks.filter.confirmClearTitle,
    );
  }

  /// 获取筛选清空历史按钮
  static String getFilterClearHistoryButton(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.filterClearHistoryButton,
      I18nFallbacks.filter.clearHistoryButton,
    );
  }

  // ==================== 搜索相关 ====================

  /// 获取搜索提示
  static String getSearchHint(BuildContext context) {
    return getText(
      context,
      (l10n) => l10n.searchHint,
      I18nFallbacks.home.searchHint,
    );
  }
}
