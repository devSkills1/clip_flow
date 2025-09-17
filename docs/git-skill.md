# Git Skills | Git 技巧清单

常用与高级 Git 技巧速查（EN-ZH 对照，示例可直接复制）。

## Staging & Commit 精细暂存与提交
- Interactively stage hunks 交互式分块暂存
  - 命令：git add -p
  - 示例：
    ```
    # 仅暂存当前文件的部分改动（逐块选择 y/n/s）
    git add -p lib/core/utils/color_utils.dart
    ```
- Amend last commit 修正上一条提交
  - 命令：git commit --amend
  - 示例：
    ```
    # 只修改提交说明，不变更代码
    git commit --amend

    # 修正上一条提交但保留原消息（仅追加更改）
    git add README.md
    git commit --amend --no-edit
    ```
- Interactive rebase 交互式整理历史
  - 命令：git rebase -i HEAD~N
  - 示例：
    ```
    # 重写最近 5 条提交：合并(squash)/改消息(reword)/重排
    git rebase -i HEAD~5
    # 编辑界面中把需要合并到上一条的提交前缀改为 squash 或 fixup
    ```

## Branch & History 分支与历史
- Create/switch branch 创建/切换分支
  - 命令：
    - git switch -c feature/x
    - git switch master
  - 示例：
    ```
    git switch -c feat/clipboard-history
    # 开发完成后切回主分支
    git switch master
    ```
- Merge with no-ff 保留合并节点
  - 命令：git merge --no-ff feature/x
  - 示例：
    ```
    # 在 master 合并功能分支，保留 merge commit 便于回溯
    git switch master
    git merge --no-ff feat/clipboard-history -m "merge: feat clipboard history"
    ```
- Cherry-pick 选择性拣入提交
  - 命令：git cherry-pick <sha>
  - 示例：
    ```
    # 把修复提交拣入到 release 分支
    git switch release/1.2
    git cherry-pick a1b2c3d
    ```
- Revert 回滚已推送提交（安全）
  - 命令：git revert <sha>
  - 示例：
    ```
    # 生成一条反向提交来回滚已推送的 bug 提交
    git revert d4e5f6a
    ```

## Shelve Work & Parallel 开发现场与并行
- Stash changes 暂存工作区
  - 命令：
    - git stash / git stash -p
    - git stash pop / apply
  - 示例：
    ```
    # 暂存当前所有未提交更改
    git stash

    # 仅按块选择需要暂存的部分（更精细）
    git stash -p

    # 恢复最近一次暂存并删除该记录
    git stash pop
    ```
- Worktree 多工作树并行
  - 命令：
    - git worktree add ../repo-copy feature/x
    - git worktree list / remove <path>
  - 示例：
    ```
    # 在平行目录创建另一个工作树，切到某功能分支并行开发
    git worktree add ../clip_flow_pro-fix hotfix/crash-startup
    cd ../clip_flow_pro-fix
    # 完成修复后回到原仓库，删除该工作树
    git worktree remove ../clip_flow_pro-fix
    ```

## Inspect & Audit 审计与定位
- Blame 忽略空白变更
  - 命令：git blame -w path/to/file
  - 示例：
    ```
    git blame -w lib/core/services/database_service.dart
    ```
- Pretty log 图形化日志
  - 命令：git log --graph --decorate --oneline --all
  - 示例：
    ```
    git log --graph --decorate --oneline --all
    ```
- Bisect 二分定位引入问题的提交
  - 命令：
    - git bisect start
    - git bisect bad / git bisect good <sha>
    - git bisect reset
  - 示例：
    ```
    # 开始二分定位
    git bisect start
    git bisect bad          # 当前版本有问题
    git bisect good v1.0.0  # 指定一个已知好的标签/提交

    # 每轮编译运行测试后，标记 good/bad，Git 会自动跳到下一个点
    # 定位完成后复位
    git bisect reset
    ```

## Submodule & Subtree 外部依赖管理
- Submodule 子模块
  - 命令：
    - git submodule add <repo> vendor/lib
    - git submodule update --init --recursive
    - git submodule update --remote --merge
  - 示例：
    ```
    git submodule add https://github.com/owner/awesome-lib.git vendor/awesome-lib
    git submodule update --init --recursive
    # 拉取上游最新并合并
    git submodule update --remote --merge
    ```
- Subtree 子树（替代方案，推拉直观）
  - 命令：
    - git subtree add --prefix vendor/lib <repo> main --squash
    - git subtree pull --prefix vendor/lib <repo> main --squash
    - git subtree push --prefix vendor/lib <repo> main
  - 示例：
    ```
    git subtree add --prefix vendor/awesome-lib https://github.com/owner/awesome-lib.git main --squash
    # 拉取上游更新
    git subtree pull --prefix vendor/awesome-lib https://github.com/owner/awesome-lib.git main --squash
    ```

