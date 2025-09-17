# Objective‑C/iOS Git Hooks Guide | Objective‑C/iOS Git 钩子指南

Practical pre-commit hook patterns for ObjC/iOS repositories.  
面向 ObjC/iOS 仓库的 pre-commit 钩子实战指南。

## Goals | 目标
- Enforce code style (clang-format)  
- Optional lint (SwiftLint for Swift-mixed repos)  
- Build & test gate (xcodebuild test)  
- Keep failures meaningful (only real breakages block commits)  
- 统一代码风格（clang-format）  
- 可选静态检查（Swift 混编可用 SwiftLint）  
- 构建与单测闸门（xcodebuild test）  
- 保持失败有意义（仅真实问题阻断提交）

## Install | 安装
Hook path must be `.git/hooks/pre-commit` and executable.  
钩子必须位于 `.git/hooks/pre-commit` 且具可执行权限。

Symlink (recommended) | 符号链接（推荐）:
```bash
chmod +x tools/hooks/pre-commit-objc
mkdir -p .git/hooks
ln -sf ../../tools/hooks/pre-commit-objc .git/hooks/pre-commit
```

Copy (alternative) | 复制方式：
```bash
chmod +x tools/hooks/pre-commit-objc
cp tools/hooks/pre-commit-objc .git/hooks/pre-commit
```

Skip temporarily | 临时跳过：
```bash
git commit -n -m "msg"
```

## Example pre-commit for ObjC | ObjC 示例 pre-commit
Save as `tools/hooks/pre-commit-objc` and symlink to `.git/hooks/pre-commit`.  
将以下脚本保存为 `tools/hooks/pre-commit-objc`，再链接到 `.git/hooks/pre-commit`。

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "[pre-commit] Detecting staged ObjC/C/C++ files..."
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(m|mm|h|c|cc|cpp)$' || true)

echo "[pre-commit] Formatting (clang-format)..."
if command -v clang-format &>/dev/null; then
  if [[ -n "${STAGED_FILES}" ]]; then
    # Format only staged files in place
    echo "${STAGED_FILES}" | xargs -r clang-format -i
    # Re-stage formatted files
    echo "${STAGED_FILES}" | xargs -r git add
  else
    echo "No staged ObjC/C/C++ files."
  fi
else
  echo "clang-format not found. Install via Homebrew: brew install clang-format" >&2
fi

echo "[pre-commit] Lint (SwiftLint, optional)..."
if command -v swiftlint &>/dev/null; then
  # Non-blocking warnings; block on errors by default behavior
  swiftlint || true
else
  echo "SwiftLint not found (skipping). Install: brew install swiftlint"
fi

echo "[pre-commit] Running unit tests (xcodebuild test)..."
# TIP: Adjust workspace/project, scheme, destinations to your repo
# 支持 .xcworkspace 或 .xcodeproj，按需选择其一
SCHEME="${SCHEME:-YourApp}"
WORKSPACE="${WORKSPACE:-YourApp.xcworkspace}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 15}"
set +e
if [[ -f "$WORKSPACE" ]]; then
  xcodebuild test \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -quiet
  XC_STATUS=$?
else
  PROJECT="${PROJECT:-YourApp.xcodeproj}"
  xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -quiet
  XC_STATUS=$?
fi
set -e

if [[ $XC_STATUS -ne 0 ]]; then
  echo "xcodebuild tests failed. Blocking commit."
  exit $XC_STATUS
fi

echo "[pre-commit] Done."
```

Environment overrides | 环境变量覆盖:
- SCHEME: default YourApp  
- WORKSPACE or PROJECT: choose one based on your repo  
- DESTINATION: default platform=iOS Simulator,name=iPhone 15  
- 可通过环境变量覆盖方案名、工作区/工程、执行目标（模拟器）

Example usage | 示例：
```bash
SCHEME=MyApp WORKSPACE=MyApp.xcworkspace DESTINATION='platform=iOS Simulator,name=iPhone 15 Pro' git commit -m "feat: add feature"
```

## Code style with clang-format | 使用 clang-format 的代码风格
- Provide a `.clang-format` at repo root to standardize style.  
- Use LLVM/Google/Chromium presets as baseline and tweak.  
- 在仓库根提供 `.clang-format` 统一风格；可基于 LLVM/Google/Chromium 预设调整。

Quick start `.clang-format` | 快速开始示例：
```yaml
BasedOnStyle: Google
IndentWidth: 2
ColumnLimit: 120
ObjCBlockIndentWidth: 2
SpacesInContainerLiterals: true
AlignConsecutiveDeclarations: Consecutive
```

## SwiftLint (optional for mixed Swift) | Swift 混编可选
- Add `.swiftlint.yml` with rules you care about.  
- Keep warnings non-blocking; fail on serious issues if desired.  
- 在根目录添加 `.swiftlint.yml`；将一般警告设为不过线，严重问题可阻断。

## Blocking strategy | 阻断策略
- Block on: unit test failures, compile failures.  
- Do not block on: style/lint warnings (print and move on).  
- 阻断：单测失败/编译失败。  
- 不阻断：风格/一般 lint 警告（仅提示）。

## CI alignment | 与 CI 对齐
- Mirror the same steps in CI but allow longer, richer checks (e.g., full matrix, code coverage upload).  
- 在 CI 复用相同步骤，CI 可做更全面的检查（矩阵测试、覆盖率上报等）。

## Troubleshooting | 排错
- xcodebuild fails with destination error → ensure Simulator runtime installed (Xcode > Settings > Platforms).  
- Permission denied → `chmod +x .git/hooks/pre-commit`.  
- clang-format not found → `brew install clang-format`.  
- xcodebuild 目的地错误 → 安装对应模拟器运行时；权限问题 → 赋予执行权限；缺少 clang-format → 用 Homebrew 安装。

## Related | 相关
- Git Hooks overview: `docs/git-hooks.md`  
- Apple xcodebuild doc: `man xcodebuild`  
- clang-format style options: LLVM docs