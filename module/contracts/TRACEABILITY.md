# contracts 追溯矩阵

- Status: Docs Baseline Synced / Coverage Closed
- Last-Updated: 2026-06-30
- Layer: 基座 · 跨域接口契约
- Source-of-Truth: `/home/contracts/pkg/contracts`
- Related: `SPEC.md`, `README.md`, `goal.md`, `ACCEPTANCE.md`, `FEATURES.md`, `IMPLEMENTATION-PLAN.md`, `tasks/`

> 本文档把当前 runtime truth 的公开符号映射到 SPEC 的 FR/BR/NFR、验证任务与文档制品；不再保留旧分层、旧版本标记或改名叙事。

## §1 功能需求追溯（FR）

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

---

## §2 业务规则追溯（BR）

| ID | 规格摘要 | runtime / 检查锚点 | 文档锚点 | 任务锚点 |
| --- | --- | --- | --- | --- |
| BR-001 | 仅定义共享契约，不实现业务或传输逻辑 | 包边界与导出面 | `SPEC.md`、`README.md` | `TASK-CONTRACTS-000` |
| BR-002 | 不再使用旧分层命名 | `README.md`、`SPEC.md` | `SPEC.md`、`goal.md`、`FEATURES.md` | `TASK-CONTRACTS-004` |
| BR-003 | 不再使用旧版查询与订阅命名、旧版本标记 | `README.md`、`goal.md`、`tasks/` | `SPEC.md`、`README.md`、`goal.md` | `TASK-CONTRACTS-004` |
| BR-004 | 依赖边界受 `module/FOUNDATION-DEPS.yaml` 约束 | 共享层依赖图 | `SPEC.md`、`goal.md` | `TASK-CONTRACTS-000` |
| BR-005 | DTO 需要明确导出字段与 JSON tag 约定 | `contracts.go`、`regime_*`、`decision_card.go`、`ingestion.go` | `SPEC.md`、`README.md` | `TASK-CONTRACTS-002` |
| BR-006 | `AllRejectCodes()` 只返回 10 个 canonical code | `ingestion.go` | `SPEC.md`、`README.md`、`FEATURES.md` | `TASK-CONTRACTS-005` |
| BR-007 | `RejectUnsupportedChannel` 导出且属于 canonical 列表 | `ingestion.go` | `SPEC.md`、`README.md`、`FEATURES.md` | `TASK-CONTRACTS-005` |
| BR-008 | 兼容别名只承担迁移，不承载新语义 | `projections.go` | `SPEC.md`、`README.md`、`FEATURES.md` | `TASK-CONTRACTS-003` |
| BR-009 | 文档必须保持同一组事实源 | `module/contracts/*` | `SPEC.md`、`README.md`、`TRACEABILITY.md`、`ACCEPTANCE.md`、`FEATURES.md`、`IMPLEMENTATION-PLAN.md`、`tasks/` | `TASK-CONTRACTS-004` |
| BR-010 | 公开 rename/removal 先修兼容层与追溯文档 | `projections.go`、`module/contracts/*` | `SPEC.md`、`goal.md`、`TRACEABILITY.md`、`ACCEPTANCE.md`、`FEATURES.md`、`IMPLEMENTATION-PLAN.md` | `TASK-CONTRACTS-003`、`TASK-CONTRACTS-004` |

## §3 非功能需求追溯（NFR）

| ID | 规格摘要 | 验证锚点 | 文档锚点 | 任务锚点 |
| --- | --- | --- | --- | --- |
| NFR-001 | 可编译、可测试、可复验 | `go test ./...` | `SPEC.md`、`ACCEPTANCE.md` | `TASK-CONTRACTS-004`、`TASK-CONTRACTS-005` |
| NFR-002 | 竞态安全 | `go test ./... -race -count=1` | `SPEC.md`、`ACCEPTANCE.md` | `TASK-CONTRACTS-005` |
| NFR-003 | 静态检查干净 | `go vet ./...` | `SPEC.md`、`ACCEPTANCE.md` | `TASK-CONTRACTS-005` |
| NFR-004 | 文档更新可审计 | `git diff --check`、`rg` 旧术语扫描 | `SPEC.md`、`TRACEABILITY.md`、`ACCEPTANCE.md` | `TASK-CONTRACTS-004` |
| NFR-005 | 公开符号保留可读 godoc | `contracts.go`、`ports.go`、`ingestion.go`、`projections.go` 的注释 | `SPEC.md`、`README.md` | `TASK-CONTRACTS-001`、`TASK-CONTRACTS-002`、`TASK-CONTRACTS-003`、`TASK-CONTRACTS-005` |
| NFR-006 | canonical reject-code 集合稳定为 10 项 | `ingestion.go` | `SPEC.md`、`README.md`、`ACCEPTANCE.md` | `TASK-CONTRACTS-005` |
| NFR-007 | 不把 transport 实现写成契约本体 | `SPEC.md`、`README.md` | `SPEC.md`、`FEATURES.md` | `TASK-CONTRACTS-000`、`TASK-CONTRACTS-004` |
| NFR-008 | 不回流旧叙事 | `module/contracts/*` 的旧术语扫描 | `SPEC.md`、`goal.md`、`TRACEABILITY.md`、`ACCEPTANCE.md`、`FEATURES.md` | `TASK-CONTRACTS-004` |

## §4 TC -> FR 反向追溯

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

## §5 全局 AC 注册表

> contracts 模块以接口契约为中心，AC 与 FR 一体化定义于 SPEC.md 和 ACCEPTANCE.md，本注册表提供交叉引用索引。

| AC 覆盖 | 关联 FR/BR | 验证 TC | 状态 |
| ------- | ---------- | ------- | ---- |
| FR-001~008 全部 | FR-001~008 | TC-001~008 | Done |
| BR-001~010 全部 | BR-001~010 | TC-001~008 | Done |
| NFR-001~008 全部 | NFR-001~008 | TC-007 | Done |

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| ---- | ---- | ---- | ------ |
| FR (功能需求) | 8 | 8 | 100% |
| BR (业务规则) | 10 | 10 | 100% |


| NFR (非功能需求) | 8 | 8 | 100% |
| TC (测试用例) | 8 | 8 | 100% |
| **合计** | **34** | **34** | **100%** |

> 说明：contracts 为纯接口契约模块，AC 粒度与 FR 同构。Task 总数 = TASK-CONTRACTS-000~005 共 6 项，全部关闭。

## §7 变更历史

| 日期 | 变更内容 |
| ---- | -------- |
| 2026-06-29 | Goal 管线对齐：章节重编号为标准 §1-§7 结构；§6 覆盖概览转为标准化 Done/覆盖率表格；新增 §5 AC 注册表索引；新增 §7 变更历史 |
| 2026-06-22 | Docs Baseline Synced：FR/BR/NFR 全链路关闭，覆盖概览 100% |

## 维护规则

- 新增、删除或重命名公开符号时，先更新 `SPEC.md`，再更新本矩阵与 `ACCEPTANCE.md`。
- 任何旧术语回流都先视为文档回归，再决定是否需要代码侧修正。
- 若 runtime truth 发生变化，以 `/home/contracts/pkg/contracts` 的最新导出为准，不以历史 task 文档为准。
