# OrderBook Goal 控制面登记草案

> 日期：2026-07-09
> 状态：Draft / 不得直接落库
> 候选 Goal ID：`GOAL-20260709-001`
> 目标控制面：`.config/goal/registry/goals.yaml`、`.config/goal/pipeline/state.yaml`、`.config/goal/gates/state.yaml`、`.config/goal/registry/risks.yaml`、`.config/goal/registry/decisions.yaml`
> 约束：本文只是登记草案，本轮不修改 `.config/goal/`

---

## 0. 使用前提

本文提供的是后续控制面写入的审查输入，不是已经生效的 registry 状态。[FRAME, HIGH]

在维护者明确授权写入 `.config/goal/` 之前，不得把本文片段复制到控制面文件中。[FRAME, HIGH]

在 owner 未替换为真实负责人之前，G1 Goal Gate 必须保持 BLOCKED。[COMPUTED, HIGH]

本文不会解除 `module/orderbook/` 和 runtime repo 的双闸门限制。[COMPUTED, HIGH]

---

## 1. `.config/goal/registry/goals.yaml` 草案

```yaml
  - goal_id: GOAL-20260709-001
    document_version: "2026-07-09"
    title: "OrderBook 独立化治理启动"
    status: Draft
    owner: TBD-HUMAN-OWNER
    priority: P0
    north_star: "将 knowledge/OrderBook.md 收敛为可审查、可追溯、受双闸门约束的 OrderBook 独立化治理包，在未授权前保持零模块创建、零 runtime repo 创建、零 registry 误写。"
    pipeline_state: CONTEXT_READY
    current_phase: GOAL
    phase_status: BLOCKED
    workflow_step: GOAL_REVIEW
    created_at: "2026-07-09"
    updated_at: "2026-07-09"
    related_issues: []
    related_specs:
      - report/OrderBook/ORDERBOOK-GOAL-DRAFT-20260709.md
      - report/OrderBook/ORDERBOOK-SPEC-DRAFT-20260709.md
      - report/OrderBook/ORDERBOOK-CONTRACT-GATE-DRAFT-20260709.md
      - report/OrderBook/ORDERBOOK-TRACEABILITY-SEED-20260709.md
    success_criteria:
      - G0 输入包含来源文档、branch、commit、工作树范围和阻断项，覆盖率 100%
      - Goal 草案包含 Context、Objective、Scope、Success Metrics、AC、Constraints、Non-goals、Priority、Deadline、Downstream Mapping
      - 未授权前 module/orderbook、runtime repo、module/registry.yaml、.config/goal 写入次数为 0
      - FR-OB-001..012 均可映射到 AC、Gate 和候选 Task seed
      - OB-010..014 均有目标、产物、验证命令和阻断关系
      - ADR 草案覆盖必要性、唯一性、净收益、替代方案、风险和后置条件
    blockers:
      - owner 未指定
      - .config/goal 写入未授权
      - module/orderbook 双闸门未完成
      - github.com/ZoneCNH/orderbook runtime repo 双闸门未完成
      - binance Phase 1 前置硬化证据未完成
```

审查结论：该条目只能在 `owner` 替换为真实负责人，并且用户明确授权写入 `.config/goal/registry/goals.yaml` 后落库。[FRAME, HIGH]

---

## 2. `.config/goal/pipeline/state.yaml` 草案

```yaml
  - goal_id: GOAL-20260709-001
    pipeline_state: CONTEXT_READY
    previous_pipeline_state: INIT
    current_phase: GOAL
    phase_status: BLOCKED
    workflow_step: GOAL_REVIEW
    state_model: four_axis
    state_axes:
      pipeline_state: docs/goal/03-pipeline.md#20-状态轴边界
      current_phase: docs/goal/03-pipeline.md#20-状态轴边界
      phase_status: docs/goal/03-pipeline.md#20-状态轴边界
      workflow_step: docs/goal/03-pipeline.md#20-状态轴边界
    artifacts_ready:
      - context
      - goal_draft
      - adr_draft
      - spec_draft
      - traceability_seed
      - contract_gate_draft
      - binance_phase1_plan
    state_history:
      - event: INIT
        pipeline_state: INIT
        current_phase: GOAL
        phase_status: NOT_STARTED
        workflow_step: CONTEXT_PREPARATION
        entered_at: "2026-07-09"
        exited_at: "2026-07-09"
      - event: CONTEXT_READY
        pipeline_state: CONTEXT_READY
        current_phase: GOAL
        phase_status: BLOCKED
        workflow_step: GOAL_REVIEW
        entered_at: "2026-07-09"
        blocked_by:
          - owner 未指定
          - 控制面写入未授权
          - module/repo 双闸门未完成
    next_required_gate: G1
    evidence_required:
      - EVID-G1-OWNER-ORDERBOOK
      - EVID-G1-GOAL-REVIEW-ORDERBOOK
      - EVID-GOV-AUTH-ORDERBOOK
      - EVID-BINANCE-PHASE1-ORDERBOOK
```

