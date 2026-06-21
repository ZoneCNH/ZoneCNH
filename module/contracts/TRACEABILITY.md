# contracts 追溯矩阵

- Status: Docs Baseline Synced / Coverage Closed
- Last-Updated: 2026-06-21
- Layer: 基座 · 跨域接口契约
- Source-of-Truth: `/home/contracts/pkg/contracts`
- Related: `SPEC.md`, `README.md`, `goal.md`, `ACCEPTANCE.md`, `FEATURES.md`, `IMPLEMENTATION-PLAN.md`, `tasks/`

> 本文档把当前 runtime truth 的公开符号映射到 SPEC 的 FR/BR/NFR、验证任务与文档制品；不再保留旧分层、旧版本标记或改名叙事。

## 1. 功能需求追溯

| ID | 规格摘要 | runtime 锚点 | 文档锚点 | 任务锚点 |
| --- | --- | --- | --- | --- |
| FR-001 | `Event`、`Command`、`Query` 基础封装 | `contracts.go` | `SPEC.md`、`README.md`、`FEATURES.md` | `TASK-CONTRACTS-002` |
| FR-002 | `DTO`、`Port`、`ErrorCode` 标记与错误元数据 | `contracts.go` | `SPEC.md`、`README.md`、`FEATURES.md` | `TASK-CONTRACTS-002` |
| FR-003 | `RegimeSnapshot`、`RegimeCard`、`DecisionCard` | `regime_snapshot.go`、`regime_card.go`、`decision_card.go` | `SPEC.md`、`README.md`、`FEATURES.md` | `TASK-CONTRACTS-002` |
| FR-004 | `SignalIntent` 与 `SignalFactoryProvider.Generate(...)` | `signal_intent.go`、`ports.go` | `SPEC.md`、`README.md`、`FEATURES.md` | `TASK-CONTRACTS-001` |
| FR-005 | `MarketDataProvider`、`MacroDataProvider`、`DecisionCardProvider` | `ports.go` | `SPEC.md`、`README.md`、`FEATURES.md` | `TASK-CONTRACTS-001` |
| FR-006 | `MarketDataService.Ingest(...)`、`IngestRequest`、`IngestResult`、`IngestAck`、`IngestReject`、`RejectCode`、`AllRejectCodes()` | `ingestion.go` | `SPEC.md`、`README.md`、`FEATURES.md` | `TASK-CONTRACTS-005` |
| FR-007 | `RegimeSnapshotEvent`、`RegimeCardEvent`、`DecisionCardEvent`、`MarketRegimePort`、`MacroRegimePort`、`RegimeEnginePort` | `projections.go` | `SPEC.md`、`README.md`、`FEATURES.md` | `TASK-CONTRACTS-003` |
| FR-008 | 文档基线与 runtime truth 同步 | `/home/contracts/pkg/contracts`、`module/contracts/*` | `SPEC.md`、`README.md`、`goal.md`、`TRACEABILITY.md`、`ACCEPTANCE.md`、`FEATURES.md`、`IMPLEMENTATION-PLAN.md`、`tasks/` | `TASK-CONTRACTS-004` |

## 2. 约束追溯

| ID | 规格摘要 | runtime / 检查锚点 | 文档锚点 | 任务锚点 |
| --- | --- | --- | --- | --- |
| BR-001 | 仅定义共享契约，不实现业务或传输逻辑 | 包边界与导出面 | `SPEC.md`、`README.md` | `TASK-CONTRACTS-000` |
| BR-002 | 不再使用旧分层命名 | `README.md`、`SPEC.md` | `SPEC.md`、`goal.md`、`FEATURES.md` | `TASK-CONTRACTS-004` |
| BR-003 | 不再使用旧版查询与订阅命名、旧版本标记 | `README.md`、`goal.md`、`tasks/` | `SPEC.md`、`README.md`、`goal.md` | `TASK-CONTRACTS-004` |
| BR-004 | 依赖边界受 `module/FOUNDATION-DEPS.yaml` 约束 | 共享层依赖图 | `SPEC.md`、`goal.md` | `TASK-CONTRACTS-000` |
| BR-005 | DTO 需要明确导出字段与 JSON tag 约定 | `contracts.go`、`regime_*`、`decision_card.go`、`ingestion.go` | `SPEC.md`、`README.md` | `TASK-CONTRACTS-002` |
| BR-006 | `AllRejectCodes()` 只返回 9 个 canonical code | `ingestion.go` | `SPEC.md`、`README.md`、`FEATURES.md` | `TASK-CONTRACTS-005` |
| BR-007 | `RejectUnsupportedChannel` 导出但不进入 canonical 列表 | `ingestion.go` | `SPEC.md`、`README.md`、`FEATURES.md` | `TASK-CONTRACTS-005` |
| BR-008 | 兼容别名只承担迁移，不承载新语义 | `projections.go` | `SPEC.md`、`README.md`、`FEATURES.md` | `TASK-CONTRACTS-003` |
| BR-009 | 文档必须保持同一组事实源 | `module/contracts/*` | `SPEC.md`、`README.md`、`TRACEABILITY.md`、`ACCEPTANCE.md`、`FEATURES.md`、`IMPLEMENTATION-PLAN.md`、`tasks/` | `TASK-CONTRACTS-004` |
| BR-010 | 公开 rename/removal 先修兼容层与追溯文档 | `projections.go`、`module/contracts/*` | `SPEC.md`、`goal.md`、`TRACEABILITY.md`、`ACCEPTANCE.md`、`FEATURES.md`、`IMPLEMENTATION-PLAN.md` | `TASK-CONTRACTS-003`、`TASK-CONTRACTS-004` |

