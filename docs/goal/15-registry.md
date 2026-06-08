# 15. Registry 系统

> 本文档从原 `advanced-operations.md` 拆分而来，聚焦于 Registry 7 个子系统的完整定义。

Registry 保存长期状态，所有 Agent 共享。

---

## 1. Goal Registry

```yaml
goal_id: G-2026-001
title: x.go Market Data MVP
status: active
owner: architect-agent
priority: P0
north_star: 完成市场数据模块独立化、可运行、可验证
current_phase: design_ready
related_issues:
  - "#1393"
related_specs:
  - .agent/specs/market_data_spec.md
success_criteria:
  - market_data 独立运行
  - 支持历史 K 线采集
  - 支持实时 WS 订阅
  - CI 测试通过
```

路径：`.agent/registry/goals.yaml`

---

## 2. Task Registry

```yaml
task_id: T-2026-001-003
goal_id: G-2026-001
title: Implement WS subscription handler
status: executing
owner: agent-market-data
priority: P0
dod:
  - WS 连接成功
  - 消息解析正确
  - 断线重连有效
  - 测试通过
evidence:
  - .agent/evidence/2026-05-31/TASK-GOAL-20260601-001-003/evidence.md
```

路径：`.agent/registry/tasks.yaml`

---

## 3. Issue Registry

```yaml
issue_id: "#1393"
source: github
title: Market Data module foundation
status: in_progress
priority: P0
goal_id: G-2026-001
spec_id: SPEC-market-data-v1
design_id: DESIGN-market-data-v1
tasks:
  - T001
  - T002
  - T003
labels:
  - market-data
  - p0
  - architecture
```

路径：`.agent/registry/issues.yaml`

---

## 4. Issue 生命周期

```text
OPEN → TRIAGED → SPEC_READY → DESIGN_READY → TASKS_READY
→ IN_PROGRESS → IN_REVIEW → READY_FOR_RELEASE → DONE
```

异常状态：`BLOCKED`、`NEEDS_RESEARCH`、`NEEDS_DECISION`、`NEEDS_REPLAN`、`NEEDS_SPLIT`

---

## 5. Release Registry

```yaml
release_id: REL-2026-05-31-market-data
goal_id: G-2026-001
version: v0.3.0
status: ready_for_pr
linked_issues:
  - "#1393"
tests:
  - go test ./...
docs_updated:
  - README.md
  - CHANGELOG.md
rollback_plan: .agent/release/rollback_market_data.md
evidence_manifest: .agent/evidence/2026-05-31/release_manifest.md
```

路径：`.agent/registry/releases.yaml`

---

## 6. Risk Registry

```yaml
risk_id: RISK-GOAL-20260601-001-001
goal_id: GOAL-20260601-001
task_id: TASK-GOAL-20260601-001-003
type: Performance Risk
description: WS 断线重连可能导致数据丢失
probability: Medium
impact: High
severity: High
trigger: WS 连接中断超过 5 秒
mitigation: 增加消息缓存和重放机制
owner: agent-market-data
status: open
```

路径：`.agent/registry/risks.yaml`

---

## 7. Decision Registry

```yaml
decision_id: ADR-0001
title: Market Data module boundary
status: accepted
context: market_data 需要独立运行并支持多数据源
options:
  - 直接耦合 Binance SDK
  - 使用 Adapter 接口隔离
decision: 使用 Adapter 接口隔离
rationale: 降低供应商耦合
rollback: 可退回单一 Binance client 实现
```

路径：`.agent/registry/decisions.yaml` 和 `docs/adr/`
