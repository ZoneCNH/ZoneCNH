# ADR-007: internal/wire 迁移到 contracts canonical（Supersede ADR-002）

> **Status**: Accepted（2026-07-05 — Phase 0-4 已实施 + post-ship 残留全量清理：contracts v0.5.0/v0.5.1/v0.5.2 canonical 富化 + 死字段移除 + binance `internal/wire` 删除 + `internal/ingestcodec` boundary 建立，7 build tag 0 FAIL，boundary-gates 15/15 全绿）
> **Date**: 2026-07-05
> **Accepted**: 2026-07-05
> **决策者**: ZoneCNH architecture
> **关联**: Supersede `ADR-002-wire-boundary.md`；执行计划 `plans/binance/012-wire-to-contracts-migration-plan-20260705.md`；`module/FOUNDATION-DEPS.yaml`（contracts 依赖边界）；`module/contracts/spec/SPEC.md` FR-006/BR-011
> **仓库归属**: ZoneCNH 主仓 `module/binance/`；代码实施在 `contracts`（v0.5.0 → v0.5.1 → v0.5.2）与 `binance`（feat branch）runtime 仓

---

## 1. 背景与问题

ADR-002（2026-06-24 Accepted）决定 `internal/wire` 暂时保留为 binance 仓内部自包含契约，理由是 contracts canonical 使用 `json.RawMessage` 承载 InstrumentKey，而 wire 使用 `domainmarket.InstrumentKey` 强类型，完整迁移"待 contracts InstrumentKey 泛化后执行"。

截至 2026-07-05 实测：

- `internal/wire/` 共 5 文件（doc.go/types.go/reject.go/transport.go/types_test.go），定义 `IngestRequest`/`IngestResult`/`IngestAck`/`IngestReject` + 4 个辅助类型
- `[COMPUTED]` `rg -l "internal/wire" --type go` 命中 62 文件（含 wire 自身），覆盖 client/server/cmd/test 全链路
- binance `go.mod` **未**接入 `github.com/ZoneCNH/contracts`
- contracts `pkg/contracts/ingestion.go` 已有 canonical 类型，但字段少于 wire（缺 Symbol/PayloadHash/TraceContext/Quality/Gap/SLA/AcceptedKey/AcceptedAt 等 9 字段）

五份架构分析报告（`report/arch/`）一致将"wire 未迁移 contracts"列为 MED 级待执行项。

## 2. 评估

### 2.1 真正阻塞是架构依赖边界，非引用量

`[KNOWN, HIGH]` `module/FOUNDATION-DEPS.yaml`：
- L200 `contracts: []` —— contracts 无 Foundation 运行时依赖
- L411-413 `from: contracts, to: [...]` —— contracts 允许下游**不含** L2.5 层（domain_market/decimalx/domainx）

`domainmarket.InstrumentKey` 经 `decimalx.Decimal`（Strike 字段）传递依赖。若 contracts import 该类型，将污染 contracts 的零依赖边界，违反 BR-004。**因此 contracts 不能持有强类型 InstrumentKey**，"InstrumentKey 泛化"在当前架构下无解。

### 2.2 字段差异是第二阻塞

`[COMPUTED]` wire 比 contracts canonical 多 9 个跨域语义字段：

| 类型 | wire 独有字段 |
| ---- | ---- |
| IngestRequest | Symbol、PayloadHash、TraceContext、Quality |
| IngestAck | AcceptedKey、AcceptedAt、Quality、Gap、SLA |

这些字段（W3C trace 透传、质量门禁 verdict、SLA 证据、gap 检测）属跨域契约语义，应在 canonical 层定义，而非留在 binance 私有包。

### 2.3 RejectCode 双枚举

wire `reject.go` 以 `BNC-001..019` 模块私有码为主、9 个 canonical 别名指向 BNC 码；contracts 以 9 个 canonical string 码为 SSOT。两套常量值不可直接互换。binance 模块级诊断/告警路由仍需 BNC 码，但跨域契约必须用 canonical 码。

### 2.4 方案抉择

