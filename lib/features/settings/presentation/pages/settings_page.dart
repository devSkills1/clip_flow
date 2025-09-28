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
                ? '开发者模式已激活'
                : '开发者模式已关闭',
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
              title: '开发者选项',
              children: [
                _buildSwitchTile(
                  title: '性能监控覆盖层',
                  subtitle: '显示实时性能指标覆盖层',
                  value: preferences.showPerformanceOverlay,
                  onChanged: (value) {
                    ref
                        .read(userPreferencesProvider.notifier)
                        .togglePerformanceOverlay();
                  },
                ),
                _buildListTile(
                  title: '清理空数据',
                  subtitle: '清理数据库中的空内容记录',
                  trailing: const Icon(Icons.cleaning_services),
                  onTap: _cleanEmptyData,
                ),
                _buildListTile(
                  title: '验证数据完整性',
                  subtitle: '检查并修复数据库完整性问题',
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
                onTap: () {
                  // 检查更新逻辑
                },
              ),
              _buildListTile(
                title:
                    l10n?.actionFeedbackTitle ??
                    I18nFallbacks.settings.actionFeedbackTitle,
                subtitle:
                    l10n?.actionFeedbackSubtitle ??
                    I18nFallbacks.settings.actionFeedbackSubtitle,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // 反馈逻辑
                },
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
                        child: Text('$value 条'),
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
        content: RadioGroup<ThemeMode>(
          groupValue: ref.read(themeModeProvider),
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
                  S.of(context)?.themeDark ?? I18nFallbacks.settings.themeDark,
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
        content: RadioGroup<DisplayMode>(
          groupValue: ref.read(userPreferencesProvider).defaultDisplayMode,
          onChanged: (value) {
            ref
                .read(userPreferencesProvider.notifier)
                .setDefaultDisplayMode(value!);
            Navigator.of(context).pop();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  S.of(context)?.displayCompact ??
                      I18nFallbacks.settings.displayCompact,
                ),
                subtitle: Text(
                  S.of(context)?.displayCompactDesc ??
                      I18nFallbacks.settings.displayCompactDesc,
                ),
                leading: const Radio<DisplayMode>(value: DisplayMode.compact),
                onTap: () {
                  ref
                      .read(userPreferencesProvider.notifier)
                      .setDefaultDisplayMode(DisplayMode.compact);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text(
                  S.of(context)?.displayNormal ??
                      I18nFallbacks.settings.displayNormal,
                ),
                subtitle: Text(
                  S.of(context)?.displayNormalDesc ??
                      I18nFallbacks.settings.displayNormalDesc,
                ),
                leading: const Radio<DisplayMode>(value: DisplayMode.normal),
                onTap: () {
                  ref
                      .read(userPreferencesProvider.notifier)
                      .setDefaultDisplayMode(DisplayMode.normal);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text(
                  S.of(context)?.displayPreview ??
                      I18nFallbacks.settings.displayPreview,
                ),
                subtitle: Text(
                  S.of(context)?.displayPreviewDesc ??
                      I18nFallbacks.settings.displayPreviewDesc,
                ),
                leading: const Radio<DisplayMode>(value: DisplayMode.preview),
                onTap: () {
                  ref
                      .read(userPreferencesProvider.notifier)
                      .setDefaultDisplayMode(DisplayMode.preview);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
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
        content: RadioGroup<String>(
          groupValue: ref.read(userPreferencesProvider).language,
          onChanged: (value) {
            ref.read(userPreferencesProvider.notifier).setLanguage(value!);
            Navigator.of(context).pop();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  S.of(context)?.languageZhCN ??
                      I18nFallbacks.settings.languageZhCN,
                ),
                leading: const Radio<String>(value: 'zh_CN'),
                onTap: () {
                  ref
                      .read(userPreferencesProvider.notifier)
                      .setLanguage('zh_CN');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text(
                  S.of(context)?.languageEnUS ??
                      I18nFallbacks.settings.languageEnUS,
                ),
                leading: const Radio<String>(value: 'en_US'),
                onTap: () {
                  ref
                      .read(userPreferencesProvider.notifier)
                      .setLanguage('en_US');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
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
          title: const Text('清理空数据'),
          content: const Text('确定要清理数据库中的空内容记录吗？此操作不可撤销。'),
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
        _showSuccessSnackBar('已清理 $count 条空数据记录');
      }
    } on Exception catch (e) {
      if (mounted) {
        _showErrorSnackBar('清理失败: $e');
      }
    }
  }

  Future<void> _validateAndRepairData() async {
    try {
      // 显示加载对话框
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在验证数据完整性...'),
            ],
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
            title: const Text('数据验证完成'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('清理空文本记录: ${stats['emptyTextItemsDeleted']} 条'),
                Text('清理孤儿文件: ${stats['orphanFilesDeleted']} 个'),
                Text('剩余记录总数: ${stats['totalItemsRemaining']} 条'),
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
        _showErrorSnackBar('验证失败: $e');
      }
    }
  }
}
