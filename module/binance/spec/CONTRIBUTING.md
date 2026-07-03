# Binance 模块贡献指南

## 1. 目标

本文件定义 `module/binance/` 的文档贡献最小规则，确保规格、追溯、计划与 issue 状态持续一致。

## 2. 基本流程

1. 从 `main` 最新基线创建 feature 分支。
2. 先读再改：一次性确定改动清单后再编辑。
3. 仅改与当前任务直接相关的文件。
4. 提交前对齐同模块关键文档。

## 3. 必需对齐文件

- `goal/goal.md`
- `spec/SPEC.md`
- `matrix/TRACEABILITY.md`
- `README.md`
- `todo.md`

涉及计划映射时补充检查：

- `plans/binance/README.md`
- `plans/binance/011-runtime-gap-master-plan-20260702.md`
- `plans/binance/011-master-issue-map.tsv`

## 4. 任务状态规则

- `module/binance/todo.md` 是只读投影，不是关闭 SSOT。
- 关闭状态以 GitHub Issues 与 Beads 为准。
- 变更 issue 状态后，需要同步刷新投影文档。

## 5. Spec 版本规则

- `spec/SPEC.md` 的 `Spec-Version` 是模块规格版本唯一源。
- CHANGELOG 与其他文档不得高于 SPEC 版本。
- 涉及契约/要求变化时必须显式更新版本与追溯关系。

## 6. 提交规范

- 使用 Conventional Commits：`docs(...)` / `fix(...)` / `chore(...)`。
- 同一逻辑改动尽量聚合为单个 commit。
- 不使用破坏性 git 命令（如 `reset --hard`）。

## 7. Issue Close Gate（GAP-E58）

关闭 `runtime-gap` issue 前必须执行：

```bash
module/binance/scripts/runtime-gap-close-check.sh <主仓issue号> <binance-pr号>
```

约束：

1. `ZoneCNH/binance#<pr>` 必须是 `MERGED`。
2. `ZoneCNH/ZoneCNH#<issue>` 必须仍为 `OPEN`（先过门禁，再关单）。
3. 关单后必须同步 `module/binance/todo.md` 与 `plans/binance/010/011` 快照。

[RULES I BROKE]：无