| 方案 | 描述 | 裁决 |
| ---- | ---- | ---- |
| A 泛型参数化 | `IngestRequest[T any]`，binance 实例化强类型 | 拒绝：契约层泛型化破坏窄接口（宪法 §4），所有消费方携带类型参数 |
| B plain DTO | contracts 定义无依赖 InstrumentKey struct | 拒绝：与 domain_market SSOT 冲突，Decimal↔string 精度风险，权威分裂 |
| **C canonical 富化 + boundary codec** | contracts 补齐 9 字段、InstrumentKey 保持 `json.RawMessage`；binance 保留极薄 `internal/ingestcodec` 做 `domainmarket.InstrumentKey ↔ json.RawMessage` 转换 + BNC 码映射 | **采纳** |

方案 C 是唯一同时满足三硬约束的解：contracts 零依赖保持、canonical 单一权威、binance 强类型在 boundary 保留。

## 3. 决策

**采纳方案 C**，执行 `internal/wire` → contracts canonical 迁移：

1. contracts canonical 富化：`IngestRequest` 补 Symbol/PayloadHash/TraceContext/Quality；`IngestAck` 补 AcceptedKey/AcceptedAt/Quality/Gap/SLA；定义 `TraceContext`/`QualityVerdict`/`GapStatus`/`SLAStatus` 为 contracts 导出类型。InstrumentKey 保持 `json.RawMessage`。`Payload` 统一为 `json.RawMessage`。
2. binance `go.mod` 接入 `github.com/ZoneCNH/contracts v1.6.0`（breaking bump）。
3. binance 新建 `internal/ingestcodec/`：`MarshalInstrumentKey`/`UnmarshalInstrumentKey` + `BNCCode` 枚举与 `BNCCodeToCanonical` 映射。该包**不定义任何 DTO**。
4. 62 处 import 站点改用 `contracts` 类型，字段访问统一 canonical 名（`IdempotencyKey`→`RequestID` 等）。
5. 删除 `internal/wire/` 全部 5 文件。

## 4. 理由

1. **架构合规优先**：contracts 零依赖是 FOUNDATION-DEPS 硬约束，不可为迁移便利而破例。方案 A/B 均违反此约束或引入权威分裂。
2. **canonical 单一权威**：9 个跨域语义字段不应散落在 binance 私有包，否则其他未来 ingestor（market_data 等）无法复用，违反 contracts 存在意义。
3. **强类型不丢失**：binance 在 boundary（`internal/ingestcodec`）仍持有 `domainmarket.InstrumentKey` 强类型，仅在跨进程契约边界序列化为 `json.RawMessage`，类型安全在 binance 内部完整保留。
4. **成本可控**：62 处 import 切换虽量大，但属机械性改动，分 4 batch 可独立验证；contracts breaking 仅影响 binance（当前唯一 ingestion 消费方）。

## 5. 替代方案（已拒绝）

- **方案 A（泛型参数化）**：拒绝。`MarketDataService` 接口需同步泛型化，破坏窄接口原则；Go 泛型对方法集约束限制多；所有未来消费方被迫携带类型参数。
- **方案 B（plain DTO）**：拒绝。InstrumentKey SSOT 在 domain_market（CONSTITUTION §1.1），contracts 重复定义造成权威分裂；`decimalx.Decimal`→`string` 转换有精度风险。
- **维持 ADR-002 现状**：拒绝。五份架构报告列为 MED 待执行；"InstrumentKey 泛化"在当前依赖架构下无解，无限期搁置非治理态度。

## 6. 后果

- contracts 发布 v1.6.0（breaking：字段补入 + Payload 类型 `[]byte`→`json.RawMessage` + IdempotencyKey→RequestID 命名统一）
- binance 删除 `internal/wire/`，新增 `internal/ingestcodec/`
- binance `go.mod` 新增 `github.com/ZoneCNH/contracts v1.6.0` direct 依赖
- ADR-002 状态改 `Superseded by ADR-007`
- `boundary-gates.sh` §3/§4（client↔server 互不 import）仍由 contracts 类型隔离保证，逻辑不变
- `internal/wire/doc.go` 标注的迁移路径关闭

## 7. 验证

```bash
# binance 仓
rg "internal/wire" /home/workspace/binance --type go        # → 0 命中
rg "github.com/ZoneCNH/contracts" /home/workspace/binance --type go  # → ≥1
go build ./... && go test ./... -short && go test -race ./...
go vet ./... && golangci-lint run
bash scripts/boundary-gates.sh                              # → 14/14 PASS

# contracts 仓
go test ./pkg/contracts/... -race
```

## 8. 修订记录

- 2026-07-05：初版。Supersede ADR-002，采纳方案 C（canonical 富化 + boundary codec）。
