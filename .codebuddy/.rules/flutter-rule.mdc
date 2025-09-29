# flutter-rule

# 项目开发规则（可执行版）

本规则用于 Flutter 多端项目，强调“可验证、可度量、可落地”。所有“必需”项应由 PR 模板与 CI 门禁强制执行，“推荐”项按团队计划推进。

## 0. 执行与度量（必读）
- PR 模板必须包含：依赖评审、性能影响、安全影响、迁移影响、可回滚性。
- 提交钩子（pre-commit / pre-push）最少包含：dart format、dart fix --apply、flutter analyze、测试与覆盖率阈值、license header 校验、unused imports 清理。
- CI 门禁：lint、测试（全局覆盖率≥70%，核心模块≥80%）、flutter pub outdated、依赖许可扫描、SCA（如 Snyk）、dart code_metrics（圈复杂度/函数长度阈值）、构建校验。
- 周期性任务（每季度）：弃用 API 审计、依赖更新与瘦身、性能基线对比（TTI/掉帧/内存）、崩溃率与稳定性复盘。

## 1. 核心规则

### 1.1 API 使用规范（必需）
- 禁止使用 @deprecated 成员；CI 将 deprecated 警告视为失败。
- Dart/Flutter 最低版本与升级节奏：在团队版本矩阵中声明；官方小版本发布两周内完成评估。
- 遇 API 变更，严格按官方迁移文档处理；产出迁移说明。
- 平台通道/FFI 接口变更遵循 SemVer，并附迁移指南与回滚方案。

### 1.2 UI/UX 设计规范（必需）
- 采用 Material 3；使用 ColorScheme 的语义化颜色令牌；统一暗/亮色策略。
- 文案国际化：强制使用 gen-l10n，文案从 ARB 获取，禁止硬编码文案。
- 无障碍：遵循 WCAG 2.1 AA；支持 textScaleFactor 1.0–1.5 无溢出；支持深色/高对比模式。
- 动画：统一 150–300ms，曲线使用标准曲线；关键操作可取消或可中断。

### 1.3 依赖与工具（必需）
- 优先使用官方 API/项目已有封装，禁止重复造轮子；若现有封装不满足需求，需在 PR 中列明差距与新增原因。
- 第三方库引入需在 PR 模板填写：功能必要性、体积/启动开销、维护活跃度、License、替代方案对比、移除成本与策略。
- 维护 tools/DEPENDENCIES.md 白名单与准入标准；定期依赖瘦身 Review。

## 2. 代码质量规范

### 2.1 代码结构（必需）
- Clean Architecture：Presentation、Domain、Data 分层；SOLID、DRY 原则。
- 禁止越层依赖：Presentation 不得直接依赖 Data；通过 UseCase/Repository 接口通信。
- 模块化：鼓励以 package 划分业务模块（melos/workspace）；公共 API 明确。
- 跨模块通信通过接口/事件/路由，禁止引用内部实现类。

### 2.2 命名规范（必需）
- 英文语义化命名与项目内一致性。
- 文件/目录：snake_case.dart；Widget 文件与类名同名；测试 *_test.dart。
- 后缀规范：Provider/Notifier/Bloc 一致；DTO/Entity/Model 语义区分；异步方法以 Async 结尾；Stream 变量显式命名或以 $ 标识。

### 2.3 常量与配置（必需）
- 禁止硬编码魔法数字/字符串/颜色；常量集中于 lib/core/constants，并语义化命名。
- 环境配置与多 Flavor：统一 lib/core/config；通过 --dart-define 管理 dev/staging/prod。
- 设计 Token：颜色/间距/排版统一来源，便于主题化与一致性。

### 2.4 文档规范（必需）
- 复杂逻辑添加注释；公共接口提供文档与使用示例。
- README 模板：运行、构建、环境变量、故障排查。
- 架构决策记录（ADR）：关键技术选型与取舍记录于 docs/decisions。
- **文档存放规范**：所有项目文档统一存放在 `docs/` 目录下，包括但不限于：技术文档、设计文档、API 文档、使用指南、优化总结等。
- 文档注释警告处理：开发阶段允许暂时忽略 `public_member_api_docs` 警告，但发布前需补全核心公共接口文档；可通过 analysis_options.yaml 配置忽略或降级该警告。

