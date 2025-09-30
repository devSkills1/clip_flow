# Release TODO（2025-09）

面向桌面端（macOS/Windows/Linux）的发布检查清单与改进项。此文档用于跟踪发布流程优化与脚本改造的执行情况。

## 已完成（本次迭代）

- [x] 统一 DMG 命名：`ClipFlowPro-<version>-<build>-<platform>.dmg`（Dev 版：`ClipFlowPro-Dev-<version>-<build>-<platform>.dmg`）
- [x] 构建阶段生成 `SHA256` 校验文件：`*.dmg.sha256`
- [x] 更新安装指引为更安全方案：优先使用“右键打开”和 `xattr -dr com.apple.quarantine` 单应用豁免；弱化 `spctl --master-disable`
- [x] 发布脚本加入 `--yes`（或 CI 环境变量）无交互模式，避免流水线阻塞
- [x] 环境切换脚本仅替换 `#include` 行，不覆盖头部注释
- [x] 发布说明生成改进：支持 `--notes-from-diff <tag>` 自动分类生成

## 待办（下阶段）

- [ ] 生产环境启用签名：在 `AppInfo-Prod.xcconfig` 默认开启签名（`CODE_SIGNING_ALLOWED = YES`），并在无证书时明确回退到无签名脚本
- [ ] 公证与安全校验：`codesign --verify --deep --strict` 与 `spctl -a -vv` 集成，Apple Notarization 流程文档与脚本化
 
- [ ] DMG 视觉优化：可选使用 `create-dmg` 自定义背景与应用快捷方式，缺失时回退 `hdiutil`
- [ ] 依赖工具显式校验：`flutter`、`hdiutil`、`shasum`（以及可选 `create-dmg`）缺失时给出安装指导
- [ ] CI 自动发布：在 `desktop-ci.yml` 中增加发布工序（打包、校验、生成说明、上传 Release/Artifacts）

## 参考

- `docs/code-signing-guide.md`：签名、公证与安全相关指引
- `scripts/build-unsigned.sh`、`scripts/release.sh`、`scripts/switch-env.sh`：构建、发布与环境切换脚本
- `macos/Runner/Configs/*.xcconfig`：macOS 应用信息与签名策略

## 实施要点与验收标准

- 生产环境启用签名
  - 实施要点：
    - 更新 `AppInfo-Prod.xcconfig`，默认开启签名：`CODE_SIGNING_ALLOWED = YES`、`CODE_SIGNING_REQUIRED = YES`、`CODE_SIGN_STYLE = Manual`。
    - 使用环境变量或 `.xcconfig` 引入证书名称与团队 ID（如 `DEVELOPMENT_TEAM`、`CODE_SIGN_IDENTITY`）。
    - 在无证书场景下，发布流程回退到 `build-unsigned.sh` 并在发布说明明确 “未签名版本”。
  - 验收标准：
    - `codesign --verify --deep --strict "<app>.app"` 通过；`spctl -a -vv "<app>.app"` 显示 accepted（签名版）。

- 公证与安全校验
  - 实施要点：
    - 使用 `xcrun notarytool submit <artifact> --keychain-profile <profile> --wait` 提交公证。
    - 对已公证的 `.app` 或 `.dmg` 执行 `xcrun stapler staple <artifact>`。
    - 在 `release.sh` 中新增可选 `--notarize`，并在 CI 中通过机密凭据触发。
  - 验收标准：
    - `spctl -a -vv <artifact>` 显示 `source=Notarized Developer ID`；首次运行不再触发隔离警告。

- 发布说明生成改进
  - 实施要点：
    - 在 `release.sh` 支持 `--notes-from-diff <tag>`，从 `git log <tag>..HEAD` 聚合分类（feat/fix/docs/chore/refactor）。
    - 模板保留“摘要/下载/校验/安装指引/变更分类/致谢”结构。
  - 验收标准：
    - 当传入 `<tag>` 时，发布说明自动包含分类变更与提交摘要，无交互模式下内容完整且不溢出。

- DMG 视觉优化
  - 实施要点：
    - 优先尝试 `create-dmg`（背景图、应用快捷方式、窗口尺寸），缺失时回退 `hdiutil`。
    - 资源命名统一：背景图放置 `assets/dmg/Background.png`，应用别名为 `Applications`。
  - 验收标准：
    - 生成的 DMG 打开后展示自定义背景与应用快捷方式；无 `create-dmg` 时仍可正常挂载与安装。

- 依赖工具显式校验
  - 实施要点：
    - 在脚本入口处校验 `flutter`、`hdiutil`、`shasum`、`git`（以及可选 `create-dmg`）。
    - 缺失时给出简明安装指引（如 `brew install create-dmg`、`xcode-select --install`）。
  - 验收标准：
    - 在依赖缺失的环境中，脚本以清晰错误信息退出；依赖完整时无噪声提示并顺利完成。

- CI 自动发布
  - 实施要点：
    - 在 `.github/workflows/desktop-ci.yml` 增加 `release` 任务：
      - 触发条件：`tag push` 或 `manual dispatch`。
      - 步骤：拉取代码 → 安装 Flutter → 构建（macOS 生成 DMG、全部平台生成包）→ 生成校验与发布说明 → 上传 GitHub Release/Artifacts。
      - 机密：使用 `secrets` 存放 Apple 公证凭据（如 notarytool profile）与 GitHub Token。
    - 产物命名一致：`ClipFlowPro-<version>-<build>-<platform>.<ext>` 与 `*.sha256`。
    - 无交互模式：本地传 `--yes` 或在 CI 设置 `CI=1` 自动继续，避免提示阻塞。
  - 验收标准：
    - 手动或推送 tag 时，工作流自动产出制品与发布说明，并附带校验文件；失败时日志明确问题位置。

## 近期计划（建议顺序）

1) 依赖校验与脚本选项完善（低风险，提升体验）
2) 发布说明自动化（无外部依赖，易验证）
3) DMG 视觉优化（可选依赖，回退可用）
4) 生产签名与本地校验（需要证书）
5) 公证与 CI 自动发布（需要机密、Runner 约束）