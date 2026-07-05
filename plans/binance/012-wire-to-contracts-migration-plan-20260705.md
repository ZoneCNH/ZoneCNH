# 计划：internal/wire → contracts 迁移（ADR-002 闭环）

> 状态：Draft（待 Goal Gate 审批）
> 日期：2026-07-05
> 仓库归属：ZoneCNH 主仓 `plans/binance/`（治理计划）；代码改动分布在 `binance` 与 `contracts` 两个 runtime 仓
> 关联：`module/binance/design/ADR-002-wire-boundary.md`（本计划闭环该 ADR 的"待迁移"状态）
> 权威：CONSTITUTION.md §4 接口契约 + `module/FOUNDATION-DEPS.yaml` 依赖矩阵

## 0. 背景与现状（事实基线）

### 0.1 当前结构

`/home/workspace/binance/internal/wire/` 共 5 文件：

| 文件            | 行数 | 职责                                                                                                                |
| --------------- | ---- | ------------------------------------------------------------------------------------------------------------------- |
| `doc.go`        | 16   | 包文档，标注 ADR-002 过渡态与迁移路径                                                                               |
| `types.go`      | 168  | `IngestRequest`/`IngestResult`/`IngestAck`/`IngestReject` + `QualityVerdict`/`GapStatus`/`SLAStatus`/`TraceContext` |
| `reject.go`     | 42   | `RejectCode` 枚举（BNC-001..019 模块码 + 9 个 canonical 别名）                                                      |
| `transport.go`  | 8    | `IngestEndpoint` 接口                                                                                               |
| `types_test.go` | —    | Ack/Reject 互斥不变量测试                                                                                           |

### 0.2 引用规模

`[COMPUTED]` `rg -l "internal/wire" --type go` 在 binance 仓命中 **62 个文件**（含 wire 自身 1 个）。分布：

- `internal/client/**`：~16 文件
- `internal/server/**`：~22 文件
- `cmd/**`：4 文件（binance-client、binance-smoke）
- `test/**`：8 文件（e2e/soak/chaos/depth/restart）
- `internal/wire/**`：1 文件

### 0.3 contracts 仓现状

`/home/workspace/contracts/pkg/contracts/ingestion.go`（120 行）已定义 canonical 类型，但与 wire 存在**三处结构性差异**（见 §1）。

### 0.4 架构约束（不可违背）

`[KNOWN, HIGH]` 来自 `module/FOUNDATION-DEPS.yaml`：

- L200 `contracts: []` —— contracts 无 Foundation 运行时依赖
- L411-413 `from: contracts, to: [kernel, configx, observex, ...business]` —— contracts 允许下游**不含** L2.5（domain_market/decimalx/domainx）
- 推论：contracts **不能 import `domainmarket.InstrumentKey`**（该类型经 `decimalx.Decimal` 传递依赖，会污染 contracts 的零依赖边界）

这正是 ADR-002 迁移被阻塞的根本原因，也是本计划方案选择的硬约束。

## 1. 差异分析（wire vs contracts canonical）

`[COMPUTED]` 逐字段对比：

### 1.1 IngestRequest

| 字段                       | wire                                   | contracts canonical | 处置                                                                            |
| -------------------------- | -------------------------------------- | ------------------- | ------------------------------------------------------------------------------- |
| IdempotencyKey / RequestID | `IdempotencyKey string`                | `RequestID string`  | **语义同**，命名不同 → 统一为 `RequestID`                                       |
| Source                     | ✅                                     | ✅                  | 对齐                                                                            |
| ProductLine                | ✅                                     | ✅                  | 对齐                                                                            |
| Symbol                     | ✅                                     | ❌                  | **canonical 缺** → 补入                                                         |
| InstrumentKey              | `domainmarket.InstrumentKey`（强类型） | `json.RawMessage`   | **核心差异**（见 §1.4）                                                         |
| EventType                  | ✅                                     | ✅                  | 对齐                                                                            |
| EventTime                  | ✅                                     | ✅                  | 对齐                                                                            |
| ReceivedAt                 | ✅                                     | ✅                  | 对齐                                                                            |
| SchemaVersion              | ✅                                     | ✅                  | 对齐                                                                            |
| Payload                    | `[]byte`                               | `json.RawMessage`   | **类型不同**（json.RawMessage 是 []byte 别名+语义） → 统一 `json.RawMessage`    |
| PayloadHash                | ✅                                     | ❌                  | **canonical 缺** → 补入                                                         |
| Sequence                   | ❌                                     | ✅                  | **wire 缺** → wire 已用 SourceMetadata 承载，canonical 该字段 `omitempty`，保留 |
| OrderingKey                | ❌                                     | ✅                  | **wire 缺** → 同上                                                              |
| SourceMetadata             | ✅                                     | ✅                  | 对齐                                                                            |
| TraceContext               | ✅                                     | ❌                  | **canonical 缺** → 补入（W3C 透传是跨域契约，属 canonical 范畴）                |
| Quality                    | ✅                                     | ❌                  | **canonical 缺** → 补入（QualityVerdict 是跨域质量门禁语义）                    |

