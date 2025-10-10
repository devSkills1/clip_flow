# ClipFlow Pro - 跨平台剪贴板历史管理工具

一个现代化的跨平台剪贴板历史管理工具，支持 Mac、Windows 和 Linux。基于 Flutter 开发，提供极简、极速、全类型的剪贴板管理体验。

## ✨ 特性

### 🎯 核心功能

- **全类型支持**：文本、富文本、图片、颜色、文件、音频、视频、代码、HTML、RTF
- **智能搜索**：全文搜索、类型过滤、实时筛选
- **多显示模式**：紧凑、默认、预览三种布局
- **OCR 识别**：图片文字识别（macOS Vision、Windows WinRT、Linux Tesseract）
- **安全加密**：AES-256 加密存储敏感数据

### 🎨 用户体验

- **现代化界面**：Material Design 3 + 自定义主题
- **全局快捷键**：可自定义快捷键配置，快速访问剪贴板历史
- **系统托盘**：后台运行，随时可用
- **拖拽支持**：直接拖拽到其他应用
- **批量操作**：多选、批量导出、批量删除
- **国际化**：支持中文、英文界面

### 🔧 技术特性

- **跨平台**：基于 Flutter，支持 Mac/Windows/Linux
- **高性能**：SQLite 数据库 + 智能缓存 + 性能监控
- **模块化**：Clean Architecture + Feature-First 组织方式
- **响应式**：Riverpod 状态管理
- **类型安全**：完整的 Dart 类型定义
- **错误监控**：集成 Sentry 错误追踪

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

1. **剪贴板监听**

   - 应用启动后自动开始监听剪贴板变化
   - 支持文本、图片、文件等多种类型
   - 自动识别内容类型并分类存储

2. **历史记录管理**

   - 查看所有剪贴板历史记录
   - 按类型筛选（文本、图片、文件等）
   - 搜索和过滤功能

3. **快捷键操作**

   - 默认快捷键：`Cmd+Shift+V`（macOS）/ `Ctrl+Shift+V`（Windows/Linux）
   - 可在设置中自定义快捷键
   - 支持全局快捷键调用

4. **OCR 文字识别**
   - 自动识别图片中的文字
   - 支持多种图片格式
   - 识别结果可搜索和复制

### 高级功能

1. **系统托盘**

   - 应用最小化到系统托盘
   - 右键托盘图标快速访问功能
   - 支持开机自启动

2. **数据安全**

   - 本地加密存储敏感数据
   - 支持数据导出和导入
   - 可设置自动清理策略

3. **性能监控**
   - 实时性能指标显示
   - 内存使用监控
   - 错误日志记录

## 📁 项目结构

```
lib/
├── core/                           # 核心功能
│   ├── constants/                  # 常量定义
│   ├── models/                     # 数据模型
│   ├── services/                   # 服务层
│   │   ├── clipboard_service.dart  # 剪贴板监听服务
│   │   ├── database_service.dart   # 数据库服务
│   │   ├── encryption_service.dart # 加密服务
│   │   ├── hotkey_service.dart     # 快捷键服务
│   │   ├── ocr_service.dart        # OCR 识别服务
│   │   └── logger/                 # 日志系统
│   └── utils/                      # 工具类
├── features/                       # 功能模块
│   ├── home/                       # 主界面
│   │   ├── data/                   # 数据层
│   │   ├── domain/                 # 领域层
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

项目采用 **Clean Architecture** 和 **Feature-First** 的组织方式：

- **Core Layer**：核心业务逻辑和数据模型
- **Feature Layer**：按功能模块组织的 UI 和业务逻辑
- **Shared Layer**：跨功能模块共享的组件和工具

### 状态管理

使用 **Riverpod** 进行状态管理，提供：

- 类型安全的状态管理
- 依赖注入
- 响应式编程
- 测试友好的架构

### 数据库设计

使用 **SQLite** 作为本地数据库，支持：

- 剪贴板项目存储
- 元数据索引
- 全文搜索
- 数据加密
- OCR 文本存储
- 批量操作优化

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

### v1.1 - 功能完善（进行中）

- [ ] 云同步服务（iCloud/OneDrive）
- [ ] 团队协作功能
- [ ] 高级搜索和筛选
- [ ] 批量操作优化
- [ ] 应用图标和品牌资源
- [ ] CI/CD 自动化构建

### v2.0 - AI 增强（计划中）

- [ ] AI 摘要功能
- [ ] 智能标签生成
- [ ] 内容分类优化
- [ ] 智能推荐系统

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

### 技术栈

- **前端框架**：Flutter 3.19.0
- **状态管理**：Riverpod 3.0.0
- **数据库**：SQLite (sqflite)
- **加密**：AES-256-GCM (encrypt)
- **日志**：自定义日志系统 + Sentry
- **国际化**：Flutter Intl
- **构建工具**：Flutter Build + 自定义脚本

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
- [Sentry](https://sentry.io/) - 错误监控平台
- [Flutter Intl](https://github.com/localizely/flutter-intl-intellij) - 国际化工具

## 📞 联系我们

- 项目主页：https://github.com/devSkills1/clip_flow_pro
- 问题反馈：https://github.com/devSkills1/clip_flow_pro/issues
- 邮箱：jr.lu.jobs@gmail.com

---

**ClipFlow Pro** - 让剪贴板管理更简单、更高效！ ✨