审查结论：该状态不能写成 `GOAL_READY`，因为 G1 未通过。[COMPUTED, HIGH]

---

## 3. `.config/goal/gates/state.yaml` 草案

```yaml
- gate_id: G0
  gate_name: Context Gate
  type: Hybrid
  blocking: true
  status: PASS_WITH_RISK
  checked_at: "2026-07-09"
  checked_by: codex
  goal_id: GOAL-20260709-001
  threshold:
    pass: 90
    pass_with_risk_min: 80
    pass_with_risk_max: 89
  allow_pass_with_risk: true
  risk:
    risk_id: RISK-GOAL-20260709-001-001
    risk_owner: TBD-HUMAN-OWNER
    risk_level: medium
    risk_reason: "当前只完成 report-only 上下文包，尚未进入正式控制面；工作树存在与本任务无关的既有改动。"
    mitigation: "只把 report/OrderBook 作为输入包维护；控制面写入需后续显式授权。"
    due_at: "2026-07-12"
    review_gate: G1
    release_blocking: false
    evidence_id: EVID-G0-CONTEXT-ORDERBOOK-20260709
  result:
    verdict: PASS_WITH_RISK
    score: 88
    threshold: 90
    details:
      - check: 上下文恢复完整
        status: PASS
        evidence: report/OrderBook/ORDERBOOK-GOAL-G0-G1-GATE-PACKET-20260709.md
      - check: 分支和 commit 已记录
        status: PASS
        evidence: docs/binance_production_readiness_report / d4f11600
      - check: 控制面未写入
        status: PASS_WITH_RISK
        evidence: 本轮保持 report-only，需后续授权

- gate_id: G1
  gate_name: Goal Gate
  type: Semantic
  blocking: true
  status: BLOCKED
  checked_at: "2026-07-09"
  checked_by: codex
  goal_id: GOAL-20260709-001
  threshold:
    pass: 90
    pass_with_risk_min: 85
    pass_with_risk_max: 89
  allow_pass_with_risk: true
  result:
    verdict: BLOCKED
    score: 85
    threshold: 90
    details:
      - check: SMART 原则
        status: PASS
        evidence: report/OrderBook/ORDERBOOK-GOAL-DRAFT-20260709.md
      - check: 成功指标和验收标准
        status: PASS
        evidence: SM-OB-GOAL-001..006 / AC-GOAL-001..008
      - check: Owner
        status: BLOCKED
        evidence: 维护者尚未指定 owner
      - check: Registry 注册
        status: BLOCKED
        evidence: 本轮未授权写入 .config/goal/registry/goals.yaml
```

审查结论：G1 应保持 BLOCKED，不能因为草案字段齐全而标记 PASS。[COMPUTED, HIGH]

---

## 4. `.config/goal/registry/risks.yaml` 草案

