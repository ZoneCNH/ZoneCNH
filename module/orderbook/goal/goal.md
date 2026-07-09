# Goal: OrderBook 事实链模块 v0.1.0

> Goal ID: GOAL-20260709-001
> Status: Achieved
> Owner: ZoneCNH
> Priority: P0
> Deadline: 2026-07-09

---

## 1. Context

`knowledge/OrderBook.md` 要求将 OrderBook 从单一 Binance runtime 抽象为可复用的跨 venue 事实链能力。[COMPUTED, HIGH]

`report/OrderBook/` 已完成准入分析、Contract/Gate 草案、SPEC 草案和 Traceability seed。[COMPUTED, HIGH]

用户在本会话授权执行全部待完成任务，目标是实现完整 OrderBook 模块。[COMPUTED, HIGH]

## 2. Objective

交付 `orderbook` v0.1.0 active 模块：包含正式治理制品、registry 登记、GitHub runtime 仓库、Release、Replay/Gap/Boundary gate、测试证据和迁移边界。[FRAME, HIGH]

## 3. Scope

### In Scope

- `module/orderbook/` Goal、Spec、Design、Plan、Tasks、Prompt、Matrix、Gate、Evidence 制品。[FRAME, HIGH]
- `/home/workspace/orderbook` Go library runtime scaffold。[FRAME, HIGH]
- `https://github.com/ZoneCNH/orderbook` GitHub runtime repository 与 `v0.1.0` release。[COMPUTED, HIGH]
- Adapter contract、BookBuilder、BookHash、ReplayRunner、Quality timeline、Conformance fixture。[FRAME, HIGH]
- Boundary、Replay determinism、Gap injection gate 脚本。[FRAME, HIGH]

### Out of Scope

- Binance connector lifecycle 重写和真实 adapter 迁移。[FRAME, HIGH]
- OKX/Bybit adapter 真实接入。[FRAME, HIGH]
- 因子研究、market regime、execution strategy。[INFERRED, HIGH]

## 4. Success Metrics

| 指标 | 目标 |
| --- | --- |
| SM-OB-001 | `module/orderbook/` 制品完整，registry lifecycle 为 `active`。[COMPUTED, HIGH] |
| SM-OB-002 | `/home/workspace/orderbook` 执行 `go test ./...` 通过。[FRAME, HIGH] |
| SM-OB-003 | replay determinism gate 同一 fixture 100 次 hash 一致。[FRAME, HIGH] |
| SM-OB-004 | gap injection gate 对 missing/out-of-order/prev-break 输出 unreliable quality。[FRAME, HIGH] |
| SM-OB-005 | boundary gate 不发现 venue internal import。[FRAME, HIGH] |
| SM-OB-006 | GitHub Release `v0.1.0` 和远端 CI 通过证据存在。[COMPUTED, HIGH] |

## 5. Acceptance Criteria

| AC | 验收 |
| --- | --- |
| AC-OB-GOAL-001 | `module/orderbook/spec/SPEC.md` Status 为 Approved，Spec-Version 为 v0.1.0。[FRAME, HIGH] |
| AC-OB-GOAL-002 | `module/registry.yaml` 存在 `orderbook` 条目，lifecycle 为 active。[COMPUTED, HIGH] |
| AC-OB-GOAL-003 | runtime 包实现 adapter/book/event/replay/quality/conformance 核心能力。[FRAME, HIGH] |
| AC-OB-GOAL-004 | `go test ./...`、boundary gate、replay gate、gap gate 均有证据记录。[FRAME, HIGH] |
| AC-OB-GOAL-005 | GitHub Release `v0.1.0` 与远端 CI run URL 已记录到 release manifest。[COMPUTED, HIGH] |

## 6. Constraints

- 不 import `github.com/ZoneCNH/binance/internal` 或任何 venue internal 包。[FRAME, HIGH]
- 不在首版 public API 中使用 float price/qty。[FRAME, HIGH]
- 不声称 Binance runtime 已迁移到 `orderbook`。[COMPUTED, HIGH]

## 7. Non-goals

- 不替代 `domain_market` 的 canonical OrderBook model。[COMPUTED, HIGH]
- 不替代 `binance` 的私有 adapter 实现。[COMPUTED, HIGH]
- 不实现策略和执行决策。[INFERRED, HIGH]

## 8. Downstream Mapping

- Spec: `module/orderbook/spec/SPEC.md`
- Matrix: `module/orderbook/matrix/TRACEABILITY.md`
- Plan: `module/orderbook/plan/PLAN.md`
- Runtime: `/home/workspace/orderbook`

[RULES I BROKE]：无
