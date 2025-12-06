# ClipFlow Pro - 跨平台剪贴板历史管理工具

一个现代化的跨平台剪贴板历史管理工具，支持 Mac、Windows 和 Linux。基于 Flutter 开发，提供极简、极速、全类型的剪贴板管理体验。

## ✨ 特性

### 🎯 核心能力

- **多类型捕获**：`ClipType` 覆盖文本、富文本 (RTF/HTML)、颜色、图片与缩略图、代码/JSON/XML、URL/邮箱、文件、音频/视频等，结合 `ClipItem` 元数据记录来源、尺寸、MIME、收藏状态与 OCR 结果。
- **智能处理链路**：`ClipboardDetector → ClipboardPoller → ClipboardProcessor → ClipboardService` 负责检测、轮询、去重与存储；配合 `DeduplicationService`、LRU缓存、`DatabaseService` 和 AES-256-GCM 加密，保证写入可靠且安全。
- **OCR 管线**：`OcrServiceFactory` 在 macOS (Vision)、Windows (WinRT) 与 Linux (Tesseract) 间切换，实现多语言识别、置信度过滤、边界框追踪，并可在设置页切换语言/阈值。
- **收藏与快速操作**：历史记录支持收藏、删除确认、OCR 文本复制、缩略图查看以及根据 `HotkeyAction` 快速粘贴/暂停监听/清空历史等操作。

### 🎨 用户体验

- **双模式界面**：`DynamicHomePage` 可在经典模式与紧凑模式间切换，后者提供模糊背景、横向卡片、键鼠导航与自动隐藏协同。
- **响应式布局与多显示模式**：`ResponsiveHomeLayout` 支持紧凑/标准/预览三种卡片模式、1-3 列网格、自适应间距及时间线式统计信息，保证信息密度与可读性。
- **搜索与筛选**：`EnhancedSearchBar`、类型过滤、日期区间与收藏筛选共同作用，配合 OCR 文本索引实现跨类型搜索；`ClipItemCard` 展示关键信息与操作。
- **窗口/托盘协作**：`AutoHideService` 根据热键唤醒后的交互自动隐藏窗口，`TrayService` 和 `WindowManagementService` 负责托盘菜单、最小化到托盘与窗口参数控制，`AutostartService` 提供开机自启动。
- **设置与国际化**：设置页可调整主题、显示语言、热键、自动隐藏、最大历史条数、OCR 语言与开发者模式；所有 UI 字符串均来自 `AppLocalizations`，同时保留英文/中文。

### 🔧 技术特性

- **Clean Architecture + Riverpod**：`core/services` 按领域拆分（clipboard/storage/platform/observability/...），`features/*` 承载 UI 流程，Riverpod 提供可测试的依赖注入与 `Notifier` 状态管理。
- **安全存储**：`DatabaseService`+`EncryptionService` 在 SQLite 中落地数据、缩略图、OCR 文本与偏好；`IdGenerator` 和 `DeduplicationService` 保证记录唯一。
- **平台桥接**：Hotkey、Tray、Window、Autostart、Finder、Permission、File I/O 等服务通过 `platform/*` 统一封装，所有 `MethodChannel` 调用集中在具体适配层并带异常处理。
- **可观测性与性能**：`logger` 支持结构化日志、敏感字段过滤与本地 CrashService 记录；`PerformanceService`、`ClipboardProcessorMetrics`、`ClipboardPollerStats` 等指标用于冷启动与滚动帧率监控。
- **测试矩阵**：`test/` 下覆盖剪贴板、OCR、热键、性能、端到端与集成测试，并由 `test/test_runner.dart` 记录推荐执行顺序；支持 `flutter test --coverage` 输出覆盖率。

## 🚀 快速开始

### 环境要求

- Flutter 3.19.0 或更高版本
- Dart 3.9.0 或更高版本
- 支持的操作系统：macOS 10.15+、Windows 10+、Ubuntu 18.04+
- 剪贴板权限（macOS 需要辅助功能权限）

