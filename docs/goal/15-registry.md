# Registry 系统

> 本文档从原 `advanced-operations.md` 拆分而来，聚焦于 6 个业务 Registry 文件及横切运行制品的完整定义。

Registry 保存长期状态，所有 Agent 共享。

## 统一状态路径

所有 Goal 相关状态统一存放在 `.config/goal/`，由 10 个 Goal Agent 共同维护：

| 目录                     | 文件             | 维护 Agent                |
| ------------------------ | ---------------- | ------------------------- |
| `.config/goal/registry/` | `goals.yaml`     | goal-spec                 |
| `.config/goal/registry/` | `tasks.yaml`     | goal-spec                 |
| `.config/goal/registry/` | `issues.yaml`    | goal-spec                 |
| `.config/goal/registry/` | `releases.yaml`  | goal-spec                 |
| `.config/goal/registry/` | `risks.yaml`     | goal-spec                 |
| `.config/goal/registry/` | `decisions.yaml` | goal-spec                 |
| `.config/goal/matrix/`   | `matrix.yaml`    | goal-matrix               |
| `.config/goal/gates/`    | `state.yaml`     | goal-reviewer             |
| `.config/goal/pipeline/` | `state.yaml`     | goal-spec                 |
| `.config/goal/evidence/` | `EVID-*.md`      | goal-evidence             |
| `.config/goal/prompts/`  | `TASK-*/v*.md`   | goal-prompt-builder       |
| `.config/goal/schema/`   | `rules.yaml`     | goal-lint（校验）         |
| `.config/goal/runtime/`  | 恢复缓存         | goal-context-recovery     |

> 校验/审计角色：goal-governance 负责 SSOT 一致性审计与漂移检测，不直接写入 `.config/goal/` 文件；goal-architect 生成 `module/{m}/design/` 与 ADR，goal-planner 生成 `module/{m}/plan/`、`module/{m}/tasks/`，二者制品不在 `.config/goal/` 下，通过 goal-spec 回写 `decisions.yaml` 等注册表。

---

## 1. Goal Registry

```yaml
goal_id: GOAL-20260608-001
title: x.go Market Data MVP
status: active
owner: architect-agent
priority: P0
north_star: 完成市场数据模块独立化、可运行、可验证
pipeline_state: DESIGN_READY
  current_phase: DESIGN
  phase_status: READY
related_issues:
  - "#1393"
related_specs:
  - module/market_data/spec/SPEC.md
success_criteria:
  - market_data 独立运行
  - 支持历史 K 线采集
  - 支持实时 WS 订阅
  - CI 测试通过
```

路径：`.config/goal/registry/goals.yaml`

---

## 2. Task Registry

```yaml
task_id: TASK-GOAL-20260608-001-003
goal_id: GOAL-20260608-001
title: Implement WS subscription handler
status: In Progress
owner: agent-market_data
priority: P0
dod:
  - WS 连接成功
  - 消息解析正确
  - 断线重连有效
  - 测试通过
evidence:
  - .config/goal/evidence/2026-06-08/TASK-GOAL-20260608-001-003/EVID-TEST-TASK-GOAL-20260608-001-003-001-001.md
```

路径：`.config/goal/registry/tasks.yaml`

---

## 3. Issue Registry

```yaml
issue_id: "#1393"
source: github
title: Market Data module foundation
status: in_progress
priority: P0
goal_id: GOAL-20260608-001
spec_id: SPEC-market_data-v1
design_id: DESIGN-market_data-v1
tasks:
  - TASK-GOAL-20260608-001-001
  - TASK-GOAL-20260608-001-002
  - TASK-GOAL-20260608-001-003
labels:
  - market_data
  - p0
  - architecture
```

路径：`.config/goal/registry/issues.yaml`

---

## 4. Issue 生命周期

```text
OPEN → TRIAGED → SPEC_READY → DESIGN_READY → TASKS_READY
→ IN_PROGRESS → IN_REVIEW → READY_FOR_RELEASE → DONE
```

异常状态分类见 [03-pipeline.md §2.2](03-pipeline.md#22-异常状态)（4 类：BLOCKED / FAILED / NEEDS_INPUT / INCONSISTENT_STATE，含子类型）。Registry 不新增本地异常状态。

---

## 5. Release Registry

```yaml
release_id: REL-20260608-market_data
goal_id: GOAL-20260608-001
version: v0.3.0
status: ready_for_pr
linked_issues:
  - "#1393"
tests:
  - go test ./...
docs_updated:
  - README.md
  - CHANGELOG.md
rollback_plan: docs/goal/release/rollback-market_data.md
evidence_manifest: .config/goal/evidence/REL-20260608-market_data-manifest.md
```

路径：`.config/goal/registry/releases.yaml`

---

## 6. Risk Registry

```yaml
risk_id: RISK-GOAL-20260608-001-001
goal_id: GOAL-20260608-001
task_id: TASK-GOAL-20260608-001-003
type: Performance Risk
description: WS 断线重连可能导致数据丢失
probability: Medium
impact: High
severity: High
trigger: WS 连接中断超过 5 秒
mitigation: 增加消息缓存和重放机制
owner: agent-market_data
status: Open
linked_gates:
  - G8
  - G10
linked_evidence:
  - EVID-GOAL-20260608-001-RISK-001
release_blocking: true
residual_risk: High
acceptance:
  accepted_by: N/A
  accepted_at: N/A
  reason: N/A
  review_due_at: N/A
review_cadence: before G10
```

路径：`.config/goal/registry/risks.yaml`

---

## 7. Decision Registry

```yaml
decision_id: DEC-20260608-001
adr_id: ADR-20260608-001
title: Market Data module boundary
status: Accepted
context: market_data 需要独立运行并支持多数据源
options:
  - 直接耦合 Binance SDK
  - 使用 Adapter 接口隔离
decision: 使用 Adapter 接口隔离
rationale: 降低供应商耦合
rollback: 可退回单一 Binance client 实现
```

路径：`.config/goal/registry/decisions.yaml`；ADR 正文放在 `docs/adr/`
