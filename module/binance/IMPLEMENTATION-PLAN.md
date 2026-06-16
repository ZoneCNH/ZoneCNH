# module/binance IMPLEMENTATION PLAN

## 1. Goal

Deliver `module/binance` v1.0.0 as a complete Binance-specific market-data C/S module.

## 2. Required Preflight Decisions

Before runtime implementation:

1. `binance-market` is removed.
2. `module/binance/client` and `module/binance/server` are documented.
3. `module/binance/server` is the Binance-specific `MarketDataService` implementation.
4. `module/domain-market` owns canonical market semantics.
5. `module/contracts` owns proto/gRPC wire contracts.
6. `module/market-data` owns downstream exchange-neutral processing.
7. Delivery semantics are at-least-once + idempotent acceptance.

### Phase 0: Upstream Contract Closure Gate (2026-06-17 验证通过)

在进入运行时实现前，必须先验证三条上游契约链闭合：

| Gate | 验证项 | 验证方式 | 状态 |
|------|--------|----------|:----:|
| G0-1 | `module/contracts` §8.4 已定义 `MarketDataService` + `IngestRequest`/`IngestResult`/`IngestAck`/`IngestReject`/`RejectCode` | `grep -c "IngestRequest\|IngestResult\|RejectCode" module/contracts/SPEC.md` ≥ 10 | ✅ |
| G0-2 | `module/domain-market` 已定义 `ProductLine`(4值)/`InstrumentKey`(12维)/`MarketFactEnvelope`(canonical wrapper) | `grep -c "ProductLine\|InstrumentKey\|MarketFactEnvelope" module/domain-market/SPEC.md` ≥ 15 | ✅ |
| G0-3 | `module/market-data` downstream dispatch port SPEC 已发布 + binance reject 映射规则已文档化 | `ls module/market-data/SPEC.md` + `grep -c "binance.*reject\|RejectCode" module/market-data/SPEC.md` ≥ 5 | ✅ |
| G0-4 | `module/binance` OQ-001（contracts wire 就绪？）已闭合 | SPEC §22 OQ-001 状态为已确认 | ✅ |
| G0-5 | `module/binance` OQ-002（market-data dispatch port 就绪？）已闭合 | SPEC §22 OQ-002 状态为已确认 | ✅ |
| G0-6 | BOUNDARY-GATES.md 提供 8 个 gate section 的 suggested checks/check keywords；尚未声称已接入 repo CI 脚本 | `grep -c "Suggested check:" module/binance/BOUNDARY-GATES.md` ≥ 7 | ⚠️ Suggested |

> **5/6 已闭合 + 1 项 suggested check inventory** — 上游 contracts/domain/market-data 契约链闭合，binance 可从 Draft 推进到运行时实现。G0-6 仅确认 `BOUNDARY-GATES.md` 存在 suggested checks；运行时 PR 仍需将这些片段落为实际 CI scripts/workflows。

## 3. Recommended PR Sequence

```text
PR-000 Remove binance-market
PR-001 module/binance root requirements
PR-002 root traceability and execution docs
PR-003 module/binance/client docs
PR-004 module/binance/server docs
PR-005 domain-market dependency
PR-006 contracts dependency
PR-007 transportx dependency
PR-008 runtime client implementation
PR-009 runtime server implementation
PR-010 runtime admin and boundary gates
```

## 4. PR-000 Remove binance-market

Scope:

- remove `binance-market` from active architecture/status
- remove old Provider references
- remove `docs/services/binance-market-client-svc.md`
- add migration note outside this module
- add no-legacy gate

Acceptance:

- no active doc says `binance-market` is current
- new Binance work points to `module/binance/client` and `module/binance/server`

## 5. PR-001 Root Module

Scope:

- add `module/binance/goal.md`
- add root `README.md`
- add root `SPEC.md`
- add root `TRACEABILITY.md`
- add root `BOUNDARY-GATES.md`
- add root `RUNTIME-MAPPING.md`
- add root `IMPLEMENTATION-PLAN.md`

Acceptance:

- root doc defines client/server split
- no storage/query/strategy ownership appears in root
- no legacy Provider path remains

