// ignore_for_file: public_member_api_docs
// 忽略公共成员API文档要求，因为这是内部设置页面，不需要对外暴露API文档
import 'dart:async';

import 'package:clip_flow_pro/core/constants/clip_constants.dart';
import 'package:clip_flow_pro/core/constants/i18n_fallbacks.dart';
import 'package:clip_flow_pro/core/constants/spacing.dart';
import 'package:clip_flow_pro/core/services/database_service.dart';
import 'package:clip_flow_pro/core/services/finder_service.dart';
import 'package:clip_flow_pro/l10n/gen/s.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 应用设置页面
/// 提供应用的配置和偏好设置
class SettingsPage extends ConsumerStatefulWidget {
  /// 创建一个设置页面组件
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
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
                ? I18nFallbacks.settings.developerModeActive
                : I18nFallbacks.settings.developerModeInactive,
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
    final l10n = S.of(context);

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
        padding: const EdgeInsets.all(ClipConstants.defaultPadding),
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
                onChanged: (value) {
                  ref.read(userPreferencesProvider.notifier).toggleAutoStart();
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
            ],
          ),

          const SizedBox(height: Spacing.s24),

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
            title: I18nFallbacks.settings.sectionStorage,
            children: [
              _buildListTile(
                title: I18nFallbacks.settings.storageDataBaseTitle,
                subtitle: I18nFallbacks.settings.storageDataBaseSubtitle,
                trailing: const Icon(Icons.folder_open),
                onTap: _showDatabaseInFinder,
              ),
              _buildListTile(
                title: I18nFallbacks.settings.storageImageTitle,
                subtitle: I18nFallbacks.settings.storageImageSubtitle,
                trailing: const Icon(Icons.folder_open),
                onTap: _showImageDirectoryInFinder,
              ),
              _buildListTile(
                title: I18nFallbacks.settings.storageFileTitle,
                subtitle: I18nFallbacks.settings.storageFileSubtitle,
                trailing: const Icon(Icons.folder_open),
                onTap: _showFileDirectoryInFinder,
              ),
              _buildListTile(
                title: I18nFallbacks.settings.storageAppDataTitle,
                subtitle: I18nFallbacks.settings.storageAppDataSubtitle,
                trailing: const Icon(Icons.folder_open),
                onTap: _showAppDocumentsInFinder,
              ),
              _buildListTile(
                title: I18nFallbacks.settings.storageLogTitle,
                subtitle: I18nFallbacks.settings.storageLogSubtitle,
                trailing: const Icon(Icons.folder_open),
                onTap: _showLogDirectoryInFinder,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 开发者选项（仅在开发者模式下显示）
          if (preferences.isDeveloperMode) ...[
            _buildSection(
              context,
              title: I18nFallbacks.settings.developerOptionsTitle,
              children: [
                _buildSwitchTile(
                  title: I18nFallbacks.settings.performanceOverlayTitle,
                  subtitle: I18nFallbacks.settings.performanceOverlaySubtitle,
                  value: preferences.showPerformanceOverlay,
                  onChanged: (value) {
                    ref
                        .read(userPreferencesProvider.notifier)
                        .togglePerformanceOverlay();
                  },
                ),
                _buildListTile(
                  title: I18nFallbacks.settings.storageCleanEmptyTitle,
                  subtitle: I18nFallbacks.settings.storageCleanEmptySubtitle,
                  trailing: const Icon(Icons.cleaning_services),
                  onTap: _cleanEmptyData,
                ),
                _buildListTile(
                  title: I18nFallbacks.settings.storageValidateTitle,
                  subtitle: I18nFallbacks.settings.storageValidateSubtitle,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }

  String _getThemeModeText(BuildContext context, ThemeMode mode) {
    final l10n = S.of(context);
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
    final l10n = S.of(context);
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
    final l10n = S.of(context);
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
      builder: (context) => AlertDialog(
        title: Text(
          S.of(context)?.dialogHotkeyTitle ??
              I18nFallbacks.settings.dialogHotkeyTitle,
        ),
        content: Text(
          S.of(context)?.dialogHotkeyContent ??
              I18nFallbacks.settings.dialogHotkeyContent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              S.of(context)?.actionCancel ?? I18nFallbacks.common.actionCancel,
            ),
          ),
          FilledButton(
            onPressed: () {
              // 设置快捷键逻辑
              Navigator.of(context).pop();
            },
            child: Text(
              S.of(context)?.actionOk ?? I18nFallbacks.common.actionOk,
            ),
          ),
        ],
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
            return RadioGroup<ThemeMode>(
              groupValue: selectedTheme,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).state = value!;
                Navigator.of(context).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<ThemeMode>(
                    title: Text(
                      S.of(context)?.themeLight ??
                          I18nFallbacks.settings.themeLight,
                    ),
                    value: ThemeMode.light,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text(
                      S.of(context)?.themeDark ??
                          I18nFallbacks.settings.themeDark,
                    ),
                    value: ThemeMode.dark,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text(
                      S.of(context)?.themeSystem ??
                          I18nFallbacks.settings.themeSystem,
                    ),
                    value: ThemeMode.system,
                  ),
                ],
              ),
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
            return RadioGroup<DisplayMode>(
              groupValue: selectedMode,
              onChanged: (value) {
                setState(() {
                  selectedMode = value!;
                });
                ref
                    .read(userPreferencesProvider.notifier)
                    .setDefaultDisplayMode(value!);
                Navigator.of(context).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<DisplayMode>(
                    title: Text(
                      S.of(context)?.displayCompact ??
                          I18nFallbacks.settings.displayCompact,
                    ),
                    subtitle: Text(
                      S.of(context)?.displayCompactDesc ??
                          I18nFallbacks.settings.displayCompactDesc,
                    ),
                    value: DisplayMode.compact,
                  ),
                  RadioListTile<DisplayMode>(
                    title: Text(
                      S.of(context)?.displayNormal ??
                          I18nFallbacks.settings.displayNormal,
                    ),
                    subtitle: Text(
                      S.of(context)?.displayNormalDesc ??
                          I18nFallbacks.settings.displayNormalDesc,
                    ),
                    value: DisplayMode.normal,
                  ),
                  RadioListTile<DisplayMode>(
                    title: Text(
                      S.of(context)?.displayPreview ??
                          I18nFallbacks.settings.displayPreview,
                    ),
                    subtitle: Text(
                      S.of(context)?.displayPreviewDesc ??
                          I18nFallbacks.settings.displayPreviewDesc,
                    ),
                    value: DisplayMode.preview,
                  ),
                ],
              ),
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
            return RadioGroup<String>(
              groupValue: selectedLanguage,
              onChanged: (value) {
                setState(() {
                  selectedLanguage = value!;
                });
                ref.read(userPreferencesProvider.notifier).setLanguage(value!);
                Navigator.of(context).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text(
                      S.of(context)?.languageZhCN ??
                          I18nFallbacks.settings.languageZhCN,
                    ),
                    value: 'zh_CN',
                  ),
                  RadioListTile<String>(
                    title: Text(
                      S.of(context)?.languageEnUS ??
                          I18nFallbacks.settings.languageEnUS,
                    ),
                    value: 'en_US',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // 存储管理相关方法
  Future<void> _showDatabaseInFinder() async {
    try {
      final success = await FinderService.instance.showDatabaseInFinder();
      if (!success && mounted) {
        _showErrorSnackBar(I18nFallbacks.settings.storageErrorDatabase);
      }
    } on Exception catch (e) {
      if (mounted) {
        _showErrorSnackBar(I18nFallbacks.settings.storageErrorOpenFinder('$e'));
      }
    }
  }

  Future<void> _showImageDirectoryInFinder() async {
    try {
      final success = await FinderService.instance.showImageDirectoryInFinder();
      if (!success && mounted) {
        _showErrorSnackBar(I18nFallbacks.settings.storageErrorImage);
      }
    } on Exception catch (e) {
      if (mounted) {
        _showErrorSnackBar(I18nFallbacks.settings.storageErrorOpenFinder('$e'));
      }
    }
  }

  Future<void> _showFileDirectoryInFinder() async {
    try {
      final success = await FinderService.instance.showFileDirectoryInFinder();
      if (!success && mounted) {
        _showErrorSnackBar(I18nFallbacks.settings.storageErrorFile);
      }
    } on Exception catch (e) {
      if (mounted) {
        _showErrorSnackBar(I18nFallbacks.settings.storageErrorOpenFinder('$e'));
      }
    }
  }

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

  Future<void> _showLogDirectoryInFinder() async {
    try {
      final success = await FinderService.instance.showLogDirectoryInFinder();
      if (!success && mounted) {
        _showErrorSnackBar(I18nFallbacks.settings.storageErrorLog);
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
          title: Text(I18nFallbacks.settings.cleanEmptyDialogTitle),
          content: Text(I18nFallbacks.settings.cleanEmptyDialogContent),
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
        _showSuccessSnackBar(I18nFallbacks.settings.cleanSuccessMessage(count));
      }
    } on Exception catch (e) {
      if (mounted) {
        _showErrorSnackBar(
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
                Text(I18nFallbacks.settings.validateProgressText),
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
            title: Text(I18nFallbacks.settings.validateCompleteDialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  I18nFallbacks.settings.validateEmptyTextDeleted(
                    stats['emptyTextItemsDeleted'] ?? 0,
                  ),
                ),
                Text(
                  I18nFallbacks.settings.validateOrphanFilesDeleted(
                    stats['orphanFilesDeleted'] ?? 0,
                  ),
                ),
                Text(
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
                  I18nFallbacks.settings.checkUpdateProgressText,
                ),
              ],
            ),
          ),
        ),
      );

      // 模拟检查更新（实际项目中应该调用真实的更新检查API）
      await Future<void>.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop(); // 关闭检查中对话框

        // 显示结果对话框
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(I18nFallbacks.settings.checkUpdateDialogTitle),
            content: Text(I18nFallbacks.settings.checkUpdateDialogContent),
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
        Navigator.of(context).pop(); // 关闭检查中对话框
        _showErrorSnackBar(
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
          title: Text(I18nFallbacks.settings.feedbackDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(I18nFallbacks.settings.feedbackEmailTitle),
                subtitle: const Text('feedback@clipflowpro.com'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openEmailFeedback();
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report),
                title: Text(I18nFallbacks.settings.feedbackIssueTitle),
                subtitle: Text(I18nFallbacks.settings.feedbackIssueSubtitle),
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
        I18nFallbacks.settings.feedbackErrorMessage(e.toString()),
      );
    }
  }

  /// 打开邮件反馈
  Future<void> _openEmailFeedback() async {
    try {
      // 这里应该使用url_launcher打开邮件客户端
      // 暂时显示一个提示
      _showInfoSnackBar(I18nFallbacks.settings.feedbackEmailInDevelopment);
    } on Exception catch (e) {
      _showErrorSnackBar(
        I18nFallbacks.settings.feedbackEmailErrorMessage(e.toString()),
      );
    }
  }

  /// 打开问题报告页面
  Future<void> _openIssuePage() async {
    try {
      // 这里应该使用url_launcher打开GitHub Issues页面
      // 暂时显示一个提示
      _showInfoSnackBar(I18nFallbacks.settings.feedbackIssueInDevelopment);
    } on Exception catch (e) {
      _showErrorSnackBar(
        I18nFallbacks.settings.feedbackIssueErrorMessage(e.toString()),
      );
    }
  }

  /// 显示信息提示
  void _showInfoSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }
}