### 1.2 IngestAck

| 字段          | wire               | contracts            | 处置                                                                                                 |
| ------------- | ------------------ | -------------------- | ---------------------------------------------------------------------------------------------------- |
| StreamID      | ✅                 | ✅                   | 对齐                                                                                                 |
| RequestID     | ❌（在 Result 层） | ✅                   | contracts 放 Ack 内，wire 放 Result —— 统一放 Result                                                 |
| AcceptedKey   | ✅                 | ❌                   | **canonical 缺** → 补入                                                                              |
| AcceptedCount | ❌                 | ✅                   | wire 用 AcceptedKey 单键，contracts 用计数 —— 保留 contracts，wire 的 AcceptedKey 视为单条场景       |
| Duplicate     | bool               | DuplicateCount int32 | **语义重叠**，类型不同 → 保留 contracts `DuplicateCount`，wire `Duplicate` 映射为 `DuplicateCount>0` |
| Durable       | ✅                 | ✅                   | 对齐                                                                                                 |
| AcceptedAt    | ✅                 | ❌                   | **canonical 缺** → 补入                                                                              |
| Quality       | ✅                 | ❌                   | **canonical 缺** → 补入                                                                              |
| Gap           | ✅                 | ❌                   | **canonical 缺** → 补入                                                                              |
| SLA           | ✅                 | ❌                   | **canonical 缺** → 补入                                                                              |

### 1.3 RejectCode

- wire（reject.go）：`BNC-001..019` 模块私有码为主，9 个 canonical 别名指向 BNC 码
- contracts：9 个 canonical string 码（`retryable`/`terminal_validation`/...），无 BNC 码

**冲突**：wire 的 `RejectCode` 类型 = `string`，但常量值是 `BNC-xxx`；contracts 常量值是 canonical 名。两者**不可直接互换**。

处置：binance 内部仍需 BNC 码做模块级诊断/告警路由，canonical 码做跨域契约。采用**双字段**：contracts `IngestReject.RejectCode`（canonical）+ binance 私有 `BNCCode`（仅在 binance 仓内附加，通过 wrapper）。

### 1.4 InstrumentKey 核心差异（迁移关键阻塞）

| 维度     | wire                                                          | contracts                  |
| -------- | ------------------------------------------------------------- | -------------------------- |
| 类型     | `domainmarket.InstrumentKey`（强类型，含 `decimalx.Decimal`） | `json.RawMessage`          |
| 类型安全 | 编译期                                                        | 运行时反序列化             |
| 依赖     | 经 domain_market→decimalx                                     | 零依赖                     |
| 架构合规 | binance 可依赖 L2.5 ✅                                        | contracts 不可依赖 L2.5 ✅ |

## 2. 方案抉择

### 方案 A：contracts 泛型参数化 `IngestRequest[T any]`

- contracts 定义 `IngestRequest[T any]`，binance 实例化为 `IngestRequest[domainmarket.InstrumentKey]`
- 优点：保留强类型
- 缺点：[INFERRED] 泛型契约导致所有消费方（market_data 等未来 ingestor）都要携带类型参数，contracts API 复杂化；Go 泛型对方法集约束限制多；`MarketDataService` 接口需同步泛型化，破坏接口窄表面积原则（宪法 §4）
- **拒绝**：契约层泛型化代价过大，违反"窄接口"原则

### 方案 B：contracts 定义 plain InstrumentKey DTO

