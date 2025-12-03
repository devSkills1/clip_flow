# 自动隐藏功能改进

## 需求概述

1. **开启自动隐藏开关后要求进入 setting_page 也不隐藏**
2. **设置回到 home_page 或者 app_switcher_page 都要继续隐藏**
3. **自动隐藏时间要求能设置**
4. **用户交互（鼠标移动、滚动）应重置自动隐藏定时器**

## 最终实现方案

### 核心设计原则

**完全依赖页面生命周期管理，不使用全局状态 provider**

- ❌ 不再使用 `settingsVisibleProvider`
- ✅ 使用页面的 `initState` 和 `dispose` 生命周期
- ✅ 在 `initState` 中保存 provider 引用，避免在 `dispose` 中使用 `ref`
- ✅ 添加用户交互监听（鼠标移动、滚动）

### 1. Settings 页面不触发自动隐藏

#### 实现方式

**文件**: `lib/features/settings/presentation/pages/settings_page.dart`

```dart
class _SettingsPageState extends ConsumerState<SettingsPage> {
  // 保存服务引用，以便在 dispose 中安全使用
  late final AutoHideService _autoHideService;
  late final bool _autoHideEnabled;

  @override
  void initState() {
    super.initState();
    
    // 保存引用以便在 dispose 中使用（避免在 dispose 中使用 ref）
    _autoHideService = ref.read(autoHideServiceProvider);
    _autoHideEnabled = ref.read(userPreferencesProvider).autoHideEnabled;

    // 停止自动隐藏定时器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _autoHideService.stopMonitoring();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 确保在设置页面中自动隐藏始终处于停止状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _autoHideService.stopMonitoring();
    });
  }

  @override
  void dispose() {
    // 使用保存的引用，不使用 ref（符合 Riverpod 最佳实践）
    if (_autoHideEnabled) {
      _autoHideService.startMonitoring();
    }
    super.dispose();
  }
}
```

#### 关键点

1. **在 `initState` 中保存引用**：避免在 `dispose` 中使用 `ref`
2. **`didChangeDependencies` 确保停止**：防止被其他逻辑意外重新启动
3. **`dispose` 中恢复监控**：使用保存的引用，不使用 `ref`

### 2. 返回 home_page 或 app_switcher_page 时恢复自动隐藏

#### 实现方式

**文件**: 
- `lib/features/home/presentation/pages/home_page.dart`
- `lib/features/appswitcher/presentation/pages/app_switcher_page.dart`

```dart
@override
void initState() {
  super.initState();
  
  // 在页面初始化时检查并启动自动隐藏监控
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    final autoHideEnabled = ref.read(userPreferencesProvider).autoHideEnabled;
    if (autoHideEnabled) {
      ref.read(autoHideServiceProvider).startMonitoring();
    }
  });
}
```

#### 关键点

1. **只在 `initState` 中启动**：避免在 `didChangeDependencies` 中被意外触发
2. **检查 `autoHideEnabled`**：只在用户开启时启动
3. **使用 `addPostFrameCallback`**：确保在 UI 渲染完成后执行

### 3. 用户交互重置定时器

#### 实现方式

在 `home_page.dart` 和 `app_switcher_page.dart` 中添加用户交互监听：

```dart
/// 处理用户交互，重置自动隐藏定时器
void _onUserInteraction() {
  ref.read(autoHideServiceProvider).onUserInteraction();
}

@override
Widget build(BuildContext context) {
  // 包装在 MouseRegion 和 Listener 中以捕获用户交互
  return MouseRegion(
    onHover: (_) => _onUserInteraction(),
    child: Listener(
      onPointerDown: (_) => _onUserInteraction(),
      onPointerMove: (_) => _onUserInteraction(),
      onPointerSignal: (_) => _onUserInteraction(), // 捕获滚动事件
      child: Scaffold(
        // ... 页面内容
      ),
    ),
  );
}
```

#### 捕获的用户交互

- ✅ 鼠标悬停 (`onHover`)
- ✅ 鼠标按下 (`onPointerDown`)
- ✅ 鼠标移动 (`onPointerMove`)
- ✅ 滚动事件 (`onPointerSignal`)

