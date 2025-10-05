# 崩溃监控配置指南

## 📊 当前状态

- **开发模式**: 崩溃监控已禁用（无DSN配置时）
- **生产模式**: 需要配置真实的Sentry DSN才能启用

## 🚀 快速开始

### 选项1: 使用Sentry.io（推荐）

1. **注册账号**
   - 访问 [sentry.io](https://sentry.io)
   - 注册免费账号（每月10,000个事件免费）

2. **创建项目**
   - 选择 "Flutter" 平台
   - 获取DSN地址（格式：`https://abc123@o123456.ingest.sentry.io/123456`）

3. **配置DSN**
   
   **方法A: 环境变量（推荐）**
   ```bash
   # 设置环境变量
   export SENTRY_DSN="https://your-real-dsn@sentry.io/project-id"
   
   # 运行应用
   flutter run -d macos
   ```
   
   **方法B: 直接修改代码**
   ```dart
   // 在 crash_service.dart 中替换
   options.dsn = "https://your-real-dsn@sentry.io/project-id";
   ```

### 选项2: 本地日志模式

如果不需要远程上报，可以修改为仅本地记录：

```dart
// 在 crash_service.dart 中
options.dsn = null; // 禁用远程上报
```

## 🔧 配置验证

运行应用后检查日志：

- ✅ **已配置**: 看到 "CrashService initialized successfully"
- ❌ **未配置**: 看到 "Sentry DSN not configured, crash reporting disabled"

## 📈 监控面板

配置成功后，可以在Sentry面板查看：

- 崩溃报告和错误统计
- 性能监控数据
- 用户会话信息
- 错误趋势分析

## 🔒 隐私说明

- 开发模式下默认禁用远程上报
- 敏感数据会被自动过滤
- 可以通过 `beforeSend` 回调进一步控制数据

## 🛠 故障排查

### 常见问题

1. **DSN格式错误**
   - 确保DSN以 `https://` 开头
   - 包含完整的项目ID

2. **网络连接问题**
   - 检查防火墙设置
   - 确认可以访问 sentry.io

3. **权限问题**
   - 确认Sentry项目权限
   - 检查API密钥是否有效

### 测试崩溃上报

```dart
// 手动触发测试错误
CrashService.reportError(
  Exception('Test crash report'),
  StackTrace.current,
  context: 'Manual test',
);
```

## 📝 生产环境建议

1. **设置合适的采样率**（当前：开发100%，生产10%）
2. **配置告警规则**（错误率阈值、新错误通知）
3. **定期检查错误趋势**
4. **设置团队通知渠道**（Slack、邮件等）