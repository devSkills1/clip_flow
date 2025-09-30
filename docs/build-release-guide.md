# ClipFlow Pro 构建与发布指南

本文档说明 ClipFlow Pro 项目的包名配置方案、构建流程和 GitHub 发布流程，以及如何在开发和生产环境之间进行切换。

## 包名方案

### 生产环境 (Production)
- **包名**: `com.clipflow.pro`
- **应用名**: `ClipFlow Pro`
- **数据库**: `clipflow_pro.db`

### 开发环境 (Development)
- **包名**: `com.clipflow.pro.dev`
- **应用名**: `ClipFlow Pro (Dev)`
- **数据库**: `clipflow_pro_dev.db`

## 设计理念

1. **品牌化**: `clipflow` 简洁易记，体现剪贴板流转的核心功能
2. **专业性**: `.pro` 后缀体现专业版定位
3. **环境隔离**: 开发环境添加 `.dev` 后缀，确保两个版本可以同时安装
4. **跨平台一致性**: 在所有平台（macOS、Windows、Linux）保持统一

## 文件结构

```
config/
├── app_config.dart              # Flutter 应用配置
macos/Runner/Configs/
├── AppInfo.xcconfig             # 默认配置（指向开发环境）
├── AppInfo-Dev.xcconfig         # 开发环境配置
└── AppInfo-Prod.xcconfig        # 生产环境配置
scripts/
├── build.sh                     # 标准构建脚本
├── build-unsigned.sh            # 无签名构建脚本
├── release.sh                   # GitHub 发布脚本
├── switch-env.sh               # 环境切换脚本
└── version-manager.sh          # 版本管理脚本（自动获取版本号和生成构建号）
docs/
└── code-signing-guide.md        # 代码签名详细指南
```

## 脚本关系与依赖

### 脚本概览

ClipFlow Pro 项目包含 5 个核心脚本，它们之间有明确的分工和依赖关系：

#### 🔧 **工具脚本**（可独立使用）
- **`version-manager.sh`**: 版本管理工具，从 `pubspec.yaml` 提取版本号并生成构建号
- **`switch-env.sh`**: 环境切换工具，在开发和生产环境之间切换

#### 🏗️ **构建脚本**（可独立或被调用）
- **`build.sh`**: 通用构建脚本，支持多平台多环境构建
- **`build-unsigned.sh`**: 专用于无签名构建，适合没有开发者证书的情况

#### 🚀 **流程脚本**（编排其他脚本）
- **`release.sh`**: 发布流程编排，调用多个其他脚本完成完整发布流程

### 脚本依赖关系图

```
release.sh (主发布流程)
    ├── version-manager.sh (版本号获取)
    ├── switch-env.sh (切换到生产环境)
    └── build-unsigned.sh (执行构建)
            └── switch-env.sh (切换到开发环境)

build.sh (独立构建脚本)
    └── (可选) switch-env.sh (环境切换)

switch-env.sh (独立环境管理)

version-manager.sh (独立版本管理)
```

### 详细依赖分析

#### 1. **release.sh** → 主发布脚本
**功能**: 完整的 GitHub 发布流程管理  
**依赖关系**:
- **调用 `version-manager.sh`**: 获取版本号和构建号
- **调用 `switch-env.sh`**: 切换到生产环境
- **调用 `build-unsigned.sh`**: 执行实际构建

**执行流程**:
```bash
release.sh
├── 1. version-manager.sh --full-version  # 获取完整版本号
├── 2. switch-env.sh prod                 # 切换生产环境
└── 3. build-unsigned.sh [options]        # 执行构建
```

#### 2. **build-unsigned.sh** → 无签名构建脚本
**功能**: 执行无签名的应用构建  
**依赖关系**:
- **调用 `switch-env.sh`**: 切换到指定环境（默认开发环境）

**执行流程**:
```bash
build-unsigned.sh [--env ENV]
└── 1. switch-env.sh [ENV]  # 切换到指定环境 (dev|prod)
```

**环境支持**:
- `--env dev`（默认）：开发环境构建
- `--env prod`：生产环境构建

