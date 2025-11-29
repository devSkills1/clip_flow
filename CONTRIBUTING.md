# Contributing to ClipFlow Pro

欢迎提交 Issue、改进文档或贡献代码。为了保持项目质量，请遵循以下流程。

## 环境准备
- 使用 Flutter 3.19+、Dart 3.9+。
- 首次开发前执行 `flutter config --enable-macos-desktop --enable-windows-desktop --enable-linux-desktop`。
- 根据平台安装 `docs/OCR_IMPLEMENTATION.md` 与 `docs/build-release-guide.md` 中列出的系统依赖（Tesseract、Xcode、Visual Studio 等）。

## 分支与提交
1. Fork 仓库并创建功能分支：`git checkout -b feature/<topic>`。
2. 按照 Conventional Commits 规范提交，如 `feat(clipboard): add drag handle`。
3. 保持每次提交原子化；若需多次更改请拆分为多个 commit。

## 代码规范
- 运行 `dart format lib test` 并确保两空格缩进、尾随逗号。
- 遵循 `analysis_options.yaml`（Very Good Analysis + 定制规则）。
- Provider 命名需包含功能前缀（例如 `historyListProvider`）。
- 所有字符串来自 `lib/l10n/arb`，避免硬编码中文/英文文案。

## 测试要求
在提交 PR 之前执行：

```bash
flutter pub get
flutter analyze
dart format --output none --set-exit-if-changed lib test
flutter test --coverage
```

如修复缺陷，请在 `test/` 目录中添加带回归场景名称的单测或整合测试。

## 提交 PR 前检查
- 更新相关文档（README、docs/* 或 MIGRATION_GUIDE.md）。
- 新增平台依赖时，请在 `docs/USAGE.md` 或 `docs/OCR_IMPLEMENTATION.md` 中注明安装方式。
- 若涉及版本号或构建脚本，请使用 `./scripts/version-manager.sh` 与 `./scripts/switch-env.sh` 确保 dev/prod 配置同步。

## 行为准则
请遵循基本的开源协作礼仪，尊重所有贡献者。若报告安全问题或敏感信息，请发送邮件至 `jr.lu.jobs@gmail.com`，避免公开 Issue。

感谢你的贡献！
