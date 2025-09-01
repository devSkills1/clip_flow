import 'dart:math' as math; //Dart 的核心数学库dart:math导入，并为其指定了别名math。
import 'dart:ui' show Color; //部分导入dart:ui库的语句，仅导入了该库中的Color类。
import '../constants/clip_constants.dart';

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

  // HEX颜色检测（支持 #RGB/#RRGGBB 以及带透明度的 #RGBA/#RRGGBBAA）、
  // 兼容有#号、无#号
  static bool _isHexColor(String value) {
    final hexPattern = RegExp(ClipConstants.hexColorPattern);
    return hexPattern.hasMatch(value);
  }

  // RGB颜色检测（支持 rgb(...) 以及 rgba(..., a) 且 a ∈ [0,1]）
  static bool _isRgbColor(String value) {
    final rgbPattern = RegExp(ClipConstants.rgbColorPattern);
    final rgbaPattern = RegExp(ClipConstants.rgbaColorPattern);

    if (!rgbPattern.hasMatch(value) && !rgbaPattern.hasMatch(value)) {
      return false;
    }

    final match = rgbPattern.firstMatch(value) ?? rgbaPattern.firstMatch(value);
    if (match == null) return false;

    final r = int.parse(match.group(1)!);
    final g = int.parse(match.group(2)!);
    final b = int.parse(match.group(3)!);

    final rgbInRange =
        r >= 0 && r <= 255 && g >= 0 && g <= 255 && b >= 0 && b <= 255;
    if (!rgbInRange) return false;

    // 如为 rgba，校验 alpha
    if (rgbaPattern.hasMatch(value)) {
      final a = double.parse(match.group(4)!);
      if (a < 0 || a > 1) return false;
    }

    return true;
  }

  // HSL颜色检测
  static bool _isHslColor(String value) {
    final hslPattern = RegExp(ClipConstants.hslColorPattern);
    if (!hslPattern.hasMatch(value)) return false;

    final match = hslPattern.firstMatch(value);
    if (match == null) return false;

    final h = int.parse(match.group(1)!);
    final s = int.parse(match.group(2)!);
    final l = int.parse(match.group(3)!);

    return h >= 0 && h <= 360 && s >= 0 && s <= 100 && l >= 0 && l <= 100;
  }

  // HEX转RGB（兼容 #RGBA/#RRGGBBAA；忽略 alpha，仅返回 RGB）
  static Map<String, int> hexToRgb(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 3) {
      // #RGB => #RRGGBB
      hex = hex.split('').map((c) => c + c).join();
    } else if (hex.length == 4) {
      // #RGBA => #RRGGBBAA
      hex = hex.split('').map((c) => c + c).join();
    }

    if (hex.length == 8) {
      // #RRGGBBAA => 仅取 RRGGBB，忽略末尾 AA
      hex = hex.substring(0, 6);
    }

    final r = int.parse(hex.substring(0, 2), radix: ClipConstants.hexRadix);
    final g = int.parse(hex.substring(2, 4), radix: ClipConstants.hexRadix);
    final b = int.parse(hex.substring(4, 6), radix: ClipConstants.hexRadix);

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

  // RGB转HSL（修复类型与 max/min 冲突）
  static Map<String, double> rgbToHsl(int r, int g, int b) {
    final double rD = r / 255.0;
    final double gD = g / 255.0;
    final double bD = b / 255.0;

    final double maxVal = [rD, gD, bD].reduce(math.max);
    final double minVal = [rD, gD, bD].reduce(math.min);
    double h = 0;
    double s = 0;
    final double l = (maxVal + minVal) / 2.0;

    if (maxVal != minVal) {
      final double d = maxVal - minVal;
      s = l > 0.5 ? d / (2.0 - maxVal - minVal) : d / (maxVal + minVal);
      if (maxVal == rD) {
        h = (gD - bD) / d + (gD < bD ? 6.0 : 0.0);
      } else if (maxVal == gD) {
        h = (bD - rD) / d + 2.0;
      } else {
        h = (rD - gD) / d + 4.0;
      }
      h /= 6.0;
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
      double hue2rgb(double p, double q, double t) {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1 / 6) return p + (q - p) * 6 * t;
        if (t < 1 / 2) return q;
        if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
        return p;
      }

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

  // 计算颜色相似度 (Delta E 简化)
  static double calculateColorSimilarity(String color1, String color2) {
    final rgb1 = hexToRgb(color1);
    final rgb2 = hexToRgb(color2);

    final r1 = rgb1['r']!.toDouble();
    final g1 = rgb1['g']!.toDouble();
    final b1 = rgb1['b']!.toDouble();

    final r2 = rgb2['r']!.toDouble();
    final g2 = rgb2['g']!.toDouble();
    final b2 = rgb2['b']!.toDouble();

    final deltaR = r1 - r2;
    final deltaG = g1 - g2;
    final deltaB = b1 - b2;

    return math.sqrt(deltaR * deltaR + deltaG * deltaG + deltaB * deltaB);
  }

  // 生成颜色变体
  static List<String> generateColorVariants(String baseColor, {int count = 5}) {
    final hsl = hexToHsl(baseColor);
    final variants = <String>[];

    for (int i = 0; i < count; i++) {
      final h = (hsl['h']! + i * 30) % 360;
      final s = (hsl['s']! + i * 10).clamp(0, 100).toDouble();
      final l = (hsl['l']! + i * 5).clamp(0, 100).toDouble();

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

  // 颜色值转换为16进制字符串
  static String colorToHex(
    Color color, {
    bool includeAlpha = false,
    bool withHash = true,
    bool upperCase = false,
  }) {
    final r = (color.r * 255).round() & 0xff;
    final g = (color.g * 255).round() & 0xff;
    final b = (color.b * 255).round() & 0xff;
    final a = (color.a * 255).round() & 0xff;

    final hex = includeAlpha ? '$r$g$b$a' : '$r$g$b'; // 使用 CSS 风格的 RRGGBBAA
    final out = withHash ? '#$hex' : hex;
    return upperCase ? out.toUpperCase() : out;
  }

  // 16进制字符串转换为 Color（支持 #RGB/#RGBA/#RRGGBB/#RRGGBBAA，兼容无#）
  static Color hexToColor(String hex) {
    var value = hex.trim();
    if (value.startsWith('#')) value = value.substring(1);

    // 基于现有校验规则验证输入
    if (!_isHexColor('#$value')) {
      throw FormatException('Invalid hex color: $hex');
    }

    // #RGB/#RGBA -> #RRGGBB/#RRGGBBAA
    if (value.length == 3 || value.length == 4) {
      value = value.split('').map((c) => c + c).join();
    }

    // 若无透明度，默认 0xFF
    if (value.length == 6) {
      value = 'FF$value'; // AARRGGBB
    } else if (value.length == 8) {
      // 从 RRGGBBAA 转为 AARRGGBB（Color 构造函数使用 ARGB）
      value = value.substring(6, 8) + value.substring(0, 6);
    }

    final argb = int.parse(value, radix: ClipConstants.hexRadix);
    return Color(argb);
  }
}