## Hooks & Policies 钩子与策略
- Client hooks 客户端钩子
  - pre-commit / commit-msg / pre-push 本地规范与检查
  - 文档：docs/git-hooks.md、docs/objc-hooks.md
  - 示例（安装符号链接）：
    ```
    chmod +x tools/hooks/pre-commit
    mkdir -p .git/hooks
    ln -sf ../../tools/hooks/pre-commit .git/hooks/pre-commit
    ```
- Server hooks 服务器钩子（需服务端）
  - pre-receive / update 强制策略（保护分支、签名校验）
  - 示例（说明向）：在 GitLab/Jenkins 服务器侧配置拒绝未签名提交的 pre-receive 脚本
- Conventional Commits 提交规范
  - 类型：feat/fix/docs/chore/refactor/test/build/ci
  - 示例：
    ```
    feat(home): 支持最近剪贴筛选
    fix(db): 修复初始化时的空表异常
    ```

## Large Files & History Cleanup 大文件与历史清理
- Git LFS 大文件
  - 命令：
    - git lfs install
    - git lfs track "*.psd" && git add .gitattributes
  - 示例：
    ```
    git lfs install
    git lfs track "*.png"
    git add .gitattributes
    git commit -m "chore: track png via LFS"
    ```
- Rewrite history 历史重写（谨慎）
  - 推荐：git filter-repo（替代 filter-branch）
  - 示例（删除历史中误提交的 .env）：
    ```
    # 需先安装 git-filter-repo，执行前请做好备份并与团队沟通
    git filter-repo --path .env --invert-paths
    ```

## Security & Signing 安全与签名
- GPG/SSH 签名提交
  - 命令：
    - git commit -S -m "msg"
    - git config --global commit.gpgsign true
  - 示例：
    ```
    # 单次签名提交
    git commit -S -m "feat: enable secure mode"

    # 全局启用签名提交
    git config --global commit.gpgsign true
    ```
- Protect secrets 秘钥防泄漏
  - .gitignore / git-secrets / pre-commit 扫描
  - 示例：
    ```
    # 忽略本地环境文件
    echo ".env" >> .gitignore
    git add .gitignore
    git commit -m "chore: ignore .env"
    ```

## Performance 性能与大仓
- Sparse checkout 稀疏检出
  - 命令：
    - git sparse-checkout init --cone
    - git sparse-checkout set path1 path2
  - 示例：
    ```
    git clone https://github.com/owner/huge-repo.git
    cd huge-repo
    git sparse-checkout init --cone
    git sparse-checkout set src/mobile src/common
    ```
- Partial clone 局部克隆（需服务器支持）
  - 命令：git clone --filter=blob:none --no-checkout <repo>
  - 示例：
    ```
    git clone --filter=blob:none --no-checkout https://github.com/owner/huge-repo.git
    cd huge-repo
    git checkout HEAD -- README.md
    ```

## Collaboration 协作增强
- CODEOWNERS 指定评审人
  - 文件：.github/CODEOWNERS
  - 示例：
    ```
    # 让 core 团队负责 core 目录评审
    /lib/core/*  @team-core
    ```
- Commit template 提交模板（你已配置）
  - 命令：git config --local commit.template .gitmessage
  - 示例：
    ```
    git config --local commit.template .gitmessage
    git commit
    # 将看到模板已自动填充到提交信息
    ```
- PR/MR 模板
  - 文件：.github/pull_request_template.md
  - 示例（说明向）：在 GitHub/GitLab 发起 MR/PR 时，该模板自动填充描述框

## Useful Aliases 常用别名（可选）
把常用长命令简化为别名（写入 ~/.gitconfig 的 [alias]）。
- lg = log --graph --decorate --oneline --all
- co = checkout
- ci = commit
- st = status -sb
- rb = rebase
- cp = cherry-pick
- last = log -1 HEAD
- br = branch -vv

示例配置：
```
git config --global alias.lg "log --graph --decorate --oneline --all"
git config --global alias.st "status -sb"
```

## Tips 小贴士
- 小步提交、信息清晰，结合 .gitmessage 模板提升可读性与可追溯性。
- 历史重写前先 push 保护分支或创建备份分支，团队同步后再执行。
- 遇到合并冲突，优先用 rebase 保持线性历史，必要时使用 --no-ff merge 保留大变更的合并节点。