#### 3. **build.sh** → 通用构建脚本
**功能**: 支持多平台、多环境的构建  
**依赖关系**:
- **可选调用 `switch-env.sh`**: 根据参数切换环境
- **接收环境变量**: `FLUTTER_BUILD_NAME`, `FLUTTER_BUILD_NUMBER`

#### 4. **switch-env.sh** → 环境切换脚本
**功能**: 管理开发/生产环境配置  
**依赖关系**: 无直接依赖，作为工具脚本被其他脚本调用

#### 5. **version-manager.sh** → 版本管理脚本
**功能**: 版本号提取和构建号生成  
**依赖关系**: 无直接依赖，作为工具脚本被其他脚本调用  
**依赖文件**: `pubspec.yaml`, `.build_counter`

### 使用场景与调用链

#### 场景 1: 完整发布流程
```bash
./scripts/release.sh
```
**执行链**: `release.sh` → `version-manager.sh` → `switch-env.sh prod` → `build-unsigned.sh --env prod` → `switch-env.sh prod`

#### 场景 2: 开发环境构建
```bash
./scripts/build.sh dev macos
```
**执行链**: `build.sh` → (可选) `switch-env.sh`

#### 场景 3: 无签名构建
```bash
./scripts/build-unsigned.sh --clean
```
**执行链**: `build-unsigned.sh` → `switch-env.sh`

#### 场景 4: 版本信息查询
```bash
./scripts/version-manager.sh --info
```
**执行链**: `version-manager.sh` (独立运行)

#### 场景 5: 环境切换
```bash
./scripts/switch-env.sh prod
```
**执行链**: `switch-env.sh` (独立运行)

### 数据流与环境变量传递

#### 版本信息流
```
pubspec.yaml → version-manager.sh → release.sh → build-unsigned.sh → Flutter 构建
```

#### 环境变量传递
```
release.sh 设置:
├── FLUTTER_BUILD_NAME (从 version-manager.sh)
├── FLUTTER_BUILD_NUMBER (从 version-manager.sh)
└── 传递给 → build-unsigned.sh → Flutter 构建命令
```

#### 环境配置流
```
switch-env.sh → 修改配置文件 → 影响后续构建行为
```

### 脚本设计特点

#### 🎯 **模块化设计**
- 每个脚本职责单一，功能明确
- 工具脚本可被多个流程脚本调用
- 便于维护和扩展

#### 🔄 **可复用性**
- `version-manager.sh` 和 `switch-env.sh` 可被多个脚本调用
- 既可独立使用，也可组合使用
- 减少代码重复

#### 🛡️ **错误处理**
- 每个脚本都有完善的错误检查
- 依赖脚本不存在时会给出友好提示
- 支持 `--help` 参数查看使用说明

#### 📊 **状态管理**
- 环境状态通过配置文件管理
- 版本信息从 `pubspec.yaml` 统一获取
- 构建计数器持久化存储

### 最佳实践建议

1. **开发阶段**: 使用 `build-unsigned.sh` 进行快速构建测试
2. **发布准备**: 使用 `release.sh` 进行完整发布流程
3. **环境管理**: 始终通过 `switch-env.sh` 切换环境，避免手动修改
4. **版本管理**: 依赖 `version-manager.sh` 自动处理版本号，避免手动指定
5. **脚本组合**: 根据需要组合使用不同脚本，发挥各自优势

## 版本管理

### 版本号获取

ClipFlow Pro 使用 `version-manager.sh` 脚本自动从 `pubspec.yaml` 获取版本号，并生成构建号。

#### 基本用法

```bash
# 显示版本号（从 pubspec.yaml 获取）
./scripts/version-manager.sh --version
# 输出: 1.0.0

# 显示构建号（日期+自增数字）
./scripts/version-manager.sh --build-number
# 输出: 2025093001

# 显示完整版本（版本号+构建号）
./scripts/version-manager.sh --full-version
# 输出: 1.0.0+2025093001

# 显示详细版本信息
./scripts/version-manager.sh --info
```

#### 构建号规则

