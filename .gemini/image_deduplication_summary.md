# ClipFlowPro 图片去重机制全链路分析

**分析日期**: 2025-11-27  
**版本**: 基于当前代码库

---

## 📋 概述

ClipFlowPro 实现了一套**多层次、全链路**的图片去重机制，确保相同的图片内容不会被重复保存到剪贴板历史中。该机制基于 **SHA-256 内容哈希**，贯穿从剪贴板检测到数据库存储的整个流程。

---

## 🔄 完整去重链路

### 1️⃣ **ID 生成层** - 内容哈希作为唯一标识
**文件**: `lib/core/services/id_generator.dart`

#### 核心方法
```dart
IdGenerator.generateId(
  ClipType type,
  String? content,
  String? filePath,
  Map<String, dynamic> metadata,
  {List<int>? binaryBytes}
)
```

#### 图片ID生成策略
- **优先级1**: 如果有 `binaryBytes`（图片二进制数据），直接对字节内容计算 SHA-256
  ```dart
  final digest = sha256.convert(binaryBytes);
  contentString = 'image_bytes:${digest.toString()}';
  ```
  
- **优先级2**: 使用文件路径（去除时间戳后的部分）
  ```dart
  contentString = 'image:$fileIdentifier';
  ```

- **最终**: 对 `contentString` 进行 SHA-256 哈希，生成64位十六进制字符串作为ID

#### 关键特性
- ✅ **内容驱动**: 相同的图片内容生成相同的ID
- ✅ **确定性**: 同一内容总是产生相同哈希
- ✅ **唯一性**: SHA-256 保证碰撞概率极低

---

### 2️⃣ **剪贴板处理层** - 内容检测与初步去重
**文件**: `lib/core/services/clipboard/clipboard_processor.dart`

#### 处理流程

```
剪贴板变化 
  ↓
获取原生数据 (_getNativeClipboardData)
  ↓
内容检测 (ClipboardDetector.detect)
  ↓
生成临时ClipItem
  ↓
【去重点1】生成 contentHash = IdGenerator.generateId(...)
  ↓
【去重点2】检查缓存 _isCached(contentHash)
  ├─ 命中缓存 → 调用 DeduplicationService.checkAndPrepare
  └─ 未命中 → 继续处理
  ↓
处理图片数据 (_processImageData)
  ↓
【去重点3】统一去重服务 DeduplicationService.checkAndPrepare
  ↓
返回去重后的ClipItem
```

#### 关键方法

##### `_isCached(String contentHash)`
```dart
Future<bool> _isCached(String contentHash) async {
  // 1. 检查内存缓存
  final entry = _contentCache[contentHash];
  if (entry == null) {
    // 2. 检查数据库
    final exists = await _checkDatabaseExistence(contentHash);
    if (exists) {
      _cacheHits++;
      return true;
    }
    _cacheMisses++;
    return false;
  }
  
  // 3. 检查缓存是否过期
  final now = DateTime.now();
  if (now.difference(entry.timestamp) > _cacheExpiry) {
    _contentCache.remove(contentHash);
    return false;
  }
  
  _cacheHits++;
  return true;
}
```

##### `_checkDatabaseExistence(String contentHash)`
```dart
Future<bool> _checkDatabaseExistence(String contentHash) async {
  final existingItem = await DatabaseService.instance
      .getClipItemById(contentHash);
  
  if (existingItem != null) {
    await Log.d(
      'Content hash already exists in database, skipping',
      fields: {'contentHash': contentHash},
    );
    return true;
  }
  return false;
}
```

#### 缓存配置
```dart
static const int _maxCacheSize = 100;           // 最大缓存条目数
static const Duration _cacheExpiry = Duration(hours: 24); // 缓存过期时间
static const int _maxMemoryUsage = 50 * 1024 * 1024;     // 最大内存使用量 50MB
```

---

### 3️⃣ **统一去重服务层** - 核心去重逻辑
**文件**: `lib/core/services/deduplication_service.dart`

#### 核心方法

##### `checkAndPrepare(String contentHash, ClipItem newItem)`
这是整个去重机制的核心方法：

