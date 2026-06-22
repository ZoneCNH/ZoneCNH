# Git 分支治理与工作树审计报告

> **分析日期**：2026-06-22
> **分析范围**：当前仓库的本地分支、远端分支、工作树位置与 `scripts/branch-governance.mjs` 输出
> **证据标签**：`[KNOWN]` 来自 `git` / 规则脚本 / 文档；`[INFERRED]` 来自跨证据归纳
> **置信度**：HIGH

---

## 摘要

本次审计的结论很清楚：**仓库当前处于干净状态，但分支治理并未完全收敛**。

- 本地工作区：clean
- 当前 HEAD：detached
- `main`：与 `origin/main` 同步
- 远端可见的 4 条治理相关分支中，存在 3 条需要人工继续处理，1 条可作为明确清理候选
- 规则脚本额外识别出 1 条 **canonical worktree path violation**

**结论**：仓库没有未提交脏改，但存在需要继续合并、同步或清理的分支治理事项；其中最明确的收尾对象是 `origin/fix/binance-p0p1-fixes-20260622`。

---

## 1. 审计方法

本次审计只使用仓库本地证据，不依赖外部推断：

- `git status --short --branch`
- `git branch -vv --no-abbrev`
- `git branch -r`
- `git rev-list --left-right --count <remote>/<branch>...origin/main`
- `git worktree list --porcelain`
- `node scripts/branch-governance.mjs --json`

另外，按团队要求并行调用了两个只读子代理：

- **Kierkegaard** `019eedb1-6600-7af1-93da-093873440b73`：检查分支/工作树拓扑与合并面风险
- **Lorentz** `019eedb1-74eb-7252-92ca-8302e4333e52`：检查可行的验证命令与测试路径

两者结论已并入本报告的发现与建议。

---

## 2. 事实层

### 2.1 本地状态

| 项目 | 结果 |
|---|---|
| 工作区状态 | clean |
| 当前分支 | detached HEAD |
| `main` 对 `origin/main` | 同步 |
| 当前仓库根路径 | `/home/ZoneCNH/.worktree/omx-team/git-3161440a/worker-3` |

### 2.2 远端分支可见面

`git branch -r` 直接可见的相关远端分支如下：

- `origin/docs/align-7-review-substate-20260622`
- `origin/docs/binance-alignment-sync-20260622`
- `origin/fix/binance-p0p1-clean-20260622`
- `origin/fix/binance-p0p1-fixes-20260622`
- `origin/main`

### 2.3 与 `origin/main` 的双向差异

| 远端分支 | ahead/behind `origin/main` | 读法 |
|---|---:|---|
| `origin/docs/align-7-review-substate-20260622` | `1 1` | 双向都有差异，需要人工合并判断 |
| `origin/docs/binance-alignment-sync-20260622` | `2 2` | 双向都有差异，需要人工合并判断 |
| `origin/fix/binance-p0p1-clean-20260622` | `3 1` | 分支仍有独立提交，且 `main` 也有后续更新 |
| `origin/fix/binance-p0p1-fixes-20260622` | `4 0` | 分支完全落后于 `main`，可优先视为关闭/清理候选 |

### 2.4 规则脚本输出

`node scripts/branch-governance.mjs --json` 的关键结果：

| 指标 | 值 |
|---|---:|
| `openPrs` | 0 |
| `mergeCandidates` | 0 |
| `fixCandidates` | 0 |
| `deleteCandidates` | 0 |
| `closeCandidates` | 0 |
| `unpublishedBranches` | 0 |
| `worktreePathViolations` | 1 |

脚本识别出的唯一 worktree path violation：

- branch: `docs/binance-deep-analysis-v2-20260622`
- actual path: `/home/ZoneCNH`
- expected canonical path: `/home/ZoneCNH/.worktree/omx-team/git-3161440a/worker-3/.worktree/workspaces/docs/binance-deep-analysis-v2-20260622`
- reason: `branch-attached worktree path is not canonical`

---

## 3. 发现

### 3.1 无脏改，但不是“无事可做”

仓库当前 clean，说明没有未保存的本地修改干扰治理判断；但 clean 并不等于治理收敛。  
本次审计确认的主要风险是**分支层面的待处理项**，不是文件层面的脏状态。

### 3.2 detached HEAD 需要留意

当前是 detached HEAD。  
这本身不一定错误，但在需要继续分支治理或补后续提交时，容易让后续动作落在不合适的引用上，因此应先确认是否要：

1. 维持 detached 作为只读检查态；或
2. 重新附着到目标分支后再做后续治理。

### 3.3 `origin/fix/binance-p0p1-fixes-20260622` 是最明确的清理候选

该分支相对 `origin/main` 为 `4 0`，即**全部提交已经包含在 main 中**。  
这意味着它不再承载可保留的独立增量，适合进入关闭或删除评估流。

### 3.4 两条 docs 分支仍需要人工合并判断

`origin/docs/align-7-review-substate-20260622` 与 `origin/docs/binance-alignment-sync-20260622` 都不是单向可删状态，而是双向有差异：

- `1 1`
- `2 2`

这种状态说明两边都有未对齐内容，不能仅按“落后”或“已包含”做机械处理，必须先判断内容是否重复、互补或互斥。

### 3.5 worktree path violation 指向治理约束而不是内容错误

违规项不是源码错误，而是**路径布局不符合 canonical 规则**。  
这类问题通常对应：

- worktree 绑定位置不在约定目录；
- 分支与工作树绑定关系需要重新整理；
- 只读审计态与可提交态没有分离清楚。

---

## 4. 清理与同步建议

### P0：先处理可确定的关闭候选

1. 复核 `origin/fix/binance-p0p1-fixes-20260622`
2. 若确认无未迁移价值，按仓库策略推进关闭/删除

### P1：继续判断两条 docs 分支

1. 对 `origin/docs/align-7-review-substate-20260622`
2. 对 `origin/docs/binance-alignment-sync-20260622`

建议先比对提交主题和变更范围，再决定：

- 合并进主线
- 作为文档同步分支保留
- 或改为短生命周期审计分支后收尾

### P1：修正 canonical worktree path violation

对 `docs/binance-deep-analysis-v2-20260622`：

- 要么迁移/重建到规范 worktree 路径
- 要么确认其为历史性绑定并解除当前不规范关联

### P2：保持当前 clean 状态

当前没有文件脏改，这是本轮治理推进的良好前提。  
建议后续继续把这份 clean 状态维持到分支整理动作完成，不要在未决分支上混入无关编辑。

---

## 5. 结论

本次审计没有发现未提交内容或新的代码缺陷，但发现了**明确的分支治理尾巴**：

1. `main` 已同步 `origin/main`
2. `origin/fix/binance-p0p1-fixes-20260622` 是最确定的关闭候选
3. 两条 docs 分支仍处于双向分歧，需要人工判断
4. `docs/binance-deep-analysis-v2-20260622` 存在 canonical worktree path violation

因此，本轮的正确收尾不是“修代码”，而是**补完分支治理报告并把后续处置对象列清楚**。
