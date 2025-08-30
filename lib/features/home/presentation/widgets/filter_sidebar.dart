import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/clip_item.dart';
import '../../../../core/constants/clip_constants.dart';
import '../../../../shared/providers/app_providers.dart';

class FilterSidebar extends ConsumerWidget {
  final ClipType? selectedType;
  final ValueChanged<ClipType?> onTypeSelected;
  final ValueChanged<DisplayMode> onDisplayModeChanged;
  final DisplayMode displayMode;

  const FilterSidebar({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
    required this.onDisplayModeChanged,
    required this.displayMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 标题
          Container(
            padding: const EdgeInsets.all(ClipConstants.defaultPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '筛选',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          
          // 可滚动的内容区域
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 类型筛选
                  _buildTypeFilters(context),
                  
                  const Divider(),
                  
                  // 显示模式
                  _buildDisplayModeSelector(context),
                ],
              ),
            ),
          ),
          
          // 底部操作
          _buildBottomActions(context, ref),
        ],
      ),
    );
  }

  Widget _buildTypeFilters(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ClipConstants.defaultPadding, vertical: ClipConstants.smallPadding),
          child: Text(
            '类型',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        _buildFilterItem(
          icon: Icons.text_fields,
          label: '全部',
          isSelected: selectedType == null,
          onTap: () => onTypeSelected(null),
        ),
        _buildFilterItem(
          icon: Icons.text_fields,
          label: '文本',
          isSelected: selectedType == ClipType.text,
          onTap: () => onTypeSelected(ClipType.text),
        ),
        _buildFilterItem(
          icon: Icons.description,
          label: '富文本',
          isSelected: selectedType == ClipType.rtf || selectedType == ClipType.html,
          onTap: () => onTypeSelected(ClipType.rtf),
        ),
        _buildFilterItem(
          icon: Icons.image,
          label: '图片',
          isSelected: selectedType == ClipType.image,
          onTap: () => onTypeSelected(ClipType.image),
        ),
        _buildFilterItem(
          icon: Icons.palette,
          label: '颜色',
          isSelected: selectedType == ClipType.color,
          onTap: () => onTypeSelected(ClipType.color),
        ),
        _buildFilterItem(
          icon: Icons.insert_drive_file,
          label: '文件',
          isSelected: selectedType == ClipType.file,
          onTap: () => onTypeSelected(ClipType.file),
        ),
        _buildFilterItem(
          icon: Icons.audiotrack,
          label: '音频',
          isSelected: selectedType == ClipType.audio,
          onTap: () => onTypeSelected(ClipType.audio),
        ),
        _buildFilterItem(
          icon: Icons.videocam,
          label: '视频',
          isSelected: selectedType == ClipType.video,
          onTap: () => onTypeSelected(ClipType.video),
        ),
      ],
    );
  }

  Widget _buildFilterItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected 
                  ? Border.all(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected 
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: ClipConstants.smallPadding),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.onSecondaryContainer
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayModeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ClipConstants.defaultPadding, vertical: ClipConstants.smallPadding),
          child: Text(
            '显示模式',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        _buildDisplayModeItem(
          icon: Icons.view_list,
          label: '紧凑',
          mode: DisplayMode.compact,
        ),
        _buildDisplayModeItem(
          icon: Icons.view_module,
          label: '默认',
          mode: DisplayMode.normal,
        ),
        _buildDisplayModeItem(
          icon: Icons.view_agenda,
          label: '预览',
          mode: DisplayMode.preview,
        ),
      ],
    );
  }

  Widget _buildDisplayModeItem({
    required IconData icon,
    required String label,
    required DisplayMode mode,
  }) {
    final isSelected = displayMode == mode;
    
    return Builder(
      builder: (context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onDisplayModeChanged(mode),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected 
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected 
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: ClipConstants.smallPadding),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                     fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                     color: isSelected 
                         ? Theme.of(context).colorScheme.onPrimaryContainer
                         : Theme.of(context).colorScheme.onSurface,
                   ),
                 ),
               ],
             ),
           ),
         ),
       ),
     );
  }

  Widget _buildBottomActions(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(ClipConstants.defaultPadding),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () {
                // 导航到设置页面
              },
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('设置'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: ClipConstants.smallPadding),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // 清空历史记录
                final historyNotifier = ref.read(clipboardHistoryProvider.notifier);
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('确认清空'),
                    content: const Text('确定要清空所有剪贴板历史吗？此操作不可恢复。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () {
                          // 清空历史记录
                          historyNotifier.clearHistory();
                          Navigator.of(dialogContext).pop();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(context).colorScheme.onError,
                        ),
                        child: const Text('清空'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('清空历史'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
