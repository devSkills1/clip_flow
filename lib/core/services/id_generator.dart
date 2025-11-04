import 'dart:convert';
import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/utils/color_utils.dart';
import 'package:crypto/crypto.dart';

/// 统一的ID生成服务
/// 提供一致的、基于内容的ID生成逻辑
class IdGenerator {
  IdGenerator._();

  /// 生成基于内容的唯一ID
  static String generateId(ClipType type, String? content, String? filePath, Map<String, dynamic> metadata) {
    String contentString;

    switch (type) {
      case ClipType.color:
        // 颜色类型使用标准化的颜色值
        final colorContent = content?.trim() ?? '';
        if (colorContent.isNotEmpty && ColorUtils.isColorValue(colorContent)) {
          contentString = 'color:${ColorUtils.normalizeColorHex(colorContent)}';
        } else {
          contentString = 'color:$colorContent';
        }

      case ClipType.image:
      case ClipType.file:
      case ClipType.audio:
      case ClipType.video:
        // 二进制类型使用文件名（去除时间戳）或元数据
        String fileIdentifier;

        if (filePath != null && filePath.isNotEmpty) {
          final fileName = filePath.split('/').last;
          final fileParts = fileName.split('_');
          if (fileParts.length >= 2) {
            fileIdentifier = fileParts.sublist(1).join('_');
          } else {
            fileIdentifier = fileName;
          }
        } else {
          fileIdentifier = metadata['fileName'] as String? ??
                          metadata['originalName'] as String? ??
                          'unknown_file';
        }

        contentString = '${type.name}:$fileIdentifier';

      case ClipType.text:
      case ClipType.code:
      case ClipType.url:
      case ClipType.email:
      case ClipType.json:
      case ClipType.xml:
      case ClipType.html:
      case ClipType.rtf:
        // 文本类型使用标准化内容
        final normalizedContent = content?.trim() ?? '';
        contentString = '${type.name}:$normalizedContent';
    }

    // 使用 SHA256 生成唯一ID
    final bytes = utf8.encode(contentString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 验证ID是否有效（非空且格式正确）
  static bool isValidId(String? id) {
    return id != null && id.isNotEmpty && id.length == 64;
  }

  /// 从文件路径提取文件标识（去除时间戳）
  static String extractFileIdentifier(String filePath) {
    final fileName = filePath.split('/').last;
    final fileParts = fileName.split('_');
    if (fileParts.length >= 2) {
      return fileParts.sublist(1).join('_');
    }
    return fileName;
  }
}