### 安装步骤

1. **克隆项目**

```bash
git clone https://github.com/devSkills1/clip_flow_pro.git
cd clip_flow_pro
```

2. **安装依赖**

```bash
flutter pub get
```

3. **运行项目**

```bash
# 开发模式
flutter run

# 构建发布版本
flutter build macos
flutter build windows
flutter build linux
```

### 平台特定配置

#### macOS

```bash
# 启用桌面支持
flutter config --enable-macos-desktop

# 构建 macOS 应用
flutter build macos
```

#### Windows

```bash
# 启用桌面支持
flutter config --enable-windows-desktop

# 构建 Windows 应用
flutter build windows
```

#### Linux

```bash
# 安装依赖
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev

# 启用桌面支持
flutter config --enable-linux-desktop

# 构建 Linux 应用
flutter build linux
```

### 构建脚本

项目提供了便捷的构建脚本：

```bash
# 构建发布版本（包含签名）
./scripts/build.sh

# 构建 macOS DMG 安装包
./scripts/build.sh --dmg

# 清理构建缓存
./scripts/build.sh --clean

# 版本管理
./scripts/version-manager.sh --version
```

## 📖 使用说明

### 基本功能

1. **剪贴板监听**：应用启动后 `ClipboardService` 自动初始化，跨平台捕获文本、富文本、媒体及文件，权限不足时会在日志中提示。
2. **历史记录与模式切换**：`DynamicHomePage` 支持经典模式与紧凑模式两种布局；前者展示时间线、缩略图、上下文菜单，后者适合全屏快速切换。
3. **搜索与筛选**：顶部搜索栏提供即时关键字过滤，配合类型筛选、日期区间、收藏状态、显示模式和排序偏好快速定位目标；OCR 文本同样可搜索。
4. **收藏与快速粘贴**：在卡片上收藏关键片段，避免被自动清理；使用 `HotkeyAction.quickPaste` 或卡片的“复制/粘贴”操作，即可将历史内容写回系统剪贴板。
5. **OCR 文字识别**：点击图片条目的 OCR 操作或触发对应快捷键即可调用原生 OCR 引擎，识别结果会写入 `ClipItem.ocrText` 并可复制。

### 快捷键

| 功能 | 默认快捷键 (macOS) | 说明 |
| --- | --- | --- |
| 显示/隐藏窗口 | `Cmd + Option + \`` | 由 `HotkeyAction.toggleWindow` 控制，可自定义并在自动隐藏模式下保持 1-30 秒可见时间。
| 快速粘贴最近一项 | `Cmd + Ctrl + V` | 直接将最近的剪贴项写回系统剪贴板后粘贴。
| 显示历史记录 | `Cmd + F9` | 快速进入历史列表视图。
| 搜索剪贴板内容 | `Cmd + Shift + F` | 聚焦搜索栏并开启极简搜索面板。
| OCR 文字识别 | `Cmd + F8` | 对当前剪贴板中的图片执行 OCR。

> Windows / Linux 默认将 `Cmd` 映射为 `Ctrl`、`Option` 映射为 `Alt`，更多快捷键说明见 [docs/SHORTCUTS.md](docs/SHORTCUTS.md)。

### 高级功能

1. **系统托盘与自动隐藏**：支持最小化到托盘、托盘菜单操作与后台运行；热键唤起后若无交互，`AutoHideService` 会按偏好设置自动隐藏窗口。
2. **设置与偏好**：设置页提供主题/语言切换、开机自启、最大历史条数、OCR 语言 & 置信度、自动隐藏时间、热键录制与开发者模式开关。
3. **数据安全**：可在偏好中关闭/开启 AES 加密与自动清理策略；文件与媒体通过 `PathService` 组织在沙盒内，避免泄露。
4. **可观测性**：支持日志导出、本地崩溃记录、性能覆盖层与 `Logger` 级别开关，便于诊断问题。

