import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:clip_flow_pro/core/services/clipboard_processor.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// 测试文件名清理功能，验证原始文件名处理逻辑
void main() {
  group('文件名处理测试', () {
    test('应该正确清理中文文件名', () {
      // 模拟文件名清理逻辑
      String sanitizedBase(String name) {
        final base = name.split('/').last.split(r'\').last;
        final dotIndex = base.lastIndexOf('.');
        final withoutExt = dotIndex > 0 ? base.substring(0, dotIndex) : base;

        final replaced = withoutExt.replaceAll(
          RegExp('[^A-Za-z0-9\u4e00-\u9fff _.-]'),
          '_',
        );

        final compact = replaced
            .replaceAll(RegExp(r'\s+'), '_')
            .replaceAll(RegExp(r'_+'), '_')
            .replaceAll(RegExp(r'^_+|_+$'), '');

        if (compact.isEmpty) {
          return 'file';
        }

        return compact.length > 60 ? compact.substring(0, 60) : compact;
      }

      // 测试中文文件名
      final chineseName = sanitizedBase('测试文档.txt');
      expect(chineseName, equals('测试文档'));

      // 测试英文文件名
      final englishName = sanitizedBase('My Important Document.docx');
      expect(englishName, equals('My_Important_Document'));

      // 测试特殊字符文件名
      final specialName = sanitizedBase('File@#\$%^&*()Name.pdf');
      expect(specialName, equals('File_Name'));

      print('中文文件名处理: 测试文档.txt -> $chineseName');
      print('英文文件名处理: My Important Document.docx -> $englishName');
      print('特殊字符处理: File@#\$%^&*()Name.pdf -> $specialName');
    });

    test('应该生成正确的文件名格式', () {
      // 模拟文件名生成逻辑
      String generateFileName(String originalName, bool keepOriginalName) {
        final bytes = utf8.encode('test content');
        final hash = sha256.convert(bytes).toString().substring(0, 8);
        final ts = DateTime.now().millisecondsSinceEpoch;

        String sanitizedBase(String name) {
          final base = name.split('/').last.split(r'\').last;
          final dotIndex = base.lastIndexOf('.');
          final withoutExt = dotIndex > 0 ? base.substring(0, dotIndex) : base;

          final replaced = withoutExt.replaceAll(
            RegExp('[^A-Za-z0-9\u4e00-\u9fff _.-]'),
            '_',
          );

          final compact = replaced
              .replaceAll(RegExp(r'\s+'), '_')
              .replaceAll(RegExp(r'_+'), '_')
              .replaceAll(RegExp(r'^_+|_+$'), '');

          if (compact.isEmpty) {
            return 'file';
          }

          return compact.length > 60 ? compact.substring(0, 60) : compact;
        }

        final ext = originalName.contains('.')
            ? originalName.split('.').last.toLowerCase()
            : 'bin';

        if (keepOriginalName && originalName.isNotEmpty) {
          final base = sanitizedBase(originalName);
          return '${base}_$hash.$ext';
        } else {
          return 'file_${ts}_$hash.$ext';
        }
      }

      // 测试保留原始文件名
      final fileName1 = generateFileName('测试文档.txt', true);
      expect(fileName1, startsWith('测试文档_'));
      expect(fileName1, endsWith('.txt'));

      final fileName2 = generateFileName('My Document.pdf', true);
      expect(fileName2, startsWith('My_Document_'));
      expect(fileName2, endsWith('.pdf'));

      // 测试不保留原始文件名
      final fileName3 = generateFileName('test.jpg', false);
      expect(fileName3, startsWith('file_'));
      expect(fileName3, endsWith('.jpg'));

      print('保留中文文件名: $fileName1');
      print('保留英文文件名: $fileName2');
      print('不保留文件名: $fileName3');
    });

    test('应该正确处理文件路径', () {
      // 测试相对路径生成
      const type = 'file';
      final relativeDir = type == 'image' ? 'media/images' : 'media/files';
      final fileName = 'test_file_12345678.txt';
      final relativePath = '$relativeDir/$fileName';

      expect(relativePath, equals('media/files/test_file_12345678.txt'));
      expect(relativePath, startsWith('media/files/'));

      print('生成的相对路径: $relativePath');
    });
  });
}
