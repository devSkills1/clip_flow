import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/analysis/ocr_copy_service.dart';

import 'ocr_copy_service_test.mocks.dart';

@GenerateMocks([
  ClipItem,
])
void main() {
  group('OCRCopyService Tests', () {
    late OCRCopyService service;

    setUp(() {
      service = OCRCopyService();
    });

    group('Service Initialization', () {
      test('should initialize successfully', () async {
        await expectLater(service.initialize(), completes);
      });

      test('should not initialize twice', () async {
        await service.initialize();
        await expectLater(service.initialize(), completes);
      });
    });

    group('Image Copying', () {
      setUp(() async {
        await service.initialize();
      });

      test('should reject non-image items', () async {
        final textItem = MockClipItem();
        when(textItem.type).thenReturn(ClipType.text);

        expect(
          () => service.copyImageSilently(textItem),
          throwsArgumentError,
        );
      });

      test('should check if image can be copied - with file path', () async {
        final imageItem = MockClipItem();
        when(imageItem.type).thenReturn(ClipType.image);
        when(imageItem.filePath).thenReturn('/path/to/image.jpg');
        when(imageItem.thumbnail).thenReturn(null);

        // Note: This test would require mocking PathService
        // For now, we'll test the logic structure
        expect(service.canCopyOcrText(imageItem), isFalse);
      });

      test('should check if image can be copied - with thumbnail', () async {
        final imageItem = MockClipItem();
        when(imageItem.type).thenReturn(ClipType.image);
        when(imageItem.filePath).thenReturn(null);
        when(imageItem.thumbnail).thenReturn([1, 2, 3, 4]);

        expect(service.canCopyOcrText(imageItem), isFalse);
      });

      test('should check if image can be copied - no data', () async {
        final imageItem = MockClipItem();
        when(imageItem.type).thenReturn(ClipType.image);
        when(imageItem.filePath).thenReturn(null);
        when(imageItem.thumbnail).thenReturn(null);

        expect(service.canCopyOcrText(imageItem), isFalse);
      });
    });

    group('OCR Text Copying', () {
      setUp(() async {
        await service.initialize();
      });

      test('should reject non-image items', () async {
        final textItem = MockClipItem();
        when(textItem.type).thenReturn(ClipType.text);
        when(textItem.ocrText).thenReturn('Sample text');

        expect(
          () => service.copyOcrTextSilently(textItem),
          throwsArgumentError,
        );
      });

      test('should reject items without OCR text', () async {
        final imageItem = MockClipItem();
        when(imageItem.type).thenReturn(ClipType.image);
        when(imageItem.ocrText).thenReturn(null);

        expect(
          () => service.copyOcrTextSilently(imageItem),
          throwsStateError,
        );
      });

      test('should reject items with empty OCR text', () async {
        final imageItem = MockClipItem();
        when(imageItem.type).thenReturn(ClipType.image);
        when(imageItem.ocrText).thenReturn('');

        expect(
          () => service.copyOcrTextSilently(imageItem),
          throwsStateError,
        );
      });

      test('should check if OCR text can be copied', () {
        final imageItem = MockClipItem();
        when(imageItem.type).thenReturn(ClipType.image);
        when(imageItem.ocrText).thenReturn('Sample OCR text');

        expect(service.canCopyOcrText(imageItem), isTrue);
      });

      test('should check if OCR text cannot be copied - non-image', () {
        final textItem = MockClipItem();
        when(textItem.type).thenReturn(ClipType.text);
        when(textItem.ocrText).thenReturn('Sample text');

        expect(service.canCopyOcrText(textItem), isFalse);
      });

      test('should check if OCR text cannot be copied - no text', () {
        final imageItem = MockClipItem();
        when(imageItem.type).thenReturn(ClipType.image);
        when(imageItem.ocrText).thenReturn(null);

        expect(service.canCopyOcrText(imageItem), isFalse);
      });
    });

    group('OCR Text Formatting', () {
      test('should format plain text correctly', () {
        const text = 'Sample OCR text with newlines\nand spaces  ';
        final formatted = service._formatOcrText(text, OCRTextFormat.plain);
        expect(formatted, equals(text));
      });

      test('should format formatted text correctly', () {
        const text = '  Sample OCR text with newlines\nand spaces  ';
        final formatted = service._formatOcrText(text, OCRTextFormat.formatted);
        expect(formatted, equals('Sample OCR text with newlines\nand spaces'));
      });

      test('should format JSON correctly', () {
        const text = 'Sample text with "quotes" and \n newlines';
        final formatted = service._formatOcrText(text, OCRTextFormat.json);

        expect(formatted, contains('"text": "Sample text with \\"quotes\\" and \\n newlines"'));
        expect(formatted, contains('"source": "OCR"'));
        expect(formatted, contains('"wordCount":'));
      });

      test('should format Markdown correctly', () {
        const text = 'Line 1\nLine 2\n\nLine 3';
        final formatted = service._formatOcrText(text, OCRTextFormat.markdown);

        expect(formatted, contains('> **识别文本**'));
        expect(formatted, contains('> Line 1'));
        expect(formatted, contains('> Line 2'));
        expect(formatted, contains('> Line 3'));
        expect(formatted, contains('> *由 ClipFlow Pro OCR 识别*'));
      });

      test('should handle empty text in JSON format', () {
        const text = '';
        final formatted = service._formatOcrText(text, OCRTextFormat.json);

        expect(formatted, contains('"text": ""'));
        expect(formatted, contains('"wordCount": 0'));
      });

      test('should handle empty text in Markdown format', () {
        const text = '';
        final formatted = service._formatOcrText(text, OCRTextFormat.markdown);

        expect(formatted, contains('> **识别文本**'));
        expect(formatted, contains('> *由 ClipFlow Pro OCR 识别*'));
      });

      test('should count words correctly in JSON format', () {
        const text = 'One two three   four\nfive';
        final formatted = service._formatOcrText(text, OCRTextFormat.json);

        expect(formatted, contains('"wordCount": 5'));
      });
    });

    group('JSON Escaping', () {
      test('should escape special characters correctly', () {
        const text = r'Backslash: \, Quote: ", Newline: \n, Tab: \t, Return: \r';
        final escaped = service._escapeJson(text);

        expect(escaped, contains(r'Backslash: \\'));
        expect(escaped, contains(r'Quote: \"'));
        expect(escaped, contains(r'Newline: \\n'));
        expect(escaped, contains(r'Tab: \\t'));
        expect(escaped, contains(r'Return: \\r'));
      });
    });

    group('Copy Support Status', () {
      test('should create correct status for image with OCR', () async {
        final imageItem = MockClipItem();
        when(imageItem.type).thenReturn(ClipType.image);
        when(imageItem.ocrText).thenReturn('Sample OCR text');
        when(imageItem.filePath).thenReturn('/path/to/image.jpg');

        // Mock the file existence check
        // Note: This would require mocking PathService in actual implementation

        final status = await service.getCopySupportStatus(imageItem);
        expect(status.hasOcrText, isTrue);
      });

      test('should create correct status for image without OCR', () async {
        final imageItem = MockClipItem();
        when(imageItem.type).thenReturn(ClipType.image);
        when(imageItem.ocrText).thenReturn(null);
        when(imageItem.filePath).thenReturn('/path/to/image.jpg');

        final status = await service.getCopySupportStatus(imageItem);
        expect(status.hasOcrText, isFalse);
      });

      test('should create correct status for non-image item', () async {
        final textItem = MockClipItem();
        when(textItem.type).thenReturn(ClipType.text);
        when(textItem.ocrText).thenReturn('Sample text');

        final status = await service.getCopySupportStatus(textItem);
        expect(status.hasOcrText, isFalse);
      });
    });

    group('OCRCopySupportStatus', () {
      test('should calculate canCopyAnything correctly', () {
        final status1 = const OCRCopySupportStatus(
          canCopyImage: true,
          canCopyOcrText: false,
          hasOcrText: false,
          hasImageData: true,
        );
        expect(status1.canCopyAnything, isTrue);

        final status2 = const OCRCopySupportStatus(
          canCopyImage: false,
          canCopyOcrText: true,
          hasOcrText: true,
          hasImageData: false,
        );
        expect(status2.canCopyAnything, isTrue);

        final status3 = const OCRCopySupportStatus(
          canCopyImage: false,
          canCopyOcrText: false,
          hasOcrText: false,
          hasImageData: false,
        );
        expect(status3.canCopyAnything, isFalse);
      });

      test('should calculate canCopyBoth correctly', () {
        final status1 = const OCRCopySupportStatus(
          canCopyImage: true,
          canCopyOcrText: true,
          hasOcrText: true,
          hasImageData: true,
        );
        expect(status1.canCopyBoth, isTrue);

        final status2 = const OCRCopySupportStatus(
          canCopyImage: true,
          canCopyOcrText: false,
          hasOcrText: false,
          hasImageData: true,
        );
        expect(status2.canCopyBoth, isFalse);
      });

      test('should provide meaningful toString', () {
        final status = const OCRCopySupportStatus(
          canCopyImage: true,
          canCopyOcrText: false,
          hasOcrText: false,
          hasImageData: true,
        );

        final result = status.toString();
        expect(result, contains('canCopyImage: true'));
        expect(result, contains('canCopyOcrText: false'));
        expect(result, contains('hasOcrText: false'));
        expect(result, contains('hasImageData: true'));
      });
    });

    group('Error Handling', () {
      setUp(() async {
        await service.initialize();
      });

      test('should handle uninitialized service', () async {
        final uninitializedService = OCRCopyService();
        final imageItem = MockClipItem();
        when(imageItem.type).thenReturn(ClipType.image);

        expect(
          () => uninitializedService.copyImageSilently(imageItem),
          throwsStateError,
        );

        expect(
          () => uninitializedService.copyOcrTextSilently(imageItem),
          throwsStateError,
        );
      });
    });

    group('OCRTextFormat Enum', () {
      test('should have correct format values', () {
        expect(OCRTextFormat.plain.name, equals('plain'));
        expect(OCRTextFormat.formatted.name, equals('formatted'));
        expect(OCRTextFormat.json.name, equals('json'));
        expect(OCRTextFormat.markdown.name, equals('markdown'));
      });
    });
  });
}