- contracts 定义 `InstrumentKey struct{ Venue, ProductLine, Symbol, ... string; Expiry *time.Time; Strike string }`（Strike 用 string 避免 decimalx 依赖）
- binance 在 boundary 做 `domainmarket.InstrumentKey ↔ contracts.InstrumentKey` 转换
- 优点：contracts 零依赖 + 强类型 DTO
- 缺点：[INFERRED] 双 InstrumentKey 定义（contracts plain + domain_market 强类型），违反 DRY；decimalx.Decimal↔string 转换有精度风险；domain_market 是 InstrumentKey 的 SSOT，contracts 重复定义造成权威分裂

### 方案 C（推荐）：contracts canonical 富化 + json.RawMessage 保留 + binance boundary adapter

- **contracts canonical 富化**：把 wire 的跨域语义字段（Symbol/PayloadHash/TraceContext/Quality/Gap/SLA/AcceptedKey/AcceptedAt）补入 contracts.IngestRequest/IngestAck，InstrumentKey 保持 `json.RawMessage`
- **binance 保留极薄 boundary 包**（重命名 `internal/wire` → `internal/ingestcodec`，仅做 `domainmarket.InstrumentKey ↔ json.RawMessage` 序列化 + BNC 码映射 helper，**不再定义任何 DTO**）
- **61 个 import 站点**改 import `contracts` 类型，DTO 字段访问改 canonical 名
- 优点：contracts 零依赖保持；canonical 单一权威；binance 私有逻辑下沉到 codec；强类型在 binance 内部 boundary 处保留
- 缺点：61 处 import 改动量大；contracts 需 breaking change（字段补入 + RequestID 命名统一）

**决策：采用方案 C。** 理由：唯一同时满足"contracts 零依赖硬约束"+"canonical 单一权威"+"binance 强类型在 boundary 保留"三者。

## 3. 阶段化执行计划

### Phase 0 — ADR 决策与设计冻结（0.5d，主仓）

- [ ] **0.1** 撰写 `module/binance/design/ADR-006-wire-to-contracts-migration.md`（Supersede ADR-002），记录方案 C 决策、字段对齐表、迁移路径
- [ ] **0.2** 更新 `module/contracts/spec/SPEC.md` §8.4，把 canonical 富化字段写入规格（Symbol/PayloadHash/TraceContext/Quality/Gap/SLA/AcceptedKey/AcceptedAt）
- [ ] **0.3** 同步 `module/binance/spec/SPEC.md` §9 字段表，标注"对齐 contracts canonical"
- [ ] **0.4** Goal Gate G2（Spec）审批

### Phase 1 — contracts canonical 富化（1d，contracts 仓 PR-1）

- [ ] **1.1** `pkg/contracts/ingestion.go` 补入字段：`Symbol`、`PayloadHash`、`TraceContext`（struct）、`QualityVerdict`（struct）、`GapStatus`（struct）、`SLAStatus`（struct）
- [ ] **1.2** `IngestAck` 补入：`AcceptedKey`、`AcceptedAt`、`Quality`、`Gap`、`SLA`
- [ ] **1.3** 统一命名：`IdempotencyKey` → `RequestID`（contracts 已是 RequestID，无需改）
- [ ] **1.4** `IngestRequest.Payload` 类型 `[]byte` → `json.RawMessage`（contracts 已是）
- [ ] **1.5** 定义 `TraceContext`/`QualityVerdict`/`GapStatus`/`SLAStatus` 为 contracts 包导出类型（跨域语义，属 canonical）
- [ ] **1.6** 补 `ingestion_test.go`：新字段 JSON round-trip + 不变量（Ack/Reject 互斥）
- [ ] **1.7** contracts 仓 `make ci`（boundary/contracts/lint/test/race）全绿
- [ ] **1.8** contracts 版本 bump：`v1.5.0` → `v1.6.0`（breaking：字段补入 + Payload 类型变更），打 tag
- [ ] **1.9** PR-1 合入 contracts main

**验证命令**：

```bash
cd /home/workspace/contracts
go test ./pkg/contracts/... -race
go vet ./...
golangci-lint run ./...
```

### Phase 2 — binance boundary codec 建立（0.5d，binance 仓 PR-2）

- [ ] **2.1** 新建 `internal/ingestcodec/` 包（替代 wire 的 DTO 职责）
  - `instrumentkey.go`：`MarshalInstrumentKey(domainmarket.InstrumentKey) (json.RawMessage, error)` + 反序列化
  - `bnc_code.go`：`BNCCode` 枚举（BNC-001..019）+ `BNCCodeToCanonical(RejectCode) RejectCode` 映射
  - `doc.go`：包文档
