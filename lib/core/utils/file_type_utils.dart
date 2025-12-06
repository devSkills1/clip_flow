import 'package:clip_flow_pro/core/models/clip_item.dart';

/// 文件类型工具类
///
/// 统一管理文件扩展名分类，避免在多个地方重复定义
/// 提供文件类型检测、分类和验证功能
class FileTypeUtils {
  /// 图片文件扩展名
  static const Set<String> imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
    'svg',
    'ico',
    'tiff',
    'tif',
    'heic',
    'heif',
    'avif',
    'jxl',
  };

  /// 视频文件扩展名
  static const Set<String> videoExtensions = {
    'mp4',
    'avi',
    'mkv',
    'mov',
    'wmv',
    'flv',
    'webm',
    'm4v',
    '3gp',
    'ogv',
    'ts',
    'mts',
    'm2ts',
    'vob',
    'f4v',
    'asf',
    'rm',
    'rmvb',
    'divx',
    'xvid',
    'mpeg',
    'mpg',
    'mpe',
    'mxf',
  };

  /// 音频文件扩展名
  static const Set<String> audioExtensions = {
    'mp3',
    'wav',
    'flac',
    'aac',
    'ogg',
    'm4a',
    'wma',
    'aiff',
    'au',
    'ra',
    'amr',
    'ac3',
    'dts',
    'opus',
    'm4p',
    'm4b',
    'ape',
    'tta',
    'voc',
  };

  /// 脚本文件扩展名
  static const Set<String> scriptExtensions = {
    'sh',
    'bash',
    'zsh',
    'fish',
    'py',
    'js',
    'ts',
    'java',
    'cpp',
    'c',
    'h',
    'hpp',
    'dart',
    'jsx',
    'tsx',
    'php',
    'rb',
    'go',
    'rs',
    'swift',
    'kt',
    'scala',
    'r',
    'pl',
    'lua',
    'vim',
    'bat',
    'ps1',
  };

  /// 代码文件扩展名（用于严格检查）
  static const Set<String> codeExtensions = {
    'dart',
    'js',
    'ts',
    'jsx',
    'tsx',
    'py',
    'java',
    'cpp',
    'c',
    'h',
    'hpp',
    'cs',
    'go',
    'rs',
    'php',
    'rb',
    'swift',
    'kt',
    'scala',
    'r',
    'pl',
    'lua',
    'vim',
    'vue',
    'svelte',
    'css',
    'scss',
    'sass',
    'less',
    'sql',
    'html',
    'htm',
    'xml',
    'json',
    'yaml',
    'yml',
  };

  /// 文档文件扩展名
  static const Set<String> documentExtensions = {
    'txt',
    'md',
    'doc',
    'docx',
    'pdf',
    'rtf',
    'csv',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
  };

  /// 压缩文件扩展名
  static const Set<String> archiveExtensions = {
    'zip',
    'rar',
    'tar',
    'gz',
    '7z',
    'bz2',
    'xz',
  };

  /// 可执行文件扩展名
  static const Set<String> executableExtensions = {
    'exe',
    'msi',
    'dmg',
    'pkg',
    'deb',
    'rpm',
    'apk',
    'ipa',
  };

  /// 配置文件扩展名
  static const Set<String> configExtensions = {
    'log',
    'conf',
    'config',
    'ini',
    'env',
    'gitignore',
    'dockerfile',
    'toml',
    'properties',
    'key',
    'pem',
    'crt',
    'p12',
    'sql',
    'db',
    'sqlite',
  };

  /// 常见文件扩展名（所有类型的合集）
  static const Set<String> commonExtensions = {
    ...scriptExtensions,
    ...documentExtensions,
    ...archiveExtensions,
    ...executableExtensions,
    ...configExtensions,
  };

  static const Set<String> _specialTextFileNames = {
    'readme',
    'makefile',
    'dockerfile',
    'license',
    'changelog',
  };

  /// 检查是否为图片文件
  static bool isImageFile(String extension) {
    return imageExtensions.contains(_normalizeExtension(extension));
  }

  /// 检查是否为视频文件
  static bool isVideoFile(String extension) {
    return videoExtensions.contains(_normalizeExtension(extension));
  }

  /// 检查是否为音频文件
  static bool isAudioFile(String extension) {
    return audioExtensions.contains(_normalizeExtension(extension));
  }

  /// 检查是否为脚本文件
  static bool isScriptFile(String extension) {
    return scriptExtensions.contains(_normalizeExtension(extension));
  }

  /// 检查是否为代码文件
  static bool isCodeFile(String extension) {
    return codeExtensions.contains(_normalizeExtension(extension));
  }

  /// 检查是否为文档文件
  static bool isDocumentFile(String extension) {
    return documentExtensions.contains(_normalizeExtension(extension));
  }

  /// 检查是否为压缩文件
  static bool isArchiveFile(String extension) {
    return archiveExtensions.contains(_normalizeExtension(extension));
  }

  /// 检查是否为可执行文件
  static bool isExecutableFile(String extension) {
    return executableExtensions.contains(_normalizeExtension(extension));
  }

  /// 检查是否为配置文件
  static bool isConfigFile(String extension) {
    return configExtensions.contains(_normalizeExtension(extension));
  }

  /// 检查是否为常见文件类型
  static bool isCommonFile(String extension) {
    return commonExtensions.contains(_normalizeExtension(extension));
  }

  /// 从文件路径提取扩展名
  static String extractExtension(String filePath) {
    final trimmed = filePath.trim();
    final lastDot = trimmed.lastIndexOf('.');
    if (lastDot == -1 || lastDot == trimmed.length - 1) {
      return '';
    }
    return trimmed.substring(lastDot + 1).toLowerCase();
  }

  /// 从文件路径提取文件名（不含扩展名）
  static String extractFileName(String filePath) {
    final normalized = filePath.replaceAll(_backslashPattern, '/');
    final lastSlash = normalized.lastIndexOf('/');
    final fileName = lastSlash == -1
        ? normalized
        : normalized.substring(lastSlash + 1);
    final dotIndex = fileName.lastIndexOf('.');
    return dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
  }

  /// 根据扩展名检测文件类型（与ClipType对应）
  static ClipType detectFileTypeByExtension(String filePath) {
    final extension = extractExtension(filePath);

    if (extension.isEmpty) {
      // 处理无扩展名的特殊文件
      final fileName = extractFileName(filePath).toLowerCase();
      if (_specialTextFileNames.contains(fileName)) {
        return ClipType.text;
      }
      return ClipType.file;
    }

    if (isImageFile(extension)) return ClipType.image;
    if (isVideoFile(extension)) return ClipType.video;
    if (isAudioFile(extension)) return ClipType.audio;
    if (extension == 'html' || extension == 'htm') return ClipType.html;
    if (extension == 'json') return ClipType.json;
    if (extension == 'xml') return ClipType.xml;
    if (isCodeFile(extension)) return ClipType.code;
    if (isDocumentFile(extension)) return ClipType.text;

    return ClipType.file;
  }

  /// 根据文件内容判断是否可能为文件路径
  static bool looksLikeFilePath(String content) {
    final trimmedContent = content.trim();

    // 检查是否包含路径分隔符
    if (!trimmedContent.contains('/') &&
        !trimmedContent.contains(r'\') &&
        !trimmedContent.contains('.')) {
      return false;
    }

    // 提取扩展名并检查
    final extension = extractExtension(trimmedContent);
    if (extension.isEmpty) return false;

    // 检查是否为常见文件类型
    return isCommonFile(extension) ||
        isImageFile(extension) ||
        isVideoFile(extension) ||
        isAudioFile(extension);
  }

  /// 获取文件类型的分类
  static FileTypeCategory getFileTypeCategory(String extension) {
    final ext = _normalizeExtension(extension);

    if (isCodeFile(ext)) {
      return FileTypeCategory.code;
    }

    if (isScriptFile(ext)) {
      return FileTypeCategory.script;
    }

    if (isImageFile(ext)) {
      return FileTypeCategory.image;
    }

    if (isVideoFile(ext)) {
      return FileTypeCategory.video;
    }

    if (isAudioFile(ext)) {
      return FileTypeCategory.audio;
    }

    if (isDocumentFile(ext)) {
      return FileTypeCategory.document;
    }

    if (isArchiveFile(ext)) {
      return FileTypeCategory.archive;
    }

    if (isConfigFile(ext)) {
      return FileTypeCategory.config;
    }

    if (isCommonFile(ext)) {
      return FileTypeCategory.document;
    }

    return FileTypeCategory.other;
  }

  /// 检查文件路径是否有效（基础验证）
  static bool isValidFilePath(String filePath) {
    if (filePath.trim().isEmpty) return false;

    // 检查是否包含非法字符（基础检查）
    final invalidChars = RegExp('[<>:"|?*]');
    if (invalidChars.hasMatch(filePath)) return false;

    // 安全检查：拒绝空字节注入
    if (filePath.contains('\x00')) return false;

    // 安全检查：拒绝路径遍历攻击
    final normalized = filePath.replaceAll(r'\', '/');
    if (normalized.contains('../') || normalized.contains('/..')) {
      return false;
    }

    // 检查是否为绝对路径或相对路径
    final isAbsolutePath =
        filePath.startsWith('/') ||
        filePath.contains(r':\') ||
        filePath.startsWith('~');

    final isRelativePath =
        filePath.startsWith('./') || filePath.startsWith('../');

    return isAbsolutePath || isRelativePath;
  }

  static String _normalizeExtension(String extension) {
    return extension.trim().toLowerCase();
  }

  static final RegExp _backslashPattern = RegExp(r'\\');
}

/// 文件类型分类枚举
enum FileTypeCategory {
  /// 图片文件
  image,

  /// 视频文件
  video,

  /// 音频文件
  audio,

  /// 代码文件
  code,

  /// 脚本文件
  script,

  /// 文档文件
  document,

  /// 压缩文件
  archive,

  /// 可执行文件
  executable,

  /// 配置文件
  config,

  /// 其他类型
  other,
}
