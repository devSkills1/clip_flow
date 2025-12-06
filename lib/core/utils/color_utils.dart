import 'dart:math' as math; //Dart 的核心数学库dart:math导入，并为其指定了别名math。
import 'dart:ui' show Color; //部分导入dart:ui库的语句，仅导入了该库中的Color类。
import 'package:clip_flow/core/constants/clip_constants.dart';

/// Color utilities for validating and converting between HEX/RGB/HSL.
class ColorUtils {
  static final RegExp _hexColorRegExp = RegExp(ClipConstants.hexColorPattern);
  static final RegExp _rgbColorRegExp = RegExp(ClipConstants.rgbColorPattern);
  static final RegExp _rgbaColorRegExp = RegExp(ClipConstants.rgbaColorPattern);
  static final RegExp _hslColorRegExp = RegExp(ClipConstants.hslColorPattern);
  static final RegExp _hslaColorRegExp = RegExp(ClipConstants.hslaColorPattern);
  static final RegExp _hex3RegExp = RegExp(r'^#[0-9A-Fa-f]{3}$');
  static final RegExp _hex4RegExp = RegExp(r'^#[0-9A-Fa-f]{4}$');
  static final RegExp _hex6RegExp = RegExp(r'^#[0-9A-Fa-f]{6}$');
  static final RegExp _hex8RegExp = RegExp(r'^#[0-9A-Fa-f]{8}$');
  static final RegExp _shortHexRegExp = RegExp(r'^[0-9A-Fa-f]{3,4}$');
  static final RegExp _longHexRegExp = RegExp(r'^[0-9A-Fa-f]{6}$');
  static final RegExp _longHexWithAlphaRegExp = RegExp(r'^[0-9A-Fa-f]{8}$');

  // 检测是否为颜色值
  /// Returns true if [value] matches supported color formats (HEX/RGB/HSL).
  static bool isColorValue(String value) {
    final trimmed = value.trim();

    // HEX格式检测
    if (_isHexColor(trimmed)) return true;

    // RGB格式检测
    if (_isRgbColor(trimmed)) return true;

    // RGBA格式检测
    if (_isRgbaColor(trimmed)) return true;

    // HSL格式检测
    if (_isHslColor(trimmed)) return true;

    // HSLA格式检测
    if (_isHslaColor(trimmed)) return true;
    return false;
  }

  // HEX颜色检测（支持 #RGB/#RRGGBB 以及带透明度的 #RGBA/#RRGGBBAA）、
  // 兼容有#号、无#号
  static bool _isHexColor(String value) {
    return _hexColorRegExp.hasMatch(value);
  }

  // RGB颜色检测（仅检测 rgb(r,g,b) 格式）
  static bool _isRgbColor(String value) {
    if (!_rgbColorRegExp.hasMatch(value)) {
      return false;
    }

    final match = _rgbColorRegExp.firstMatch(value);
    if (match == null) return false;

    final r = int.parse(match.group(1)!);
    final g = int.parse(match.group(2)!);
    final b = int.parse(match.group(3)!);

    return r >= 0 && r <= 255 && g >= 0 && g <= 255 && b >= 0 && b <= 255;
  }

  // RGBA颜色检测（专门检测 rgba(r,g,b,a) 格式）
  static bool _isRgbaColor(String value) {
    if (!_rgbaColorRegExp.hasMatch(value)) {
      return false;
    }

    final match = _rgbaColorRegExp.firstMatch(value);
    if (match == null) return false;

    final r = int.parse(match.group(1)!);
    final g = int.parse(match.group(2)!);
    final b = int.parse(match.group(3)!);
    final a = double.parse(match.group(4)!);

    final rgbInRange =
        r >= 0 && r <= 255 && g >= 0 && g <= 255 && b >= 0 && b <= 255;
    final alphaInRange = a >= 0 && a <= 1;

    return rgbInRange && alphaInRange;
  }

  // HSL颜色检测（仅检测 hsl(h,s%,l%) 格式）
  static bool _isHslColor(String value) {
    if (!_hslColorRegExp.hasMatch(value)) return false;

    final match = _hslColorRegExp.firstMatch(value);
    if (match == null) return false;

    final h = int.parse(match.group(1)!);
    final s = int.parse(match.group(2)!);
    final l = int.parse(match.group(3)!);

    return h >= 0 && h <= 360 && s >= 0 && s <= 100 && l >= 0 && l <= 100;
  }

