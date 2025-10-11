import 'package:clip_flow_pro/core/services/platform/ocr/ocr_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// OCR功能演示页面
class OcrDemoPage extends StatefulWidget {
  /// 构造函数
  const OcrDemoPage({super.key});

  @override
  State<OcrDemoPage> createState() => _OcrDemoPageState();
}

class _OcrDemoPageState extends State<OcrDemoPage> {
  final OcrService _ocrService = OcrServiceFactory.getInstance();
  String _result = '';
  bool _isProcessing = false;
  double _confidence = 0;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  /// 创建一个简单的测试图像（包含数字"1"的模式）
  Uint8List _createTestImage() {
    // 创建一个简单的8x8像素图像，包含数字"1"的模式
    const width = 8;
    const height = 8;

    // 数字"1"的模式（与SimpleOcrImpl中定义的模式匹配）
    const pattern = [
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 1, 1, 1, 0, 0, 0],
      [0, 1, 1, 1, 1, 0, 0, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
      [1, 1, 1, 1, 1, 1, 1, 1],
    ];

    // 创建RGBA像素数据
    final pixels = <int>[];
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final isWhite = pattern[y][x] == 1;
        if (isWhite) {
          pixels.addAll([255, 255, 255, 255]); // 白色
        } else {
          pixels.addAll([0, 0, 0, 255]); // 黑色
        }
      }
    }

    // 创建简单的PNG格式图像数据
    final header = <int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
    ];

    // IHDR chunk
    final ihdr = <int>[
      0x00, 0x00, 0x00, 0x0D, // chunk length
      0x49, 0x48, 0x44, 0x52, // chunk type "IHDR"
      0x00, 0x00, 0x00, width, // width
      0x00, 0x00, 0x00, height, // height
      0x08, // bit depth
      0x06, // color type (RGBA)
      0x00, // compression method
      0x00, // filter method
      0x00, // interlace method
      // CRC would go here in a real PNG
      0x00, 0x00, 0x00, 0x00,
    ];

    // 简化的IDAT chunk（实际应该包含压缩的像素数据）
    final idat = <int>[
      0x00, 0x00, 0x01, 0x00, // chunk length (simplified)
      0x49, 0x44, 0x41, 0x54, // chunk type "IDAT"
      ...pixels.take(256), // 简化的像素数据
      0x00, 0x00, 0x00, 0x00, // CRC
    ];

    // IEND chunk
    final iend = <int>[
      0x00, 0x00, 0x00, 0x00, // chunk length
      0x49, 0x45, 0x4E, 0x44, // chunk type "IEND"
      0xAE, 0x42, 0x60, 0x82, // CRC
    ];

    return Uint8List.fromList([...header, ...ihdr, ...idat, ...iend]);
  }

  /// 测试OCR识别
  Future<void> _testOcr() async {
    setState(() {
      _isProcessing = true;
      _result = '';
      _confidence = 0;
    });

    try {
      final testImage = _createTestImage();
      final result = await _ocrService.recognizeText(testImage);

      setState(() {
        if (result != null) {
          _result = result.text.isEmpty ? '未识别到文字' : result.text;
          _confidence = result.confidence;
        } else {
          _result = '识别失败';
          _confidence = 0;
        }
      });
    } on FormatException catch (e) {
      setState(() {
        _result = '错误: $e';
        _confidence = 0;
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// 显示OCR服务信息
  Widget _buildServiceInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OCR服务信息',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<bool>(
              future: _ocrService.isAvailable(),
              builder: (context, snapshot) {
                return Text(
                  '服务状态: ${snapshot.data ?? false ? "可用" : "不可用"}',
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              '支持语言: ${_ocrService.getSupportedLanguages().join(", ")}',
            ),
          ],
        ),
      ),
    );
  }

  /// 显示识别结果
  Widget _buildResult() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '识别结果',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_isProcessing)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('正在识别...'),
                ],
              )
            else ...[
              Text('文本: $_result'),
              const SizedBox(height: 4),
              Text('置信度: ${(_confidence * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _confidence,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _confidence > 0.7
                      ? Colors.green
                      : _confidence > 0.4
                      ? Colors.orange
                      : Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR功能演示'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildServiceInfo(),
            const SizedBox(height: 16),
            _buildResult(),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '测试说明',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '点击下方按钮将测试OCR功能，使用一个包含数字"1"的简单图像模式。'
                      '\n\n当前OCR实现支持：'
                      '\n• 基础图像预处理（灰度化、二值化、降噪）'
                      '\n• 连通组件分析'
                      '\n• 简单的数字识别（0-1）'
                      '\n• 文字特征检测',
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isProcessing ? null : _testOcr,
              child: const Text('测试OCR识别'),
            ),
          ],
        ),
      ),
    );
  }
}