### 4. AutoHideService 简化

**文件**: `lib/core/services/operations/auto_hide_service.dart`

```dart
/// 检查自动隐藏功能是否启用
/// 只检查用户偏好设置，不再检查页面状态
/// 页面状态由各页面的生命周期方法控制（startMonitoring/stopMonitoring）
bool get _isEnabled {
  return _ref.read(userPreferencesProvider).autoHideEnabled;
}
```

#### 关键改进

- ❌ 移除了对 `settingsVisibleProvider` 的依赖
- ✅ 只检查用户偏好设置
- ✅ 页面状态由各页面自己管理

### 5. 自动隐藏时间可设置

#### 5.1 添加国际化字符串

**中文 (app_zh.arb)**：
```json
"generalAutoHideTimeoutTitle": "自动隐藏延迟",
"generalAutoHideTimeoutSubtitle": "无操作后 {seconds} 秒自动隐藏"
```

**英文 (app_en.arb)**：
```json
"generalAutoHideTimeoutTitle": "Auto-hide delay",
"generalAutoHideTimeoutSubtitle": "Hide after {seconds} seconds of inactivity"
```

#### 5.2 添加设置方法

在 `UserPreferencesNotifier` 中：

```dart
/// 设置自动隐藏超时时间（秒）。
void setAutoHideTimeout(int seconds) {
  final clamped = seconds.clamp(3, 30);
  state = state.copyWith(autoHideTimeoutSeconds: clamped);
  unawaited(_savePreferences());
}
```

#### 5.3 在设置页面添加滑块控件

```dart
if (preferences.autoHideEnabled) ...[ 
  ListTile(
    title: Text(l10n?.generalAutoHideTimeoutTitle ?? '自动隐藏延迟'),
    subtitle: Text('无操作后 ${preferences.autoHideTimeoutSeconds} 秒自动隐藏'),
    trailing: SizedBox(
      width: 220,
      child: Slider(
        value: preferences.autoHideTimeoutSeconds.toDouble(),
        min: 3,
        max: 30,
        divisions: 27,
        label: '${preferences.autoHideTimeoutSeconds}秒',
        onChanged: (v) {
          ref.read(userPreferencesProvider.notifier)
              .setAutoHideTimeout(v.round());
        },
      ),
    ),
  ),
],
```

## 完整工作流程

```
应用启动:
├─ HomePage initState
├─ 检查 autoHideEnabled
└─ 如果开启 → startMonitoring() ✅

用户在主页:
├─ 鼠标移动 → onUserInteraction() → 重置定时器 ✅
├─ 滚动页面 → onUserInteraction() → 重置定时器 ✅
└─ 无操作超时 → 自动隐藏 ✅

用户打开设置:
├─ SettingsPage initState
├─ 保存 _autoHideService 和 _autoHideEnabled
├─ stopMonitoring() ✅
└─ didChangeDependencies 确保停止 ✅

用户在设置页面:
└─ 监控保持停止状态，不会自动隐藏 ✅

用户关闭设置:
├─ SettingsPage dispose
├─ 使用保存的 _autoHideEnabled 检查
├─ 使用保存的 _autoHideService.startMonitoring()
└─ 重新启动监控 ✅

回到主页:
├─ 监控已恢复
├─ 用户交互重置定时器
└─ 自动隐藏功能正常工作 ✅
```

## 技术细节

### 自动隐藏时间范围
- **最小值**：3 秒
- **最大值**：30 秒
- **步进**：1 秒（27 个分段）
- **默认值**：3 秒

### Riverpod 最佳实践

1. ✅ **在 `initState` 中保存 provider 引用**
2. ✅ **在 `dispose` 中使用保存的引用，不使用 `ref`**
3. ✅ **避免在 `dispose` 中使用 `addPostFrameCallback` + `ref`**
4. ✅ **使用 `mounted` 检查确保 widget 仍然有效**

### 状态管理
- 使用 Riverpod 的 `StateNotifier` 管理用户偏好
- 自动持久化到本地存储
- 实时更新 UI

## 修改的文件列表

