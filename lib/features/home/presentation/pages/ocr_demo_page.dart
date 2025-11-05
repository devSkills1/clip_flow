import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/analysis/ocr_copy_service.dart';
import 'package:clip_flow_pro/features/home/presentation/widgets/responsive_home_layout.dart';
import 'package:clip_flow_pro/shared/providers/app_providers.dart';

/// OCR功能演示组件
///
/// 展示如何使用分离式OCR点击功能：
/// - 点击图片复制图片到剪贴板
/// - 点击OCR文本复制识别的文本到剪贴板
class OCRDemoPage extends ConsumerWidget {
  const OCRDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 模拟一些包含OCR文本的图片数据
    final sampleItems = [
      ClipItem(
        id: 'sample_image_1',
        type: ClipType.image,
        filePath: 'assets/sample1.jpg',
        ocrText: '这是一段从图片中识别的文本内容\n可以包含多行文字\n支持中英文混合',
        isOcrExtracted: true,
        metadata: {
          'ocrConfidence': 0.95,
          'width': 800,
          'height': 600,
        },
      ),
      ClipItem(
        id: 'sample_image_2',
        type: ClipType.image,
        filePath: 'assets/sample2.jpg',
        ocrText: 'Hello World!\nThis is English text from OCR',
        isOcrExtracted: true,
        metadata: {
          'ocrConfidence': 0.92,
          'width': 600,
          'height': 400,
        },
      ),
    ];

    final preferences = ref.watch(userPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR功能演示'),
        actions: [
          // OCR功能开关
          Switch(
            value: preferences.enableOCR,
            onChanged: (value) {
              ref.read(userPreferencesProvider.notifier).setEnableOCR(value);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // 说明区域
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '分离式OCR点击演示',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('• 点击图片区域：复制图片到剪贴板'),
                const Text('• 点击OCR文本区域：复制识别的文本到剪贴板'),
                const Text('• 开启上方开关启用OCR功能'),
                const SizedBox(height: 8),
                Text(
                  'OCR状态: ${preferences.enableOCR ? "已启用" : "已禁用"}',
                  style: TextStyle(
                    color: preferences.enableOCR ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 剪贴项列表
          Expanded(
            child: ResponsiveHomeLayout(
              items: sampleItems,
              displayMode: DisplayMode.normal,
              searchQuery: null,
              onItemTap: (item) => _copyImage(context, ref, item),
              onItemDelete: (item) => _showMessage(context, '删除功能未实现'),
              onItemFavoriteToggle: (item) => _showMessage(context, '收藏功能未实现'),
              onOcrTextTap: (item) => _copyOcrText(context, ref, item),
              enableOcrCopy: preferences.enableOCR,
              emptyWidget: const Center(child: Text('没有数据')),
            ),
          ),
        ],
      ),
    );
  }

  /// 复制图片到剪贴板
  void _copyImage(BuildContext context, WidgetRef ref, ClipItem item) async {
    try {
      final copyService = OCRCopyService();
      await copyService.initialize();

      final success = await copyService.copyImageSilently(item);

      if (context.mounted) {
        _showMessage(
          context,
          success ? '图片已复制到剪贴板' : '图片复制失败',
          success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, '复制错误: ${e.toString()}', false);
      }
    }
  }

  /// 复制OCR文本到剪贴板
  void _copyOcrText(BuildContext context, WidgetRef ref, ClipItem item) async {
    try {
      final copyService = OCRCopyService();
      await copyService.initialize();

      final success = await copyService.copyOcrTextSilently(item);

      if (context.mounted) {
        _showMessage(
          context,
          success ? 'OCR文本已复制到剪贴板' : 'OCR文本复制失败',
          success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, '复制错误: ${e.toString()}', false);
      }
    }
  }

  /// 显示操作结果消息
  void _showMessage(BuildContext context, String message, [bool isSuccess = true]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}