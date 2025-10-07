# 快捷键唤起应用测试指南

## 功能说明

本功能允许用户在应用最小化或隐藏后，通过快捷键迅速唤起应用窗口。

## 最新更新

- **使用Carbon API**: 现在使用Carbon API来注册全局快捷键，确保在应用后台时仍能工作
- **增强权限**: 添加了必要的系统权限，包括Apple Events支持
- **改进日志**: 增加了详细的日志记录，便于调试

## 默认快捷键

- **macOS**: `Cmd + Shift + V` (默认) 或 `Cmd + Shift + B` (当前配置)
- **Windows/Linux**: `Ctrl + Shift + V`

## 测试步骤

1. **启动应用**
   ```
   flutter run -d macos
   ```

2. **最小化应用**
   - 点击窗口左上角的黄色最小化按钮
   - 或使用窗口菜单中的最小化选项

3. **使用快捷键唤起应用**
   - 按下 `Cmd + Shift + B` (当前配置) 或 `Cmd + Shift + V` (默认)
   - 应用窗口应该会显示并聚焦到前台

4. **测试隐藏/显示切换**
   - 当应用窗口可见时，按下快捷键应该隐藏窗口
   - 当应用窗口隐藏时，按下快捷键应该显示窗口

## 调试信息

如果快捷键不工作，请检查控制台日志中的以下信息：

1. **快捷键注册日志**
   ```
   快捷键服务初始化完成
   快捷键注册成功: action=toggleWindow, key=Cmd+Shift+V
   ```

2. **Carbon API注册日志**
   ```
   ClipboardPlugin: Successfully registered Carbon hotkey for action toggleWindow with key cmd+shift+b
   ClipboardPlugin: Set up Carbon event handler
   ```

3. **快捷键触发日志**
   ```
   快捷键被按下: action=toggleWindow
   执行快捷键回调: action=toggleWindow
   toggleWindow called: isVisible=false, isMinimized=true
   显示窗口
   ```

4. **专用测试应用**
   可以使用 `test_hotkey_background.dart` 进行专门测试：
   ```bash
   flutter run test_hotkey_background.dart
   ```

## 常见问题

### 1. 快捷键不响应

- 确认使用的是正确的快捷键组合 (`Cmd + Shift + V`)
- 检查是否有其他应用占用了相同的快捷键
- 尝试重启应用
- 检查系统权限设置，确保应用有Apple Events权限

### 2. 应用最小化后无法唤起

- 检查应用是否真的最小化了，而不是关闭了
- 确认应用在后台仍在运行（检查Dock栏是否有应用图标）
- 检查Carbon API是否成功注册（查看日志）
- 确认entitlements文件中包含必要的权限

### 3. 快捷键只工作一次

- 这可能是正常的，因为快捷键会切换窗口的显示/隐藏状态
- 再次按下快捷键应该会隐藏窗口

### 4. 后台快捷键失效

- 确认使用的是Carbon API而不是NSEvent
- 检查应用是否有Apple Events权限
- 查看控制台日志中的Carbon API注册状态

## 自定义快捷键

用户可以在设置页面自定义快捷键组合：

1. 打开应用设置
2. 找到"快捷键"或"热键"选项
3. 修改"显示/隐藏窗口"的快捷键组合

## 技术实现

快捷键功能通过以下组件实现：

1. **HotkeyService**: 负责注册和处理全局快捷键
2. **TrayService**: 负责窗口的显示/隐藏逻辑
3. **WindowListener**: 负监听窗口状态变化
4. **ClipboardPlugin**: 原生端实现全局快捷键监听

### 核心技术细节

- **Carbon API**: 使用`RegisterEventHotKey`函数注册全局快捷键，确保在应用后台时仍能工作
- **事件处理**: 通过`InstallEventHandler`处理快捷键事件
- **权限管理**: 在沙盒环境中添加了`com.apple.security.automation.apple-events`权限
- **备用方案**: 保留了NSEvent监听器作为备用方案，当Carbon API注册失败时自动回退

## 故障排除

如果问题仍然存在，请尝试：

1. 完全退出应用并重新启动
2. 检查系统权限设置，确保应用有Apple Events权限
3. 重置快捷键设置为默认值
4. 查看应用日志文件获取更多错误信息
5. 检查entitlements文件是否包含必要的权限
6. 使用专用测试应用验证功能