## 📁 项目结构

```
lib/
├── core/                           # 核心功能
│   ├── constants/                  # 常量定义
│   ├── models/                     # 数据模型
│   ├── services/                   # 服务层（模块化架构）
│   │   ├── clipboard/              # 剪贴板模块
│   │   │   ├── clipboard_ports.dart        # 剪贴板服务接口
│   │   │   ├── clipboard_service.dart      # 剪贴板服务协调器
│   │   │   ├── clipboard_processor.dart    # 内容处理器
│   │   │   ├── clipboard_poller.dart      # 轮询器
│   │   │   ├── clipboard_detector.dart    # 内容检测器
│   │   │   └── index.dart                 # 模块导出
│   │   ├── analysis/               # 分析模块
│   │   │   ├── analysis_ports.dart        # 分析服务接口
│   │   │   ├── content_analyzer.dart      # 内容分析器
│   │   │   ├── html_analyzer.dart         # HTML 分析器
│   │   │   ├── code_analyzer.dart         # 代码分析器
│   │   │   └── index.dart                 # 模块导出
│   │   ├── storage/                # 存储模块
│   │   │   ├── storage_ports.dart         # 存储服务接口
│   │   │   ├── database_service.dart      # 数据库服务
│   │   │   ├── encryption_service.dart    # 加密服务
│   │   │   ├── preferences_service.dart   # 偏好设置服务
│   │   │   ├── path_service.dart          # 路径服务
│   │   │   └── index.dart                 # 模块导出
│   │   ├── platform/               # 平台模块
│   │   │   ├── platform_ports.dart        # 平台服务接口
│   │   │   ├── system/                    # 系统服务
│   │   │   │   ├── permission_service.dart    # 权限服务
│   │   │   │   ├── autostart_service.dart     # 自启动服务
│   │   │   │   ├── finder_service.dart       # Finder 服务
│   │   │   │   └── window_listener.dart      # 窗口监听
│   │   │   ├── input/                      # 输入服务
│   │   │   │   └── hotkey_service.dart       # 热键服务
│   │   │   ├── ocr/                        # OCR 服务
│   │   │   │   ├── ocr_service.dart         # OCR 接口
│   │   │   │   └── native_ocr_impl.dart     # 原生实现
│   │   │   ├── ui_tray/                    # 托盘服务
│   │   │   │   └── tray_service.dart        # 系统托盘
│   │   │   └── index.dart                   # 模块导出
│   │   ├── performance/            # 性能模块
│   │   │   ├── performance_ports.dart       # 性能服务接口
│   │   │   ├── performance_service.dart    # 性能监控服务
│   │   │   ├── async_processing_queue.dart # 异步处理队列
│   │   │   └── index.dart                  # 模块导出
│   │   ├── observability/          # 可观测性模块
│   │   │   ├── observability_ports.dart    # 可观测性服务接口
│   │   │   ├── error_handler.dart          # 错误处理器
│   │   │   ├── crash_service.dart          # 崩溃监控服务
│   │   │   ├── logger/                     # 日志系统
│   │   │   │   ├── logger.dart             # 日志服务
│   │   │   │   └── adapters/               # 日志适配器
│   │   │   └── index.dart                  # 模块导出
│   │   └── operations/              # 操作模块
│   │       ├── operations_ports.dart       # 操作服务接口
│   │       ├── update_service.dart         # 更新服务
│   │       └── index.dart                  # 模块导出
│   └── utils/                      # 工具类
├── features/                       # 功能模块
│   ├── classic/                    # 经典模式界面
│   │   ├── data/                   # 数据层
│   │   ├── domain/                 # 领域层
│   │   └── presentation/           # 表现层
│   ├── compact/                    # 紧凑模式界面
│   │   └── presentation/           # 表现层
│   └── settings/                   # 设置页面
├── shared/                         # 共享组件
│   ├── widgets/                    # 共享组件
│   ├── providers/                  # 状态管理
│   └── constants/                  # 常量定义
├── l10n/                          # 国际化
├── debug/                         # 调试工具
├── app.dart                       # 应用入口
└── main.dart                      # 主入口
```