- [ ] **2.2** binance `go.mod` 新增 direct 依赖 `github.com/ZoneCNH/contracts v1.6.0`
- [ ] **2.3** `go mod tidy` + 验证 `go build ./...`

### Phase 3 — import 站点迁移（2d，binance 仓 PR-2 续）

按依赖方向分批切换，每批可独立编译验证：

**Batch 3a — internal/server/**（~22 文件）

- [ ] 3a.1 `internal/server/ingest.go`：`wire.IngestRequest` → `contracts.IngestRequest`，字段访问 `IdempotencyKey`→`RequestID`、`InstrumentKey`（domainmarket）→ 经 `ingestcodec.MarshalInstrumentKey` 转 `json.RawMessage`
- [ ] 3a.2 `internal/server/consumer/consumer.go`、`internal/server/admin.go`、`internal/server/quality.go`、`internal/server/replay_bridge.go`、`internal/server/alert_dispatcher.go`、`internal/server/deadletter_replay.go`、`internal/server/logging.go`
- [ ] 3a.3 server 侧 test 文件同步（coverage_100/coverage_targets/sla_window/schema_compat/group1/bench/m4/admin/helper/kafka_dispatch/metrics_integration/controlplane/storage_ingest/server_final）
- [ ] 3a.4 验证：`go build ./internal/server/... && go test ./internal/server/... -short`

**Batch 3b — internal/client/**（~16 文件）

- [ ] 3b.1 `internal/client/runtime.go`、`internal/client/ingest_request.go`、`internal/client/relay.go`、`internal/client/queue.go`、`internal/client/history_lifecycle.go`、`internal/client/http_ingest_endpoint.go`、`internal/client/publisher/publisher.go`
- [ ] 3b.2 `internal/client/doc.go`
- [ ] 3b.3 client 侧 test 文件同步
- [ ] 3b.4 验证：`go build ./internal/client/... && go test ./internal/client/... -short`

**Batch 3c — cmd/**（4 文件）

- [ ] 3c.1 `cmd/binance-client/main.go`、`cmd/binance-smoke/main.go`（含 main_test.go）
- [ ] 3c.2 验证：`go build ./cmd/...`

**Batch 3d — test/**（8 文件）

- [ ] 3d.1 `test/e2e/*`、`test/soak/*`、`test/chaos/*`、`test/depth/*`、`test/restart_recovery_test.go`
- [ ] 3d.2 验证：`go test ./test/... -short`（集成测试按 opt-in）

### Phase 4 — internal/wire 收缩与删除（0.5d，binance 仓 PR-2 续）

- [ ] **4.1** `internal/wire/types.go`：删除全部 DTO（IngestRequest/Result/Ack/Reject/QualityVerdict/GapStatus/SLAStatus/TraceContext）
- [ ] **4.2** `internal/wire/reject.go`：删除（BNC 码迁至 `internal/ingestcodec/bnc_code.go`）
- [ ] **4.3** `internal/wire/transport.go`：删除 `IngestEndpoint` 接口（改用 `contracts.MarketDataService` 或 binance 私有接口视实际调用形态）
- [ ] **4.4** `internal/wire/types_test.go`：不变量测试迁至 contracts 仓 `ingestion_test.go`（已在 Phase 1.6 完成）
- [ ] **4.5** 评估：`internal/wire/` 是否完全删除，还是保留为空包占位 → **完全删除**（`rmdir internal/wire`）
- [ ] **4.6** 验证零残留：`rg "internal/wire" /home/workspace/binance --type go` → 0 命中

### Phase 5 — gate / evidence / 文档闭环（0.5d，双仓）

- [ ] **5.1** binance `scripts/boundary-gates.sh` 14/14 PASS（§3/§4 client-server 互不 import 仍由 contracts 类型隔离保证）
- [ ] **5.2** binance `go build/test/race/vet` + `golangci-lint` 全绿
- [ ] **5.3** binance 本地 smoke self-test PASS
- [ ] **5.4** ADR-002 状态改 `Superseded by ADR-006`；ADR-006 状态 `Accepted`
- [ ] **5.5** 更新文档：
  - `module/binance/design/DESIGN.md` ADR 表（ADR-002 → Superseded）
  - `module/binance/spec/FEATURES.md` BR-008（去掉"ADR-002 过渡态"措辞，改为"已迁入 contracts canonical"）
  - `module/binance/gate/BOUNDARY-GATES.md` §8（wire externality 描述更新）
  - `module/binance/matrix/RUNTIME-GAP-MATRIX.md`（GAP-E23 引用路径更新或关闭）
  - ZoneCNH 主仓 `report/arch/` 下 5 份分析报告的"wire 未迁移"条目标记为 Resolved（归档说明，不重写）
  - `internal/wire/doc.go` 已随 Phase 4 删除
- [ ] **5.6** Goal Gate G8（Review）/ G9（Release）证据归档至 `module/binance/evidence/2026-07-DD/`

## 4. 风险与缓解

| 风险                                     | 等级 | 缓解                                                                                                                                      |
| ---------------------------------------- | ---- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| 61 处 import 切换引入编译错误            | MED  | 分 4 batch 切换，每 batch 独立 `go build` 验证；先 server 后 client（server 是消费方，client 是生产方）                                   |
| InstrumentKey 序列化/反序列化精度丢失    | MED  | boundary codec 单元测试覆盖 `decimalx.Decimal`（Strike）+ `*time.Time`（Expiry）round-trip；用 golden file 固定                           |
| contracts breaking change 影响其他消费方 | LOW  | `[COMPUTED]` 当前仅 binance 使用 ingestion 契约（contracts 仓 ingestion.go 仅 binance 引用，见 §0.3）；版本 bump v1.6.0 显式标注 breaking |
| BNC 码与 canonical 码映射错位            | MED  | `ingestcodec/bnc_code.go` 建映射表 + 测试；reject.go 现有别名关系作为映射 SSOT                                                            |
| boundary-gates §3/§4 误报                | LOW  | §3/§4 检测 client↔server 互不 import，迁移后改为 contracts 类型隔离，门禁逻辑不变；预跑确认                                               |
| domain_market InstrumentKey 字段未来扩展 | LOW  | codec 层做向前兼容（未知字段保留到 SourceMetadata 或忽略策略），contracts json.RawMessage 天然兼容                                        |

## 5. 验证清单（Definition of Done）

- [ ] `rg "internal/wire" /home/workspace/binance --type go` → 0 命中
- [ ] `rg "github.com/ZoneCNH/contracts" /home/workspace/binance --type go` → ≥1 命中（go.mod direct + import）
- [ ] binance `go build ./...` PASS
- [ ] binance `go test ./... -short` PASS
- [ ] binance `go test -race ./...` PASS
- [ ] binance `go vet ./...` PASS
- [ ] binance `golangci-lint run` PASS
- [ ] binance `bash scripts/boundary-gates.sh` → 14/14 PASS
- [ ] binance 本地 smoke self-test PASS
- [ ] contracts `go test ./pkg/contracts/... -race` PASS
- [ ] ADR-006 Accepted，ADR-002 Superseded
- [ ] `module/binance/evidence/2026-07-DD/` 含 test/review/release 三类证据

## 6. 估时与依赖

| Phase    | 工时   | 前置                      | 仓库         |
| -------- | ------ | ------------------------- | ------------ |
| 0        | 0.5d   | —                         | ZoneCNH 主仓 |
| 1        | 1d     | P0                        | contracts    |
| 2        | 0.5d   | P1 (contracts v1.6.0 tag) | binance      |
| 3        | 2d     | P2                        | binance      |
| 4        | 0.5d   | P3                        | binance      |
| 5        | 0.5d   | P4                        | 双仓         |
| **合计** | **5d** |                           |              |

P2/P3/P4 可合并为 binance 单 PR-2；P1 为 contracts 独立 PR-1。P0 必须先于一切。

## 7. 不在本计划范围（Non-goals）

- 不重构 binance client/server 业务逻辑（仅切换契约类型来源）
- 不引入 transportx（Envelope 迁移是独立 ADR，见 `docs/production-standards/transportx.md`）
- 不处理 GAP-E8/E19/E23（schema/hash/精度治理，另有 `plans/binance/011-runtime-gap-master-plan` 承载）
- 不改 contracts 其他文件（ports.go/decision*card.go/regime*\*.go 等）
- 不动 binance 与 domain_market 的依赖关系（L2.5 依赖合规，保持）