## 3. 非功能追溯

| ID | 规格摘要 | 验证锚点 | 文档锚点 | 任务锚点 |
| --- | --- | --- | --- | --- |
| NFR-001 | 可编译、可测试、可复验 | `go test ./...` | `SPEC.md`、`ACCEPTANCE.md` | `TASK-CONTRACTS-004`、`TASK-CONTRACTS-005` |
| NFR-002 | 竞态安全 | `go test ./... -race -count=1` | `SPEC.md`、`ACCEPTANCE.md` | `TASK-CONTRACTS-005` |
| NFR-003 | 静态检查干净 | `go vet ./...` | `SPEC.md`、`ACCEPTANCE.md` | `TASK-CONTRACTS-005` |
| NFR-004 | 文档更新可审计 | `git diff --check`、`rg` 旧术语扫描 | `SPEC.md`、`TRACEABILITY.md`、`ACCEPTANCE.md` | `TASK-CONTRACTS-004` |
| NFR-005 | 公开符号保留可读 godoc | `contracts.go`、`ports.go`、`ingestion.go`、`projections.go` 的注释 | `SPEC.md`、`README.md` | `TASK-CONTRACTS-001`、`TASK-CONTRACTS-002`、`TASK-CONTRACTS-003`、`TASK-CONTRACTS-005` |
| NFR-006 | canonical reject-code 集合稳定为 9 项 | `ingestion.go` | `SPEC.md`、`README.md`、`ACCEPTANCE.md` | `TASK-CONTRACTS-005` |
| NFR-007 | 不把 transport 实现写成契约本体 | `SPEC.md`、`README.md` | `SPEC.md`、`FEATURES.md` | `TASK-CONTRACTS-000`、`TASK-CONTRACTS-004` |
| NFR-008 | 不回流旧叙事 | `module/contracts/*` 的旧术语扫描 | `SPEC.md`、`goal.md`、`TRACEABILITY.md`、`ACCEPTANCE.md`、`FEATURES.md` | `TASK-CONTRACTS-004` |

## 4. 检查用例

| TC | 检查项 | 覆盖需求 | 证据 |
| --- | --- | --- | --- |
| TC-001 | 导出面与 runtime truth 一致 | FR-001、FR-002、FR-003、FR-004、FR-005、FR-007 | `README.md`、`/home/contracts/pkg/contracts` |
| TC-002 | Provider 方法名只保留当前版本 | FR-004、FR-005、BR-003 | `ports.go`、`README.md` |
| TC-003 | Ingest 是单次请求 / 单次结果 | FR-006、BR-006、BR-007、NFR-006 | `ingestion.go`、`README.md` |
| TC-004 | 兼容别名只作投影，不扩展语义 | FR-007、BR-008、BR-010 | `projections.go`、`README.md` |
| TC-005 | 文档树不存在旧术语 | BR-002、BR-003、NFR-004、NFR-008 | `SPEC.md`、`TRACEABILITY.md`、`FEATURES.md`、`IMPLEMENTATION-PLAN.md`、`tasks/` |
| TC-006 | 变更说明与验收项同源 | FR-008、BR-009 | `README.md`、`goal.md`、`ACCEPTANCE.md` |
| TC-007 | 运行时检查命令可复验 | NFR-001、NFR-002、NFR-003 | `ACCEPTANCE.md` |
| TC-008 | 依赖边界不回流到业务层 | BR-001、BR-004、NFR-007 | `SPEC.md`、`goal.md` |

## 5. 覆盖概览

- FR 覆盖：8 / 8
- BR 覆盖：10 / 10
- NFR 覆盖：8 / 8
- 检查用例：8 / 8
- 任务覆盖：6 / 6
- 已知缺口：无

## 6. 维护规则

- 新增、删除或重命名公开符号时，先更新 `SPEC.md`，再更新本矩阵与 `ACCEPTANCE.md`。
- 任何旧术语回流都先视为文档回归，再决定是否需要代码侧修正。
- 若 runtime truth 发生变化，以 `/home/contracts/pkg/contracts` 的最新导出为准，不以历史 task 文档为准。
