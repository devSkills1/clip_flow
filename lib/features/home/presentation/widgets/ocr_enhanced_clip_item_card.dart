import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/models/ocr_enhanced_clip_item.dart';
import 'package:clip_flow_pro/core/services/analysis/ocr_copy_service.dart';
import 'package:clip_flow_pro/core/services/analysis/ocr_manager_service.dart';
import 'package:clip_flow_pro/core/services/analysis/ocr_ports.dart';
import 'package:clip_flow_pro/core/services/observability/logger/logger.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/modern_clip_item_card.dart';

/// OCR增强的剪贴项卡片
/// 在原有卡片基础上增加OCR功能按钮和文本预览
class OCREnhancedClipItemCard extends ConsumerWidget {
  final ClipItem item;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool showOCRPreview;
  final ValueChanged<bool>? onShowOCRPreviewChanged;

  const OCREnhancedClipItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onFavorite,
    this.showOCRPreview = false,
    this.onShowOCRPreviewChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取OCR状态
    final ocrStatus = ref.watch(ocrStatusProvider(item.id));

    // 获取OCR增强项
    final enhancedItem = ref.watch(ocrEnhancedItemProvider(item.id));

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 原始卡片内容
          ModernClipItemCard(
            item: item,
            onTap: onTap,
            onFavorite: onFavorite,
          ),

          // OCR操作区域
          if (item.type == ClipType.image) ...[
            const Divider(height: 1),
            _buildOCRActions(context, ref, ocrStatus, enhancedItem),
          ],

