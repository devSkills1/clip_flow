# 验证清理机制是否正常工作

## 方法 1：查看日志

运行应用后，查看日志中是否有以下信息：

```
[DatabaseService] Starting cleanup of excess items
[DatabaseService] Current database stats
[DatabaseService] Deleting excess items
[DatabaseService] Cleanup completed successfully
```

## 方法 2：手动测试

### 步骤 1：准备测试环境
1. 打开应用
2. 复制大量内容（超过 500 条）

### 步骤 2：检查数据库
```bash
# 进入应用数据目录
cd ~/Library/Containers/com.example.clipFlowPro/Data/Documents/

# 查看数据库记录数
sqlite3 clipflow_pro.db "SELECT COUNT(*) FROM clip_items WHERE is_favorite = 0;"

# 查看媒体文件数量
ls -la media/images/ | wc -l
ls -la media/files/ | wc -l
```

### 步骤 3：修改设置
1. 打开设置页面
2. 将最大历史记录数改为 100
3. 等待几秒

### 步骤 4：再次检查
```bash
# 应该只剩下 100 条非收藏记录
sqlite3 clipflow_pro.db "SELECT COUNT(*) FROM clip_items WHERE is_favorite = 0;"

# 媒体文件也应该相应减少
ls -la media/images/ | wc -l
```

## 方法 3：代码审查清单

✅ `DatabaseService.cleanupExcessItems()` 已实现
✅ 查询时包含 `file_path` 字段
✅ 删除数据库记录
✅ 调用 `_deleteMediaFileSafe()` 删除文件
✅ 在 `preloadFromDatabase()` 中调用
✅ 在 `updateMaxHistoryLimit()` 中调用
✅ 添加了详细的日志记录
✅ 异常处理不会影响主流程

## 预期结果

### 数据库
- 非收藏项数量 ≤ maxHistoryItems
- 收藏项全部保留
- 旧记录被删除

### 文件系统
- 孤立的媒体文件被删除
- 磁盘空间被释放
- 只保留有效记录的文件

## 注意事项

1. **收藏项不受限制**
   - 即使总数超过 maxHistoryItems，收藏项也会全部保留

2. **清理是异步的**
   - 不会阻塞 UI
   - 失败不会影响应用运行

3. **安全删除**
   - 使用 `_deleteMediaFileSafe()` 确保文件删除安全
   - 即使文件不存在也不会报错
