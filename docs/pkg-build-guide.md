# macOS `.pkg` 安装器制作指南

本指南介绍如何将 `ClipFlow.app` 封装为 `.pkg` 安装器，以实现“一键安装”（自动复制到 `Applications`）。本指南仅为文档与命令示例，不改动项目脚本。

## 场景与注意事项

- `.pkg` 更适合正式分发与企业内部部署；相比 DMG 的“拖拽安装”，`.pkg` 可直接安装到目标位置。
- 未签名或未公证的 `.pkg` 在双击安装时可能触发安全警告。公开分发建议使用 `Developer ID Installer` 签名并进行 Apple 公证。
- `.pkg` 制作常见两种路径：
  - 单组件包（`pkgbuild --root`）：最简单，直接将 `.app` 放入 `Applications`。
  - 分发包（`productbuild`）：用于组合多个组件或生成更复杂的安装流程。

## 前置条件

- 已完成 macOS 构建：`build/macos/Build/Products/Release/ClipFlow.app`
- 可选：Apple 开发者账号与证书
  - `Developer ID Installer: <Name> (<TEAMID>)`
  - 建议后续进行 Apple Notarization（公证）

## 最简流程：单组件 `.pkg`（推荐入门）

1) 准备安装根目录（将 `.app` 置于 `Applications` 目录结构）

```bash
mkdir -p build/pkgroot/Applications
cp -R "build/macos/Build/Products/Release/ClipFlow.app" \
      "build/pkgroot/Applications/ClipFlow.app"
```

2) 生成 `.pkg`

```bash
# 使用语义化版本与构建号（示例）
VERSION="v1.0.0"
BUILD="20250101"

pkgbuild \
  --root build/pkgroot \
  --install-location / \
  --identifier com.clipflow.app \
  --version "${VERSION#v}.${BUILD}" \
  "build/ClipFlow-${VERSION}-${BUILD}-macos.pkg"
```

3) 可选：签名（公开分发推荐）

```bash
pkgbuild \
  --root build/pkgroot \
  --install-location / \
  --identifier com.clipflow.app \
  --version "${VERSION#v}.${BUILD}" \
  --sign "Developer ID Installer: Your Name (TEAMID)" \
  "build/ClipFlow-${VERSION}-${BUILD}-macos.pkg"
```

## 进阶：`productbuild` 生成分发包

如需组合多个组件或生成分发包，可先用 `pkgbuild` 生成组件包，再用 `productbuild` 打包：

```bash
# 组件包（将 app 复制到 Applications）
mkdir -p build/pkgroot/Applications
cp -R "build/macos/Build/Products/Release/ClipFlow.app" \
      "build/pkgroot/Applications/ClipFlow.app"

pkgbuild \
  --root build/pkgroot \
  --install-location / \
  --identifier com.clipflow.app \
  --version "${VERSION#v}.${BUILD}" \
  "build/ClipFlow.component.pkg"

# 分发包（可选签名）
productbuild \
  --sign "Developer ID Installer: Your Name (TEAMID)" \
  --package "build/ClipFlow.component.pkg" \
  "build/ClipFlow-${VERSION}-${BUILD}-macos.pkg"
```

> 提示：如不签名，`productbuild` 的 `--sign` 参数可省略；但公开分发时强烈建议签名并公证。

## 安装与验证

- 双击安装：打开生成的 `.pkg` 按向导安装；若出现安全提示，需在系统中允许运行或采用签名/公证流程。
- 终端安装（便于验证）：

```bash
sudo installer -pkg "build/ClipFlow-${VERSION}-${BUILD}-macos.pkg" -target /
```

- 安装完成后，`/Applications/ClipFlow.app` 应可见并可启动。

## 公证与分发建议（概览）

- 证书与签名：使用 `Developer ID Installer` 对 `.pkg` 签名。
- 公证：使用 `notarytool` 提交公证并附加凭证。示例流程（仅概览）：

```bash
xcrun notarytool submit "build/ClipFlow-${VERSION}-${BUILD}-macos.pkg" \
  --apple-id "your@appleid" \
  --team-id "TEAMID" \
  --password "app-specific-password" \
  --wait
```

- 验证：`spctl -a -vv "build/ClipFlow-${VERSION}-${BUILD}-macos.pkg"` 与安装后运行验证。

## 故障排查

- 无法双击安装：未签名或未公证导致；请改用终端 `installer` 或进行签名、公证。
- 安装后找不到应用：确认 `pkgbuild --root` 的目录结构为 `Applications/ClipFlow.app`，且 `--install-location /`。
- 权限与沙盒：`.pkg` 不改变应用沙盒配置；与 Xcode entitlements 配置无关。

## 与发布指南的关系

- 发布指南 `docs/build-release-guide.md` 已在“使用发布脚本（推荐）”段落后链接到本文档。
- DMG 与 `.pkg` 二选一：
  - DMG 更易分发与预览，需拖拽安装；
  - `.pkg` 安装更直接，正式分发推荐使用签名与公证。