## 🛠️ 开发指南

### 架构模式

项目采用 **Clean Architecture** 和 **模块化架构** 的组织方式：

- **Core Layer**：核心业务逻辑和数据模型
  - **模块化服务层**：按业务领域划分的服务模块
  - **端口接口设计**：每个模块定义清晰的接口边界
  - **依赖方向控制**：避免循环依赖，确保架构清晰
- **Feature Layer**：按功能模块组织的 UI 和业务逻辑
- **Shared Layer**：跨功能模块共享的组件和工具

#### 服务模块架构

```
📦 服务层模块化架构
├── 🔄 clipboard/     # 剪贴板核心功能
├── 🔍 analysis/      # 内容分析和语义识别  
├── 💾 storage/       # 数据存储和管理
├── 🖥️ platform/     # 平台特定系统集成
├── ⚡ performance/   # 性能监控和优化
├── 📊 observability/ # 错误处理和日志记录
└── 🔧 operations/    # 跨域业务操作
```

#### 依赖方向

```
clipboard → analysis, storage, platform
analysis → platform
storage → platform/files
operations → clipboard, analysis, storage (通过端口)
observability ← 所有层 (可被所有层使用)
platform ← 最底层 (不依赖业务服务)
```

### 状态管理

使用 **Riverpod** 进行状态管理，提供：

- 类型安全的状态管理
- 依赖注入
- 响应式编程
- 测试友好的架构

### 服务模块设计原则

#### 端口接口模式

每个服务模块都采用 **端口接口模式**：

- **端口接口** (`*_ports.dart`)：定义模块对外暴露的接口
- **实现类**：实现对应的端口接口
- **依赖注入**：通过接口而非具体实现进行依赖注入
- **测试友好**：便于 mock 和单元测试

#### 模块边界

- **单一职责**：每个模块只负责特定的业务领域
- **接口隔离**：模块间通过接口进行交互
- **依赖倒置**：依赖抽象而非具体实现
- **统一导出**：每个模块提供 `index.dart` 进行统一导出

### 数据库设计

使用 **SQLite** 作为本地数据库，支持：

- 剪贴板项目存储
- 元数据索引
- 全文搜索
- 数据加密
- OCR 文本存储
- 批量操作优化

### UI组件架构

#### 现代化组件设计

项目采用现代化的UI组件架构，确保最佳的用户体验：

- **ResponsiveHomeLayout**：响应式网格布局管理器
  - 支持1-3列动态调整
  - 基于屏幕尺寸自适应布局
  - 网格间距和边距智能计算

- **ClipItemCard**：优化的卡片组件
  - 防止布局溢出的约束系统
  - 统计信息和元数据的时间行整合
  - 多种显示模式（紧凑、标准、预览）
  - 内容滚动和溢出处理

- **EnhancedSearchBar**：增强搜索组件
  - 实时搜索建议
  - 一键清除并隐藏建议
  - Material Design 3风格设计

#### 布局优化策略

- **约束管理**：使用ConstrainedBox和BoxConstraints控制尺寸
- **弹性布局**：Flexible和Expanded的合理使用
- **滚动处理**：SingleChildScrollView防止内容溢出
- **性能优化**：const构造器和智能重建边界

## 🧪 测试与质量

