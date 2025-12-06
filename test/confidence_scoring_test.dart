import 'package:clip_flow/core/models/clip_item.dart';
import 'package:clip_flow/core/services/clipboard_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('置信度评分系统测试', () {
    late ClipboardDetector detector;

    setUp(() {
      detector = ClipboardDetector();
    });

    group('代码与HTML区分测试', () {
      test('应该正确识别纯HTML而非代码', () {
        const htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <title>测试页面</title>
</head>
<body>
    <div class="container">
        <h1>欢迎</h1>
        <p>这是一个段落</p>
    </div>
</body>
</html>''';

        final result = detector.detectContentType(htmlContent);
        expect(result, equals(ClipType.html));
      });

      test('应该正确识别包含HTML的JavaScript代码', () {
        const jsWithHtml = '''
function createComponent() {
  const element = document.createElement('div');
  element.innerHTML = '<h1>Hello World</h1>';
  element.className = 'component';
  return element;
}

export default createComponent;''';

        final result = detector.detectContentType(jsWithHtml);
        expect(result, equals(ClipType.code));
      });

      test('应该正确识别React组件代码', () {
        const reactCode = '''
import React, { useState } from 'react';

const MyComponent = () => {
  const [count, setCount] = useState(0);
  
  return (
    <div>
      <h1>Count: {count}</h1>
      <button onClick={() => setCount(count + 1)}>
        Increment
      </button>
    </div>
  );
};

export default MyComponent;''';

        final result = detector.detectContentType(reactCode);
        expect(result, equals(ClipType.code));
      });
    });

    group('边界情况测试', () {
      test('应该正确处理混合内容', () {
        const mixedContent = '''
{
  "name": "test",
  "url": "https://example.com",
  "email": "test@example.com"
}''';

        final result = detector.detectContentType(mixedContent);
        expect(result, equals(ClipType.json));
      });

      test('应该正确识别带有代码片段的JSON', () {
        const jsonWithCode = '''
{
  "script": "function test() { return 'hello'; }",
  "html": "<div>Hello</div>",
  "css": "body { color: red; }"
}''';

        final result = detector.detectContentType(jsonWithCode);
        expect(result, equals(ClipType.json));
      });

      test('应该正确识别SQL查询', () {
        const sqlQuery = '''
SELECT u.name, u.email, p.title
FROM users u
JOIN posts p ON u.id = p.user_id
WHERE u.active = 1
ORDER BY p.created_at DESC
LIMIT 10;''';

        final result = detector.detectContentType(sqlQuery);
        expect(result, equals(ClipType.code));
      });
    });

    group('置信度分析测试', () {
      test('应该提供详细的分析结果', () {
        const codeContent = '''
function fibonacci(n) {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}''';

        final details = detector.getAnalysisDetails(codeContent);
        expect(details, isA<Map<String, dynamic>>());
        expect(details.containsKey('results'), isTrue);
        expect(details.containsKey('decision'), isTrue);

        final results = details['results'] as List<Map<String, dynamic>>;
        expect(results.isNotEmpty, isTrue);

        // 验证代码分析器有高置信度
        final codeResult = results.firstWhere(
          (r) => r['type'] == 'code',
          orElse: () => <String, dynamic>{},
        );
        expect(codeResult.isNotEmpty, isTrue);
        expect(codeResult['confidence'] as double, greaterThan(0.7));
      });

      test('应该正确分析颜色值', () {
        const colorValue = '#FF5733';

        final details = detector.getAnalysisDetails(colorValue);
        final results = details['results'] as List<Map<String, dynamic>>?;
        expect(results, isNotNull);

        final colorResult = results!.firstWhere(
          (r) => r['type'] == 'color',
          orElse: () => <String, dynamic>{},
        );
        expect(colorResult.isNotEmpty, isTrue);
        expect(colorResult['confidence'] as double, equals(1.0));
      });
    });

    group('语言识别测试', () {
      test('应该正确识别Python代码', () {
        const pythonCode = '''
def calculate_fibonacci(n):
    if n <= 1:
        return n
    return calculate_fibonacci(n - 1) + calculate_fibonacci(n - 2)

if __name__ == "__main__":
    print(calculate_fibonacci(10))''';

        final language = detector.estimateLanguage(pythonCode);
        expect(language, equals('python'));
      });

      test('应该正确识别Dart代码', () {
        const dartCode = '''
class Calculator {
  int add(int a, int b) => a + b;
  
  int subtract(int a, int b) => a - b;
}

void main() {
  final calc = Calculator();
  print(calc.add(5, 3));
}''';

        final language = detector.estimateLanguage(dartCode);
        expect(language, equals('dart'));
      });

      test('应该正确识别Go代码', () {
        const goCode = '''
package main

import "fmt"

func fibonacci(n int) int {
    if n <= 1 {
        return n
    }
    return fibonacci(n-1) + fibonacci(n-2)
}

func main() {
    fmt.Println(fibonacci(10))
}''';

        final language = detector.estimateLanguage(goCode);
        expect(language, equals('go'));
      });
    });

    group('文件类型检测测试', () {
      test('应该根据扩展名检测文件类型', () {
        expect(detector.detectFileType('test.js'), equals(ClipType.code));
        expect(detector.detectFileType('test.py'), equals(ClipType.code));
        expect(detector.detectFileType('test.html'), equals(ClipType.html));
        expect(detector.detectFileType('test.json'), equals(ClipType.json));
        expect(detector.detectFileType('test.xml'), equals(ClipType.xml));
        expect(detector.detectFileType('test.txt'), equals(ClipType.text));
      });

      test('应该处理无扩展名的文件', () {
        expect(detector.detectFileType('README'), equals(ClipType.text));
        expect(detector.detectFileType('Makefile'), equals(ClipType.text));
      });
    });
  });
}
