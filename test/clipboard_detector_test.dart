import 'package:clip_flow/core/models/clip_item.dart';
import 'package:clip_flow/core/services/clipboard_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClipboardDetector 测试', () {
    late ClipboardDetector detector;

    setUp(() {
      detector = ClipboardDetector();
    });

    group('颜色检测', () {
      test('应该检测十六进制颜色值', () {
        expect(detector.detectContentType('#FF0000'), ClipType.color);
        expect(detector.detectContentType('#ff0000'), ClipType.color);
        expect(detector.detectContentType('#F00'), ClipType.color);
        expect(detector.detectContentType('#f00'), ClipType.color);
      });

      test('应该检测 RGB 颜色值', () {
        expect(detector.detectContentType('rgb(255, 0, 0)'), ClipType.color);
        expect(detector.detectContentType('rgb(255,0,0)'), ClipType.color);
        expect(detector.detectContentType('RGB(255, 0, 0)'), ClipType.color);
      });

      test('应该检测 RGBA 颜色值', () {
        expect(
          detector.detectContentType('rgba(255, 0, 0, 0.5)'),
          ClipType.color,
        );
        expect(detector.detectContentType('rgba(255,0,0,1)'), ClipType.color);
        expect(
          detector.detectContentType('RGBA(255, 0, 0, 0.8)'),
          ClipType.color,
        );
      });

      test('应该检测 HSL 颜色值', () {
        expect(detector.detectContentType('hsl(0, 100%, 50%)'), ClipType.color);
        expect(
          detector.detectContentType('HSL(120, 50%, 25%)'),
          ClipType.color,
        );
      });

      test('应该检测 HSLA 颜色值', () {
        expect(
          detector.detectContentType('hsla(0, 100%, 50%, 0.5)'),
          ClipType.color,
        );
        expect(
          detector.detectContentType('HSLA(240, 100%, 50%, 1)'),
          ClipType.color,
        );
      });
    });

    group('URL 检测', () {
      test('应该检测 HTTP/HTTPS URL', () {
        expect(
          detector.detectContentType('https://www.example.com'),
          ClipType.url,
        );
        expect(
          detector.detectContentType('http://localhost:3000'),
          ClipType.url,
        );
        expect(
          detector.detectContentType('https://github.com/user/repo'),
          ClipType.url,
        );
      });

      test('应该检测 FTP URL', () {
        expect(
          detector.detectContentType('ftp://files.example.com'),
          ClipType.url,
        );
      });

      test('应该检测带参数的 URL', () {
        expect(
          detector.detectContentType('https://example.com?param=value'),
          ClipType.url,
        );
        expect(
          detector.detectContentType('https://example.com/path?a=1&b=2'),
          ClipType.url,
        );
      });
    });

    group('邮箱检测', () {
      test('应该检测标准邮箱地址', () {
        expect(detector.detectContentType('user@example.com'), ClipType.email);
        expect(
          detector.detectContentType('test.email@domain.org'),
          ClipType.email,
        );
        expect(
          detector.detectContentType('admin@subdomain.example.co.uk'),
          ClipType.email,
        );
      });

      test('应该检测带数字的邮箱', () {
        expect(
          detector.detectContentType('user123@example.com'),
          ClipType.email,
        );
        expect(
          detector.detectContentType('123user@example.com'),
          ClipType.email,
        );
      });
    });

    group('JSON 检测', () {
      test('应该检测简单 JSON 对象', () {
        expect(detector.detectContentType('{"name": "John"}'), ClipType.json);
        expect(
          detector.detectContentType('{"age": 30, "active": true}'),
          ClipType.json,
        );
      });

      test('应该检测 JSON 数组', () {
        expect(detector.detectContentType('[1, 2, 3]'), ClipType.json);
        expect(
          detector.detectContentType('[{"id": 1}, {"id": 2}]'),
          ClipType.json,
        );
      });

      test('应该检测嵌套 JSON', () {
        const nestedJson = '{"user": {"name": "John", "details": {"age": 30}}}';
        expect(detector.detectContentType(nestedJson), ClipType.json);
      });
    });

    group('XML 检测', () {
      test('应该检测简单 XML', () {
        expect(
          detector.detectContentType('<root>content</root>'),
          ClipType.xml,
        );
        expect(
          detector.detectContentType('<user><name>John</name></user>'),
          ClipType.xml,
        );
      });

      test('应该检测带属性的 XML', () {
        expect(
          detector.detectContentType('<user id="1">John</user>'),
          ClipType.xml,
        );
      });

      test('应该检测 XML 声明', () {
        expect(
          detector.detectContentType('<?xml version="1.0"?><root></root>'),
          ClipType.xml,
        );
      });
    });

    group('代码检测', () {
      test('应该检测 JavaScript 代码', () {
        expect(
          detector.detectContentType('function test() { return true; }'),
          ClipType.code,
        );
        expect(detector.detectContentType('const x = 10;'), ClipType.code);
        expect(detector.detectContentType('if (condition) { }'), ClipType.code);
      });

      test('应该检测 Python 代码', () {
        expect(detector.detectContentType('def hello(): pass'), ClipType.code);
        expect(detector.detectContentType('import os'), ClipType.code);
        expect(detector.detectContentType('class MyClass:'), ClipType.code);
      });

      test('应该检测 Java 代码', () {
        expect(
          detector.detectContentType('public class Test { }'),
          ClipType.code,
        );
        expect(
          detector.detectContentType('private void method() { }'),
          ClipType.code,
        );
      });

      test('应该检测 C++ 代码', () {
        expect(
          detector.detectContentType('#include <iostream>'),
          ClipType.code,
        );
        expect(
          detector.detectContentType('int main() { return 0; }'),
          ClipType.code,
        );
      });
    });

    group('HTML 检测', () {
      test('应该检测 HTML 标签', () {
        expect(
          detector.detectContentType('<html><body></body></html>'),
          ClipType.html,
        );
        expect(
          detector.detectContentType('<div class="container">content</div>'),
          ClipType.html,
        );
        expect(
          detector.detectContentType('<p>Hello <strong>world</strong></p>'),
          ClipType.html,
        );
      });

      test('应该检测 HTML 文档类型', () {
        expect(detector.detectContentType('<!DOCTYPE html>'), ClipType.html);
      });
    });

    group('RTF 检测', () {
      test('应该检测 RTF 格式', () {
        expect(detector.detectContentType(r'{\rtf1\ansi\deff0'), ClipType.rtf);
        expect(
          detector.detectContentType(r'{\rtf1 Hello World}'),
          ClipType.rtf,
        );
      });
    });

    group('文件路径检测', () {
      test('应该检测 Windows 文件路径', () {
        expect(
          detector.detectContentType(r'C:\Users\Documents\file.txt'),
          ClipType.file,
        );
        expect(
          detector.detectContentType(r'D:\Projects\app.exe'),
          ClipType.file,
        );
      });

      test('应该检测 Unix 文件路径', () {
        expect(
          detector.detectContentType('/home/user/documents/file.txt'),
          ClipType.file,
        );
        expect(detector.detectContentType('/usr/local/bin/app'), ClipType.file);
      });

      test('应该检测相对路径', () {
        expect(
          detector.detectContentType('./config/settings.json'),
          ClipType.file,
        );
        expect(
          detector.detectContentType('../assets/image.png'),
          ClipType.file,
        );
        expect(
          detector.detectContentType('file://./config/settings.json'),
          ClipType.file,
        );
      });
    });

    group('普通文本检测', () {
      test('应该将简单文本识别为普通文本', () {
        expect(detector.detectContentType('Hello World'), ClipType.text);
        expect(
          detector.detectContentType('This is a simple text'),
          ClipType.text,
        );
        expect(detector.detectContentType('123456'), ClipType.text);
      });

      test('应该将多行文本识别为普通文本', () {
        const multilineText = '''
        This is a
        multiline text
        with several lines
        ''';
        expect(detector.detectContentType(multilineText), ClipType.text);
      });
    });

    group('边界情况', () {
      test('应该处理空字符串', () {
        expect(detector.detectContentType(''), ClipType.text);
      });

      test('应该处理只有空格的字符串', () {
        expect(detector.detectContentType('   '), ClipType.text);
        expect(detector.detectContentType('\n\t\r'), ClipType.text);
      });

      test('应该处理特殊字符', () {
        expect(detector.detectContentType('你好世界！@#￥%'), ClipType.text);
      });
    });
  });
}
