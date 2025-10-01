# 文件复制到本地沙盒并保存原始文件名功能

## 功能概述

本功能实现了将剪贴板中的文件复制到应用本地沙盒目录，并尽可能保留原始文件名的功能。这样用户可以在沙盒中看到具有可读性的文件名，而不是随机生成的哈希值。

## 实现细节

### 1. 文件处理流程

当用户复制文件到剪贴板时，应用会：

1. **检测文件类型**：识别文件是图片、文档、视频等类型
2. **读取文件内容**：将原始文件读取为字节数组
3. **提取原始文件名**：从文件路径中提取原始文件名
4. **清理文件名**：去除非法字符，支持中文文件名
5. **生成唯一文件名**：结合原始名称和哈希值确保唯一性
6. **保存到沙盒**：将文件保存到 `~/Documents/media/files/` 目录

### 2. 文件名处理策略

#### 原始文件名清理规则

```dart
String sanitizedBase(String name) {
  // 去除路径分隔符，仅保留文件名部分
  final base = name.split('/').last.split(r'\').last;
  // 去掉扩展名
  final dotIndex = base.lastIndexOf('.');
  final withoutExt = dotIndex > 0 ? base.substring(0, dotIndex) : base;
  
  // 保留中文字符、字母数字、空格、横杠和下划线，其它替换为下划线
  // 支持中文字符范围：\u4e00-\u9fff
  final replaced = withoutExt.replaceAll(
    RegExp('[^A-Za-z0-9\u4e00-\u9fff _.-]'),
    '_',
  );
  
  // 将连续空格和下划线压缩
  final compact = replaced
      .replaceAll(RegExp(r'\s+'), '_')  // 空格转下划线
      .replaceAll(RegExp(r'_+'), '_')   // 连续下划线压缩
      .replaceAll(RegExp(r'^_+|_+$'), ''); // 去除首尾下划线
  
  // 如果清理后为空，使用默认名称
  if (compact.isEmpty) {
    return 'file';
  }
  
  // 限制长度，避免超长文件名，优先保留前面的字符
  return compact.length > 60 ? compact.substring(0, 60) : compact;
}
```

#### 文件名生成格式

- **保留原始名称**：`原始名_哈希值.扩展名`
- **不保留原始名称**：`type_时间戳_哈希值.扩展名`

### 3. 支持的文件名类型

#### 中文文件名
- **原始**：`测试文档.txt`
- **处理后**：`测试文档_6ae8a755.txt`

#### 英文文件名
- **原始**：`My Important Document.docx`
- **处理后**：`My_Important_Document_6ae8a755.docx`

#### 特殊字符文件名
- **原始**：`File@#$%^&*()Name.pdf`
- **处理后**：`File_Name_6ae8a755.pdf`

### 4. 目录结构

文件保存在以下目录结构中：

```
~/Documents/
└── media/
    ├── images/          # 图片文件
    │   └── 图片名_hash.jpg
    └── files/           # 其他文件
        ├── 文档名_hash.pdf
        ├── 测试文档_hash.txt
        └── My_Document_hash.docx
```

## 代码修改

### 1. 修改文件处理方法

在 `clipboard_processor.dart` 的 `_processFileContent` 方法中：

```dart
// 获取原始文件名（不包含路径）
final originalFileName = file.path.split('/').last;

relativePath = await _saveMediaToDisk(
  bytes: bytes,
  type: 'file',
  suggestedExt: ext,
  // 传入原始文件名，保留原始名称
  originalName: originalFileName,
  keepOriginalName: true,  // 关键参数
);
```

### 2. 优化文件名清理逻辑

- 支持中文字符（Unicode 范围 `\u4e00-\u9fff`）
- 更好的特殊字符处理
- 连续空格和下划线压缩
- 长度限制（60字符）

### 3. 简化文件名格式

- 移除时间戳，使用更简洁的格式
- 哈希值已足够保证唯一性
- 提高文件名可读性

## 测试验证

创建了完整的单元测试来验证功能：

```bash
flutter test test/file_copy_test.dart
```

测试结果：
```
中文文件名处理: 测试文档.txt -> 测试文档
英文文件名处理: My Important Document.docx -> My_Important_Document
特殊字符处理: File@#$%^&*()Name.pdf -> File_Name

保留中文文件名: 测试文档_6ae8a755.txt
保留英文文件名: My_Document_6ae8a755.pdf
不保留文件名: file_1759242491681_6ae8a755.jpg

生成的相对路径: media/files/test_file_12345678.txt
```

## 使用效果

### 用户体验改进

1. **可读性**：保存的文件名具有可读性，用户可以轻松识别文件内容
2. **国际化**：支持中文文件名，适合中文用户使用
3. **兼容性**：自动处理特殊字符，确保文件系统兼容性
4. **唯一性**：通过哈希值确保文件名唯一，避免冲突

### 实际应用场景

- 复制 Word 文档：`重要报告.docx` → `重要报告_a1b2c3d4.docx`
- 复制 PDF 文件：`用户手册.pdf` → `用户手册_e5f6g7h8.pdf`
- 复制图片文件：`截图.png` → `截图_i9j0k1l2.png`
- 复制代码文件：`main.dart` → `main_m3n4o5p6.dart`

## 技术特点

- **安全性**：所有文件保存在应用沙盒内，不会污染系统目录
- **性能**：使用哈希值去重，避免重复保存相同文件
- **稳定性**：完善的错误处理，文件保存失败不影响应用运行
- **可维护性**：清晰的代码结构，易于扩展和维护

## 总结

此功能成功实现了文件复制到本地沙盒并保留原始文件名的需求，提升了用户体验，特别是对中文用户的支持。通过合理的文件名清理策略和目录结构设计，确保了功能的稳定性和可用性。