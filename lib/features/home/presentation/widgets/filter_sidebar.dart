import 'package:flutter/material.dart';

import '../../../../core/models/clip_item.dart';
import '../../../../shared/providers/app_providers.dart';

class FilterSidebar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // 标题
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '筛选',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // 类型筛选
          _buildTypeFilters(),
          
          const Divider(),
          
          // 显示模式
          _buildDisplayModeSelector(),
          
          const Spacer(),
          
          // 底部操作
          _buildBottomActions(context),
        ],
      ),
    );
  }

  Widget _buildTypeFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '类型',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.blue : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '显示模式',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
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
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onDisplayModeChanged(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.blue : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // 导航到设置页面
              },
              icon: const Icon(Icons.settings, size: 16),
              label: const Text('设置'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // 清空历史记录
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('确认清空'),
                    content: const Text('确定要清空所有剪贴板历史吗？此操作不可恢复。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          // 清空历史记录
                          Navigator.of(context).pop();
                        },
                        child: const Text('清空'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('清空历史'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
