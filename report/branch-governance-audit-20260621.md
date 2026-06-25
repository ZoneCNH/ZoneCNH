# Git 分支治理审计与清理路径

**日期**: 2026-06-21  
**范围**: 当前仓库的本地分支、远程跟踪分支与工作树占用情况  
**目标**: 记录“先备份、再合并、再验证、最后清理”的分支治理闭环，最终收敛到 `main` 作为唯一长期保留分支。

> 说明：本文是**审计与操作路径文档**，不是自动执行记录。  
> 当前状态下，`main` 仍可作为稳定基线；`governance/integration-20260621T152330Z` 仍是待收口的综合分支，不应在未验证前直接删除。

---

## 1. 现场快照

- 当前工作树：`HEAD (no branch)`，指向 `ce29d4dc7470022f9746f6c630e93ddcd563db61`
- `main`：`92ad34759c5d2e1378157860a2008647fb8fa806`
- 远程默认分支：`origin/HEAD -> origin/main`
- 当前综合分支：`governance/integration-20260621T152330Z`
- 已进入 `main` 的历史收口分支：
  - `docs/clickhousex-release-evidence-sync`
  - `governance/final-integration-20260621T125038Z`

### 1.1 已确认的分支关系

| 分支 | 与 `main` 的关系 | 结论 |
| ---- | ---- | ---- |
| `docs/binance-features-acceptance` | 相对 `main`：1 个独有提交，且已被 `governance/integration-20260621T152330Z` 吸收 | 可作为历史分支保留到备份完成后清理 |
| `docs/binance-traceability-fix` | 与 `fix/binance-spec-traceability-drift` 指向同一提交 `c33ea4f4` | 这是别名/重复分支，保留一个即可 |
| `fix/binance-spec-traceability-drift` | 与 `docs/binance-traceability-fix` 指向同一提交 `c33ea4f4` | 这是别名/重复分支，保留一个即可 |
| `docs/clickhousex-v1.0.10-sync` | 已被 `governance/final-evidence-preservation-20260621T123651Z` 继承，后者又被 `governance/integration-20260621T152330Z` 继承 | 可在合并后清理 |
| `governance/final-evidence-preservation-20260621T123651Z` | 已被 `governance/integration-20260621T152330Z` 继承 | 作为中间收口分支，合并完成后可清理 |
| `governance/integration-20260621T152330Z` | 相对 `main` 仍未收口 | 这是当前需要先合并到 `main` 的综合分支 |

### 1.2 关键判断

1. **`governance/integration-20260621T152330Z` 是当前唯一需要优先收口的综合分支**。  
   它携带了 binance / contracts / clickhousex 的收口结果，但 `main` 尚未吸收。
2. **`docs/binance-traceability-fix` 与 `fix/binance-spec-traceability-drift` 是同一提交的双命名分支**。  
   清理前必须先做备份并确认没有工作树或远程依赖其中任一名字。
3. **`docs/clickhousex-v1.0.10-sync`、`governance/final-evidence-preservation-20260621T123651Z` 属于已被更上层综合分支继承的中间层**。  
   它们的价值主要在历史追踪，不再是长期保留分支候选。
4. **已进 `main` 的两个分支不需要重复合并**。  
   即 `docs/clickhousex-release-evidence-sync` 与 `governance/final-integration-20260621T125038Z` 只需保留为历史记录。

---

## 2. 合并优先级

### 2.1 推荐顺序

1. **先备份**
   - 记录 `refs.txt`
   - 记录 `worktree list`
   - 保存必要的 `stash` / 暂存区补丁
   - 确认 `origin/main` 与本地 `main` 同步点

2. **先合并综合分支到 `main`**
   - 将 `governance/integration-20260621T152330Z` 合并到 `main`
   - 保持 `main` 可测试、可回退
   - 如有冲突，先解决文档/投影冲突，再执行验证

3. **再验证**
   - 运行仓库要求的最小验证集
   - 对文档仓库至少执行：`git diff --check`、相关 lint / test / typecheck（若仓库提供）
   - 任何失败都先修复，再进入清理阶段

4. **最后清理分支**
   - 删除已经被 `main` 吸收的本地分支
   - 删除对应远程分支
   - 对重复别名分支只保留一个 canonical 名称，另一条直接清理
   - 清理后执行 `git worktree prune`

### 2.2 不建议的做法

- 不要在未备份时直接 `git branch -D`
- 不要在未验证 `main` 之前删除综合分支
- 不要同时删除一对别名分支的两个名字
- 不要把 worktree 目录残骸和分支引用混为一谈；二者清理流程不同

---

## 3. 清理路径

### 3.1 本地分支

建议按以下规则处理：

| 分支 | 建议动作 | 备注 |
| ---- | ---- | ---- |
| `governance/integration-20260621T152330Z` | 合并到 `main` 后删除 | 这是当前收口入口 |
| `docs/binance-features-acceptance` | 合并确认后删除 | 已被综合分支吸收 |
| `docs/binance-traceability-fix` / `fix/binance-spec-traceability-drift` | 保留一个 canonical 名称，删除另一个 | 这是重复引用，不应双保留 |
| `docs/clickhousex-v1.0.10-sync` | 合并确认后删除 | 已被上层分支继承 |
| `governance/final-evidence-preservation-20260621T123651Z` | 合并确认后删除 | 中间层历史分支 |
| `docs/clickhousex-release-evidence-sync` | 保留历史记录或删除 | 已在 `main` 中；按仓库政策决定 |
| `governance/final-integration-20260621T125038Z` | 保留历史记录或删除 | 已在 `main` 中；按仓库政策决定 |

### 3.2 远程分支

远程清理顺序与本地一致：

1. 先确认 `main` 已包含目标提交
2. 再执行 `git push origin --delete <branch>`
3. 最后核对 `git fetch --prune` 后远程引用已消失

### 3.3 工作树

如果某个分支还绑定有 worktree，必须先解除工作树占用，再删分支：

1. `git worktree list`
2. 对应 worktree 若不再使用，先切走或删除目录
3. `git worktree prune`
4. 再删除分支引用

---

## 4. 验证要求

收口到 `main` 前，至少确认：

- `git status --short --branch` 无意外脏状态
- `git branch --merged main` 结果仅包含已确认可以保留的历史分支
- `git branch --no-merged main` 只剩仍待收口或刻意保留的分支
- `git worktree list` 不再引用待删分支
- 文档或代码变更通过仓库要求的测试 / lint / typecheck

---

## 5. 当前结论

1. **当前仓库不应直接清空所有分支**；正确顺序是先把 `governance/integration-20260621T152330Z` 收口到 `main`。  
2. **`docs/binance-traceability-fix` 与 `fix/binance-spec-traceability-drift` 是重复分支名问题**，应在备份后收敛为单一 canonical 名称。  
3. **`docs/clickhousex-v1.0.10-sync` 与 `governance/final-evidence-preservation-20260621T123651Z` 属于中间层历史分支**，适合在综合分支进入 `main` 后按清理路径回收。  
4. **`main` 已可用**，本次治理的核心目标是把剩余有价值内容集中回 `main`，然后再做本地/远程/工作树三层清理。