- **格式**: `YYYYMMDD` + 两位自增数字
- **重置**: 每天自动从 `01` 开始
- **存储**: 计数器保存在 `.build_counter` 文件中
- **示例**: 
  - 第一次构建: `2025093001`
  - 同一天第二次: `2025093002`
  - 新的一天: `2025093101`

#### 重置构建计数器

```bash
# 手动重置构建计数器
./scripts/version-manager.sh --reset-counter
```

### 版本号配置

版本号在 `pubspec.yaml` 中配置：

```yaml
version: 1.0.0+1
```

- **版本号**: `1.0.0`（语义化版本）
- **构建号**: 脚本会自动覆盖 `+1` 部分

## 环境切换

### 使用脚本切换（推荐）

```bash
# 切换到开发环境
./scripts/switch-env.sh dev

# 切换到生产环境
./scripts/switch-env.sh prod

# 查看当前环境状态
./scripts/switch-env.sh status
```

### 手动切换

编辑 `macos/Runner/Configs/AppInfo.xcconfig` 文件：

**开发环境**:
```xcconfig
#include "AppInfo-Dev.xcconfig"
```

**生产环境**:
```xcconfig
#include "AppInfo-Prod.xcconfig"
```

## 构建应用

### 使用构建脚本（推荐）

```bash
# 构建开发环境的 macOS 应用
./scripts/build.sh dev macos

# 构建生产环境的 macOS 应用
./scripts/build.sh prod macos

# 构建生产环境的所有平台应用
./scripts/build.sh prod all

# 清理后构建
./scripts/build.sh -c dev macos
```

### 无签名构建（适用于没有开发者证书）

```bash
# 基本无签名构建（开发环境）
./scripts/build-unsigned.sh

# 生产环境构建
./scripts/build-unsigned.sh --env prod

# 清理后构建并创建 DMG 安装包
./scripts/build-unsigned.sh --clean --dmg

# 生产环境完整流程：清理、构建、创建 DMG、打开输出目录
./scripts/build-unsigned.sh --clean --dmg --env prod --open

# 查看帮助信息
./scripts/build-unsigned.sh --help
```

**环境参数说明**：
- `--env dev`（默认）：开发环境，包名带有 `dev` 标识
- `--env prod`：生产环境，正式发布包名

### 手动构建

```bash
# 开发环境
flutter build macos --dart-define=ENVIRONMENT=development

# 生产环境
flutter build macos --dart-define=ENVIRONMENT=production

# 无签名构建
flutter build macos --dart-define=ENVIRONMENT=development --release
```

## GitHub 发布流程

### 🚨 重要提醒

由于 ClipFlow Pro 目前**没有 Apple 开发者证书**，用户在 macOS 上安装时会遇到安全警告。这是正常现象，不是应用本身的问题。

### 使用发布脚本（推荐）

```bash
# 自动获取版本号发布（本地交互）
./scripts/release.sh

# 自动获取版本号发布（无交互）
./scripts/release.sh --yes

# 明确使用自动版本（无交互）
./scripts/release.sh --auto-version --yes

# 指定版本号发布（无交互）
./scripts/release.sh v1.0.0 --yes

# 完整发布流程（清理、构建、创建 DMG）（无交互）
./scripts/release.sh --clean --dmg --yes

# 指定版本的完整流程（无交互）
./scripts/release.sh v1.0.0 --clean --dmg --yes

# 从指定 tag 生成分类发布说明（示例）
./scripts/release.sh --clean --dmg --yes --notes-from-diff v1.0.0
```

提示：在 CI 环境下无需显式传 `--yes`，脚本检测到 `CI` 环境变量会自动进入无交互模式。

#### DMG 安装行为与脚本建议

- 双击 `*.dmg` 仅会挂载磁盘映像，不会自动复制到 `Applications`。安装需在挂载窗口中将应用拖拽到 `Applications`（或手动将 `.app` 拖拽到 `/Applications`）。
- 在构建脚本中为 `hdiutil` 回退添加 `Applications` 快捷方式，提升安装体验：
  ```bash
  ln -sf /Applications "$TEMP_DIR/Applications"
  ```
