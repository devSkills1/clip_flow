// ignore_for_file: public_member_api_docs
// 忽略公共成员API文档要求，因为这是内部设置页面，不需要对外暴露API文档
// Internal settings page that doesn't require public API documentation.
import 'dart:async';

import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/constants/i18n_fallbacks.dart';
import 'package:clip_flow_pro/core/constants/spacing.dart';
import 'package:clip_flow_pro/core/models/hotkey_config.dart';
import 'package:clip_flow_pro/core/services/operations/index.dart';
import 'package:clip_flow_pro/core/services/platform/index.dart';
import 'package:clip_flow_pro/core/services/storage/index.dart';
import 'package:clip_flow_pro/features/settings/presentation/widgets/hotkey_capture_dialog.dart';
import 'package:clip_flow_pro/features/settings/presentation/widgets/modern_radio_list_tile.dart';
import 'package:clip_flow_pro/l10n/gen/s.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// 应用设置页面
/// 提供应用的配置和偏好设置
class SettingsPage extends ConsumerStatefulWidget {
  /// 创建一个设置页面组件
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  S? get l10n => S.of(context);
  int _versionTapCount = 0;

  void _handleVersionTap() {
    setState(() {
      _versionTapCount++;
    });

    if (_versionTapCount >= 7) {
      // 激活开发者模式
      ref.read(userPreferencesProvider.notifier).toggleDeveloperMode();

      // 显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(userPreferencesProvider).isDeveloperMode
                ? l10n?.developerModeActive ??
                      I18nFallbacks.settings.developerModeActive
                : l10n?.developerModeInactive ??
                      I18nFallbacks.settings.developerModeInactive,
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // 重置计数
      _versionTapCount = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(userPreferencesProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context)?.settingsTitle ?? I18nFallbacks.settings.title,
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // 常规设置
          _buildSection(
            context,
            title:
                l10n?.sectionGeneral ?? I18nFallbacks.settings.sectionGeneral,
            children: [
              _buildSwitchTile(
                title:
                    l10n?.generalAutoStartTitle ??
                    I18nFallbacks.settings.generalAutoStartTitle,
                subtitle:
                    l10n?.generalAutoStartSubtitle ??
                    I18nFallbacks.settings.generalAutoStartSubtitle,
                value: preferences.autoStart,
                onChanged: (value) async {
                  await ref
                      .read(userPreferencesProvider.notifier)
                      .toggleAutoStart();
                },
              ),
              _buildSwitchTile(
                title:
                    l10n?.generalMinimizeToTrayTitle ??
                    I18nFallbacks.settings.generalMinimizeToTrayTitle,
                subtitle:
                    l10n?.generalMinimizeToTraySubtitle ??
                    I18nFallbacks.settings.generalMinimizeToTraySubtitle,
                value: preferences.minimizeToTray,
                onChanged: (value) {
                  ref
                      .read(userPreferencesProvider.notifier)
                      .toggleMinimizeToTray();
                },
              ),
              // 性能监控覆盖层开关（在所有构建类型中可用）
              _buildSwitchTile(
                title:
                    l10n?.performanceOverlayTitle ??
                    I18nFallbacks.settings.performanceOverlayTitle,
                subtitle:
                    l10n?.performanceOverlaySubtitle ??
                    I18nFallbacks.settings.performanceOverlaySubtitle,
                value: preferences.showPerformanceOverlay,
                onChanged: (value) {
                  ref
                      .read(userPreferencesProvider.notifier)
                      .togglePerformanceOverlay();
                },
              ),
              _buildListTile(
                title:
                    l10n?.generalGlobalHotkeyTitle ??
                    I18nFallbacks.settings.generalGlobalHotkeyTitle,
                subtitle:
                    l10n?.generalGlobalHotkeySubtitle(
                      preferences.globalHotkey,
                    ) ??
                    I18nFallbacks.settings.generalGlobalHotkeySubtitle(
                      preferences.globalHotkey,
                    ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showHotkeyDialog(context, ref);
                },
              ),
              _buildListTile(
                title:
                    l10n?.generalMaxHistoryTitle ??
                    I18nFallbacks.settings.generalMaxHistoryTitle,
                subtitle:
                    l10n?.generalMaxHistorySubtitle(
                      preferences.maxHistoryItems,
                    ) ??
                    I18nFallbacks.settings.generalMaxHistorySubtitle(
                      preferences.maxHistoryItems,
                    ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showMaxHistoryDialog(context, ref);
                },
              ),
              _buildRadioTile<UiMode>(
                title: '界面模式',
                subtitle: '选择应用的界面风格',
                value: preferences.uiMode,
                options: const [
                  (
                    value: UiMode.traditional,
                    title: '传统剪贴板',
                    subtitle: '经典的剪贴板历史管理界面',
                  ),
                  (
                    value: UiMode.appSwitcher,
                    title: '应用切换器',
                    subtitle: '类似 macOS Cmd+Tab 的切换界面',
                  ),
                ],
                onChanged: (UiMode value) {
                  ref.read(userPreferencesProvider.notifier).setUiMode(value);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 安全设置
          _buildSection(
            context,
            title:
                l10n?.sectionSecurity ?? I18nFallbacks.settings.sectionSecurity,
            children: [
              _buildSwitchTile(
                title:
                    l10n?.securityEnableEncryptionTitle ??
                    I18nFallbacks.settings.securityEnableEncryptionTitle,
                subtitle:
                    l10n?.securityEnableEncryptionSubtitle ??
                    I18nFallbacks.settings.securityEnableEncryptionSubtitle,
                value: preferences.enableEncryption,
                onChanged: (value) {
                  ref.read(userPreferencesProvider.notifier).toggleEncryption();
                },
              ),
              _buildSwitchTile(
                title:
                    l10n?.securityEnableOcrTitle ??
                    I18nFallbacks.settings.securityEnableOcrTitle,
                subtitle:
                    l10n?.securityEnableOcrSubtitle ??
                    I18nFallbacks.settings.securityEnableOcrSubtitle,
                value: preferences.enableOCR,
                onChanged: (value) {
                  ref.read(userPreferencesProvider.notifier).toggleOCR();
                },
              ),
              if (preferences.enableOCR) ...[
                const SizedBox(height: 8),
                // OCR 语言选择
                ListTile(
                  title: Text(
                    l10n?.ocrLanguageTitle ??
                        I18nFallbacks.settings.ocrLanguageTitle,
                  ),
                  subtitle: Text(
                    l10n?.ocrLanguageSubtitle ??
                        I18nFallbacks.settings.ocrLanguageSubtitle,
                  ),
                  trailing: DropdownButton<String>(
                    value: preferences.ocrLanguage,
                    items: OcrServiceFactory.getInstance()
                        .getSupportedLanguages()
                        .map(
                          (lang) {
                            return DropdownMenuItem(
                              value: lang,
                              child: Text(lang),
                            );
                          },
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(userPreferencesProvider.notifier)
                            .setOcrLanguage(value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // OCR 最小置信度滑块
                ListTile(
                  title: Text(
                    l10n?.ocrMinConfidenceTitle ??
                        I18nFallbacks.settings.ocrMinConfidenceTitle,
                  ),
                  subtitle: Text(
                    l10n?.ocrMinConfidenceSubtitle ??
                        I18nFallbacks.settings.ocrMinConfidenceSubtitle,
                  ),
                  trailing: SizedBox(
                    width: 220,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final percentage =
                                  (preferences.ocrMinConfidence * 100).round();
                              return Slider(
                                value: preferences.ocrMinConfidence,
                                divisions: 20,
                                label: '$percentage%',
                                onChanged: (v) {
                                  ref
                                      .read(userPreferencesProvider.notifier)
                                      .setOcrMinConfidence(v);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          // 外观设置
          _buildSection(
            context,
            title:
                l10n?.sectionAppearance ??
                I18nFallbacks.settings.sectionAppearance,
            children: [
              _buildListTile(
                title:
                    l10n?.appearanceThemeModeTitle ??
                    I18nFallbacks.settings.appearanceThemeModeTitle,
                subtitle: _getThemeModeText(context, themeMode),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showThemeDialog(context, ref);
                },
              ),
              _buildListTile(
                title:
                    l10n?.appearanceDefaultDisplayModeTitle ??
                    I18nFallbacks.settings.appearanceDefaultDisplayModeTitle,
                subtitle: _getDisplayModeText(
                  context,
                  preferences.defaultDisplayMode,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showDisplayModeDialog(context, ref);
                },
              ),
              _buildListTile(
                title:
                    l10n?.appearanceLanguageTitle ??
                    I18nFallbacks.settings.appearanceLanguageTitle,
                subtitle: _getLanguageText(context, preferences.language),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showLanguageDialog(context, ref);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 存储管理
          _buildSection(
            context,
            title:
                l10n?.sectionStorage ?? I18nFallbacks.settings.sectionStorage,
            children: [
              _buildListTile(
                title:
                    l10n?.storageAppDataTitle ??
                    I18nFallbacks.settings.storageAppDataTitle,
                subtitle:
                    l10n?.storageAppDataSubtitle ??
                    I18nFallbacks.settings.storageAppDataSubtitle,
                trailing: const Icon(Icons.folder_open),
                onTap: _showAppDocumentsInFinder,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 开发者选项（仅在开发者模式下显示）
          if (preferences.isDeveloperMode) ...[
            _buildSection(
              context,
              title:
                  l10n?.developerOptionsTitle ??
                  I18nFallbacks.settings.developerOptionsTitle,
              children: [
                _buildListTile(
                  title:
                      l10n?.storageCleanEmptyTitle ??
                      I18nFallbacks.settings.storageCleanEmptyTitle,
                  subtitle:
                      l10n?.storageCleanEmptySubtitle ??
                      I18nFallbacks.settings.storageCleanEmptySubtitle,
                  trailing: const Icon(Icons.cleaning_services),
                  onTap: _cleanEmptyData,
                ),
                _buildListTile(
                  title:
                      l10n?.storageValidateTitle ??
                      I18nFallbacks.settings.storageValidateTitle,
                  subtitle:
                      l10n?.storageValidateSubtitle ??
                      I18nFallbacks.settings.storageValidateSubtitle,
                  trailing: const Icon(Icons.verified),
                  onTap: _validateAndRepairData,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // 关于
          _buildSection(
            context,
            title: l10n?.sectionAbout ?? I18nFallbacks.settings.sectionAbout,
            children: [
              _buildListTile(
                title:
                    l10n?.aboutVersionTitle ??
                    I18nFallbacks.settings.aboutVersionTitle,
                subtitle:
                    l10n?.aboutVersionValue ??
                    I18nFallbacks.settings.aboutVersionValue,
                onTap: _handleVersionTap,
              ),
              _buildListTile(
                title:
                    l10n?.actionCheckUpdateTitle ??
                    I18nFallbacks.settings.actionCheckUpdateTitle,
                subtitle:
                    l10n?.actionCheckUpdateSubtitle ??
                    I18nFallbacks.settings.actionCheckUpdateSubtitle,
                trailing: const Icon(Icons.chevron_right),
                onTap: _checkForUpdates,
              ),
              _buildListTile(
                title:
                    l10n?.actionFeedbackTitle ??
                    I18nFallbacks.settings.actionFeedbackTitle,
                subtitle:
                    l10n?.actionFeedbackSubtitle ??
                    I18nFallbacks.settings.actionFeedbackSubtitle,
                trailing: const Icon(Icons.chevron_right),
                onTap: _openFeedback,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: value,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 16),
                  trailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getThemeModeText(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return l10n?.themeLight ?? I18nFallbacks.settings.themeLight;
      case ThemeMode.dark:
        return l10n?.themeDark ?? I18nFallbacks.settings.themeDark;
      case ThemeMode.system:
        return l10n?.themeSystem ?? I18nFallbacks.settings.themeSystem;
    }
  }

  String _getDisplayModeText(BuildContext context, DisplayMode mode) {
    switch (mode) {
      case DisplayMode.compact:
        return l10n?.displayCompact ?? I18nFallbacks.settings.displayCompact;
      case DisplayMode.normal:
        return l10n?.displayNormal ?? I18nFallbacks.settings.displayNormal;
      case DisplayMode.preview:
        return l10n?.displayPreview ?? I18nFallbacks.settings.displayPreview;
    }
  }

  String _getLanguageText(BuildContext context, String language) {
    switch (language) {
      case 'zh_CN':
        return l10n?.languageZhCN ?? I18nFallbacks.settings.languageZhCN;
      case 'en_US':
        return l10n?.languageEnUS ?? I18nFallbacks.settings.languageEnUS;
      default:
        return l10n?.languageZhCN ?? I18nFallbacks.settings.languageZhCN;
    }
  }

  void _showHotkeyDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => const HotkeyCaptureDialog(
        action: HotkeyAction.toggleWindow,
      ),
    );
  }

  void _showMaxHistoryDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          S.of(context)?.dialogMaxHistoryTitle ??
              I18nFallbacks.settings.dialogMaxHistoryTitle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              S.of(context)?.dialogMaxHistoryContent ??
                  I18nFallbacks.settings.dialogMaxHistoryContent,
            ),
            const SizedBox(height: ClipConstants.defaultPadding),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: ref
                        .read(userPreferencesProvider)
                        .maxHistoryItems,
                    decoration: InputDecoration(
                      labelText:
                          S.of(context)?.dialogMaxHistoryFieldLabel ??
                          I18nFallbacks.settings.dialogMaxHistoryFieldLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ClipConstants.cardBorderRadius,
                        ),
                      ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                    items: [100, 200, 500, 1000, 2000].map((value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(
                          S.of(context)?.maxHistoryUnit(value) ??
                              I18nFallbacks.settings.maxHistoryUnit(value),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(userPreferencesProvider.notifier)
                            .setMaxHistoryItems(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              S.of(context)?.actionOk ?? I18nFallbacks.common.actionOk,
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          S.of(context)?.dialogThemeTitle ??
              I18nFallbacks.settings.dialogThemeTitle,
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            final selectedTheme = ref.read(themeModeProvider);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ModernRadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: selectedTheme,
                  title: Text(
                    S.of(context)?.themeLight ??
                        I18nFallbacks.settings.themeLight,
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(themeModeProvider.notifier).state = value;
                      Navigator.of(context).pop();
                    }
                  },
                ),
                ModernRadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: selectedTheme,
                  title: Text(
                    S.of(context)?.themeDark ??
                        I18nFallbacks.settings.themeDark,
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(themeModeProvider.notifier).state = value;
                      Navigator.of(context).pop();
                    }
                  },
                ),
                ModernRadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: selectedTheme,
                  title: Text(
                    S.of(context)?.themeSystem ??
                        I18nFallbacks.settings.themeSystem,
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(themeModeProvider.notifier).state = value;
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showDisplayModeDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          S.of(context)?.dialogDisplayModeTitle ??
              I18nFallbacks.settings.dialogDisplayModeTitle,
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            var selectedMode = ref
                .read(userPreferencesProvider)
                .defaultDisplayMode;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ModernRadioListTile<DisplayMode>(
                  title: Text(
                    S.of(context)?.displayCompact ??
                        I18nFallbacks.settings.displayCompact,
                  ),
                  subtitle: Text(
                    S.of(context)?.displayCompactDesc ??
                        I18nFallbacks.settings.displayCompactDesc,
                  ),
                  value: DisplayMode.compact,
                  groupValue: selectedMode,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedMode = value;
                      });
                      ref
                          .read(userPreferencesProvider.notifier)
                          .setDefaultDisplayMode(value);
                      Navigator.of(context).pop();
                    }
                  },
                ),
                ModernRadioListTile<DisplayMode>(
                  title: Text(
                    S.of(context)?.displayNormal ??
                        I18nFallbacks.settings.displayNormal,
                  ),
                  subtitle: Text(
                    S.of(context)?.displayNormalDesc ??
                        I18nFallbacks.settings.displayNormalDesc,
                  ),
                  value: DisplayMode.normal,
                  groupValue: selectedMode,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedMode = value;
                      });
                      ref
                          .read(userPreferencesProvider.notifier)
                          .setDefaultDisplayMode(value);
                      Navigator.of(context).pop();
                    }
                  },
                ),
                ModernRadioListTile<DisplayMode>(
                  title: Text(
                    S.of(context)?.displayPreview ??
                        I18nFallbacks.settings.displayPreview,
                  ),
                  subtitle: Text(
                    S.of(context)?.displayPreviewDesc ??
                        I18nFallbacks.settings.displayPreviewDesc,
                  ),
                  value: DisplayMode.preview,
                  groupValue: selectedMode,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedMode = value;
                      });
                      ref
                          .read(userPreferencesProvider.notifier)
                          .setDefaultDisplayMode(value);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          S.of(context)?.dialogLanguageTitle ??
              I18nFallbacks.settings.dialogLanguageTitle,
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            var selectedLanguage = ref.read(userPreferencesProvider).language;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ModernRadioListTile<String>(
                  title: Text(
                    S.of(context)?.languageZhCN ??
                        I18nFallbacks.settings.languageZhCN,
                  ),
                  value: 'zh_CN',
                  groupValue: selectedLanguage,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedLanguage = value;
                      });
                      ref
                          .read(userPreferencesProvider.notifier)
                          .setLanguage(value);
                      Navigator.of(context).pop();
                    }
                  },
                ),
                ModernRadioListTile<String>(
                  title: Text(
                    S.of(context)?.languageEnUS ??
                        I18nFallbacks.settings.languageEnUS,
                  ),
                  value: 'en_US',
                  groupValue: selectedLanguage,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedLanguage = value;
                      });
                      ref
                          .read(userPreferencesProvider.notifier)
                          .setLanguage(value);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // 存储管理相关方法

  Future<void> _showAppDocumentsInFinder() async {
    try {
      final success = await FinderService.instance.showAppDocumentsInFinder();
      if (!success && mounted) {
        _showErrorSnackBar(I18nFallbacks.settings.storageErrorAppData);
      }
    } on Exception catch (e) {
      if (mounted) {
        _showErrorSnackBar(I18nFallbacks.settings.storageErrorOpenFinder('$e'));
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _cleanEmptyData() async {
    try {
      // 显示确认对话框
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            l10n?.cleanEmptyDialogTitle ??
                I18nFallbacks.settings.cleanEmptyDialogTitle,
          ),
          content: Text(
            l10n?.cleanEmptyDialogContent ??
                I18nFallbacks.settings.cleanEmptyDialogContent,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                S.of(context)?.actionCancel ??
                    I18nFallbacks.common.actionCancel,
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                S.of(context)?.actionOk ?? I18nFallbacks.common.actionOk,
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // 执行清理
      final count = await DatabaseService.instance.cleanEmptyTextItems();
      if (mounted) {
        _showSuccessSnackBar(
          l10n?.cleanSuccessMessage(count) ??
              I18nFallbacks.settings.cleanSuccessMessage(count),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          l10n?.cleanErrorMessage(e.toString()) ??
              I18nFallbacks.settings.cleanErrorMessage(e.toString()),
        );
      }
    }
  }

  Future<void> _validateAndRepairData() async {
    try {
      // 显示加载对话框（不等待它完成）
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text(
                  l10n?.validateProgressText ??
                      I18nFallbacks.settings.validateProgressText,
                ),
              ],
            ),
          ),
        ),
      );

      // 执行验证和修复
      final stats = await DatabaseService.instance.validateAndRepairData();

      if (mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框

        // 显示结果对话框
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              l10n?.validateCompleteDialogTitle ??
                  I18nFallbacks.settings.validateCompleteDialogTitle,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.validateEmptyTextDeleted(
                        stats['emptyTextItemsDeleted'] ?? 0,
                      ) ??
                      I18nFallbacks.settings.validateEmptyTextDeleted(
                        stats['emptyTextItemsDeleted'] ?? 0,
                      ),
                ),
                Text(
                  l10n?.validateOrphanFilesDeleted(
                        stats['orphanFilesDeleted'] ?? 0,
                      ) ??
                      I18nFallbacks.settings.validateOrphanFilesDeleted(
                        stats['orphanFilesDeleted'] ?? 0,
                      ),
                ),
                Text(
                  l10n?.validateTotalRemaining(
                        stats['totalItemsRemaining'] ?? 0,
                      ) ??
                      I18nFallbacks.settings.validateTotalRemaining(
                        stats['totalItemsRemaining'] ?? 0,
                      ),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  S.of(context)?.actionOk ?? I18nFallbacks.common.actionOk,
                ),
              ),
            ],
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
        _showErrorSnackBar(
          l10n?.validateErrorMessage(e.toString()) ??
              I18nFallbacks.settings.validateErrorMessage(e.toString()),
        );
      }
    }
  }

  /// 检查应用更新
  Future<void> _checkForUpdates() async {
    try {
      // 显示检查中的对话框
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: Spacing.s16),
                Text(
                  l10n?.checkUpdateProgressText ??
                      I18nFallbacks.settings.checkUpdateProgressText,
                ),
              ],
            ),
          ),
        ),
      );

      // 使用真实的更新检查服务
      final updateService = UpdateService();
      final hasUpdate = await updateService.checkForUpdates();

      if (mounted) {
        Navigator.of(context).pop(); // 关闭检查中对话框

        if (hasUpdate) {
          // 有可用更新
          final latestVersion = updateService.latestVersion;
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                S.of(context)?.updateAvailableTitle ??
                    I18nFallbacks.settings.updateAvailableTitle,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      final prefix =
                          S.of(context)?.updateLatestVersionPrefix ??
                          I18nFallbacks.settings.updateLatestVersionPrefix;
                      return Text('$prefix${latestVersion?.version}');
                    },
                  ),
                  const SizedBox(height: Spacing.s8),
                  if (latestVersion?.releaseNotes.isNotEmpty ?? false) ...[
                    Text(
                      S.of(context)?.updateReleaseNotesTitle ??
                          I18nFallbacks.settings.updateReleaseNotesTitle,
                    ),
                    const SizedBox(height: Spacing.s4),
                    Text(
                      latestVersion!.releaseNotes,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    S.of(context)?.updateLaterAction ??
                        I18nFallbacks.settings.updateLaterAction,
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    updateService.openDownloadPage();
                  },
                  child: Text(
                    S.of(context)?.downloadNowAction ??
                        I18nFallbacks.settings.downloadNowAction,
                  ),
                ),
              ],
            ),
          );
        } else {
          // 已是最新版本
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                l10n?.checkUpdateDialogTitle ??
                    I18nFallbacks.settings.checkUpdateDialogTitle,
              ),
              content: Text(
                l10n?.checkUpdateDialogContent ??
                    I18nFallbacks.settings.checkUpdateDialogContent,
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    S.of(context)?.actionOk ?? I18nFallbacks.common.actionOk,
                  ),
                ),
              ],
            ),
          );
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭检查中对话框
        _showErrorSnackBar(
          l10n?.checkUpdateErrorMessage(e.toString()) ??
              I18nFallbacks.settings.checkUpdateErrorMessage(e.toString()),
        );
      }
    }
  }

  /// 打开反馈页面
  Future<void> _openFeedback() async {
    try {
      // 显示反馈选项对话框
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            l10n?.feedbackDialogTitle ??
                I18nFallbacks.settings.feedbackDialogTitle,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(
                  l10n?.feedbackEmailTitle ??
                      I18nFallbacks.settings.feedbackEmailTitle,
                ),
                subtitle: Text(
                  l10n?.feedbackEmailAddress ?? ClipConstants.feedbackEmail,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _openEmailFeedback();
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report),
                title: Text(
                  l10n?.feedbackIssueTitle ??
                      I18nFallbacks.settings.feedbackIssueTitle,
                ),
                subtitle: Text(
                  l10n?.feedbackIssueSubtitle ??
                      I18nFallbacks.settings.feedbackIssueSubtitle,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _openIssuePage();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                S.of(context)?.actionCancel ??
                    I18nFallbacks.common.actionCancel,
              ),
            ),
          ],
        ),
      );
    } on Exception catch (e) {
      _showErrorSnackBar(
        l10n?.feedbackErrorMessage(e.toString()) ??
            I18nFallbacks.settings.feedbackErrorMessage(e.toString()),
      );
    }
  }

  /// 打开邮件反馈
  Future<void> _openEmailFeedback() async {
    try {
      final subject = Uri.encodeComponent(
        I18nFallbacks.settings.feedbackEmailSubject,
      );
      final body = Uri.encodeComponent(
        I18nFallbacks.settings.feedbackEmailBody,
      );
      final emailUri = Uri(
        scheme: 'mailto',
        path: ClipConstants.feedbackEmail,
        query: 'subject=$subject&body=$body',
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showErrorSnackBar(
          l10n?.feedbackEmailErrorMessage('Unable to launch email client') ??
              I18nFallbacks.settings.feedbackEmailErrorMessage(
                'Unable to launch email client',
              ),
        );
      }
    } on Exception catch (e) {
      _showErrorSnackBar(
        l10n?.feedbackEmailErrorMessage(e.toString()) ??
            I18nFallbacks.settings.feedbackEmailErrorMessage(e.toString()),
      );
    }
  }

  /// 打开问题报告页面
  Future<void> _openIssuePage() async {
    try {
      final issueUri = Uri.parse(
        '${ClipConstants.githubRepositoryUrl}/issues/new',
      );

      if (await canLaunchUrl(issueUri)) {
        await launchUrl(issueUri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar(
          l10n?.feedbackIssueErrorMessage(
                'Unable to open GitHub issues page',
              ) ??
              I18nFallbacks.settings.feedbackIssueErrorMessage(
                'Unable to open GitHub issues page',
              ),
        );
      }
    } on Exception catch (e) {
      _showErrorSnackBar(
        l10n?.feedbackIssueErrorMessage(e.toString()) ??
            I18nFallbacks.settings.feedbackIssueErrorMessage(e.toString()),
      );
    }
  }
}
