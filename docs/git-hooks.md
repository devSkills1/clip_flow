# Git Hooks Guide | Git 钩子指南

A concise guide to using and reusing pre-commit hooks in this repo and others.  
本仓库与跨项目可复用的 pre-commit 钩子简明指南。

## What is pre-commit? | 什么是 pre-commit？
- Git client-side hook executed before `git commit`.
- Exit code 0 allows commit; non‑zero blocks commit.
- Location: `.git/hooks/pre-commit` (per repo, not versioned by default).
- Git 端本地钩子，在执行 `git commit` 之前触发。
- 退出码 0 允许提交；非 0 阻断提交。
- 位置：`.git/hooks/pre-commit`（默认不随代码版本化）。

## This repo's pre-commit flow | 本仓库 pre-commit 流程
Script source: `tools/hooks/pre-commit` (symlink or copy into `.git/hooks/pre-commit`).  
脚本源：`tools/hooks/pre-commit`（建议符号链接或复制到 `.git/hooks/pre-commit`）。

Steps 步骤:
1) Format 代码格式化
   - `dart format` (non-destructive)  
   - Auto-stage changes if any (`git add -A`)  
   - 非侵入式格式化，若有改动自动 `git add -A`
2) Auto-fix 自动修复
   - `dart fix --apply`  
   - Auto-stage if changed  
   - 若产生改动自动加入暂存
3) Analyze 分析（非阻断 infos/warnings）
   - `flutter analyze --no-fatal-infos --no-fatal-warnings || true`  
   - 报告信息/警告但不阻断提交
4) Tests with coverage 测试（阻断）
   - `flutter test --coverage`  
   - 失败会阻断提交
5) Outdated deps 依赖过期提示（非阻断）
   - `flutter pub outdated`  
   - 仅提示，不阻断

Notes 说明:
- Hook runs locally; no extra dev action required.  
  钩子本地运行，开发者无需额外操作。
- To skip hooks temporarily: `git commit -n` (use sparingly).  
  临时跳过钩子：`git commit -n`（谨慎使用）。

## Install/Update hook | 安装/更新钩子
Recommended 推荐：create a symlink to keep it in sync | 用符号链接保持同步

macOS/Linux:
```bash
chmod +x tools/hooks/pre-commit
mkdir -p .git/hooks
ln -sf ../../tools/hooks/pre-commit .git/hooks/pre-commit
```

Windows (Git Bash):
```bash
chmod +x tools/hooks/pre-commit
mkdir -p .git/hooks
ln -sf ../../tools/hooks/pre-commit .git/hooks/pre-commit
```

Copy alternative 复制方式:
```bash
chmod +x tools/hooks/pre-commit
cp tools/hooks/pre-commit .git/hooks/pre-commit
```

## Verify locally | 本地验证
- Make a trivial change, then `git commit -m "chore: verify hooks"`  
- Expect: format/fix may stage changes; analyzer prints infos/warnings only; tests must pass.  
- 做一个微小改动后提交：格式化/修复可能会改动并自动加入暂存；分析仅提示信息/警告；测试需通过。

## Common Q&A | 常见问答
- Q: Why analyzer infos/warnings not blocking?  
  A: To avoid friction. Errors should block; infos/warnings are for awareness.  
- 问：为何 info/warning 不阻断？  
  答：降低阻力；错误应阻断，信息/警告用于提醒。

- Q: How to see outdated dependencies?  
  A: Hook prints `flutter pub outdated` table; run manually for details.  
- 问：如何查看过期依赖？  
  答：钩子会输出结果；也可手动运行以获取更多细节。

- Q: How to speed up?  
  A: Run unit tests selectively or use caching in CI. Local hook keeps tests but you can adjust if needed.  
- 问：如何提速？  
  答：本地可以按需调整测试策略；CI 中使用缓存更显著。

## Reuse in other projects (e.g., Objective‑C) | 在其它项目复用（如 objc）
Git hooks are language-agnostic. Replace commands with your stack equivalents.  
Git 钩子与语言无关，替换为对应生态命令即可。

Example for iOS/objc 示例:
```bash
#!/usr/bin/env bash
set -euo pipefail

echo "[pre-commit] Formatting (clang-format)..."
# find and format staged files, e.g., *.m,*.h
git diff --cached --name-only --diff-filter=ACM | grep -E '\.(m|mm|h|c|cpp)$' | xargs -r clang-format -i

echo "[pre-commit] Lint (swiftlint, optional)..."
if command -v swiftlint &>/dev/null; then
  swiftlint || true
fi

echo "[pre-commit] Build & tests (xcodebuild)..."
set +e
xcodebuild test \
  -scheme YourApp \
  -workspace YourApp.xcworkspace \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -quiet
xc_status=$?
set -e

if [ $xc_status -ne 0 ]; then
  echo "xcodebuild tests failed."
  exit $xc_status
fi

# Auto-add formatting changes
git add -A
```

Tips 提示:
- Ensure executable permission: `chmod +x .git/hooks/pre-commit`  
- Keep failures meaningful (tests/build failures return non‑zero).  
- 可执行权限需开启；失败应仅代表真实问题（构建/单测失败）。

## Maintenance | 维护建议
- Keep `tools/hooks/pre-commit` the single source of truth; use symlink.  
- Document skip rules and local debug command in README.  
- 单一脚本源，符号链接；在 README 标注跳过方式与调试命令。

## Related docs | 相关文档
- PR Template / 拉取请求模板: `.github/pull_request_template.md`
- Commands Cheat Sheet / 常用命令清单: `docs/command.md`