```dart
Future<ClipItem?> checkAndPrepare(
  String contentHash,
  ClipItem newItem,
) async {
  try {
    // 【单一数据库检查】
    final existing = await _checkDatabaseExists(contentHash);
    
    if (existing != null) {
      // 找到重复项 → 更新时间戳而非创建新记录
      return existing.copyWith(
        updatedAt: DateTime.now(),
        // 合并新旧数据，保留最新信息
        thumbnail: newItem.thumbnail ?? existing.thumbnail,
        ocrText: newItem.ocrText ?? existing.ocrText,
        metadata: {...existing.metadata, ...newItem.metadata},
      );
    }
    
    // 没有重复 → 返回新项目
    return newItem;
  } catch (e) {
    // 错误时允许创建新项目，避免数据丢失
    return newItem;
  }
}
```

##### `_checkDatabaseExists(String contentHash)`
```dart
Future<ClipItem?> _checkDatabaseExists(String contentHash) async {
  final databaseService = DatabaseService.instance;
  
  // ID就是contentHash，直接查询
  final existing = await databaseService.getClipItemById(contentHash);
  
  return existing; // null = 不存在重复
}
```

#### 去重策略
- ✅ **更新而非创建**: 重复内容更新 `updatedAt` 时间戳
- ✅ **数据合并**: 保留最新的缩略图、OCR文本等
- ✅ **容错机制**: 错误时允许创建，避免数据丢失

---

### 4️⃣ **剪贴板管理层** - 再次验证
**文件**: `lib/core/services/clipboard/clipboard_manager.dart`

#### 处理流程

```dart
Future<void> _handleClipboardChange() async {
  // 处理剪贴板内容
  final clipItem = await _processor.processClipboardContent();
  if (clipItem == null) return;
  
  // 【去重点4】再次检查数据库
  final existingItem = await _database.getClipItemById(clipItem.id);
  if (existingItem != null) {
    // 更新时间戳
    final updatedItem = existingItem.copyWith(
      updatedAt: DateTime.now(),
      createdAt: DateTime.now(),  // 注意：这里同时更新了createdAt
    );
    await _database.updateClipItem(updatedItem);
    
    // 更新UI，将项目移到顶部
    _safeAddToUiStream(updatedItem);
    return;
  }
  
  // 新项目 → 加入处理队列
  await _addToProcessingQueue(clipItem);
}
```

---

### 5️⃣ **UI交互层** - 用户触发的去重
**文件**: `lib/core/utils/clip_item_card_util.dart`

#### 图片点击复制
```dart
static Future<void> handleItemTap(
  ClipItem item,
  WidgetRef ref, {
  BuildContext? context,
}) async {
  // 1. 复制到剪贴板
  await ref.read(clipboardServiceProvider).setClipboardContent(item);
  
  // 2. 更新数据库时间戳
  final updatedItem = item.copyWith(
    updatedAt: DateTime.now(),
    createdAt: DateTime.now(),
  );
  await _updateItemRecord(updatedItem);
  
  // 3. 更新UI（将项目移到顶部）
  ref.read(clipboardHistoryProvider.notifier).addItem(updatedItem);
}
```

#### OCR文本点击复制
```dart
static Future<void> handleOcrTextTap(
  ClipItem item,
  WidgetRef ref, {
  BuildContext? context,
}) async {
  // 1. 直接复制OCR文本
  await Clipboard.setData(ClipboardData(text: item.ocrText!));
  
  // 2. 更新OCR文本记录的时间戳（如果存在ocrTextId）
  if (item.ocrTextId != null) {
    final updatedOcrItem = await _updateOcrTextRecord(item);
    if (updatedOcrItem != null) {
      ref.read(clipboardHistoryProvider.notifier).addItem(updatedOcrItem);
    }
  }
}
```

---

## 🎯 OCR文本去重机制

### OCR文本ID生成
**文件**: `lib/core/services/id_generator.dart`

```dart
static String generateOcrTextId(String ocrText, String parentImageId) {
  // 标准化OCR文本
  final normalizedText = _normalizeOcrText(ocrText);
  
  // 关联式ID：图片ID + 文本内容
  final contentString = 'ocr_text:$parentImageId:$normalizedText';
  
  // SHA-256哈希
  final bytes = utf8.encode(contentString);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
```