- 使用 `create-dmg` 时需同时传入“输出文件”和“源路径”两个位置参数，例如：
  ```bash
  create-dmg \
    --overwrite \
    --volname "$VOLUME_NAME" \
    --window-pos 200 120 \
    --window-size 800 400 \
    --icon-size 110 \
    --app-drop-link 600 200 \
    "$DMG_OUTPUT_PATH" \
    "$TEMP_DIR"
  ```
- 验证：构建完成后双击挂载，窗口内应出现应用图标与 `Applications` 别名；拖拽安装后在 `/Applications` 中可见 `ClipFlow Pro.app` 并能正常启动。
- 若首次运行受隔离限制，按“安装说明”章节中的 `xattr -dr com.apple.quarantine` 单应用豁免处理。

#### `.pkg` 安装器文档

如需“一键安装”体验（自动复制到 `Applications`），请参考新增文档：`docs/pkg-build-guide.md`。

### 发布脚本功能

`release.sh` 脚本会自动完成以下操作：

1. **环境切换**: 自动切换到生产环境
2. **应用构建**: 构建无签名的 macOS 应用
3. **文件重命名**: 按照版本号重命名输出文件
4. **DMG 创建**: 可选创建 DMG 安装包
5. **校验和生成**: 为所有文件生成 SHA256 校验和
6. **发布说明**: 生成包含安装说明的发布说明模板

### 发布文件说明

发布后会在 `build/` 目录生成：

```
ClipFlowPro-<version>-<build>-macos.dmg          # DMG 安装包
ClipFlowPro-<version>-<build>-macos.dmg.sha256   # DMG 校验和
release-notes-<version>.md                        # 发布说明模板（如生成）
```

### GitHub Release 创建步骤

1. **准备发布文件**:
   ```bash
   ./scripts/release.sh --clean --dmg --version v1.0.0 --yes
   ```

2. **编辑发布说明**: 编辑生成的 `release-notes-v1.0.0.md` 文件，添加：
   - 版本更新内容
   - 新功能说明
   - 问题修复列表
   - 已知问题

3. **创建 GitHub Release**:
   - 在 GitHub 仓库页面点击 "Releases"
   - 点击 "Create a new release"
   - 填写 Tag version（如 v1.0.0）
   - 上传生成的 `build/ClipFlowPro-<version>-<build>-macos.dmg` 与对应 `.sha256`
   - 复制发布说明内容

4. **发布后验证**:
   - 下载发布的文件
   - 验证 SHA256 校验和
   - 测试安装和运行

### 发布说明模板

在 GitHub Release 中使用以下模板：

```markdown
# ClipFlow Pro v1.0.0

## 📥 下载安装

### macOS 用户安装说明

⚠️ **重要提醒**：由于应用未经 Apple 签名，首次安装需要额外步骤。

#### 方法一：DMG 安装（推荐）
1. 下载 `ClipFlowPro-<version>-<build>-macos.dmg`
2. 双击 DMG 文件挂载
3. 将 `ClipFlow Pro` 拖拽到 `Applications` 文件夹
4. 首次运行时：
   - 如果提示"无法打开"，请右键点击应用
   - 选择"打开"
   - 在弹出对话框中点击"打开"

#### 方法二：终端豁免（更稳妥）
如果仍遇到“已损坏”或“无法打开”，可对单个应用解除隔离：
```bash
# 解除隔离（单应用豁免，不修改系统级设置）
xattr -dr com.apple.quarantine "/Applications/ClipFlow Pro.app"
```

#### 方法三：系统设置
1. 打开“系统设置” → “隐私与安全性”
2. 在尝试打开应用后，点击底部的“仍要打开”

## ✨ 新功能
- 功能1描述
- 功能2描述

## 🐛 修复问题
- 问题1修复
- 问题2修复

## 📋 系统要求
- macOS 10.15 或更高版本
- 64位处理器

## 🔒 安全说明
本应用是开源项目，代码完全透明。安全警告仅因为缺乏 Apple 开发者证书，不影响应用功能和安全性。

## 📞 技术支持
如果遇到安装问题，请：
1. 查看安装故障排查指南
2. 提交 Issue 反馈问题
```