## 6. PR-002 Root Traceability and Execution Docs

Scope:

- normalize root task specs to `TASK-BINANCE-000` through `TASK-BINANCE-010`
- keep root `TRACEABILITY.md`, `IMPLEMENTATION-PLAN.md`, and `BOUNDARY-GATES.md` aligned
- preserve FR/BR/AC/TC mapping against physical task files
- expose scorer-visible validation, dependencies, risks, and rollback

Acceptance:

- every root task reference points to an existing task file
- rule scoring for root spec/matrix/tasks/plan is 100
- no legacy root-prefixed task reference remains

## 7. PR-003 Client Docs

Scope:

- add client README/SPEC/TRACEABILITY/PLAN
- add 13 client tasks
- define product-line catalog
- define parser/mapping/spool/checkpoint/sender/admin

Acceptance:

- each client task has A/C
- client does not implement server behavior
- checkpoint depends on server ACK

## 8. PR-004 Server Docs

Scope:

- add server README/SPEC/TRACEABILITY/PLAN
- add 9 server tasks
- define ingest service implementation
- define validation/idempotency/ACK/dispatch/admin

Acceptance:

- server owns Binance-specific ingest acceptance
- server does not connect to Binance exchange endpoints
- server does not own physical storage/query/strategy

## 9. PR-005 domain-market Dependency

Required external concepts:

- `InstrumentKey`
- `ProductLine`
- `InstrumentType`
- `OptionType`
- `PriceKind`
- `MarketScope`
- `MarketFactEnvelope`
- `decision_time`

> **Docs baseline**: 以上全部类型已在 `module/domain-market/SPEC.md` v1.0.1 §10 中定义（ProductLine=4 值枚举, InstrumentKey=12 字段, MarketFactEnvelope=canonical wrapper with time semantics）。运行时实现时直接 import domain-market Go 类型，不需要在 binance 侧重新定义。

Acceptance from Binance perspective:

- Spot/Futures/Options identity collisions are impossible
- proto/domain mapping can be tested
- old event envelopes have a compatibility path if needed

## 10. PR-006 contracts Dependency

Required external protocol:

- `MarketDataService`
- `IngestRequest`
- `IngestAck`
- `IngestReject`
- canonical event envelope wire representation
- enum compatibility policy

> **Docs baseline**: 以上全部接口和 DTO 已在 `module/contracts/SPEC.md` v1.2.0 §8.4 中定义（MarketDataService Go 接口 + IngestRequest(12字段)/IngestResult/IngestAck/IngestReject + RejectCode(9码) + 跨层命名映射表）。运行时 proto 编译与 gRPC code generation 待后续阶段执行。

Acceptance from Binance perspective:

- client can generate gRPC sender
- server can implement gRPC receiver
- ACK/reject semantics are testable

## 11. PR-007 transportx Dependency

Required external policies:

- gRPC streaming policy
- retry/backoff defaults
- Gin admin conventions
- health/readiness conventions
- auth/TLS recommendations

## 12. PR-008~PR-010 Runtime Implementation

Recommended runtime layout:

```text
github.com/ZoneCNH/binance/
  cmd/
    binance-client/
    binance-server/
  internal/
    client/
    server/
  pkg/
    config/
    observability/
```

Implementation order:

1. generated contracts integration
2. domain type mapping
3. server mock and contract tests
4. client catalog/parser
5. connectors
6. mapper
7. spool/checkpoint
8. gRPC sender
9. real server ingest
10. validation/idempotency/ACK
11. downstream dispatch
12. admin/observability
13. integration tests
14. boundary gates in CI

## 13. Dependencies / DAG

Task references are the execution handles for the PR sequence:

