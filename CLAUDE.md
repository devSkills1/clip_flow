# CLAUDE.md

ClipFlow Pro - 跨平台剪贴板历史管理工具开发指南

## 项目概览

**技术栈**: Flutter 3.19.0+ + Dart 3.9.0+ + Riverpod 3.0.0 + SQLite + Clean Architecture
**平台支持**: macOS, Windows, Linux
**架构模式**: Clean Architecture + 模块化服务层

## 快速开始

### 核心命令
```bash
# 环境设置
flutter pub get
flutter run --dart-define=ENVIRONMENT=development

# 构建
./scripts/build.sh dev macos        # 开发构建
./scripts/build.sh prod all         # 生产构建

# 代码质量
flutter analyze                    # 代码分析
dart format .                     # 代码格式化
flutter test                      # 运行测试
```

### 构建脚本
- `./scripts/build.sh` - 主构建脚本
- `./scripts/version-manager.sh` - 版本管理
- `./scripts/cleanup_apps.sh` - 应用清理

## 核心架构

### 服务模块组织
```
lib/core/services/
├── clipboard/          # 剪贴板监控和处理
├── analysis/           # 内容分析 (HTML, 代码, OCR)
├── storage/            # 数据持久化和加密
├── platform/           # 平台特定集成
├── performance/        # 性能监控
└── observability/      # 日志和错误处理
```

### 关键模式
- **端口适配器模式**: 每个模块定义 `*_ports.dart` 接口
- **依赖注入**: 使用 Riverpod providers
- **ID生成统一化**: 使用 `IdGenerator.generateId()` 创建所有内容ID

### 依赖关系
```
clipboard → analysis, storage, platform
analysis → platform
storage → platform/files
operations → clipboard, analysis, storage
observability ← all layers
```

## 开发标准

### 代码质量
- **静态分析**: `very_good_analysis` 规则
- **覆盖率**: 全局 ≥70%, 核心模块 ≥80%
- **格式化**: `dart format` (单引号, 尾随逗号)
- **类型安全**: 启用严格推断和强制转换

### 关键规则
- ✅ 使用 `lib/core/services/logger` - 禁止 `print()`/`debugPrint()`
- ✅ 错误处理: `try on Exception catch (e)` - 禁止通用 catch
- ✅ 异步: 优先 async/await 而非 then()
- ❌ 禁止使用 @deprecated 成员
- ❌ 禁止硬编码密钥或敏感信息
- ❌ Git 提交消息不得包含 AI/工具署名

### UI/UX 标准
- **Material 3**: 必须使用 Material Design 3
- **国际化**: 所有 UI 文本使用 gen-l10n
- **无障碍**: 支持 WCAG 2.1 AA 和 textScaleFactor 1.0-1.5
- **动画**: 150-300ms, 标准曲线, 关键操作可取消

## 性能优化

### 关键指标
- 帧时间 < 16ms (60fps 设备)
- 图片加载: 使用 `OptimizedImageLoader`
- 列表性能: `ListView.builder` + 分页
- 内存管理: 适当处置资源

### 已实现的优化
- **52%** 更快的初始加载
- **18%** 改善的滚动帧率
- **37%** 减少的内存使用
- **50%** 更快的图片加载

## 故障排除

### 热键问题
1. 检查 macOS Console.app 中的 `ClipboardPlugin` 消息
2. 验证 "Successfully registered Carbon hotkey" 消息
3. 应用具有智能热键过滤，会根据当前应用变化
4. 系统冲突时使用 `HotkeyService.resetToDefaults()` 重置

### 调试命令
```bash
# 监控 Flutter 日志
flutter run -d macos --dart-define=ENVIRONMENT=development

# 系统日志检查 (macOS)
log stream --predicate 'process == "ClipFlow Pro"' --info

# 性能分析
flutter run --profile
```

### 常见问题
- **macOS 构建失败**: 检查辅助功能权限
- **内存问题**: 使用 `OptimizedImageLoader` 处理大图片
- **列表性能**: 实现分页处理大量历史记录

## 关键架构组件

### ID生成和去重系统
- **IdGenerator**: 统一 SHA256 哈希 ID 生成
- **DeduplicationService**: 集中化去重逻辑
- **关键原则**: 仅在需要写入数据库时生成ID

### 正确流程:
```dart
// 1. 检测剪贴板内容
final detectionResult = await _universalDetector.detect(clipboardData);

// 2. 先检查缓存 (不生成ID)
if (await _isCachedByContent(tempItem)) return null;

// 3. 确定保存时才生成ID
final contentHash = IdGenerator.generateId(type, content, filePath, metadata);
```

## 测试策略

### 测试类型
- **单元测试**: 所有服务组件
- **集成测试**: 使用 `integration_test` 包
- **Widget测试**: 关键UI组件
- **Golden测试**: 视觉回归

### 运行测试
```bash
flutter test                              # 所有测试
flutter test test/integration/            # 集成测试
flutter test --coverage                   # 带覆盖率
```

## 发布流程

### 版本管理
```bash
./scripts/version-manager.sh --info       # 检查版本
./scripts/build.sh prod all              # 生产构建
```

### 发布前检查清单
- [ ] 所有测试通过
- [ ] 代码质量检查通过 (`flutter analyze`)
- [ ] 文档已更新
- [ ] 版本号已更新
- [ ] 所有平台构建测试

## 环境配置

- **开发**: `--dart-define=ENVIRONMENT=development`
- **生产**: `--dart-define=ENVIRONMENT=production`
- 配置文件位于平台目录 (如 `macos/Runner/Configs/`)

---

**文档更新触发条件**: 架构变更、主要功能实现、技术栈更新、平台特定变更、新的故障排除模式、开发工作流变更

**sub-agent 使用**: 优先使用专门的 sub-agents 处理复杂任务，特别是 flutter-expert, dart-pro, backend-architect 等具有特定专业知识的代理。