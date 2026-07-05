# 计划：internal/wire → contracts 迁移（ADR-002 闭环）

> 状态：**Completed**（Phase 0-5 全部实施，2026-07-05）
> 日期：2026-07-05
> 仓库归属：ZoneCNH 主仓 `plans/binance/`（治理计划）；代码改动分布在 `binance` 与 `contracts` 两个 runtime 仓
> 关联：`module/binance/design/ADR-007-wire-to-contracts-migration.md`（本计划闭环 ADR-002 的"待迁移"状态）
> 权威：CONSTITUTION.md §4 接口契约 + `module/FOUNDATION-DEPS.yaml` 依赖矩阵
> PR：contracts [#19](https://github.com/ZoneCNH/contracts/pull/19)（v0.5.0）、binance [#432](https://github.com/ZoneCNH/binance/pull/432)、ZoneCNH [#1679](https://github.com/ZoneCNH/ZoneCNH/pull/1679)

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

### 0.3 contracts 仓现状（迁移后）

`/home/workspace/contracts/pkg/contracts/ingestion.go` 已富化为 canonical 单一权威（v0.5.0），吸收原 wire 跨域语义字段。原 binance `internal/wire` 已删除，`internal/ingestcodec` boundary 层负责 `domainmarket.InstrumentKey ↔ json.RawMessage` 序列化与 BNC 码映射。

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
| RequestID     | ❌（在 Result 层） | ✅                   | 计划：统一放 Result；**实际偏差**：RequestID 保留在 IngestAck 内（未移除），因 Ack 内 RequestID 用于幂等键回执匹配，移至 Result 会破坏 ack→request 关联语义 |
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

处置：binance 内部仍需 BNC 码做模块级诊断/告警路由，canonical 码做跨域契约。实际实现：contracts `IngestReject.RejectCode`（canonical）为唯一跨域字段；binance 在 `internal/ingestcodec` 维护 BNC 私有码（`RejectCode` BNC-001..019）+ `BNCCodeToCanonical(BNCCode) contracts.RejectCode` 映射函数，构造 `IngestReject` 时经映射写入 canonical 码。`RejectError.Code`（server 内部错误类型）保留 BNC 码用于模块级诊断。

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
- **61 个 import 站点**（62 文件减去 wire 自身 1 个）改 import `contracts` 类型，DTO 字段访问改 canonical 名
- 优点：contracts 零依赖保持；canonical 单一权威；binance 私有逻辑下沉到 codec；强类型在 binance 内部 boundary 处保留
- 缺点：61 处 import 改动量大；contracts 需 breaking change（字段补入 + RequestID 命名统一）

**决策：采用方案 C。** 理由：唯一同时满足"contracts 零依赖硬约束"+"canonical 单一权威"+"binance 强类型在 boundary 保留"三者。

## 3. 阶段化执行计划

### Phase 0 — ADR 决策与设计冻结（0.5d，主仓）✅

- [x] **0.1** 撰写 `module/binance/design/ADR-007-wire-to-contracts-migration.md`（Supersede ADR-002），记录方案 C 决策、字段对齐表、迁移路径
- [x] **0.2** 更新 `module/contracts/spec/SPEC.md` FR-006，把 canonical 富化字段写入规格（Symbol/PayloadHash/TraceContext/Quality/Gap/SLA/AcceptedKey/AcceptedAt）+ 新增 BR-011
- [x] **0.3** 同步 `module/binance/spec/SPEC.md` §4 Runtime Boundary，`internal/wire` → `internal/ingestcodec`
- [x] **0.4** ADR-007 状态 Accepted（Phase 0-4 实施验证后转 Accepted）

### Phase 1 — contracts canonical 富化（1d，contracts 仓 PR #19）✅

- [x] **1.1** `pkg/contracts/ingestion.go` 补入字段：`Symbol`、`PayloadHash`、`TraceContext`（struct）、`QualityVerdict`（struct）、`GapStatus`（struct）、`SLAStatus`（struct）
- [x] **1.2** `IngestAck` 补入：`AcceptedKey`、`AcceptedAt`、`Quality`、`Gap`、`SLA`
- [x] **1.3** 统一命名：`IdempotencyKey` → `RequestID`（contracts 已是 RequestID，binance 侧迁移时改字段访问）
- [x] **1.4** `IngestRequest.Payload` 类型语义明确为 `json.RawMessage`（contracts 已是）
- [x] **1.5** 定义 `TraceContext`/`QualityVerdict`/`GapStatus`/`SLAStatus` 为 contracts 包导出类型（跨域语义，属 canonical）
- [x] **1.6** 补 `ingestion_test.go`：新字段 JSON round-trip + 不变量（Ack/Reject 互斥）+ `IsAck`/`IsReject`/`Validate()`
- [x] **1.7** contracts 仓 `go build/vet/lint/test/race` + `make boundary`/`make contracts` 全绿（`make test`/`make race` 因 `scripts/` 预存 stale 测试失败，非本次引入；`make governance-check` 需 `GOWORK=off`）
- [x] **1.8** contracts 版本 bump：v0.4.x → **v0.5.0**（breaking），CHANGELOG 已写，待合入打 tag
- [x] **1.9** PR #19 已创建，待合入

**验证命令**：

```bash
cd /home/workspace/contracts
go test ./pkg/contracts/... -race
go vet ./...
golangci-lint run ./...
```

### Phase 2 — binance boundary codec 建立（0.5d，binance 仓 PR #432）✅

- [x] **2.1** 新建 `internal/ingestcodec/` 包（替代 wire 的 DTO 职责）
  - `instrumentkey.go`：`MarshalInstrumentKey`/`UnmarshalInstrumentKey`/`MustMarshalInstrumentKey`
  - `bnc_code.go`：BNC-001..019 枚举 + `BNCCodeToCanonical` 映射 + canonical 常量重导出
  - `aliases.go`：contracts DTO 类型别名 + `IngestEndpoint` + `NewAckResult`/`NewRejectResult` + `BoolToInt32`
  - `doc.go`：包文档
  - `codec_test.go`：InstrumentKey round-trip + BNC 映射测试
- [x] **2.2** binance `go.mod` 新增 direct 依赖 `github.com/ZoneCNH/contracts v0.5.0` + 临时 `replace`（待 contracts tag 发布后移除）
- [x] **2.3** `go build ./...` 验证通过

### Phase 3 — import 站点迁移（2d，binance 仓 PR #432 续）✅

按依赖方向分批切换，每批可独立编译验证：

**Batch 3a — internal/server/**（~22 文件）

- [x] 3a.1 `internal/server/ingest.go`：`wire.IngestRequest` → `ingestcodec.IngestRequest`，字段访问 `IdempotencyKey`→`RequestID`、`InstrumentKey` 经 `ingestcodec.UnmarshalInstrumentKey` 还原 `domainmarket.InstrumentKey`、`Duplicate`(bool)→`DuplicateCount`(int)、`IngestReject.Code`(BNC)→`RejectCode`(canonical via `BNCCodeToCanonical`)
- [x] 3a.2 `internal/server/server.go`（RejectCode 别名重指向 ingestcodec）、`consumer/consumer.go`、`admin.go`、`quality.go`、`replay_bridge.go`、`alert_dispatcher.go`、`deadletter_replay.go`、`logging.go`
- [x] 3a.3 server 侧 test 文件同步
- [x] 3a.4 验证：`go build ./internal/server/... && go test ./internal/server/... -short`

**Batch 3b — internal/client/**（~16 文件）

- [x] 3b.1 `internal/client/ingest_request.go`（InstrumentKey 经 `MarshalInstrumentKey` 序列化）、`runtime.go`、`relay.go`、`queue.go`、`history_lifecycle.go`、`http_ingest_endpoint.go`、`publisher/publisher.go`
- [x] 3b.2 `internal/client/doc.go`
- [x] 3b.3 client 侧 test 文件同步
- [x] 3b.4 验证：`go build ./internal/client/... && go test ./internal/client/... -short`

**Batch 3c — cmd/**（4 文件）

- [x] 3c.1 `cmd/binance-client/main.go`、`cmd/binance-smoke/main.go`（含 main_test.go）
- [x] 3c.2 验证：`go build ./cmd/...`

**Batch 3d — test/**（8 文件）

- [x] 3d.1 `test/e2e/*`、`test/soak/*`、`test/chaos/*`、`test/depth/*`、`test/restart_recovery_test.go`
- [x] 3d.2 验证：`go test ./test/... -short`（集成测试按 opt-in）

### Phase 4 — internal/wire 收缩与删除（0.5d，binance 仓 PR #432 续）✅

- [x] **4.1** `internal/wire/types.go`：删除全部 DTO
- [x] **4.2** `internal/wire/reject.go`：删除（BNC 码迁至 `internal/ingestcodec/bnc_code.go`）
- [x] **4.3** `internal/wire/transport.go`：删除 `IngestEndpoint` 接口（迁至 `internal/ingestcodec/aliases.go`）
- [x] **4.4** `internal/wire/types_test.go`：不变量测试迁至 contracts 仓 `ingestion_test.go`（Phase 1.6）
- [x] **4.5** `internal/wire/` 完全删除（`rm -rf internal/wire`）
- [x] **4.6** 验证零残留：`rg "internal/wire" /home/workspace/binance --type go` → 0 命中

### Phase 5 — gate / evidence / 文档闭环（0.5d，双仓）✅

- [x] **5.1** binance `scripts/boundary-gates.sh` **15/15 PASS**（§3/§4 client-server 互不 import 由 contracts 类型隔离保证）
- [x] **5.2** binance `go build/test/race/vet` 全绿；`golangci-lint` 仅预存 issue（whitelist/whitelistclient，非本次引入）
- [x] **5.3** binance 本地 smoke self-test（含于 `go test ./... -short`）
- [x] **5.4** ADR-002 状态改 `Superseded by ADR-007`；ADR-007 状态 `Accepted`
- [x] **5.5** 更新文档：
  - `module/binance/design/DESIGN.md` ADR 表（ADR-002 → Superseded，新增 ADR-007）
  - `module/binance/spec/FEATURES.md` BR-008（去掉"ADR-002 过渡态"措辞，改为"已迁入 contracts canonical"）
  - `module/binance/gate/BOUNDARY-GATES.md` §5/§8（wire externality 描述更新）+ gate 计数 13→15
  - `module/binance/matrix/RUNTIME-GAP-MATRIX.md` GAP-E23（路径引用更新）
  - `module/binance/design/RUNTIME-MAPPING.md`（wire 引用更新 + gate 10→15）
  - `module/README.md` 目录树（internal/wire → internal/ingestcodec）
  - `module/binance/spec/ACCEPTANCE.md` P10-A1（标注 ADR-007 闭环）
  - ZoneCNH 主仓 `report/arch/` 6 份 + `report/binance/` 3 份报告加归档说明；`report/binance/06.md` 正文对齐
  - binance runtime 仓 `BOUNDARY-GATES.md`/`README.md`/evidence template 同步
- [x] **5.6** 证据归档至 `module/binance/evidence/2026-07-05/release/adr-007-wire-migration.md`

## 4. 风险与缓解

| 风险                                     | 等级 | 缓解                                                                                                                                      |
| ---------------------------------------- | ---- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| 61 处 import 切换引入编译错误            | MED  | 分 4 batch 切换，每 batch 独立 `go build` 验证；先 server 后 client（server 是消费方，client 是生产方）。**已验证**：实际 62 文件，分批迁移后 build/vet 全绿 |
| InstrumentKey 序列化/反序列化精度丢失    | MED  | boundary codec 单元测试覆盖 `decimalx.Decimal`（Strike）+ `*time.Time`（Expiry）round-trip；用 golden file 固定                           |
| contracts breaking change 影响其他消费方 | LOW  | `[COMPUTED]` 当前仅 binance 使用 ingestion 契约（contracts 仓 ingestion.go 仅 binance 引用，见 §0.3）；版本 bump v0.5.0 显式标注 breaking |
| BNC 码与 canonical 码映射错位            | MED  | `ingestcodec/bnc_code.go` 建映射表 + 测试；reject.go 现有别名关系作为映射 SSOT                                                            |
| boundary-gates §3/§4 误报                | LOW  | §3/§4 检测 client↔server 互不 import，迁移后改为 contracts 类型隔离，门禁逻辑不变；预跑确认                                               |
| domain_market InstrumentKey 字段未来扩展 | LOW  | codec 层做向前兼容（未知字段保留到 SourceMetadata 或忽略策略），contracts json.RawMessage 天然兼容                                        |

## 5. 验证清单（Definition of Done）

- [x] `rg "internal/wire" /home/workspace/binance --type go` → 0 命中
- [x] `rg "github.com/ZoneCNH/contracts" /home/workspace/binance --type go` → 2 文件命中（go.mod + import）
- [x] binance `go build ./...` PASS
- [x] binance `go test ./... -short` PASS
- [x] binance `go test -race ./internal/... ./cmd/... -short` PASS
- [x] binance `go vet ./...` PASS
- [x] binance `golangci-lint run` —— 本次改动 0 issue（预存 whitelist/whitelistclient issue 非本次引入）
- [x] binance `bash scripts/boundary-gates.sh` → **15/15 PASS**
- [x] binance `go test ./... -short` 含 smoke 路径
- [x] contracts `go test ./pkg/contracts/... -race` PASS
- [x] ADR-007 Accepted，ADR-002 Superseded
- [x] `module/binance/evidence/2026-07-05/release/adr-007-wire-migration.md` 证据归档

## 6. 估时与依赖

| Phase    | 工时   | 前置                      | 仓库         | 状态 |
| -------- | ------ | ------------------------- | ------------ | ---- |
| 0        | 0.5d   | —                         | ZoneCNH 主仓 | ✅    |
| 1        | 1d     | P0                        | contracts    | ✅    |
| 2        | 0.5d   | P1 (contracts v0.5.0 tag) | binance      | ✅    |
| 3        | 2d     | P2                        | binance      | ✅    |
| 4        | 0.5d   | P3                        | binance      | ✅    |
| 5        | 0.5d   | P4                        | 双仓         | ✅    |
| **合计** | **5d** |                           |              | **完成** |

P2/P3/P4 合并为 binance 单 PR #432；P1 为 contracts 独立 PR #19。实际采用 `go.mod replace` 指向本地 contracts 检出，未阻塞于 contracts tag 发布。

### 发布待办（contracts PR #19 合入后）

- [ ] contracts PR #19 合入 main → 打 `v0.5.0` tag
- [ ] binance `go.mod` 移除 `replace` 指令 → `go get github.com/ZoneCNH/contracts@v0.5.0`
- [ ] binance PR #432 合入
- [ ] ZoneCNH PR #1679 合入

## 7. 不在本计划范围（Non-goals）

- 不重构 binance client/server 业务逻辑（仅切换契约类型来源）
- 不引入 transportx（Envelope 迁移是独立 ADR，见 `docs/production-standards/transportx.md`）
- 不处理 GAP-E8/E19/E23（schema/hash/精度治理，另有 `plans/binance/011-runtime-gap-master-plan` 承载）
- 不改 contracts 其他文件（ports.go/decision*card.go/regime*\*.go 等）
- 不动 binance 与 domain_market 的依赖关系（L2.5 依赖合规，保持）