### OCR去重流程
**文件**: `lib/core/services/deduplication_service.dart`

```dart
Future<ClipItem?> checkAndPrepareOcrText(
  String ocrText,
  ClipItem parentImageItem,
) async {
  // 1. 生成OCR文本的独立ID
  final ocrTextId = IdGenerator.generateOcrTextId(ocrText, parentImageItem.id);
  
  // 2. 检查是否已存在相同OCR文本
  final existing = await _checkDatabaseExists(ocrTextId);
  if (existing != null) {
    // 更新时间戳
    return existing.copyWith(
      updatedAt: DateTime.now(),
      isOcrExtracted: true,
    );
  }
  
  // 3. 创建新的OCR文本项目
  return ClipItem(
    id: ocrTextId,
    type: ClipType.text,
    content: ocrText,
    ocrTextId: ocrTextId,
    isOcrExtracted: true,
    metadata: {
      'source': 'ocr',
      'parentImageId': parentImageItem.id,
    },
  );
}
```

### 图片+OCR组合处理
```dart
Future<List<ClipItem>> processImageWithOcr(
  ClipItem imageItem,
  String? ocrText,
) async {
  final results = <ClipItem>[];
  
  // 1. 处理图片去重
  final processedImage = await checkAndPrepare(imageItem.id, imageItem);
  if (processedImage != null) {
    results.add(processedImage);
  }
  
  // 2. 如果有OCR文本，处理OCR去重
  if (ocrText != null && ocrText.isNotEmpty) {
    final processedOcr = await checkAndPrepareOcrText(ocrText, imageItem);
    if (processedOcr != null) {
      results.add(processedOcr);
      
      // 3. 更新图片项目的OCR状态
      if (processedImage != null) {
        final imageWithOcr = processedImage.copyWith(
          ocrText: ocrText,
          isOcrExtracted: true,
          ocrTextId: processedOcr.id,
        );
        results.removeWhere((item) => item.type == ClipType.image);
        results.add(imageWithOcr);
      }
    }
  }
  
  return results;
}
```

---

## 📊 数据库设计

### Schema说明
**文件**: `lib/core/services/storage/database/ocr_schema.sql`

#### ClipItem表OCR相关字段
```sql
ALTER TABLE clip_items ADD COLUMN ocr_text TEXT;
ALTER TABLE clip_items ADD COLUMN ocr_text_id TEXT;
ALTER TABLE clip_items ADD COLUMN is_ocr_extracted INTEGER NOT NULL DEFAULT 0;
```

#### 索引优化
```sql
CREATE INDEX idx_clip_items_ocr_text_id ON clip_items(ocr_text_id);
CREATE INDEX idx_clip_items_is_ocr_extracted ON clip_items(is_ocr_extracted);
```

#### 去重机制
- ✅ **单表设计**: 图片和OCR文本在同一条记录中
- ✅ **主键去重**: `id` (contentHash) 作为主键，天然防重
- ✅ **OCR文本ID**: `ocr_text_id` 用于OCR文本复制时的去重

---

## 🔍 去重检查点总结

| 检查点 | 位置 | 机制 | 作用 |
|-------|------|------|------|
| 1️⃣ | ClipboardProcessor | 内存缓存 | 快速拦截最近处理过的内容 |
| 2️⃣ | ClipboardProcessor | 数据库查询 | 防止应用重启后的重复 |
| 3️⃣ | DeduplicationService | 统一去重检查 | 核心去重逻辑，数据合并 |
| 4️⃣ | ClipboardManager | 二次数据库验证 | 确保持久化前不重复 |
| 5️⃣ | UI层 (handleItemTap) | 用户交互更新 | 点击时更新时间戳而非创建 |

---

## ⚙️ 缓存策略