- 运行 `flutter analyze`、`dart format --output=none --set-exit-if-changed` 与 `flutter test --coverage` 作为合并前的基础门禁。
- `test/test_runner.dart` 记录了推荐的测试编排，覆盖单元、集成、性能与端到端用例，可用于本地或 CI 自定义执行。
- `test/` 目录内提供剪贴板、OCR、热键、性能、去重、媒体、多平台 Smoke Test 等 suites，mock 了 clipboard/OCR/storage 依赖，避免直接调用平台 API。
- 覆盖率报告生成在 `coverage/lcov.info`，可配合 `genhtml` 等工具生成可视化报告。

## 📋 开发计划

### MVP (v1.0) - 已完成 ✅

- [x] 基础项目架构
- [x] 剪贴板监听服务
- [x] 数据模型设计
- [x] UI 界面框架
- [x] 数据库集成
- [x] 加密服务
- [x] 平台特定功能
- [x] OCR 文字识别
- [x] 快捷键系统
- [x] 系统托盘集成
- [x] 国际化支持
- [x] 错误监控系统

### v1.1 - 稳定化与发布准备（进行中）

- [x] 响应式布局优化
- [x] 搜索交互改进
- [x] UI 性能与自动隐藏体验
- [ ] 跨平台 CI/CD（Flutter Analyze/Test/Build + 制品上传）
- [ ] 应用与托盘图标、品牌资源及 `Info.plist` 配置
- [ ] 核心服务单元测试 ≥80% + 性能/端到端门禁
- [ ] macOS 签名/公证、Windows 安装器与 Linux 包装脚本
- [ ] `CHANGELOG.md` 与版本脚本、发布流程文档

### v1.2 - 协作与高级功能（规划中）

- [ ] 云同步服务（iCloud/OneDrive/自建服务）
- [ ] 团队协作与角色权限
- [ ] 高级搜索语法与多条件筛选
- [ ] 批量操作与导出增强


> 更多需求与改进 TODO 汇总可参考 [docs/requirements_optimization_todo.md](docs/requirements_optimization_todo.md)。

## 🤝 贡献指南

我们欢迎所有形式的贡献！请查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解详情。

### 开发流程

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 📊 项目状态

### 当前版本：v1.0.0

- ✅ **核心功能完成**：剪贴板监听、数据库存储、OCR 识别、快捷键系统
- ✅ **跨平台支持**：macOS、Windows、Linux 三端构建成功
- ✅ **性能优化**：智能缓存、批量操作、内存管理优化
- ✅ **用户体验**：Material Design 3 界面、国际化支持、错误监控
- ✅ **UI优化**：响应式布局、防溢出设计、统计信息整合
- ✅ **搜索改进**：实时建议、一键清除、交互优化
- ✅ **架构重构**：模块化服务层、端口接口设计、依赖方向控制

### 技术栈

- **前端框架**：Flutter 3.19.0
- **状态管理**：Riverpod 3.0.0
- **数据库**：SQLite (sqflite)
- **加密**：AES-256-GCM (encrypt)
- **日志**：自定义日志系统 + CrashService（本地）
- **国际化**：Flutter Intl
- **构建工具**：Flutter Build + 自定义脚本
- **架构模式**：Clean Architecture + 模块化服务层
- **设计模式**：端口接口模式 + 依赖注入

### 测试覆盖

- 单元测试：核心服务组件
- 集成测试：端到端功能验证
- 性能测试：内存使用和响应时间
- 平台测试：三端兼容性验证

## 🙏 致谢

- [Flutter](https://flutter.dev/) - 跨平台开发框架
- [Riverpod](https://riverpod.dev/) - 状态管理
- [SQLite](https://www.sqlite.org/) - 数据库引擎
- [Material Design](https://material.io/) - 设计系统
- [Flutter Intl](https://github.com/localizely/flutter-intl-intellij) - 国际化工具

## 📞 联系我们

- 项目主页：https://github.com/devSkills1/clip_flow_pro
- 问题反馈：https://github.com/devSkills1/clip_flow_pro/issues
- 邮箱：jr.lu.jobs@gmail.com

---

**ClipFlow Pro** - 让剪贴板管理更简单、更高效！ ✨