| PR | Task ref | Depends on | Dependency rationale |
|----|----------|------------|----------------------|
| PR-000 | TASK-BINANCE-000 | — | Remove legacy `binance-market` references before new module ownership is asserted. |
| PR-001 | TASK-BINANCE-001 | TASK-BINANCE-000 | Establish root requirements and boundary vocabulary for all child docs. |
| PR-002 | TASK-BINANCE-002 | TASK-BINANCE-001 | Establish root traceability, implementation plan, and execution metadata. |
| PR-003 | TASK-BINANCE-003 | TASK-BINANCE-002, TASK-BINANCE-005, TASK-BINANCE-006 | Client docs require root traceability, domain-market identity, and contracts ingest semantics. |
| PR-004 | TASK-BINANCE-004 | TASK-BINANCE-002, TASK-BINANCE-005, TASK-BINANCE-006 | Server docs require root traceability, domain-market identity, contracts ingest, and downstream dispatch. |
| PR-005 | TASK-BINANCE-005 | TASK-BINANCE-001 | Domain-market dependency can be validated once root identity expectations are fixed. |
| PR-006 | TASK-BINANCE-006 | TASK-BINANCE-001 | Contracts dependency can be validated once root wire expectations are fixed. |
| PR-007 | TASK-BINANCE-007 | TASK-BINANCE-003, TASK-BINANCE-004 | Transport/admin policy depends on client/server surface definitions. |
| PR-008 | TASK-BINANCE-008 | TASK-BINANCE-003, TASK-BINANCE-005, TASK-BINANCE-006, TASK-BINANCE-007 | Client runtime implementation starts after client docs, domain semantics, contracts, and transport policy are stable. |
| PR-009 | TASK-BINANCE-009 | TASK-BINANCE-004, TASK-BINANCE-005, TASK-BINANCE-006, TASK-BINANCE-007 | Server runtime implementation starts after server docs, domain semantics, contracts, and transport policy are stable. |
| PR-010 | TASK-BINANCE-010 | TASK-BINANCE-008, TASK-BINANCE-009 | Runtime admin and boundary gates close only after both client and server slices exist. |

DAG summary: `TASK-BINANCE-000 -> TASK-BINANCE-001 -> {TASK-BINANCE-002,TASK-BINANCE-005,TASK-BINANCE-006} -> {TASK-BINANCE-003,TASK-BINANCE-004} -> TASK-BINANCE-007 -> {TASK-BINANCE-008,TASK-BINANCE-009} -> TASK-BINANCE-010`, with PR-003/PR-004 and PR-008/PR-009 allowed to proceed in parallel after their shared dependencies close.

## 14. Validation Commands

Root-doc scoring and whitespace checks for this plan lane:

```bash
python3 scripts/rule-scorer.py spec binance --out /tmp/binance-spec-score.json
python3 scripts/rule-scorer.py matrix binance --out /tmp/binance-matrix-score.json
python3 scripts/rule-scorer.py plan binance --out /tmp/binance-plan-score.json
git diff --check
```

Runtime implementation PRs should additionally wire the suggested boundary checks into executable CI, for example:

```bash
bash .github/ci/binance-boundary-gates.sh
go test ./module/binance/...
```

The second block is a target validation contract, not a claim that those scripts/packages exist in this docs baseline.

## 15. Risks

- Boundary checks stay as documentation snippets unless PR-007 or a CI-hardening PR promotes them into scripts/workflows.
- Client/server docs can drift if BR IDs are renumbered without updating TRACEABILITY and tests together.
- Domain-market or contracts version changes can invalidate mapper assumptions and generated-code expectations.
- Admin/auth and secret-redaction requirements are easy to under-test if only happy-path health endpoints are implemented.

## 16. Rollback

- Docs-only rollback: revert the specific PR/task commit and rerun the three `rule-scorer.py` stages plus `git diff --check`.
- Runtime rollback: disable new Binance client/server deployment, preserve spool/checkpoint files for replay, and route downstream ingestion back to the last known-good feed path.
- CI rollback: if promoted boundary scripts block unrelated work incorrectly, revert the workflow wiring while keeping `BOUNDARY-GATES.md` as suggested checks until false positives are fixed.
- Contract rollback: if contracts/domain-market updates break Binance integration, pin to the last compatible contracts/domain-market version and open a follow-up compatibility task before retrying PR-007.

## 17. Done Definition

v1.0.0 is done when:

- docs compile as a coherent module
- all tasks have acceptance criteria
- client/server boundaries are enforced
- server ACK can drive client checkpoint
- duplicate idempotency keys are accepted once
- no `binance-market` active reference exists
- integration test demonstrates client → server → downstream port flow