### 核心服务
1. `lib/core/services/operations/auto_hide_service.dart`
   - 简化 `_isEnabled` getter
   - 增强日志记录
   - 移除 `settingsVisibleProvider` 依赖

### UI 页面
2. `lib/features/settings/presentation/pages/settings_page.dart`
   - 添加 `_autoHideService` 和 `_autoHideEnabled` 字段
   - 在 `initState` 中保存引用
   - 在 `dispose` 中安全地恢复监控
   - 添加超时滑块控件

3. `lib/features/home/presentation/pages/home_page.dart`
   - 在 `initState` 中启动监控
   - 添加 `_onUserInteraction()` 方法
   - 使用 `MouseRegion` 和 `Listener` 捕获用户交互

4. `lib/features/appswitcher/presentation/pages/app_switcher_page.dart`
   - 在 `initState` 中启动监控
   - 添加 `_onUserInteraction()` 方法
   - 使用 `MouseRegion` 和 `Listener` 捕获用户交互

### 国际化
5. `lib/l10n/arb/app_zh.arb` - 添加中文字符串
6. `lib/l10n/arb/app_en.arb` - 添加英文字符串
7. `lib/core/constants/i18n_fallbacks.dart` - 添加回退字符串

### 状态管理
8. `lib/shared/providers/app_providers.dart` - 添加 `setAutoHideTimeout` 方法

## 测试建议

### 1. Settings 页面不隐藏
- 开启自动隐藏
- 进入设置页面
- 等待超时时间（例如 10 秒）
- ✅ 验证窗口不会自动隐藏

### 2. 返回主页面恢复隐藏
- 从设置页面返回 home_page
- 等待超时时间
- ✅ 验证窗口自动隐藏
- 同样测试 app_switcher_page

### 3. 用户交互重置定时器
- 在主页面移动鼠标
- ✅ 验证定时器被重置
- 滚动页面
- ✅ 验证定时器被重置

### 4. 超时时间可调节
- 在设置中调整超时时间（3-30秒）
- 返回主页面
- ✅ 验证新的超时时间生效

### 5. 无 Riverpod 错误
- 打开设置页面
- 关闭设置页面
- ✅ 验证控制台没有 "Using ref when widget is disposed" 错误

## 用户体验改进

1. **直观的设置界面**：滑块控件提供直观的时间调节体验
2. **实时反馈**：滑块标签显示当前选择的秒数
3. **合理的范围**：3-30秒的范围满足大多数使用场景
4. **智能显示**：仅在启用自动隐藏时显示超时设置
5. **无缝切换**：在不同页面间切换时自动隐藏行为保持一致
6. **响应式交互**：鼠标移动和滚动都会重置定时器
7. **稳定可靠**：遵循 Riverpod 最佳实践，无内存泄漏和错误

## 已知问题和解决方案

### ❌ 问题 1: 在 `dispose` 中使用 `ref`
**错误**: `Bad state: Using "ref" when a widget is about to or has been unmounted is unsafe`

**解决方案**: 在 `initState` 中保存 provider 引用到字段，在 `dispose` 中使用保存的引用

### ❌ 问题 2: `didChangeDependencies` 被意外触发
**现象**: 打开设置页面时，HomePage 的 `didChangeDependencies` 也被触发，导致重新启动监控

**解决方案**: 移除 `didChangeDependencies` 中的启动逻辑，只在 `initState` 中启动一次

### ❌ 问题 3: 设置页面仍然自动隐藏
**现象**: 即使停止了监控，设置页面仍然会自动隐藏

**解决方案**: 在 `didChangeDependencies` 中也调用 `stopMonitoring()`，确保即使页面重建也保持停止状态

## 总结

本次改进完全重构了自动隐藏功能的实现方式：

- ✅ 移除了全局状态 `settingsVisibleProvider`
- ✅ 使用页面生命周期管理自动隐藏状态
- ✅ 遵循 Riverpod 最佳实践
- ✅ 添加完整的用户交互监听
- ✅ 提供可配置的超时时间
- ✅ 详细的日志记录便于调试
- ✅ 稳定可靠，无内存泄漏和错误

**实现更简洁、更可靠、更符合 Flutter 和 Riverpod 的最佳实践。**