# Flutter Useful Commands 常用命令

## Format 格式化
```bash
dart format lib test
# 格式化 lib 与 test 目录
```
```bash
dart fix --dry-run
dart fix --apply
# 预览并应用可自动修复的建议
```

## Analyze & Lint 静态检查
```bash
flutter analyze
# 运行静态分析（遵循 analysis_options.yaml）
```
```bash
flutter analyze --watch
# 监听变更持续分析
```

## Test 测试
```bash
flutter test
# 运行所有单元/小部件测试
```
```bash
flutter test --coverage
# 生成覆盖率（默认在 coverage/）
```
```bash
flutter test --plain-name "<keyword>"
# 仅运行名称包含关键字的测试
```

## Run 运行
```bash
flutter run
# 运行到已连接设备或模拟器
```
```bash
flutter run -d macos   # macOS 桌面
flutter run -d linux   # Linux 桌面
flutter run -d windows # Windows 桌面
flutter run -d chrome  # Web
flutter run -d ios     # iOS
flutter run -d android # Android
```
```bash
flutter run -d chrome --web-renderer canvaskit
# Web 使用 CanvasKit 渲染
```

## Build 构建
```bash
flutter build apk --release
# 构建 Android APK（发布）
```
```bash
flutter build appbundle --release
# 构建 Android AAB（发布上架用）
```
```bash
flutter build ios --release
# 构建 iOS（需在 macOS 且 Xcode 已配置）
```
```bash
flutter build macos --release
flutter build linux --release
flutter build windows --release
flutter build web --release
# 构建桌面与 Web
```

## Dependencies 依赖
```bash
flutter pub get
# 获取依赖
```
```bash
flutter pub upgrade
# 升级到兼容的最新版本
```
```bash
flutter pub outdated
# 查看可升级依赖
```
```bash
dart pub global activate melos
# 示例：激活全局工具（这里以 melos 为例）
```

## Internationalization 国际化
```bash
flutter gen-l10n
# 根据 l10n/arb 生成本地化代码（如项目已配置）
```

## Clean & Cache 清理与缓存
```bash
flutter clean
# 清理构建产物
```
```bash
flutter pub cache repair
# 修复 Pub 缓存
```

## Device & Doctor 设备与环境
```bash
flutter devices
# 列出可用设备
```
```bash
flutter doctor -v
# 检查环境配置
```

## 版本更新
```bash
flutter upgrade
# 升级 Flutter SDK
```

## Perf & Debug 性能与调试
```bash
flutter run --profile
# Profile 模式运行（性能分析）
```
```bash
flutter run --trace-skia
# Skia 渲染跟踪（配合 DevTools）
```
```bash
dart --observe
# Dart VM 观察/调试（部分场景）