> **效力声明**：本文件内容提取自 [`CONSTITUTION.md`](../../CONSTITUTION.md)（FoundationX 最高治理文件）。
> 如本文件与根目录 `CONSTITUTION.md` 有差异，以 `CONSTITUTION.md` 为准。
>
> [← 上一节](preamble.md) · [↑ 目录](README.md) · [下一节 →](01-design-principles.md)

---

## 第零条：分支纪律（最高优先级）

> 本条优先级高于本文件所有其他条款。任何工作流、Agent 编排或人工操作不得违反。

### 0.1 禁止 main 开发

**严禁**在 `main` 分支上直接进行任何开发工作（包括但不限于：编写代码、编辑文档、运行实验性变更）。

| 操作             | main                           | worktree / feature branch |
| ---------------- | ------------------------------ | ------------------------- |
| 编辑文件         | ❌ 禁止                         | ✅ 必须                    |
| 提交变更         | ❌ 禁止（仅允许 merge/rebase）  | ✅ 必须                    |
| 运行实验         | ❌ 禁止                         | ✅ 必须                    |
| 合并已完成的工作 | ✅ 允许（通过 PR 或 merge）     | —                         |

### 0.2 强制使用 worktree

所有开发工作必须通过 `git worktree` 或 feature branch 进行：

0. **所有分支必须从 `main` HEAD 创建**——禁止从其他 feature branch、旧 commit 或 detached HEAD 拉取新分支。创建前必须先 `git fetch origin && git rebase origin/main`（或 `git pull --rebase`）确保本地 main 为最新。
1. **每个独立任务**必须在独立 worktree 或 feature branch 中执行（纯文档仓库允许 feature branch 替代 worktree；含源码的模块仓库应优先使用 `git worktree add`）
2. **分支/worktree 命名**必须遵循 `{type}/{module}-{description}` 格式（如 `docs/kernel-spec-update`、`feat/kernel-new-api`、`fix/redisx-timeout`），或 `{branch-name}` 格式（如 `feat/v2-foundation-trust-governance-20260615`）
3. **工作完成后**通过 PR 或 merge 合入 main，随后清理 worktree 和 feature branch
4. **禁止**在 main worktree 中堆积未提交变更
5. **ZoneCNH 纯文档仓库新增的 feature worktree** 统一放在 `/home/workspace/{module}/.worktree/workspaces/<branch-name>`，其中 `{module}` 是仓库目录名，`<branch-name>` 直接使用 Git 分支名本体（仅去掉 `refs/heads/` 前缀；分支名中的 `/` 会自然展开为嵌套目录）；该模板与 `scripts/worktree-policy.mjs` 的 canonical 规则一致。仓库根 checkout 作为分支工作区时不视为新增 worktree，不受此附加模板约束；不得再使用仓库根外的临时散落路径
6. **worktree 有效性以 Git 注册表为准**：只有出现在 `git worktree list --porcelain` 输出中的路径才是已注册 worktree；`.worktree/` 下的空目录或未注册目录只能视为运行态残留/临时目录，不得作为开发工作区。清理已注册 worktree 必须使用 `git worktree remove <path>`，随后用 `git worktree prune --dry-run --verbose` 验证无残留；禁止用裸 `rm -rf` 删除已注册 worktree
7. **禁止长期保留嵌套注册 worktree**：除仓库根目录下的 `.worktree/workspaces/` 规范槽位外，已注册 worktree 不应嵌套在另一个非根 worktree 内。短期 detached 运行态 worktree 必须保持可被 `git worktree list --porcelain` 发现，并在任务结束后按注册 worktree 流程清理

### 0.3 Agent 约束

所有 AI 代理（Claude、Codex、Copilot 及任何未来代理）在本仓库工作时：

1. **必须**在开始**编辑文件**前确认当前不在 main 分支（`git checkout main` 等 git 操作不受此约束）
2. **必须**使用 worktree 或 feature branch 隔离开发任务（参见 §0.2.1）
3. **禁止**在 main 上直接 commit
4. **发现** main 上有未提交变更时，**必须**停止并警告人类维护者
5. **禁止**未经授权创建 `module/{模块名}/` 目录或 `github.com/ZoneCNH/{模块名}` 仓库；遇到此类请求时必须拒绝并提示须先获双闸门授权（治理层 §12 修正程序审批 + 执行层人工会话显式授权，详见 §2.6）

### 0.4 例外

仅以下操作允许在 main 上执行：

- `git merge` / `git rebase` 合并已完成的分支
- `git pull` 同步远程更新
- 紧急 hotfix（需事后补充 worktree 流程记录）。hotfix 分支**同样必须从 `main` HEAD 创建**，不得从其他 feature branch 拉取

---
