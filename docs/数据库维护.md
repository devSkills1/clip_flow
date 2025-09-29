# 数据库维护和清理指南

本文档说明 ClipFlow Pro 中数据库维护功能的使用方法，特别是针对空内容数据的问题和解决方案。

## 问题背景

### 空内容数据问题

在某些情况下，数据库中可能会出现 `type` 为 `text` 但 `content` 为空或只包含空白字符的记录。这些记录的产生原因包括：

1. **剪贴板内容为空**: 用户复制了空内容或只包含空白字符的内容
2. **系统异常**: 在剪贴板监听过程中出现异常，导致内容获取失败
3. **数据传输问题**: 在数据处理管道中内容被意外清空
4. **历史数据**: 早期版本的数据验证不够严格

### 影响

- 占用不必要的存储空间
- 在界面中显示空白项目，影响用户体验
- 可能导致搜索和筛选功能异常

## 解决方案

### 1. 预防措施

#### 剪贴板内容验证

在 `ClipboardService` 中添加了内容验证逻辑：

```dart
// 验证内容是否有效（非空且不只是空白字符）
if (content.trim().isEmpty) {
  Log.d('Skipping empty content', tag: 'clipboard');
  return;
}
```

#### 监听条件改进

增强了剪贴板监听的条件判断：

```dart
if (!hasChange &&
    currentContent.isNotEmpty &&
    currentContent.trim().isNotEmpty &&  // 新增验证
    currentContent != _lastClipboardContent) {
```

### 2. 数据清理功能

#### 清理空文本记录

```dart
/// 清理空内容的文本类型数据
Future<int> cleanEmptyTextItems() async {
  final deletedCount = await _database!.delete(
    ClipConstants.clipItemsTable,
    where: "type = 'text' AND (content IS NULL OR TRIM(content) = '')",
  );
  return deletedCount;
}
```

#### 统计空数据

```dart
/// 获取空内容的文本数据统计
Future<int> countEmptyTextItems() async {
  final result = await _database!.rawQuery(
    "SELECT COUNT(*) as count FROM ${ClipConstants.clipItemsTable} "
    "WHERE type = 'text' AND (content IS NULL OR TRIM(content) = '')",
  );
  return (result.first['count'] as int?) ?? 0;
}
```

#### 综合数据验证

```dart
/// 验证并修复数据完整性
Future<Map<String, int>> validateAndRepairData() async {
  final stats = <String, int>{};
  
  // 清理空文本内容
  stats['emptyTextItemsDeleted'] = await cleanEmptyTextItems();
  
  // 清理孤儿媒体文件
  stats['orphanFilesDeleted'] = await cleanOrphanMediaFiles();
  
  // 统计当前数据
  stats['totalItemsRemaining'] = await getTotalItemCount();
  
  return stats;
}
```

## 使用方法

### 开发者选项

在设置页面的开发者选项中（需要先激活开发者模式），提供了以下功能：

#### 1. 清理空数据

- **位置**: 设置 → 开发者选项 → 清理空数据
- **功能**: 删除所有空内容的文本记录
- **操作**: 点击后会弹出确认对话框，确认后执行清理
- **结果**: 显示清理的记录数量

#### 2. 验证数据完整性

- **位置**: 设置 → 开发者选项 → 验证数据完整性
- **功能**: 执行全面的数据库清理和验证
- **包含操作**:
  - 清理空文本记录
  - 清理孤儿媒体文件
  - 统计剩余数据
- **结果**: 显示详细的清理统计信息

### 激活开发者模式

1. 进入设置页面
2. 找到"关于"部分的"版本"选项
3. 连续点击版本信息 7 次
4. 系统会提示"开发者模式已激活"
5. 开发者选项部分会出现在设置页面中

## 最佳实践

### 定期维护

建议定期执行数据库维护，特别是：

1. **应用更新后**: 验证数据完整性
2. **存储空间不足时**: 清理无用数据
3. **性能下降时**: 检查并清理数据库
4. **用户反馈界面异常时**: 验证数据完整性

### 数据备份

在执行清理操作前，建议：

1. 确保应用数据已备份（如果有备份功能）
2. 在测试环境中验证清理效果
3. 记录清理前的数据统计

### 监控指标

可以通过以下方式监控数据质量：

1. 定期检查空数据数量
2. 监控数据库文件大小变化
3. 观察用户界面异常反馈

## 技术细节

### SQL 查询

清理空数据使用的 SQL 语句：

```sql
DELETE FROM clip_items 
WHERE type = 'text' AND (content IS NULL OR TRIM(content) = '');
```

统计空数据的 SQL 语句：

```sql
SELECT COUNT(*) as count FROM clip_items 
WHERE type = 'text' AND (content IS NULL OR TRIM(content) = '');
```

### 事务处理

所有数据库操作都在事务中执行，确保数据一致性：

- 清理操作是原子性的
- 失败时自动回滚
- 提供详细的操作日志

### 性能考虑

- 使用索引优化查询性能
- 批量操作减少数据库访问
- 异步执行避免阻塞 UI

## 故障排查

### 常见问题

1. **清理操作失败**
   - 检查数据库文件权限
   - 确认数据库未被其他进程锁定
   - 查看应用日志获取详细错误信息

2. **清理后数据丢失**
   - 检查清理条件是否过于宽泛
   - 验证备份数据的完整性
   - 联系技术支持

3. **性能影响**
   - 在低峰时段执行清理操作
   - 分批处理大量数据
   - 监控系统资源使用情况

### 日志查看

相关日志可以在以下位置查看：

- **应用日志**: `~/Documents/logs/`
- **数据库操作**: 搜索 `DatabaseService` 相关日志
- **清理操作**: 搜索 `cleanEmptyTextItems` 和 `validateAndRepairData`

## 更新历史

- **v1.0.0**: 初始实现数据库清理功能
- **v1.0.1**: 添加预防性验证逻辑
- **v1.0.2**: 完善开发者选项界面

## 相关文档

- [Finder集成功能](./FINDER_INTEGRATION.md)
- [项目开发规则](./.codebuddy/.rules/flutter-rule.mdc)
- [架构决策记录](./docs/decisions/)