### 文件命名规范

```
ClipFlowPro-<version>-<build>-macos.dmg
ClipFlowPro-<version>-<build>-windows.zip
ClipFlowPro-<version>-<build>-linux.tar.gz
```

### 用户反馈处理

#### 常见问题回复模板

**问题**："应用无法打开，提示已损坏"
**回复**：
```
这是 macOS 的安全机制，因为应用未经 Apple 签名。请按以下步骤操作：
1. 右键点击应用，选择"打开"
2. 在弹出对话框中点击"打开"
3. 如果仍无法打开，请参考安装指南中的详细步骤

这个问题不影响应用的功能和安全性，仅是因为个人开发者账号限制。
```

### 长期解决方案

1. **申请开发者证书**：$99/年，彻底解决安全警告问题
2. **代码签名**：提高应用可信度
3. **公证服务**：通过 Apple 官方验证
4. **替代分发方式**：
   - **Homebrew**：发布到 Homebrew Cask
   - **直接分发**：通过网站直接提供下载
   - **开源说明**：强调开源透明性

## Flutter 代码中的使用

在 Flutter 代码中，可以通过 `AppConfig` 类获取当前环境的配置：

```dart
import 'package:clip_flow_pro/config/app_config.dart';

// 获取当前环境
AppEnvironment env = AppConfig.environment;

// 获取包名
String packageName = AppConfig.packageName;

// 获取应用名
String appName = AppConfig.appName;

// 判断环境
if (AppConfig.isDevelopment) {
  // 开发环境特有逻辑
}

if (AppConfig.isProduction) {
  // 生产环境特有逻辑
}
```

## 环境特性对比

| 特性 | 开发环境 | 生产环境 |
|------|----------|----------|
| 包名 | `com.clipflow.pro.dev` | `com.clipflow.pro` |
| 应用名 | `ClipFlow Pro (Dev)` | `ClipFlow Pro` |
| 数据库 | `clipflow_pro_dev.db` | `clipflow_pro.db` |
| 日志级别 | Debug | Warning |
| 调试功能 | 启用 | 禁用 |
| 性能监控 | 禁用 | 启用 |
| 代码签名 | 自动 | 手动 |

## 注意事项

1. **环境隔离**: 开发和生产环境使用不同的包名，可以在同一设备上同时安装
2. **数据隔离**: 不同环境使用不同的数据库文件，避免数据混淆
3. **构建前切换**: 构建前确保切换到正确的环境配置
4. **代码签名**: 生产环境需要配置正确的开发者证书
5. **CI/CD**: 在持续集成中使用 `--dart-define` 参数指定环境

## 故障排查

### 包名不正确
1. 检查 `macos/Runner/Configs/AppInfo.xcconfig` 是否包含正确的配置文件
2. 运行 `./scripts/switch-env.sh status` 查看当前环境
3. 重新切换环境后重新构建

### 应用无法安装
1. 确认包名没有冲突
2. 检查代码签名配置
3. 清理构建缓存后重新构建

### 数据丢失
1. 检查是否意外切换了环境
2. 确认数据库文件路径是否正确
3. 备份重要数据到外部文件

## 脚本使用案例

### 1. 环境切换脚本 (`switch-env.sh`)

#### 基本用法
```bash
# 查看当前环境状态
./scripts/switch-env.sh status

# 切换到开发环境
./scripts/switch-env.sh dev

# 切换到生产环境  
./scripts/switch-env.sh prod

# 显示帮助信息
./scripts/switch-env.sh help
```

#### 实际使用场景
```bash
# 场景1: 开发阶段，确保使用开发环境
$ ./scripts/switch-env.sh status
当前环境: 开发环境 (Development)
包名: com.clipflow.pro.dev
应用名: ClipFlow Pro Dev

# 场景2: 准备发布，切换到生产环境
$ ./scripts/switch-env.sh prod
✅ 已切换到生产环境
配置文件: macos/Runner/Configs/AppInfo.xcconfig -> AppInfo-Prod.xcconfig

# 场景3: 发布后切回开发环境继续开发
$ ./scripts/switch-env.sh dev
✅ 已切换到开发环境
配置文件: macos/Runner/Configs/AppInfo.xcconfig -> AppInfo-Dev.xcconfig
```

