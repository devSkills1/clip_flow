import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 测试快捷键唤起应用的简单脚本
/// 这个脚本可以用来验证快捷键是否能正确唤起最小化的应用
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化窗口管理
  await windowManager.ensureInitialized();

  // 设置窗口选项
  const windowOptions = WindowOptions(
    size: Size(400, 300),
    center: true,
    backgroundColor: Colors.white,
    titleBarStyle: TitleBarStyle.normal,
    alwaysOnTop: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setTitle('快捷键测试');
  });

  runApp(const HotkeyTestApp());
}

class HotkeyTestApp extends StatelessWidget {
  const HotkeyTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('快捷键唤起测试'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '快捷键唤起测试',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 20),
              Text(
                '1. 点击最小化按钮最小化窗口\n'
                '2. 使用快捷键 Cmd+Shift+V (macOS) 唤起应用\n'
                '3. 验证应用是否能正确显示并聚焦',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              TestButtons(),
            ],
          ),
        ),
      ),
    );
  }
}

class TestButtons extends StatefulWidget {
  const TestButtons({super.key});

  @override
  State<TestButtons> createState() => _TestButtonsState();
}

class _TestButtonsState extends State<TestButtons> {
  String _status = '就绪';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '状态: $_status',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () async {
                setState(() => _status = '最小化中...');
                await windowManager.minimize();
                setState(() => _status = '已最小化，请使用快捷键唤起');
              },
              child: const Text('最小化窗口'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() => _status = '隐藏中...');
                await windowManager.hide();
                setState(() => _status = '已隐藏，请使用快捷键唤起');
              },
              child: const Text('隐藏窗口'),
            ),
          ],
        ),
      ],
    );
  }
}