## 3. 性能与构建

### 3.1 性能最佳实践（必需）
- 组件优化：尽量使用 const 构造、Selector/ValueListenable/Memoization 降重建；明确 Rebuild 边界。
- 列表与图片：使用 Sliver 系列与分页；图片默认缓存（如 cached_network_image）并设定缓存策略与尺寸。
- 诊断：引入大组件或复杂场景需在 PR 附 DevTools 截图，目标帧耗时 < 16ms（60fps 设备）。

### 3.2 构建优化（推荐）
- Tree Shaking：移除未使用代码；分包与按路由拆分（web）。
- release 关闭调试面板与 assert；日志可观测开关通过 dart-define 控制。
- Web 渲染策略：明确 canvaskit/html 选择；Service Worker 缓存策略。

## 4. 安全规范

### 4.1 数据安全（必需）
- 禁止在代码中硬编码密钥/密码；使用 .env + dart-define + Secret Manager。
- 本地安全存储统一 flutter_secure_storage；日志与剪贴板脱敏。
- 网络通信：HTTPS，必要时配置证书锁定（TLS pinning）；防重放与中间人风险评估。

### 4.2 依赖安全（必需）
- 启用 dependabot/renovate；SCA 扫描（如 Snyk）。
- 版本锁定：app 层提交 pubspec.lock，库层不提交；CI 校验可复现构建。

## 5. 测试规范

### 5.1 覆盖率（必需）
- 全局覆盖率≥70%，核心模块≥80%，低于阈值 CI 失败。
- Golden Test 用于关键 UI；网络/时间/平台交互使用 Mock/Fake。
- 并发/异步使用 fake_async 等工具覆盖。

### 5.2 测试质量（必需）
- 统一 Given-When-Then 命名/结构；使用测试数据工厂/fixtures。
- 端到端测试使用 integration_test，覆盖启动/登录/关键主流程。

## 6. 版本与发布

### 6.1 Git 规范（必需）
- 约定式提交（Conventional Commits）；小步提交；禁止在同一 PR 混合重构与功能。
- 重要变更需附性能/内存对比；所有变更需代码审查。

### 6.2 发布管理（必需）
- 语义化版本（SemVer）；维护变更日志与回滚策略。
- 多平台签名与证书流程：Android keystore、iOS 证书/Provision、macOS notarization。
- 崩溃/ANR：接入 Crashlytics/Sentry；发布灰度与回滚脚本。

## 7. 平台与工程实践

### 7.1 路由与导航（必需）
- 统一使用 go_router（或团队指定），路由命名规范与深链（deep link）策略明确。

### 7.2 状态管理（必需）
- 指定首选（如 Riverpod/Bloc），提供选择矩阵与边界；禁止无规范混用。

### 7.3 数据与缓存（必需）
- Repository 模式统一；缓存层（内存/磁盘/失效时间）约定；离线优先场景说明。

### 7.4 错误与日志（必需）
- 统一错误模型与全局错误边界；日志分级与脱敏；release 最小化日志输出。
- **统一日志工具**：强制使用项目封装的日志工具 `lib/core/services/logger`，禁止直接使用 `print()` 或 `debugPrint()`；支持多适配器（控制台、文件）和日志级别管理。
- 异常捕获规范：强制使用 `try on Exception catch (e)` 格式，禁止使用 `try catch (e)`；确保异常类型明确，避免捕获所有异常。

### 7.5 可观测性（推荐）
- 接入 APM/埋点；核心指标：TTI、冷启动、掉帧率、网络失败率；仪表盘与告警阈值。

## 8. 代码质量检查（工具清单）
- Lint：very_good_analysis 或团队自定义 analysis_options.yaml。
- 格式化：dart format；自动修复：dart fix --apply。
- 静态分析：flutter analyze；性能分析：Flutter DevTools。
- 依赖：flutter pub outdated、许可扫描、未使用依赖清理。
- 文档注释：开发阶段可配置忽略 `public_member_api_docs` 警告，发布前统一补全重要接口文档。

—— 规则文档会随项目演进持续更新 ——