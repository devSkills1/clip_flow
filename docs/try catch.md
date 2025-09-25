# Dart 异常处理规范

## 异常处理最佳实践

### 1. 异常捕获格式规范

**强制使用：**
```dart
try {
  // 可能抛出异常的代码
} on Exception catch (e) {
  // 处理异常
}
```

**禁止使用：**
```dart
try {
  // 可能抛出异常的代码
} catch (e) {
  // 处理异常 - 不推荐
}
```

### 2. Exception 类型详解

#### 2.1 常见 Exception 类型

| Exception 类型 | 使用场景 | 示例 |
|---|---|---|
| `FormatException` | 数据格式解析错误 | JSON 解析、数字转换、日期解析 |
| `StateError` | 状态错误 | 在错误状态下调用方法 |
| `RangeError` | 索引越界 | 数组访问越界、字符串截取越界 |
| `ArgumentError` | 参数错误 | 传入无效参数值 |
| `UnsupportedError` | 不支持的操作 | 平台不支持的功能 |
| `ConcurrentModificationError` | 并发修改错误 | 在迭代过程中修改集合 |
| `TimeoutException` | 超时异常 | 网络请求、异步操作超时 |
| `SocketException` | 网络异常 | 网络连接失败、DNS 解析失败 |
| `FileSystemException` | 文件系统异常 | 文件不存在、权限不足、磁盘空间不足 |
| `HttpException` | HTTP 异常 | HTTP 请求失败、状态码错误 |

#### 2.2 特定场景的 Exception 处理

##### 网络请求场景
```dart
try {
  final response = await http.get(Uri.parse(url));
  return response.body;
} on SocketException catch (e) {
  // 网络连接问题
  logger.error('网络连接失败: $e');
  return null;
} on HttpException catch (e) {
  // HTTP 错误
  logger.error('HTTP 请求失败: $e');
  return null;
} on TimeoutException catch (e) {
  // 请求超时
  logger.error('请求超时: $e');
  return null;
} on FormatException catch (e) {
  // 响应格式错误
  logger.error('响应格式错误: $e');
  return null;
} on Exception catch (e) {
  // 其他未知异常
  logger.error('未知异常: $e');
  return null;
}
```

##### 文件操作场景
```dart
try {
  final file = File(path);
  final content = await file.readAsString();
  return content;
} on FileSystemException catch (e) {
  // 文件系统错误
  if (e.osError?.errorCode == 2) {
    logger.error('文件不存在: $path');
  } else if (e.osError?.errorCode == 13) {
    logger.error('权限不足: $path');
  } else {
    logger.error('文件系统错误: $e');
  }
  return null;
} on FormatException catch (e) {
  // 文件内容格式错误
  logger.error('文件内容格式错误: $e');
  return null;
} on Exception catch (e) {
  // 其他异常
  logger.error('读取文件异常: $e');
  return null;
}
```

##### JSON 解析场景
```dart
try {
  final jsonData = jsonDecode(jsonString);
  return MyModel.fromJson(jsonData);
} on FormatException catch (e) {
  // JSON 格式错误
  logger.error('JSON 格式错误: $e');
  return null;
} on TypeError catch (e) {
  // 类型转换错误
  logger.error('类型转换错误: $e');
  return null;
} on Exception catch (e) {
  // 其他异常
  logger.error('JSON 解析异常: $e');
  return null;
}
```

##### 数据库操作场景
```dart
try {
  final result = await database.query('users', where: 'id = ?', whereArgs: [id]);
  return result.isNotEmpty ? User.fromMap(result.first) : null;
} on DatabaseException catch (e) {
  // 数据库错误
  logger.error('数据库操作失败: $e');
  return null;
} on FormatException catch (e) {
  // 数据格式错误
  logger.error('数据格式错误: $e');
  return null;
} on Exception catch (e) {
  // 其他异常
  logger.error('数据库查询异常: $e');
  return null;
}
```

### 3. 异常处理原则

