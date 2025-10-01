# Flutter 常用命令参考手册

## 📋 目录

- [1. 代码格式化与修复](#1-代码格式化与修复)
- [2. 静态分析与检查](#2-静态分析与检查)
- [3. 测试相关](#3-测试相关)
- [4. 运行与调试](#4-运行与调试)
- [5. 构建与发布](#5-构建与发布)
- [6. 依赖管理](#6-依赖管理)
- [7. 国际化](#7-国际化)
- [8. 清理与缓存](#8-清理与缓存)
- [9. 设备与环境](#9-设备与环境)
- [10. 版本管理](#10-版本管理)
- [11. 性能与调试](#11-性能与调试)
- [12. Git 相关](#12-git-相关)
- [13. 项目特定命令](#13-项目特定命令)
- [14. 推荐高效命令组合](#14-推荐高效命令组合)

---

## 1. 代码格式化与修复

### 格式化代码
```bash
dart format lib test
# 格式化 lib 与 test 目录
```

### 自动修复
```bash
dart fix --dry-run
# 预览可自动修复的建议

dart fix --apply
# 应用可自动修复的建议
```

## 2. 静态分析与检查

### 基础分析
```bash
flutter analyze
# 运行静态分析（遵循 analysis_options.yaml）
```

### 监听模式
```bash
flutter analyze --watch
# 监听变更持续分析
```

## 3. 测试相关

### 运行测试
```bash
flutter test
# 运行所有单元/小部件测试
```

### 覆盖率测试
```bash
flutter test --coverage
# 生成覆盖率报告（默认在 coverage/ 目录）
```

### 指定测试
```bash
flutter test --plain-name "<keyword>"
# 仅运行名称包含关键字的测试
```

## 4. 运行与调试

### 基础运行
```bash
flutter run
# 运行到已连接设备或模拟器
```

### 指定平台运行
```bash
flutter run -d macos     # macOS 桌面
flutter run -d linux     # Linux 桌面
flutter run -d windows   # Windows 桌面
flutter run -d chrome    # Web 浏览器
flutter run -d ios       # iOS 设备/模拟器
flutter run -d android   # Android 设备/模拟器
```

### Web 特定选项
```bash
flutter run -d chrome --web-renderer canvaskit
# Web 使用 CanvasKit 渲染器
```

### 详细模式运行
```bash
flutter run -d macos -v
# 详细模式运行 macOS 桌面应用
```

## 5. 构建与发布

### Android 构建
```bash
flutter build apk --release
# 构建 Android APK（发布版）

flutter build appbundle --release
# 构建 Android AAB（Google Play 上架用）
```

### iOS 构建
```bash
flutter build ios --release
# 构建 iOS（需在 macOS 且 Xcode 已配置）
```

### 桌面平台构建
```bash
flutter build macos --release   # macOS
flutter build linux --release   # Linux
flutter build windows --release # Windows
```

### Web 构建
```bash
flutter build web --release
# 构建 Web 应用
```

### 详细构建
```bash
flutter build macos -v
# 详细模式构建 macOS 桌面应用
```

## 6. 依赖管理

### 基础依赖操作
```bash
flutter pub get
# 获取依赖

flutter pub upgrade
# 升级到兼容的最新版本

flutter pub outdated
# 查看可升级的依赖
```

### 全局工具
```bash
dart pub global activate melos
# 激活全局工具（以 melos 为例）
```

## 7. 国际化

```bash
flutter gen-l10n
# 根据 l10n/arb 文件生成本地化代码
```

## 8. 清理与缓存

### 清理构建产物
```bash
flutter clean
# 清理构建产物
```

### 修复缓存
```bash
flutter pub cache repair
# 修复 Pub 缓存
```

## 9. 设备与环境

### 设备管理
```bash
flutter devices
# 列出可用设备
```

### 环境检查
```bash
flutter doctor -v
# 检查开发环境配置
```

## 10. 版本管理

```bash
flutter upgrade
# 升级 Flutter SDK
```

## 11. 性能与调试

### Profile 模式
```bash
flutter run --profile
# Profile 模式运行（性能分析）
```

### 渲染跟踪
```bash
flutter run --trace-skia
# Skia 渲染跟踪（配合 DevTools 使用）
```

### Dart VM 调试
```bash
dart --observe
# Dart VM 观察/调试（特定场景使用）
```

## 12. Git 相关

### 查看变更
```bash
git diff --cached docs/TODO.md
# 查看暂存区 TODO.md 变更

git diff --cached --stat
# 查看暂存区变更统计
```

### 查看历史
```bash
git log --oneline -5 docs/TODO.md
# 查看最近 5 条 TODO.md 变更记录
```

## 13. 项目特定命令

### 查找应用
```bash
find /Applications -name "*ClipFlow*" -o -name "*clip_flow*" 2>/dev/null
# 查找 ClipFlow Pro 应用程序
```

## 14. 推荐高效命令组合

### 🔥 日常开发必备

#### 热重载开发
```bash
flutter run -d macos --hot
# 启动后在终端按 'r' 进行热重载，'R' 进行热重启
```

#### 代码质量三件套
```bash
dart format . && dart fix --apply && flutter analyze
# 一键格式化 + 修复 + 分析
```

#### 快速测试与覆盖率
```bash
flutter test --coverage && genhtml coverage/lcov.info -o coverage/html
# 运行测试并生成 HTML 覆盖率报告
```

### 🚀 项目维护组合

#### 万能清理重建
```bash
flutter clean && flutter pub get && flutter run -d macos
# 遇到奇怪问题时的解决方案
```

#### 依赖管理组合
```bash
flutter pub outdated && flutter pub upgrade
# 检查并升级过时依赖
```

#### 多平台构建检查
```bash
flutter build macos --debug && flutter build web --debug
# 确保代码在所有目标平台都能构建
```

### 💡 调试与诊断

#### 详细诊断模式
```bash
flutter run -d macos -v --verbose
# 详细模式运行，查看所有构建信息
```

#### 环境健康检查
```bash
flutter doctor -v && flutter devices
# 全面检查开发环境和可用设备
```

#### 性能分析模式
```bash
flutter run -d macos --profile
# Profile 模式，配合 DevTools 进行性能分析
```

### 🎯 ClipFlow Pro 专用

#### 剪贴板功能测试
```bash
flutter test test/clipboard_*_test.dart --reporter=expanded
# 运行所有剪贴板相关测试
```

#### 性能监控测试
```bash
flutter test test/performance_test.dart --reporter=expanded
# 运行性能测试
```

#### 集成测试
```bash
flutter test integration/ --reporter=expanded
# 运行集成测试套件
```

### 🛠️ 高级开发技巧

#### 监听模式开发
```bash
flutter analyze --watch
# 文件变化时自动进行静态分析
```

#### 构建大小分析
```bash
flutter build macos --analyze-size
# 分析应用构建大小
```

#### 国际化更新
```bash
flutter gen-l10n && flutter run -d macos
# 更新本地化文件并重新运行
```

### 💪 终极效率组合

#### 完整开发流程
```bash
flutter clean && \
flutter pub get && \
dart format . && \
dart fix --apply && \
flutter analyze && \
flutter test --coverage && \
flutter run -d macos
# 从零开始的完整开发流程
```

#### 发布前检查
```bash
flutter doctor -v && \
flutter analyze && \
flutter test && \
flutter build macos --release
# 发布前的完整验证流程
```

#### Git 工作流集成
```bash
dart format . && flutter analyze && flutter test && git add . && git commit
# 提交前的完整代码检查
```

### 🎨 推荐别名配置

在 `~/.zshrc` 或 `~/.bashrc` 中添加：

```bash
# Flutter 开发别名
alias frun="flutter run -d macos"
alias ftest="flutter test --coverage"
alias fclean="flutter clean && flutter pub get"
alias fcheck="dart format . && dart fix --apply && flutter analyze"
alias fbuild="flutter build macos --release"
alias fdev="flutter run -d macos --hot"
alias fprofile="flutter run -d macos --profile"
```

---

## 💡 使用提示

1. **开发阶段**：经常使用代码质量三件套保持代码质量
2. **测试阶段**：使用 `flutter test --coverage` 确保测试覆盖率
3. **发布前**：使用发布前检查组合验证代码质量
4. **性能优化**：使用 `flutter run --profile` 进行性能分析
5. **问题排查**：使用万能清理重建解决大部分构建问题
6. **效率提升**：配置别名减少重复输入
7. **持续集成**：结合 Git 工作流确保代码质量

---

*最后更新：2025-10-01*