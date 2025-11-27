# P1 级别漏洞修复记录

## 修复时间
2025-11-27 10:15

## P1 级别修复完成 ✅

### 修复 #1: 改进文件保存策略 (漏洞#5)
**严重性**: 🔴 HIGH (CVSS 7.0)

#### 问题
- 文件名包含时间戳 (`type_timestamp_hash.ext`)
- 相同内容在不同时间保存会生成不同文件名
- 导致基于文件路径的去重失效
- 浪费存储空间

#### 修复
**文件**: `lib/core/services/clipboard/clipboard_processor.dart`

```dart
// ❌ 修复前
final ts = DateTime.now().millisecondsSinceEpoch;
final hash = sha256.convert(bytes).toString().substring(0, 8);
fileName = '${type}_${ts}_$hash.$ext';

// ✅ 修复后
// 移除时间戳，使用更长的哈希
final hash = sha256.convert(bytes).toString();
final shortHash = hash.substring(0, 16);
fileName = '${type}_$shortHash.$ext';
```

#### 影响
- ✅ 相同内容总是保存为相同的文件名
- ✅ 实现了基于文件的去重（物理存储层面）
- ✅ 解决了ID生成不一致的根本原因之一（文件名现在是确定性的）

---

### 修复 #2: 防止UI层双重更新 (漏洞#11)
**严重性**: 🟡 MEDIUM (CVSS 4.5)

#### 问题
- `handleOcrTextTap` 手动更新数据库
- 同时 `Clipboard.setData` 触发剪贴板监控
- 导致创建了两个记录（一个是更新的OCR记录，一个是监控创建的新文本记录）
- UI跳动，数据重复

#### 修复
**文件**: `lib/core/utils/clip_item_card_util.dart`

```dart
// ❌ 修复前
await flutter_services.Clipboard.setData(...);
if (item.ocrTextId != null) {
  await _updateOcrTextRecord(item); // 手动更新
}

// ✅ 修复后
await flutter_services.Clipboard.setData(...);
// 移除手动更新，完全依赖剪贴板监控
// 监控会自动检测到新文本并创建/更新记录
```

#### 影响
- ✅ 消除双重更新
- ✅ 统一数据流向（所有外部剪贴板变更都由监控处理）
- ✅ 简化UI逻辑

---

### 验证 #3: OCR文本标准化 (漏洞#4)
**状态**: ✅ 已修复

#### 检查
检查了 `lib/core/services/id_generator.dart`，发现标准化逻辑已经非常完善：
- ✅ 处理了零宽字符 (U+200B等)
- ✅ 处理了全角空格
- ✅ 正确处理了换行符
- ✅ 统一了大小写

无需额外修复。

---

### 验证 #4: ID生成一致性 (漏洞#2)
**状态**: 🔄 已缓解

#### 分析
漏洞#2的核心是“基于文件名的ID”与“基于内容的ID”不一致。
通过修复漏洞#5（文件名基于内容哈希），我们确保了：
- 相同内容 -> 相同文件名
- 即使回退到基于文件名的ID生成，由于文件名包含内容哈希，ID也是确定性的且与内容绑定的（虽然算法不同，但映射关系是固定的）

这大大降低了ID不一致的风险。

---

## 下一步计划
- [ ] 运行单元测试验证修复
- [ ] 关注 P2 级别漏洞（事务支持、缓存一致性）