  // HSLA颜色检测（专门检测 hsla(h,s%,l%,a) 格式）
  static bool _isHslaColor(String value) {
    if (!_hslaColorRegExp.hasMatch(value)) return false;

    final match = _hslaColorRegExp.firstMatch(value);
    if (match == null) return false;

    final h = int.parse(match.group(1)!);
    final s = int.parse(match.group(2)!);
    final l = int.parse(match.group(3)!);
    final a = double.parse(match.group(4)!);

    final hslInRange =
        h >= 0 && h <= 360 && s >= 0 && s <= 100 && l >= 0 && l <= 100;
    final alphaInRange = a >= 0 && a <= 1;

    return hslInRange && alphaInRange;
  }

  // HEX转RGB（兼容 #RGBA/#RRGGBBAA；忽略 alpha，仅返回 RGB）
  /// Converts HEX (supports #RGB/#RGBA/#RRGGBB/#RRGGBBAA) to RGB map.
  /// Returns {'r':R,'g':G,'b':B}.
  static Map<String, int> hexToRgb(String hex) {
    final color = hexToColor(hex);
    return {
      'r': _channelR(color),
      'g': _channelG(color),
      'b': _channelB(color),
    };
  }

  // RGB转HEX
  /// Converts RGB to hex string (#RRGGBB).
  static String rgbToHex(int r, int g, int b) {
    String component(int value) => value.toRadixString(16).padLeft(2, '0');
    return '#${component(r)}${component(g)}${component(b)}'.toUpperCase();
  }

  // HEX转HSL
  /// Converts HEX to HSL map: {'h':0-360,'s':0-100,'l':0-100}.
  static Map<String, double> hexToHsl(String hex) {
    final rgb = hexToRgb(hex);
    return rgbToHsl(rgb['r']!, rgb['g']!, rgb['b']!);
  }

