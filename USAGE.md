## ClipFlow Pro 使用说明（运行与打包）

### 1. 环境准备
- Flutter：3.19+（建议保持最新稳定版）
- Dart：3.9+
- 平台工具：
  - macOS：Xcode 14+、CMake、CocoaPods（如需 iOS）
  - Windows：Visual Studio 2022（含 Desktop development with C++）、CMake、Ninja（可选）
  - Linux：clang、cmake、ninja-build、pkg-config、libgtk-3-dev、liblzma-dev

> 启用桌面支持（首次执行）：
```bash
flutter config --enable-macos-desktop --enable-windows-desktop --enable-linux-desktop
```

### 2. 安装依赖
```bash
flutter pub get
```

### 3. 运行指令（Development）
- macOS：
```bash
flutter run -d macos
```
- Windows：
```bash
flutter run -d windows
```
- Linux：
```bash
flutter run -d linux
```
- Web（如启用）：
```bash
flutter run -d chrome
```

### 4. 打包指令（Release/分发）
- macOS（.app，开发分发）：
```bash
flutter build macos --release
```
  - 产物目录：`build/macos/Build/Products/Release/*.app`
  - 若需签名与公证，使用 Xcode 打开 `/macos/Runner.xcworkspace` 进行签名配置

- Windows（.exe）：
```bash
flutter build windows --release
```
  - 产物目录：`build/windows/x64/runner/Release/*.exe`
  - 若需打包安装器，推荐 NSIS/Inno Setup/Wix Toolset

- Linux（可执行文件）：
```bash
flutter build linux --release
```
  - 产物目录：`build/linux/x64/release/bundle/`
  - 若需 DEB/RPM，使用 fpm/CPack 自行封装

- Web（静态资源）：
```bash
flutter build web --release
```
  - 产物目录：`build/web/`

### 5. 常见问题与注意事项
- 依赖安装失败：
  - 执行 `flutter clean && flutter pub get`
  - 检查代理/镜像设置（尤其在公司网络环境）
- 桌面窗口/托盘问题：
  - macOS/Windows/Linux 托盘与窗口属性依赖 `window_manager`、`tray_manager`，需允许窗口权限（macOS 需辅助功能权限）
- 全局快捷键：
  - 需平台通道支持；macOS 可能需要在“隐私与安全性”中开启辅助功能
- 剪贴板监听：
  - 不同平台实现差异较大；若检测不到，确认系统权限与 API 可用性
- 构建体积过大：
  - Release 构建默认包含 Flutter 引擎；结合资源裁剪与延迟加载优化
- 打包签名：
  - macOS 需 Developer ID Application 证书与公证；Windows 若需 SmartScreen 信誉，考虑 EV 代码签名证书

### 6. 开发调试建议
- 热重载：`r`（终端）或 IDE 快捷键
- 日志：`flutter logs` 或平台日志工具（Console.app/Event Viewer/journalctl）
- 分支与版本：用 `--build-name`/`--build-number` 标识版本
```bash
flutter build macos --release --build-name 1.0.1 --build-number 2
```

### 7. 目录与产物
- 运行/打包产物均在 `build/` 下；仓库已通过 `.gitignore` 忽略常见临时产物与平台构建目录
