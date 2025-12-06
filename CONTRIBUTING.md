# 贡献指南

感谢你对 ClipFlow 的关注！我们欢迎各种形式的贡献。

## 🚀 快速开始

### 环境要求

- Flutter 3.19.0+
- Dart 3.9.0+
- macOS 10.15+ / Windows 10+ / Ubuntu 18.04+

### 本地开发

```bash
# 克隆项目
git clone https://github.com/devSkills1/clip_flow.git
cd clip_flow

# 安装依赖
flutter pub get

# 运行开发版本
flutter run -d macos --dart-define=ENVIRONMENT=development
```

## 📝 贡献流程

### 1. 提交 Issue

在开始编码之前，请先创建或查找相关的 Issue：
- 🐛 Bug 报告：描述问题、复现步骤、期望行为
- ✨ 功能请求：描述需求、使用场景、期望效果
- 📚 文档改进：指出需要补充或修正的内容

### 2. Fork 和分支

```bash
# Fork 项目后克隆到本地
git clone https://github.com/YOUR_USERNAME/clip_flow.git

# 创建功能分支
git checkout -b feature/your-feature-name
# 或 Bug 修复分支
git checkout -b fix/bug-description
```

### 3. 开发规范

#### 代码风格
- 遵循 [Effective Dart](https://dart.dev/guides/language/effective-dart) 规范
- 使用 `dart format` 格式化代码
- 通过 `flutter analyze` 检查

#### 提交规范
使用 [Conventional Commits](https://www.conventionalcommits.org/) 格式：

```
<type>(<scope>): <subject>

<body>

<footer>
```

类型（type）：
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式（不影响代码运行）
- `refactor`: 重构
- `perf`: 性能优化
- `test`: 测试相关
- `chore`: 构建/工具变更

示例：
```
feat(clipboard): 添加 RTF 格式支持

- 实现 RTF 内容检测
- 添加 RTF 渲染组件
- 更新类型枚举

Closes #123
```

### 4. 测试要求

```bash
# 运行所有测试
flutter test

# 带覆盖率运行
flutter test --coverage

# 运行特定测试
flutter test test/unit/
```

覆盖率要求：
- 全局覆盖率 ≥ 70%
- 核心模块覆盖率 ≥ 80%

### 5. 提交 Pull Request

1. 确保通过所有测试和 lint 检查
2. 更新相关文档（如有必要）
3. 填写 PR 模板中的所有必填项
4. 等待代码审查

## 🏗️ 项目架构

```
lib/
├── core/                  # 核心功能
│   ├── constants/         # 常量定义
│   ├── models/            # 数据模型
│   ├── services/          # 服务层
│   └── utils/             # 工具类
├── features/              # 功能模块
│   ├── classic/           # 经典模式
│   ├── compact/           # 紧凑模式
│   └── settings/          # 设置页面
├── shared/                # 共享组件
└── l10n/                  # 国际化
```

详细架构说明请参考 [README.md](README.md)。

## 📋 代码审查标准

PR 审查主要关注以下方面：

- ✅ 代码质量和可读性
- ✅ 测试覆盖和质量
- ✅ 性能影响评估
- ✅ 安全性考虑
- ✅ 文档完整性
- ✅ 向后兼容性

## 🔒 安全问题

如果发现安全漏洞，请勿公开提交 Issue。请发送邮件至 jr.lu.jobs@gmail.com，我们会尽快处理。

## 💬 获取帮助

- 📖 查看 [文档](docs/)
- 💬 在 Issue 中提问
- 📧 发送邮件至 jr.lu.jobs@gmail.com

## 📜 许可证

通过提交贡献，你同意你的贡献将按照项目的 [MIT 许可证](LICENSE) 进行授权。

---

再次感谢你的贡献！🎉