#### 3.1 异常捕获优先级
1. **具体异常类型** - 优先捕获具体的异常类型
2. **通用 Exception** - 最后捕获通用的 Exception
3. **避免捕获所有异常** - 不要使用 `catch (e)` 捕获所有异常

#### 3.2 异常处理策略
- **记录日志** - 所有异常都应该记录到日志系统
- **用户友好提示** - 向用户显示友好的错误信息
- **优雅降级** - 在异常情况下提供备用方案
- **资源清理** - 确保在异常情况下正确清理资源

#### 3.3 异常传播
```dart
// 重新抛出异常
try {
  await riskyOperation();
} on FormatException catch (e) {
  logger.error('格式错误: $e');
  rethrow; // 重新抛出给上层处理
}

// 包装异常
try {
  await externalService();
} on Exception catch (e) {
  throw ServiceException('外部服务调用失败', e);
}
```

### 4. 项目中的异常处理规范

#### 4.1 剪贴板服务异常处理
```dart
// 剪贴板访问异常
try {
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  return data?.text;
} on Exception catch (_) {
  // 忽略剪贴板访问错误，避免影响主流程
  return null;
}

// 平台通道调用异常
try {
  final result = await _platformChannel.invokeMethod('getClipboardImage');
  return result;
} on Exception catch (_) {
  // 平台不支持时返回 null
  return null;
}
```

#### 4.2 文件操作异常处理
```dart
// 文件保存异常
try {
  await file.writeAsBytes(data, flush: true);
} on FileSystemException catch (e) {
  logger.error('文件保存失败: ${e.path}');
  throw StorageException('文件保存失败', e);
} on Exception catch (e) {
  logger.error('未知文件操作异常: $e');
  throw StorageException('文件操作失败', e);
}
```

### 5. 测试中的异常处理

#### 5.1 异常测试
```dart
test('should throw FormatException for invalid JSON', () async {
  expect(
    () => jsonDecode('invalid json'),
    throwsA(isA<FormatException>()),
  );
});

test('should handle FileSystemException gracefully', () async {
  when(() => mockFile.readAsString())
      .thenThrow(FileSystemException('File not found'));
  
  final result = await service.readFile('invalid_path');
  expect(result, isNull);
});
```

#### 5.2 Mock 异常
```dart
// Mock 网络异常
when(() => mockHttpClient.get(any()))
    .thenThrow(SocketException('Network error'));

// Mock 文件系统异常
when(() => mockFile.readAsString())
    .thenThrow(FileSystemException('Permission denied'));
```

### 6. 性能考虑

#### 6.1 异常处理性能
- **避免频繁异常** - 不要使用异常控制正常流程
- **预检查** - 在可能抛出异常前进行预检查
- **异常缓存** - 对于重复的异常，考虑缓存处理结果

#### 6.2 异步异常处理
```dart
// 异步操作异常处理
Future<void> performAsyncOperation() async {
  try {
    await longRunningTask();
  } on TimeoutException catch (e) {
    logger.error('操作超时: $e');
    // 执行清理操作
    await cleanup();
  } on Exception catch (e) {
    logger.error('异步操作失败: $e');
    // 执行清理操作
    await cleanup();
    rethrow;
  }
}
```

### 7. 监控和调试

#### 7.1 异常监控
- 使用结构化日志记录异常
- 集成错误监控服务（如 Sentry）
- 设置异常告警阈值

#### 7.2 调试技巧
```dart
try {
  await riskyOperation();
} on Exception catch (e, stackTrace) {
  logger.error('操作失败', error: e, stackTrace: stackTrace);
  // 在开发环境中打印详细堆栈
  if (kDebugMode) {
    print('异常详情: $e');
    print('堆栈跟踪: $stackTrace');
  }
}
```

---

## 总结

遵循这些异常处理规范可以：
- 提高代码的健壮性和可维护性
- 提供更好的用户体验
- 便于问题定位和调试
- 确保系统的稳定性

记住：**异常处理不是错误处理，而是优雅地处理意外情况**。
