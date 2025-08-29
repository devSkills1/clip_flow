import 'dart:math';

class ColorUtils {
  // 检测是否为颜色值
  static bool isColorValue(String value) {
    final trimmed = value.trim();
    
    // HEX格式检测
    if (_isHexColor(trimmed)) return true;
    
    // RGB格式检测
    if (_isRgbColor(trimmed)) return true;
    
    // HSL格式检测
    if (_isHslColor(trimmed)) return true;
    
    return false;
  }

  // HEX颜色检测
  static bool _isHexColor(String value) {
    final hexPattern = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
    return hexPattern.hasMatch(value);
  }

  // RGB颜色检测
  static bool _isRgbColor(String value) {
    final rgbPattern = RegExp(
      r'^rgb\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)$',
    );
    if (!rgbPattern.hasMatch(value)) return false;
    
    final match = rgbPattern.firstMatch(value);
    if (match == null) return false;
    
    final r = int.parse(match.group(1)!);
    final g = int.parse(match.group(2)!);
    final b = int.parse(match.group(3)!);
    
    return r >= 0 && r <= 255 && g >= 0 && g <= 255 && b >= 0 && b <= 255;
  }

  // HSL颜色检测
  static bool _isHslColor(String value) {
    final hslPattern = RegExp(
      r'^hsl\(\s*(\d{1,3})\s*,\s*(\d{1,3})%\s*,\s*(\d{1,3})%\s*\)$',
    );
    if (!hslPattern.hasMatch(value)) return false;
    
    final match = hslPattern.firstMatch(value);
    if (match == null) return false;
    
    final h = int.parse(match.group(1)!);
    final s = int.parse(match.group(2)!);
    final l = int.parse(match.group(3)!);
    
    return h >= 0 && h <= 360 && s >= 0 && s <= 100 && l >= 0 && l <= 100;
  }

  // HEX转RGB
  static Map<String, int> hexToRgb(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 3) {
      hex = hex.split('').map((c) => c + c).join();
    }
    
    final r = int.parse(hex.substring(0, 2), radix: 16);
    final g = int.parse(hex.substring(2, 4), radix: 16);
    final b = int.parse(hex.substring(4, 6), radix: 16);
    
    return {'r': r, 'g': g, 'b': b};
  }

  // RGB转HEX
  static String rgbToHex(int r, int g, int b) {
    return '#${r.toRadixString(16).padLeft(2, '0')}'
           '${g.toRadixString(16).padLeft(2, '0')}'
           '${b.toRadixString(16).padLeft(2, '0')}';
  }

  // HEX转HSL
  static Map<String, double> hexToHsl(String hex) {
    final rgb = hexToRgb(hex);
    return rgbToHsl(rgb['r']!, rgb['g']!, rgb['b']!);
  }

  // RGB转HSL
  static Map<String, double> rgbToHsl(int r, int g, int b) {
    r /= 255;
    g /= 255;
    b /= 255;
    
    final max = [r, g, b].reduce(max);
    final min = [r, g, b].reduce(min);
    double h, s, l = (max + min) / 2;
    
    if (max == min) {
      h = s = 0; // 灰色
    } else {
      final d = max - min;
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
      
      switch (max) {
        case r:
          h = (g - b) / d + (g < b ? 6 : 0);
          break;
        case g:
          h = (b - r) / d + 2;
          break;
        case b:
          h = (r - g) / d + 4;
          break;
        default:
          h = 0;
      }
      h /= 6;
    }
    
    return {
      'h': (h * 360).roundToDouble(),
      's': (s * 100).roundToDouble(),
      'l': (l * 100).roundToDouble(),
    };
  }

  // HSL转RGB
  static Map<String, int> hslToRgb(double h, double s, double l) {
    h /= 360;
    s /= 100;
    l /= 100;
    
    double r, g, b;
    
    if (s == 0) {
      r = g = b = l; // 灰色
    } else {
      final hue2rgb = (double p, double q, double t) {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1 / 6) return p + (q - p) * 6 * t;
        if (t < 1 / 2) return q;
        if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
        return p;
      };
      
      final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      final p = 2 * l - q;
      r = hue2rgb(p, q, h + 1 / 3);
      g = hue2rgb(p, q, h);
      b = hue2rgb(p, q, h - 1 / 3);
    }
    
    return {
      'r': (r * 255).round(),
      'g': (g * 255).round(),
      'b': (b * 255).round(),
    };
  }

  // 计算颜色相似度 (Delta E)
  static double calculateColorSimilarity(String color1, String color2) {
    final rgb1 = hexToRgb(color1);
    final rgb2 = hexToRgb(color2);
    
    final r1 = rgb1['r']!.toDouble();
    final g1 = rgb1['g']!.toDouble();
    final b1 = rgb1['b']!.toDouble();
    
    final r2 = rgb2['r']!.toDouble();
    final g2 = rgb2['g']!.toDouble();
    final b2 = rgb2['b']!.toDouble();
    
    // 简单的欧几里得距离
    final deltaR = r1 - r2;
    final deltaG = g1 - g2;
    final deltaB = b1 - b2;
    
    return sqrt(deltaR * deltaR + deltaG * deltaG + deltaB * deltaB);
  }

  // 生成颜色变体
  static List<String> generateColorVariants(String baseColor, {int count = 5}) {
    final hsl = hexToHsl(baseColor);
    final variants = <String>[];
    
    for (int i = 0; i < count; i++) {
      final h = (hsl['h']! + i * 30) % 360;
      final s = (hsl['s']! + i * 10).clamp(0, 100);
      final l = (hsl['l']! + i * 5).clamp(0, 100);
      
      final rgb = hslToRgb(h, s, l);
      final hex = rgbToHex(rgb['r']!, rgb['g']!, rgb['b']!);
      variants.add(hex);
    }
    
    return variants;
  }

  // 获取颜色名称
  static String getColorName(String hexColor) {
    final rgb = hexToRgb(hexColor);
    final r = rgb['r']!;
    final g = rgb['g']!;
    final b = rgb['b']!;
    
    // 简单的颜色名称映射
    if (r > 200 && g < 100 && b < 100) return '红色';
    if (r < 100 && g > 200 && b < 100) return '绿色';
    if (r < 100 && g < 100 && b > 200) return '蓝色';
    if (r > 200 && g > 200 && b < 100) return '黄色';
    if (r > 200 && g < 100 && b > 200) return '紫色';
    if (r < 100 && g > 200 && b > 200) return '青色';
    if (r > 200 && g > 200 && b > 200) return '白色';
    if (r < 50 && g < 50 && b < 50) return '黑色';
    
    return '自定义颜色';
  }
}
