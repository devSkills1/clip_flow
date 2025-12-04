# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概览

ClipFlow Pro - 跨平台剪贴板历史管理工具，基于 Flutter 3.19.0+ + Dart 3.9.0+ + Riverpod 3.0.0 + SQLite + Clean Architecture。

**架构核心**: Clean Architecture + 模块化服务层 + 端口适配器模式

## 核心开发命令

### 环境和构建
```bash
# 环境设置
flutter pub get
flutter run --dart-define=ENVIRONMENT=development

# 构建脚本
./scripts/build.sh dev macos        # 开发构建
./scripts/build.sh prod all         # 生产构建
./scripts/version-manager.sh --info # 版本检查

# 代码质量
flutter analyze                    # 代码分析
dart format .                     # 代码格式化
flutter test                      # 运行测试
```

### 测试命令
```bash
flutter test                              # 所有测试
flutter test test/integration/            # 集成测试
flutter test --coverage                   # 带覆盖率
flutter test test/unit/some_test.dart     # 单个测试文件
```

## 核心架构模式

### 模块化服务层架构
```
lib/core/services/
├── clipboard/          # 剪贴板监控和处理
├── analysis/           # 内容分析 (HTML, 代码, OCR)
├── storage/            # 数据持久化和加密
├── platform/           # 平台特定集成
│   ├── input/         # 热键和输入处理
│   ├── ui_tray/       # 系统托盘
│   ├── ocr/           # OCR 服务
│   ├── system/        # 系统权限和自启动
│   └── files/         # 文件系统操作
├── operations/         # 高级业务操作
├── performance/        # 性能监控
└── observability/      # 日志和错误处理
```

### 端口适配器模式 (Port-Adapter Pattern)
每个服务模块定义 `*_ports.dart` 接口：
- **接口定义**: 抽象端口定义模块边界
- **依赖倒置**: 高层模块不依赖低层实现
- **平台抽象**: 清晰的平台特定和共享代码分离
- **测试友好**: 便于 mock 和单元测试

### 关键依赖方向
```
clipboard → analysis, storage, platform
analysis → platform
storage → platform/files
operations → clipboard, analysis, storage (通过端口)
observability ← 所有层
platform ← 最底层 (不依赖业务服务)
```

## 关键技术模式

### 1. 统一ID生成和去重系统
**核心原则**: 仅在需要写入数据库时生成ID

```dart
// 正确流程:
// 1. 检测剪贴板内容
final detectionResult = await _universalDetector.detect(clipboardData);

// 2. 先检查缓存 (不生成ID)
if (await _isCachedByContent(tempItem)) return null;

// 3. 确定保存时才生成ID
final contentHash = IdGenerator.generateId(type, content, filePath, metadata);
```

- **IdGenerator**: SHA256 哈希统一 ID 生成
- **DeduplicationService**: 集中化去重逻辑，支持并发控制
- **竞态条件防护**: Map-based processing locks

### 2. Riverpod 高级状态管理
**关键提供者** (lib/shared/providers/app_providers.dart):
- `clipboardHistoryProvider`: StateNotifier，内存+数据库同步
- `userPreferencesProvider`: 持久化设置，系统同步
- `autoHideServiceProvider`: 窗口管理和用户交互监控
- `clipboardStreamProvider`: 实时剪贴板监控

**高级特性**:
- 预加载策略防止首屏数据空白
- 并发状态同步保持一致性
- 内存限制强制执行

### 3. 性能优化架构
- **自适应轮询**: ClipboardPollerPort 智能间隔调整
- **内存管理**: 强制历史限制，收藏优先级
- **图片优化**: OptimimizedImageLoader 大图片处理
- **并发处理**: 去重锁防止竞态条件

## 严格的开发标准

### 代码质量
- **静态分析**: `very_good_analysis` 规则严格遵循
- **覆盖率**: 全局 ≥70%, 核心模块 ≥80%
- **格式化**: `dart format` (单引号, 尾随逗号)
- **类型安全**: 严格推断和强制转换

### 禁止模式
- ❌ 使用 `print()`/`debugPrint()` - 必须使用 `lib/core/services/logger`
- ❌ 通用 `catch(e)` - 必须使用 `try on Exception catch (e)`
- ❌ 使用 `.then()` - 必须优先 `async/await`
- ❌ 使用 `@deprecated` 成员
- ❌ 硬编码密钥或敏感信息
- ❌ Git 提交消息包含 AI/工具署名
- ❌ Git 提交消息包含任何 CLAUDE、Claude Code 或相关 AI 工具信息

### UI/UX 标准
- **Material 3**: 强制使用
- **国际化**: 所有 UI 文本必须使用 gen-l10n
- **无障碍**: WCAG 2.1 AA 和 textScaleFactor 1.0-1.5 支持
- **性能**: 确保帧时间 < 16ms (60fps)

## 平台集成细节

### 应用数据存储
**关键路径**: Application Support 目录 (非 Documents)
- 使用 `PathService.instance.getApplicationSupportDirectory()`
- 设置页面"打开数据目录"功能依赖 FinderService
- 数据库、媒体文件、日志统一存储

### 热键系统
- **智能过滤**: 根据当前应用变化
- **冲突检测**: 系统冲突时使用 `HotkeyService.resetToDefaults()` 重置
- **调试点**: macOS Console.app 中检查 `ClipboardPlugin` 消息

### 窗口管理
- **自动隐藏**: AutoHideService 监控用户交互
- **激活源追踪**: 区分快捷键/托盘/无激活状态
- **系统集成**: 系统托盘和窗口监听器

## 故障排除指南

### 调试命令
```bash
# 开发环境监控
flutter run -d macos --dart-define=ENVIRONMENT=development

# macOS 系统日志
log stream --predicate 'process == "ClipFlow Pro"' --info

# 性能分析
flutter run --profile
```

### 常见问题解决
- **macOS 构建失败**: 检查辅助功能权限
- **内存问题**: 使用 `OptimizedImageLoader` 处理大图片
- **路径问题**: 确保使用 Application Support 目录
- **热键失效**: 检查系统权限和应用冲突

## 国际化架构
- **生成系统**: gen-l10n
- **回退机制**: lib/core/constants/i18n_fallbacks.dart
- **混合工具**: 支持生成和运行时翻译

## 环境配置
- **开发环境**: `--dart-define=ENVIRONMENT=development`
- **生产环境**: `--dart-define=ENVIRONMENT=production`
- **配置文件**: 平台目录 (如 `macos/Runner/Configs/`)

## 重要提醒

### 代码提交
- Git 提交消息使用中文
- 严格禁止包含任何 AI/工具署名或 CLAUDE 相关信息
- 提交前必须通过 `flutter analyze`

### 架构变更
- 更新 .gemini/project_memory.md 如有重大架构变更
- 保持端口接口模式的完整性
- 维护模块依赖方向

**sub-agent 使用**: 优先使用专门的 sub-agents 处理复杂任务，特别是 flutter-expert, dart-pro, backend-architect 等具有特定专业知识的代理。