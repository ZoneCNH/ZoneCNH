# 自动化提交合并工作流

本文定义任务完成后的本地自动交付闭环：Codex Stop hook 检测到 `task_complete` 后，在 feature worktree 中完成提交、受控合并、同步和清理。

## 目标

- 检测任务完成事件后自动提交已验证变更。
- 只允许从非 `main` 分支合并到 `main`。
- 合并前确认 `main` 干净且与 `origin/main` 一致。
- 合并只使用 `fast-forward`，失败时保留分支和 worktree 供人工处理。
- 若提交已完成但合并曾被阻断，后续 clean feature 分支可重试合并和清理。
- 合并成功后自动清理 feature worktree 和已合并分支。
- 运行状态写入 Git 内部目录，不污染待提交文件。

## 入口

仓库级 Codex hook 位于 `.codex/hooks.json`，Stop 事件会先定位当前 Git 仓库根目录，再执行：

```text
/usr/bin/env bash -c 'repo=$(git rev-parse --show-toplevel 2>/dev/null) || ...; cd "$repo" && exec scripts/auto-deliver-on-complete.sh --hook'
```

脚本默认只在检测到 `task_complete` 时执行。若 hook payload 无法直接携带完成事件，可通过以下变量调整：

| 变量                                  | 默认值                                          | 用途                                     |
| ------------------------------------- | ----------------------------------------------- | ---------------------------------------- |
| `AUTO_DELIVERY_FORCE`                 | `0`                                             | 设为 `1` 时跳过完成事件检测              |
| `AUTO_DELIVERY_REQUIRE_TASK_COMPLETE` | `1`                                             | 设为 `0` 时每次 Stop 都尝试交付          |
| `AUTO_DELIVERY_MERGE`                 | `1`                                             | 设为 `0` 时只提交不合并                  |
| `AUTO_DELIVERY_RETRY_MERGE`           | `1`                                             | clean feature 分支上重试合并和清理       |
| `AUTO_DELIVERY_PUSH`                  | `0`                                             | 设为 `1` 时合并后 `git push origin main` |
| `AUTO_DELIVERY_CLEANUP`               | `1`                                             | 设为 `0` 时保留 worktree 和分支          |
| `AUTO_DELIVERY_VERIFY_CMD`            | `git diff --check && git diff --cached --check` | 覆盖提交前验证命令                       |
| `AUTO_DELIVERY_COMMIT_SUBJECT`        | `chore: 自动交付已验证的任务完成变更`           | 覆盖自动提交标题                         |

## 门禁

脚本按以下顺序执行：

1. 确认当前目录属于 Git 仓库。
2. Hook 模式下检测 `task_complete`；未检测到则跳过。
3. 确认当前分支不是 `main`，且不是 detached HEAD。
4. 若工作区无变更且启用 `AUTO_DELIVERY_RETRY_MERGE=1`，直接进入合并重试路径。
5. 若工作区存在变更，`git add -A` 后扫描 staged 文件名和 diff 内容，阻止凭证、密钥和 `.env` 等敏感内容自动提交。
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

如需在提交已存在、工作区干净时重试合并：

```text
AUTO_DELIVERY_FORCE=1 scripts/auto-deliver-on-complete.sh --hook < /dev/null
```

## 受保护工作流说明

这是交付工作流改进，按 `CONSTITUTION.md` 第十四条和 `docs/governance/DEVELOPMENT-WORKFLOW.md` 的要求，配套元级改进规格位于：

```text
docs/governance/improvements/20260609-auto-delivery-hook/SPEC.md
```

合入主线前仍需完成项目要求的元级管线评审与授权。

---

## S-7 反向工作流议题（2026-06-22 新增）

### 问题陈述

近 30 天 1266 commits（日均 42）集中在 "preserve evidence" / "保存已验证变更" / "avoid 传播未经验证断言" 等语义，反映**文档追代码**的反向工作流：大量精力消耗在文档同步而非实现推进。

### 根因分析（来自 report/architecture-structural-analysis-20260622.md §7.2）

**投影层与事实层未分离**：

- **投影层**：`ARCHITECTURE.md` / `STATUS.md` / `README.md` 中的版本号、进度百分比、组件计数（全手工）
- **事实层**：`.foundationx/status/index.json`（机器生成，仅覆盖 21 个 Foundation 模块）

每次实现变更需手工同步多处投影，churn 高。业务域模块（分析/决策/执行域，47 个）完全无机器事实源，仍全部手工维护。

### 修复路径（分阶段）

| 阶段 | 范围 | 工具 | 状态 |
| --- | --- | --- | --- |
| Phase 1 | Foundation 21 模块 fact→projection 只读 diff | `scripts/projection-sync.py`（雏形） | ✅ 2026-06-22 |
| Phase 2 | 建立业务域事实层（factor_engine/signal_factory 等 32 模块） | 待规划：扩展 `.foundationx/status/index.json` schema 或独立 `.foundationx/business/index.json` | ⏳ |
| Phase 3 | 投影自动写入 STATUS 手工块（auto-patch） | 升级 projection-sync.py 支持 `--apply` 模式 | ⏳ |
| Phase 4 | README/ARCHITECTURE 全部纳入投影范围 | 进一步分离手工块与机器块 | ⏳ |

### 当前可消费工具

```text
python3 scripts/projection-sync.py            # 报告 + exit code（0=一致 / 1=漂移）
python3 scripts/projection-sync.py --json     # 机器可读 JSON
```

报告示例字段：

```text
foundation_factory_grade: 20/21 (machine fact)
foundation_open_blockers: 0
dashboard.total: 73 (manual; PENDING_FACT_SOURCE 因业务域无事实层)
```

### 与 audit-status.py 的关系

- **`audit-status.py`**：横向一致性检查（STATUS 内部跨字段、跨表数字是否自洽，目前 51/51 PASS）
- **`projection-sync.py`**：纵向投影↔事实对齐检查（手工数字 vs 机器事实是否漂移）

两者并行运行，互不替代：

```text
python3 scripts/audit-status.py        # 自洽性
python3 scripts/projection-sync.py     # 真实性
```

### 计量目标

| 指标 | 当前 | Phase 4 目标 |
| --- | --- | --- |
| 手工同步 commit 占比（近 30 天） | 估约 60% | < 20% |
| Foundation 数字漂移检测延迟 | 手工（不定） | CI 自动（< 5 min） |
| 业务域数字事实源覆盖 | 0% | 100% |
