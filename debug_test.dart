/// 调试测试文件，用于验证 HTML 检测逻辑
void main() {
  const test = '#include <iostream>';

  // 模拟 _isPureHtml 逻辑
  // 检查是否包含明显的代码模式
  final hasCodePatterns =
      test.contains('function ') ||
      test.contains('const ') ||
      test.contains('let ') ||
      test.contains('var ') ||
      test.contains('class ') ||
      test.contains('def ') ||
      test.contains('import ') ||
      test.contains('from ') ||
      test.contains('//') ||
      test.contains('/*') ||
      test.contains('useState') ||
      test.contains('useEffect') ||
      test.contains('document.') ||
      test.contains('console.');

  // ignore: avoid_print, 用于调试输出
  print('Has code patterns: $hasCodePatterns');

  if (hasCodePatterns) {
    // ignore: avoid_print, 用于调试输出
    print('Should return false from _isPureHtml');
    return;
  }

  // 检查是否主要由 HTML 标签组成
  const htmlTagPattern = '<[^>]+>';
  final matches = RegExp(htmlTagPattern).allMatches(test);
  const totalLength = test.length;
  final tagLength = matches.fold(
    0,
    (sum, match) => sum + match.group(0)!.length,
  );

  // ignore: avoid_print, 用于调试输出
  print('Total length: $totalLength');
  // ignore: avoid_print, 用于调试输出
  print('Tag length: $tagLength');
  // ignore: avoid_print, 用于调试输出
  print('Tag ratio: ${tagLength / totalLength}');

  // 如果 HTML 标签占内容的 30% 以上，认为是纯 HTML
  final isPureHtml = tagLength / totalLength > 0.3;
  // ignore: avoid_print, 用于调试输出
  print('Is pure HTML: $isPureHtml');
}