### 内存缓存
```dart
class ClipboardProcessor {
  // 内容缓存: contentHash -> CacheEntry
  final Map<String, _CacheEntry> _contentCache = {};
  
  // 时间戳跟踪
  final Map<String, DateTime> _hashTimestamps = {};
  
  // 配置参数
  static const int _maxCacheSize = 100;
  static const Duration _cacheExpiry = Duration(hours: 24);
  static const int _maxMemoryUsage = 50 * 1024 * 1024; // 50MB
}
```

### 智能清理
```dart
void _performSmartCleanup() {
  // 按年龄和大小综合评分
  final scoreA = ageA * 0.7 + sizeA * 0.3;
  
  // 清理一半缓存
  final toRemove = entries.take(entries.length ~/ 2);
}
```

---

## 🎨 特殊情况处理

### 相同图片的不同复制
- 使用**二进制内容哈希**，确保相同图片总是生成相同ID
- 即使文件名不同，只要内容相同就会被识别为重复

### 图片点击后再复制
```
用户点击图片 → setClipboardContent
       ↓
剪贴板监控检测到变化
       ↓
ClipboardManager检查: existingItem != null
       ↓
【结果】更新updatedAt和createdAt，而非创建新记录
       ↓
UI更新，项目移到顶部
```

### OCR文本复制后的去重
```
用户点击OCR按钮 → Clipboard.setData(ocrText)
       ↓
剪贴板监控检测到文本变化
       ↓
生成contentHash（基于文本内容）
       ↓
DeduplicationService检查ocrTextId
       ↓
【结果】找到对应的OCR记录，更新时间戳
```

---

## 📈 性能监控

### 统计指标
```dart
// ClipboardProcessor中的性能监控
int _currentMemoryUsage = 0;
int _cacheHits = 0;
int _cacheMisses = 0;
DateTime? _lastCleanup;

Map<String, dynamic> getPerformanceMetrics() {
  return {
    'cache': {
      'size': _contentCache.length,
      'memoryUsage': _currentMemoryUsage,
      'hitRate': _cacheHits / (_cacheHits + _cacheMisses),
    },
  };
}
```

---

## 💡 最佳实践

### ✅ 优势
1. **多层防护**: 内存缓存 → 数据库 → 统一服务，三层去重检查
2. **内容驱动**: 基于SHA-256哈希，确保内容相同必定去重
3. **智能更新**: 重复时更新时间戳而非创建新记录
4. **数据合并**: 保留最新的缩略图、OCR文本等信息
5. **容错机制**: 出错时优先保证数据不丢失
6. **性能优化**: 内存缓存加速，批量处理降低数据库压力

### ⚠️ 注意事项
1. **createdAt更新**: 重复项会更新`createdAt`，使其出现在最前面
2. **OCR关联**: OCR文本ID与图片ID关联，确保同一图片OCR不重复
3. **缓存过期**: 24小时缓存过期，避免内存占用过大
4. **错误处理**: 去重逻辑失败时允许创建新项目

---

## 🔧 核心文件清单

| 文件 | 职责 |
|------|------|
| `id_generator.dart` | ID生成，基于内容的SHA-256哈希 |
| `clipboard_processor.dart` | 内容处理，内存缓存，初步去重 |
| `deduplication_service.dart` | 统一去重服务，核心去重逻辑 |
| `clipboard_manager.dart` | 剪贴板监控，二次验证 |
| `clip_item_card_util.dart` | UI交互，用户触发的更新 |
| `ocr_schema.sql` | 数据库Schema，OCR字段定义 |

---

## 📝 总结

ClipFlowPro 的图片去重机制是一个**完整、健壮、高效**的系统：

- 🔐 **基于内容哈希**: SHA-256确保唯一性和一致性
- 🚀 **多层检查**: 内存缓存 → 数据库 → 统一服务
- 🔄 **智能更新**: 更新时间戳而非创建重复记录
- 🎯 **OCR支持**: 独立的OCR文本去重机制
- 📊 **性能优化**: 缓存策略、批量处理、智能清理
- 🛡️ **容错设计**: 错误时优先保证数据完整性

整个机制贯穿**剪贴板检测 → 内容处理 → 去重检查 → 数据库存储 → UI更新**的完整流程，确保用户不会看到重复的剪贴板历史记录。
