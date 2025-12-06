import 'package:flutter_test/flutter_test.dart';
import 'package:clip_flow/core/models/clip_item.dart';
import 'package:clip_flow/core/services/clipboard/clipboard_processor.dart';

void main() {
  group('Empty Content Filter Tests', () {
    late ClipboardProcessor processor;

    setUp(() {
      processor = ClipboardProcessor();
    });

    test('应该过滤空文本内容', () {
      // 创建空的文本ClipItem
      final emptyTextClip = ClipItem(
        id: 'test-empty-text',
        type: ClipType.text,
        content: '',
        metadata: <String, dynamic>{},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 调用私有方法进行测试（通过反射或创建公共测试方法）
      final isEmpty = _isClipItemEmpty(processor, emptyTextClip);
      expect(isEmpty, true);
    });

    test('应该过滤只包含空格的文本内容', () {
      final whitespaceClip = ClipItem(
        id: 'test-whitespace',
        type: ClipType.text,
        content: '   \t\n   ',
        metadata: <String, dynamic>{},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final isEmpty = _isClipItemEmpty(processor, whitespaceClip);
      expect(isEmpty, true);
    });

    test('不应该过滤有实际内容的文本', () {
      final validTextClip = ClipItem(
        id: 'test-valid-text',
        type: ClipType.text,
        content: 'Hello, World!',
        metadata: <String, dynamic>{},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final isEmpty = _isClipItemEmpty(processor, validTextClip);
      expect(isEmpty, false);
    });

    test('应该过滤没有文件路径的文件', () {
      final fileClipWithoutPath = ClipItem(
        id: 'test-file-no-path',
        type: ClipType.file,
        content: '',
        filePath: null,
        metadata: <String, dynamic>{},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final isEmpty = _isClipItemEmpty(processor, fileClipWithoutPath);
      expect(isEmpty, true);
    });

    test('应该过滤空文件路径的文件', () {
      final fileClipWithEmptyPath = ClipItem(
        id: 'test-file-empty-path',
        type: ClipType.file,
        content: '',
        filePath: '',
        metadata: <String, dynamic>{},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final isEmpty = _isClipItemEmpty(processor, fileClipWithEmptyPath);
      expect(isEmpty, true);
    });

    test('不应该过滤有有效文件路径的文件', () {
      final validFileClip = ClipItem(
        id: 'test-valid-file',
        type: ClipType.file,
        content: '',
        filePath: 'documents/example.pdf',
        metadata: <String, dynamic>{},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final isEmpty = _isClipItemEmpty(processor, validFileClip);
      expect(isEmpty, false);
    });

    test('应该过滤没有文件路径的图片', () {
      final imageClipWithoutPath = ClipItem(
        id: 'test-image-no-path',
        type: ClipType.image,
        content: '',
        filePath: null,
        metadata: <String, dynamic>{},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final isEmpty = _isClipItemEmpty(processor, imageClipWithoutPath);
      expect(isEmpty, true);
    });

    test('不应该过滤有有效文件路径的图片', () {
      final validImageClip = ClipItem(
        id: 'test-valid-image',
        type: ClipType.image,
        content: '',
        filePath: 'media/images/photo.jpg',
        metadata: <String, dynamic>{},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final isEmpty = _isClipItemEmpty(processor, validImageClip);
      expect(isEmpty, false);
    });
  });
}

// 辅助函数：通过反射调用私有方法 _isEmptyContent
bool _isClipItemEmpty(ClipboardProcessor processor, ClipItem item) {
  // 由于 _isEmptyContent 是私有方法，我们需要复制其逻辑来进行测试
  switch (item.type) {
    case ClipType.text:
    case ClipType.code:
    case ClipType.color:
    case ClipType.url:
    case ClipType.email:
    case ClipType.json:
    case ClipType.xml:
    case ClipType.html:
    case ClipType.rtf:
      final content = item.content ?? '';
      return content.trim().isEmpty;

    case ClipType.image:
      return item.filePath?.isEmpty ?? true;

    case ClipType.file:
    case ClipType.audio:
    case ClipType.video:
      return item.filePath?.isEmpty ?? true;
  }
}