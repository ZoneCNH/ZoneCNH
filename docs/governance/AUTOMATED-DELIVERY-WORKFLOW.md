# 自动化提交合并工作流

本文定义任务完成后的本地自动交付闭环：Codex Stop hook 检测到 `task_complete` 后，在 feature worktree 中完成提交、受控合并、同步和清理。

## 目标

- 检测任务完成事件后自动提交已验证变更。
- 只允许从非 `main` 分支合并到 `main`。
- 合并前确认 `main` 干净且与 `origin/main` 一致。
- 合并只使用 `fast-forward`，失败时保留分支和 worktree 供人工处理。
- 合并成功后自动清理 feature worktree 和已合并分支。
- 运行状态写入 Git 内部目录，不污染待提交文件。

## 入口

仓库级 Codex hook 位于 `.codex/hooks.json`，Stop 事件会先定位当前 Git 仓库根目录，再执行：

```text
/usr/bin/env bash -c 'repo=$(git rev-parse --show-toplevel 2>/dev/null) || ...; cd "$repo" && exec scripts/auto-deliver-on-complete.sh --hook'
```

脚本默认只在检测到 `task_complete` 时执行。若 hook payload 无法直接携带完成事件，可通过以下变量调整：

| 变量 | 默认值 | 用途 |
|------|--------|------|
| `AUTO_DELIVERY_FORCE` | `0` | 设为 `1` 时跳过完成事件检测 |
| `AUTO_DELIVERY_REQUIRE_TASK_COMPLETE` | `1` | 设为 `0` 时每次 Stop 都尝试交付 |
| `AUTO_DELIVERY_MERGE` | `1` | 设为 `0` 时只提交不合并 |
| `AUTO_DELIVERY_PUSH` | `0` | 设为 `1` 时合并后 `git push origin main` |
| `AUTO_DELIVERY_CLEANUP` | `1` | 设为 `0` 时保留 worktree 和分支 |
| `AUTO_DELIVERY_VERIFY_CMD` | `git diff --check && git diff --cached --check` | 覆盖提交前验证命令 |
| `AUTO_DELIVERY_COMMIT_SUBJECT` | `chore: 自动交付已验证的任务完成变更` | 覆盖自动提交标题 |

## 门禁

脚本按以下顺序执行：

1. 确认当前目录属于 Git 仓库。
2. Hook 模式下检测 `task_complete`；未检测到则跳过。
3. 确认当前分支不是 `main`，且不是 detached HEAD。
4. 确认工作区存在变更。
5. `git add -A` 后扫描 staged 文件名和 diff 内容，阻止凭证、密钥和 `.env` 等敏感内容自动提交。
6. 执行验证命令。
7. 使用 Lore 协议生成提交信息并提交。
8. 若启用合并，确认 `main` worktree 干净且 `main == origin/main`。
9. 对 `main` 执行 `git merge --ff-only <branch>`。
10. 若启用 push，则推送 `origin main`。
11. 若启用清理，则合并后移除 feature worktree 并删除已合并分支。

任一门禁失败时，脚本阻断提交或合并，但 hook 仍返回 `continue: true`，避免破坏 Codex 会话。

## 运行状态

状态和日志写入 Git common dir：

```text
.git/auto-delivery/
├── auto-delivery.log
├── commit-message.txt
├── hook-payload.json
└── status.json
```

这些文件不是仓库内容，不会进入自动提交。

## 与分支纪律的关系

本工作流执行 `CONSTITUTION.md` 第零条：

- 不在 `main` 上编辑或提交。
- 只在 feature worktree 中自动提交。
- `main` 只接收已完成分支的 `fast-forward` 合并。
- `main` 不干净、未同步或与远程不一致时停止。
- 合并完成后清理 worktree。

当前 `main` 若存在未跟踪文件、未提交变更或本地 ahead/behind 状态，自动合并会被阻断。

## 验证

本地验证命令：

```text
AUTO_DELIVERY_FORCE=1 AUTO_DELIVERY_DRY_RUN=1 scripts/auto-deliver-on-complete.sh --hook < /dev/null
git diff --check
python3 -m pytest scripts/tests
```

如需测试完整提交但不合并：

```text
AUTO_DELIVERY_FORCE=1 AUTO_DELIVERY_MERGE=0 scripts/auto-deliver-on-complete.sh --hook < /dev/null
```

## 受保护工作流说明

这是交付工作流改进，按 `CONSTITUTION.md` 第十四条和 `docs/governance/DEVELOPMENT-WORKFLOW.md` 的要求，配套元级改进规格位于：

```text
docs/governance/improvements/20260609-auto-delivery-hook/SPEC.md
```

合入主线前仍需完成项目要求的元级管线评审与授权。
