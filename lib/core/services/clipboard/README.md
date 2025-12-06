# Clipboard 模块架构文档

## 概述

本模块遵循 **Clean Architecture** 原则，实现了剪贴板功能的分层架构。重构后的设计消除了代码重复，提高了可维护性和可测试性。

## 架构分层

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│              (UI Components & Controllers)                   │
├─────────────────────────────────────────────────────────────┤
│                    Application Layer                        │
│                 (Use Cases & Services)                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │ ClipboardService│  │ OptimizedClip-  │  │ Clipboard-   │ │
│  │                 │  │ boardProcessor  │  │ Detector     │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                     Domain Layer                            │
│              (Business Logic & Models)                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │ ClipItem        │  │ ClipboardPort   │  │ Detection-   │ │
│  │ DetectionResult │  │ Interfaces      │  │ Result       │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                Infrastructure Layer                         │
│           (External Services & Utilities)                    │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │ Native Platform │  │ File Utils      │  │ Image Utils  │ │
│  │ Integration     │  │ Content Utils   │  │ Cache Utils  │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 核心组件

### 1. 接口层 (Ports)

**文件**: `clipboard_ports.dart`

定义了所有剪贴板服务的抽象接口，遵循依赖倒置原则：

- **ClipboardServicePort**: 主要剪贴板服务接口
- **ClipboardProcessorPort**: 内容处理接口
- **ClipboardPollerPort**: 轮询管理接口
- **ClipboardDetectorPort**: 类型检测接口

### 2. 应用服务层 (Services)

#### 主要服务

- **ClipboardService**: 主要剪贴板服务，整合所有功能
- **OptimizedClipboardProcessor**: 优化后的内容处理器
- **UniversalClipboardDetector**: 通用内容检测器
- **ClipboardDetector**: 基于置信度的智能检测器

#### 设计原则

- **单一职责**: 每个服务专注于特定功能
- **依赖注入**: 通过接口进行依赖管理
- **错误处理**: 统一的异常处理机制

### 3. 领域模型层 (Models)

- **ClipItem**: 剪贴板条目核心模型
- **ClipboardDetectionResult**: 检测结果模型
- **ClipboardFormatInfo**: 格式信息模型
- **ClipboardData**: 原始剪贴板数据模型

### 4. 基础设施层 (Utils)

#### 统一工具类

- **FileTypeUtils**: 文件类型检测和分类
- **ContentDetectionUtils**: 内容类型检测
- **ImageUtils**: 图片处理和缩略图生成
- **ColorUtils**: 颜色处理和验证

## 关键改进

### 1. 消除重复逻辑

**重构前**:
```dart
// ClipboardDetector 中的硬编码扩展名
const imageExtensions = ['jpg', 'jpeg', 'png', ...];

// ImageUtils 中的重复定义
static bool isImageFile(String filePath) {
  final extension = filePath.split('.').last.toLowerCase();
  return ['jpg', 'jpeg', 'png', ...].contains(extension);
}
```

**重构后**:
```dart
// 统一使用 FileTypeUtils
ClipType detectFileType(String filePath) {
  return FileTypeUtils.detectFileTypeByExtension(filePath);
}
```

### 2. 工具类统一

**重构前**: 多处重复实现文件类型检测
**重构后**:
- `FileTypeUtils`: 所有文件类型检测逻辑
- `ContentDetectionUtils`: 所有内容检测逻辑
- `ImageUtils`: 委托给 FileTypeUtils 进行文件类型检测

### 3. 依赖关系优化

**重构前**:
```
ClipboardProcessor ──→ ImageUtils
                     ├──→ FileTypeUtils (部分使用)
                     └──→ 重复的逻辑
```

**重构后**:
```
OptimizedClipboardProcessor ──→ FileTypeUtils (统一)
                              ├──→ ContentDetectionUtils
                              ├──→ ImageUtils
                              └──→ 其他工具类
```

## 使用指南

### 基本使用

```dart
import 'package:clip_flow/core/services/clipboard/index.dart';
import 'package:clip_flow/core/utils/index.dart';

// 使用优化后的处理器
final processor = OptimizedClipboardProcessor();
final clipItem = await processor.processClipboardContent();

// 使用统一的文件类型检测
final fileType = FileTypeUtils.detectFileTypeByExtension(filePath);

// 使用内容检测工具
final isFilePath = ContentDetectionUtils.isFilePath(content);
```

### 自定义检测逻辑

```dart
// 扩展内容检测
class CustomContentDetector {
  static bool isCustomType(String content) {
    // 使用基础检测工具
    if (ContentDetectionUtils.isCodeContent(content)) {
      return false;
    }

    // 添加自定义逻辑
    return _matchesCustomPattern(content);
  }
}
```

### 性能监控

```dart
// 获取缓存统计
final stats = processor.getCacheStats();
print('缓存命中率: ${stats['hitRate']}%');

// 获取性能指标
final metrics = processor.getPerformanceMetrics();
```

## 测试策略

### 单元测试

- **工具类测试**: 测试所有检测逻辑
- **服务类测试**: 使用 Mock 对象测试业务逻辑
- **模型测试**: 测试数据转换和验证

### 集成测试

- **端到端流程测试**: 完整的剪贴板处理流程
- **性能测试**: 缓存效率和内存使用
- **平台兼容性测试**: 不同操作系统的兼容性

## 迁移指南

### 从旧版本迁移

1. **替换处理器**:
   ```dart
   // 旧版本
   final processor = ClipboardProcessor();

   // 新版本
   final processor = OptimizedClipboardProcessor();
   ```

2. **使用统一工具类**:
   ```dart
   // 旧版本
   if (ImageUtils.isImageFile(path)) { ... }

   // 新版本
   if (FileTypeUtils.isImageFile(FileTypeUtils.extractExtension(path))) { ... }
   ```

3. **更新导入**:
   ```dart
   // 使用统一导出
   import 'package:clip_flow/core/utils/index.dart';
   import 'package:clip_flow/core/services/clipboard/index.dart';
   ```

## 性能优化

### 缓存策略

- **智能缓存**: 基于内容哈希的去重缓存
- **内存管理**: 自动清理和内存使用监控
- **性能监控**: 详细的缓存效率统计

### 检测优化

- **分层检测**: 快速路径 + 详细检测
- **置信度评分**: 智能类型决策
- **早期退出**: 避免不必要的深度分析

## 未来改进

1. **异步检测**: 大文件的异步处理
2. **机器学习**: 基于ML的智能内容分类
3. **插件系统**: 可扩展的检测器插件
4. **云同步**: 跨设备的剪贴板同步

## 总结

重构后的 clipboard 模块遵循 Clean Architecture 原则，实现了：

- ✅ **消除代码重复**: 统一的文件类型和内容检测
- ✅ **清晰的职责分离**: 每个组件专注于特定功能
- ✅ **改进的依赖关系**: 通过接口解耦，使用统一工具类
- ✅ **更好的可测试性**: 模块化设计便于单元测试
- ✅ **性能优化**: 智能缓存和优化的检测流程
- ✅ **向后兼容**: 保持现有API的兼容性

这个重构为项目的长期维护和扩展奠定了坚实的基础。