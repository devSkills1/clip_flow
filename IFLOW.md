# ClipFlow Pro - 项目上下文文档

## 项目概述

ClipFlow Pro 是一个基于 Flutter 开发的跨平台剪贴板历史管理工具，支持 macOS、Windows 和 Linux 三大平台。该项目采用 Clean Architecture 和模块化架构设计，提供全类型剪贴板内容支持、OCR 文字识别、智能搜索等现代化功能。

### 核心技术栈

- **前端框架**: Flutter 3.19.0+ (Dart 3.9.0+)
- **状态管理**: Riverpod 3.0.0
- **数据库**: SQLite (sqflite)
- **加密**: AES-256-GCM (encrypt)
- **错误监控**: Sentry Flutter
- **国际化**: Flutter Intl
- **架构模式**: Clean Architecture + 模块化服务层

## 项目结构

### 核心目录结构

```
lib/
├── core/                           # 核心功能层
│   ├── constants/                  # 常量定义
│   ├── models/                     # 数据模型
│   ├── services/                   # 模块化服务层
│   │   ├── clipboard/              # 剪贴板模块
│   │   ├── analysis/               # 内容分析模块
│   │   ├── storage/                # 存储模块
│   │   ├── platform/               # 平台特定模块
│   │   ├── performance/            # 性能监控模块
│   │   ├── observability/          # 可观测性模块
│   │   └── operations/             # 操作模块
│   └── utils/                      # 工具类
├── features/                       # 功能模块层
│   ├── home/                       # 主界面功能
│   └── settings/                   # 设置页面功能
├── shared/                         # 共享组件层
│   ├── providers/                  # 状态管理提供者
│   └── widgets/                    # 共享组件
├── l10n/                          # 国际化资源
├── debug/                         # 调试工具
├── app.dart                       # 应用入口组件
└── main.dart                      # 主函数入口
```

### 模块化服务架构

项目采用端口接口模式设计的服务模块：

```
📦 服务层模块化架构
├── 🔄 clipboard/     # 剪贴板核心功能
│   ├── clipboard_ports.dart        # 服务接口定义
│   ├── clipboard_service.dart      # 服务协调器
│   ├── clipboard_processor.dart    # 内容处理器
│   ├── clipboard_poller.dart      # 轮询器
│   └── optimized_clipboard_manager.dart # 优化管理器
├── 🔍 analysis/      # 内容分析和语义识别  
├── 💾 storage/       # 数据存储和管理
├── 🖥️ platform/     # 平台特定系统集成
├── ⚡ performance/   # 性能监控和优化
├── 📊 observability/ # 错误处理和日志记录
└── 🔧 operations/    # 跨域业务操作
```

## 构建和运行

### 环境要求

- Flutter 3.19.0 或更高版本
- Dart 3.9.0 或更高版本
- 对应平台的开发环境

### 快速开始

1. **安装依赖**
   ```bash
   flutter pub get
   ```

2. **运行开发版本**
   ```bash
   flutter run
   ```

3. **构建发布版本**
   ```bash
   # 使用构建脚本（推荐）
   ./scripts/build.sh prod all
   
   # 或直接使用 Flutter 命令
   flutter build macos --release
   flutter build windows --release
   flutter build linux --release
   ```

### 构建脚本使用

项目提供了便捷的构建脚本 `scripts/build.sh`：

```bash
# 构建所有平台的生产版本
./scripts/build.sh prod all

# 构建特定平台的开发版本
./scripts/build.sh dev macos

# 清理后构建
./scripts/build.sh -c prod macos

# 查看帮助
./scripts/build.sh --help
```

### 测试

```bash
# 运行所有测试
flutter test

# 运行特定测试
flutter test test/clipboard_service_test.dart

# 运行集成测试
flutter test integration/
```

## 开发约定

### 代码规范

项目使用 `very_good_analysis` 代码分析规则，主要约定：

