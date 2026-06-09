# Goal 报告 Canonical Issue Ledger

账本日期：2026-06-09
最后更新：2026-06-09 agent team 修复验收后
适用范围：`docs/goal/`, `.config/goal/`, `docs/goal/tools/`, `docs/report/goal/`, `.worktree/todo.md`

## 状态定义

| 状态 | 含义 |
| --- | --- |
| `open` | 已确认，尚未修复 |
| `fixed` | 已修复并有本轮验证证据 |
| `deferred` | 有意延期，不阻塞当前目标 |
| `won't-fix` | 明确不修复 |

## 总览

| 优先级 | open | fixed | deferred |
| --- | ---: | ---: | ---: |
| P0 | 0 | 0 | 0 |
| P1 | 0 | 12 | 0 |
| P2/P3 | 0 | 5 | 3 |

最新复评分：`92/100`。验证证据见 `goal-docs-fix-verification-20260609.md`。

## Phase 0：报告目录化

| ID | Priority | Status | 问题 | 处理结果 |
| --- | --- | --- | --- | --- |
| `GDR-00-01` | P0 | fixed | 建立报告入口 | `docs/report/goal/README.md` 已说明目录用途、报告关系、当前状态和工作区风险 |
| `GDR-00-02` | P0 | fixed | 建立 canonical ledger | 本文件统一 canonical GDR ID、状态和关闭证据 |
| `GDR-00-03` | P1 | fixed | 记录工作区快照 | README 已记录 dirty/untracked 与 ignore 边界 |
| `GDR-00-04` | P1 | fixed | 记录评分基线 | README 已记录 `66/100`、`63/100` 和 `92/100` 复评分 |
| `GDR-00-05` | P2 | fixed | 定义报告生命周期 | README 已说明报告只追加、不覆盖历史审计 |

## Canonical GDR 问题

| ID | Priority | Status | 问题 | 修复证据 |
| --- | --- | --- | --- | --- |
| `GDR-AUTH-01` | P1 | fixed | 权威源分散 | `docs/goal/00-authority-map.md` 与 `.config/goal/README.md` 已定义 SSOT、Projection、Config、Runtime |
| `GDR-CONFIG-01` | P1 | fixed | 配置控制面边界不清 | `.gitignore` 放行 `.config/goal/` 控制面，继续忽略 runtime；`git check-ignore` 已验证 |
| `GDR-FLOW-01` | P1 | fixed | 主流程与执行视图混杂 | `workflow_step`、Matrix 横切 edge、CI/CD profile 已拆分 |
| `GDR-STATE-01` | P1 | fixed | 状态模型混淆 | `.config/goal/schema/rules.yaml` 定义四轴状态，文档/配置/工具已统一 |
| `GDR-ID-01` | P1 | fixed | ID 与版本语义混合 | 模板与文档改为统一命名，旧 `P-XXX` 等 stale literal 检查通过 |
| `GDR-SCHEMA-01` | P1 | fixed | Schema 投影未闭合 | drift checker 校验 registry、gate、pipeline、matrix、CI 与 stale literal |
| `GDR-MATRIX-01` | P1 | fixed | Matrix 策略与证据链不完整 | `.config/goal/matrix/matrix.yaml` 改为 edge 模型，27/27 edge 终态 |
| `GDR-EVID-01` | P1 | fixed | Evidence 证明深度不足 | `gate-check.sh` 与 `rule-drift-check.py` 均验证 Evidence closure |
| `GDR-TOOLS-01` | P1 | fixed | 工具只验证局部规则 | `lint-goal.sh`、`rule-drift-check.py`、`matrix-gen.py`、`gate-check.sh` 已更新并通过验收 |
| `GDR-INFO-01` | P2 | fixed | 信息架构和历史材料混杂 | README、quickstart、CHANGELOG、GLOSSARY、authority map 已补齐当前状态与迁移边界 |

## Phase 6：关闭与复评

| ID | Priority | Status | 问题 | 修复证据 |
| --- | --- | --- | --- | --- |
| `GDR-06-01` | P1 | fixed | 关闭 P1 ledger | 本文件已更新为 P1 全部 fixed |
| `GDR-06-02` | P1 | fixed | 执行复评分 | `goal-docs-fix-verification-20260609.md` 给出 `92/100` 复评分 |
| `GDR-06-03` | P2 | fixed | 记录延期项 | 本文件的 Deferred / Residual 区记录保留原因 |
| `GDR-06-04` | P2 | fixed | 记录验证证据 | 验证命令和输出摘要已写入验证报告 |

## Deferred / Residual

| ID | Priority | Status | 说明 |
| --- | --- | --- | --- |
| `GDR-FIXTURE-01` | P2 | deferred | 可继续沉淀独立负例 fixture 套件，当前真实配置与脚本自检已覆盖本轮目标 |
| `GDR-REPORT-01` | P3 | deferred | `docs/report/goal/` 是分析制品目录，尚未纳入 Goal runtime gate |
| `GDR-WORKTREE-01` | P3 | deferred | 当前 worktree 存在无关历史脏文件/未跟踪目录，本轮按用户请求未清理 |

## 本轮验证命令

```bash
git diff --check
bash -n docs/goal/tools/*.sh
python3 -m py_compile docs/goal/tools/matrix-gen.py docs/goal/tools/rule-drift-check.py
bash docs/goal/tools/lint-goal.sh docs/goal
python3 docs/goal/tools/rule-drift-check.py --root .
python3 docs/goal/tools/matrix-gen.py --check-only --matrix .config/goal/matrix/matrix.yaml
bash docs/goal/tools/gate-check.sh .
git check-ignore -v .config/goal/schema/rules.yaml
git check-ignore -v .config/goal/runtime/cache.json
rg -n "GOAL_DRAFTING|SPEC_REVIEWING|PROMPTING|CODING|TESTING|PAUSED|CANCELLED|P-XXX|docs/goals|docs/module" docs/goal .config/goal
```
