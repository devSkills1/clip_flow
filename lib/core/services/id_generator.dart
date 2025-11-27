import 'dart:convert';

import 'package:clip_flow_pro/core/models/clip_item.dart';
import 'package:clip_flow_pro/core/utils/color_utils.dart';
import 'package:crypto/crypto.dart';

/// 统一的ID生成服务
/// 提供一致的、基于内容的ID生成逻辑
class IdGenerator {
  IdGenerator._();

  /// 生成基于内容的唯一ID
  static String generateId(
    ClipType type,
    String? content,
    String? filePath,
    Map<String, dynamic> metadata, {
    List<int>? binaryBytes,
  }) {
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
        // 如果有二进制数据，优先使用数据的哈希
        if (binaryBytes != null && binaryBytes.isNotEmpty) {
          final digest = sha256.convert(binaryBytes);
          contentString = '${type.name}_bytes:${digest.toString()}';
          break;
        }

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
          fileIdentifier =
              metadata['fileName'] as String? ??
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

  /// 为OCR文本生成独立ID
  ///
  /// [ocrText] OCR识别的文本内容
  /// [parentImageId] 原图片的ID，用于建立关联关系
  ///
  /// 返回基于图片ID和OCR文本内容生成的唯一ID
  static String generateOcrTextId(String ocrText, String parentImageId) {
    // 标准化OCR文本内容
    final normalizedText = _normalizeOcrText(ocrText);

    // 使用图片ID和标准化文本生成关联式ID
    final contentString = 'ocr_text:$parentImageId:$normalizedText';

    // 使用 SHA256 生成唯一ID
    final bytes = utf8.encode(contentString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 标准化OCR文本内容
  ///
  /// 移除多余的空白字符，统一换行符，截断过长的文本
  static String _normalizeOcrText(String text) {
    if (text.isEmpty) return '';

    // 移除首尾空白
    var normalized = text.trim();

    // 统一换行符
    normalized = normalized.replaceAll(RegExp(r'\r\n|\r'), '\n');

    // 将连续的空白字符替换为单个空格
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

    // 如果文本过长，进行截断（保留前10000个字符）
    const maxLength = 10000;
    if (normalized.length > maxLength) {
      normalized = '${normalized.substring(0, maxLength)}...';
    }

    return normalized;
  }

  /// 生成OCR内容的签名用于缓存比较
  ///
  /// 与generateOcrTextId不同，此方法用于快速比较OCR内容是否相同
  static String generateOcrContentSignature(String ocrText) {
    final normalizedText = _normalizeOcrText(ocrText);
    final contentString = 'ocr_signature:$normalizedText';

    final bytes = utf8.encode(contentString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