### 2. 标准构建脚本 (`build.sh`)

#### 基本用法
```bash
# 构建开发环境的 macOS 应用
./scripts/build.sh dev macos

# 构建生产环境的 macOS 应用
./scripts/build.sh prod macos

# 构建所有平台（macOS、Windows、Linux）
./scripts/build.sh prod all

# 清理后构建
./scripts/build.sh -c dev macos

# 发布模式构建
./scripts/build.sh -r prod macos
```

#### 实际使用场景
```bash
# 场景1: 日常开发测试
$ ./scripts/build.sh dev macos
🚀 开始构建 ClipFlow Pro...
环境: development
平台: macos
✅ 构建完成: build/macos/Build/Products/Release/ClipFlow Pro Dev.app

# 场景2: 发布前最终构建
$ ./scripts/build.sh -c -r prod macos
🧹 清理构建缓存...
🚀 开始构建 ClipFlow Pro...
环境: production
平台: macos
模式: release
✅ 构建完成: build/macos/Build/Products/Release/ClipFlow Pro.app

# 场景3: 多平台发布构建
$ ./scripts/build.sh prod all
🚀 构建 macOS 应用...
✅ macOS 构建完成
🚀 构建 Windows 应用...
✅ Windows 构建完成
🚀 构建 Linux 应用...
✅ Linux 构建完成
```

### 3. 无签名构建脚本 (`build-unsigned.sh`)

#### 基本用法
```bash
# 基本无签名构建
./scripts/build-unsigned.sh

# 清理后构建
./scripts/build-unsigned.sh --clean

# 构建并创建 DMG 安装包
./scripts/build-unsigned.sh --dmg

# 完整流程：清理、构建、创建 DMG、打开输出目录
./scripts/build-unsigned.sh --clean --dmg --open

# 查看帮助信息
./scripts/build-unsigned.sh --help
```

#### 实际使用场景
```bash
# 场景1: 个人使用，快速构建测试
$ ./scripts/build-unsigned.sh
🚀 开始构建 ClipFlow Pro (无签名版本)
📝 切换到开发环境...
🔨 构建 macOS 应用...
✅ 应用构建成功
   路径: build/macos/Build/Products/Release/ClipFlow Pro Dev.app
   大小: 45.2M

# 场景2: 分发给朋友测试，创建 DMG 安装包
$ ./scripts/build-unsigned.sh --clean --dmg
🧹 清理构建缓存...
🔨 构建 macOS 应用...
✅ 应用构建成功
📦 创建 DMG 安装包...
✅ DMG 创建成功
   文件: ClipFlowPro-Dev-20250103-143022.dmg
   大小: 42.8M

📋 安装说明
注意：此应用未经 Apple 签名，首次运行需要额外步骤
1. 双击应用或 DMG 文件
2. 如果提示 '无法打开'，请右键点击应用选择 '打开'

# 场景3: 完整发布流程
$ ./scripts/build-unsigned.sh --clean --dmg --open
🧹 清理构建缓存...
🔨 构建 macOS 应用...
✅ 应用构建成功
📦 创建 DMG 安装包...
✅ DMG 创建成功
📂 打开输出目录...
🎉 构建完成！
```

### 4. GitHub 发布脚本 (`release.sh`)

#### 基本用法
```bash
# 基本发布构建（使用当前日期作为版本）
./scripts/release.sh

# 指定版本号发布
./scripts/release.sh --version v1.0.0

# 清理后发布
./scripts/release.sh --clean --version v1.0.1

# 完整发布流程：清理、构建、创建 DMG
./scripts/release.sh --clean --dmg --version v1.0.2

# 查看帮助信息
./scripts/release.sh --help
```