          // OCR文本预览
          if (showOCRPreview && enhancedItem?.hasOCR == true) ...[
            const Divider(height: 1),
            _buildOCRPreview(context, enhancedItem!),
          ],
        ],
      ),
    );
  }

  Widget _buildOCRActions(
    BuildContext context,
    WidgetRef ref,
    OCRProcessingStatus status,
    OCREnhancedClipItem? enhancedItem,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // OCR状态显示
          Row(
            children: [
              Icon(
                Icons.text_fields,
                size: 16,
                color: status == OCRProcessingStatus.completed
                    ? Colors.green
                    : status == OCRProcessingStatus.processing
                        ? Colors.orange
                        : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                _getOCRStatusText(status),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: status == OCRProcessingStatus.completed
                          ? Colors.green
                          : status == OCRProcessingStatus.processing
                              ? Colors.orange
                              : Colors.grey,
                    ),
              ),
              const Spacer(),
              // 预览切换按钮
              if (enhancedItem?.hasOCR == true)
                TextButton.icon(
                  onPressed: () {
                    onShowOCRPreviewChanged?.call(!showOCRPreview);
                  },
                  icon: Icon(
                    showOCRPreview ? Icons.visibility_off : Icons.visibility,
                    size: 16,
                  ),
                  label: Text(
                    showOCRPreview ? '隐藏文本' : '显示文本',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // OCR操作按钮
          if (status == OCRProcessingStatus.completed && enhancedItem != null)
            _buildOCRButtons(context, ref, enhancedItem)
          else if (status == OCRProcessingStatus.processing)
            _buildProcessingIndicator(context)
          else if (status == OCRProcessingStatus.pending)
            _buildPendingActions(context, ref)
          else if (status == OCRProcessingStatus.failed)
            _buildFailedActions(context, ref),
        ],
      ),
    );
  }

  Widget _buildOCRButtons(
    BuildContext context,
    WidgetRef ref,
    OCREnhancedClipItem enhancedItem,
  ) {
    return Row(
      children: [
        // 复制图片
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _copyImage(context, ref, enhancedItem),
            icon: const Icon(Icons.image, size: 16),
            label: const Text('复制图片'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 复制文本
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _copyOCRText(context, ref, enhancedItem),
            icon: const Icon(Icons.text_fields, size: 16),
            label: const Text('复制文本'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 复制两者（弹出菜单）
        PopupMenuButton<OCRCopyType>(
          icon: const Icon(Icons.more_vert, size: 16),
          tooltip: '更多选项',
          onSelected: (type) => _smartCopy(context, ref, enhancedItem, type),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: OCRCopyType.image,
              child: Row(
                children: [
                  Icon(Icons.image, size: 16),
                  SizedBox(width: 8),
                  Text('仅复制图片'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: OCRCopyType.text,
              child: Row(
                children: [
                  Icon(Icons.text_fields, size: 16),
                  SizedBox(width: 8),
                  Text('仅复制文本'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: OCRCopyType.both,
              child: Row(
                children: [
                  Icon(Icons.copy_all, size: 16),
                  SizedBox(width: 8),
                  Text('复制两者'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProcessingIndicator(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '正在识别文字...',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            // TODO: 取消OCR处理
          },
          child: const Text(
            '取消',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingActions(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Icon(Icons.pending, size: 16),
        const SizedBox(width: 8),
        const Text('等待文字识别'),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => _startOCR(context, ref),
          icon: const Icon(Icons.play_arrow, size: 16),
          label: const Text('开始识别'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildFailedActions(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Icon(
          Icons.error_outline,
          size: 16,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 8),
        Text(
          '文字识别失败',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () => _retryOCR(context, ref),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text(
            '重试',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildOCRPreview(BuildContext context, OCREnhancedClipItem enhancedItem) {
    final text = enhancedItem.ocrText ?? '';
    final confidence = enhancedItem.ocrConfidence;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.text_snippet_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '识别文本',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (confidence != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(confidence).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(confidence * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: _getConfidenceColor(confidence),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // 文本内容
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: SelectableText(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          // 操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _copyOCRText(context, null, enhancedItem),
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('复制文本'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: const Size(0, 32),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('文本已复制到剪贴板'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.check, size: 14),
                label: const Text('复制并关闭'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getOCRStatusText(OCRProcessingStatus status) {
    switch (status) {
      case OCRProcessingStatus.pending:
        return '等待识别';
      case OCRProcessingStatus.processing:
        return '正在识别';
      case OCRProcessingStatus.completed:
        return '识别完成';
      case OCRProcessingStatus.failed:
        return '识别失败';
      case OCRProcessingStatus.skipped:
        return '已跳过';
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.9) return Colors.green;
    if (confidence >= 0.7) return Colors.orange;
    return Colors.red;
  }

  void _copyImage(
    BuildContext context,
    WidgetRef ref,
    OCREnhancedClipItem enhancedItem,
  ) async {
    try {
      final copyService = ref.read(ocrCopyServiceProvider);
      await copyService.copyImage(enhancedItem);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('图片已复制到剪贴板'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on Exception catch (e) {
      Log.e('Failed to copy image', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('复制失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _copyOCRText(
    BuildContext context,
    WidgetRef? ref,
    OCREnhancedClipItem enhancedItem,
  ) async {
    try {
      final copyService = ref?.read(ocrCopyServiceProvider) ?? OCRCopyService();
      await copyService.copyOCRText(enhancedItem);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('文本已复制到剪贴板'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on Exception catch (e) {
      Log.e('Failed to copy OCR text', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('复制失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _smartCopy(
    BuildContext context,
    WidgetRef ref,
    OCREnhancedClipItem enhancedItem,
    OCRCopyType type,
  ) async {
    try {
      final copyService = ref.read(ocrCopyServiceProvider);
      await copyService.smartCopy(enhancedItem, type: type);

      if (context.mounted) {
        String message;
        switch (type) {
          case OCRCopyType.image:
            message = '图片已复制';
            break;
          case OCRCopyType.text:
            message = '文本已复制';
            break;
          case OCRCopyType.both:
            message = '将依次复制图片和文本';
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on Exception catch (e) {
      Log.e('Failed to smart copy', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('复制失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _startOCR(BuildContext context, WidgetRef ref) async {
    try {
      final ocrManager = ref.read(ocrManagerProvider);
      await ocrManager.initialize();

      // 创建OCR增强项
      final enhancedItem = OCREnhancedClipItem.fromClipItem(item);

      // 加入处理队列
      await ocrManager.enqueueForOCR(item, priority: OCRPriority.high);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已开始文字识别'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on Exception catch (e) {
      Log.e('Failed to start OCR', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('启动失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _retryOCR(BuildContext context, WidgetRef ref) {
    _startOCR(context, ref);
  }
}

// Provider定义

/// OCR状态Provider
final ocrStatusProvider = Provider.family<OCRProcessingStatus, String>(
  (ref, itemId) {
    // TODO(you): 从OCRManager获取实时状态
    return OCRProcessingStatus.pending;
  },
);

/// OCR增强项Provider
final ocrEnhancedItemProvider = Provider.family<OCREnhancedClipItem?, String>(
  (ref, itemId) {
    // TODO(you): 从OCRManager获取增强项
    return null;
  },
);

/// OCR复制服务Provider
final ocrCopyServiceProvider = Provider<OCRCopyService>(
  (ref) => OCRCopyService(),
);

/// OCR管理器Provider
final ocrManagerProvider = Provider<OCRManagerService>(
  (ref) => OCRManagerService(),
);