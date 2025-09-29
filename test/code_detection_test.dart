import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/services/clipboard_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('代码检测测试', () {
    late ClipboardService clipboardService;

    setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

    setUp(() {
      clipboardService = ClipboardService();
    });

    test('Flutter Widget代码检测', () async {
      const codeContent = '''
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text('Hello'),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {},
            child: Text('Click me'),
          ),
        ],
      ),
    );
  }
}''';

      final result = clipboardService.detectContentTypeForTesting(codeContent);
      expect(result, ClipType.code, reason: 'Flutter widget代码应该被识别为代码类型');
    });

    test('包含HTML标签的JavaScript代码检测', () async {
      const codeContent = '''
function createDiv() {
  const div = document.createElement('div');
  div.innerHTML = '<p>Hello World</p>';
  div.className = 'my-class';
  
  if (div.children.length > 0) {
    console.log('Created div with children');
  }
  
  return div;
}''';

      final result = clipboardService.detectContentTypeForTesting(codeContent);
      expect(result, ClipType.code, reason: '包含HTML标签的JavaScript代码应该被识别为代码类型');
    });

    test('React组件代码检测', () {
      const codeContent = '''
const MyComponent = () => {
  const [count, setCount] = useState(0);
  
  return (
    <div className="container">
      <h1>Counter: {count}</h1>
      <button onClick={() => setCount(count + 1)}>
        Increment
      </button>
    </div>
  );
};''';

      final result = clipboardService.detectContentTypeForTesting(codeContent);
      expect(result, ClipType.code, reason: 'React组件代码应该被识别为代码类型');
    });

    test('纯HTML内容检测', () {
      const htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <title>Test Page</title>
</head>
<body>
  <h1>Welcome</h1>
  <p>This is a test page.</p>
  <div class="content">
    <ul>
      <li>Item 1</li>
      <li>Item 2</li>
    </ul>
  </div>
</body>
</html>''';

      final result = clipboardService.detectContentTypeForTesting(htmlContent);
      expect(result, ClipType.html, reason: '完整的HTML文档应该被识别为HTML类型');
    });

    test('HTML片段检测', () {
      const htmlContent = '''
<div class="card">
  <h2>Card Title</h2>
  <p>Card description goes here.</p>
  <button class="btn">Click me</button>
  <img src="image.jpg" alt="Image">
  <a href="link.html">Read more</a>
</div>''';

      final result = clipboardService.detectContentTypeForTesting(htmlContent);
      expect(result, ClipType.html, reason: '包含多个HTML标签的片段应该被识别为HTML类型');
    });

    test('简单HTML标签应该被识别为HTML', () {
      const simpleContent = '<div>Simple content</div>';

      final result = clipboardService.detectContentTypeForTesting(
        simpleContent,
      );
      expect(result, ClipType.html, reason: '简单的HTML标签应该被识别为HTML类型');
    });
  });
}
