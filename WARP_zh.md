# WARP.md

此文件为 WARP (warp.dev) 在处理此存储库代码时提供指导。

## 项目概述
ClipFlow Pro 是一个使用 Flutter 构建的跨平台剪贴板历史管理工具。它支持 macOS、Windows 和 Linux，具有 Material Design 3 UI，并提供带有 AES-256 加密的安全剪贴板监控。

## 架构

### 高级结构
项目遵循**清洁架构**和**功能优先**的组织方式：

- **核心层** (`lib/core/`): 业务逻辑、模型和服务
- **功能层** (`lib/features/`): UI 和按域组织的功能特定业务逻辑
- **共享层** (`lib/shared/`): 跨功能组件、提供者和工具

### 关键组件

#### 状态管理
- 使用 **Riverpod** 进行响应式状态管理
- 主要提供者在 `lib/shared/providers/app_providers.dart` 中：
  - `clipboardHistoryProvider`: 使用 `ClipboardHistoryNotifier` 管理剪贴板历史
  - `userPreferencesProvider`: 用户设置和首选项
  - `themeModeProvider`: 应用主题（系统/浅色/深色）
  - `routerProvider`: GoRouter 配置

#### 核心服务
- **ClipboardService** (`lib/core/services/clipboard_service.dart`): 
  - 使用自适应轮询（200ms-2s 间隔）监控剪贴板变化
  - 支持文本、图片、颜色、文件、音频、视频
  - 实现内容缓存和基于哈希的去重
  - 使用平台通道进行系统剪贴板访问
- **DatabaseService**: 基于 SQLite 的存储，支持加密
- **EncryptionService**: 敏感数据的 AES-256 加密
- **PreferencesService**: 用户首选项持久化

#### 数据模型
- **ClipItem** (`lib/core/models/clip_item.dart`): 表示剪贴板条目的核心数据模型
  - 支持 8 种内容类型：文本、rtf、html、图片、颜色、文件、音频、视频
  - 包含媒体内容的元数据、缩略图和文件路径
  - 不可变，使用 copyWith 模式

#### 平台集成
- 使用 `window_manager` 和 `tray_manager` 进行桌面窗口管理
- 使用 `path_provider` 进行跨平台文件系统访问
- 通过方法通道进行平台特定的剪贴板监控

## 开发命令

### 环境设置
```bash
# 启用桌面平台（首次）
flutter config --enable-macos-desktop --enable-windows-desktop --enable-linux-desktop

# 安装依赖
flutter pub get
```

### 运行应用程序
```bash
# 在特定平台上运行
flutter run -d macos
flutter run -d windows
flutter run -d linux
flutter run -d chrome  # Web（如果启用）

# 开发模式，支持热重载
flutter run --hot
```

### 构建发布版本
```bash
# macOS (.app 包)
flutter build macos --release

# Windows (可执行文件)
flutter build windows --release

# Linux (可执行文件包)
flutter build linux --release

# Web (静态文件)
flutter build web --release
```

### 代码质量
```bash
# 静态分析（遵循 very_good_analysis 规则）
flutter analyze

# 格式化代码
dart format lib test

# 自动修复问题
dart fix --apply

# 运行测试
flutter test

# 运行带覆盖率的测试
flutter test --coverage

# 运行特定测试
flutter test --plain-name "关键词"
```

### 国际化
```bash
# 从 ARB 文件生成本地化文件
flutter gen-l10n
```

### 清理和维护
```bash
# 清理构建工件
flutter clean

# 修复 pub 缓存
flutter pub cache repair

# 检查环境
flutter doctor -v

# 列出可用设备
flutter devices
```

## 项目特定指南

### 代码组织
- 添加新功能时遵循现有的功能优先结构
- 将共享小部件放在 `lib/shared/widgets/`
- 将新提供者添加到 `lib/shared/providers/app_providers.dart`
- 使用单例模式将服务保持在 `lib/core/services/` 中

### 状态管理模式
- 对复杂状态使用 Riverpod StateNotifierProvider
- 对简单状态值使用 StateProvider
- 在 StateNotifiers 中实现适当的释放
- 遵循现有的提供者命名约定（例如，`featureNameProvider`）

### 性能考虑
- ClipboardService 实现自适应轮询以减少 CPU 使用
- 使用基于哈希的去重进行内容缓存以防止重复
- 图片缩略图异步生成，有大小限制
- 对重计算（哈希、图像处理）使用 Isolates

### 平台特定实现
- macOS: 全局热键需要辅助功能权限
- Windows: 系统托盘功能的 UAC 兼容性
- Linux: 依赖 GTK3 和桌面环境兼容性
- 对特定操作系统的剪贴板操作使用平台通道

### 安全性
- 永远不要在代码或数据库中存储加密密钥
- 使用系统密钥链/凭据管理器进行密钥存储
- 只加密内容字段，保持元数据可搜索
- 为敏感剪贴板数据实现安全删除

### 测试
- 测试位于 `test/` 目录
- 包括服务和模型的单元测试
- 使用冒烟测试进行基本功能验证
- 剪贴板监控效率的性能测试

### 分发构建
- macOS: 使用 Xcode 进行代码签名和公证
- Windows: 考虑使用 NSIS/Inno Setup 制作安装程序
- Linux: 根据需要打包为 AppImage、DEB 或 RPM
- 使用 `--build-name` 和 `--build-number` 进行版本控制

### 开发工具
- 开发者模式中提供性能监控覆盖
- 使用 Flutter DevTools 进行调试和分析
- 在应用设置中启用开发者模式以获得额外的调试功能

## 文件结构参考
```
lib/
├── core/                    # 核心业务逻辑
│   ├── constants/          # 应用常量和主题
│   ├── models/            # 数据模型（ClipItem 等）
│   ├── services/          # 核心服务（剪贴板、数据库等）
│   └── utils/             # 工具函数
├── features/              # 功能模块（首页、搜索、设置）
├── shared/                # 共享组件
│   ├── providers/         # Riverpod 提供者
│   └── widgets/           # 可重用 UI 组件
├── l10n/                  # 国际化
├── app.dart               # 应用配置和主题
└── main.dart              # 应用程序入口点
```

## 依赖项
- **flutter_riverpod**: 状态管理
- **go_router**: 导航和路由
- **sqflite**: 本地 SQLite 数据库
- **window_manager**: 桌面窗口管理
- **tray_manager**: 系统托盘集成
- **clipboard**: 基本剪贴板访问（由平台通道补充）
- **encrypt**: 敏感数据的 AES 加密
- **very_good_analysis**: 严格的代码检查规则