#### 实际使用场景
```bash
# 场景1: 快速发布测试版本
$ ./scripts/release.sh
🚀 开始构建 GitHub Release 版本...
📝 切换到生产环境...
🔨 构建 macOS 应用 (无签名)...
✅ 应用构建成功
📦 重命名输出文件...
   ClipFlowPro-20250103-143022.app
🔐 生成 SHA256 校验和...
   ClipFlowPro-20250103-143022.app.sha256
📝 生成发布说明模板...
   release-notes-20250103-143022.md
✅ GitHub Release 文件准备完成！

# 场景2: 正式版本发布
$ ./scripts/release.sh --clean --dmg --version v1.0.0
🧹 清理构建缓存...
🚀 开始构建 GitHub Release 版本 v1.0.0...
📝 切换到生产环境...
🔨 构建 macOS 应用 (无签名)...
✅ 应用构建成功
📦 创建 DMG 安装包...
✅ DMG 创建成功
📦 重命名输出文件...
   ClipFlowPro-v1.0.0.app
   ClipFlowPro-v1.0.0.dmg
🔐 生成 SHA256 校验和...
   ClipFlowPro-v1.0.0.app.sha256
   ClipFlowPro-v1.0.0.dmg.sha256
📝 生成发布说明模板...
   release-notes-v1.0.0.md

📋 发布说明模板已生成，包含：
- 版本信息和更新内容
- macOS 安装说明（绕过安全警告）
- 文件校验和信息
- 故障排查指南

🎯 下一步：
1. 编辑 release-notes-v1.0.0.md 添加更新内容
2. 在 GitHub 创建新的 Release
3. 上传生成的文件和发布说明

# 场景3: 热修复版本发布
$ ./scripts/release.sh --version v1.0.1-hotfix
🚀 开始构建 GitHub Release 版本 v1.0.1-hotfix...
📝 切换到生产环境...
🔨 构建 macOS 应用 (无签名)...
✅ 应用构建成功
📦 重命名输出文件...
   ClipFlowPro-v1.0.1-hotfix.app
🔐 生成 SHA256 校验和...
   ClipFlowPro-v1.0.1-hotfix.app.sha256
📝 生成发布说明模板...
   release-notes-v1.0.1-hotfix.md
✅ GitHub Release 文件准备完成！
```

#### 脚本组合使用
```bash
# 完整开发到发布流程
# 1. 确认开发环境
./scripts/switch-env.sh status

# 2. 开发阶段快速构建测试
./scripts/build-unsigned.sh

# 3. 准备发布，切换到生产环境
./scripts/switch-env.sh prod

# 4. 生产环境最终构建（如果有证书）
./scripts/build.sh -c -r prod macos

# 5. 或者无证书发布构建
./scripts/build-unsigned.sh --clean --dmg --open

# 6. GitHub 发布流程
./scripts/release.sh --clean --dmg --version v1.0.0

# 7. 发布后切回开发环境
./scripts/switch-env.sh dev

# GitHub 发布专用流程
# 1. 快速测试版本发布
./scripts/release.sh

# 2. 正式版本发布
./scripts/release.sh --clean --dmg --version v1.0.0

# 3. 热修复版本发布
./scripts/release.sh --version v1.0.1-hotfix
```

## 最佳实践

1. **开发阶段**: 始终使用开发环境配置
2. **测试阶段**: 使用生产环境配置进行最终测试
3. **发布前**: 确保使用生产环境配置构建
4. **版本控制**: 默认提交开发环境配置
5. **文档更新**: 包名变更时及时更新相关文档
6. **脚本使用**: 优先使用自动化脚本，减少手动操作错误
7. **无证书发布**: 使用 `build-unsigned.sh` 进行快速分发和测试
8. **GitHub 发布**: 使用 `release.sh` 自动化发布流程，包含文件重命名、校验和生成、发布说明模板
9. **版本管理**: 正式发布使用语义化版本号（如 v1.0.0），测试版本可使用日期标识
10. **发布文档**: 每次发布都要编辑生成的发布说明模板，添加详细的更新内容和安装说明