```yaml
  - risk_id: RISK-GOAL-20260709-001-001
    document_version: "2026-07-09"
    goal_id: GOAL-20260709-001
    title: OrderBook Goal 控制面写入前 owner 缺失
    severity: High
    probability: High
    impact: High
    status: Open
    release_blocking: true
    owner: TBD-HUMAN-OWNER
    created_at: "2026-07-09"
    updated_at: "2026-07-09"
    due_at: "2026-07-12"
    review_gate: G1
    evidence_id: EVID-G1-OWNER-ORDERBOOK
    risk_owner: TBD-HUMAN-OWNER
    risk_level: high
    risk_reason: "G1 Goal Gate 要求 owner；当前 owner 尚未由维护者指定。"
    mitigation:
      - 维护者明确 Goal owner
      - owner 写入正式 Goal registry 或模块 Goal 文档
    contingency:
      - owner 未指定前保持 G1 BLOCKED
    related_gates:
      - G1
    related_tasks: []

  - risk_id: RISK-GOAL-20260709-001-002
    document_version: "2026-07-09"
    goal_id: GOAL-20260709-001
    title: 未授权创建 orderbook 模块或 runtime repo
    severity: High
    probability: Medium
    impact: High
    status: Open
    release_blocking: true
    owner: TBD-HUMAN-OWNER
    created_at: "2026-07-09"
    updated_at: "2026-07-09"
    due_at: "2026-08-31"
    review_gate: G3
    evidence_id: EVID-GOV-AUTH-ORDERBOOK
    risk_owner: TBD-HUMAN-OWNER
    risk_level: high
    risk_reason: "新建 module/orderbook 和 github.com/ZoneCNH/orderbook 需要治理层审批与人工会话显式授权。"
    mitigation:
      - 在 report/OrderBook 维护准入材料
      - 正式 ADR Accepted 前不创建 module/orderbook
      - binance Phase 1 证据完成前不创建 runtime repo
    contingency:
      - 若发现越权创建，立即停止并提交治理审查
    related_gates:
      - G1
      - G3
      - G10
    related_tasks: []

  - risk_id: RISK-GOAL-20260709-001-003
    document_version: "2026-07-09"
    goal_id: GOAL-20260709-001
    title: binance Phase 1 前置硬化未完成导致迁移风险
    severity: High
    probability: Medium
    impact: High
    status: Open
    release_blocking: true
    owner: TBD-HUMAN-OWNER
    created_at: "2026-07-09"
    updated_at: "2026-07-09"
    due_at: "2026-07-31"
    review_gate: G4
    evidence_id: EVID-BINANCE-PHASE1-ORDERBOOK
    risk_owner: TBD-HUMAN-OWNER
    risk_level: high
    risk_reason: "combined stream 分片、DepthLevel 语义、options depth 口径和 replay input 证据尚未闭环。"
    mitigation:
      - 优先执行 OB-010..014
      - 完成前只准备 contract/gate 草案，不迁移 runtime
    contingency:
      - 若 Phase 1 延期，则 runtime repo 创建决策同步延期
    related_gates:
      - G4
      - G5
      - G8
    related_tasks:
      - OB-010
      - OB-011
      - OB-012
      - OB-013
      - OB-014
```

---

## 5. `.config/goal/registry/decisions.yaml` 草案

```yaml
  - decision_id: DEC-GOAL-20260709-001-001
    document_version: "2026-07-09"
    goal_id: GOAL-20260709-001
    title: OrderBook Goal 先以 report-only 方式启动
    status: Proposed
    maker: TBD-HUMAN-OWNER
    created_at: "2026-07-09"
    updated_at: "2026-07-09"
    context: |
      knowledge/OrderBook.md 提出了独立 OrderBook runtime/platform 的方向，但 orderbook 尚未在 module/registry.yaml 中注册，新模块和新仓库创建受双闸门约束。
    decision: |
      先在 report/OrderBook 下形成 Goal、G0/G1 Gate、ADR、Spec、Contract/Gate、Traceability 和 binance Phase 1 hardening 草案；不直接写 module/orderbook、runtime repo、module/registry.yaml 或 .config/goal。
    alternatives:
      - name: 直接创建 module/orderbook
        reason: "被双闸门阻断。"
      - name: 直接创建 runtime repo
        reason: "被双闸门阻断，且 binance Phase 1 证据未完成。"
      - name: 继续只在 binance 内硬化
        reason: "短期可行，但不足以回答跨 venue contract/gate 是否需要独立 SSOT。"
    consequences:
      - Goal 能被审查但 G1 仍因 owner 和控制面授权缺失保持 BLOCKED
      - 后续若授权控制面写入，可按本文片段进入正式 registry
      - 任何 module/repo 创建仍需单独双闸门授权
    related_tasks:
      - OB-010
      - OB-011
      - OB-012
      - OB-013
      - OB-014
```

---

## 6. 落库前检查清单

| 检查 | 必须满足 |
| --- | --- |
| Owner | `TBD-HUMAN-OWNER` 已替换为真实 owner。[FRAME, HIGH] |
| 授权 | 用户明确授权修改 `.config/goal/`。[FRAME, HIGH] |
| ID 冲突 | `GOAL-20260709-001`、risk ID、decision ID 未与现有控制面冲突。[FRAME, HIGH] |
| G1 结论 | owner 未补齐前不得把 G1 改成 PASS。[COMPUTED, HIGH] |
| 模块创建 | 不得把控制面登记误解为 `module/orderbook/` 创建授权。[COMPUTED, HIGH] |
| 验证命令 | 落库后必须运行 `bash docs/goal/tools/goal-workflow.sh validate`。[COMPUTED, HIGH] |

---

[RULES I BROKE]：无
