import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/clipboard_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('剪贴板类型检测优化测试', () {
    late ClipboardService clipboardService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      clipboardService = ClipboardService();
    });

    test('颜色值检测', () {
      expect(
        clipboardService.detectContentTypeForTesting('#FF0000'),
        ClipType.color,
      );
      expect(
        clipboardService.detectContentTypeForTesting('rgb(255, 0, 0)'),
        ClipType.color,
      );
      expect(
        clipboardService.detectContentTypeForTesting('rgba(255, 0, 0, 0.5)'),
        ClipType.color,
      );
    });

    test('URL检测', () {
      expect(
        clipboardService.detectContentTypeForTesting('https://www.example.com'),
        ClipType.url,
      );
      expect(
        clipboardService.detectContentTypeForTesting('http://localhost:3000'),
        ClipType.url,
      );
    });

    test('邮箱检测', () {
      expect(
        clipboardService.detectContentTypeForTesting('user@example.com'),
        ClipType.email,
      );
    });

    test('JSON内容检测', () {
      const jsonContent = '{"name": "John", "age": 30}';
      expect(
        clipboardService.detectContentTypeForTesting(jsonContent),
        ClipType.json,
      );
    });

    test('HTML内容检测', () {
      const htmlContent = '<html><body><h1>Test</h1></body></html>';
      expect(
        clipboardService.detectContentTypeForTesting(htmlContent),
        ClipType.html,
      );
    });

    test('普通文本检测', () {
      const plainText = '这是一段普通的文本内容';
      expect(
        clipboardService.detectContentTypeForTesting(plainText),
        ClipType.text,
      );
    });
  });
}
