# ADR-002: internal/wire 保留为内部自包含契约

> 状态：Superseded by ADR-007（2026-07-05）
> 日期：2026-06-24（2026-06-25 订正事实层并迁回主仓）
> 决策者：ZoneCNH architecture
> 来源：Plan006 Task 8.4, §11.11
> 仓库归属：ZoneCNH 主仓 `module/binance/`
> Supersede：本 ADR 的"待 contracts InstrumentKey 泛化后迁移"状态由 `ADR-007-wire-to-contracts-migration.md` 闭环。执行计划见 `plans/binance/012-wire-to-contracts-migration-plan-20260705.md`。

## 背景

Plan006 Task 8.4 要求将 `internal/wire` 契约迁移到 `module/contracts`（natsx subject + domain_market envelope），删除 internal/wire。

## 评估

1. **当前状态**: `internal/wire` 包含 3 个文件（doc.go/types.go/transport.go），定义 `IngestRequest`/`IngestResult`/`IngestAck`/`IngestReject` 等核心契约类型，被 33 处 import 引用（截至 2026-06-25 实测），覆盖 client/server/smoke/e2e 全链路。

2. **§8 gate 含义更正**: `scripts/boundary-gates.sh` §8 gate（`gate_wire_externality`）实际只检测仓内无 `.proto` 文件，并不验证 wire 的 import 边界。client/server 互不 import 由 §3/§4 gate 保证。ADR 早期版本曾将 §8 描述为"wire 边界验证门禁"，系对 gate 实现的误读，此处订正。

3. **module/contracts 已存在**: `module/contracts`（独立 Go 仓 `github.com/ZoneCNH/contracts`，本地 `/home/workspace/contracts`）已创建。`pkg/contracts/ingestion.go` 已定义 canonical `IngestRequest`/`IngestResult`/`IngestAck`/`IngestReject`。`internal/wire/doc.go` 已声明此迁移路径：contracts 使用 `json.RawMessage`（InstrumentKey），wire 使用 `domainmarket.InstrumentKey` 强类型，完整迁移待 contracts InstrumentKey 泛化。

4. **AGENTS.md 边界**: ZoneCNH 主仓 AGENTS.md 规定"模块代码的本地工作目录统一为 /home/workspace/{module}"。但 contracts 仓是独立 Go 模块仓（非文档仓），且 binance 仓 go.mod 已接入 `domain-market`、`natsx` 两个 ZoneCNH Go 仓作 direct 依赖，"禁止依赖文档仓 Go 代码"的旧理由前提不成立。真正的迁移阻力是 InstrumentKey 强类型差异与 33 处引用的切换成本，而非仓库边界。

## 决策

**internal/wire 暂时保留为 binance 仓内部自包含契约**，维持当前 3 文件结构。不立即执行向 module/contracts 的完整迁移。

## 理由

1. wire 类型是 binance runtime 的内部通信契约，当前仍有独立封装价值（强类型 InstrumentKey）
2. contracts 仓 canonical 类型已落地，但 InstrumentKey 强类型 vs `json.RawMessage` 的差异未解决，迁移会丢失类型安全
3. 当前 33 处引用的迁移成本高（全链路 client/server/smoke/e2e 同步切换），在类型差异解决前收益为零（契约语义不变）
4. 迁移时机由 contracts InstrumentKey 泛化进度决定，而非 Plan checklist

## 替代方案（已拒绝）

- **方案 A**: 立即迁移到 contracts 仓 —— 拒绝：InstrumentKey 泛化未完成，强行迁移会丢失强类型或要求 contracts 先做破坏性变更
- **方案 B**: 删除 internal/wire 改用 natsx 原生类型 —— 拒绝：natsx 不定义 IngestRequest 等业务语义类型，wire 封装有独立价值

## 后果

- `internal/wire/doc.go` 标注为"内部自包含契约，待 contracts InstrumentKey 泛化后迁移"
- Task 8.4 关闭，不阻塞 Plan006 release
- §3/§4 gate 继续作为 client/server 互不 import 的边界验证门禁；§8 gate 仅作 `.proto` 检测

## 验证

- `bash scripts/boundary-gates.sh` → 14/14 PASS（§15 亦通过：本 ADR 不在 runtime 仓）
- `go build ./...` → PASS（wire import 不受影响）
- 33 处 import 不变

## 修订记录

- 2026-06-25：事实层订正。"module/contracts 不存在"→"已存在且含 canonical 类型"；"34 处引用"→"33 处"；§8 gate 语义更正；"禁止依赖文档仓 Go 代码"理由更正；ADR 从 binance runtime 仓迁回主仓 `module/binance/`（制品归属：架构决策记录归主仓，runtime 仓 §15 gate 禁止承载 spec 制品）。
