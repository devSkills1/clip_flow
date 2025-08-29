import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/clip_constants.dart';
import '../../../../shared/providers/app_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(userPreferencesProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(ClipConstants.defaultPadding),
        children: [
          // 常规设置
          _buildSection(
            title: '常规',
            children: [
              _buildSwitchTile(
                title: '开机自启动',
                subtitle: '应用启动时自动运行',
                value: preferences.autoStart,
                onChanged: (value) {
                  ref.read(userPreferencesProvider.notifier).toggleAutoStart();
                },
              ),
              _buildSwitchTile(
                title: '最小化到系统托盘',
                subtitle: '关闭窗口时最小化到系统托盘',
                value: preferences.minimizeToTray,
                onChanged: (value) {
                  ref.read(userPreferencesProvider.notifier).toggleMinimizeToTray();
                },
              ),
              _buildListTile(
                title: '全局快捷键',
                subtitle: preferences.globalHotkey,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showHotkeyDialog(context, ref);
                },
              ),
              _buildListTile(
                title: '最大历史记录数',
                subtitle: '${preferences.maxHistoryItems} 条',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showMaxHistoryDialog(context, ref);
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 安全设置
          _buildSection(
            title: '安全',
            children: [
              _buildSwitchTile(
                title: '启用加密',
                subtitle: '使用AES-256加密存储敏感数据',
                value: preferences.enableEncryption,
                onChanged: (value) {
                  ref.read(userPreferencesProvider.notifier).toggleEncryption();
                },
              ),
              _buildSwitchTile(
                title: '启用OCR',
                subtitle: '自动识别图片中的文字',
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
            title: '外观',
            children: [
              _buildListTile(
                title: '主题模式',
                subtitle: _getThemeModeText(themeMode),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showThemeDialog(context, ref);
                },
              ),
              _buildListTile(
                title: '默认显示模式',
                subtitle: _getDisplayModeText(preferences.defaultDisplayMode),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showDisplayModeDialog(context, ref);
                },
              ),
              _buildListTile(
                title: '语言',
                subtitle: _getLanguageText(preferences.language),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showLanguageDialog(context, ref);
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 关于
          _buildSection(
            title: '关于',
            children: [
              _buildListTile(
                title: '版本',
                subtitle: '1.0.0',
                trailing: null,
                onTap: null,
              ),
              _buildListTile(
                title: '检查更新',
                subtitle: '检查最新版本',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // 检查更新逻辑
                },
              ),
              _buildListTile(
                title: '反馈问题',
                subtitle: '报告Bug或建议',
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

  Widget _buildSection({
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
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

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  String _getDisplayModeText(DisplayMode mode) {
    switch (mode) {
      case DisplayMode.compact:
        return '紧凑';
      case DisplayMode.normal:
        return '默认';
      case DisplayMode.preview:
        return '预览';
    }
  }

  String _getLanguageText(String language) {
    switch (language) {
      case 'zh_CN':
        return '简体中文';
      case 'en_US':
        return 'English';
      default:
        return '简体中文';
    }
  }

  void _showHotkeyDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置全局快捷键'),
        content: const Text('请按下您想要设置的快捷键组合'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 设置快捷键逻辑
              Navigator.of(context).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showMaxHistoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置最大历史记录数'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择最大保存的剪贴板历史记录数量'),
            const SizedBox(height: ClipConstants.defaultPadding),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: ref.read(userPreferencesProvider).maxHistoryItems,
                    items: [100, 200, 500, 1000, 2000].map((value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text('$value 条'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(userPreferencesProvider.notifier)
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题模式'),
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
                title: const Text('浅色'),
                value: ThemeMode.light,
              ),
              RadioListTile<ThemeMode>(
                title: const Text('深色'),
                value: ThemeMode.dark,
              ),
              RadioListTile<ThemeMode>(
                title: const Text('跟随系统'),
                value: ThemeMode.system,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDisplayModeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择默认显示模式'),
        content: RadioGroup<DisplayMode>(
          groupValue: ref.read(userPreferencesProvider).defaultDisplayMode,
          onChanged: (value) {
            ref.read(userPreferencesProvider.notifier)
                .setDefaultDisplayMode(value!);
            Navigator.of(context).pop();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('紧凑'),
                subtitle: const Text('列表形式，显示更多项目'),
                leading: Radio<DisplayMode>(
                  value: DisplayMode.compact,
                ),
                onTap: () {
                  ref.read(userPreferencesProvider.notifier)
                      .setDefaultDisplayMode(DisplayMode.compact);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('默认'),
                subtitle: const Text('网格形式，平衡显示效果'),
                leading: Radio<DisplayMode>(
                  value: DisplayMode.normal,
                ),
                onTap: () {
                  ref.read(userPreferencesProvider.notifier)
                      .setDefaultDisplayMode(DisplayMode.normal);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('预览'),
                subtitle: const Text('大卡片形式，突出内容预览'),
                leading: Radio<DisplayMode>(
                  value: DisplayMode.preview,
                ),
                onTap: () {
                  ref.read(userPreferencesProvider.notifier)
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择语言'),
        content: RadioGroup<String>(
          groupValue: ref.read(userPreferencesProvider).language,
          onChanged: (value) {
            ref.read(userPreferencesProvider.notifier)
                .setLanguage(value!);
            Navigator.of(context).pop();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('简体中文'),
                leading: Radio<String>(
                  value: 'zh_CN',
                ),
                onTap: () {
                  ref.read(userPreferencesProvider.notifier)
                      .setLanguage('zh_CN');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('English'),
                leading: Radio<String>(
                  value: 'en_US',
                ),
                onTap: () {
                  ref.read(userPreferencesProvider.notifier)
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
}
