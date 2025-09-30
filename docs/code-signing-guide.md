# ClipFlow Pro 代码签名指南

本文档说明在没有开发证书情况下的打包、安装和分发策略。

## 🔍 证书影响分析

### 开发阶段
- ✅ **flutter run** - 无影响，可正常开发调试
- ✅ **Xcode 调试** - 无影响，可直接运行
- ✅ **本地测试** - 无影响，功能完全正常

### 构建和分发
- ⚠️ **本地构建** - 可以构建，但会有未签名警告
- ❌ **App Store** - 无法上架，必须有开发者证书
- ❌ **公开分发** - 用户安装困难，体验差

## 🛠️ 解决方案

### 方案一：自签名证书（推荐用于开发）

```bash
# 1. 创建自签名证书
security create-keychain -p "password" build.keychain
security default-keychain -s build.keychain
security unlock-keychain -p "password" build.keychain

# 2. 生成自签名证书
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes \
  -subj "/C=CN/ST=State/L=City/O=ClipFlow/OU=Dev/CN=ClipFlow Pro"

# 3. 导入证书到钥匙串
security import cert.pem -k build.keychain -T /usr/bin/codesign
security import key.pem -k build.keychain -T /usr/bin/codesign
```

### 方案二：修改构建配置（临时方案）

更新生产环境配置，使用自动签名：

```xcconfig
// macos/Runner/Configs/AppInfo-Prod.xcconfig
PRODUCT_NAME = ClipFlow Pro
PRODUCT_BUNDLE_IDENTIFIER = com.clipflow.pro
PRODUCT_COPYRIGHT = Copyright © 2025 ClipFlow. All rights reserved.

// 使用自动签名（无需开发者证书）
DEVELOPMENT_TEAM = 
CODE_SIGN_STYLE = Automatic
CODE_SIGN_IDENTITY = -
```

### 方案三：禁用代码签名（仅限开发）

```bash
# 构建时禁用代码签名
flutter build macos --dart-define=ENVIRONMENT=development --no-codesign
```

## 📦 不同场景的打包策略

### 1. 个人使用/内部测试

```bash
# 使用开发环境配置
./scripts/switch-env.sh dev
./scripts/build.sh dev macos

# 或手动构建
flutter build macos --dart-define=ENVIRONMENT=development
```

**安装方法**：
1. 双击 `.app` 文件
2. 如果提示"无法打开"，右键选择"打开"
3. 在弹出对话框中点击"打开"

### 2. 小范围分发（朋友/同事）

```bash
# 创建 DMG 安装包
hdiutil create -volname "ClipFlow Pro" -srcfolder "build/macos/Build/Products/Release/ClipFlow Pro.app" -ov -format UDZO ClipFlowPro.dmg
```

**用户安装指南**：
1. 下载 DMG 文件
2. 双击挂载
3. 将应用拖拽到 Applications 文件夹
4. 首次运行时右键选择"打开"

### 3. 公开分发（需要证书）

如果要公开分发，建议：
1. 申请 Apple Developer 账号（$99/年）
2. 获取 Developer ID 证书
3. 进行公证（notarization）

## 🔧 自动化脚本

创建无证书构建脚本：

```bash
#!/bin/bash
# scripts/build-unsigned.sh

echo "构建未签名版本..."

# 切换到开发环境
./scripts/switch-env.sh dev

# 构建应用
flutter build macos --dart-define=ENVIRONMENT=development

# 创建 DMG
APP_PATH="build/macos/Build/Products/Release/ClipFlow Pro Dev.app"
DMG_NAME="ClipFlowPro-Dev-$(date +%Y%m%d).dmg"

if [ -d "$APP_PATH" ]; then
    hdiutil create -volname "ClipFlow Pro Dev" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_NAME"
    echo "✅ DMG 创建完成: $DMG_NAME"
else
    echo "❌ 应用构建失败"
    exit 1
fi
```

## ⚠️ 注意事项

### 安全警告
- 未签名应用会显示安全警告
- 用户需要手动允许运行
- 可能被防病毒软件误报

### 功能限制
- 某些系统权限可能受限
- 无法使用某些 macOS 特性（如沙盒）
- 无法通过 App Store 分发

### 用户体验
- 首次安装需要额外步骤
- 可能降低用户信任度
- 技术小白用户可能无法安装

## 🎯 推荐策略

### 开发阶段
1. 使用开发环境配置
2. 禁用代码签名
3. 专注功能开发

### MVP 测试
1. 创建自签名证书
2. 构建 DMG 安装包
3. 提供详细安装说明

### 正式发布
1. 申请 Apple Developer 账号
2. 获取正式证书
3. 进行代码签名和公证

## 📋 检查清单

### 构建前检查
- [ ] 确认环境配置正确
- [ ] 检查代码签名设置
- [ ] 验证构建脚本权限

### 构建后检查
- [ ] 应用可以正常启动
- [ ] 核心功能正常工作
- [ ] 权限请求正常显示

### 分发前检查
- [ ] 创建安装说明文档
- [ ] 测试在其他设备上安装
- [ ] 准备用户支持材料

## 🔗 相关资源

- [Apple Developer Program](https://developer.apple.com/programs/)
- [Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)