- 强制使用 `const` 构造函数
- 优先使用 `final` 而非 `var`
- 单引号字符串
- 尾随逗号要求
- 严格的类型检查
- 禁止 `print` 语句（使用日志系统）

### 架构原则

1. **Clean Architecture**: 分层架构，依赖方向由外向内
2. **模块化设计**: 按业务领域划分服务模块
3. **端口接口模式**: 通过接口定义模块边界
4. **依赖注入**: 使用 Riverpod 进行依赖管理
5. **单一职责**: 每个模块只负责特定业务领域

### 状态管理

使用 Riverpod 进行状态管理：

- `Provider`: 不可变值
- `StateNotifierProvider`: 可变状态
- `AsyncNotifierProvider`: 异步状态
- `FutureProvider`: 异步数据

### 日志和错误处理

项目集成了完整的日志系统和错误监控：

```dart
// 使用日志系统
Log.i('信息日志', tag: 'module');
Log.e('错误日志', tag: 'module', error: error);

// 错误报告
await CrashService.reportError(error, stackTrace);
```

## 关键功能模块

### 剪贴板服务

剪贴板模块是项目的核心，包含：

- `OptimizedClipboardManager`: 优化的剪贴板管理器
- `ClipboardDetector`: 内容类型检测
- `ClipboardProcessor`: 内容处理和格式化
- `ClipboardPoller`: 剪贴板轮询监听

### 存储服务

存储模块负责数据持久化：

- `DatabaseService`: SQLite 数据库操作
- `EncryptionService`: AES-256 数据加密
- `PreferencesService`: 用户偏好设置

### 平台服务

平台特定功能集成：

- `HotkeyService`: 全局快捷键
- `TrayService`: 系统托盘
- `OcrService`: OCR 文字识别
- `PermissionService`: 权限管理

## 国际化

项目支持中文和英文两种语言：

- 资源文件位置: `lib/l10n/arb/`
- 使用 Flutter Intl 生成代码
- 通过 `S.of(context).key` 访问翻译

## 性能优化

项目实施了多项性能优化措施：

- 智能缓存机制
- 异步处理队列
- 批量数据库操作
- 内存使用监控
- 性能指标追踪

## 错误监控

集成 Sentry 进行错误监控：

- 生产环境自动崩溃报告
- 错误上下文收集
- 性能监控
- 用户反馈追踪

## 开发工具

### 调试功能

项目提供了丰富的调试工具：

- `debug/clipboard_debug_page.dart`: 剪贴板调试页面
- `debug/ocr_demo.dart`: OCR 功能演示
- 性能监控覆盖层
- 详细的日志输出

### 热重载和调试

支持 Flutter 的标准热重载和调试功能：

```bash
# 启用调试模式
flutter run --debug

# 启用性能分析
flutter run --profile

# 查看性能图表
flutter run --profile --trace-startup
```

## 贡献指南

### 开发流程

1. Fork 项目仓库
2. 创建功能分支
3. 实现功能并编写测试
4. 运行代码分析和测试
5. 提交 Pull Request

### 代码提交

遵循项目的提交信息规范：

```
type(scope): description

[optional body]

[optional footer]
```

类型包括：
- `feat`: 新功能
- `fix`: 修复
- `docs`: 文档
- `style`: 格式
- `refactor`: 重构
- `test`: 测试
- `chore`: 构建

## 常见问题

### 权限问题

macOS 需要辅助功能权限来监听剪贴板：

1. 系统偏好设置 > 安全性与隐私 > 辅助功能
2. 添加 ClipFlow Pro 应用

### 构建问题

如果遇到构建问题，尝试：

```bash
# 清理项目
flutter clean
flutter pub get

# 重新构建
./scripts/build.sh -c prod all
```

### 性能问题

如果应用运行缓慢：

1. 检查性能监控覆盖层
2. 查看日志输出
3. 运行性能测试
4. 检查数据库索引