  // RGB转HSL（修复类型与 max/min 冲突）
  /// Converts RGB to HSL map: {'h':0-360,'s':0-100,'l':0-100}.
  static Map<String, double> rgbToHsl(int r, int g, int b) {
    final rD = r / 255.0;
    final gD = g / 255.0;
    final bD = b / 255.0;

    final maxVal = [rD, gD, bD].reduce(math.max);
    final minVal = [rD, gD, bD].reduce(math.min);
    double h = 0;
    double s = 0;
    final l = (maxVal + minVal) / 2.0;

    if (maxVal != minVal) {
      final d = maxVal - minVal;
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
  /// Converts HSL (h:0-360, s/l:0-100) to RGB map.
  static Map<String, int> hslToRgb(double h, double s, double l) {
    final normalizedH = h / 360;
    final normalizedS = s / 100;
    final normalizedL = l / 100;

    double r;
    double g;
    double b;

    if (normalizedS == 0) {
      r = g = b = normalizedL; // 灰色
    } else {
      double hue2rgb(double p, double q, double t) {
        var normalizedT = t;
        if (normalizedT < 0) normalizedT += 1;
        if (normalizedT > 1) normalizedT -= 1;
        if (normalizedT < 1 / 6) return p + (q - p) * 6 * normalizedT;
        if (normalizedT < 1 / 2) return q;
        if (normalizedT < 2 / 3) return p + (q - p) * (2 / 3 - normalizedT) * 6;
        return p;
      }

      final q = normalizedL < 0.5
          ? normalizedL * (1 + normalizedS)
          : normalizedL + normalizedS - normalizedL * normalizedS;
      final p = 2 * normalizedL - q;
      r = hue2rgb(p, q, normalizedH + 1 / 3);
      g = hue2rgb(p, q, normalizedH);
      b = hue2rgb(p, q, normalizedH - 1 / 3);
    }

    return {
      'r': (r * 255).round(),
      'g': (g * 255).round(),
      'b': (b * 255).round(),
    };
  }

  // 计算颜色相似度 (Delta E 简化)
  /// Returns Euclidean distance of two colors in RGB space (smaller = closer).
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
  /// Generates [count] color variants around a base HEX color.
  static List<String> generateColorVariants(String baseColor, {int count = 5}) {
    final hsl = hexToHsl(baseColor);
    final variants = <String>[];

    for (var i = 0; i < count; i++) {
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
  /// Heuristically maps a HEX color to a human-readable Chinese color name.
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
  /// Converts a [Color] to hex string.
  /// If [includeAlpha] is true, format is #RRGGBBAA, otherwise #RRGGBB.
  /// Set [withHash] to false to omit leading '#'.
  /// Uppercase when [upperCase] is true.
  static String colorToHex(
    Color color, {
    bool includeAlpha = false,
    bool withHash = true,
    bool upperCase = false,
  }) {
    String component(int value) => value.toRadixString(16).padLeft(2, '0');
    final buffer = StringBuffer();
    if (withHash) buffer.write('#');
    buffer
      ..write(component(_channelR(color)))
      ..write(component(_channelG(color)))
      ..write(component(_channelB(color)));
    if (includeAlpha) {
      buffer.write(component(_channelA(color)));
    }
    final out = buffer.toString();
    return upperCase ? out.toUpperCase() : out;
  }

  // 16进制字符串转换为 Color（支持 #RGB/#RGBA/#RRGGBB/#RRGGBBAA，兼容无#）
  /// 标准化颜色十六进制格式
  /// 将各种格式的颜色统一转换为 #RRGGBB 格式
  static String normalizeColorHex(String color) {
    final trimmed = color.trim();

    // 如果已经是 #RRGGBB 格式，直接返回
    if (_hex6RegExp.hasMatch(trimmed)) {
      return trimmed.toUpperCase();
    }

    if (_hex8RegExp.hasMatch(trimmed)) {
      return '#${trimmed.substring(1, 7)}'.toUpperCase();
    }

    // 如果是 #RGB 格式，转换为 #RRGGBB
    if (_hex3RegExp.hasMatch(trimmed)) {
      final hex = trimmed.substring(1);
      final expanded = hex.split('').map((c) => c + c).join();
      return '#$expanded'.toUpperCase();
    }

    if (_hex4RegExp.hasMatch(trimmed)) {
      final hex = trimmed.substring(1);
      final expanded = hex.split('').map((c) => c + c).join();
      return '#${expanded.substring(0, 6)}'.toUpperCase();
    }

    // 如果没有 # 号的 6 位十六进制，添加 # 号
    if (_longHexRegExp.hasMatch(trimmed)) {
      return '#$trimmed'.toUpperCase();
    }

    if (_longHexWithAlphaRegExp.hasMatch(trimmed)) {
      return '#${trimmed.substring(0, 6)}'.toUpperCase();
    }

    // 如果是 3 位无 # 号，转换为 #RRGGBB
    if (_shortHexRegExp.hasMatch(trimmed)) {
      final expanded = trimmed.split('').map((c) => c + c).join();
      return '#$expanded'.toUpperCase();
    }

    // 其他格式（RGB/RGBA/HSL/HSLA 等）返回原值
    return trimmed;
  }

  /// 生成颜色类型的内容ID前缀
  /// 用于确保相同颜色生成相同的ID
  static String generateColorContentId(String colorHex) {
    final normalizedHex = normalizeColorHex(colorHex).toUpperCase();
    return 'color:$normalizedHex';
  }

  /// Parses HEX string to [Color]. Supports #RGB/#RGBA/#RRGGBB/#RRGGBBAA and no-# input.
  static Color hexToColor(String hex) {
    try {
      var value = hex.trim();
      if (value.startsWith('#')) value = value.substring(1);

      // 基于现有校验规则验证输入
      if (!_isHexColor('#$value')) {
        throw FormatException('Invalid hex color: $hex');
      }

      final normalized = _normalizeToArgb(value);
      final argb = int.parse(normalized, radix: ClipConstants.hexRadix);
      return Color(argb);
    } on FormatException {
      rethrow;
    } on Exception catch (e) {
      throw FormatException('Failed to parse hex color: $hex - $e');
    }
  }

  static String _normalizeToArgb(String input) {
    var value = input;
    if (_shortHexRegExp.hasMatch(value)) {
      value = value.split('').map((c) => c + c).join();
    }

    if (value.length == 6) {
      return 'FF${value.toUpperCase()}';
    }

    if (value.length == 8) {
      final rgb = value.substring(0, 6).toUpperCase();
      final alpha = value.substring(6, 8).toUpperCase();
      return '$alpha$rgb';
    }

    throw FormatException('Unsupported hex format: $input');
  }

  static int _channelR(Color color) => _channelFromUnit(color.r);
  static int _channelG(Color color) => _channelFromUnit(color.g);
  static int _channelB(Color color) => _channelFromUnit(color.b);
  static int _channelA(Color color) => _channelFromUnit(color.a);

  static int _channelFromUnit(double value) {
    final scaled = (value * 255.0).round();
    if (scaled < 0) return 0;
    if (scaled > 255) return 255;
    return scaled;
  }
}
